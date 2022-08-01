//
//  ViewController.swift
//  PDFSignature
//
//  Created by Rajee Jones on 3/12/18.
//  Copyright © 2018 rajeejones. All rights reserved.
//

import UIKit
import PDFKit

class PDFImageAnnotation: PDFAnnotation {
    let image: UIImage
    let originalBounds: CGRect
    /// 0 - 360
    var angle: CGFloat = 0 {
        didSet {
            // reload annotation
            shouldDisplay = true
        }
    }
    /// scale annotation
    var scale: CGFloat = 1 {
        didSet {
            // Scale on the original size
            let width = originalBounds.width * scale
            let height = originalBounds.height * scale
            // move origin
            let x = bounds.origin.x - (width - bounds.width)/2
            let y = bounds.origin.y - (height - bounds.height)/2
            print("new ---- \(CGRect(x: x, y: y, width: width, height: height))")
            // Setting the bounds will automatically re-render
            bounds = CGRect(x: x, y: y, width: width, height: height)
        }
    }
    /// move center point
    var center: CGPoint = .zero {
        didSet {
            let x = center.x - bounds.width/2.0
            let y = center.y - bounds.height/2.0
            // Setting the bounds will automatically re-render
            bounds = CGRect(origin: CGPoint(x: x, y: y), size: bounds.size)
        }
    }

    public init(bounds: CGRect, image: UIImage) {
        self.image = image
        originalBounds = bounds
        super.init(bounds: bounds, forType: .ink, withProperties: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        super.draw(with: box, in: context)
        print("PDFImageAnnotation bounds - \(bounds)")
        guard let page = page else {
            return
        }
        UIGraphicsPushContext(context)
        context.saveGState()
        
        // rotate annotation
        // The origin of the annotation is always at the initial position
        let translateX = bounds.width/2 + bounds.origin.x
        let translateY = bounds.height/2 + bounds.origin.y
        // The page has its own rotation Angle
        let newAngle = angle + CGFloat(page.rotation)
        context.translateBy(x: translateX, y: translateY)
        context.rotate(by: newAngle*(CGFloat.pi/180.0))
        context.translateBy(x: -translateX, y: -translateY)

        // draw image
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: bounds)
        }

        context.restoreGState()
        UIGraphicsPopContext()
    }
}


class ViewController: UIViewController {

    @IBOutlet weak var pdfContainerView: PDFView!
    
    var currentlySelectedAnnotation: PDFAnnotation?
    var signatureImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "PDF Viewer"
        setupPdfView()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let signatureImage = signatureImage, let page = pdfContainerView.currentPage else { return }
        let imageBounds = CGRect(x: 0, y: 0, width: signatureImage.size.width, height: signatureImage.size.height)
//        let imageStamp = ImageStampAnnotation(with: signatureImage, forBounds: imageBounds, withProperties: nil)
        let uuid = UUID().uuidString
        let imageStamp = PDFImageAnnotation(bounds: imageBounds, image: signatureImage)
        imageStamp.userName = uuid
        page.addAnnotation(imageStamp)
        
        let signViewFrame = pdfContainerView.convert(imageBounds, from: page)
        let signView = PDFSignAnnotationView(frame: signViewFrame, annotationIdentity: uuid)
        signView.delegate = self
        pdfContainerView.addSubview(signView)
        pdfContainerView.setNeedsDisplay()
    }

    func setupPdfView() {
        // Download simple pdf document
        let path = Bundle.main.url(forResource: "Sample", withExtension: "pdf")
        let document = PDFDocument(url: path!) 
        
        // Set document to the view, center it, and set background color
        pdfContainerView.document = document
        pdfContainerView.autoScales = true
        pdfContainerView.isUserInteractionEnabled = true
        pdfContainerView.backgroundColor = .gray
        pdfContainerView.displayBox = .artBox
        pdfContainerView.usePageViewController(true, withViewOptions: nil)
        pdfContainerView.displayDirection = .vertical
        
        pdfContainerView.autoScales = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSignatureSegue" {
            if let nextVC = segue.destination as? SignatureViewController {
                nextVC.previousViewController = self
            }
        }
    }
    
}
 
extension ViewController: PDFSignAnnotationViewDelegate {
    func signAnnotationView(_ view: PDFSignAnnotationView, didMove point: CGPoint) {
        guard let page = pdfContainerView.currentPage,
              let imageAnnotation = page.annotations.filter({$0.userName == view.identity}).first as? PDFImageAnnotation else {
            return
        }
        let locationOnPage = self.pdfContainerView.convert(point, to: page)
        imageAnnotation.center = locationOnPage
    }
    
    func signAnnotationView(_ view: PDFSignAnnotationView, didScale scale: CGFloat) {
        guard let page = pdfContainerView.currentPage,
              let imageAnnotation = page.annotations.filter({$0.userName == view.identity}).first as? PDFImageAnnotation else {
            return
        }
        imageAnnotation.scale = scale
    }
    
    func signAnnotationView(_ view: PDFSignAnnotationView, didRotate angle: CGFloat) {
        guard let page = pdfContainerView.currentPage,
              let imageAnnotation = page.annotations.filter({$0.userName == view.identity}).first as? PDFImageAnnotation else {
            return
        }
        print("didRotate - \(angle)")
        imageAnnotation.angle = -angle
    }
    func signAnnotationView(_ view: PDFSignAnnotationView, close identity: String) {
        guard let page = pdfContainerView.currentPage else {
            return
        }
        guard let annotation = page.annotations.filter({$0.userName == identity}).first else {
            return
        }
        page.removeAnnotation(annotation)
    }
}
