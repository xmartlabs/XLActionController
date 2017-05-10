//  YouTubeExampleViewControllerWithDispatch.swift
//  XLActionController ( https://github.com/xmartlabs/XLActionController )
//
//  Copyright (c) 2017 Xmartlabs ( http://xmartlabs.com )
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
import XLActionController

class YoutubeDispatchExampleViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @IBAction func backButtonDidTouch(_ sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tapGestureDidRecognize(_ sender: UITapGestureRecognizer) {
        let actionController = YoutubeActionController()
        actionController.addAction(Action(ActionData(title: "Add to Watch Later", image: UIImage(named: "yt-add-to-watch-later-icon")!), style: .default, handler: { action in
        }))
        actionController.addAction(Action(ActionData(title: "Add to Playlist...", image: UIImage(named: "yt-add-to-playlist-icon")!), style: .default, handler: { action in
        }))
        present(actionController, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            actionController.addAction(Action(ActionData(title: "Share...", image: UIImage(named: "yt-share-icon")!), style: .default, handler: { action in
            }))
            actionController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "yt-cancel-icon")!), style: .cancel, handler: nil))
            actionController.collectionView.reloadData()
            actionController.calculateContentInset()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                actionController.removeAction(2)
                actionController.collectionView.reloadData()
                actionController.calculateContentInset()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    actionController.removeAction(closure: { action in action.data?.title == "Add to Watch Later" })
                    actionController.collectionView.reloadData()
                    actionController.calculateContentInset()
                    
                    // This option is not going to be removed because it doesn't exist anymore
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                        actionController.removeAction(closure: { action in action.data?.title == "Add to Watch Later" })
                        actionController.collectionView.reloadData()
                        actionController.calculateContentInset()
                    })
                })
            })
        })
    }
    
}
