//  CancelCell.swift
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

protocol CancelCellProtocol: class {
    
    func didTappedCancel()
}

class CancelCell: UICollectionViewCell {

    var cancelView: UIView?
    weak var delegate: CancelCellProtocol?

    func addCancel(view: UIView) {
        cancelView = view
        let views = ["view": view]
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        ["V", "H"].forEach {
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "\($0):|[view]|", options: [], metrics: nil, views: views))
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelView?.removeFromSuperview()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        let cancelButton: UIButton = {
            let cancelButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
            cancelButton.addTarget(self, action: #selector(cancelButtonDidTouch(_:)), for: .touchUpInside)
            return cancelButton
        }()
        self.addSubview(cancelButton)
    }
    
    func cancelButtonDidTouch(_ sender: UIButton) {
        delegate?.didTappedCancel()
    }
}
