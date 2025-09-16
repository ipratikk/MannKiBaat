//
//  ImageCropperView.swift
//  MannKiBaat
//

import SwiftUI
import UIKit

struct ImageCropperView: UIViewControllerRepresentable {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void   // 👈 add cancel callback
    
    func makeUIViewController(context: Context) -> CropperVC {
        let vc = CropperVC()
        vc.sourceImage = image
        vc.onCrop = onCrop
        vc.onCancel = onCancel
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CropperVC, context: Context) {}
}

// MARK: - UIKit Cropper
class CropperVC: UIViewController, UIScrollViewDelegate {
    var sourceImage: UIImage?
    var onCrop: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?   // 👈 callback instead of dismiss
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupScrollView()
        setupImage()
        setupOverlay()
        setupToolbar()
    }
    
    private func setupScrollView() {
        scrollView.frame = view.bounds
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
    }
    
    private func setupImage() {
        guard let sourceImage = sourceImage else { return }
        imageView.image = sourceImage
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        scrollView.addSubview(imageView)
    }
    
    private func setupOverlay() {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.isUserInteractionEnabled = false
        
        let squareSize = min(view.bounds.width, view.bounds.width)
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
    
    private func setupToolbar() {
        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.tintColor = .white
        cancel.frame = CGRect(x: 20, y: 50, width: 80, height: 40)
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancel)
        
        let crop = UIButton(type: .system)
        crop.setTitle("Crop", for: .normal)
        crop.tintColor = .white
        crop.frame = CGRect(x: view.bounds.width - 100, y: 50, width: 80, height: 40)
        crop.addTarget(self, action: #selector(cropTapped), for: .touchUpInside)
        view.addSubview(crop)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @objc private func cancelTapped() {
        onCancel?()   // 👈 just call back
    }
    
    @objc private func cropTapped() {
        guard let image = sourceImage else { return }
        
        // Simple square crop from the center
        let size = min(image.size.width, image.size.height)
        let cropRect = CGRect(
            x: (image.size.width - size) / 2,
            y: (image.size.height - size) / 2,
            width: size,
            height: size
        )
        
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            let cropped = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            onCrop?(cropped)
        }
    }
}
