//
//  HidingTabBar.swift
//  WhyTabBarWhy
//
//  Created by Brian Nickel on 8/19/15.
//  Copyright © 2015 Brian Nickel. All rights reserved.
//

import UIKit

public let HidingTabBarVisibilityWillChangeNotification = "HidingTabBarVisibilityWillChangeNotification"
public let HidingTabBarVisibilityDidChangeNotification = "HidingTabBarVisibilityDidChangeNotification"
public let HidingTabBarVisibilityAnimatingNotification = "HidingTabBarVisibilityAnimatingNotification"
public let HidingTabBarHiddenKey = "hidden"

// UIViewController bottomLayoutGuide and scrollview content insets are driven by a mix of sizeThatFits(_:) and bounds.size.height.
// This class adjusts both values in setHidden(_:) so that view controllers can update their values accordingly.
public class HidingTabBar : UITabBar {
    
    private static var customHeight:CGFloat? = nil
    private weak var currentAnimatingView:UIView?
    private weak var currentAnimation:AnyObject?
    private var lastAnimatedView:(UITabBarItem?, UIView)?
    
    override public func sizeThatFits(size: CGSize) -> CGSize {
        return sizeThatFits(size, hidden: hidden)
    }
    
    private func sizeThatFits(size: CGSize, hidden:Bool) -> CGSize {
        var size = super.sizeThatFits(size)
        if hidden {
            size.height = 0
        } else if let customHeight = HidingTabBar.customHeight {
            size.height = customHeight
        }
        return size
    }
    
    // If UITabBarItem is laid out when height == 0, the UITabBarLabel width gets reduced by 10pt permanently.
    // It appears that the rendering gets cached so even resizing the label to its original width after animation DOES NOT WORK.
    // This is sufficiently effective.
    override public func layoutSubviews() {
        if bounds.height != 0 {
            super.layoutSubviews()
            
            // Fix the background view if its height gets stuck at zero.  Only seen so far on a 4S once.  Not sure how to reproduce: 
            if let background = subviews.first where background.frame.width == bounds.width {
                background.frame = bounds
            }
        }
    }
    
    override public var hidden:Bool {
        get {
            return super.hidden
        }
        set(value) {
            setHidden(value, animated: false, alongsideAnimations: { () -> () in }, completion: { (_) -> () in })
        }
    }
    
