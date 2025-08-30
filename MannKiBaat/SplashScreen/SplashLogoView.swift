//
//  SplashLogoView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI

struct SplashLogoView: View {
    var namespace: Namespace.ID
    @State private var drawNotebook = false

    var body: some View {
        NotebookShape()
            .trim(from: 0, to: drawNotebook ? 1 : 0)
            .stroke(Color.primary, lineWidth: 3)
            .frame(width: 120, height: 120)
            .matchedGeometryEffect(id: "notebook", in: namespace)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5)) {
                    drawNotebook = true
                }
            }
    }
}

struct NotebookShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.addRoundedRect(
            in: CGRect(x: 0, y: 0, width: w, height: h),
            cornerSize: CGSize(width: 16, height: 16)
        )

        path.move(to: CGPoint(x: w * 0.3, y: 0))
        path.addLine(to: CGPoint(x: w * 0.3, y: h))

        return path
    }
}

#Preview("Light Mode") {
    SplashLogoView(namespace: Namespace().wrappedValue)
        .preferredColorScheme(.light)
        .padding()
}

#Preview("Dark Mode") {
    SplashLogoView(namespace: Namespace().wrappedValue)
        .preferredColorScheme(.dark)
        .padding()
}
