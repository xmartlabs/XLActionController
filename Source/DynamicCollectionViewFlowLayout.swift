//  DynamicCollectionViewFlowLayout.swiftg
//  DynamicCollectionViewFlowLayout ( https://github.com/xmartlabs/XLActionController )
//
//  Copyright (c) 2015 Xmartlabs ( whttp://xmartlabs.com )
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

import UIKit

public class DynamicCollectionViewFlowLayout: UICollectionViewFlowLayout {


    // MARK: - Properties definition 
    
    public var dynamicAnimator: UIDynamicAnimator?
    public var itemsAligment = UIControlContentHorizontalAlignment.Center

    public lazy var collisionBehavior: UICollisionBehavior? = {
        let collision = UICollisionBehavior(items: [])
        return collision
    }()

    public lazy var dynamicItemBehavior: UIDynamicItemBehavior? = {
        let dynamic = UIDynamicItemBehavior(items: [])
        dynamic.allowsRotation = false
        return dynamic
    }()
    
    public lazy var gravityBehavior: UIGravityBehavior? = {
        let gravity = UIGravityBehavior(items: [])
        gravity.gravityDirection = CGVectorMake(0, -1)
        gravity.magnitude = 4.0
        return gravity
    }()
    
    public var useDynamicAnimator = false {
        didSet(newValue) {
            guard useDynamicAnimator != newValue else {
                return
            }
            
            if useDynamicAnimator {
                dynamicAnimator = UIDynamicAnimator(collectionViewLayout: self)

                dynamicAnimator!.addBehavior(collisionBehavior!)
                dynamicAnimator!.addBehavior(dynamicItemBehavior!)
                dynamicAnimator!.addBehavior(gravityBehavior!)
            }
        }
    }
    
    // MARK: - Intialize
    
    override init() {
        super.init()
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
    }
    
    // MARK: - UICollectionViewFlowLayout overrides
    
    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let animator = dynamicAnimator else {
            return super.layoutAttributesForElementsInRect(rect)
        }
        
