//
//  ViewController.swift
//  QTFeatureAdPathGenerator
//
//  Created by fminor on 16/11/2016.
//  Copyright © 2016 fminor. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, CJTracePanelDelegate {

    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var drawPanel: CJTracePanelView!
    @IBOutlet weak var computeButton: NSButton!
    
    var startTime = 9.0
    var originPoint: CGPoint?
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        let _click = NSClickGestureRecognizer(target: self, action: #selector(gestureHandler(sender:)))
        drawPanel.addGestureRecognizer(_click)
        drawPanel.delegate = self
        
        computeButton.target = self
        computeButton.action = #selector(_actionCompute)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func gestureHandler(sender: NSGestureRecognizer) {
        if drawPanel.isRecording == false {
            drawPanel.startRecordMouseLoaction()
        }
    }

    func CJTracePanelView(_ panel: CJTracePanelView, didUpdate pointParams: NSArray?) {
        _log(pointParams: pointParams)
    }
    
    func _log(pointParams: NSArray? ) {
        if let _pointParams = pointParams {
            var _logString = String()
            for _pointParam in _pointParams {
                
                let _convertedParam = _convertPointParam(from: _pointParam as! CJPointParam, width: 1080.0, height: 270.0)
                let _location = _convertedParam.location
                let _time = _convertedParam.time
                
                _logString = _logString.appendingFormat("%.02f, %.02f, %.02f;", _location.x, _location.y, _time)
            }
            textView.string = _logString
        }
    }
    
    func _convertPointParam(from origin: CJPointParam, width containerWidth: CGFloat, height containerHeight: CGFloat) -> CJPointParam {
        var _convertedPoint = CGPoint.zero
        
        if let _originPoint = originPoint {
            let _ratio_x = containerWidth / ( drawPanel.bounds.width - _originPoint.x )
            let _ratio_y = containerHeight / _originPoint.y
            let _x = ( origin.location.x - _originPoint.x ) * _ratio_x
            let _y = ( _originPoint.y - origin.location.y ) * _ratio_y
            _convertedPoint.x = _x
            _convertedPoint.y = _y
        } else {
            originPoint = origin.location
            _convertedPoint = originPoint!
        }
        
        return CJPointParam(location: _convertedPoint, time: CGFloat(startTime) + origin.time)
    }
    
    func _actionCompute() {
        guard let points = drawPanel.pointParamArr else {
            return
        }
        let _computorx = CJSplineInterpolation()
        let _computory = CJSplineInterpolation()
        var _array_x = Array<CJInterpolationPoint>()
        var _array_y = Array<CJInterpolationPoint>()
        for i in 0...points.count - 1 {
            let _point = points[i] as! CJPointParam
            let _t = _point.time
            let _x = _point.location.x
            let _y = _point.location.y
            
            _array_x.append(CJInterpolationPoint(input: Double(_t), value: Double(_x)))
            _array_y.append(CJInterpolationPoint(input: Double(_t), value: Double(_y)))
        }
        
        _computorx.fixedPoints = _array_x
        _computory.fixedPoints = _array_y
        
        _computorx.solve()
        _computory.solve()
        
        let _newArr = NSMutableArray()
        for i in stride(from: 0.0, to: (points.lastObject as! CJPointParam).time, by: 0.01) {
            let _location = NSPoint(x: _computorx.interpolate(at: Double(i)), y: _computory.interpolate(at: Double(i)))
            let _point = CJPointParam(location: _location, time: i)
            _newArr.add(_point)
        }
        drawPanel.pointParamArr = _newArr
        drawPanel.setNeedsDisplay(drawPanel.frame)
        
        _log(pointParams: _newArr)
    }
}
