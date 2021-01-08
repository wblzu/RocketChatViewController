//
//  RocketChatViewController.swift
//  RocketChatViewController Example
//
//  Created by Rafael Kellermann Streit on 30/07/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import UIKit
import DifferenceKit

public extension UICollectionView {
    public func dequeueChatCell(withReuseIdentifier reuseIdetifier: String, for indexPath: IndexPath) -> ChatCell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: reuseIdetifier, for: indexPath) as? ChatCell else {
            fatalError("Trying to dequeue a reusable UICollectionViewCell that doesn't conforms to BindableCell protocol")
        }

        return cell
    }
}

/**
    A type-erased ChatCellViewModel that must conform to the Differentiable protocol.

    The `AnyChatCellViewModel` type forwards equality comparisons and utilities operations or properties
    such as relatedReuseIdentifier to an underlying differentiable value,
    hiding its specific underlying type.
 */

public struct AnyChatItem: ChatItem, Differentiable {
   public var relatedReuseIdentifier: String {
        return base.relatedReuseIdentifier
    }

    public let base: ChatItem
    public let differenceIdentifier: AnyHashable

    let isUpdatedFrom: (AnyChatItem) -> Bool

    public init<D: Differentiable & ChatItem>(_ base: D) {
        self.base = base
        self.differenceIdentifier = AnyHashable(base.differenceIdentifier)

        self.isUpdatedFrom = { source in
            guard let sourceBase = source.base as? D else { return false }
            return base.isContentEqual(to: sourceBase)
        }
    }

    public func isContentEqual(to source: AnyChatItem) -> Bool {
        return isUpdatedFrom(source)
    }
}

/**
    A type-erased SectionController.

    The `AnySectionController` type forwards equality comparisons and servers as a data source
    for RocketChatViewController to build one section, hiding its specific underlying type.
 */

public struct AnyChatSection: ChatSection {
    
    public weak var controllerContext: UIViewController? {
        get {
            return base.controllerContext
        }

        set(newControllerContext) {
            base.controllerContext = newControllerContext
        }
    }

    public var object: AnyDifferentiable {
        return base.object
    }

    public var base: ChatSection

    public init<D: ChatSection>(_ base: D) {
        self.base = base
    }
    
    public func viewModels() -> [AnyChatItem] {
        return base.viewModels()
    }

    public func cell(for viewModel: AnyChatItem, on collectionView: UICollectionView, at indexPath: IndexPath) -> ChatCell {
        return base.cell(for: viewModel, on: collectionView, at: indexPath)
    }
}

extension AnyChatSection: Differentiable {
    public var differenceIdentifier: AnyHashable {
        return AnyHashable(base.object.differenceIdentifier)
    }

    public func isContentEqual(to source: AnyChatSection) -> Bool {
        return base.object.isContentEqual(to: source.object)
    }
}

/**
    The responsible for implementing the data source of a single section
    which represents an object splitted into differentiable view models
    each one being binded on a reusable UICollectionViewCell that get updated when there's
    something to update on its content.

    A SectionController is also responsible for handling the actions
    and interactions with the object related to it.

    A SectionController's object is meant to be immutable.
 */

public protocol ChatSection {
    var object: AnyDifferentiable { get }
    var controllerContext: UIViewController? { get set }
    func viewModels() -> [AnyChatItem]
    func cell(for viewModel: AnyChatItem, on collectionView: UICollectionView, at indexPath: IndexPath) -> ChatCell
}

/**
    A single split of an object that binds an UICollectionViewCell and can be differentiated.

    A ChatCellViewModel also holds the related UICollectionViewCell's reuseIdentifier.
 */

public protocol ChatItem {
    var relatedReuseIdentifier: String { get }
}

public extension ChatItem where Self: Differentiable {
    // In order to use a ChatCellViewModel along with a SectionController
    // we must use it as a type-erased ChatCellViewModel, which in this case also means
    // that it must conform to the Differentiable protocol.
    public var wrapped: AnyChatItem {
        return AnyChatItem(self)
    }
}

/**
    A protocol that must be implemented by all cells to padronize the way we bind the data on its view.
 */

public protocol ChatCell {
    var messageWidth: CGFloat { get set }
    var viewModel: AnyChatItem? { get set }
    var indexPath: IndexPath? { get set }
    func configure(completeRendering: Bool)
}

public protocol ChatDataUpdateDelegate: class {
    func didUpdateChatData(newData: [AnyChatSection], updatedItems: [AnyHashable])
}

