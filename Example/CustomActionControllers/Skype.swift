//  Skype.swift
//  Skype ( https://github.com/xmartlabs/XLActionController )
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
#if XLACTIONCONTROLLER_EXAMPLE
import XLActionController
#endif

public class SkypeCell: UICollectionViewCell {
    
    @IBOutlet weak var actionTitleLabel: UILabel!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    func initialize() {
        backgroundColor = .clearColor()
        actionTitleLabel?.textColor = .darkGrayColor()
        let backgroundView = UIView()
        backgroundView.backgroundColor = backgroundColor
        selectedBackgroundView = backgroundView
    }
}


public class SkypeActionController: ActionController<SkypeCell, String, UICollectionReusableView, Void, UICollectionReusableView, Void> {
    
    private var contextView: ContextView!
    private var normalAnimationRect: UIView!
    private var springAnimationRect: UIView!
    
    let topSpace = CGFloat(40)
    
    public override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: NSBundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        cellSpec = .NibFile(nibName: "SkypeCell", bundle: NSBundle(forClass: SkypeCell.self), height: { _ in 60 })
        settings.animation.scale = nil
        settings.animation.present.duration = 0.5
        settings.animation.present.options = UIViewAnimationOptions.CurveEaseOut.union(.AllowUserInteraction)
        settings.animation.present.springVelocity = 0.0
        settings.animation.present.damping = 0.7
        settings.statusBar.style = .Default
        
        onConfigureCellForAction = { cell, action, indexPath in
            cell.actionTitleLabel.text = action.data
            cell.actionTitleLabel.textColor = .whiteColor()
            cell.alpha = action.enabled ? 1.0 : 0.5
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        contextView = ContextView(frame: CGRectMake(0, -topSpace, collectionView.bounds.width, contentHeight + topSpace + 20))
        contextView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(.FlexibleBottomMargin)
        collectionView.clipsToBounds = false
        collectionView.addSubview(contextView)
        collectionView.sendSubviewToBack(contextView)
        
        
        normalAnimationRect = UIView(frame: CGRect(x: 0, y: view.bounds.height/2, width: 30, height: 30))
        normalAnimationRect.hidden = true
        view.addSubview(normalAnimationRect)
        
        springAnimationRect = UIView(frame: CGRect(x: 40, y: view.bounds.height/2, width: 30, height: 30))
        springAnimationRect.hidden = true
        view.addSubview(springAnimationRect)
        
        backgroundView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.65)
    }
    
    override public func onWillPresentView() {
        super.onWillPresentView()
        
        collectionView.frame.origin.y = contentHeight + (topSpace - contextView.topSpace)
        
        startAnimation()
        let initSpace = CGFloat(45.0)
        let initTime = 0.1
        let animationDuration = settings.animation.present.duration - 0.1
        
        let options = UIViewAnimationOptions.CurveEaseOut.union(.AllowUserInteraction)
        UIView.animateWithDuration(initTime, delay: settings.animation.present.delay, options: options, animations: { [weak self] in
                guard let me = self else {
                    return
                }
                
                var frame = me.springAnimationRect.frame
                frame.origin.y = frame.origin.y - initSpace
                me.springAnimationRect.frame = frame
            }, completion: { [weak self] finished in
                guard let me = self where finished else {
                    self?.finishAnimation()
                    return
                }
                
                UIView.animateWithDuration(animationDuration - initTime, delay: 0, options: options, animations: { [weak self] in
                    guard let me = self else {
                        return
                    }
                    
                    var frame = me.springAnimationRect.frame
                    frame.origin.y -= (me.contentHeight - initSpace)
                    me.springAnimationRect.frame = frame
                    }, completion: { (finish) -> Void in
                        me.finishAnimation()
                })
            })
        
        
        UIView.animateWithDuration(animationDuration - initTime, delay: settings.animation.present.delay + initTime, options: options, animations: { [weak self] in
            guard let me = self else {
                return
            }
            
            var frame = me.normalAnimationRect.frame
            frame.origin.y -= me.contentHeight
            me.normalAnimationRect.frame = frame
        }, completion:nil)
    }
    
    
    override public func dismissView(presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((completed: Bool) -> Void)?) {
        finishAnimation()
        finishAnimation()
        
        let animationSettings = settings.animation.dismiss
        UIView.animateWithDuration(animationDuration,
            delay: animationSettings.delay,
            usingSpringWithDamping: animationSettings.damping,
            initialSpringVelocity: animationSettings.springVelocity,
            options: animationSettings.options,
            animations: { [weak self] in
                self?.backgroundView.alpha = 0.0
            },
            completion:nil)
        
        gravityBehavior.action = { [weak self] in
            if let me = self {
                let progress = min(1.0, me.collectionView.frame.origin.y / (me.contentHeight + (me.topSpace - me.contextView.topSpace)))
                let pixels = min(20, progress * 150.0)
                me.contextView.diff = -pixels
                me.contextView.setNeedsDisplay()
                
                if self?.collectionView.frame.origin.y > self?.view.bounds.size.height {
                    self?.animator.removeAllBehaviors()
                    completion?(completed: true)
                }
            }
        }
        animator.addBehavior(gravityBehavior)
    }
    
    //MARK : Private Helpers
    
    private var diff = CGFloat(0)
    private var displayLink: CADisplayLink!
    private var animationCount = 0
    
    private lazy var animator: UIDynamicAnimator = { [unowned self] in
        let animator = UIDynamicAnimator(referenceView: self.view)
        return animator
        }()
    
    private lazy var gravityBehavior: UIGravityBehavior = { [unowned self] in
        let gravityBehavior = UIGravityBehavior(items: [self.collectionView])
        gravityBehavior.magnitude = 2.0
        return gravityBehavior
        }()
    
    
    @objc private func update(displayLink: CADisplayLink) {
        
        let normalRectLayer = normalAnimationRect.layer.presentationLayer()
        let springRectLayer = springAnimationRect.layer.presentationLayer()
        
        let normalRectFrame = normalRectLayer!.valueForKey("frame")!.CGRectValue
        let springRectFrame = springRectLayer!.valueForKey("frame")!.CGRectValue
        contextView.diff = normalRectFrame.origin.y - springRectFrame.origin.y
        contextView.setNeedsDisplay()
    }
    
    private func startAnimation() {
        if displayLink == nil {
            self.displayLink = CADisplayLink(target: self, selector: "update:")
            self.displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        }
        animationCount++
    }
    
    private func finishAnimation() {
        animationCount--
        if animationCount == 0 {
            displayLink.invalidate()
            displayLink = nil
        }
    }
    
    
    private class ContextView: UIView {
        let topSpace = CGFloat(25)
        var diff = CGFloat(0)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clearColor()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func drawRect(rect: CGRect) {
            let path = UIBezierPath()
            
            path.moveToPoint(CGPoint(x: 0, y: frame.height))
            path.addLineToPoint(CGPoint(x: frame.width, y: frame.height))
            path.addLineToPoint(CGPoint(x: frame.width, y: topSpace))
            path.addQuadCurveToPoint(CGPoint(x: 0, y: topSpace), controlPoint: CGPoint(x: frame.width/2, y: topSpace - diff))
            path.closePath()
            
            let context = UIGraphicsGetCurrentContext()
            CGContextAddPath(context, path.CGPath)
            UIColor(colorLiteralRed: 18/255.0, green: 165/255.0, blue: 244/255.0, alpha: 1.0).set()
            CGContextFillPath(context)
        }
    }
}