    func setHidden(hidden:Bool, animated:Bool, alongsideAnimations:() -> (), completion:(Bool) -> ()) {
        if hidden == self.hidden {
            return
        }
        
        let userInfo = [HidingTabBarHiddenKey: hidden]
        NSNotificationCenter.defaultCenter().postNotificationName(HidingTabBarVisibilityWillChangeNotification, object: self, userInfo: userInfo)
        
        let initialFrame = frame
        let finalFrame:CGRect
        
        if hidden {
            finalFrame = CGRect(x: frame.minX, y: frame.maxY, width: frame.width, height: 0)
        } else {
            let height = sizeThatFits(frame.size, hidden: false).height
            finalFrame = CGRect(x: frame.minX, y: frame.minY - height, width: frame.width, height: height)
        }
        
        if !animated || superview == nil {
            UIView.performWithoutAnimation({ () -> Void in
                self.frame = finalFrame
                self.alpha = 1
                super.hidden = hidden
                self.currentAnimatingView?.removeFromSuperview()
                alongsideAnimations()

            })
            completion(true)
            NSNotificationCenter.defaultCenter().postNotificationName(HidingTabBarVisibilityDidChangeNotification, object: self, userInfo: userInfo)
            return
        }
        
        // bounds.size.height must be set in order for UIViewController to animate alongside.
        // This means we have to animate a snapshot view if we want a up/down sliding effect.
        // We reuse the existing animating view for smooth animations when setting multiple times.
        let animatingView:UIView
        let alreadyAnimating:Bool
        let animateSelf:Bool
        
        if let currentAnimatingView = currentAnimatingView {
            animatingView = currentAnimatingView
            alreadyAnimating = true
            animateSelf = false
        } else {
            alreadyAnimating = false
            
            if let (selectedItem, view) = self.lastAnimatedView where selectedItem == selectedItem && view.frame.size == finalFrame.size {
                // If possible, we reuse the last animated view.  This is the best way to get an accurate snapshot of the current view.  It misses
                // the case where the orientation has changed since the view was hidden.
                animatingView = view
                animateSelf = false
            } else if hidden {
                animatingView = snapshotViewAfterScreenUpdates(false)
                animateSelf = false
            } else {
                // Rendering the zero size snapshot view unfortunately results in a blank tab bar and snapshotViewAfterScreenUpdates(true) has horrifying behaviors.
                // For the most common case, we just let the tab bar animate in place.  If for some reason we show/hide the tab bar relatively fast, we'll compensate
                // by switching to the actual snapshot, which should look fine unless the tab bar width has changed since it was hidden.  In that case, the bar buttons
                // will be laid out with their original widths. This is the edge case of the edge case of the edge case so I don't care to take this too much further.
                self.frame = finalFrame
                animatingView = snapshotViewAfterScreenUpdates(false)
                animateSelf = true
            }
        }
        
        self.lastAnimatedView = (selectedItem, animatingView)
        self.frame = finalFrame
        super.hidden = hidden
        
        // Continue from the last position.
        if !alreadyAnimating {
            animatingView.frame.origin.y = initialFrame.minY
            self.superview?.addSubview(animatingView)
            currentAnimatingView = animatingView
        }
        
        if animateSelf {
            self.alpha = 1
            animatingView.alpha = 0
            self.frame = animatingView.frame
        } else {
            self.alpha = 0
            animatingView.alpha = 1
        }
        
        // This is a quick but reliable way to check if the animation was interrupted by a new one.
        let currentAnimation = NSObject()
        self.currentAnimation = currentAnimation
        
        UIView.animateWithDuration(NSTimeInterval(UINavigationControllerHideShowBarDuration), animations: { () -> Void in
            animatingView.frame.origin.y = finalFrame.minY
            if animateSelf {
                self.frame.origin.y = finalFrame.minY
            }
            alongsideAnimations()
            NSNotificationCenter.defaultCenter().postNotificationName(HidingTabBarVisibilityAnimatingNotification, object: self, userInfo: userInfo)
        }, completion: { (finished) -> Void in
            if self.currentAnimation === currentAnimation {
                self.alpha = 1
                self.currentAnimatingView = nil
                animatingView.removeFromSuperview()
            }
            completion(finished)
            NSNotificationCenter.defaultCenter().postNotificationName(HidingTabBarVisibilityDidChangeNotification, object: self, userInfo: userInfo)
        })
    }
    
    // The original snapshot does not include the tab bar background/border.
    override public func snapshotViewAfterScreenUpdates(afterUpdates: Bool) -> UIView {
        let parent = HidingTabBar(frame: frame)
        for subview in subviews where subview.frame != bounds {
            let snapshotView = subview.snapshotViewAfterScreenUpdates(afterUpdates)
            snapshotView.center = subview.center
            parent.addSubview(snapshotView)
        }
        return parent
    }
}

extension UITabBarController {
    
    public var tabBarHidden:Bool {
        get {
            return tabBar.hidden
        }
        set (tabBarHidden) {
            setTabBarHidden(tabBarHidden, animated: false)
        }
    }
    
    public func setTabBarHidden(tabBarHidden: Bool, animated: Bool) {
        
        guard let tabBar = tabBar as? HidingTabBar else {
            preconditionFailure("\(self.tabBar) is not a HidingTabBar.")
        }
        
        if tabBarHidden == tabBar.hidden {
            return
        }
        
        tabBar.setHidden(tabBarHidden, animated: animated, alongsideAnimations: { () -> Void in
            
            // This code triggers the child (most likely navigation) controller to update the scroll view insets and bottom layout guide.
            if let view = self.selectedViewController?.view {
                view.setNeedsLayout()
                view.layoutIfNeeded()
            }
            }, completion: { (_) -> Void in
        })
    }
}
