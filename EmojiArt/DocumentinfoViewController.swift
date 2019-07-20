//
//  DocumentinfoViewController.swift
//  EmojiArt
//
//  Created by Sunny on 2019/7/20.
//  Copyright © 2019年 Sunny. All rights reserved.
//

import UIKit

class DocumentinfoViewController: UIViewController {
    
    var document: EmojiArtDocument? {
        didSet{updateUI()}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    private let shortDateFomatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func updateUI() {
        if sizeLabel != nil, createLabel != nil, let url = document?.fileURL,
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
            sizeLabel.text = "\(attributes[.size] ?? 0) bytes"
            if let created = attributes[.creationDate] as? Date {
                createLabel.text = shortDateFomatter.string(from: created)
            }
        }
        if thumbnailImageView != nil, let thumbnail = document?.thumbnail {
            thumbnailImageView.image = thumbnail
            thumbnailImageView.removeConstraint(thumbnailAspectRatio)
            thumbnailAspectRatio = NSLayoutConstraint(
                item: thumbnailImageView,
                attribute: .width,
                relatedBy: .equal,
                toItem: thumbnailImageView,
                attribute: .height,
                multiplier: thumbnail.size.width / thumbnail.size.height,
                constant: 0)
            thumbnailImageView.addConstraint(thumbnailAspectRatio)
        }
        if presentationController is UIPopoverPresentationController {
            thumbnailImageView?.isHidden = true
            returnToDocumentButton?.isHidden = true
            view.backgroundColor = .clear
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let fittedSize = topLevelView?.sizeThatFits(UIView.layoutFittingCompressedSize) {
            preferredContentSize = CGSize(width: fittedSize.width + 30 , height: fittedSize.height + 30)
        }
    }
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet var thumbnailAspectRatio: NSLayoutConstraint!
    
    @IBOutlet weak var returnToDocumentButton: UIButton!
    @IBOutlet weak var topLevelView: UIStackView!
    @IBAction func done() {
        presentingViewController?.dismiss(animated: true)
    }
    @IBOutlet weak var createLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
}
