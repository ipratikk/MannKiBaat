//
//  ImageCropperView.swift
//  MannKiBaat
//

import SwiftUI
import UIKit

struct ImageCropperView: UIViewControllerRepresentable {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> CropperViewController {
        let vc = CropperViewController()
        vc.image = image
        vc.onCrop = onCrop
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CropperViewController, context: Context) {}
}

// MARK: - UIKit Controller
class CropperViewController: UIViewController, UIScrollViewDelegate {
    var image: UIImage?
    var onCrop: ((UIImage) -> Void)?
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        guard let image = image else { return }
        
        // Setup scrollView
        scrollView.frame = view.bounds
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        
        // Setup imageView
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        scrollView.addSubview(imageView)
        
        // Mask overlay
        addSquareMask()
        
        // Toolbar
        setupToolbar()
    }
    
    private func setupToolbar() {
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.tintColor = .white
        cancelButton.frame = CGRect(x: 20, y: 40, width: 80, height: 40)
        cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        let cropButton = UIButton(type: .system)
        cropButton.setTitle("Crop", for: .normal)
        cropButton.tintColor = .white
        cropButton.frame = CGRect(x: view.bounds.width - 100, y: 40, width: 80, height: 40)
        cropButton.addTarget(self, action: #selector(cropAction), for: .touchUpInside)
        view.addSubview(cropButton)
    }
    
    private func addSquareMask() {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.isUserInteractionEnabled = false
        
        let squareSize = min(view.bounds.width, view.bounds.height) - 40
        let squareRect = CGRect(
            x: (view.bounds.width - squareSize) / 2,
            y: (view.bounds.height - squareSize) / 2,
            width: squareSize,
            height: squareSize
        )
        
        let path = UIBezierPath(rect: overlay.bounds)
        let cutout = UIBezierPath(rect: squareRect)
        path.append(cutout.reversing())
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        overlay.layer.mask = mask
        view.addSubview(overlay)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @objc private func cancelAction() {
        dismiss(animated: true)
    }
    
    @objc private func cropAction() {
        guard let image = imageView.image else { return }
        
        // Square crop area
        let squareSize = min(view.bounds.width, view.bounds.height) - 40
        let squareRect = CGRect(
            x: (view.bounds.width - squareSize) / 2,
            y: (view.bounds.height - squareSize) / 2,
            width: squareSize,
            height: squareSize
        )
        
        // Convert squareRect to image coordinates
        let scale = image.size.width / imageView.bounds.width
        let offsetX = scrollView.contentOffset.x
        let offsetY = scrollView.contentOffset.y
        
        let cropRect = CGRect(
            x: (offsetX + squareRect.origin.x) * scale,
            y: (offsetY + squareRect.origin.y) * scale,
            width: squareRect.width * scale,
            height: squareRect.height * scale
        )
        
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            let cropped = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            onCrop?(cropped)
        }
        
        dismiss(animated: true)
    }
}
