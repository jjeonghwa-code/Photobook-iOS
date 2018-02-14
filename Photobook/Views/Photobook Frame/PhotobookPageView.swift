//
//  PhotobookPageView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

@objc protocol PhotobookPageViewDelegate: class {
    @objc optional func didTapOnPage(index: Int)
    @objc optional func didTapOnAsset(index: Int)
    @objc optional func didTapOnText(index: Int)
}

enum PhotobookPageViewInteraction {
    case disabled, wholePage, assetAndText
}

class PhotobookPageView: UIView {
    
    weak var delegate: PhotobookPageViewDelegate?
    var index: Int?
    var aspectRatio: CGFloat? {
        didSet {
            guard let aspectRatio = aspectRatio else { return }
            self.removeConstraint(self.aspectRatioConstraint)
            aspectRatioConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: self, attribute: .height, multiplier: aspectRatio, constant: 0)
            aspectRatioConstraint.priority = UILayoutPriority(750)
            self.addConstraint(aspectRatioConstraint)
        }
    }
    var imageSize = CGSize(width: Int.max, height: Int.max)
    var isVisible: Bool = false {
        didSet {
            for subview in subviews {
                subview.isHidden = !isVisible
            }
        }
    }
    var color: ProductColor = .white
    
    private var hasSetupGestures = false
    var productLayout: ProductLayout?
    
    var interaction: PhotobookPageViewInteraction = .disabled
    
    @IBOutlet private weak var assetContainerView: UIView!
    @IBOutlet private weak var assetPlaceholderIconImageView: UIImageView!
    @IBOutlet private weak var assetImageView: UIImageView!
    @IBOutlet private weak var pageTextLabel: UILabel? {
        didSet { pageTextLabel!.alpha = 0.0 }
    }
    @IBOutlet private weak var textLabelPlaceholderBoxView: TextLabelPlaceholderBoxView? {
        didSet { textLabelPlaceholderBoxView!.alpha = 0.0 }
    }
    
    @IBOutlet private var aspectRatioConstraint: NSLayoutConstraint!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let imageBox = productLayout?.layout.imageLayoutBox else { return }
        assetContainerView.frame = imageBox.rectContained(in: CGSize(width: frame.width, height: frame.height))
        
        let iconSize = min(assetContainerView.bounds.width, assetContainerView.bounds.height)
        assetPlaceholderIconImageView.bounds.size = CGSize(width: iconSize * 0.2, height: iconSize * 0.2)
        assetPlaceholderIconImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
        
        adjustTextLabel()
        setupGestures()
    }
    
    private func setupGestures() {
        guard !hasSetupGestures else { return }
        switch interaction {
        case .wholePage:
            let pageTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnPage(_:)))
            addGestureRecognizer(pageTapGestureRecognizer)
        case .assetAndText:
            let assetTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnAsset(_:)))
            assetContainerView.addGestureRecognizer(assetTapGestureRecognizer)
            
            let textTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnText(_:)))
            pageTextLabel?.addGestureRecognizer(textTapGestureRecognizer)
        default:
            break
        }
        hasSetupGestures = true
    }
    
    func setupLayoutBoxes() {
        guard assetImageView.image != nil && productLayout?.layout.imageLayoutBox != nil else {
            setupImageBox()
            setupTextBox()
            return
        }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.assetContainerView.alpha = 0.0
        }, completion: { _ in
            self.setupImageBox()
            self.setupTextBox()
        })
    }
    
    func setupImageBox(with assetImage: UIImage? = nil) {
        guard let imageBox = productLayout?.layout.imageLayoutBox else {
            assetContainerView.alpha = 0.0
            return
        }
        
        assetContainerView.frame = imageBox.rectContained(in: bounds.size)
        
        guard let index = index, let asset = productLayout?.productLayoutAsset?.asset else {
            setImagePlaceholder(visible: true)
            return
        }
        
        let imageCompletion: ((UIImage) -> Void) = { [weak welf = self] (image) in
            welf?.setImage(image: image)
            
            UIView.animate(withDuration: 0.3) {
                welf?.assetContainerView.alpha = 1.0
            }
        }
        
        // Avoid reloading image if not necessary
        if assetImage != nil {
            imageCompletion(assetImage!)
            return
        }
        
        asset.image(size: imageSize, completionHandler: { [weak welf = self] (image, _) in
            guard welf?.index == index, let image = image else { return }
            imageCompletion(image)
        })
    }
    
    func setImage(image: UIImage) {
        guard let asset = productLayout?.productLayoutAsset?.asset else {
            setImagePlaceholder(visible: true)
            return
        }
        
        setImagePlaceholder(visible: false)
        
        assetContainerView.alpha = 1.0
        assetImageView.image = image
        assetImageView.transform = .identity
        assetImageView.frame = CGRect(x: 0.0, y: 0.0, width: asset.size.width, height: asset.size.height)
        assetImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
        
        productLayout!.productLayoutAsset!.containerSize = assetContainerView.bounds.size
        assetImageView.transform = productLayout!.productLayoutAsset!.transform
    }
    
    func setupTextBox(shouldBeLegible: Bool = true) {
        guard let textBox = productLayout?.layout.textLayoutBox else {
            if let placeholderView = textLabelPlaceholderBoxView { placeholderView.alpha = 0.0 }
            if let pageTextLabel = pageTextLabel { pageTextLabel.alpha = 0.0 }
            return
        }
        
        if !shouldBeLegible, let placeholderView = textLabelPlaceholderBoxView {
            placeholderView.alpha = 1.0
            placeholderView.frame = textBox.rectContained(in: bounds.size)
            placeholderView.color = color
            placeholderView.setNeedsDisplay()
            return
        }

        guard let pageTextLabel = pageTextLabel else { return }
        pageTextLabel.alpha = 1.0
        
        adjustTextLabel()
        setTextColor()
    }
    
    private func adjustTextLabel() {
        guard let pageTextLabel = pageTextLabel, let textBox = productLayout?.layout.textLayoutBox else { return }
        
        var text = productLayout?.text
        if (text ?? "").isEmpty {
            text = NSLocalizedString("Views/Photobook Frame/PhotobookPageView/pageTextLabel/placeholder",
                                     value: "Add your own text",
                                     comment: "Placeholder text to show on a cover / page")
        }

        let finalFrame = textBox.rectContained(in: bounds.size)
        let finalCentre =  CGPoint(x: finalFrame.midX, y: finalFrame.midY)
        
        let scale: CGFloat = 1.55
        let fakeSize = CGSize(width: finalFrame.width * scale, height: finalFrame.height * scale)
        
        pageTextLabel.transform = .identity
        pageTextLabel.frame = CGRect(x: finalFrame.minX, y: finalFrame.minY, width: finalFrame.width * scale, height: finalFrame.height * scale)
        pageTextLabel.center = finalCentre
        pageTextLabel.transform = pageTextLabel.transform.scaledBy(x: 1/scale, y: 1/scale)
        
        let layoutContainerSize = textBox.containerSize(for: fakeSize)
        
        let fontType = productLayout!.fontType ?? .clear
        
        let photobookToOnScreenScale = layoutContainerSize.height / ProductManager.shared.product!.pageHeight
        let fontSize = round(fontType.photobookFontSize() * photobookToOnScreenScale)

        pageTextLabel.attributedText = fontType.attributedText(with: text!, fontSize: fontSize, fontColor: color.fontColor())
        
        let textHeight = pageTextLabel.attributedText!.height(for: fakeSize.width)
        if textHeight < fakeSize.height { pageTextLabel.frame.size.height = textHeight }
    }
    
    private func setImagePlaceholder(visible: Bool) {
        if visible {
            assetImageView.image = nil
            assetContainerView.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0)
            assetPlaceholderIconImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
            assetPlaceholderIconImageView.alpha = 1.0
        } else {
            assetContainerView.backgroundColor = .clear
            assetPlaceholderIconImageView.alpha = 0.0
        }
    }
    
    func setTextColor() {
        if let pageTextLabel = pageTextLabel { pageTextLabel.textColor = color.fontColor() }
        if let placeholderView = textLabelPlaceholderBoxView {
            placeholderView.color = color
            placeholderView.setNeedsDisplay()
        }
    }
    
    @objc private func didTapOnPage(_ sender: UITapGestureRecognizer) {
        guard let index = index else { return }
        delegate?.didTapOnPage?(index: index)
    }
    
    @objc private func didTapOnAsset(_ sender: UITapGestureRecognizer) {
        guard let index = index else { return }
        delegate?.didTapOnAsset?(index: index)
    }

    @objc private func didTapOnText(_ sender: UITapGestureRecognizer) {
        guard let index = index else { return }
        delegate?.didTapOnText?(index: index)
    }

}