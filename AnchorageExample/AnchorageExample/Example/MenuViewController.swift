//
//  MenuViewController.swift
//  Anchorage
//
//  Created by (no data) on 26/01/2022.
//

import Foundation
import UIKit

extension MenuViewController: Anchoring {
    func anchors(for anchorable: Anchorable) -> [Anchor] { [topAnchor, centreAnchor] }
}

class MenuViewController: UIViewController {
    
    private static let padding: CGFloat = 16.0

    override func viewDidLoad() {
        title = "Anchorage"
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    // MARK: - Accessors
    
    private var topAnchorRect: CGRect { CGRect(origin: CGPoint(x: MenuViewController.padding,
                                                               y: view.bounds.size.height/2 - 220.0),
                                            size: CGSize(width: view.bounds.size.width - MenuViewController.padding*2,
                                                         height: 100.0)) }
    
    private var anchorRect: CGRect { CGRect(origin: CGPoint(x: MenuViewController.padding,
                                                            y: view.bounds.size.height/2 - 100.0),
                                            size: CGSize(width: view.bounds.size.width - MenuViewController.padding*2,
                                                         height: 200.0)) }
    
    private func topAnchorConstraints(for view: UIView) -> Anchor.Constraints {
        let padding = MenuViewController.padding
        return Anchor.Constraints(x: view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,
                                                                   constant: padding),
                                  y: view.bottomAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -120),
                                  w: view.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -padding*2),
                                  h: view.heightAnchor.constraint(equalToConstant: 100.0))
    }
    
    private func anchorConstraints(for view: UIView) -> Anchor.Constraints {
        let padding = MenuViewController.padding
        return Anchor.Constraints(x: view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,
                                                                   constant: padding),
                                  y: view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                                  w: view.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -padding*2),
                                  h: view.heightAnchor.constraint(equalToConstant: 200.0))
    }
    
    // MARK: - Properties
    
    private lazy var topAnchor = Anchor(view: view,
                                        constraints: { [weak self] v in self?.topAnchorConstraints(for: v) },
                                        interceptRect: { [weak self] in self?.topAnchorRect ?? .zero },
                                        highlight: { [weak self] in (self?.topAnchorRect ?? .zero, .blue) })
    
    private lazy var centreAnchor = Anchor(view: view,
                                           constraints: { [weak self] v in self?.anchorConstraints(for: v) },
                                           interceptRect: { [weak self] in self?.anchorRect ?? .zero },
                                           highlight: { [weak self] in (self?.anchorRect ?? .zero, .blue) })
}