/**
    RocketChatViewController is basically a UIViewController that holds
    two key components: a list and a message composer.

    The whole idea is to keep the list as close as possible to a regular UICollectionView,
    but with some features and add-ons to make it more "chat friendly" in the point of view of
    performance, modularity and flexibility.

    To solve modularity (and help with performance) we've created a set of protocols
    and wrappers that ensure that we treat each object as a section of our list
    then break it down as much as possible into subobjects that can be differentiated.

    Bringing it to the chat concept, each message is a section, each section can have one
    or more items, it will depend on the complexity of each message. For example, if it's a simple
    text-only message we can represent it using a single reusable cell for this message's section,
    on the other hand if the message has attachments or multimedia content, it's better to
    split the most basic components of a message (avatar, username and text) into a reusable cell
    and the multimedia content (video, image, link preview, etc) into other reusable cells. This
    way we will wind up with simpler cells that cost less to reuse.

    To solve performance our main efforts are concentrated on updating the views the least
    possible. In order to do that we rely on a third-party (awesome) diffing library
    called DifferenceKit. Based on the benchmarks provided on its GitHub page it is the most
    performatic diffing library available for iOS development now. DifferenceKit also provides a
    UICollectionView extension that performs batch updates based on a changeset making sure that
    only the items that changed are going to be refreshed. On top of DifferenceKit's reloading
    we've implemented a simple operation queue to guarantee that no more than one reload will run
    at once.

    To solve flexibility we thought a lot on how to do the things above but yet keep it a regular
    UICollectionView for those who just want to implement their own list, and we decided that we would
    manage the UICollectionViewDataSource through a public `data` property that reflects on a private `internalData`
    property. This way on a subclass of RocketChatViewController we just need to process the data and set to the `data`
    property that the superclass implementation will handle the data source and will be able to apply the custom reload
    method managed by our operation queue. On the other hand, if anyone wants to implement their message list without
    having to conform to DifferenceKit and our protocols, he just need to override the UICollectionViewDataSource methods
    and provide a custom implementation.

    Minor features:
    - Inverted mode
    - Self-sizing cells support

 */

open class RocketChatViewController: UICollectionViewController {
    open var composerHeightConstraint: NSLayoutConstraint!
//    open var composerView = ComposerView()
    open var composerView = BWComposerView()

    open override var inputAccessoryView: UIView? {
        guard presentedViewController?.isBeingDismissed != false else {
            return nil
        }
        
        composerView.delegate = self
        
        composerView.layoutMargins = view.layoutMargins
        composerView.directionalLayoutMargins = systemMinimumLayoutMargins
        return composerView
    }

    open override var canBecomeFirstResponder: Bool {
        return true
    }
    
    private var internalData: [ArraySection<AnyChatSection, AnyChatItem>] = []

    open weak var dataUpdateDelegate: ChatDataUpdateDelegate?
    private let updateDataQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInteractive
        operationQueue.underlyingQueue = DispatchQueue.main
        return operationQueue
    }()

//    open var isInverted = true {
    open var isInverted = false {// invert(倒置) or not, default is not
        didSet {
            DispatchQueue.main.async {
                if self.isInverted != oldValue {
                    self.collectionView?.transform = self.isInverted ? self.invertedTransform : self.regularTransform
                    self.collectionView?.reloadData()
                }
            }
        }
    }
    
    open var isSelfSizing = false

    fileprivate let kEmptyCellIdentifier = "kEmptyCellIdentifier"

    open var keyboardHeight: CGFloat = 0.0
    open var keyboardDown: Bool = false
    
    open var willDisappear: Bool = false
    var adjustContentSize: Bool = false
    open var adjustContentOffset: Bool = true
    var intersectionHeight: CGFloat = 0.0 {
        didSet {
            if intersectionHeight != oldValue {
                adjustContentSize = true
            }
        }
    }

    private let invertedTransform = CGAffineTransform(scaleX: 1, y: -1)
    private let regularTransform = CGAffineTransform(scaleX: 1, y: 1)

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupChatViews()
        registerObservers()
        startObservingKeyboard()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: composerView.textView
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(composerViewTextViewShouldBeginEditing),
            name: Notification.Name("ComposerViewTextViewShouldBeginEditing"),
            object: nil
        )
    }

    @objc func composerViewTextViewShouldBeginEditing(_ notification: Notification) {
        self.adjustContentOffset = true
        print("aaaaaa contentsize composerViewTextViewShouldBeginEditing adjustContentOffset = \(adjustContentOffset)")
    }
    @objc func textDidChange() {
        self.adjustContentOffset = true
        print("aaaaaa contentsize textDidChange adjustContentOffset = \(adjustContentOffset)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UITextView.textDidChangeNotification,
            object: composerView.textView
        )
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name("ComposerViewTextViewShouldBeginEditing"),
            object: nil
        )
    }


    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        willDisappear = false
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        willDisappear = true
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.keyboardHeight = 0
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

    }
    

    func registerObservers() {
        view.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
    }

    func setupChatViews() {
        guard let collectionView = collectionView else {
            return
        }

        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: kEmptyCellIdentifier)

        collectionView.collectionViewLayout = UICollectionViewFlowLayout()
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true

        collectionView.transform = isInverted ? invertedTransform : collectionView.transform

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.keyboardDismissMode = .interactive
//        collectionView.contentInsetAdjustmentBehavior = isInverted ? .never : .always
        // important. if .always, collectionView will automatic adjust it's contentinset
        collectionView.contentInsetAdjustmentBehavior = .never

        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout, isSelfSizing {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
    
    open func updateData(with target: [ArraySection<AnyChatSection, AnyChatItem>]) {

    }

    func updatedItems(from data: [ArraySection<AnyChatSection, AnyChatItem>], with changes: Changeset<[ArraySection<AnyChatSection, AnyChatItem>]>?) -> [AnyHashable] {
        guard let changes = changes else {
            return []
        }

        var updatedItems = [AnyHashable]()

        changes.elementUpdated.forEach { item in
            let section = data[item.section]
            let elementId = section.elements[item.element].differenceIdentifier
            updatedItems.append(elementId)
        }

        changes.elementDeleted.forEach { item in
            let section = data[item.section]
            let elementId = section.elements[item.element].differenceIdentifier
            updatedItems.append(elementId)
        }

        return updatedItems
    }
}

