//
//  SignPDFView.swift
//  PDFSignature
//
//  Created by FSKJ on 2022/12/16.
//  Copyright © 2022 rajeejones. All rights reserved.
//

import Foundation
import PDFKit

class SignPDFView: PDFView {
    deinit {
        print("\(Self.self) - deinit")
        NotificationCenter.default.removeObserver(self)
    }
    // 当前页面原始比例
    var pageOriginalScale: CGFloat = 1.0
    
    var currentlySelectedAnnotation: PDFAnnotation?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // 添加点击手势
        let tapAnnotationGesture = UITapGestureRecognizer.init(target: self, action: #selector(didTapAnnotation(sender:)))
        addGestureRecognizer(tapAnnotationGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(pdfViewPageChanged), name: .PDFViewPageChanged, object: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // 添加点击手势
        let tapAnnotationGesture = UITapGestureRecognizer.init(target: self, action: #selector(didTapAnnotation(sender:)))
        addGestureRecognizer(tapAnnotationGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(pdfViewPageChanged), name: .PDFViewPageChanged, object: nil)
    }
    
    @objc func pdfViewPageChanged() {
        print("pdfViewPageChanged")
        pageOriginalScale = scaleFactor
    }

    @objc func didSwipeGestureRecognizer(sender: UISwipeGestureRecognizer) {
        let touchLocation = sender.location(in: self)
        print("didSwipeGestureRecognizer - \(touchLocation)")
    }

    @objc func didTapAnnotation(sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: self)
        print("didTapAnnotation - \(touchLocation)")
        
        // 命中注释之后设置缩放为原始缩放 显示操作view
        if let page = self.page(for: touchLocation, nearest: true),
           let imageAnnotation = page.getAnnotation(at: touchLocation, pdfView: self, inset: 30) as? PDFImageAnnotation {
            showAnnotation(imageAnnotation: imageAnnotation)
        }
    }
    
    private func hideAnnotation() {
        // 没有命中注释，隐藏所有注释
        for view in subviews {
            if let view = view as? PDFSignAnnotationView {
                view.isHidden = true
            }
        }
    }
    
    private func showAnnotation(imageAnnotation: PDFImageAnnotation) {
        print("------------")
        scaleFactor = pageOriginalScale
        let bounds = imageAnnotation.bounds
        let localRect = convert(bounds, from: currentPage!)
        let rotateRect = localRect.rotateRect(imageAnnotation.angle)
        
        for view in subviews {
            if let signView = view as? PDFSignAnnotationView {
                if signView.identity == imageAnnotation.userName  {
                    signView.isHidden = false
                    print("signview - \(signView.frame)")
                    // 重新设置操作view的位置
                    signView.center = CGPoint(x: rotateRect.midX, y: rotateRect.midY)
                } else {
                    signView.isHidden = true
                }
            }
        }
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let touchLocation = gestureRecognizer.location(in: self)
//        print("gestureRecognizer - \(gestureRecognizer) \n otherGestureRecognizer - \(otherGestureRecognizer)")
        // 命中注释之后注释相关的手势优先
        if let page = self.page(for: touchLocation, nearest: true),
           let _ = page.getAnnotation(at: touchLocation, pdfView: self, inset: 30) as? PDFImageAnnotation {
            return false
        }
        
        print("++++++++++++")
        // 没有命中注释 隐藏所有的注释外框
        hideAnnotation()
        
        return true
    }
}

extension PDFPage {
    // 通过点击点获取注释，扩大命中范围
    func getAnnotation(at point: CGPoint, pdfView: PDFView, inset: CGFloat = 0) -> PDFAnnotation? {
        for annotation in annotations {
            if let annotation = annotation as? PDFImageAnnotation {
                // 转换成当前坐标系rect
                let convertRect = pdfView.convert(annotation.bounds, from: self)
                // 旋转
                let rotateRect = convertRect.rotateRect(annotation.angle)
                // 缩放
                let rect = rotateRect.insetBy(dx: -inset, dy: -inset)
                if rect.contains(point) {
                    return annotation
                }
            }
        }
        return nil
    }
}

extension CGRect {
    func rotateRect(_ angle: CGFloat) -> CGRect {
        let x = midX
        let y = midY
        let transform = CGAffineTransform(translationX: x, y: y)
            .rotated(by: angle * (CGFloat.pi / 180.0))
            .translatedBy(x: -x, y: -y)

        return applying(transform)
    }
}
