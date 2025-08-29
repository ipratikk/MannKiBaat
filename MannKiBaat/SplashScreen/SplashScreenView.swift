//
//  SplashScreenView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI

struct SplashScreenView: View {
    var namespace: Namespace.ID

    @State private var drawNotebook = false

    var body: some View {
        ZStack {
            NotebookShape()
                .trim(from: 0, to: drawNotebook ? 1 : 0)
                .stroke(Color.primary, lineWidth: 3)
                .frame(width: 120, height: 120)
                .matchedGeometryEffect(id: "notebook", in: namespace) // 👈 important
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                drawNotebook = true
            }
        }
    }
}


#Preview("Light Mode") {
    NavigationStack {
        SplashScreenView(namespace: Namespace().wrappedValue)
            .preferredColorScheme(.light)
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        SplashScreenView(namespace: Namespace().wrappedValue)
            .preferredColorScheme(.dark)
    }
}
