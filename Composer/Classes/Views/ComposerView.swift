//
//  ComposerView.swift
//  RocketChatViewController Example
//
//  Created by Matheus Cardoso on 9/5/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import UIKit
import NotificationCenter

/**
 An enum that represents a place in the composer view where an addon is placed.
 */
public enum ComposerAddonSlot {
    /**
     When the addon represents something in the message (eg. attached media)
     */
    case component

    /**
     When the addon represents a utility to the composer (eg. hint view)
     */
    case utility
}

/*
 A default composer view delegate with fallback behaviors.
 */
private class ComposerViewFallbackDelegate: ComposerViewDelegate { }

// MARK: Initializers
public class ComposerView: UIView, ComposerLocalizable {
    static let ObservingInputAccessoryViewFrameDidChangeNotification = "ObservingInputAccessoryViewFrameDidChangeNotification"
    
    /**
     The object that acts as the delegate of the composer.
     */
    public weak var delegate: ComposerViewDelegate?

    /**
     A fallback delegate for when delegate is nil.
     */
    private var fallbackDelegate = ComposerViewFallbackDelegate()

    /**
     Returns the delegate if set, if not, returns the default delegate.

     Delegate should only be accessed inside this class via this computed property.
     */
    private var currentDelegate: ComposerViewDelegate {
        return delegate ?? fallbackDelegate
    }

    /**
     The view that contains all subviews
     */
    public let containerView = tap(UIView()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            let dyColor1 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor.white
                } else {
                    return UIColor.tertiarySystemBackground
                }
            }
            $0.backgroundColor = dyColor1
            
        } else {
            // Fallback on earlier versions
            $0.backgroundColor = .white
        }
    }

    /**
     The button that stays in the left side of the composer.
     */
    public let leftButton = tap(ComposerButton()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setBackgroundImage(ComposerAssets.micButtonImage, for: .normal)

        $0.addTarget(self, action: #selector(touchUpInsideButton), for: .touchUpInside)
        $0.addTarget(self, action: #selector(touchUpOutsideButton), for: .touchUpOutside)
        $0.addTarget(self, action: #selector(touchDownInButton), for: .touchDown)
        $0.addTarget(self, action: #selector(touchDragInsideButton), for: .touchDragInside)
        $0.addTarget(self, action: #selector(touchDragOutsideButton), for: .touchDragOutside)

        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    /**
     The button that stays in the right side of the composer.
     */
    public let rightButton = tap(ComposerButton()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setBackgroundImage(ComposerAssets.addButtonImage, for: .normal)

        $0.addTarget(self, action: #selector(touchUpInsideButton), for: .touchUpInside)
        $0.addTarget(self, action: #selector(touchUpOutsideButton), for: .touchUpOutside)
        $0.addTarget(self, action: #selector(touchDownInButton), for: .touchDown)
        $0.addTarget(self, action: #selector(touchDragInsideButton), for: .touchDragInside)
        $0.addTarget(self, action: #selector(touchDragOutsideButton), for: .touchDragOutside)

        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    /**
     The text view used to compose the message.
     */
    public let textView = tap(ComposerTextView()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
    
        $0.text = ""
        $0.placeholderLabel.text = localized(.textViewPlaceholder)
        $0.placeholderLabel.font = .preferredFont(forTextStyle: .body)
        $0.placeholderLabel.adjustsFontForContentSizeCategory = true

        $0.font = .preferredFont(forTextStyle: .body)
        $0.adjustsFontForContentSizeCategory = true
        
        if #available(iOS 13.0, *) {
            let dyColor1 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor(red: 243/255.0, green: 244/255.0, blue: 245/255.0, alpha: 1)
                } else {
                    return UIColor.systemBackground
                }
            }
            $0.backgroundColor = dyColor1
            
            let dyColor2 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor(red: 156/255.0, green: 162/255.0, blue: 168/255.0, alpha: 1)
                } else {
                    return UIColor.placeholderText
                }
            }
            $0.placeholderLabel.textColor = dyColor2
            
        } else {
            // Fallback on earlier versions
            $0.backgroundColor = UIColor(red: 243/255.0, green: 244/255.0, blue: 245/255.0, alpha: 1)
            $0.placeholderLabel.textColor = UIColor(red: 156/255.0, green: 162/255.0, blue: 168/255.0, alpha: 1)
        }
    }

    /**
     The view that contains component addons on top of the text (eg. attached media)
     */
    public let componentStackView = tap(ComposerAddonStackView()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
    }

    /**
     The separator line on top of the composer
     */
    public let topSeparatorView = tap(UIView()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            let dyColor1 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return UIColor(red: 225/255.0, green: 229/255.0, blue: 232/255.0, alpha: 1)
                } else {
                    return UIColor.secondarySystemBackground
                }
            }
            $0.backgroundColor = dyColor1
            
        } else {
            // Fallback on earlier versions
            $0.backgroundColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9098039216, alpha: 1)
        }

        NSLayoutConstraint.activate([
            $0.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    /**
     The view that contains utility addons on top of the composer (eg. hint view)
     */
    public let utilityStackView = tap(ComposerAddonStackView()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    /**
     The view that overlays the composer when showOverlay is called.
     */
    public let overlayView = tap(OverlayView()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isHidden = true
    }
    
    public let keyboardBackgroundView = tap(UIView()) {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .red
        if #available(iOS 13.0, *) {
            let dyColor1 = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .light {
                    return .white
                } else {
                    return UIColor.tertiarySystemBackground
                }
            }
            $0.backgroundColor = dyColor1
            
        } else {
            // Fallback on earlier versions
            $0.backgroundColor = .white
        }
        let btn2 = UIButton(type: .system)
        btn2.setTitle("你好", for: .normal)
        btn2.setTitleColor(.black, for: .normal)
        btn2.tintColor = UIColor.black
        btn2.frame = CGRect(x: 20, y: 20, width: 80, height: 40)
        btn2.addTarget(self, action: #selector(action2), for: .touchUpInside)
        $0.addSubview(btn2)
    }
    
    @objc func action2() {
        print("hello, action2")
    }

    /**
     A Boolean value that indicates whether text can change in the textView
     */
    public var isTextInputEnabled = true

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: super.intrinsicContentSize.width, height: containerView.bounds.height)
    }

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

    /**
     Shared initialization procedures.
     */
    public func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false

        leftButton.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)

        textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        textView.delegate = self

        containerView.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)

        addSubviews()
        setupConstraints()
    }

    /**
     Adds buttons and other UI elements as subviews.
     */
    private func addSubviews() {
        addSubview(keyboardBackgroundView)
        addSubview(containerView)

        containerView.addSubview(leftButton)
        containerView.addSubview(rightButton)
        containerView.addSubview(textView)
        containerView.addSubview(componentStackView)
        containerView.addSubview(topSeparatorView)
        containerView.addSubview(utilityStackView)
        containerView.addSubview(overlayView)
        
        // constraint for keyboardBackgroundView
        NSLayoutConstraint.activate([
            keyboardBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 49),
            keyboardBackgroundView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            keyboardBackgroundView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            keyboardBackgroundView.heightAnchor.constraint(equalToConstant: 288)
        ])
    }

    // MARK: Constraints

