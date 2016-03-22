//  XLActionController.swift
//  XLActionController ( https://github.com/xmartlabs/XLActionController )
//
//  Copyright (c) 2015 Xmartlabs ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit

// MARK: - Section class

public class Section<ActionDataType, SectionHeaderDataType> {
    
    public var data: SectionHeaderDataType? {
        get { return _data?.data }
        set { _data = RawData(data: newValue) }
    }
    public var actions = [Action<ActionDataType>]()
    private var _data: RawData<SectionHeaderDataType>?

    public init() {}
}

// MARK: - Enum definitions

public enum CellSpec<CellType: UICollectionViewCell, CellDataType> {
    
    case NibFile(nibName: String, bundle: NSBundle?, height:((CellDataType)-> CGFloat))
    case CellClass(height:((CellDataType)-> CGFloat))
    
    public var height: ((CellDataType) -> CGFloat) {
        switch self {
        case .CellClass(let heightCallback):
            return heightCallback
        case .NibFile(_, _, let heightCallback):
            return heightCallback
        }
    }
}

public enum HeaderSpec<HeaderType: UICollectionReusableView, HeaderDataType> {
    
    case NibFile(nibName: String, bundle: NSBundle?, height:((HeaderDataType) -> CGFloat))
    case CellClass(height:((HeaderDataType) -> CGFloat))
    
    public var height: ((HeaderDataType) -> CGFloat) {
        switch self {
        case .CellClass(let heightCallback):
            return heightCallback
        case .NibFile(_, _, let heightCallback):
            return heightCallback
        }
    }
}

private enum ReusableViewIds: String {
    case Cell = "Cell"
    case Header = "Header"
    case SectionHeader = "SectionHeader"
}

// MARK: - Row class

final class RawData<T> {
    var data: T!
    
    init?(data: T?) {
        guard let data = data else { return nil }
        self.data = data
    }
}

// MARK: - ActionController class

