//
//  BWComposerTextView.swift
//  Rocket.Chat
//
//  Created by bw on 2021/1/21.
//  Copyright © 2021 Rocket.Chat. All rights reserved.
//

import Foundation

public class BWComposerTextView: UITextView {

    public override func canPerformAction(_ action: Selector, withSender sender: Any!) -> Bool {
        if (action == #selector(cut(_:))) {
            return super.canPerformAction(action, withSender: sender)
        }
        else if (action == #selector(copy(_:))) {
            return super.canPerformAction(action, withSender: sender)
        }
        else if (action == #selector(paste(_:))) {
            return super.canPerformAction(action, withSender: sender)
        }
        else if (action == #selector(select(_:))) {
            return super.canPerformAction(action, withSender: sender)
        }
        else if (action == #selector(selectAll(_:))) {
            return super.canPerformAction(action, withSender: sender)
        }
        else if (action == #selector(lineBreakAction(_:))) {
            return true
        }
        
        return false
    }
    
    @objc public func lineBreakAction(_ sender: Any) {
        if self.text.count > 0 {
//            let location = self.selectedRange.location
//            var str = self.text
//            let start1 = str!.startIndex
//            let start2 = str!.index(str!.startIndex, offsetBy: location)
//            let str1 = String(str![start1..<start2])+"\n"
//            let str2 = String(str![start2..<text!.endIndex])
//            self.text = str1+str2
//            self.selectedRange = NSRange.init(location: location+1, length: 0)
            
            // the simplest way
            self.replace(self.selectedTextRange!, withText: "\r")
        }
    }
}
