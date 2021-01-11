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
    func keyboardFrameChange(_ textView: UITextView, keyBoardheight: CGFloat)
}

public class BWComposerView: UIView {
    static let ObservingInputAccessoryViewFrameDidChangeNotification = "ObservingInputAccessoryViewFrameDidChangeNotification"
    
    public let kTextViewDefaultHeight: CGFloat = 44.0
    public let kTextViewMaxHeight: CGFloat = 122.0
    public let kShowAreaHeight: CGFloat = 100.0
    public var kLastTextViewFrame: CGRect = CGRect.zero
    
    public var textView: UITextView!
    
    public var containerView: UIView!
    public var leftButton: UIButton!
    public var rightButton: UIButton!
    public var pressMic: UIView!
    public var pressMicLabel: UILabel!
    
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
        let backgroundView = UIView.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: kShowAreaHeight))
        addSubview(backgroundView)

        leftButton = UIButton(type: .system)
        leftButton.frame = CGRect(x: 10, y: 15, width: 35, height: 35)
        leftButton.setImage(UIImage(named: "语音按钮"), for: .normal)
        leftButton.addTarget(self, action: #selector(action1(_:)), for: .touchUpInside)
        
        rightButton = UIButton(type: .system)
        rightButton.frame = CGRect(x: UIScreen.main.bounds.width-45, y: 15, width: 35, height: 35)
        rightButton.setImage(UIImage(named: "发送文件"), for: .normal)
        rightButton.addTarget(self, action: #selector(action2(_:)), for: .touchUpInside)
        
        
        //
        pressMic = UIView.init(frame: CGRect(x: 50, y: 10, width: UIScreen.main.bounds.width-100, height: kTextViewDefaultHeight))
        pressMic.layer.cornerRadius = 10
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressRecognized(_:)))
        longPress.minimumPressDuration = 0.01
        pressMic.addGestureRecognizer(longPress)
        addSubview(pressMic)
        
        pressMicLabel = UILabel.init(frame: CGRect(x: 0, y: 0, width: pressMic.frame.size.width, height: pressMic.frame.size.height))
        pressMicLabel.isUserInteractionEnabled = false
        pressMicLabel.textAlignment = .center
        pressMicLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        pressMicLabel.text = "按住 说话"
        pressMic.addSubview(pressMicLabel)
        
        
        //
        textView = UITextView.init(frame: CGRect(x: 50, y: 10, width: UIScreen.main.bounds.width-100, height: kTextViewDefaultHeight))
        textView.delegate = self
        textView.font = UIFont.systemFont(ofSize: 17.0)
        textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        
        containerView = UIView.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: kShowAreaHeight))
        containerView.backgroundColor = .clear
