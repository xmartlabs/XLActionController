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

open class Section<ActionDataType, SectionHeaderDataType> {

    open var data: SectionHeaderDataType? {
        get { return _data?.data }
        set { _data = RawData(data: newValue) }
    }
    open var actions = [Action<ActionDataType>]()
    fileprivate var _data: RawData<SectionHeaderDataType>?

    public init() {}
}

// MARK: - Enum definitions

public enum CellSpec<CellType: UICollectionViewCell, CellDataType> {

    case nibFile(nibName: String, bundle: Bundle?, height:((CellDataType)-> CGFloat))
    case cellClass(height:((CellDataType)-> CGFloat))

    public var height: ((CellDataType) -> CGFloat) {
        switch self {
        case .cellClass(let heightCallback):
            return heightCallback
        case .nibFile(_, _, let heightCallback):
            return heightCallback
        }
    }
}

public enum HeaderSpec<HeaderType: UICollectionReusableView, HeaderDataType> {

    case nibFile(nibName: String, bundle: Bundle?, height:((HeaderDataType) -> CGFloat))
    case cellClass(height:((HeaderDataType) -> CGFloat))

    public var height: ((HeaderDataType) -> CGFloat) {
        switch self {
        case .cellClass(let heightCallback):
            return heightCallback
        case .nibFile(_, _, let heightCallback):
            return heightCallback
        }
    }
}

public enum CancelSpec<CancelType: UICollectionReusableView> {

    case nibFile(nibName: String, bundle: Bundle?, height:(() -> CGFloat))
    case cellClass(height:(() -> CGFloat))

    public var height: (() -> CGFloat) {
        switch self {
        case .cellClass(let heightCallback):
            return heightCallback
        case .nibFile(_, _, let heightCallback):
            return heightCallback
        }
    }
}

private enum ReusableViewIds: String {
    case Cell = "Cell"
    case Header = "Header"
    case Cancel = "Cancel"
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

open class ActionController<ActionViewType: UICollectionViewCell, ActionDataType, HeaderViewType: UICollectionReusableView, HeaderDataType, SectionHeaderViewType: UICollectionReusableView, SectionHeaderDataType, CancelViewType: UICollectionReusableView>: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {

    // MARK - Public properties

    open var headerData: HeaderDataType? {
        set { _headerData = RawData(data: newValue) }
        get { return _headerData?.data }
    }

    public typealias IndexedAction = (indexPath: IndexPath, action: Action<ActionDataType>)
    public typealias PropertiesComply = (IndexedAction) -> Bool

    open var settings: ActionControllerSettings = ActionControllerSettings.defaultSettings()

    open var cellSpec: CellSpec<ActionViewType, ActionDataType>
    open var sectionHeaderSpec: HeaderSpec<SectionHeaderViewType, SectionHeaderDataType>?
    open var headerSpec: HeaderSpec<HeaderViewType, HeaderDataType>?

    open var cancelSpec: CancelSpec<CancelViewType>?
    open var onConfigureCancelForAction: ((CancelViewType, Action<ActionDataType>?, IndexPath) -> ())?

    open var onConfigureHeader: ((HeaderViewType, HeaderDataType) -> ())?
    open var onConfigureSectionHeader: ((SectionHeaderViewType, SectionHeaderDataType) -> ())?
    open var onConfigureCellForAction: ((ActionViewType, Action<ActionDataType>, IndexPath) -> ())?

    open var contentHeight: CGFloat = 0.0

    lazy open var backgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return backgroundView
    }()