public class ActionController<ActionViewType: UICollectionViewCell, ActionDataType, HeaderViewType: UICollectionReusableView, HeaderDataType, SectionHeaderViewType: UICollectionReusableView, SectionHeaderDataType>: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
 
    // MARK - Public properties
    
    public var headerData: HeaderDataType? {
        set { _headerData = RawData(data: newValue) }
        get { return _headerData?.data }
    }

    public var settings: ActionControllerSettings = ActionControllerSettings.defaultSettings()
    
    public var cellSpec: CellSpec<ActionViewType, ActionDataType>
    public var sectionHeaderSpec: HeaderSpec<SectionHeaderViewType, SectionHeaderDataType>?
    public var headerSpec: HeaderSpec<HeaderViewType, HeaderDataType>?
    
    public var onConfigureHeader: ((HeaderViewType, HeaderDataType) -> ())?
    public var onConfigureSectionHeader: ((SectionHeaderViewType, SectionHeaderDataType) -> ())?
    public var onConfigureCellForAction: ((ActionViewType, Action<ActionDataType>, NSIndexPath) -> ())?
    
    public var contentHeight: CGFloat = 0.0

    lazy public var backgroundView: UIView = { [unowned self] in
        let backgroundView = UIView()
        backgroundView.autoresizingMask = UIViewAutoresizing.FlexibleHeight.union(.FlexibleWidth)
        backgroundView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        return backgroundView
    }()

    lazy public var collectionView: UICollectionView = { [unowned self] in
        let collectionView = UICollectionView(frame: UIScreen.mainScreen().bounds, collectionViewLayout: self.collectionViewLayout)
        collectionView.alwaysBounceVertical = self.settings.behavior.bounces
        collectionView.autoresizingMask = UIViewAutoresizing.FlexibleHeight.union(.FlexibleWidth)
        collectionView.backgroundColor = .clearColor()
        collectionView.bounces = self.settings.behavior.bounces
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.scrollEnabled = self.settings.behavior.scrollEnabled
        collectionView.showsVerticalScrollIndicator = false
        if self.settings.behavior.hideOnTap {
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ActionController.tapGestureDidRecognize(_:)))
            collectionView.backgroundView = UIView(frame: collectionView.bounds)
            collectionView.backgroundView?.userInteractionEnabled = true
            collectionView.backgroundView?.addGestureRecognizer(tapRecognizer)
        }
        if self.settings.behavior.hideOnScrollDown && !self.settings.behavior.scrollEnabled {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(ActionController.swipeGestureDidRecognize(_:)))
            swipeGesture.direction = .Down
            collectionView.addGestureRecognizer(swipeGesture)
        }
        return collectionView
    }()
    
    lazy public var collectionViewLayout: DynamicCollectionViewFlowLayout = { [unowned self] in
        let collectionViewLayout = DynamicCollectionViewFlowLayout()
        collectionViewLayout.useDynamicAnimator = self.settings.behavior.useDynamics
        collectionViewLayout.minimumInteritemSpacing = 0.0
        collectionViewLayout.minimumLineSpacing = 0.0
        return collectionViewLayout
    }()
    
    // MARK: - ActionController initializers
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        cellSpec = .CellClass(height: { _ -> CGFloat in 60 })
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        transitioningDelegate = self
        modalPresentationStyle = .Custom
    }
    
    public required init?(coder aDecoder: NSCoder) {
        cellSpec = .CellClass(height: { _ -> CGFloat in 60 })
        super.init(coder: aDecoder)
        transitioningDelegate = self
        modalPresentationStyle = .Custom
    }
    
    // MARK - Public API
    
    public func addAction(action: Action<ActionDataType>) {
        if let section = _sections.last {
            section.actions.append(action)
        } else {
            let section = Section<ActionDataType, SectionHeaderDataType>()
            addSection(section)
            section.actions.append(action)
        }
    }
    
    public func addSection(section: Section<ActionDataType, SectionHeaderDataType>) -> Section<ActionDataType, SectionHeaderDataType> {
        _sections.append(section)
        return section
    }
    
    // MARK: - Helpers
    
    public func sectionForIndex(index: Int) -> Section<ActionDataType, SectionHeaderDataType>? {
        return _sections[index]
    }
    
    public func actionForIndexPath(indexPath: NSIndexPath) -> Action<ActionDataType>? {
        return _sections[indexPath.section].actions[indexPath.item]
    }
    
    public func actionIndexPathFor(indexPath: NSIndexPath) -> NSIndexPath {
        if hasHeader() {
            return NSIndexPath(forItem: indexPath.item, inSection: indexPath.section - 1)
        }
        return indexPath
    }
    
    public func dismiss() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - View controller behavior
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // background view
        view.addSubview(backgroundView)

        // register main cell
        switch cellSpec {
        case .NibFile(let nibName, let bundle, _):
            collectionView.registerNib(UINib(nibName: nibName, bundle: bundle), forCellWithReuseIdentifier:ReusableViewIds.Cell.rawValue)
        case .CellClass:
            collectionView.registerClass(ActionViewType.self, forCellWithReuseIdentifier:ReusableViewIds.Cell.rawValue)
        }
        
        // register main header
        if let headerSpec = headerSpec, let _ = headerData {
            switch headerSpec {
            case .CellClass:
                collectionView.registerClass(HeaderViewType.self, forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: ReusableViewIds.Header.rawValue)
            case .NibFile(let nibName, let bundle, _):
                collectionView.registerNib(UINib(nibName: nibName, bundle: bundle), forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: ReusableViewIds.Header.rawValue)
            }
        }
        
        // register section header
        if let headerSpec = sectionHeaderSpec {
            switch headerSpec {
            case .CellClass:
                collectionView.registerClass(SectionHeaderViewType.self, forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: ReusableViewIds.SectionHeader.rawValue)
            case .NibFile(let nibName, let bundle, _):
                collectionView.registerNib(UINib(nibName: nibName, bundle: bundle), forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: ReusableViewIds.SectionHeader.rawValue)
            }
        }
        
        view.addSubview(collectionView)
        
        // calculate content Inset
        collectionView.layoutSubviews()
        if let section = _sections.last where !settings.behavior.useDynamics {
            let lastSectionIndex = _sections.count - 1
            let layoutAtts = collectionViewLayout.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: section.actions.count - 1, inSection: hasHeader() ? lastSectionIndex + 1 : lastSectionIndex))
            contentHeight = layoutAtts!.frame.origin.y + layoutAtts!.frame.size.height
        }
        
        setUpContentInsetForHeight(view.frame.height)
        
        // set up collection view initial position taking into account top content inset
        collectionView.frame = view.bounds
        collectionView.frame.origin.y += contentHeight + (settings.cancelView.showCancel ? settings.cancelView.height : 0)
        collectionViewLayout.footerReferenceSize = CGSizeMake(320, 0)
        // -
        
        if settings.cancelView.showCancel {
            if cancelView == nil {
                cancelView = {
                    let cancel = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: settings.cancelView.height))
                    cancel.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(.FlexibleTopMargin)
                    cancel.backgroundColor = settings.cancelView.backgroundColor
                    let cancelButton: UIButton = {
                        let cancelButton = UIButton(frame: CGRectMake(0, 0, 100, settings.cancelView.height))
                        cancelButton.addTarget(self, action: #selector(ActionController.cancelButtonDidTouch(_:)), forControlEvents: .TouchUpInside)
                        cancelButton.setTitle(settings.cancelView.title, forState: .Normal)
                        cancelButton.translatesAutoresizingMaskIntoConstraints = false
                        return cancelButton
                    }()
                    cancel.addSubview(cancelButton)
                    cancel.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[button]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["button": cancelButton]))
                    cancel.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[button]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["button": cancelButton]))
                    return cancel
                }()
            }
            view.addSubview(cancelView!)
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        backgroundView.frame = view.bounds
    }

    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if let _ = settings.animation.scale {
            presentingViewController?.view.transform = CGAffineTransformIdentity
        }
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        coordinator.animateAlongsideTransition({ [weak self] _ in
            self?.setUpContentInsetForHeight(size.height)
            self?.collectionView.reloadData()
            if let scale = self?.settings.animation.scale {
                self?.presentingViewController?.view.transform = CGAffineTransformMakeScale(scale.width, scale.height)
            }
        }, completion: nil)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    public override func prefersStatusBarHidden() -> Bool {
        return !settings.statusBar.showStatusBar
    }
    
    public  override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return settings.statusBar.style
    }
        
    // MARK: - UICollectionViewDataSource
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return numberOfSections()
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if hasHeader() && section == 0 { return 0 }
        if settings.behavior.useDynamics && section > _dynamicSectionIndex {
            return 0
        }
        return _sections[actionSectionIndexFor(section)].actions.count
    }
    
    public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            if indexPath.section == 0 && hasHeader() {
                let reusableview = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: ReusableViewIds.Header.rawValue, forIndexPath: indexPath) as? HeaderViewType
                onConfigureHeader?(reusableview!, headerData!)
                return reusableview!
            } else {
                let reusableview = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: ReusableViewIds.SectionHeader.rawValue, forIndexPath: indexPath) as? SectionHeaderViewType
                onConfigureSectionHeader?(reusableview!,  sectionForIndex(actionSectionIndexFor(indexPath.section))!.data!)
                return reusableview!
            }
        }
        
        fatalError()
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let action = actionForIndexPath(actionIndexPathFor(indexPath))
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ReusableViewIds.Cell.rawValue, forIndexPath: indexPath) as? ActionViewType
        self.onConfigureCellForAction?(cell!, action!, indexPath)
        return cell!
    }
    
    // MARK: - UICollectionViewDelegate & UICollectionViewDelegateFlowLayout
    
    public func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ActionViewType
        (cell as? SeparatorCellType)?.hideSeparator()
        if let prevCell = prevCell(indexPath) {
            (prevCell as? SeparatorCellType)?.hideSeparator()
        }
        return true
    }
    
    public func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ActionViewType
        (cell as? SeparatorCellType)?.showSeparator()
        if let prevCell = prevCell(indexPath) {
            (prevCell as? SeparatorCellType)?.showSeparator()
        }
    }
    
    public func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return actionForIndexPath(actionIndexPathFor(indexPath))?.enabled == true
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let action = self.actionForIndexPath(actionIndexPathFor(indexPath)) {
            action.handler?(action)
        }
        self.dismiss()
    }

    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        guard let action = self.actionForIndexPath(actionIndexPathFor(indexPath)), let actionData = action.data else {
            return CGSizeZero
        }

        let referenceWidth = collectionView.bounds.size.width
        let margins = 2 * settings.collectionView.lateralMargin + collectionView.contentInset.left + collectionView.contentInset.right
        return CGSize(width: referenceWidth - margins, height: cellSpec.height(actionData))
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            if let headerData = headerData, let headerSpec = headerSpec {
                return CGSizeMake(collectionView.bounds.size.width, headerSpec.height(headerData))
            } else if let sectionHeaderSpec = sectionHeaderSpec, let section = sectionForIndex(actionSectionIndexFor(section)), let sectionData = section.data {
                return CGSizeMake(collectionView.bounds.size.width, sectionHeaderSpec.height(sectionData))
            }
        } else if let sectionHeaderSpec = sectionHeaderSpec, let section = sectionForIndex(actionSectionIndexFor(section)), let sectionData = section.data {
            return CGSizeMake(collectionView.bounds.size.width, sectionHeaderSpec.height(sectionData))
        }
        return CGSizeZero
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSizeZero
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }
    
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    
    public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return isPresenting ? 0 : settings.animation.dismiss.duration
    }
    
    public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView()
        
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let fromView = fromViewController.view
        
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let toView = toViewController.view
        
        if isPresenting {
            toView.autoresizingMask = UIViewAutoresizing.FlexibleHeight.union(.FlexibleWidth)
            containerView?.addSubview(toView)
            
            transitionContext.completeTransition(true)
            presentView(toView, presentingView: fromView, animationDuration: settings.animation.present.duration, completion: nil)
        } else {
            dismissView(fromView, presentingView: toView, animationDuration: settings.animation.dismiss.duration) { completed in
                if completed {
                    fromView.removeFromSuperview()
                }
                transitionContext.completeTransition(completed)
            }
        }
    }
    
    public func presentView(presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((completed: Bool) -> Void)?) {
        onWillPresentView()
        let animationSettings = settings.animation.present
        UIView.animateWithDuration(animationDuration,
            delay: animationSettings.delay,
            usingSpringWithDamping: animationSettings.damping,
            initialSpringVelocity: animationSettings.springVelocity,
            options: animationSettings.options.union(.AllowUserInteraction),
            animations: { [weak self] in
                if let transformScale = self?.settings.animation.scale {
                    presentingView.transform = CGAffineTransformMakeScale(transformScale.width, transformScale.height)
                }
                self?.performCustomPresentationAnimation(presentedView, presentingView: presentingView)
            },
            completion: { [weak self] finished in
                self?.onDidPresentView()
                completion?(completed: finished)
            })
    }
    
    public func dismissView(presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((completed: Bool) -> Void)?) {
        onWillDismissView()
        let animationSettings = settings.animation.dismiss
        
        UIView.animateWithDuration(animationDuration,
            delay: animationSettings.delay,
            usingSpringWithDamping: animationSettings.damping,
            initialSpringVelocity: animationSettings.springVelocity,
            options: animationSettings.options.union(.AllowUserInteraction),
            animations: { [weak self] in
                if let _ = self?.settings.animation.scale {
                    presentingView.transform = CGAffineTransformIdentity
                }
                self?.performCustomDismissingAnimation(presentedView, presentingView: presentingView)
            },
            completion: { [weak self] _ in
                self?.onDidDismissView()
            })

        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(animationDuration * 0.25 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            completion?(completed: true)
        }
    }
    
    public func onWillPresentView() {
        backgroundView.alpha = 0.0
        cancelView?.frame.origin.y = view.bounds.size.height
        // Override this to add custom behavior previous to start presenting view animated.
        // Tip: you could start a new animation from this method
    }
    
    public func performCustomPresentationAnimation(presentedView: UIView, presentingView: UIView) {
        backgroundView.alpha = 1.0
        cancelView?.frame.origin.y = view.bounds.size.height - settings.cancelView.height
        collectionView.frame = view.bounds
        // Override this to add custom animations. This method is performed within the presentation animation block
    }
    
    public func onDidPresentView() {
        // Override this to add custom behavior when the presentation animation block finished
    }
    
    public func onWillDismissView() {
        // Override this to add custom behavior previous to start dismissing view animated
        // Tip: you could start a new animation from this method
    }
    
    public func performCustomDismissingAnimation(presentedView: UIView, presentingView: UIView) {
        backgroundView.alpha = 0.0
        cancelView?.frame.origin.y = view.bounds.size.height
        collectionView.frame.origin.y = contentHeight + (settings.cancelView.showCancel ? settings.cancelView.height : 0) + settings.animation.dismiss.offset
        // Override this to add custom animations. This method is performed within the presentation animation block
    }
    
    public func onDidDismissView() {
        // Override this to add custom behavior when the presentation animation block finished
    }
    
    // MARK: - Event handlers
    
    func cancelButtonDidTouch(sender: UIButton) {
        self.dismiss()
    }
    
    func tapGestureDidRecognize(gesture: UITapGestureRecognizer) {
        self.dismiss()
    }
    
    func swipeGestureDidRecognize(gesture: UISwipeGestureRecognizer) {
        self.dismiss()
    }
    
    // MARK: - Internal helpers
    
    func prevCell(indexPath: NSIndexPath) -> ActionViewType? {
        let prevPath: NSIndexPath?
        switch indexPath.item {
        case 0 where indexPath.section > 0:
            prevPath = NSIndexPath(forItem: collectionView(collectionView, numberOfItemsInSection: indexPath.section - 1) - 1, inSection: indexPath.section - 1)
        case let x where x > 0:
            prevPath = NSIndexPath(forItem: x - 1, inSection: indexPath.section)
        default:
            prevPath = nil
        }
        
        guard let unwrappedPrevPath = prevPath else { return nil }
        
        return collectionView.cellForItemAtIndexPath(unwrappedPrevPath) as? ActionViewType
    }

    func hasHeader() -> Bool {
        return headerData != nil && headerSpec != nil
    }
    
    private func numberOfActions() -> Int {
        return _sections.flatMap({ $0.actions }).count
    }
        
    private func numberOfSections() -> Int {
        return hasHeader() ? _sections.count + 1 : _sections.count
    }
    
    private func actionSectionIndexFor(section: Int) -> Int {
        return hasHeader() ? section - 1 : section
    }

    // MARK: - Private properties
    
    private func setUpContentInsetForHeight(height: CGFloat) {
        let currentInset = collectionView.contentInset
        let bottomInset = settings.cancelView.showCancel ? settings.cancelView.height : currentInset.bottom
        var topInset = height - contentHeight
        
        if settings.cancelView.showCancel {
            topInset -= settings.cancelView.height
        }
        
        topInset = max(topInset, max(30, height - contentHeight))
        
        collectionView.contentInset = UIEdgeInsets(top: topInset, left: currentInset.left, bottom: bottomInset, right: currentInset.right)
    }
    public var cancelView: UIView?
    private var isPresenting = false
    private var _dynamicSectionIndex: Int?
    private var _headerData: RawData<HeaderDataType>?
    private var _sections = [Section<ActionDataType, SectionHeaderDataType>]()
}

