# HidingTabBar

A UITabBar subclass you can hide.  I may package eventually but I've got to ship my app first.  
No guarantees that anything good can come from using this.  Tested only in iOS9 simulator.

## Demo

Open and run the project in Xcode 7. [Slowmo Video](https://www.youtube.com/watch?v=LHrEn0QSw78)

## Instructions

1. Drop HidingTabBar.swift into your app.
2. In your storyboard/xib, set your UITabBarController's custom class to HidingTabBar.
3. Call `UITabBarController.setTabBarHidden(_:animated:)`, preferably when nothing else it animating.
   I like to do it in a `UINavigationControllerDelegate`.

## Warnings

I made this today.  It makes some (possibly wrong) assumptions.
