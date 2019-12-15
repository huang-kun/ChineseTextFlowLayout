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
    
    override func prepare() {
        super.prepare()
        createLayoutNodes()
        updateLayoutNodes()
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return nodes.filter { rect.contains($0.frame) }.map { $0.attr }
    }
    
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
    }
    
    func updateLayoutNodes() {
        for node in nodes {
            // 如果一行只有一个字，不用换行
            if node.isHeadOfLine && node.isTailOfLine {
                node.adjustPosition()
            }
            // 该节点不可以出现在行首，看情况换行
            else if node.isHeadOfLine && !node.canBeHeadOfLine {
                node.adjustPositionsFromPreviousCandidate()
            }
            // 该节点不可以出现在行末尾，看情况换行
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
            if node.beyondBoundary {
                if node.canBeHeadOfLine {
                    node.changeToNextLine()
                } else {
                    node.adjustPositionsFromPreviousCandidate()
                }
            }
        }
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
