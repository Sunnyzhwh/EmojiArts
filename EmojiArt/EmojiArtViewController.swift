//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Sunny on 2019/7/11.
//  Copyright © 2019年 Sunny. All rights reserved.
//

import UIKit

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UICollectionViewDragDelegate, UICollectionViewDropDelegate, UIPopoverPresentationControllerDelegate
{
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Documentinfo" {
            if let destination = segue.destination.contents as? DocumentinfoViewController {
                document?.thumbnail = emojiArtView.snapShot
                destination.document = document
                if let ppc = destination.popoverPresentationController {
                    ppc.delegate = self
                }
            }
        }else if segue.identifier == "Embed Document Info" {
            embeddedDocumentInfo = segue.destination.contents as? DocumentinfoViewController
        }
    }
    
    private var embeddedDocumentInfo: DocumentinfoViewController?
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    @IBAction func close(bySegue: UIStoryboardSegue) {
        close()
    }
    
    @IBOutlet weak var embeddedDocinfoHeight: NSLayoutConstraint!
    
    @IBOutlet weak var embeddedDocinfoWidth: NSLayoutConstraint!
    
    // MARK: -Model
    
    var emojiArt: EmojiArt? {
        get{
            if let url = emojiArtBackgroundImage.url {
                let emojis = emojiArtView.subviews.compactMap { $0 as? UILabel }.compactMap { EmojiArt.EmojiInfo(label: $0) }
                return EmojiArt(url: url, emojis: emojis)
            }
            return nil
        }
        set{
//            emojiArtBackgroundImage = (nil,nil)
//            emojiArtView.subviews.compactMap { $0 as? UILabel }.forEach { $0.removeFromSuperview() }
            if let url = newValue?.url {
                imageFetcher = ImageFetcher(fetch: url ) { (url, image) in
                    DispatchQueue.main.async {
                        self.emojiArtBackgroundImage = (url, image)
                        newValue?.emojis.forEach {
                            let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
                            self.emojiArtView.addlabel(with: attributedText, centerdAt: CGPoint(x:$0.x, y:$0.y))
                        }
                    }
                }
            }
        }
    }
    
    var document: EmojiArtDocument?
    
//    @IBAction func save(_ sender: UIBarButtonItem? = nil) {
//        document?.emojiArt = emojiArt
//        if document?.emojiArt != nil {
//            document?.updateChangeCount(.done)
//        }
//    }
    
    @IBAction func close(_ sender: UIBarButtonItem? = nil ) {
//        save()
        if let observer = emojiArtViewObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if document?.emojiArt != nil {
            document?.thumbnail = emojiArtView.snapShot
        }
        presentingViewController?.dismiss(animated: true){
            self.document?.close { success in
                if let observer = self.documentObserver {
                    NotificationCenter.default.removeObserver(observer)
                    }
                
                }
            }
    }
    
    private var documentObserver: NSObjectProtocol?
    
    private var emojiArtViewObserver: NSObjectProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        documentObserver = NotificationCenter.default.addObserver(
            forName: UIDocument.stateChangedNotification,
            object: document,
            queue: OperationQueue.main,
            using: { notification in
                print("DocumentState changed to \(self.document!.documentState) ")
                if self.document!.documentState == .normal, let docInfoVC = self.embeddedDocumentInfo {
                    docInfoVC.document = self.document
                    self.embeddedDocinfoWidth.constant = docInfoVC.preferredContentSize.width
                    self.embeddedDocinfoHeight.constant = docInfoVC.preferredContentSize.height
                }
            }
        )
        document?.open { success in
            if success {
                self.title = self.document?.localizedName
                self.emojiArt = self.document?.emojiArt
                self.emojiArtViewObserver = NotificationCenter.default.addObserver(
                    forName: .EmojiArtViewDidChange,
                    object: self.emojiArtView,
                    queue: OperationQueue.main,
                    using: { notification in
                        self.documentChanged()
                    }
                )
            }
        }
    }
    
    func documentChanged() {
        document?.emojiArt = emojiArt
        if emojiArt != nil {
            document?.updateChangeCount(.done)
        }
    }
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        if let url = try? FileManager.default.url(
//            for: .documentDirectory,
//            in: .userDomainMask,
//            appropriateFor: nil,
//            create: true
//            ).appendingPathComponent("Untitled.json") {
//            document = EmojiArtDocument(fileURL: url)
//        }
//    }
    
    private var addingEmoji = false
   
    @IBAction func addEmoji() {
        addingEmoji = true
        emojiCollectionView.reloadSections(IndexSet(integer: 0))
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int ) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return emojis.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
            if let emojiCell = cell as? EmojiCollectionViewCell {
                let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font:font])
                emojiCell.label.attributedText = text
            }
            return cell
        }else if addingEmoji {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell", for: indexPath)
            if let inputCell = cell as? TextFieldCollectionViewCell {
                inputCell.resignationHandler = { [weak self, unowned inputCell ] in
                    if let text = inputCell.textField.text {
                        self?.emojis = (text.map { String($0) } + self!.emojis).uniquified
                    }
                    self?.addingEmoji = false
                    self?.emojiCollectionView.reloadData()
                }
            }
            return cell
        }else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if addingEmoji && indexPath.section == 0 {
            return CGSize(width: 300, height: 80)
        }else {
            return CGSize(width: 80, height: 80)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let inputCell = cell as? TextFieldCollectionViewCell {
            inputCell.textField.becomeFirstResponder()
        }
    }

    @IBOutlet weak var dropZone: UIView!{
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    //MARK: EmojiArtView
    
    var emojiArtView = EmojiArtView()
    
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeight.constant = scrollView.contentSize.height
        scrollViewWidth.constant = scrollView.contentSize.width
    }
    
    //MARK: -EmojiArtViewDelegate
    
    func emojiArtViewDidChange(_ sender: EmojiArtView) {
        documentChanged()
    }
    
    private var _emojiArtBackgroundImageURL: URL?
    
    var emojiArtBackgroundImage: (url:URL?, image:UIImage?) {
        get {
            return (_emojiArtBackgroundImageURL!, emojiArtView.backgroundImage)
        }
        set {
            _emojiArtBackgroundImageURL = newValue.url
            scrollView?.zoomScale = 1.0
            emojiArtView.backgroundImage = newValue.image
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView?.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
                scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
            }
        }
    }
    
