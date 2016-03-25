# HidingTabBar

A UITabBar subclass you can hide.  Yes, you can use `ViewController.hidesBottomBarWhenPushed`, and I did for a very long time, but I needed more fine-grained control for adaptive layout on iPads.

## Demo

Open and run the project in Xcode 7.3+ *(thanks swift)*. [Slowmo Video](https://www.youtube.com/watch?v=LHrEn0QSw78). [Released app](https://itunes.apple.com/us/app/stack-exchange/id871299723?mt=8).

## Instructions

1. Drop HidingTabBar.swift into your app.
2. In your storyboard, set your UITabBarController's tab bar's class to HidingTabBar.  There is literally no way to do this in code or a regular xib.
3. Call `UITabBarController.setTabBarHidden(_:animated:)`, preferably when nothing else it animating.
   I like to do it in a [`UINavigationControllerDelegate`](WhyTabBarWhy/FirstViewController.swift).

## Warnings

Lots of assumptions. Zero tests.