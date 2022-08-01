//
//  PDFSignView.swift
//  PDFSignature
//
//  Created by FSKJ on 2022/8/1.
//  Copyright © 2022 rajeejones. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

protocol PDFSignAnnotationViewDelegate: AnyObject {
    func signAnnotationView(_ view: PDFSignAnnotationView, didMove point: CGPoint)
    func signAnnotationView(_ view: PDFSignAnnotationView, didScale scale: CGFloat)
    func signAnnotationView(_ view: PDFSignAnnotationView, didRotate angle: CGFloat)
    func signAnnotationView(_ view: PDFSignAnnotationView, close identity: String)
}
class PDFSignAnnotationView: UIView {
    weak var delegate: PDFSignAnnotationViewDelegate?
    let globalInset: CGFloat = 8
    let identity: String

    private var initialDistance: CGFloat = 0
    private var deltaAngle: CGFloat = 0
    private var lastLocation: CGPoint = .zero
    private var oldScale: CGFloat = 1
    private var selfScale: CGFloat = 1
    
    init(frame: CGRect, annotationIdentity id: String) {
        self.identity = id
        var newFrame = frame
        if (newFrame.size.width < globalInset*2.0) {
            newFrame.size.width = globalInset*2.0;
        }
        if (newFrame.size.height < globalInset*2.0) {
            newFrame.size.height = globalInset*2.0;
        }
        
        super.init(frame: newFrame)
        
        setupUI()
        addGR()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addGR() {
        // 旋转手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(rotateGesture(_:)))
        rotateButton.addGestureRecognizer(pan)
        // 平移手势
        let movePan = UIPanGestureRecognizer(target: self, action: #selector(moveGesture(_:)))
        addGestureRecognizer(movePan)
    }
    
    // MARK: - Event
    // MAKR: - 关闭
    @objc func closeButtonAction() {
        delegate?.signAnnotationView(self, close: identity)
        removeFromSuperview()
    }

    // 缩放和旋转
    @objc func rotateGesture(_ sender: UIPanGestureRecognizer) {
        let touchLocation = sender.location(in: self.superview)
        print(touchLocation)
        
        if sender.state == .began {
            lastLocation = touchLocation
            initialDistance = CGPoint.distance(p1: self.center, p2: touchLocation)
            deltaAngle = -self.transform.radian
            oldScale = selfScale
        }
        if sender.state == .changed {
            let newDistance = CGPoint.distance(p1: self.center, p2: touchLocation)
            let scale = newDistance / initialDistance
            print("scale ---- \(scale)")
            
            selfScale = oldScale + (scale-1.0)*oldScale
            // 角度
            let ang =
            -atan2(lastLocation.y-center.y, lastLocation.x-center.x) + atan2(touchLocation.y-center.y, touchLocation.x-center.x)
            
            let angleDiff = deltaAngle - ang
            let newTransform = CGAffineTransform(rotationAngle: -angleDiff)
            self.transform = newTransform.scaledBy(x: selfScale, y: selfScale)
            print("rotate - \(rotateButton.frame)")
            delegate?.signAnnotationView(self, didRotate: transform.angle)
            delegate?.signAnnotationView(self, didScale: selfScale)
            
            // 关闭和旋转按钮 方向缩放
            rotateButton.transform = CGAffineTransform.init(scaleX: 1/selfScale, y: 1/selfScale).translatedBy(x: globalInset*selfScale, y: globalInset*selfScale)
            closeButton.transform = CGAffineTransform.init(scaleX: 1/selfScale, y: 1/selfScale).translatedBy(x: -globalInset*selfScale, y: -globalInset*selfScale)
        }
        if sender.state == .ended {
            
        }
    }
   
    // 移动
    @objc func moveGesture(_ sender: UIPanGestureRecognizer) {
        let touchLocation = sender.location(in: self.superview)
        print("moveGesture - \(touchLocation)")
        var shockX: CGFloat = 0
        var shockY: CGFloat = 0
        if sender.state == .began {
            
        }
        if sender.state == .changed {
            shockX = super.center.x
            shockY = super.center.y
            
            let point = sender.translation(in: superview)
            print("translation - \(point)")
            shockX += point.x
            shockY += point.y
            
            self.center = CGPoint(x: shockX, y: shockY)
            sender.setTranslation(.zero, in: superview)
            delegate?.signAnnotationView(self, didMove: center)
        }
        if sender.state == .ended {
            
        }
    }
    
    // MARK: - UI
    lazy var signImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        return view
    }()
    lazy var closeButton: UIButton = {
        let view = UIButton(type: .custom)
        view.backgroundColor = .blue
        view.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        return view
    }()
    lazy var rotateButton: UIButton = {
        let view = UIButton(type: .custom)
        view.backgroundColor = .red
        view.frame = CGRect(x: self.bounds.size.width - globalInset*3 + globalInset/2.0,
                            y: self.bounds.size.height - globalInset*3 + globalInset/2.0,
                            width: globalInset*3,
                            height: globalInset*3)
        return view
        
    }()
    fileprivate func setupUI() {
        backgroundColor = .systemPink.withAlphaComponent(0.5)
        
        addSubview(signImageView)
        signImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            signImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: globalInset),
            signImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: globalInset),
            signImageView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -globalInset),
            signImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -globalInset)
        ])
        
        addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: -globalInset/2.0),
            closeButton.leftAnchor.constraint(equalTo: self.leftAnchor, constant: -globalInset/2.0),
            closeButton.widthAnchor.constraint(equalToConstant: globalInset*3),
            closeButton.heightAnchor.constraint(equalToConstant: globalInset*3),
        ])
        
        addSubview(rotateButton)
        rotateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rotateButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: globalInset/2.0),
            rotateButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: globalInset/2.0),
            rotateButton.widthAnchor.constraint(equalToConstant: globalInset*3),
            rotateButton.heightAnchor.constraint(equalToConstant: globalInset*3),
        ])
    }
}


extension CGPoint {
    /// 计算2点之间的距离
    static func distance(p1: CGPoint, p2: CGPoint) -> CGFloat {
        let fx = (p1.x - p2.x)
        let fy = (p1.y - p2.y)
        
        return sqrt(fx*fx + fy*fy)
    }
}

extension CGAffineTransform {
    /// 弧度
    var radian: CGFloat {
        return atan2(b, a)
    }
    /// 角度
    var angle: CGFloat {
        return radian * (180.0 / .pi)
    }
}
