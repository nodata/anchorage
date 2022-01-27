//
//  Anchorage.swift
//  Anchorage
//
//  Created by (no data) on 26/01/2022.
//

import Foundation
import UIKit

// Anchorable: a UIView that can be dragged around and attached to an Anchor

protocol Anchorable: UIView {

    var liftThreshold: CGFloat { get }
    func floatingSize(in view: UIView) -> CGSize?
    var state: AnchorableState { get set }
    
    func willStartFloating()
    func didStartFloating()
    func didAttach(to anchor: Anchor)
}

// Sadly it can't be nested inside Anchorable
class AnchorableState {
    var isFloating = false
    var initialTouchPoint: CGPoint = .zero
    var anchor: Anchor?
    var constraints: Anchor.Constraints?
}

extension Anchorable {
    
    // Override this when you'd like the Anchorable to resist being dragged off the view
    // either completely by setting some huge value or slightly to protect against other gestures / mistakes
    var liftThreshold: CGFloat { 0.0 }
    
    // There is a default 4:3 size for Anchorables being dragged around the RootView
    // but you can override that here
    func floatingSize(in view: UIView) -> CGSize? { nil }

    // Designed to provide you with information to determine lift threshold etc.. override this at your own risk.
    var state: AnchorableState {
        get {
            if let state = objc_getAssociatedObject(self, &AssociatedKeys.reference) as? AnchorableState {
                return state
            }
            let new = AnchorableState()
            state = new
            return new
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.reference, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // Again these are designed to help you make decisions on what to do with your Anchorable
    // setting shadows, UI state, external state etc
    func willStartFloating() { }
    func didStartFloating() { }
    func didAttach(to anchor: Anchor) { }
}

// Anchoring: a UIView or UIViewController that contains Anchors

protocol Anchoring {
    func anchors(for anchorable: Anchorable) -> [Anchor]
}

// AnchoringRoot: The RootViewController that allows the Anchorables to
// float over the rest of the UI and to highlight anchor locations

protocol AnchoringRoot: UIViewController {
    var anchoringHighlightView: UIView { get }
    func floatingAnchors(for anchorable: Anchorable) -> [Anchor]
}

// Anchor: The model that creates and maintains where the Anchorable can go
// and how it interacts with the Anchoring objects

class Anchor {
    
    enum Priority: Comparable {
        case high, normal, low, custom(UInt)
        
        var value: UInt {
            switch self {
            case .high:    return 1000
            case .normal:  return 500
            case .low:     return 100
            case .custom(let value): return value
            }
        }
        
        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.value < rhs.value
        }
    }
    
    struct Constraints {
        let x: NSLayoutConstraint
        let y: NSLayoutConstraint
        let w: NSLayoutConstraint?
        let h: NSLayoutConstraint?
        
        var all: [NSLayoutConstraint] { [x,y,w,h].compactMap { $0 } }
    }

    let view: UIView
    let priority: Priority
    let constraints: ((UIView) -> Constraints?)
    let interceptRect: (() -> CGRect)
    let highlight: (() -> (CGRect, UIColor))?

    weak var anchored: Anchorable?
    
    init(view: UIView,
         priority: Priority = .normal,
         constraints: @escaping ((UIView) -> Constraints?),
         interceptRect: @escaping (() -> CGRect),
         highlight: (() -> (CGRect, UIColor))? = nil) {
        
        self.constraints = constraints
        self.view = view
        self.priority = priority
        self.interceptRect = interceptRect
        self.highlight = highlight
    }
}

// Implementation

extension UIView {
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let self = self as? Anchorable else { return }
        self.began(touches, with: event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let self = self as? Anchorable else { return }
        self.moved(touches, with: event)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let self = self as? Anchorable else { return }
        self.ended(touches, with: event)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard let self = self as? Anchorable else { return }
        self.ended(touches, with: event)
    }
    