    lazy open var collectionView: UICollectionView = { [unowned self] in
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: self.collectionViewLayout)
        collectionView.alwaysBounceVertical = self.settings.behavior.bounces
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = UIColor.clear
        collectionView.bounces = self.settings.behavior.bounces
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = self.settings.behavior.scrollEnabled
        collectionView.showsVerticalScrollIndicator = false
        if self.settings.behavior.hideOnTap {
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ActionController.tapGestureDidRecognize(_:)))
            collectionView.backgroundView = UIView(frame: collectionView.bounds)
            collectionView.backgroundView?.isUserInteractionEnabled = true
            collectionView.backgroundView?.addGestureRecognizer(tapRecognizer)
        }
        if self.settings.behavior.hideOnScrollDown && !self.settings.behavior.scrollEnabled {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(ActionController.swipeGestureDidRecognize(_:)))
            swipeGesture.direction = .down
            collectionView.addGestureRecognizer(swipeGesture)
        }
        return collectionView
    }()

    lazy open var collectionViewLayout: DynamicCollectionViewFlowLayout = { [unowned self] in
        let collectionViewLayout = DynamicCollectionViewFlowLayout()
        collectionViewLayout.useDynamicAnimator = self.settings.behavior.useDynamics
        collectionViewLayout.minimumInteritemSpacing = 0.0
        collectionViewLayout.minimumLineSpacing = 0
        return collectionViewLayout
    }()

    // MARK: - ActionController initializers

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        cellSpec = .cellClass(height: { _ -> CGFloat in 60 })
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    public required init?(coder aDecoder: NSCoder) {
        cellSpec = .cellClass(height: { _ -> CGFloat in 60 })
        super.init(coder: aDecoder)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    // MARK - Public API

    open func addAction(_ action: Action<ActionDataType>) {
        if let section = _sections.last {
            section.actions.append(action)
            collectionView.reloadData()

        } else {
            let section = Section<ActionDataType, SectionHeaderDataType>()
            addSection(section)
            section.actions.append(action)
            if self.presentingViewController != nil {
                collectionView.reloadData()
                self.calculateContentInset()
            }
        }
    }
    @discardableResult
    open func addSection(_ section: Section<ActionDataType, SectionHeaderDataType>) -> Section<ActionDataType, SectionHeaderDataType> {
        _sections.append(section)
        if self.presentingViewController != nil {
            collectionView.reloadData()
        }
        return section
    }

    open func removeAction(indexPath: IndexPath) {
        if indexPath.section < _sections.count && indexPath.row < _sections[indexPath.section].actions.count {
            _sections[indexPath.section].actions.remove(at: indexPath.row)

            if _sections[indexPath.section].actions.isEmpty {
                _sections.remove(at: indexPath.section)
            }
            collectionView.reloadData()
            self.calculateContentInset()
        }
    }

    open func removeAction(where: PropertiesComply) {
        _sections.enumerated().reversed().forEach { sectionIndex, section in
            section.actions.enumerated().reversed().forEach { actionIndex, action in
                if `where`((indexPath: IndexPath(row: actionIndex, section: sectionIndex), action: action)) {
                    section.actions.remove(at: actionIndex)
                }
            }
            if section.actions.isEmpty {
                _sections.remove(at: sectionIndex)
            }
        }
        collectionView.reloadData()
        self.calculateContentInset()
    }


    // MARK: - Helpers

    open func sectionForIndex(_ index: Int) -> Section<ActionDataType, SectionHeaderDataType>? {
        return _sections[index]
    }

    open func actionForIndexPath(_ indexPath: IndexPath) -> Action<ActionDataType>? {
        guard _sections.count > indexPath.section else { return  nil }
        guard _sections[(indexPath).section].actions.count > indexPath.row else { return nil }

        return _sections[(indexPath as NSIndexPath).section].actions[(indexPath as NSIndexPath).item]
    }

    open func actionIndexPathFor(_ indexPath: IndexPath) -> IndexPath {
        if hasHeader() {
            return IndexPath(item: (indexPath as NSIndexPath).item, section: (indexPath as NSIndexPath).section - 1)
        }
        return indexPath
    }

    open func dismiss() {
        dismiss(nil)
    }

    open func dismiss(_ completion: (() -> ())?) {
        disableActions = true
        presentingViewController?.dismiss(animated: true) { [weak self] in
            self?.disableActions = false
            completion?()
        }
    }

    // MARK: - View controller behavior

    open override func viewDidLoad() {
        super.viewDidLoad()

        modalPresentationCapturesStatusBarAppearance = settings.statusBar.modalPresentationCapturesStatusBarAppearance

        // background view
        view.addSubview(backgroundView)

        // register main cell
        switch cellSpec {
        case .nibFile(let nibName, let bundle, _):
            collectionView.register(UINib(nibName: nibName, bundle: bundle), forCellWithReuseIdentifier:ReusableViewIds.Cell.rawValue)
        case .cellClass:
            collectionView.register(ActionViewType.self, forCellWithReuseIdentifier:ReusableViewIds.Cell.rawValue)
        }

        // register section cancel
        if let cancelSpec = cancelSpec {
            switch cancelSpec {
            case .cellClass:
                collectionView.register(CancelViewType.self, forCellWithReuseIdentifier: ReusableViewIds.Cancel.rawValue)
            case .nibFile(let nibName, let bundle, _):
                collectionView.register(UINib(nibName: nibName, bundle: bundle), forCellWithReuseIdentifier: ReusableViewIds.Cancel.rawValue)
            }
        }

        // register main header
        if let headerSpec = headerSpec, let _ = headerData {
            switch headerSpec {
            case .cellClass:
                collectionView.register(HeaderViewType.self, forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: ReusableViewIds.Header.rawValue)
            case .nibFile(let nibName, let bundle, _):
                collectionView.register(UINib(nibName: nibName, bundle: bundle), forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: ReusableViewIds.Header.rawValue)
            }
        }

        // register section header
        if let headerSpec = sectionHeaderSpec {
            switch headerSpec {
            case .cellClass:
                collectionView.register(SectionHeaderViewType.self, forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: ReusableViewIds.SectionHeader.rawValue)
            case .nibFile(let nibName, let bundle, _):
                collectionView.register(UINib(nibName: nibName, bundle: bundle), forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: ReusableViewIds.SectionHeader.rawValue)
            }
        }
        view.addSubview(collectionView)
        calculateContentInset()

        // set up collection view initial position taking into account top content inset
        collectionView.frame = view.bounds
        collectionView.frame.origin.y += contentHeight
        collectionViewLayout.footerReferenceSize = CGSize(width: 320, height: 0)
    }

    open func calculateContentInset() {
        // calculate content Inset
        if collectionViewLayout.dynamicAnimator != nil {

            collectionViewLayout.shouldInvalidateLayout(forBoundsChange: CGRect(x: 0, y: 0, width: 0, height: 0))

            contentHeight = CGFloat(numberOfActions()) * settings.collectionView.cellHeightWhenDynamicsIsUsed + (CGFloat(_sections.count) * (collectionViewLayout.sectionInset.top + collectionViewLayout.sectionInset.bottom))
            contentHeight += collectionView.contentInset.bottom

            setUpContentInsetForHeight(view.frame.height)

            view.setNeedsLayout()
            view.layoutIfNeeded()


        } else {
            collectionView.layoutSubviews()
            
            if let section = _sections.last, !settings.behavior.useDynamics {
                let lastSectionIndex = _sections.count - 1
                let layoutAtts = collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: section.actions.count - 1, section: hasHeader() ? lastSectionIndex + 1 : lastSectionIndex))
                contentHeight = layoutAtts!.frame.origin.y + layoutAtts!.frame.size.height

                if let spec = cancelSpec, hasCancel {
                    contentHeight += spec.height()
                }
            }
            setUpContentInsetForHeight(view.frame.height)
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        backgroundView.frame = view.bounds
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if let _ = settings.animation.scale {
            presentingViewController?.view.transform = CGAffineTransform.identity
        }

        self.collectionView.collectionViewLayout.invalidateLayout()

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.setUpContentInsetForHeight(size.height)
            self?.collectionView.reloadData()
            if let scale = self?.settings.animation.scale {
                self?.presentingViewController?.view.transform = CGAffineTransform(scaleX: scale.width, y: scale.height)
            }
        }, completion: nil)
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    open override var prefersStatusBarHidden: Bool {
        return !settings.statusBar.showStatusBar
    }

    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return settings.statusBar.style
    }

    // MARK: - UICollectionViewDataSource

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfSections()
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if hasHeader() && section == 0 { return 0 }
        let realSectionIndex = actionSectionIndexFor(section)
        var rows = _sections[realSectionIndex].actions.count
        if _sections.count == realSectionIndex + 1 && hasCancel {
            rows += 1
        }
        guard let dynamicSectionIndex = _dynamicSectionIndex else {
            return settings.behavior.useDynamics ? 0 : rows
        }
        if settings.behavior.useDynamics && section > dynamicSectionIndex {
            return 0
        }
        return rows
    }

    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            if (indexPath as NSIndexPath).section == 0 && hasHeader() {
                let reusableview = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ReusableViewIds.Header.rawValue, for: indexPath) as? HeaderViewType
                onConfigureHeader?(reusableview!, headerData!)
                return reusableview!
            } else {
                let reusableview = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ReusableViewIds.SectionHeader.rawValue, for: indexPath) as? SectionHeaderViewType
                onConfigureSectionHeader?(reusableview!, sectionForIndex(actionSectionIndexFor((indexPath as NSIndexPath).section))!.data!)
                return reusableview!
            }
        }
        fatalError()
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let action = actionForIndexPath(actionIndexPathFor(indexPath))
        if let action = action {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReusableViewIds.Cell.rawValue, for: indexPath) as! ActionViewType
            self.onConfigureCellForAction?(cell, action, indexPath)
            return cell
        } else {
            // check if cancel should be added
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReusableViewIds.Cancel.rawValue, for: indexPath) as! CancelViewType
            self.onConfigureCancelForAction?(cell, action, indexPath)
            return cell as! UICollectionViewCell
        }
    }

    // MARK: - UICollectionViewDelegate & UICollectionViewDelegateFlowLayout

    open func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath) as? ActionViewType
        (cell as? SeparatorCellType)?.hideSeparator()
        if let prevCell = prevCell(indexPath) {
            (prevCell as? SeparatorCellType)?.hideSeparator()
        }
        return true
    }

    open func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? ActionViewType
        (cell as? SeparatorCellType)?.showSeparator()
        if let prevCell = prevCell(indexPath) {
            (prevCell as? SeparatorCellType)?.showSeparator()
        }
    }

    open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !disableActions && (actionForIndexPath(actionIndexPathFor(indexPath))?.enabled == true || actionForIndexPath(actionIndexPathFor(indexPath))?.enabled == nil)
    }

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let action = self.actionForIndexPath(actionIndexPathFor(indexPath))

        if let action = action, action.executeImmediatelyOnTouch {
            action.handler?(action)
        }
        
        self.dismiss() {
            if let action = action, !action.executeImmediatelyOnTouch {
                action.handler?(action)
            }
        }
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let action = self.actionForIndexPath(actionIndexPathFor(indexPath)), let actionData = action.data else {
            if let cancelSpec = cancelSpec {
                return CGSize(width: view.frame.width, height: cancelSpec.height())
            }
            
            return CGSize(width: view.frame.width, height: 46)
        }

        let referenceWidth = collectionView.bounds.size.width
        let margins = 2 * settings.collectionView.lateralMargin + collectionView.contentInset.left + collectionView.contentInset.right
        return CGSize(width: referenceWidth - margins, height: cellSpec.height(actionData))
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            if let headerData = headerData, let headerSpec = headerSpec {
                return CGSize(width: collectionView.bounds.size.width, height: headerSpec.height(headerData))
            } else if let sectionHeaderSpec = sectionHeaderSpec, let section = sectionForIndex(actionSectionIndexFor(section)), let sectionData = section.data {
                return CGSize(width: collectionView.bounds.size.width, height: sectionHeaderSpec.height(sectionData))
            }
        } else if let sectionHeaderSpec = sectionHeaderSpec, let section = sectionForIndex(actionSectionIndexFor(section)), let sectionData = section.data {
            return CGSize(width: collectionView.bounds.size.width, height: sectionHeaderSpec.height(sectionData))
        }
        return CGSize.zero
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }

    // MARK: - UIViewControllerTransitioningDelegate

    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }

    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresenting ? 0 : settings.animation.dismiss.duration
    }

    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let fromView = fromViewController.view

        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let toView = toViewController.view

        if isPresenting {
            toView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            containerView.addSubview(toView!)

            transitionContext.completeTransition(true)
            presentView(toView!, presentingView: fromView!, animationDuration: settings.animation.present.duration, completion: nil)
        } else {
            dismissView(fromView!, presentingView: toView!, animationDuration: settings.animation.dismiss.duration) { completed in
                if completed {
                    fromView?.removeFromSuperview()
                }
                transitionContext.completeTransition(completed)
            }
        }
    }

    open func presentView(_ presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((_ completed: Bool) -> Void)?) {
        onWillPresentView()
        let animationSettings = settings.animation.present
        UIView.animate(withDuration: animationDuration,
            delay: animationSettings.delay,
            usingSpringWithDamping: animationSettings.damping,
            initialSpringVelocity: animationSettings.springVelocity,
            options: animationSettings.options.union(.allowUserInteraction),
            animations: { [weak self] in
                if let transformScale = self?.settings.animation.scale {
                    presentingView.transform = CGAffineTransform(scaleX: transformScale.width, y: transformScale.height)
                }
                self?.performCustomPresentationAnimation(presentedView, presentingView: presentingView)
            },
            completion: { [weak self] finished in
                self?.onDidPresentView()
                completion?(finished)
            })
    }

    open func dismissView(_ presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((_ completed: Bool) -> Void)?) {
        onWillDismissView()
        let animationSettings = settings.animation.dismiss

        UIView.animate(withDuration: animationDuration,
            delay: animationSettings.delay,
            usingSpringWithDamping: animationSettings.damping,
            initialSpringVelocity: animationSettings.springVelocity,
            options: animationSettings.options.union(.allowUserInteraction),
            animations: { [weak self] in
                if let _ = self?.settings.animation.scale {
                    presentingView.transform = CGAffineTransform.identity
                }
                self?.performCustomDismissingAnimation(presentedView, presentingView: presentingView)
            },
            completion: { [weak self] _ in
                self?.onDidDismissView()
                completion?(true)
            })
    }

    open func onWillPresentView() {
        backgroundView.alpha = 0.0
        // Override this to add custom behavior previous to start presenting view animated.
        // Tip: you could start a new animation from this method
    }

    open func performCustomPresentationAnimation(_ presentedView: UIView, presentingView: UIView) {
        backgroundView.alpha = 1.0
        collectionView.frame = view.bounds
        // Override this to add custom animations. This method is performed within the presentation animation block
    }

    open func onDidPresentView() {
        // Override this to add custom behavior when the presentation animation block finished
    }

    open func onWillDismissView() {
        // Override this to add custom behavior previous to start dismissing view animated
        // Tip: you could start a new animation from this method
    }

    open func performCustomDismissingAnimation(_ presentedView: UIView, presentingView: UIView) {
        backgroundView.alpha = 0.0
        collectionView.frame.origin.y = contentHeight
        // Override this to add custom animations. This method is performed within the presentation animation block
    }

    open func onDidDismissView() {
        // Override this to add custom behavior when the presentation animation block finished
    }

    // MARK: - Event handlers

    func tapGestureDidRecognize(_ gesture: UITapGestureRecognizer) {
        self.dismiss()
    }

    func swipeGestureDidRecognize(_ gesture: UISwipeGestureRecognizer) {
        self.dismiss()
    }

    // MARK: - Internal helpers

    func prevCell(_ indexPath: IndexPath) -> ActionViewType? {
        let prevPath: IndexPath?
        switch (indexPath as NSIndexPath).item {
        case 0 where (indexPath as NSIndexPath).section > 0:
            prevPath = IndexPath(item: collectionView(collectionView, numberOfItemsInSection: (indexPath as NSIndexPath).section - 1) - 1, section: (indexPath as NSIndexPath).section - 1)
        case let x where x > 0:
            prevPath = IndexPath(item: x - 1, section: (indexPath as NSIndexPath).section)
        default:
            prevPath = nil
        }

        guard let unwrappedPrevPath = prevPath else { return nil }

        return collectionView.cellForItem(at: unwrappedPrevPath) as? ActionViewType
    }

    func hasHeader() -> Bool {
        return headerData != nil && headerSpec != nil
    }

    var hasCancel: Bool {
        return cancelSpec != nil  //settings.cancel.hasCancel
    }

    var cancelIndexPath: IndexPath? {
        guard hasCancel else { return nil }
        return IndexPath(item: _sections.last?.actions.count ?? 0, section: numberOfSections() - 1)
    }


    fileprivate func numberOfActions() -> Int {
        return _sections.flatMap({ $0.actions }).count
    }

    fileprivate func numberOfSections() -> Int {
        return hasHeader() ? _sections.count + 1 : _sections.count
    }

    fileprivate func actionSectionIndexFor(_ section: Int) -> Int {
        return hasHeader() ? section - 1 : section
    }

    open func setUpContentInsetForHeight(_ height: CGFloat) {
        let currentInset = collectionView.contentInset
        var topInset = height - contentHeight
        topInset = max(topInset, max(30, height - contentHeight))

        collectionView.contentInset = UIEdgeInsets(top: topInset, left: currentInset.left, bottom: 0 /*bottomInset*/, right: currentInset.right)
    }

    // MARK: - Private properties

    fileprivate var disableActions = false
    fileprivate var isPresenting = false

    fileprivate var _dynamicSectionIndex: Int?
    fileprivate var _headerData: RawData<HeaderDataType>?
    fileprivate var _sections = [Section<ActionDataType, SectionHeaderDataType>]()
}

