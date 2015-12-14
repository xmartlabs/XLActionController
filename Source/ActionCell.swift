//  ActionCell.swift
//  XLActionController ( https://github.com/xmartlabs/ActionCell )
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

import UIKit

public protocol SeparatorCellType: NSObjectProtocol {
    func showSeparator()
    func hideSeparator()
}

public class ActionCell: UICollectionViewCell, SeparatorCellType {

    @IBOutlet public weak var actionTitleLabel: UILabel?
    @IBOutlet public weak var actionImageView: UIImageView?
    @IBOutlet public weak var actionDetailLabel: UILabel?
    @IBOutlet public weak var separatorView: UIView?

    public func setup(title: String?, detail: String?, image: UIImage?) {
        actionTitleLabel?.text = title
        actionDetailLabel?.text = detail
        actionImageView?.image = image

        if let _ = image {
            actionTitleLabelConstraintToContainer?.priority = UILayoutPriorityDefaultHigh
            actionTitleLabelConstraintToImageView?.priority = UILayoutPriorityRequired
        } else {
            actionTitleLabelConstraintToContainer?.priority = UILayoutPriorityRequired
            actionTitleLabelConstraintToImageView?.priority = UILayoutPriorityDefaultHigh
        }
    }
    
    
    @IBOutlet private weak var actionTitleLabelConstraintToContainer: NSLayoutConstraint?
    @IBOutlet private weak var actionTitleLabelConstraintToImageView: NSLayoutConstraint?
    
    
    public func showSeparator() {
        separatorView?.alpha = 1.0
    }
    
    public func hideSeparator() {
        separatorView?.alpha = 0.0
    }
}
