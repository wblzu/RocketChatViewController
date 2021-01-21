//
//  BWComposerView.swift
//  TestKeyboard
//
//  Created by bw on 2021/1/6.
//

import UIKit
import Foundation
import AudioToolbox.AudioServices

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

public protocol BWComposerViewMultiMediaDelegate: class {
    // audio
    func recordButtonDidBegin()
    func recordButtonDidStop()
    func recordButtonDidCancel()
    
    // image
    func imagePickButtonDidBegin()
}

public protocol BWComposerViewSendTextDelegate: class {    
    func didPressSendButton(_ textView: UITextView)
}

public class BWComposerView: UIView {
    static let ObservingInputAccessoryViewFrameDidChangeNotification = "ObservingInputAccessoryViewFrameDidChangeNotification"
    
    public let kTextViewDefaultHeight: CGFloat = 44.0
    public let kTextViewMaxHeight: CGFloat = 122.0
    public let kShowAreaHeight: CGFloat = 100.0
    public var kLastTextViewFrame: CGRect = CGRect.zero
    
    public var textView: BWComposerTextView!
    
    public var containerView: UIView!
    public var leftButton: UIButton!
    public var rightButton: UIButton!
    public var recorderView: UIView!
    public var pressIndicatorLabel: UILabel!
    
     var cancelRecording: Bool = false
    
    public var keyboardStatus: BWKeyboardStatus = .BWEditing
    public var showArea: Bool = false
    
    public weak var delegate: BWComposerViewDelegate?
    public weak var multiMediaDelegate: BWComposerViewMultiMediaDelegate?
    public weak var sendTextDelegate: BWComposerViewSendTextDelegate?
    
    
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
        leftButton.addTarget(self, action: #selector(leftAction(_:)), for: .touchUpInside)
        
        rightButton = UIButton(type: .system)
        rightButton.frame = CGRect(x: UIScreen.main.bounds.width-45, y: 15, width: 35, height: 35)
        rightButton.setImage(UIImage(named: "发送文件"), for: .normal)
        rightButton.addTarget(self, action: #selector(rightAction(_:)), for: .touchUpInside)
        
        
        //
        recorderView = UIView.init(frame: CGRect(x: 50, y: 10, width: UIScreen.main.bounds.width-100, height: kTextViewDefaultHeight))
        recorderView.layer.cornerRadius = 10
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressRecognized(_:)))
        longPress.minimumPressDuration = 0.01
        recorderView.addGestureRecognizer(longPress)
        recorderView.isHidden = true
        addSubview(recorderView)
        