    fileprivate func removeAllConstraints() {
        var superview = self.superview
        while let s = superview {
            s.constraints.forEach {
                if let first = $0.firstItem as? UIView, first == self { s.removeConstraint($0) }
                if let second = $0.secondItem as? UIView, second == self { s.removeConstraint($0) }
            }
            superview = s.superview
        }
        removeConstraints(constraints)
    }
}

extension Anchorable {
    
    fileprivate func began(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController as? AnchoringRoot else { return }
        guard let rootView = root.view else { return }
        let location = touches.first?.location(in: rootView) ?? .zero
        state.initialTouchPoint = location
    }
    
    fileprivate func moved(_ touches: Set<UITouch>, with event: UIEvent?)  {
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController as? AnchoringRoot else { return }
        guard let rootView = root.view else { return }
        let location = touches.first?.location(in: rootView) ?? .zero

        if state.isFloating {
            state.constraints?.x.constant = location.x - bounds.size.width/2
            state.constraints?.y.constant = location.y - bounds.size.height/2
            highlightAnchor(at: center, with: self)
        } else if abs(location.x - state.initialTouchPoint.x) > liftThreshold
                    || abs(location.y - state.initialTouchPoint.y) > liftThreshold {
            willStartFloating()
            attachToRootView(touches, with: event)
            state.isFloating = true
            didStartFloating()
        }
    }
    
    fileprivate func ended(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController as? AnchoringRoot else { return }
        guard let rootView = root.view else { return }
        let location = touches.first?.location(in: rootView) ?? .zero
        attach(at: location)
        state.isFloating = false
    }
    
    private func attachToRootView(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let rootView = UIApplication.shared.keyWindowScene?.rootViewController?.view else { return }
                
        state.anchor?.anchored = nil
        removeAllConstraints()
        alpha = 0.8
        
        if superview != rootView { rootView.addSubview(self) }
        
        let p = rootView.convert(frame.origin, to: nil)
        let size = floatingSize(in: rootView) ?? CGSize(width: rootView.bounds.size.width * 0.4,
                                                        height: rootView.bounds.size.width * 0.3)
        
        let newConstraints = Anchor.Constraints(x: leadingAnchor.constraint(equalTo: rootView.leadingAnchor,
                                                                            constant: p.x),
                                                y: topAnchor.constraint(equalTo: rootView.topAnchor,
                                                                        constant: p.y),
                                                w: widthAnchor.constraint(equalToConstant: size.width),
                                                h: heightAnchor.constraint(equalToConstant: size.height))
        
        NSLayoutConstraint.activate(newConstraints.all)
        rootView.setNeedsLayout()
        setNeedsLayout()

        UIView.animate(withDuration: 0.4,
                       delay: 0.0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.1,
                       options: [.beginFromCurrentState, .curveEaseOut]) {
                                rootView.layoutIfNeeded()
                                self.layoutIfNeeded() }
                       completion: { _ in }
        
        state.constraints = newConstraints
    }
    
    private func attach(at point: CGPoint) {
        if let main = anchor(at: point) {
            attach(to: main, animated: true)
        } else if let floating = (UIApplication.shared.keyWindowScene?.rootViewController as? AnchoringRoot)?
                                            .floatingAnchors(for: self)
                                            .filter({ $0.interceptRect().contains(point) }).first {
            attach(to: floating, animated: true)
        } else {
            removeFromSuperview()
        }
    }
    
