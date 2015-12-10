//  Twitter.swift
//  Twitter ( https://github.com/xmartlabs/XLActionController )
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
import XLActionController

public class TwitterCell: ActionCell {
    
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
        backgroundColor = .whiteColor()
        actionImageView?.clipsToBounds = true
        actionImageView?.layer.cornerRadius = 5.0
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(white: 0.0, alpha: 0.15)
        selectedBackgroundView = backgroundView
    }
}

public class TwitterActionControllerHeader: UICollectionReusableView {
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .Center
        label.backgroundColor = .whiteColor()
        label.font = UIFont.boldSystemFontOfSize(17)
        return label
    }()
    
    lazy var bottomLine: UIView = {
        let bottomLine = UIView()
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.backgroundColor = .lightGrayColor()
        return bottomLine
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .whiteColor()
        addSubview(label)
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["label": label]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["label": label]))
        addSubview(bottomLine)
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[line(1)]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["line": bottomLine]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[line]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["line": bottomLine]))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}


public class TwitterActionController: ActionController<TwitterCell, ActionData, TwitterActionControllerHeader, String, UICollectionReusableView, Void> {
    
    public override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: NSBundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        settings.animation.present.duration = 0.6
        settings.animation.dismiss.duration = 0.6
        cellSpec = CellSpec.NibFile(nibName: "TwitterCell", bundle: NSBundle(forClass: TwitterCell.self), height: { _ in 56 })
        headerSpec = .CellClass(height: { _ -> CGFloat in return 45 })
        
        
        onConfigureHeader = { header, title in
            header.label.text = title
        }
        onConfigureCellForAction = { [weak self] cell, action, indexPath in
            
            cell.setup(action.data?.title, detail: action.data?.subtitle, image: action.data?.image)
            cell.separatorView?.hidden = indexPath.item == (self?.collectionView.numberOfItemsInSection(indexPath.section))! - 1
            cell.alpha = action.enabled ? 1.0 : 0.5
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.clipsToBounds = false
        let hideBottomSpaceView: UIView = {
            let hideBottomSpaceView = UIView(frame: CGRectMake(0, 0, collectionView.bounds.width, contentHeight + 20))
            hideBottomSpaceView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(.FlexibleBottomMargin)
            hideBottomSpaceView.backgroundColor = .whiteColor()
            return hideBottomSpaceView
        }()
        collectionView.addSubview(hideBottomSpaceView)
        collectionView.sendSubviewToBack(hideBottomSpaceView)
    }
    
    override public func dismissView(presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((completed: Bool) -> Void)?) {
        onWillDismissView()
        let animationSettings = settings.animation.dismiss
        let upTime = 0.1
        UIView.animateWithDuration(upTime, delay: 0, options: .CurveEaseIn, animations: { [weak self] in
            self?.collectionView.frame.origin.y -= 10
        }, completion: { [weak self] (completed) -> Void in
            UIView.animateWithDuration(animationDuration - upTime,
                delay: 0,
                usingSpringWithDamping: animationSettings.damping,
                initialSpringVelocity: animationSettings.springVelocity,
                options: UIViewAnimationOptions.CurveEaseIn,
                animations: { [weak self] in
                    presentingView.transform = CGAffineTransformIdentity
                    self?.performCustomDismissingAnimation(presentedView, presentingView: presentingView)
                },
                completion: { [weak self] finished in
                    self?.onDidDismissView()
                    completion?(completed: finished)
                })
        })
    }
}
