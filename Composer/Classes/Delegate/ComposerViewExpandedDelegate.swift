//
//  ComposerViewExpandedDelegate.swift
//  RocketChatViewController Example
//
//  Created by Matheus Cardoso on 9/12/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import UIKit

private extension ComposerView {
    var replyView: ReplyView? {
        return componentStackView.subviews.first(where: { $0 as? ReplyView != nil }) as? ReplyView
    }

    var hintsView: HintsView? {
        return utilityStackView.subviews.first(where: { $0 as? HintsView != nil }) as? HintsView
    }
}

/**
 An expanded child of the ComposerViewDelegate protocol.
 This adds default implementatios for reply, autocompletion and more.
 */
public protocol ComposerViewExpandedDelegate: ComposerViewDelegate, HintsViewDelegate, ReplyViewDelegate {
    func hintPrefixes(for composerView: ComposerView) -> [Character]
    func isHinting(in composerView: ComposerView) -> Bool

    func composerView(_ composerView: ComposerView, didChangeHintPrefixedWord word: String)
}

public extension ComposerViewExpandedDelegate {
    func composerViewDidChangeSelection(_ composerView: ComposerView) {
        func didChangeHintPrefixedWord(_ word: String) {
            self.composerView(composerView, didChangeHintPrefixedWord: word)

            guard let hintsView = composerView.hintsView else {
                return
            }

            UIView.animate(withDuration: 0.2) {
                hintsView.reloadData()
                hintsView.invalidateIntrinsicContentSize()
                hintsView.layoutIfNeeded()
            }
        }

        if let range = composerView.textView.rangeOfNearestWordToSelection {
            let word = String(composerView.textView.text[range])

            if let char = word.first, hintPrefixes(for: composerView).contains(char) {
                didChangeHintPrefixedWord(word)
            } else {
                didChangeHintPrefixedWord("")
            }

            return
        }

        didChangeHintPrefixedWord("")
    }

    func composerView(_ composerView: ComposerView, didTapButtonAt slot: ComposerButtonSlot) {
        switch slot {
        case .left:
            UIView.animate(withDuration: 0.2) {
                composerView.replyView?.isHidden = false
                composerView.layoutIfNeeded()
            }
        case .right:
            composerView.textView.text = ""
        }
    }

    // MARK: Addons

    func numberOfAddons(in composerView: ComposerView, at slot: ComposerAddonSlot) -> UInt {
        return 1
    }

    func composerView(_ composerView: ComposerView, addonAt slot: ComposerAddonSlot, index: UInt) -> ComposerAddon? {
        switch slot {
        case .utility:
            return .hints
        case .component:
            return .reply
        }
    }

    func composerView(_ composerView: ComposerView, didUpdateAddonView view: UIView?, at slot: ComposerAddonSlot, index: UInt) {
        if let view = view as? HintsView {
            view.registerCellTypes(UserHintCell.self, TextHintCell.self)
            view.hintsDelegate = self
        }

        if let view = view as? ReplyView {
            view.delegate = self
        }
    }
}
