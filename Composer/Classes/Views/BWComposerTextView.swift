//
//  BWComposerTextView.swift
//  Rocket.Chat
//
//  Created by bw on 2021/1/21.
//  Copyright © 2021 Rocket.Chat. All rights reserved.
//

import Foundation

public class BWComposerTextView: UITextView {
    public override var canBecomeFirstResponder: Bool {
        return true
    }

    public override func canPerformAction(_ action: Selector, withSender sender: Any!) -> Bool {
        if (action == #selector(lineBreakAction(_:))) {
            return true
        } else {
            return false
        }
    }
    
    @objc func lineBreakAction(_ sender: Any) {
        
    }
}
