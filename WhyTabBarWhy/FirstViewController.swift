//
//  FirstViewController.swift
//  WhyTabBarWhy
//
//  Created by Brian Nickel on 8/19/15.
//  Copyright © 2015 Brian Nickel. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var sceneNameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FirstViewController.tabBarVisibilityChanging(_:)), name: HidingTabBarVisibilityAnimatingNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        navigationController?.delegate = self
    }
    
    func tabBarVisibilityChanging(notification:NSNotification) {
        let hiding = notification.userInfo![HidingTabBarHiddenKey] as! Bool
        sceneNameLabel.transform = CGAffineTransformMakeRotation(hiding ? CGFloat(M_PI) : 0)
    }

    @IBAction func toggleTabBar(sender: AnyObject) {
        tabBarController!.setTabBarHidden(!tabBarController!.tabBarHidden, animated: true)
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        
        tabBarController?.setTabBarHidden(navigationController.viewControllers.count > 1, animated: true)
    }
}

class CustomTableView: UITableView {
    override var contentInset:UIEdgeInsets {
        didSet {
            print("ContentInset: \(contentInset)")
        }
    }
}

class CustomView : UIView {
    
    override var frame:CGRect {
        didSet {
            print("Frame: \(frame)")
        }
    }
    
    override var bounds:CGRect {
        didSet {
            print("Bounds: \(bounds)")
        }
    }
    
    override var center:CGPoint {
        didSet {
            print("Center: \(center)")
        }
    }
}