//        containerView.backgroundColor = .orange
        containerView.alpha = 0
        addSubview(containerView)
        
        let picButton = UIButton(type: .system)
        picButton.frame = CGRect(x: 20, y: 15, width: 50, height: 50)
        picButton.setImage(UIImage(named: "sharemore_pic"), for: .normal)
        picButton.addTarget(self, action: #selector(action1(_:)), for: .touchUpInside)
        
        addSubview(leftButton)
        addSubview(rightButton)
        addSubview(textView)
        containerView.addSubview(picButton)
        
        if #available(iOS 13.0, *) {
            let dyColor1 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1)
                } else {
                    return UIColor.tertiarySystemBackground
                }
            }
            self.backgroundColor = dyColor1
            backgroundView.backgroundColor = dyColor1
            
            let dyColor2 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor.white
                } else {
                    return UIColor.secondarySystemBackground
                }
            }
            pressMic.backgroundColor = dyColor2
            
            let dyColor3 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor(red: 243/255.0, green: 244/255.0, blue: 245/255.0, alpha: 1)
                } else {
                    return UIColor.systemBackground
                }
            }
            textView.backgroundColor = dyColor3
            
        } else {
            // Fallback on earlier versions
            self.backgroundColor = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1)
            backgroundView.backgroundColor = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1)
            pressMic.backgroundColor = UIColor.white
            textView.backgroundColor = UIColor(red: 243/255.0, green: 244/255.0, blue: 245/255.0, alpha: 1)
        }
    }
    
    @objc func action1(_ button: UIButton) {
        if keyboardStatus != .BWLeft {
            leftButton.setImage(UIImage(named: "ToolViewKeyboard"), for: .normal)
            kLastTextViewFrame = textView.frame
            textView.isHidden = true
            var frame = textView.frame
            frame.size.height = 0
            textView.frame = frame
            
            leftButton.frame.origin.y = 15
            rightButton.frame.origin.y = 15
            
            self.containerView.alpha = 0
            keyboardStatus = .BWLeft
            showArea = false
            textView.resignFirstResponder()
            delegate?.leftButtonAction(self)
        }
        else if keyboardStatus == .BWLeft {
            leftButton.setImage(UIImage(named: "语音按钮"), for: .normal)
            textView.frame = kLastTextViewFrame
            textView.isHidden = false
            textView.becomeFirstResponder()

            leftButton.frame.origin.y = kLastTextViewFrame.size.height-30
            rightButton.frame.origin.y = kLastTextViewFrame.size.height-30
            
            keyboardStatus = .BWEditing
            showArea = false
            delegate?.textViewBeginEdit(textView)
        }
    }
    
    @objc func action2(_ button: UIButton) {
        if keyboardStatus != .BWRight {
            UIView.animate(withDuration: 0.25) {
                self.containerView.alpha = 1
            }
            textView.isHidden = false
            textView.frame = kLastTextViewFrame
            textView.resignFirstResponder()
            
            leftButton.frame.origin.y = kLastTextViewFrame.size.height-30
            rightButton.frame.origin.y = kLastTextViewFrame.size.height-30
            
            keyboardStatus = .BWRight
            delegate?.rightButtonAction(self)
        }
        else if keyboardStatus == .BWRight {
            textView.frame = kLastTextViewFrame
            textView.isHidden = false
            textView.becomeFirstResponder()

            leftButton.frame.origin.y = kLastTextViewFrame.size.height-30
            rightButton.frame.origin.y = kLastTextViewFrame.size.height-30
            
            keyboardStatus = .BWEditing
            showArea = false
            delegate?.textViewBeginEdit(textView)
        }
    }
    
    @objc private func longPressRecognized(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            pressMicLabel.text = "松开 结束"
            if #available(iOS 13.0, *) {
                let dyColor1 = UIColor { (trainCollection) -> UIColor in
                    if trainCollection.userInterfaceStyle == .light {
                        return UIColor(red: 246/255.0, green: 246/255.0, blue: 247/255.0, alpha: 1)
                    } else {
                        return UIColor.systemBackground
                    }
                }
                pressMic.backgroundColor = dyColor1
                
            } else {
                // Fallback on earlier versions
                pressMic.backgroundColor = UIColor.white
            }
        }
        else if sender.state == .changed {
            
        }
        else {
            pressMicLabel.text = "按住 说话"
            if #available(iOS 13.0, *) {
                let dyColor1 = UIColor { (trainCollection) -> UIColor in
                    if trainCollection.userInterfaceStyle == .light {
                        return UIColor.white
                    } else {
                        return UIColor.secondarySystemBackground
                    }
                }
                pressMic.backgroundColor = dyColor1
                
            } else {
                // Fallback on earlier versions
                pressMic.backgroundColor = UIColor.white
            }
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
            print("abcd ComposerView observeValue textView \(textView.frame.size.height) \(textView.contentSize.height) \(height)")
            var frame = textView.frame
            frame.size.height = height
            textView.frame = frame
            kLastTextViewFrame = frame
            
            leftButton.frame.origin.y = height-30
            rightButton.frame.origin.y = height-30
            containerView.frame.origin.y = leftButton.frame.origin.y+50
            delegate?.textViewTextChange(textView)
        }
        
        if object as AnyObject? === self.superview && keyPath == "center" {
            #if DEBUG
            let rect = self.superview!.frame
            let height = UIScreen.main.bounds.height-rect.minY-self.frame.height
            if keyboardStatus != .BWRight {
                delegate?.keyboardFrameChange(textView, keyBoardheight: height)
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