//    var emojis = "🐻😀🌶🍎🥦🚲🛵🛴🚑🚅🎹🎲🎬✈️💡".map { hhhh in
//        return String(hhhh)
//    }
    var emojis = "🐻😀🌶🍎🥦🚲🛵🛴🚑🚅🎹🎲🎬✈️💡".map { String($0) }
    
    @IBOutlet weak var emojiCollectionView: UICollectionView! {
        didSet {
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
            emojiCollectionView.dragInteractionEnabled = true
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return emojis.count
//    }
    
    private var font: UIFont {
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
//        if let emojiCell = cell as? EmojiCollectionViewCell {
//            let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font : font])
//            emojiCell.label.attributedText = text
//        }
//        return cell
//    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if !addingEmoji,let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
            dragItem.localObject = attributedString
            return [dragItem]
        }else {
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                if let attributedString = item.dragItem.localObject as? NSAttributedString {
                    collectionView.performBatchUpdates ({
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(attributedString.string, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            }else {
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self) { (provider, error) in
                    DispatchQueue.main.sync {
                        if let attributedString = provider as? NSAttributedString {
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                            })
                        }else {
                            placeholderContext.deletePlaceholder()
                        }
                    }
                    
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath, indexPath.section == 1 {
            let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
            return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
        }else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    var imageFetcher: ImageFetcher!
    
    private var suppressBadURLWarings = false
    
    private func presentBadURLWarning(for url: URL?) {
        if !suppressBadURLWarings {
            let alert = UIAlertController(
                title: "Image Transfer Failed",
                message: "Couldn't transfer image from its source.\nShow this waring in the future?",
                preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(
                title: "Keep Waring",
                style: .default
                ))
            
            alert.addAction(UIAlertAction(
                title: "Stop Waring",
                style: .destructive,
                handler: { action in
                    self.suppressBadURLWarings = true
                }
            ))
            
            present(alert,animated: true)
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = (url,image)
                self.documentChanged()
            }
        }
        session.loadObjects(ofClass: NSURL.self) { nsurls in
            if let url = nsurls.first as? URL {
//                self.imageFetcher.fetch(url)
                DispatchQueue.global(qos: .userInitiated).async {
                    if let imageData = try? Data(contentsOf: url.imageURL), let image = UIImage(data: imageData) {
                        DispatchQueue.main.async {
                            self.emojiArtBackgroundImage = (url, image)
                            self.documentChanged()
                        }
                    }else {
                        self.presentBadURLWarning(for: url)
                    }
                }
            }
        }
        session.loadObjects(ofClass: UIImage.self) { images in
            if let image = images.first as? UIImage {
                self.imageFetcher.backup = image
            }
            
        }

    }
}

extension EmojiArt.EmojiInfo {
    init?(label: UILabel) {
        if let attributedText = label.attributedText, let font = attributedText.font {
            x = Int(label.center.x)
            y = Int(label.center.y)
            text = attributedText.string
            size = Int(font.pointSize)
        }
        else {
            return nil
        }
    }
}
