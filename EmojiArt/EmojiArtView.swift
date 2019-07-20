//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Sunny on 2019/7/11.
//  Copyright © 2019年 Sunny. All rights reserved.
//

import UIKit

protocol EmojiArtViewDelegate: class {
    func emojiArtViewDidChange(_ sender: EmojiArtView)
}

extension Notification.Name {
    static let EmojiArtViewDidChange = Notification.Name("EmojiArtViewDidChange")
}

class EmojiArtView: UIView, UIDropInteractionDelegate
{
    //MARK: -Delegation
    weak var delegate: EmojiArtViewDelegate?
    
    //MARK: -Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        addInteraction(UIDropInteraction(delegate: self))
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: NSAttributedString.self) { providers in
            let dropPoint = session.location(in: self)
            for attributedString in providers as? [NSAttributedString] ?? [] {
                self.addlabel(with: attributedString, centerdAt: dropPoint)
                self.delegate?.emojiArtViewDidChange(self)
                NotificationCenter.default.post(name: .EmojiArtViewDidChange, object: self)
            }
        }
    }
    
    private var labelObservations = [UIView:NSKeyValueObservation]()
    
    func addlabel(with attributedString: NSAttributedString, centerdAt point: CGPoint) {
        let label = UILabel()
        label.backgroundColor = .clear
        label.attributedText = attributedString
        label.sizeToFit()
        label.center = point
        addEmojiArtGestureRecognizers(to: label)
        addSubview(label)
        labelObservations[label] = label.observe(\.center) { (label, change) in
            self.delegate?.emojiArtViewDidChange(self)
            NotificationCenter.default.post(name: .EmojiArtViewDidChange, object: self)
        }
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        if labelObservations[subview] != nil {
            labelObservations[subview] = nil
        }
    }
    
    var backgroundImage: UIImage! {didSet{setNeedsDisplay()}}
    override func draw(_ rect: CGRect) {
       backgroundImage?.draw(in: bounds)
    }
   

}
