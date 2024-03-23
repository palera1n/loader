//
//  UIActivityIndicatorView.swift
//  palera1nLoader
//
//  Created by samara on 3/22/24.
//

import UIKit

extension UIActivityIndicatorView {
    static var defaultStyle: UIActivityIndicatorView.Style {
        #if os(tvOS)
        return .medium
        #else
        if #available(iOS 13.0, *) {
            return .medium
        } else {
            return .gray
        }
        #endif
    }
}

extension UIColor {
    static var defaultContainerBackgroundColor: UIColor {
        #if os(tvOS)
        return .black
        #else
        if #available(iOS 13.0, *) {
            return .systemGroupedBackground
        } else {
            return .black
        }
        #endif
    }
}
