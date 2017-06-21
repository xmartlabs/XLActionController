//
//  CancelView.swift
//  Example
//
//  Created by Karina on 6/19/17.
//  Copyright © 2017 Xmartlabs. All rights reserved.
//

import UIKit

public class CancelView: UIView {
    
    @IBOutlet weak var label: UILabel! {
        didSet {
            label.text = "Cancel"
        }
    }
    
}
