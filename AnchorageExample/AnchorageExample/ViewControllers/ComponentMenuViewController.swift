//
//  ComponentMenuViewController.swift
//  Anchorage
//
//  Created by (no data) on 27/01/2022.
//

import Foundation
import UIKit


class ComponentMenuViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
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
        
        view.addSubview(titleLabel)
        view.addSubview(bodyLabel)
        view.addSubview(colorView)
        view.addSubview(anchorImageView)
        view.addSubview(blackAnchorImageView)

        let padding = 16.0
        let size = 52.0
        
        // Ideally this would all be in a tableview but I'm lazy
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            titleLabel.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: -(150 + padding + size/2)),

            bodyLabel.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: -(padding + size/2)),
            bodyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            bodyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            
            colorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            colorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            colorView.widthAnchor.constraint(equalToConstant: size),
            colorView.heightAnchor.constraint(equalToConstant: size),
            
            anchorImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            anchorImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            anchorImageView.widthAnchor.constraint(equalToConstant: size),
            anchorImageView.heightAnchor.constraint(equalToConstant: size),
            
            blackAnchorImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            blackAnchorImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            blackAnchorImageView.widthAnchor.constraint(equalToConstant: size),
            blackAnchorImageView.heightAnchor.constraint(equalToConstant: size)
        ])
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
    
    func didStartFloating() {
        backgroundColor = .green
        
        // This is a hack to dismiss the component library.. obviously don't do this in a production app
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController else { return }
        root.presentedViewController?.dismiss(animated: true)
    }
    
    func didAttach(to anchor: Anchor) {
        backgroundColor = .red
    }
}

extension UIImageView: Anchorable {
    func didStartFloating() {
        // Normally I'd doubt you'd ever want generic components like UIImageView to have these overridden
        // unless you're adding shadows or updating the view itself in some way
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController else { return }
        root.presentedViewController?.dismiss(animated: true)
    }
}
extension UILabel: Anchorable {
    func didStartFloating() {
        guard let root = UIApplication.shared.keyWindowScene?.rootViewController else { return }
        root.presentedViewController?.dismiss(animated: true)
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
