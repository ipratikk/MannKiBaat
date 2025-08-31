//
//  AppIconGenerator.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 31/08/25.
//

import SwiftUI
import UIKit
import SharedModels

public struct AppIconGenerator {
    
    // MARK: - App Icon SwiftUI View
    public struct AppIconView: View {
        public init() {}
        public var body: some View {
            ZStack {
                LinearGradient(
                    colors: [Color("primaryBackground"), Color("secondaryBackground")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                NotebookShape()
                    .fill(Color("buttonBackground"))
                    .padding(50)
                
                Text("MKB")
                    .font(.system(size: 200, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - App Icon Sizes
    public struct AppIconSize {
        let size: CGFloat
        let scale: Int
        var fileName: String { "\(Int(size))@\(scale)x.png" }
    }
    
    public static let iconSizes: [AppIconSize] = [
        AppIconSize(size: 20, scale: 2),
        AppIconSize(size: 20, scale: 3),
        AppIconSize(size: 29, scale: 2),
        AppIconSize(size: 29, scale: 3),
        AppIconSize(size: 40, scale: 2),
        AppIconSize(size: 40, scale: 3),
        AppIconSize(size: 60, scale: 2),
        AppIconSize(size: 60, scale: 3),
        AppIconSize(size: 76, scale: 1),
        AppIconSize(size: 76, scale: 2),
        AppIconSize(size: 83.5, scale: 2),
        AppIconSize(size: 1024, scale: 1) // App Store
    ]
    
    // MARK: - Render SwiftUI View to UIImage
    public static func renderIcon(size: CGFloat, scale: Int) -> UIImage {
        let controller = UIHostingController(rootView: AppIconView())
        let view = controller.view
        let targetSize = CGSize(width: size * CGFloat(scale), height: size * CGFloat(scale))
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
    
    // MARK: - Generate PNGs
    public static func generateAllIcons() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputFolder = documentsURL.appendingPathComponent("AppIcons")
        
        do {
            try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        } catch {
            print("Failed to create folder: \(error)")
            return
        }
        
        for icon in iconSizes {
            let image = renderIcon(size: icon.size, scale: icon.scale)
            let fileURL = outputFolder.appendingPathComponent(icon.fileName)
            if let pngData = image.pngData() {
                do {
                    try pngData.write(to: fileURL)
                    print("Saved: \(fileURL.lastPathComponent)")
                } catch {
                    print("Failed to save \(icon.fileName): \(error)")
                }
            }
        }
        
        print("All app icons generated at: \(outputFolder.path)")
    }
}

struct IconGeneratorTestView: View {
    var body: some View {
        Button("Generate App Icons") {
            AppIconGenerator.generateAllIcons()
        }
        .padding()
        .background(Color.buttonBackground)
        .foregroundColor(.white)
        .clipShape(Capsule())
    }
}
