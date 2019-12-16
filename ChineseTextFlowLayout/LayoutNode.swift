//
//  LayoutNode.swift
//  ChineseTextFlowLayout
//
//  Created by huangkun on 2019/12/13.
//  Copyright © 2019 huangkun. All rights reserved.
//

import UIKit

final class LayoutNode {
    
    // MARK: Static
    
    /// 中文起始标点（〈《「『〔【“‘﹃
    static var beginPuncCharset: CharacterSet {
        return CharacterSet(charactersIn: "\u{ff08}\u{3008}\u{300a}\u{300c}\u{300e}\u{3014}\u{3010}\u{201c}\u{2018}\u{fe43}")
    }
    /// 中文结束标点  ）〉》」』〕、】。！；”’—﹏…～？：，﹄
    static var endPuncCharset: CharacterSet {
        return CharacterSet(charactersIn: "\u{ff09}\u{3009}\u{300b}\u{300d}\u{300f}\u{fe44}\u{3015}\u{2014}\u{fe4f}\u{3001}\u{3011}\u{3002}\u{ff01}\u{ff1b}\u{201d}\u{2019}\u{2026}\u{ff5e}\u{ff0c}\u{ff1f}\u{ff1a}")
    }
    static var lineBreakCharSet: CharacterSet {
        return CharacterSet(charactersIn: "\u{000a}")
    }
    /// 查看string是否属于特殊字符
    static func checkIf(text: String, foundInCharSet charSet: CharacterSet) -> Bool {
        guard let r = text.rangeOfCharacter(from: charSet) else { return false }
        return !r.isEmpty
    }
    
    // MARK: 节点属性
    
    /// 下一个节点
    var next: LayoutNode?
    /// 上一个节点
    weak var prev: LayoutNode?
    /// 节点布局信息
    let attr: UICollectionViewLayoutAttributes
    /// 节点所属的layout
    weak var layout: UICollectionViewFlowLayout?
    /// 节点文本
    let content: String
    /// 该节点是否为起始标点
    let isBeginPunc: Bool
    /// 该节点是否为结束标点
    let isEndPunc: Bool
    /// 包含换行符
    let hasLineBreak: Bool
    
    // MARK: 初始化
    
    init(content: String, attributes: UICollectionViewLayoutAttributes, layout: UICollectionViewFlowLayout) {
        self.content = content
        self.attr = attributes
        self.layout = layout
        self.isBeginPunc = LayoutNode.checkIf(text: content, foundInCharSet: LayoutNode.beginPuncCharset)
        self.isEndPunc = LayoutNode.checkIf(text: content, foundInCharSet: LayoutNode.endPuncCharset)
        self.hasLineBreak = LayoutNode.checkIf(text: content, foundInCharSet: LayoutNode.lineBreakCharSet)
    }
    
    // MARK: 节点计算属性
    
    var isFirstInSection: Bool {
        return attr.indexPath.item == 0
    }
    /// 该节点是否位于行开头
    var isHeadOfLine: Bool {
        guard let prev = prev else { return true }
        return frame.minY >= prev.frame.maxY
    }
    /// 该节点是否位于行末尾
    var isTailOfLine: Bool {
        guard let next = next else { return true }
        return frame.maxY <= next.frame.minY
    }
    /// 该节点是否可以位于行开头
    var canBeHeadOfLine: Bool {
        guard let prev = prev else { return true }
        return !isEndPunc && !prev.isBeginPunc
    }
    /// 该节点是否可以位于行末尾
    var canBeTailOfLine: Bool {
        return !isBeginPunc
    }
    /// 该节点是否超出该行的显示区域
    var isBeyondBoundary: Bool {
        return frame.maxX > lineWidth
    }
    
    // MARK: 方法
    
