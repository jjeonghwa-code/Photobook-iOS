//
//  PhotobookPageView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

@objc protocol PhotobookPageViewDelegate: class {
    @objc optional func didTapOnPage(at index: Int)
    @objc optional func didTapOnAsset(at index: Int)
    @objc optional func didTapOnText(at index: Int)
}

enum PhotobookPageViewInteraction {
    case disabled // The user cannot tap on the page
    case wholePage // The user can tap anywhere on the page for a single action
    case assetAndText // The user can tap on the page and the text for two different actions
}

enum TextBoxMode {
    case placeHolder // Shows a placeholder "Add your own text" or the user's input if available
    case userTextOnly // Only shows the user's input if available. Blank otherwise.
    case linesPlaceholder // Shows a graphical representation of text in the form of two lines
}

class PhotobookPageView: UIView {
    
    weak var delegate: PhotobookPageViewDelegate?
    var pageIndex: Int?
    var aspectRatio: CGFloat? {
        didSet {
            guard let aspectRatio = aspectRatio else { return }
            self.removeConstraint(self.aspectRatioConstraint)
            aspectRatioConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: self, attribute: .height, multiplier: aspectRatio, constant: 0)
            aspectRatioConstraint.priority = UILayoutPriority(750)
            self.addConstraint(aspectRatioConstraint)
        }
    }
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
    
    var interaction: PhotobookPageViewInteraction = .disabled {
        didSet {
            if oldValue != interaction {
                hasSetupGestures = false
                setupGestures()
            }
        }
    }
    
    private var isShowingTextPlaceholder = false
    
    @IBOutlet private weak var assetContainerView: UIView!
    @IBOutlet private weak var assetPlaceholderIconImageView: UIImageView!
    @IBOutlet private weak var assetImageView: UIImageView!
    @IBOutlet private weak var pageTextLabel: UILabel? {
        didSet {
            pageTextLabel!.alpha = 0.0
            pageTextLabel!.layer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        }
    }
    @IBOutlet private weak var textLabelPlaceholderBoxView: TextLabelPlaceholderBoxView? {
        didSet { textLabelPlaceholderBoxView!.alpha = 0.0 }
    }
    
    @IBOutlet private var aspectRatioConstraint: NSLayoutConstraint!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let imageBox = productLayout?.layout.imageLayoutBox else { return }
        assetContainerView.frame = imageBox.rectContained(in: bounds.size)
        
        let iconSize = min(assetContainerView.bounds.width, assetContainerView.bounds.height)
        assetPlaceholderIconImageView.bounds.size = CGSize(width: iconSize * 0.2, height: iconSize * 0.2)
        assetPlaceholderIconImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
        
        adjustTextLabel()
        setupGestures()
    }
    
    private func setupGestures() {
        guard !hasSetupGestures else { return }
        
        if let gestureRecognizers = gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                removeGestureRecognizer(gestureRecognizer)
            }
        }
        
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
    
    func setupLayoutBoxes(animated: Bool = true) {
        guard assetImageView.image == nil && productLayout?.layout.imageLayoutBox != nil && animated else {
            setupImageBox(animated: false)
            setupTextBox()
            return
        }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.assetImageView.alpha = 0.0
        }, completion: { _ in
            self.setupImageBox()
            self.setupTextBox()
        })
    }
    
    func setupImageBox(with assetImage: UIImage? = nil, animated: Bool = true) {
        guard let imageBox = productLayout?.layout.imageLayoutBox else {
            assetContainerView.alpha = 0.0
            return
        }
        
        assetContainerView.alpha = 1.0
        assetContainerView.frame = imageBox.rectContained(in: bounds.size)
        setImagePlaceholder(visible: true)
        
        guard let index = pageIndex, let asset = productLayout?.productLayoutAsset?.asset else { return }
        
        // Avoid reloading image if not necessary
        if let assetImage = assetImage {
            setImage(image: assetImage)
            return
        }
        
        asset.image(size: assetContainerView.frame.size, completionHandler: { [weak welf = self] (image, _) in
            guard welf?.pageIndex == index, let image = image else { return }
            welf?.setImage(image: image)
            
            UIView.animate(withDuration: animated ? 0.1 : 0.0) {
                welf?.assetImageView.alpha = 1.0
            }
        })
    }
    
    func setImage(image: UIImage) {
        guard let asset = productLayout?.productLayoutAsset?.asset else {
            setImagePlaceholder(visible: true)
            return
        }
        
        setImagePlaceholder(visible: false)
        
        assetImageView.image = image
        assetImageView.transform = .identity
        assetImageView.frame = CGRect(x: 0.0, y: 0.0, width: asset.size.width, height: asset.size.height)
        assetImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
        
        productLayout!.productLayoutAsset!.containerSize = assetContainerView.bounds.size
        assetImageView.transform = productLayout!.productLayoutAsset!.transform
    }
    
    func setupTextBox(mode: TextBoxMode = .placeHolder) {
        guard let textBox = productLayout?.layout.textLayoutBox else {
            if let placeholderView = textLabelPlaceholderBoxView { placeholderView.alpha = 0.0 }
            if let pageTextLabel = pageTextLabel { pageTextLabel.alpha = 0.0 }
            return
        }
        
        if mode == .linesPlaceholder, let placeholderView = textLabelPlaceholderBoxView {
            placeholderView.alpha = 1.0
            placeholderView.frame = textBox.rectContained(in: bounds.size)
            placeholderView.color = color
            placeholderView.setNeedsDisplay()
            return
        }

        guard let pageTextLabel = pageTextLabel else { return }
        pageTextLabel.alpha = 1.0
        
        if (productLayout?.text ?? "").isEmpty && mode == .placeHolder {
            pageTextLabel.text = NSLocalizedString("Views/Photobook Frame/PhotobookPageView/pageTextLabel/placeholder",
                                     value: "Add your own text",
                                     comment: "Placeholder text to show on a cover / page")
            isShowingTextPlaceholder = true
        } else {
            pageTextLabel.text = productLayout?.text
            isShowingTextPlaceholder = false
        }

        adjustTextLabel()
        setTextColor()
    }
    
    private func adjustTextLabel() {
        guard let pageTextLabel = pageTextLabel, let textBox = productLayout?.layout.textLayoutBox else { return }

        pageTextLabel.transform = .identity
        pageTextLabel.frame = textBox.rectContained(in: bounds.size)

        guard pageTextLabel.text != nil else { return }

        let fontType = isShowingTextPlaceholder ? .plain : (productLayout!.fontType ?? .plain)
        var fontSize = fontType.sizeForScreenHeight(bounds.height)
        if isShowingTextPlaceholder { fontSize *= 2.0 } // Make text larger so the placeholder can be read
        
        pageTextLabel.attributedText = fontType.attributedText(with: pageTextLabel.text!, fontSize: fontSize, fontColor: color.fontColor())
        
        let textHeight = pageTextLabel.attributedText!.height(for: pageTextLabel.bounds.width)
        if textHeight < pageTextLabel.bounds.height { pageTextLabel.frame.size.height = textHeight }
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
        guard let index = pageIndex else { return }
        delegate?.didTapOnPage?(at: index)
    }
    
    @objc private func didTapOnAsset(_ sender: UITapGestureRecognizer) {
        guard let index = pageIndex else { return }
        delegate?.didTapOnAsset?(at: index)
    }

    @objc private func didTapOnText(_ sender: UITapGestureRecognizer) {
        guard let index = pageIndex else { return }
        delegate?.didTapOnText?(at: index)
    }

}
