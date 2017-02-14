//
//  CircleCounterView.swift
//  Simple Deadlines
//
//  Created by Edric MILARET on 17-01-24.
//  Copyright © 2017 Edric MILARET. All rights reserved.
//

import UIKit

@IBDesignable
public class CircleCounterView: UIView {
    
    // MARK: - Properties
    let circleLayer = CAShapeLayer()
    let dayLabel = UILabel()
    
    @IBInspectable public var dayRemaining: Int = 0 {
        didSet {
            dayLabel.text = String(dayRemaining)
        }
    }
    
    @IBInspectable public var color: UIColor = .red {
        didSet {
            circleLayer.fillColor = color.cgColor
        }
    }
    
    // MARK: - Init func
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isOpaque = false
        self.backgroundColor = .clear
    }
    
    // MARK: - Draw Func
    
    public override func draw(_ frame: CGRect) {
        drawCircle()
    }
    
    func drawCircle() {
        let width = Double(self.bounds.size.width);
        let height = Double(self.bounds.size.height);
        
        dayLabel.bounds = self.bounds
        dayLabel.textAlignment = NSTextAlignment.center
        dayLabel.center = CGPoint(x: width/2, y: height/2)
        dayLabel.textColor = UIColor.white
        self.addSubview(dayLabel)
        
        circleLayer.bounds = CGRect(x: 2.0, y: 2.0, width: width-2.0, height: height-2.0)
        circleLayer.position = CGPoint(x: width/2, y: height/2);
        let rect = CGRect(x: 2.0, y: 2.0, width: width-2.0, height: height-2.0)
        let path = UIBezierPath.init(ovalIn: rect)
        circleLayer.path = path.cgPath
        circleLayer.fillColor = color.cgColor
        circleLayer.lineWidth = 2.0
        
        self.layer.insertSublayer(circleLayer, at: 0)
    }
}