        pressIndicatorLabel = UILabel.init(frame: CGRect(x: 0, y: 0, width: recorderView.frame.size.width, height: recorderView.frame.size.height))
        pressIndicatorLabel.isUserInteractionEnabled = false
        pressIndicatorLabel.textAlignment = .center
        pressIndicatorLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        pressIndicatorLabel.text = "按住 说话"
        recorderView.addSubview(pressIndicatorLabel)
        
        
        //
        textView = BWComposerTextView.init(frame: CGRect(x: 50, y: 10, width: UIScreen.main.bounds.width-100, height: kTextViewDefaultHeight))
        textView.delegate = self
        textView.returnKeyType = .send
        textView.enablesReturnKeyAutomatically = true
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
        picButton.addTarget(self, action: #selector(pickImageAction(_:)), for: .touchUpInside)
        
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
                    return UIColor(red: 244/255.0, green: 244/255.0, blue: 247/255.0, alpha: 1)
                } else {
                    return UIColor.secondarySystemBackground
                }
            }
            recorderView.backgroundColor = dyColor2
            
            let dyColor3 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor(red: 244/255.0, green: 244/255.0, blue: 247/255.0, alpha: 1)
                } else {
                    return UIColor.systemBackground
                }
            }
            textView.backgroundColor = dyColor3
            
        } else {
            // Fallback on earlier versions
            self.backgroundColor = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1)
            backgroundView.backgroundColor = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1)
            recorderView.backgroundColor = UIColor(red: 244/255.0, green: 244/255.0, blue: 247/255.0, alpha: 1)
            textView.backgroundColor = UIColor(red: 244/255.0, green: 244/255.0, blue: 247/255.0, alpha: 1)
        }
    }
    
    @objc func leftAction(_ button: UIButton) {
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
            recorderView.isHidden = false
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
            recorderView.isHidden = true
            showArea = false
            delegate?.textViewBeginEdit(textView)
        }
    }
    
    @objc func rightAction(_ button: UIButton) {
        if keyboardStatus != .BWRight {
            UIView.animate(withDuration: 0.25) {
                self.containerView.alpha = 1
            }
            textView.isHidden = false
            textView.frame = kLastTextViewFrame
            textView.resignFirstResponder()
            
            leftButton.setImage(UIImage(named: "语音按钮"), for: .normal)
            leftButton.frame.origin.y = kLastTextViewFrame.size.height-30
            rightButton.frame.origin.y = kLastTextViewFrame.size.height-30
            
            keyboardStatus = .BWRight
            delegate?.rightButtonAction(self)
        }
        else if keyboardStatus == .BWRight {
            textView.frame = kLastTextViewFrame
            textView.isHidden = false
            textView.becomeFirstResponder()

            leftButton.setImage(UIImage(named: "语音按钮"), for: .normal)
            leftButton.frame.origin.y = kLastTextViewFrame.size.height-30
            rightButton.frame.origin.y = kLastTextViewFrame.size.height-30
            
            keyboardStatus = .BWEditing
            showArea = false
            delegate?.textViewBeginEdit(textView)
        }
    }
    
    @objc private func longPressRecognized(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if #available(iOS 13.0, *) {
                let dyColor1 = UIColor { (trainCollection) -> UIColor in
                    if trainCollection.userInterfaceStyle == .light {
                        return UIColor(red: 236/255.0, green: 236/255.0, blue: 239/255.0, alpha: 1)
                    } else {
                        return UIColor.systemBackground
                    }
                }
                recorderView.backgroundColor = dyColor1
                
            } else {
                // Fallback on earlier versions
                recorderView.backgroundColor = UIColor(red: 236/255.0, green: 236/255.0, blue: 239/255.0, alpha: 1)
            }
            
            pressIndicatorLabel.text = "松开 发送"
            
            let peek = SystemSoundID(1519)
            AudioServicesPlaySystemSoundWithCompletion(peek, {
            })
            cancelRecording = false
            self.multiMediaDelegate?.recordButtonDidBegin()
            
        }
        else if sender.state == .changed {
            let point = sender.location(in: self.recorderView)
            if self.recorderView.point(inside: point, with: nil) {
                cancelRecording = false
                pressIndicatorLabel.text = "松开 发送"
            } else {
                // cancel recording
                cancelRecording = true
                pressIndicatorLabel.text = "上滑 取消"
            }
            
        }
        else {
            if #available(iOS 13.0, *) {
                let dyColor1 = UIColor { (trainCollection) -> UIColor in
                    if trainCollection.userInterfaceStyle == .light {
                        return UIColor(red: 244/255.0, green: 244/255.0, blue: 247/255.0, alpha: 1)
                    } else {
                        return UIColor.secondarySystemBackground
                    }
                }
                recorderView.backgroundColor = dyColor1
                
            } else {
                // Fallback on earlier versions
                recorderView.backgroundColor = UIColor(red: 244/255.0, green: 244/255.0, blue: 247/255.0, alpha: 1)
            }
            
            pressIndicatorLabel.text = "按住 说话"
            if cancelRecording {
                self.multiMediaDelegate?.recordButtonDidCancel()
            } else {
                self.multiMediaDelegate?.recordButtonDidStop()
            }
        }
    }
    
    @objc func pickImageAction(_ button: UIButton) {
        self.multiMediaDelegate?.imagePickButtonDidBegin()
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
            debugPrint("abcd ComposerView observeValue textView \(textView.frame.size.height) \(textView.contentSize.height) \(height)")
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
            debugPrint("observeValue self.superview!.frame.origin.y \(rect.origin.y) \(height)")
            #endif
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        debugPrint("abcd layoutSubviews textView.frame.size.height=\(textView.frame.size.height) \(textView.contentSize.height)")
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
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sendTextDelegate?.didPressSendButton(textView)
            return false
        }
        
        return true
    }
}
