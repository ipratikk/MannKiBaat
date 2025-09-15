//
//  ImageCropperView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 16/09/25.
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
    private let maskLayer = CAShapeLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        guard let image = image else { return }

        // ScrollView setup
        scrollView.frame = view.bounds
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.bounces = true
        scrollView.clipsToBounds = false
        view.addSubview(scrollView)

        // ImageView inside ScrollView
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        scrollView.addSubview(imageView)

        // Square overlay mask
        addSquareMask()

        // Toolbar buttons
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.tintColor = .white
        cancelButton.frame = CGRect(x: 20, y: view.safeAreaInsets.top + 10, width: 80, height: 40)
        cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        view.addSubview(cancelButton)

        let cropButton = UIButton(type: .system)
        cropButton.setTitle("Crop", for: .normal)
        cropButton.tintColor = .white
        cropButton.frame = CGRect(x: view.bounds.width - 100, y: view.safeAreaInsets.top + 10, width: 80, height: 40)
        cropButton.addTarget(self, action: #selector(cropAction), for: .touchUpInside)
        view.addSubview(cropButton)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    private func addSquareMask() {
        let maskView = UIView(frame: view.bounds)
        maskView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        maskView.isUserInteractionEnabled = false

        let squareSize = min(view.bounds.width, view.bounds.height) - 40
        let squareRect = CGRect(x: (view.bounds.width - squareSize) / 2,
                                y: (view.bounds.height - squareSize) / 2,
                                width: squareSize,
                                height: squareSize)

        let path = UIBezierPath(rect: maskView.bounds)
        let squarePath = UIBezierPath(rect: squareRect)
        path.append(squarePath.reversing())

        maskLayer.path = path.cgPath
        maskView.layer.mask = maskLayer
        view.addSubview(maskView)
    }

    @objc private func cancelAction() {
        dismiss(animated: true)
    }

    @objc private func cropAction() {
        guard let image = imageView.image else { return }

        let squareSize = min(view.bounds.width, view.bounds.height) - 40
        let squareRect = CGRect(x: (view.bounds.width - squareSize) / 2,
                                y: (view.bounds.height - squareSize) / 2,
                                width: squareSize,
                                height: squareSize)

        // Render cropped area
        let renderer = UIGraphicsImageRenderer(bounds: squareRect)
        let croppedImage = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

        onCrop?(croppedImage)
        dismiss(animated: true)
    }
}