// MARK: Content Adjustment

extension RocketChatViewController {

    fileprivate func adjustContentInsetIfNeeded() {
        guard let collectionView = collectionView else { return }

        var contentInset = UIEdgeInsets.zero

        if isInverted {
            //
        } else {
            contentInset.bottom = keyboardHeight+composerView.frame.size.height
        }

        collectionView.contentInset = contentInset
        collectionView.scrollIndicatorInsets = contentInset
        
        print("aaaaaa contentsize adjustContentInsetIfNeeded \(willDisappear) \(keyboardHeight) \(contentInset.bottom) \(composerView.frame.size.height)")
    }
}


extension RocketChatViewController: UICollectionViewDelegateFlowLayout {
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .zero
    }
}


extension RocketChatViewController {
    func startObservingKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_onKeyboardFrameWillChangeNotificationReceived(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func _onKeyboardFrameWillChangeNotificationReceived(_ notification: Notification) {
        guard presentedViewController?.isBeingDismissed != false else {
            return
        }
        
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let collectionView = collectionView
        else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 0, dy: -additionalSafeAreaInsets.top)
        let intersection = safeAreaFrame.intersection(keyboardFrameInView)

//        let animationDuration: TimeInterval = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
//        let animationCurveRawNSN = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
//        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
//        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw)
//
//        guard intersection.height != self.keyboardHeight else {
//            print("aaaaaa contentsize keyboardFrame.height return")
//            return
//        }

//        print("aaaaaa contentsize keyboardFrame.height = \(keyboardFrame.height)\n intersection.height = \(intersection.height)\n composerView.frame.size.height = \(composerView.frame.size.height)\n view.safeAreaInsets.bottom = \(view.safeAreaInsets.bottom)\n intersection.height+view.safeAreaInsets.bottom-composerView.frame.size.height = \(intersection.height+view.safeAreaInsets.bottom-composerView.frame.size.height)\n self.keyboardHeight before = \(self.keyboardHeight)\n adjustContentSize = \(adjustContentSize)\n adjustContentOffset = \(adjustContentOffset)\n")
        print("aaaaaa contentsize _onKeyboardFrameWillChangeNotificationReceived adjustContentSize = \(adjustContentSize) adjustContentOffset = \(adjustContentOffset) \(intersection.height)")
        
        intersectionHeight = intersection.height
        
        if intersection.height+view.safeAreaInsets.bottom-composerView.frame.size.height == self.keyboardHeight {
            if !adjustContentSize {
                print("aaaaaa contentsize _onKeyboardFrameWillChangeNotificationReceived return adjustContentSize = \(adjustContentSize)")
                return
            }
        }

        if !willDisappear {
//            self.keyboardHeight = keyboardFrame.height-composerView.frame.size.height
            self.keyboardHeight = intersection.height+view.safeAreaInsets.bottom-composerView.frame.size.height
            adjustContentSize = false
            
            var contentOffset = CGPoint(x: 0, y: 0)
            if collectionView.contentSize.height == 0 {
                adjustContentInsetIfNeeded()
                contentOffset.y = keyboardHeight+composerView.frame.size.height
                collectionView.setContentOffset(contentOffset, animated: false)
                print("aaaaaa contentsize _onKeyboardFrameWillChangeNotificationReceived contentSize.height == 0 currentoffsety \(collectionView.contentOffset.y)")
            }
            else if collectionView.contentSize.height < collectionView.frame.size.height-keyboardHeight-composerView.frame.size.height {
                print("aaaaaa contentsize _onKeyboardFrameWillChangeNotificationReceived contentSize.height < ")
            }
            else {
                adjustContentInsetIfNeeded()
                if self.adjustContentOffset == true {
                    contentOffset.y = collectionView.contentSize.height-collectionView.frame.size.height+keyboardHeight+composerView.frame.size.height
                    collectionView.setContentOffset(contentOffset, animated: false)
                    self.adjustContentOffset = false
                    print("aaaaaa contentsize _onKeyboardFrameWillChangeNotificationReceived contentSize.height == 0 else adjustContentOffset completed and adjustContentOffset = \(adjustContentOffset)")
                }
            }
            
            print("aaaaaa contentsize _onKeyboardFrameWillChangeNotificationReceived \(collectionView.contentSize.height) \(collectionView.frame.size.height) \(keyboardHeight) \(composerView.frame.size.height)")
        }
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as AnyObject === view, keyPath == "frame" {
            guard let window = UIApplication.shared.keyWindow else {
                return
            }

//            composerView.containerViewLeadingConstraint.constant = window.bounds.width - view.bounds.width
        }
    }
}



