//
//  BWComposerView.swift
//  TestKeyboard
//
//  Created by bw on 2021/1/6.
//

import UIKit
import Foundation

protocol BWComposerViewDelegate: class {
    func leftButtonAction(_ composerView: BWComposerView)
    func rightButtonAction(_ composerView: BWComposerView)
    
    func textViewBeginEdit(_ textView: UITextView)
    func textViewTextChange(_ textView: UITextView)
}

class BWComposerView: UIView {
    public var textView: UITextView!
    
    public var leftButton: UIButton!
    public var rightButton: UIButton!
    
    weak var delegate: BWComposerViewDelegate?
    
    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    
    public func commonInit() {
        self.backgroundColor = UIColor.red

        leftButton = UIButton(type: .system)
        leftButton.frame = CGRect(x: 10, y: 10, width: 35, height: 35)
        leftButton.setTitle("L", for: .normal)
        leftButton.addTarget(self, action: #selector(action1(_:)), for: .touchUpInside)
        
        rightButton = UIButton(type: .system)
        rightButton.frame = CGRect(x: UIScreen.main.bounds.width-50, y: 10, width: 35, height: 35)
        rightButton.setTitle("R", for: .normal)
        rightButton.addTarget(self, action: #selector(action2(_:)), for: .touchUpInside)
        
        
        textView = UITextView.init(frame: CGRect(x: 50, y: 10, width: UIScreen.main.bounds.width-100, height: 44))
        textView.delegate = self
//        let notificationCenter = NotificationCenter.default
//        notificationCenter.addObserver(textView, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: nil)
        textView.font = UIFont.systemFont(ofSize: 17.0)
        
        addSubview(leftButton)
        addSubview(rightButton)
        addSubview(textView)
        
        if #available(iOS 13.0, *) {
            let dyColor1 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor(red: 243/255.0, green: 244/255.0, blue: 245/255.0, alpha: 1)
                } else {
                    return UIColor.systemBackground
                }
            }
            textView.backgroundColor = dyColor1
            
        } else {
            // Fallback on earlier versions
            textView.backgroundColor = UIColor(red: 243/255.0, green: 244/255.0, blue: 245/255.0, alpha: 1)
        }
        
        textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    @objc func action1(_ button: UIButton) {
        textView.resignFirstResponder()
        delegate?.leftButtonAction(self)
    }
    
    @objc func action2(_ button: UIButton) {
        textView.resignFirstResponder()
        delegate?.rightButtonAction(self)
    }
    
//    @objc private func textDidChange() {
//
//    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as AnyObject? === textView && keyPath == "contentSize" {
            var frame = textView.frame
            var height: CGFloat = 0.0
            if textView.contentSize.height <= 44 {
                height = 44
            }
            else {
                height = textView.contentSize.height
            }
            print("abcd ComposerView observeValue textView \(textView.frame.size.height) \(textView.contentSize.height)")
            frame.size.height = height
            textView.frame = frame
            delegate?.textViewTextChange(textView)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        print("abcd layoutSubviews textView.frame.size.height=\(textView.frame.size.height) \(textView.contentSize.height)")
        if textView.contentSize.height <= 44 {
            textView.layer.cornerRadius = textView.contentSize.height/2
        }
        else {
            textView.layer.cornerRadius = 10
        }
        textView.layer.masksToBounds = true
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.layoutManager.allowsNonContiguousLayout = false
    }
    
    
    deinit {
//        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
    }
}


extension BWComposerView: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        delegate?.textViewBeginEdit(textView)
        return true
    }
    
    
}
