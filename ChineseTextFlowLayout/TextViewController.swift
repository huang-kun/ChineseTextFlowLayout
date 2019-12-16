//
//  TextViewController.swift
//  ChineseTextFlowLayout
//
//  Created by huangkun on 2019/12/16.
//  Copyright © 2019 huangkun. All rights reserved.
//

import UIKit

class TextViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    weak var delegate: TextViewControllerDelegate?
    var content: String {
        set {
            // 预先调用viewDidLoad
            let _ = view
            textView.text = newValue
        }
        get {
            let _ = view
            return textView.text
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.textViewControllerWillDisappear(self)
    }
 
}

protocol TextViewControllerDelegate: AnyObject {
    func textViewControllerWillDisappear(_ tvc: TextViewController)
}
