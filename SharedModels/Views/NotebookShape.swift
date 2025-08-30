//
//  NotebookShape.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI

public struct NotebookShape: Shape {
    
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
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