    private func attach(to anchor: Anchor, animated: Bool) {

        guard let newConstraints = anchor.constraints(self) else { return }
        translatesAutoresizingMaskIntoConstraints = false
        alpha = 1.0
        removeAllConstraints()

        if let root = UIApplication.shared.keyWindowScene?.rootViewController as? AnchoringRoot {
            root.anchoringHighlightView.alpha = 0.0
        }
        
        if superview != anchor.view { anchor.view.addSubview(self) }

        anchor.anchored = self
        state.anchor = anchor
        
        guard animated else {
            NSLayoutConstraint.activate(newConstraints.all);
            didAttach(to: anchor)
            return
        }
        
        let p = anchor.view.convert(frame.origin, to: anchor.view)
        NSLayoutConstraint.activate(Anchor.Constraints(x: leadingAnchor.constraint(equalTo: anchor.view.leadingAnchor,
                                                                                   constant: p.x),
                                                       y: topAnchor.constraint(equalTo: anchor.view.topAnchor,
                                                                               constant: p.y),
                                                       w: widthAnchor.constraint(equalToConstant: frame.size.width),
                                                       h: heightAnchor.constraint(equalToConstant: frame.size.height)).all)
        anchor.view.setNeedsLayout()
        anchor.view.layoutIfNeeded()

        removeAllConstraints()
        NSLayoutConstraint.activate(newConstraints.all)
        anchor.view.setNeedsLayout()

        UIView.animate(withDuration: 0.4,
                       delay: 0.0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.2,
                       options: [.beginFromCurrentState, .curveEaseOut]) {
            anchor.view.layoutIfNeeded()
        } completion: { _ in
            self.didAttach(to: anchor)
        }
    }
    
    private func anchor(at point: CGPoint) -> Anchor? {
        
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController else { return nil }
        var viewControllers = [UIViewController]()
        var views = [UIView]()

        func applyTo(view: UIView) {
            guard !view.isHidden && view.alpha != 0.0 else { return }
            if let v = view as? UIStackView {
                v.arrangedSubviews.forEach { applyTo(view: $0) }
            } else {
                view.subviews.forEach { applyTo(view: $0) }
                if view as? Anchoring != nil { views.append(view) }
            }
        }
        
        // Potentially needs work as there's lots of possible edge cases depending on layout.
        func applyTo(viewController: UIViewController) {
                     
            if viewController.isTop {
                applyTo(view: viewController.view)
                if viewController as? Anchoring != nil { viewControllers.append(viewController) }
                viewController.children.forEach { applyTo(viewController: $0) }
            }
   
            if let presented = viewController.presentedViewController {
                if presented as? Anchoring != nil { viewControllers.append(presented) }
                applyTo(viewController: presented)
            }
            
            if let navigationController = viewController as? UINavigationController,
               let last = navigationController.viewControllers.last {
                    applyTo(viewController: last)
            }
        }
        
        // TODO: translate to global rect
        applyTo(viewController: root)
        let vcAnchors = Set(viewControllers).flatMap { ($0 as? Anchoring)!.anchors(for: self) }
        let viewAnchors = Set(views).flatMap { ($0 as? Anchoring)!.anchors(for: self) }
        return (vcAnchors + viewAnchors)
                    .filter { $0.interceptRect().contains(point) && ($0.anchored == nil || $0.anchored == self)  }
                    .sorted { $0.priority > $1.priority }.first
    }

    private func highlightAnchor(at point: CGPoint, with view: Anchorable) {
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController as? AnchoringRoot else { return }
        guard let highlight = anchor(at: point)?.highlight?() else {
            UIView.animate(withDuration: 0.1,
                           delay: 0.0,
                           options: [.curveEaseInOut, .beginFromCurrentState]) { root.anchoringHighlightView.alpha = 0.0 }
                           completion: { _ in }
            return
        }

        root.view.bringSubviewToFront(root.anchoringHighlightView)
        root.view.bringSubviewToFront(view)
        
        root.anchoringHighlightView.frame = highlight.0
        root.anchoringHighlightView.layer.borderWidth = 2.0
        root.anchoringHighlightView.layer.borderColor = highlight.1.cgColor
        root.anchoringHighlightView.backgroundColor = highlight.1.withAlphaComponent(0.7)
        
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            root.anchoringHighlightView.alpha = 1.0
        } completion: { _ in }
    }
}

private extension UIApplication {
    var keyWindowScene: UIWindow? {
        connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows.filter({$0.isKeyWindow}).first
    }
}

private extension UIViewController {
    
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

private struct AssociatedKeys {
    static var reference = "reference"
}
