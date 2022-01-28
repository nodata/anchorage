//
//  RequiredExtensions.swift
//  AnchorageExample
//
//  Created by Anthony Smith on 28/01/2022.
//

import Foundation
import UIKit

extension UIApplication {
    var keyWindowScene: UIWindow? {
        connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows.filter({$0.isKeyWindow}).first
    }
}

extension UIViewController {
    
    var isVisible: Bool {
        guard isViewLoaded else { return false }
        return view.window != nil
    }
    
    var isTop: Bool {
        if navigationController != nil {
            return navigationController?.visibleViewController == self
        } else if tabBarController != nil {
            return tabBarController?.selectedViewController == self && presentedViewController == nil
        } else {
            return presentedViewController == nil && self.isVisible
        }
    }
}
