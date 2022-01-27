//
//  ViewController.swift
//  AnchorageExample
//
//  Created by Anthony Smith on 27/01/2022.
//

import UIKit

extension ViewController: AnchoringRoot {
    var anchoringHighlightView: UIView { highlightView }
    func floatingAnchors(for anchorable: Anchorable) -> [Anchor] { cornerAnchors }
}

class ViewController: UIViewController {
    
    private static let cornerPadding: CGFloat = 16.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        view.addSubview(highlightView)
        
        let nav = UINavigationController(rootViewController: MenuViewController())
        
        addChild(nav)
        view.addSubview(nav.view)
        nav.view.translatesAutoresizingMaskIntoConstraints = false

        let buttonSize: CGFloat = 52.0
        let componentButton = UIButton(type: .custom)
        componentButton.translatesAutoresizingMaskIntoConstraints = false
        componentButton.backgroundColor = .blue
        componentButton.setTitleColor(.white, for: .normal)
        componentButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 50.0)
        componentButton.setTitle("+", for: .normal)
        componentButton.layer.cornerRadius = buttonSize/2
        componentButton.addTarget(self, action: #selector(componentButtonTapped), for: .touchUpInside)
        view.addSubview(componentButton)
        
        NSLayoutConstraint.activate([
            nav.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nav.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            nav.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            nav.view.heightAnchor.constraint(equalTo: view.heightAnchor),
            
            componentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            componentButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20.0),
            componentButton.widthAnchor.constraint(equalToConstant: buttonSize),
            componentButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }
    
    @objc private func componentButtonTapped() {
        present(ComponentMenuViewController(), animated: true, completion: nil)
    }

    // MARK: - Accessors
    
    // Note how the intercept rects take up 1/4 of the screen so that
    // we always have a fall back and catch a loose Anchorable
    // If you prefer to lose the Anchorable, simply do not add these
    // and the default behaviour is to removeFromSuperView

    // Check out NoData.Pin for more readable NSLayoutConstraints

    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
        
        func xConstraint(for anchorable: UIView, in view: UIView) -> NSLayoutConstraint {
            switch self {
            case .topLeft, .bottomLeft:
                return anchorable.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                           constant: ViewController.cornerPadding)
            case .topRight, .bottomRight:
                return anchorable.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                            constant: -ViewController.cornerPadding)
            }
        }
        
        func yConstraint(for anchorable: UIView, in view: UIView) -> NSLayoutConstraint {
            switch self {
            case .topLeft, .topRight:
                return anchorable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                       constant: ViewController.cornerPadding)
            case .bottomLeft, .bottomRight:
                return anchorable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                          constant: -ViewController.cornerPadding)
            }
        }
        
        func interceptRect(in view: UIView?) -> CGRect? {
            
            guard let view = view else { return nil }
            
            let origin: CGPoint
            switch self {
            case .topLeft:
                origin = .zero
            case .topRight:
                origin = CGPoint(x: view.bounds.size.width/2, y: 0.0)
            case .bottomLeft:
                origin = CGPoint(x: 0.0, y: view.bounds.size.height/2)
            case .bottomRight:
                origin = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
            }
            
            return CGRect(origin: origin,
                          size: CGSize(width: view.bounds.size.width/2, height: view.bounds.size.height/2))
        }
    }
    
    private func constraints(for anchorable: UIView, at corner: Corner) -> Anchor.Constraints {
        Anchor.Constraints(x: corner.xConstraint(for: anchorable, in: view),
                           y: corner.yConstraint(for: anchorable, in: view),
                           w: widthConstraint(for: anchorable),
                           h: heightConstraint(for: anchorable))
    }
    
    private func widthConstraint(for anchorable: UIView) -> NSLayoutConstraint {
        anchorable.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.44)
    }
    
    private func heightConstraint(for anchorable: UIView) -> NSLayoutConstraint {
        anchorable.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.33)
    }
    
    // MARK: - Properties
    
    private lazy var highlightView: UIView = {
        let view = UIView()
        view.alpha = 0.0
        return view
    }()
    
    private lazy var cornerAnchors: [Anchor] = {
        
        let tl = Anchor(view: view,
                        constraints: { [weak self] v in self?.constraints(for: v, at: .topLeft) },
                        interceptRect: { [weak self] in Corner.topLeft.interceptRect(in: self?.view) ?? .zero })
        
        let tr = Anchor(view: view,
                        constraints: { [weak self] v in self?.constraints(for: v, at: .topRight) },
                        interceptRect: { [weak self] in Corner.topRight.interceptRect(in: self?.view) ?? .zero })
        
        let br = Anchor(view: view,
                        constraints: { [weak self] v in self?.constraints(for: v, at: .bottomRight) },
                        interceptRect: { [weak self] in Corner.bottomRight.interceptRect(in: self?.view) ?? .zero })
        
        let bl = Anchor(view: view,
                        constraints: { [weak self] v in self?.constraints(for: v, at: .bottomLeft) },
                        interceptRect: { [weak self] in Corner.bottomLeft.interceptRect(in: self?.view) ?? .zero })

        return [tl, tr, br, bl]
    }()
}


