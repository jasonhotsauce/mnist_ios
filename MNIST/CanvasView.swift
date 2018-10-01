//
//  CanvasView.swift
//  MNIST
//
//  Created by Wenbin Zhang on 9/26/18.
//  Copyright © 2018 Wenbin Zhang. All rights reserved.
//

import UIKit

final class CanvasView: UIView {
    private var lines: [Line] = []
    private var lastPoint: CGPoint = .zero
    var lineWidth: CGFloat = 15 {
        didSet {
            setNeedsDisplay()
        }
    }
    var color = UIColor.white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        lastPoint = point
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let newPoint = touches.first?.location(in: self) else { return }
        lines.append(Line(start: lastPoint, end: newPoint))
        lastPoint = newPoint
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard lines.count > 0 else {
            return
        }
        let path = UIBezierPath()
        path.lineCapStyle = .round
        path.lineWidth = lineWidth
        color.set()
        lines.forEach { line in
            path.move(to: line.start)
            path.addLine(to: line.end)
        }
        path.stroke()
    }
}

extension CanvasView {
    func reset() {
        lines = []
        setNeedsDisplay()
    }
    
    var hasContent: Bool {
        return lines.count > 0
    }
}

private struct Line {
    let start: CGPoint
    let end: CGPoint
}