// MARK: - DynamicsActionController class
open class DynamicsActionController<ActionViewType: UICollectionViewCell, ActionDataType, HeaderViewType: UICollectionReusableView, HeaderDataType, SectionHeaderViewType: UICollectionReusableView, SectionHeaderDataType, CancelViewType: UICollectionReusableView> : ActionController<ActionViewType, ActionDataType, HeaderViewType, HeaderDataType, SectionHeaderViewType, SectionHeaderDataType, CancelViewType> {

    open lazy var animator: UIDynamicAnimator = {
        return UIDynamicAnimator()
    }()

    open lazy var gravityBehavior: UIGravityBehavior = {
        let gravity = UIGravityBehavior(items: [self.collectionView])
        gravity.magnitude = 10
        return gravity
    }()

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        settings.behavior.useDynamics = true
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        settings.behavior.useDynamics = true
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.frame = view.bounds

        contentHeight = CGFloat(numberOfActions()) * settings.collectionView.cellHeightWhenDynamicsIsUsed + (CGFloat(_sections.count) * (collectionViewLayout.sectionInset.top + collectionViewLayout.sectionInset.bottom))
        contentHeight += collectionView.contentInset.bottom
        contentHeight += cancelSpec != nil ? settings.collectionView.cellHeightWhenDynamicsIsUsed : CGFloat(0)

