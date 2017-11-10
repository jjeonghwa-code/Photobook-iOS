//
//  PhotoBookNavigationBar.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotoBookNavigationBar: UINavigationBar {
    
    var hasAddedBlur = false
    var effectView: UIVisualEffectView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !hasAddedBlur {
            hasAddedBlur = true
            
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            effectView.frame = CGRect(x: 0.0, y: -20.0, width: bounds.width, height: 64.0)
            effectView.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
            insertSubview(effectView, at: 0)
        }
        sendSubview(toBack: effectView)
    }
    
    func setup() {
        barTintColor = .white
        if #available(iOS 11.0, *) {
            prefersLargeTitles = true
        }
        
        setBackgroundImage(UIImage(color: .clear), for: .default)
        shadowImage = UIImage()
    }
    
}
