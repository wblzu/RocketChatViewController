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
        debugPrint("BWComposerTextView lineBreakAction")
    }
}