//    lazy var textViewLeadingConstraint: NSLayoutConstraint = {
//        textView.leadingAnchor.constraint(equalTo: leftButton.trailingAnchor, constant: 0)
//    }()

    lazy var containerViewLeadingConstraint: NSLayoutConstraint = {
        containerView.leadingAnchor.constraint(equalTo: leadingAnchor)
    }()
    
    public lazy var containerViewBottomConstraint: NSLayoutConstraint = {
        return containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
    }()

    /**
     Sets up constraints between the UI elements in the composer.
     */
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // containerView constraints

            containerViewLeadingConstraint,
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerViewBottomConstraint,

            // utilityStackView constraints

            utilityStackView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            utilityStackView.widthAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.widthAnchor),
            utilityStackView.centerXAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerXAnchor),
            utilityStackView.bottomAnchor.constraint(equalTo: topSeparatorView.topAnchor),

            // topSeparatorView constraints

            topSeparatorView.widthAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.widthAnchor),
            topSeparatorView.centerXAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerXAnchor),
            topSeparatorView.bottomAnchor.constraint(equalTo: componentStackView.topAnchor),

            // componentStackView constraints

            componentStackView.topAnchor.constraint(equalTo: topSeparatorView.bottomAnchor),
            componentStackView.widthAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.widthAnchor),
            componentStackView.centerXAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerXAnchor),
            componentStackView.bottomAnchor.constraint(equalTo: textView.topAnchor, constant: -10),

            // textView constraints

            textView.leadingAnchor.constraint(equalTo: leftButton.trailingAnchor, constant: 10),
            textView.trailingAnchor.constraint(equalTo: rightButton.leadingAnchor, constant: -10),
            textView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -layoutMargins.bottom),

            // rightButton constraints

            rightButton.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor, constant: -layoutMargins.right*2+5),
            rightButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant:  -layoutMargins.bottom*2),

            // leftButton constraints

            leftButton.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor, constant: layoutMargins.left*2-5),
            leftButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -layoutMargins.bottom*2),

            // overlayView constraints

            overlayView.topAnchor.constraint(equalTo: topSeparatorView.bottomAnchor),
            overlayView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        
        print("aaaaaa textView.frame.size.height=\(textView.frame.size.height)")
        if textView.frame.size.height <= 44 {
            textView.layer.cornerRadius = textView.frame.size.height/2
        }
        else {
            textView.layer.cornerRadius = 10
        }
        textView.layer.masksToBounds = true
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.layoutManager.allowsNonContiguousLayout = false
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        superview?.removeObserver(self, forKeyPath: "center")
        
        newSuperview?.addObserver(self, forKeyPath: "center", options: [.old, .new], context: nil)

        reloadAddons()
        configureButtons()
    }
    
    deinit {
        superview?.removeObserver(self, forKeyPath: "center")
    }

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in self.subviews {
            if view.isUserInteractionEnabled, view.point(inside: self.convert(point, to: view), with: event) {
                return true
            }
        }

        return false
    }

    
}