        setUpContentInsetForHeight(view.frame.height)

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        for (index, section) in _sections.enumerated() {
            var rowIndex = -1
            var indexPaths = section.actions.map({ _ -> IndexPath in
                rowIndex += 1
                return IndexPath(row: rowIndex, section: index)
            })
            
            if index == _sections.count - 1 {
                indexPaths.append(IndexPath(item: rowIndex + 1, section: index))
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.3 * Double(index) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                self._dynamicSectionIndex = index
                self.collectionView.performBatchUpdates({
                    if indexPaths.count > 0 {
                        self.collectionView.insertItems(at: indexPaths)
                    }
                }, completion: nil)
            })
        }
    }

    // MARK: - UICollectionViewDelegate & UICollectionViewDelegateFlowLayout

    open override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let alignment = (collectionViewLayout as? DynamicCollectionViewFlowLayout)?.itemsAligment , alignment != .fill else {
            return super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
        }

        let referenceWidth = min(collectionView.bounds.size.width, collectionView.bounds.size.height)
        let width = referenceWidth - (2 * settings.collectionView.lateralMargin) - collectionView.contentInset.left - collectionView.contentInset.right

        if let action = self.actionForIndexPath(actionIndexPathFor(indexPath)), let actionData = action.data {
            return CGSize(width: width, height: cellSpec.height(actionData))
        } else if let cancelSpec = cancelSpec {
            return CGSize(width: width, height: cancelSpec.height())
        }
        
        return CGSize.zero
    }

    // MARK: - Overrides

    open override func dismiss() {
        dismiss(nil)
    }

    open override func dismiss(_ completion: (() -> ())?) {
        animator.addBehavior(gravityBehavior)

        UIView.animate(withDuration: settings.animation.dismiss.duration, animations: { [weak self] in
            self?.backgroundView.alpha = 0.0
        })

        presentingViewController?.dismiss(animated: true, completion: completion)
    }

    open override func dismissView(_ presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((_ completed: Bool) -> Void)?) {
        onWillDismissView()

        UIView.animate(withDuration: animationDuration,
            animations: { [weak self] in
                presentingView.transform = CGAffineTransform.identity
                self?.performCustomDismissingAnimation(presentedView, presentingView: presentingView)
            },
            completion: { [weak self] finished in
                self?.onDidDismissView()
                completion?(finished)
            })
    }

    open override func onWillPresentView() {
        backgroundView.frame = view.bounds
        backgroundView.alpha = 0.0

        self.backgroundView.alpha = 1.0
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }

    open override func performCustomDismissingAnimation(_ presentedView: UIView, presentingView: UIView) {
        // Nothing to do in this case
    }

}
