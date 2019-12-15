//
//  ViewController.swift
//  ChineseTextFlowLayout
//
//  Created by huangkun on 2019/12/13.
//  Copyright © 2019 huangkun. All rights reserved.
//

import UIKit

class TextCell: UICollectionViewCell {
    @IBOutlet weak var textLabel: UILabel!
}

class ViewController: UIViewController {
    
    var minimumCompressionWidth: CGFloat = 0
    var flowLayout: UICollectionViewFlowLayout!
    var textLayout: ChineseTextFlowLayout!
    var characters: [String] = []
    
    @IBOutlet weak var layoutSwitcher: UISwitch!
    @IBOutlet weak var widthSlider: UISlider!
    @IBOutlet weak var textButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let space: CGFloat = 0
        collectionView.contentInset = UIEdgeInsets.zero
        
        textLayout = ChineseTextFlowLayout()
        textLayout.minimumLineSpacing = space
        textLayout.minimumInteritemSpacing = space
        
        flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        
        minimumCompressionWidth = flowLayout.itemSize.width + flowLayout.sectionInset.left + flowLayout.sectionInset.right + collectionView.contentInset.left + collectionView.contentInset.right + 1
        
        loadText()
        collectionView.reloadData()
    }

    func loadText() {
        characters.removeAll()
        if let path = Bundle.main.path(forResource: "demo", ofType: "txt") {
            let text = try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
            characters += text.characterStringComponents()
        }
    }
    
    @IBAction func changeLayout(_ sender: UISwitch) {
        collectionView.collectionViewLayout = sender.isOn ? textLayout : flowLayout
    }
    
    @IBAction func changeWidth(_ sender: UISlider) {
        guard let layoutFrame = view.layoutGuides.first?.layoutFrame else { return }
        changeWidth(inSize: layoutFrame.size, progress: CGFloat(sender.value))
    }
    
    @IBAction func editText(_ sender: UIBarButtonItem) {
        let estimatedSize = CGSize(width: 44, height: 44)
        flowLayout.estimatedItemSize = estimatedSize
        textLayout.estimatedItemSize = estimatedSize
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let layoutFrame = view.layoutGuides.first?.layoutFrame else { return }
        let reversedSize = CGSize(width: layoutFrame.height, height: layoutFrame.width)
        changeWidth(inSize: reversedSize, progress: CGFloat(widthSlider.value))
    }
    
    func changeWidth(inSize size: CGSize, progress: CGFloat) {
        let containerWidth = size.width
        var constant = containerWidth * (1 - progress)
        if constant > containerWidth - minimumCompressionWidth {
            constant = containerWidth - minimumCompressionWidth
        }
        trailingConstraint.constant = constant
    }
    
}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return characters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextCell", for: indexPath) as! TextCell
        cell.textLabel.text = characters[indexPath.item]
        return cell
    }
    
}

extension ViewController: ChineseTextFlowLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout: ChineseTextFlowLayout, chineseTextForItemAt indexPath: IndexPath) -> String {
        return characters[indexPath.item]
    }
    
}