// MARK: - DynamicsActionController class

public class DynamicsActionController<ActionViewType: UICollectionViewCell, ActionDataType, HeaderViewType: UICollectionReusableView, HeaderDataType, SectionHeaderViewType: UICollectionReusableView, SectionHeaderDataType> : ActionController<ActionViewType, ActionDataType, HeaderViewType, HeaderDataType, SectionHeaderViewType, SectionHeaderDataType> {

    public lazy var animator: UIDynamicAnimator = {
        return UIDynamicAnimator()
    }()
    
    public lazy var gravityBehavior: UIGravityBehavior = {
        let gravity = UIGravityBehavior(items: [self.collectionView])
        gravity.magnitude = 10
        return gravity
    }()
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        settings.behavior.useDynamics = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        settings.behavior.useDynamics = true
    }
 
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.frame = view.bounds

        contentHeight = CGFloat(numberOfActions()) * settings.collectionView.cellHeightWhenDynamicsIsUsed + (CGFloat(_sections.count) * (collectionViewLayout.sectionInset.top + collectionViewLayout.sectionInset.bottom))
        contentHeight += collectionView.contentInset.bottom
        
        setUpContentInsetForHeight(view.frame.height)

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        for (index, section) in _sections.enumerate() {
            var rowIndex = -1
            let indexPaths = section.actions.map({ _ -> NSIndexPath in
                rowIndex += 1
                return NSIndexPath(forRow: rowIndex, inSection: index)
            })
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(index) * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self._dynamicSectionIndex = index
                self.collectionView.performBatchUpdates({
                    if indexPaths.count > 0 {
                        self.collectionView.insertItemsAtIndexPaths(indexPaths)
                    }
                }, completion: nil)
            })
        }
    }
    
    // MARK: - UICollectionViewDelegate & UICollectionViewDelegateFlowLayout
    
    public override func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        guard let alignment = (collectionViewLayout as? DynamicCollectionViewFlowLayout)?.itemsAligment where alignment != .Fill else {
            return super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAtIndexPath: indexPath)
        }
        
        if let action = self.actionForIndexPath(actionIndexPathFor(indexPath)), let actionData = action.data {
            let referenceWidth = min(collectionView.bounds.size.width, collectionView.bounds.size.height)
            let width = referenceWidth - (2 * settings.collectionView.lateralMargin) - collectionView.contentInset.left - collectionView.contentInset.right
            return CGSize(width: width, height: cellSpec.height(actionData))
        }
        return CGSizeZero
    }

    // MARK: - Overrides
    
    public override func dismiss() {
        animator.addBehavior(gravityBehavior)
        
        UIView.animateWithDuration(settings.animation.dismiss.duration) { [weak self] in
            self?.backgroundView.alpha = 0.0
        }
        
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    public override func dismissView(presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((completed: Bool) -> Void)?) {
        onWillDismissView()

        UIView.animateWithDuration(animationDuration,
            animations: { [weak self] in
                presentingView.transform = CGAffineTransformIdentity
                self?.performCustomDismissingAnimation(presentedView, presentingView: presentingView)
            },
            completion: { [weak self] finished in
                self?.onDidDismissView()
                completion?(completed: finished)
            })
    }

    public override func onWillPresentView() {
        backgroundView.frame = view.bounds
        backgroundView.alpha = 0.0
        
        self.backgroundView.alpha = 1.0
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    public override func performCustomDismissingAnimation(presentedView: UIView, presentingView: UIView) {
        // Nothing to do in this case
    }
}