extension RocketChatViewController: BWComposerViewDelegate {
    
    public func keyboardFrameChangeByDrag(_ textView: UITextView, keyBoardheight: CGFloat) {
        guard let inputAccessoryView = self.inputAccessoryView,
              let constraint = self.inputAccessoryView?.constraints[0]
              else {
            return
        }
        
        let targetHeight = (textView.contentSize.height <= 44 ? 44 : textView.contentSize.height)+view.safeAreaInsets.bottom+20
        let changeValue = targetHeight-keyBoardheight
        if keyBoardheight <= view.safeAreaInsets.bottom {
            print("abcde keyboardFrameChangeByDrag drag normal \(keyBoardheight) \(changeValue)")
            constraint.constant = min(changeValue, targetHeight)
        }
        else { // keyboard drag Up too fast
            print("abcde keyboardFrameChangeByDrag drag up too fast \(keyBoardheight) \(changeValue)")
            constraint.constant = targetHeight-view.safeAreaInsets.bottom
        }
    }
    
    public func textViewTextChange(_ textView: UITextView) {
        guard let inputAccessoryView = self.inputAccessoryView,
              let constraint = self.inputAccessoryView?.constraints[0]
              else {
            return
        }
        constraint.constant = min(140, (textView.contentSize.height <= 44 ? 44 : textView.contentSize.height)+view.safeAreaInsets.bottom+20)
        inputAccessoryView.superview?.layoutIfNeeded()
    }
    
    public func textViewBeginEdit(_ textView: UITextView) {
        guard let inputAccessoryView = self.inputAccessoryView,
              let constraint = self.inputAccessoryView?.constraints[0]
              else {
            return
        }
        self.adjustContentOffset = true
        constraint.constant = min(140, (textView.contentSize.height <= 44 ? 44 : textView.contentSize.height)+20)
        inputAccessoryView.superview?.layoutIfNeeded()
    }
    
    public func leftButtonAction(_ composerView: BWComposerView) {
        guard let inputAccessoryView = self.inputAccessoryView,
              let constraint = self.inputAccessoryView?.constraints[0]
              else {
            return
        }
        constraint.constant = 64+view.safeAreaInsets.bottom
        inputAccessoryView.superview?.layoutIfNeeded()
    }
    
    public func rightButtonAction(_ composerView: BWComposerView) {
        guard let inputAccessoryView = self.inputAccessoryView,
              let constraint = self.inputAccessoryView?.constraints[0]
              else {
            return
        }
        constraint.constant = 150
        inputAccessoryView.superview?.layoutIfNeeded()
        
        adjustContentInsetIfNeeded()
        var contentOffset = CGPoint(x: 0, y: 0)
        contentOffset.y = collectionView.contentSize.height-collectionView.frame.size.height+keyboardHeight+composerView.frame.size.height
        collectionView.setContentOffset(contentOffset, animated: false)
        self.adjustContentOffset = false
    }
}