    /// 调整该节点的位置
    func adjustPosition() {
        guard let prev = prev else {
            frame.origin.x = sectionInset.left
            frame.origin.y = sectionInset.top
            return
        }
        if isHeadOfLine {
            frame.origin.x = sectionInset.left
            frame.origin.y = prev.frame.maxY + minimumLineSpacing
        } else {
            frame.origin.x = prev.frame.maxX + minimumInterItemSpacing
            frame.origin.y = prev.frame.maxY - frame.size.height
        }
    }
    /// 从该节点之前（可以换行）的某个节点开始换行，然后调整从换行后的节点到当前节点之间所有节点的位置
    func adjustPositionsFromPreviousCandidate() {
        if let prev = lookupPreviousCandidate(), !prev.hasLineBreak {
            prev.changeToNextLine()
            if prev.next !== self {
                var next = prev.next
                while next !== self {
                    next?.adjustPosition()
                    next = next?.next
                }
            }
        }
        adjustPosition()
    }
    /// 换行
    func changeToNextLine() {
        guard let prev = prev else { return }
        frame.origin.x = sectionInset.left
        frame.origin.y = prev.frame.maxY + minimumLineSpacing
        // 修复换行符高度的bug
        if hasLineBreak {
            frame.size.height = prev.frame.size.height
        }
    }
    /// 找到该节点之前（可以换行）的某个节点
    func lookupPreviousCandidate() -> LayoutNode? {
        guard let prev = prev else { return nil }
        if prev.canBeHeadOfLine {
            return prev
        }
        return prev.lookupPreviousCandidate()
    }
    /// 给节点设置链表关系
    func append(_ node: LayoutNode) {
        next = node
        node.prev = self
    }
    /// 解除节点的链表关系
    func removeAll() {
        guard let node = next else { return }
        next = nil
        node.prev = nil
        node.removeAll()
    }
    
    // MARK: Helper
    
    var frame: CGRect {
        set { attr.frame = newValue }
        get { return attr.frame }
    }
    
    var sectionInset: UIEdgeInsets {
        guard let layout = layout else { return UIEdgeInsets.zero }
        guard let cv = layout.collectionView else { return layout.sectionInset }
        guard let delegate = layout.collectionView?.delegate as? UICollectionViewDelegateFlowLayout else { return layout.sectionInset }
        return delegate.collectionView?(cv, layout: layout, insetForSectionAt: attr.indexPath.section) ?? layout.sectionInset
    }
    
    var minimumLineSpacing: CGFloat {
        guard let layout = layout else { return 0 }
        guard let cv = layout.collectionView else { return layout.minimumLineSpacing }
        guard let delegate = layout.collectionView?.delegate as? UICollectionViewDelegateFlowLayout else { return layout.minimumLineSpacing }
        return delegate.collectionView?(cv, layout: layout, minimumLineSpacingForSectionAt: attr.indexPath.section) ?? layout.minimumLineSpacing
    }
    
    var minimumInterItemSpacing: CGFloat {
        guard let layout = layout else { return 0 }
        guard let cv = layout.collectionView else { return layout.minimumInteritemSpacing }
        guard let delegate = layout.collectionView?.delegate as? UICollectionViewDelegateFlowLayout else {
            return layout.minimumInteritemSpacing
        }
        return delegate.collectionView?(cv, layout: layout, minimumInteritemSpacingForSectionAt: attr.indexPath.section) ?? layout.minimumInteritemSpacing
    }
    
    var lineWidth: CGFloat {
        guard let cv = layout?.collectionView else { return 0 }
        let inset = sectionInset
        return cv.frame.size.width + inset.left + inset.right
    }
}

extension LayoutNode: CustomStringConvertible {
    var description: String {
        return content
    }
}

extension LayoutNode: CustomDebugStringConvertible {
    var debugDescription: String {
        var desc = content + " \(frame)"
        if isHeadOfLine {
            desc += " line_head"
        }
        if isTailOfLine {
            desc += " line_tail"
        }
        return desc
    }
}
