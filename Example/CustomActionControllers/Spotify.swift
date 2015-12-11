//  Spotify.swift
//  Spotify ( https://github.com/xmartlabs/XLActionController )
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

public class SpotifyCell: ActionCell {
    
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
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
        selectedBackgroundView = backgroundView
        actionTitleLabel?.textColor = .whiteColor()
        actionTitleLabel?.textAlignment = .Left
        
    }
}

public struct SpotifyHeaderData {
    
    var title: String
    var subtitle: String
    var image: UIImage
    
    public init(title: String, subtitle: String, image: UIImage) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }
}

public class SpotifyHeaderView: UICollectionReusableView {
    
    public lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRectZero)
        imageView.image = UIImage(named: "sp-header-icon")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    public lazy var title: UILabel = {
        let title = UILabel(frame: CGRectZero)
        title.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        title.text = "The Fast And ... The Furious Soundtrack Collection"
        title.textColor = UIColor.whiteColor()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.sizeToFit()
        return title
    }()
    
    public lazy var artist: UILabel = {
        let discArtist = UILabel(frame: CGRectZero)
        discArtist.font = UIFont(name: "HelveticaNeue", size: 16)
        discArtist.text = "Various..."
        discArtist.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.8)
        discArtist.translatesAutoresizingMaskIntoConstraints = false
        discArtist.sizeToFit()
        return discArtist
    }()
    
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
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clearColor()
        addSubview(imageView)
        addSubview(title)
        addSubview(artist)
        let separator: UIView = {
            let separator = UIView(frame: CGRectZero)
            separator.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
            separator.translatesAutoresizingMaskIntoConstraints = false
            return separator
        }()
        addSubview(separator)
        
        let views = [ "ico": imageView, "title": title, "artist": artist, "separator": separator ]
        let metrics = [ "icow": 54, "icoh": 54 ]
        let options = NSLayoutFormatOptions()
        
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-15-[ico(icow)]-10-[title]-15-|", options: options, metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[separator]|", options: options, metrics: metrics, views: views))
        
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-10-[ico(icoh)]", options: options, metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-18-[title][artist]", options: .AlignAllLeft, metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[separator(1)]|", options: options, metrics: metrics, views: views))
    }
}

public class SpotifyActionController: ActionController<SpotifyCell, ActionData, SpotifyHeaderView, SpotifyHeaderData, UICollectionReusableView, Void> {
    
    private lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        blurView.autoresizingMask = UIViewAutoresizing.FlexibleHeight.union(.FlexibleWidth)
        return blurView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.addSubview(blurView)
        
        cancelView?.frame.origin.y = view.bounds.size.height // Starts hidden below screen
        cancelView?.layer.shadowColor = UIColor.blackColor().CGColor
        cancelView?.layer.shadowOffset = CGSizeMake(0, -4)
        cancelView?.layer.shadowRadius = 2
        cancelView?.layer.shadowOpacity = 0.8
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        blurView.frame = backgroundView.bounds
    }
    
    public override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: NSBundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        settings.behavior.bounces = true
        settings.behavior.scrollEnabled = true
        settings.cancelView.showCancel = true
        settings.animation.scale = nil
        settings.animation.present.springVelocity = 0.0
        
        cellSpec = .NibFile(nibName: "SpotifyCell", bundle: NSBundle(forClass: SpotifyCell.self), height: { _ in 60 })
        headerSpec = .CellClass( height: { _ in 84 })
        
        onConfigureCellForAction = { [weak self] cell, action, indexPath in
            cell.setup(action.data?.title, detail: action.data?.subtitle, image: action.data?.image)
            cell.separatorView?.hidden = indexPath.item == (self?.collectionView.numberOfItemsInSection(indexPath.section))! - 1
            cell.alpha = action.enabled ? 1.0 : 0.5
        }
        onConfigureHeader = { (header: SpotifyHeaderView, data: SpotifyHeaderData)  in
            header.title.text = data.title
            header.artist.text = data.subtitle
            header.imageView.image = data.image
        }
    }
    
    public override func performCustomDismissingAnimation(presentedView: UIView, presentingView: UIView) {
        super.performCustomDismissingAnimation(presentedView, presentingView: presentingView)
        cancelView?.frame.origin.y = view.bounds.size.height + 10
    }
    
    public override func onWillPresentView() {
        cancelView?.frame.origin.y = view.bounds.size.height
    }
}