        return animator.itemsInRect(rect) as? [UICollectionViewLayoutAttributes]
    }
    
    override public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath?) -> UICollectionViewLayoutAttributes? {
        guard let indexPath = indexPath else {
            return nil
        }
        
        guard let animator = dynamicAnimator else {
            return super.layoutAttributesForItemAtIndexPath(indexPath)
        }
        
        return animator.layoutAttributesForCellAtIndexPath(indexPath) ?? setupAttributesForIndexPath(indexPath)
    }

    override public func prepareForCollectionViewUpdates(updateItems: [UICollectionViewUpdateItem]) {
        super.prepareForCollectionViewUpdates(updateItems)
        
        updateItems.filter { $0.updateAction == .Insert && layoutAttributesForItemAtIndexPath($0.indexPathAfterUpdate) == nil } .forEach {
            setupAttributesForIndexPath($0.indexPathAfterUpdate)
        }
    }

    // MARK: - Helpers
    
    private func topForItemAt(indexPath indexPath: NSIndexPath) -> CGFloat {
        guard let unwrappedCollectionView = collectionView else {
            return CGFloat(0.0)
        }
        
        // Top within item's section
        var top = CGFloat(indexPath.item) * itemSize.height
        
        if indexPath.section > 0 {
            let lastItemOfPrevSection = unwrappedCollectionView.numberOfItemsInSection(indexPath.section - 1)
            // Add previous sections height recursively. We have to add the sectionInsets and the last section's item height
            let inset = (unwrappedCollectionView.delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(unwrappedCollectionView, layout: self, insetForSectionAtIndex: indexPath.section) ?? sectionInset
            top += topForItemAt(indexPath: NSIndexPath(forItem: lastItemOfPrevSection - 1, inSection: indexPath.section - 1)) + inset.bottom + inset.top + itemSize.height
        }
        
        return top
    }
    
    func setupAttributesForIndexPath(indexPath: NSIndexPath?) -> UICollectionViewLayoutAttributes? {
        guard let indexPath = indexPath, animator = dynamicAnimator, collectionView = collectionView else {
            return nil
        }
        
        let delegate: UICollectionViewDelegateFlowLayout = collectionView.delegate as! UICollectionViewDelegateFlowLayout
        
        let collectionItemSize = delegate.collectionView!(collectionView, layout: self, sizeForItemAtIndexPath: indexPath)
        
        // UIDynamic animator will animate this item from initialFrame to finalFrame.
        
        // Items will be animated from far bottom to its final position in the collection view layout
        let originY = collectionView.frame.size.height - collectionView.contentInset.top
        var frame = CGRectMake(0, topForItemAt(indexPath: indexPath), collectionItemSize.width, collectionItemSize.height)
        var initialFrame = CGRectMake(0, originY + frame.origin.y, collectionItemSize.width, collectionItemSize.height)

        // Calculate x position depending on alignment value
        var translationX: CGFloat
        let collectionViewContentWidth = collectionView.bounds.size.width - collectionView.contentInset.left - collectionView.contentInset.right
        switch itemsAligment {
        case .Center:
            translationX = (collectionViewContentWidth - frame.size.width) * 0.5
        case .Fill, .Left:
            translationX = 0.0
        case .Right:
            translationX = (collectionViewContentWidth - frame.size.width)
        }

        frame.origin.x = translationX
        initialFrame.origin.x = translationX

        let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        attributes.frame = initialFrame

        let attachmentBehavior: UIAttachmentBehavior

        let collisionBehavior = UICollisionBehavior(items: [attributes])

        let itemBehavior = UIDynamicItemBehavior(items: [attributes])
        itemBehavior.allowsRotation = false

        if indexPath.item == 0 {
            let mass = CGFloat(collectionView.numberOfItemsInSection(indexPath.section) ?? 1)

            itemBehavior.elasticity = (0.70 / mass)

            var topMargin = CGFloat(1.5)
            if indexPath.section > 0 {
                topMargin -= sectionInset.top + sectionInset.bottom
            }
            let fromPoint = CGPoint(x: CGRectGetMinX(frame), y: CGRectGetMinY(frame) + topMargin)
            let toPoint = CGPoint(x: CGRectGetMaxX(frame), y: fromPoint.y)
            collisionBehavior.addBoundaryWithIdentifier("top", fromPoint: fromPoint, toPoint: toPoint)

            attachmentBehavior = UIAttachmentBehavior(item: attributes, attachedToAnchor:CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame)))
            attachmentBehavior.length = 1
            attachmentBehavior.damping = 0.30 * sqrt(mass)
            attachmentBehavior.frequency = 5.0
            
        } else {
            itemBehavior.elasticity = 0.0

            let fromPoint = CGPoint(x: CGRectGetMinX(frame), y: CGRectGetMinY(frame))
            let toPoint = CGPoint(x: CGRectGetMaxX(frame), y: fromPoint.y)
            collisionBehavior.addBoundaryWithIdentifier("top", fromPoint: fromPoint, toPoint: toPoint)

            let prevPath = NSIndexPath(forItem: indexPath.item - 1, inSection: indexPath.section)
            let prevItemAttributes = layoutAttributesForItemAtIndexPath(prevPath)!
            attachmentBehavior = UIAttachmentBehavior(item: attributes, attachedToItem: prevItemAttributes)
            attachmentBehavior.length = itemSize.height
            attachmentBehavior.damping = 0.0
            attachmentBehavior.frequency = 0.0
        }

        animator.addBehavior(attachmentBehavior)
        animator.addBehavior(collisionBehavior)
        animator.addBehavior(itemBehavior)
        
        return attributes
    }

    public override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        guard let animator = dynamicAnimator else {
            return super.shouldInvalidateLayoutForBoundsChange(newBounds)
        }

        guard let unwrappedCollectionView = collectionView else {
            return super.shouldInvalidateLayoutForBoundsChange(newBounds)
        }
        
        animator.behaviors
            .filter { $0 is UIAttachmentBehavior || $0 is UICollisionBehavior || $0 is UIDynamicItemBehavior}
            .forEach { animator.removeBehavior($0) }
        
        for section in 0..<unwrappedCollectionView.numberOfSections() {
            for item in 0..<unwrappedCollectionView.numberOfItemsInSection(section) {
                let indexPath = NSIndexPath(forItem: item, inSection: section)
                setupAttributesForIndexPath(indexPath)
            }
        }
        
        return false
    }
}
