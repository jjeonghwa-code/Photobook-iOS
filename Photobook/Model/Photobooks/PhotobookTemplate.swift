//
//  PhotobookTemplate.swift
//  Photobook
//
//  Created by Jaime Landazuri on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit

// Defines the characteristics of a photobook / product
class PhotobookTemplate: Codable {
    
    private static let mmToPtMultiplier = 2.83464566929134
    
    var id: String
    var name: String
    var templateId: String
    var coverSize: CGSize
    var pageSize: CGSize
    var coverAspectRatio: CGFloat { return coverSize.width / coverSize.height }
    var pageAspectRatio: CGFloat { return pageSize.width / pageSize.height }
    var spineTextRatio: CGFloat
    var coverLayouts: [Int]
    var layouts: [Int] // IDs of the permitted layouts
    var minPages: Int = 20
    var maxPages: Int = 100
    
    // TODO: Currencies?
    
    init(id: String, name: String, templateId: String, coverSize: CGSize, pageSize: CGSize, spineTextRatio: CGFloat, coverLayouts: [Int], layouts: [Int]) {
        self.id = id
        self.name = name
        self.templateId = templateId
        self.coverSize = coverSize
        self.pageSize = pageSize
        self.spineTextRatio = spineTextRatio
        self.coverLayouts = coverLayouts
        self.layouts = layouts
    }

    // Parses a photobook dictionary.
    static func parse(_ dictionary: [String: AnyObject]) -> PhotobookTemplate? {
        
        guard
            let id = dictionary["kiteId"] as? String,
            let name = dictionary["displayName"] as? String,
            let templateId = dictionary["templateId"] as? String,
            let variants = dictionary["variants"] as? [[String: Any]],
            let variantDictionary = variants.first,
            
            let coverSizeDictionary = variantDictionary["coverSize"] as? [String: Any],
            let coverSizeMm = coverSizeDictionary["mm"] as? [String: Any],
            let coverWidth = coverSizeMm["width"] as? Double,
            let coverHeight = coverSizeMm["height"] as? Double,
            
            let pageSizeDictionary = variantDictionary["size"] as? [String: Any],
            let pageSizeMm = pageSizeDictionary["mm"] as? [String: Any],
            let pageWidth = pageSizeMm["width"] as? Double,
            let pageHeight = pageSizeMm["height"] as? Double,

            let spineTextRatio = dictionary["spineTextRatio"] as? CGFloat, spineTextRatio > 0.0,
            let coverLayouts = dictionary["coverLayouts"] as? [Int], !coverLayouts.isEmpty,
            let layouts = dictionary["layouts"] as? [Int], !layouts.isEmpty
        else { return nil }
        
        let coverSize = CGSize(width: coverWidth * PhotobookTemplate.mmToPtMultiplier, height: coverHeight * PhotobookTemplate.mmToPtMultiplier)
        let pageSize = CGSize(width: pageWidth * PhotobookTemplate.mmToPtMultiplier * 0.5, height: pageHeight * PhotobookTemplate.mmToPtMultiplier) // The width is that of a full spread
        
        let photobookTemplate = PhotobookTemplate(id: id, name: name, templateId: templateId, coverSize: coverSize, pageSize: pageSize, spineTextRatio: spineTextRatio, coverLayouts: coverLayouts, layouts: layouts)

        if let minPages = variantDictionary["minPages"] as? Int { photobookTemplate.minPages = minPages }
        if let maxPages = variantDictionary["maxPages"] as? Int { photobookTemplate.maxPages = maxPages }
        
        return photobookTemplate
    }    
}

extension PhotobookTemplate: Equatable {
    
    static func ==(lhs: PhotobookTemplate, rhs: PhotobookTemplate) -> Bool {
        return lhs.id == rhs.id
    }
}
