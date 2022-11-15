//
//  ViewFlip.swift
//  ballpa1n
//
//  Created by Lakhan Lothiyi on 21/10/2022.
//

import SwiftUI

struct FlipView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(180))
    }
}

extension View {
    func flipped() -> some View {
        modifier(FlipView())
    }
}
