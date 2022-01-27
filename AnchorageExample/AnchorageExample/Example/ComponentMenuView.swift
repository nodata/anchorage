//
//  ComponentMenuViewController.swift
//  Anchorage
//
//  Created by (no data) on 27/01/2022.
//

import Foundation
import UIKit


class ComponentMenuView: UIView {
    
    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isUserInteractionEnabled = true
        titleLabel.text = "Anchor"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 50.0)
        
        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.isUserInteractionEnabled = true
        bodyLabel.text = "Noun: a heavy object attached to a rope or chain and used to moor a vessel to the sea bottom, typically one having a metal shank with a ring at one end for the rope and a pair of curved and/or barbed flukes at the other."
        bodyLabel.numberOfLines = 0
        
        let colorView = ChangingColorView()
        colorView.translatesAutoresizingMaskIntoConstraints = false

        let anchorImageView = UIImageView(image: UIImage(named: "anchor")?.withRenderingMode(.alwaysTemplate))
        anchorImageView.translatesAutoresizingMaskIntoConstraints = false
        anchorImageView.isUserInteractionEnabled = true
        anchorImageView.contentMode = .scaleAspectFit
        anchorImageView.tintColor = .blue
        
        let blackAnchorImageView = UIImageView(image: UIImage(named: "anchor"))
        blackAnchorImageView.isUserInteractionEnabled = true
        blackAnchorImageView.translatesAutoresizingMaskIntoConstraints = false
        blackAnchorImageView.contentMode = .scaleAspectFit
        
        addSubview(titleLabel)
        addSubview(bodyLabel)
        addSubview(colorView)
        addSubview(anchorImageView)
        addSubview(blackAnchorImageView)

        let padding = 16.0
        let size = 52.0
        let bottomPadding = 40.0
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(bottomPadding + 110 + padding + size)),

            bodyLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(bottomPadding + padding + size)),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            
            colorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomPadding),
            colorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            colorView.widthAnchor.constraint(equalToConstant: size),
            colorView.heightAnchor.constraint(equalToConstant: size),
            
            anchorImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomPadding),
            anchorImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            anchorImageView.widthAnchor.constraint(equalToConstant: size),
            anchorImageView.heightAnchor.constraint(equalToConstant: size),
            
            blackAnchorImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomPadding),
            blackAnchorImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            blackAnchorImageView.widthAnchor.constraint(equalToConstant: size),
            blackAnchorImageView.heightAnchor.constraint(equalToConstant: size)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ChangingColorView: UIView, Anchorable {
    
    func floatingSize(in view: UIView) -> CGSize? { CGSize(width: view.bounds.size.width * 0.25,
                                                           height: view.bounds.size.width * 0.25)}
    
    var liftThreshold: CGFloat { 30.0 }
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .red
        clipsToBounds = true
        layer.cornerRadius = 4.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func willStartFloating() {
        // This is a hack to dismiss the component library.. obviously don't do this in a production app
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController as? ViewController else { return }
        guard superview != root.view else { return }
        root.hideMenu()
    }
    
    func didStartFloating() {
        backgroundColor = .green
    }
    
    func didAttach(to anchor: Anchor) {
        backgroundColor = .red
    }
}

extension UIImageView: Anchorable {
    func willStartFloating() {
        // Normally I'd doubt you'd ever want generic components like UIImageView to have these overridden
        // unless you're adding shadows or updating the view itself in some way
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController as? ViewController else { return }
        guard superview != root.view else { return }
        root.hideMenu()
    }
}
extension UILabel: Anchorable {
    
    func floatingSize(in view: UIView) -> CGSize? { CGSize(width: view.frame.size.width * 0.8,
                                                           height: bounds.size.height) }
    
    func willStartFloating() {
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController as? ViewController else { return }
        guard superview != root.view else { return }
        root.hideMenu()
    }
}

// Copied for the hack
private extension UIApplication {
    var keyWindowScene: UIWindow? {
        connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows.filter({$0.isKeyWindow}).first
    }
}
