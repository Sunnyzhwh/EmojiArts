//
//  Utilities.swift
//  EmojiArt
//
//  Created by Sunny on 2019/7/11.
//  Copyright © 2019年 Sunny. All rights reserved.
//

import UIKit

class ImageFetcher {
    var backup: UIImage? { didSet{ callHandlerIfNeeded() } }
    func fetch(_ url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let data = try? Data(contentsOf: url.imageURL){
                if self != nil {
                    if let image = UIImage(data: data) {
                        self?.handler(url, image)
                    }else {
                        self?.fetchFailed = true
                    }
                }else {
                    print("ImageFetcher: fetch returned but I've left the heap -- ignoring result.")
                }
            }else {
                self?.fetchFailed = true
            }
        }
    }
    
    init(handler: @escaping (URL, UIImage) -> Void) {
        self.handler = handler
    }
    init(fetch url: URL, handler: @escaping (URL, UIImage) -> Void) {
        self.handler = handler
        fetch(url)
    }
    
    private let handler: (URL, UIImage) -> Void
    private var fetchFailed = false { didSet{ callHandlerIfNeeded() } }
    private func callHandlerIfNeeded() {
        if fetchFailed, let image = backup, let url = image.storeLocallyAsJPEG(named: String(Date().timeIntervalSinceReferenceDate)) {
            handler(url, image)
        }
    }
    
}
extension URL {
    var imageURL: URL {
        if let url = UIImage.urlToStoreLocallyAsJPEG(named: self.path){
            return url
        }else {
            for query in query?.components(separatedBy: "&") ?? [] {
                let queryComponents = query.components(separatedBy: "=")
                if queryComponents.count == 2 {
                    if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? "") {
                        return url
                    }
                }
            }
            return self.baseURL ?? self
        }
        
    }
}

extension UIImage {
    private static let localImagesDirectory = "UIImage.storeLocallyAsJPEG"
    static func urlToStoreLocallyAsJPEG(named: String) -> URL? {
        var name = named
        let pathComponents = name.components(separatedBy: "/")
        if pathComponents.count > 1 {
            if pathComponents[pathComponents.count-2] == localImagesDirectory {
                name = pathComponents.last!
            }else {
                return nil
            }
        }
        if var url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            url = url.appendingPathComponent(localImagesDirectory)
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                url = url.appendingPathComponent(name)
                if url.pathExtension != "jpg" {
                    url = url.appendingPathExtension("jpg")
                }
                return url
                
            }catch let error{
                print("UIImage.urlToStoreLocallyAsJPEG \(error)")
            }
        }
        return nil
    }
    func storeLocallyAsJPEG(named name: String) -> URL? {
        if let imageData = self.jpegData(compressionQuality: 1.0) {
            if let url = UIImage.urlToStoreLocallyAsJPEG(named: name) {
                do {
                    try imageData.write(to: url)
                    return url
                } catch let error {
                    print("UIImage.StoreLocallyAsJPEG \(error)")
                }
            }
        }
        return nil
    }
}
extension String{
    func madeUnique(withRespectTo otherStrings: [String]!) -> String {
        var possiblyUnique = self
        var uniqueNumber = 1
        while otherStrings.contains(possiblyUnique) {
            possiblyUnique = self + "\(uniqueNumber)"
            uniqueNumber += 1
        }
        return possiblyUnique
    }
}

extension Array where Element: Equatable {
    var uniquified: [Element] {
        var elements = [Element]()
        forEach  { if !elements.contains($0) { elements.append($0) } }
        return elements
    }
    
}

extension NSAttributedString {
    func withFontScaled(by factor: CGFloat) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.setFont(mutable.font?.scaled(by: factor))
        return mutable
    }
    var font: UIFont? {
        get { return attribute(.font,at: 0, effectiveRange: nil) as? UIFont }
    }
}

extension String {
    func attributedString(withTextStyle style: UIFont.TextStyle, ofSize size: CGFloat) -> NSAttributedString {
        let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(size))
        return NSAttributedString(string: self, attributes: [.font: font])
    }
}

extension NSMutableAttributedString {
    func setFont(_ newValue: UIFont?) {
        if newValue != nil { addAttributes([.font:newValue!], range: NSMakeRange(0, length)) }
    }
}
extension UIFont {
    func scaled(by factor: CGFloat) -> UIFont { return withSize(pointSize * factor) }
}
extension UILabel {
    func StretchToFit() {
        let oldCenter = center
        sizeToFit()
        center = oldCenter
    }
}
extension CGPoint {
    func offset(by delta: CGPoint) -> CGPoint {
        return CGPoint(x: x + delta.x, y: y + delta.y)
    }
}
extension UIViewController {
    var contents: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        }else {
            return self
        }
    }
}
extension UIView {
    var snapShot: UIImage? {
        UIGraphicsBeginImageContext(bounds.size)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