// MARK: Overlay

public extension ComposerView {
    func showOverlay(userData: Any? = nil) {
        overlayView.isHidden = false

        leftButton.isUserInteractionEnabled = false
        rightButton.isUserInteractionEnabled = false
        isTextInputEnabled = false

        currentDelegate.composerView(self, willConfigureOverlayView: overlayView, with: userData)
        currentDelegate.composerView(self, didConfigureOverlayView: overlayView)
    }

    func hideOverlay() {
        overlayView.isHidden = true

        leftButton.isUserInteractionEnabled = true
        rightButton.isUserInteractionEnabled = true
        isTextInputEnabled = true
    }
}

// MARK: Buttons

public extension ComposerView {
    func configureButtons() {
        currentDelegate.composerView(self, willConfigureButton: leftButton)
        currentDelegate.composerView(self, willConfigureButton: rightButton)
    }
}

// MARK: Addons

public extension ComposerView {
    func reloadAddons() {
        [
            (componentStackView, ComposerAddonSlot.component),
            (utilityStackView, ComposerAddonSlot.utility)
        ].forEach { (stackView, slot) in
            stackView.subviews.forEach {
                stackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }

            for index in 0..<currentDelegate.numberOfAddons(in: self, at: slot) {
                if let addon = currentDelegate.composerView(self, addonAt: slot, index: index) {
                    let addonView: UIView = addon.viewType.init()
                    addonView.frame = stackView.frame
                    stackView.addArrangedSubview(addonView)

                    currentDelegate.composerView(self, didUpdateAddonView: addonView, at: slot, index: index)
                } else {
                    currentDelegate.composerView(self, didUpdateAddonView: nil, at: slot, index: index)
                }
            }
        }
    }
}

// MARK: Observers, Gestures & Actions

public extension ComposerView {
    /**
     Called when the content size of the text view changes and adjusts the composer height constraint.
     */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as AnyObject? === self.superview && keyPath == "center" {
            #if DEBUG
            let rect = self.superview!.frame
            let height = UIScreen.main.bounds.height-rect.minY-self.frame.height
            print("observeValue self.superview!.frame.origin.y \(rect.origin.y) \(height)")
            #endif
        }
        
        
        if object as AnyObject? === leftButton && keyPath == "bounds" {
            if leftButton.isHidden {
                textView.leadingAnchor.constraint(equalTo: leftButton.trailingAnchor, constant: 0)
            }
            else {
                textView.leadingAnchor.constraint(equalTo: leftButton.trailingAnchor, constant: layoutMargins.left-5)
            }
        }

        if object as AnyObject? === containerView && keyPath == "bounds" {
            self.invalidateIntrinsicContentSize()
            self.superview?.setNeedsLayout()
        }

        if object as AnyObject? === textView && keyPath == "contentSize" {
            textView.invalidateIntrinsicContentSize()
            self.superview?.layoutIfNeeded()
        }
    }

    /**
     Called when a touchUpInside event happens in one of the buttons.
     */
    @objc private func touchUpInsideButton(_ button: ComposerButton, _ event: UIEvent) {
        currentDelegate.composerView(self, event: event, eventType: .touchUpInside, happenedInButton: button)
    }

    /**
     Called when a touchUpOutside event happens in one of the buttons.
     */
    @objc private func touchUpOutsideButton(_ button: ComposerButton, _ event: UIEvent) {
        currentDelegate.composerView(self, event: event, eventType: .touchUpOutside, happenedInButton: button)
    }

    /**
     Called when a touchDown event happens in one of the buttons.
     */
    @objc private func touchDownInButton(_ button: ComposerButton, _ event: UIEvent) {
        currentDelegate.composerView(self, event: event, eventType: .touchDown, happenedInButton: button)
    }

    /**
     Called when a touchDragInside event happens in one of the buttons.
     */
    @objc private func touchDragInsideButton(_ button: ComposerButton, _ event: UIEvent) {
        currentDelegate.composerView(self, event: event, eventType: .touchDragInside, happenedInButton: button)
    }

    /**
     Called when a touchDragOutside event happens in one of the buttons.
     */
    @objc private func touchDragOutsideButton(_ button: ComposerButton, _ event: UIEvent) {
        currentDelegate.composerView(self, event: event, eventType: .touchDragOutside, happenedInButton: button)
    }
}

// MARK: UITextView Delegate
extension ComposerView: UITextViewDelegate {
    public func textViewDidChangeSelection(_ textView: UITextView) {
        currentDelegate.composerViewDidChangeSelection(self)
        return
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard isTextInputEnabled else {
            return false
        }

        if text == "\n" {
            return currentDelegate.composerViewShouldReturn(self)
        }

        return true
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        containerViewBottomConstraint.constant = 0
        print("ComposerView textViewShouldBeginEditing")
        NotificationCenter.default.post(name: Notification.Name("ComposerViewTextViewShouldBeginEditing"), object: nil)
        return true
    }
}
