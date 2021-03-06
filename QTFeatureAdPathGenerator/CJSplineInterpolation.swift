//
//  CJSplineInterpolation.swift
//  QTFeatureAdPathGenerator
//
//  Created by fminor on 23/12/2016.
//  Copyright © 2016 fminor. All rights reserved.
//

import Cocoa

class CJSplineInterpolation: CJInterpolation {
    
    typealias Input = Double
    typealias Output = Double
    
    var fixedPoints: [CJAlgorithmData<Input, Output>]?
    
    var functionCount: Int {
        get {
            return self.pointCount - 1
        }
    }
    
    fileprivate var h = [Input]()         // h[i] = x[i+1] - x[i] , 共 n - 1 个
    fileprivate var z = [Input]()          // z: 共 n 个
    
    func solve() {
        guard let _fixedPoints = fixedPoints else {
            return
        }
        
        h = Array<Double>()
        for i in 0...self.functionCount - 1 {
            h.insert(_fixedPoints[i+1].x - _fixedPoints[i].x, at: i)
        }
        
        var a = [Double]()
        var b = [Double]()
        var c = [Double]()
        var r = [Double]()
        for i in 0...self.pointCount - 1 {
            if i == 0 {
                a.append(0.0)
                b.append(1.0)
                c.append(0.0)
                r.append(0.0)
                continue
            }
            if i == self.pointCount - 1 {
                a.append(1.0)
                b.append(0.0)
                c.append(0.0)
                r.append(0.0)
                continue
            }
            a.append(h[i-1])
            b.append(2 * ( h[i-1] + h[i] ))
            c.append(h[i])
            
            let _part1 = ( _fixedPoints[i+1].y - _fixedPoints[i].y ) / h[i];
            let _part2 = ( _fixedPoints[i].y - _fixedPoints[i-1].y ) / h[i-1];
            let _r = 6 * ( _part1 - _part2 );
            r.append(_r)
        }
        
        z = solveTridiagonalMetrix(a: a, b: b, c: c, r: r)
    }
    
    func interpolate(at input: Double) -> Double {
        guard let pts = self.fixedPoints else {
            return 0.0
        }
        
        if input < pts[0].x || input > (pts.last?.x)! {
            return 0.0
        }
        
        var i = 0
        for j in 0...self.functionCount - 1 {
            i = j
            if (self.fixedPoints?[i+1].x)! > input {
                break
            }
        }
        
        // Si(x) = (z[i+1](x-x[i])^3 + z[i](x[i+1]-x)^3)/6h[i] + (y[i+1]/h[i] - h[i]/6*z[i+1])(x-x[i])
        //  + (y[i]/h[i] - h[i]z[i]/6)(x[i+1]-x)
        
        let x_xi = input - pts[i].x
        let xi1_x = pts[i+1].x - input
        let _p1 = ( z[i+1] * x_xi * x_xi * x_xi + z[i] * xi1_x * xi1_x * xi1_x ) / ( 6.0 * h[i] )
        let _p2 = ( pts[i+1].y / h[i] - h[i] * z[i+1] / 6.0 ) * x_xi
        let _p3 = ( pts[i].y / h[i] - h[i] * z[i] / 6.0 ) * xi1_x
        return _p1 + _p2 + _p3
    }
    
    
    func solveTridiagonalMetrix(a: Array<Double>, b: Array<Double>, c: Array<Double>, r: Array<Double>) -> Array<Double> {
        guard a.count == b.count && b.count == c.count && c.count == r.count else {
            return Array<Double>()
        }
        
        var _result = Array<Double>()
        var p = Array<Double>()
        var q = Array<Double>()
        let n = a.count
        for i in 0...n - 1 {
            if i == 0 {
                p.append(c[0] / b[0])
                q.append(r[0] / b[0])
                continue
            }
            p.append(c[i] / ( b[i] - a[i] * p[i-1]))
            q.append(( r[i] - a[i] * q[i-1] ) / ( b[i] - a[i] * p[i-1] ))
        }
        
        for j in 0...n - 1 {
            let i = n - 1 - j
            if i == n - 1 {
                _result.append(q[i])
                continue
            }
            _result.insert(q[i] - p[i] * _result[0], at: 0)
        }
        return _result
    }
}

