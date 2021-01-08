//
//  BWComposerView.swift
//  TestKeyboard
//
//  Created by bw on 2021/1/6.
//

import UIKit
import Foundation

public enum BWKeyboardStatus: String {
    case BWLeft
    case BWRight
    case BWEditing
}

public protocol BWComposerViewDelegate: class {
    func leftButtonAction(_ composerView: BWComposerView)
    func rightButtonAction(_ composerView: BWComposerView)
    
    func textViewBeginEdit(_ textView: UITextView)
    func textViewTextChange(_ textView: UITextView)
    func keyboardFrameChangeByDrag(_ textView: UITextView, keyBoardheight: CGFloat)
}

public class BWComposerView: UIView {
    static let ObservingInputAccessoryViewFrameDidChangeNotification = "ObservingInputAccessoryViewFrameDidChangeNotification"
    
    public let kTextViewDefaultHeight: CGFloat = 44.0
    
    public var textView: UITextView!
    
    public var containerView: UIView!
    public var leftButton: UIButton!
    public var rightButton: UIButton!
    
    public var keyboardStatus: BWKeyboardStatus = .BWEditing
    public var showArea: Bool = false
    
    public weak var delegate: BWComposerViewDelegate?
    
    
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
        // backgroundView
        let backgroundView = UIView.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200))
        addSubview(backgroundView)

        leftButton = UIButton(type: .system)
        leftButton.frame = CGRect(x: 10, y: 15, width: 35, height: 35)
        leftButton.setImage(UIImage(named: "语音按钮"), for: .normal)
        leftButton.addTarget(self, action: #selector(action1(_:)), for: .touchUpInside)
        
        rightButton = UIButton(type: .system)
        rightButton.frame = CGRect(x: UIScreen.main.bounds.width-45, y: 15, width: 35, height: 35)
        rightButton.setImage(UIImage(named: "发送文件"), for: .normal)
        rightButton.addTarget(self, action: #selector(action2(_:)), for: .touchUpInside)
        
        textView = UITextView.init(frame: CGRect(x: 50, y: 10, width: UIScreen.main.bounds.width-100, height: kTextViewDefaultHeight))
        textView.delegate = self
        textView.font = UIFont.systemFont(ofSize: 17.0)
        
        containerView = UIView.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200))
        containerView.backgroundColor = .clear
        containerView.alpha = 0
        addSubview(containerView)
        
        let picButton = UIButton(type: .system)
        picButton.frame = CGRect(x: 20, y: leftButton.frame.origin.y+leftButton.frame.size.height+30, width: 50, height: 50)
        picButton.setImage(UIImage(named: "sharemore_pic"), for: .normal)
        picButton.addTarget(self, action: #selector(action1(_:)), for: .touchUpInside)
        
        addSubview(leftButton)
        addSubview(rightButton)
        addSubview(textView)
        containerView.addSubview(picButton)
        
        if #available(iOS 13.0, *) {
            let dyColor1 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor.white
                } else {
                    return UIColor.tertiarySystemBackground
                }
            }
            self.backgroundColor = dyColor1
            backgroundView.backgroundColor = dyColor1
            
            let dyColor2 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor(red: 243/255.0, green: 244/255.0, blue: 245/255.0, alpha: 1)
                } else {
                    return UIColor.systemBackground
                }
            }
            textView.backgroundColor = dyColor2
            
        } else {
            // Fallback on earlier versions
            self.backgroundColor = UIColor.white
            backgroundView.backgroundColor = UIColor.white
            textView.backgroundColor = UIColor(red: 243/255.0, green: 244/255.0, blue: 245/255.0, alpha: 1)
        }
        
        //
        textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    @objc func action1(_ button: UIButton) {
        if keyboardStatus != .BWLeft {
            self.containerView.alpha = 0
            keyboardStatus = .BWLeft
            showArea = false
            textView.resignFirstResponder()
            delegate?.leftButtonAction(self)
        }
    }
    
    @objc func action2(_ button: UIButton) {
        if keyboardStatus != .BWRight {
            UIView.animate(withDuration: 0.25) {
                self.containerView.alpha = 1
            }
            keyboardStatus = .BWRight
            textView.resignFirstResponder()
            delegate?.rightButtonAction(self)
        }
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        superview?.removeObserver(self, forKeyPath: "center")
        
        newSuperview?.addObserver(self, forKeyPath: "center", options: [.old, .new], context: nil)
    }
    
    deinit {
        superview?.removeObserver(self, forKeyPath: "center")
    }
    
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as AnyObject? === textView && keyPath == "contentSize" {
            let height: CGFloat = min(100, textView.contentSize.height <= kTextViewDefaultHeight ? kTextViewDefaultHeight : textView.contentSize.height)
            print("abcd ComposerView observeValue textView \(textView.frame.size.height) \(textView.contentSize.height)")
            var frame = textView.frame
            frame.size.height = height
            textView.frame = frame
            leftButton.frame.origin.y = height-30
            rightButton.frame.origin.y = height-30
            delegate?.textViewTextChange(textView)
        }
        
        if object as AnyObject? === self.superview && keyPath == "center" {
            #if DEBUG
            let rect = self.superview!.frame
            let height = UIScreen.main.bounds.height-rect.minY-self.frame.height
            if keyboardStatus != .BWRight {
                delegate?.keyboardFrameChangeByDrag(textView, keyBoardheight: height)
            }
            print("observeValue self.superview!.frame.origin.y \(rect.origin.y) \(height)")
            #endif
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        print("abcd layoutSubviews textView.frame.size.height=\(textView.frame.size.height) \(textView.contentSize.height)")
        if textView.contentSize.height <= kTextViewDefaultHeight {
            textView.layer.cornerRadius = textView.contentSize.height/2
        }
        else {
            textView.layer.cornerRadius = 10
        }
        textView.layer.masksToBounds = true
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.layoutManager.allowsNonContiguousLayout = false
    }
}


extension BWComposerView: UITextViewDelegate {
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        UIView.animate(withDuration: 0.25) {
            self.containerView.alpha = 0
        }
        keyboardStatus = .BWEditing
        showArea = false
        delegate?.textViewBeginEdit(textView)
        return true
    }
    
    
}
