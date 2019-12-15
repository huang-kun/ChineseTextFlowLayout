//
//  StringComponents.swift
//  ChineseTextFlowLayout
//
//  Created by huangkun on 2019/12/15.
//  Copyright © 2019 huangkun. All rights reserved.
//

import Foundation

extension NSString {
    
    func characterStringComponents() -> [String] {
        var components: [String] = []
        for i in 0..<length {
            let r = NSRange(location: i, length: 1)
            let c = substring(with: r)
            components.append(c)
        }
        return components
    }
}

extension String {
    
    func characterStringComponents() -> [String] {
        let nsString = self as NSString
        return nsString.characterStringComponents()
    }

}
