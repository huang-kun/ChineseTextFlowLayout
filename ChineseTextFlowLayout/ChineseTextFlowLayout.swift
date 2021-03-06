//
//  ChineseTextFlowLayout.swift
//  ChineseTextFlowLayout
//
//  Created by huangkun on 2019/12/13.
//  Copyright © 2019 huangkun. All rights reserved.
//

import UIKit

class ChineseTextFlowLayout: UICollectionViewFlowLayout {
    
    var nodes: [LayoutNode] = []
    var oldFrameOfLastNode = CGRect.zero
    var newFrameOfLastNode = CGRect.zero
    
    // MARK: override

    override func prepare() {
        super.prepare()
        createLayoutNodes()
        updateLayoutNodes()
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return nodes.filter { rect.contains($0.frame) }.map { $0.attr }
    }
    
    override var collectionViewContentSize: CGSize {
        var contentSize = super.collectionViewContentSize
        if oldFrameOfLastNode != newFrameOfLastNode {
            contentSize.height += abs(newFrameOfLastNode.maxY - oldFrameOfLastNode.maxY)
        }
        return contentSize
    }
    
    // MARK: Custom
    
    func createLayoutNodes() {
        nodes.first?.removeAll()
        nodes.removeAll()
        
        guard let cv = collectionView else { return }
        guard let dataSource = cv.dataSource else { return }
        guard let delegate = cv.delegate as? ChineseTextFlowLayoutDelegate else { return }
        
        let sections = dataSource.numberOfSections?(in: cv) ?? 1
        for s in 0..<sections {
            let items = dataSource.collectionView(cv, numberOfItemsInSection: s)
            for i in 0..<items {
                let indexPath = IndexPath(item: i, section: s)
                let text = delegate.collectionView(cv, layout: self, chineseTextForItemAt: indexPath)
                if let attr = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes {
                    let node = LayoutNode(content: text, attributes: attr, layout: self)
                    nodes.last?.append(node)
                    nodes.append(node)
                }
            }
        }
        oldFrameOfLastNode = nodes.last?.frame ?? CGRect.zero
    }
    
    func updateLayoutNodes() {
        for node in nodes {
            // 修复位置布局错误的节点
            node.validatePosition()
            
            // 如果是换行符，直接换行
            if node.hasLineBreak {
                node.changeToNextLine()
            }
            // 该节点（e.g.末尾标点）不可以出现在行首，寻找前面可以换行的节点来换行
            else if node.isHeadOfLine && !node.canBeHeadOfLine {
                node.adjustPositionsFromPreviousCandidate()
            }
            // 该节点（e.g.起始标点）不可以出现在行末尾，看情况换行
            else if node.isTailOfLine && !node.canBeTailOfLine {
                if node.canBeHeadOfLine {
                    node.changeToNextLine()
                } else {
                    node.adjustPositionsFromPreviousCandidate()
                }
            }
            // 该节点不需要换行，正常对齐
            else {
                node.adjustPosition()
            }
            
            // 如果调整后，该节点超出frame，依然需要换行
            if node.isBeyondBoundary {
                if node.canBeHeadOfLine {
                    node.changeToNextLine()
                } else {
                    node.adjustPositionsFromPreviousCandidate()
                }
            }
            // 如果调整后，该节点依然超出frame，可能是容器宽度过窄导致之前的换行无效，因此采取强制换行
            if node.isBeyondBoundary {
                node.changeToNextLine()
            }
        }
        newFrameOfLastNode = nodes.last?.frame ?? CGRect.zero
    }
    
    func debugLookupFirstNode(match text: String) -> LayoutNode? {
        guard !text.isEmpty else { return nil }
        let characters = text.characterStringComponents()
        let charCount = characters.count
        let nodeCount = nodes.count
        for (i, node) in nodes.enumerated() {
            if node.content == characters[0] {
                let j = i + charCount - 1
                if j < nodeCount {
                    let possibleMatch = nodes[i...j].map { $0.content }
                    if possibleMatch == characters {
                        return node
                    } else {
                        continue
                    }
                }
            }
        }
        return nil
    }
}

protocol ChineseTextFlowLayoutDelegate: UICollectionViewDelegateFlowLayout {
    /// 给对应的indexPath返回一个中文字符
    func collectionView(_ collectionView: UICollectionView, layout: ChineseTextFlowLayout, chineseTextForItemAt indexPath: IndexPath) -> String
}
