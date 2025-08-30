//
//  GradientBackgroundView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI

public struct GradientBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [.themeSageGreen, .themeBeige]
                : [.themeMidnight, .themeForest],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
