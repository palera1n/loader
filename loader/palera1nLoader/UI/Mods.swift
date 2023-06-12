//
//  Mods.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation
import UIKit

class mods {
    static public func applySymbolModifications(to cell: UITableViewCell, with symbolName: String, backgroundColor: UIColor) {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        let symbolSize = symbolImage?.size ?? .zero
        let imageSize = CGSize(width: 30, height: 30)
        let scale = min((imageSize.width - 6) / symbolSize.width, (imageSize.height - 6) / symbolSize.height)
        let adjustedSymbolSize = CGSize(width: symbolSize.width * scale, height: symbolSize.height * scale)
        let coloredBackgroundImage = UIGraphicsImageRenderer(size: imageSize).image { context in
            backgroundColor.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageSize), cornerRadius: 7).fill()
        }
        let mergedImage = UIGraphicsImageRenderer(size: imageSize).image { context in
            coloredBackgroundImage.draw(in: CGRect(origin: .zero, size: imageSize))
            symbolImage?.draw(in: CGRect(x: (imageSize.width - adjustedSymbolSize.width) / 2, y: (imageSize.height - adjustedSymbolSize.height) / 2, width: adjustedSymbolSize.width, height: adjustedSymbolSize.height))
        }
        cell.imageView?.image = mergedImage
        cell.imageView?.layer.cornerRadius = 7
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
    }

    static public func applyImageModifications(to cell: UITableViewCell, with originalImage: UIImage) {
        let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { context in
            originalImage.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
        }
        cell.imageView?.image = resizedImage
        cell.imageView?.layer.cornerRadius = 7
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
    }

}

