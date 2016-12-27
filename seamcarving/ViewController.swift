//
//  ViewController.swift
//  seamcarving
//
//  Created by Nav on 2016-12-25.
//  Copyright © 2016 Squad. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController {

    @IBOutlet var testImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func removeSeam() {
        let op = SobelEdgeDetection()
        let bwImage = self.testImage.image?.filterWithOperation(op)
        
        
        let width = self.testImage.image?.cgImage?.width
        let height = self.testImage.image?.cgImage?.height
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
        
        let bytesPerPixel: Int = 4
        let bytesPerRow: Int = width! * bytesPerPixel
        let bitsPerComponent: Int = 8
        let raw = malloc(bytesPerRow * height!)
        defer {
            free(raw)
        }
        
        guard let ctx = CGContext(data: raw, width: width!, height: height!, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorspace, bitmapInfo: bitmapInfo) else {
            fatalError("UIImageColors.getColors failed: could not create CGBitmapContext")
        }
        
        let drawingRect = CGRect(x: 0, y: 0, width: CGFloat(width!), height: CGFloat(height!))
        ctx.draw((bwImage?.cgImage)!, in: drawingRect)
        
        let data = ctx.data?.assumingMemoryBound(to: UInt8.self)
        let arr = Array(UnsafeBufferPointer(start: data, count: width! * height! * 4))
        let bwArr = arr.enumerated().filter({ index, _ in
            return (index-1) % 4 == 0
        }).map({$0.1})
        
        ctx.draw((self.testImage.image?.cgImage)!, in: drawingRect)
        let data2 = ctx.data?.assumingMemoryBound(to: UInt8.self)
        let realArr = Array(UnsafeBufferPointer(start: data2, count: width! * height! * 4))
        
        var weightsArr = [Int]()
        
        
        for (index, element) in bwArr.enumerated() {
            let row: Int = index / width!
            let col: Int = index % width!
            
            if row == 0 {
                weightsArr.append(Int(element))
                continue
            }
            
            let bottomLeft = (col == 0) ? Int.max : weightsArr[(row - 1) * width! + (col - 1)]
            let bottom = weightsArr[(row - 1) * width! + col]
            let bottomRight = (col == width! - 1) ? Int.max : weightsArr[(row - 1) * width! + (col + 1)]
            
            weightsArr.append(Int(element) + min(bottomLeft, bottom, bottomRight, Int.max))
        }
        
        var row = height! - 1
        var minCol = -1
        var minAccumulativeEnergy = Int.max
        for col in 0..<width! {
            let minValue = min(minAccumulativeEnergy, weightsArr[row * width! + col])
            if minAccumulativeEnergy != minValue {
                minAccumulativeEnergy = minValue
                minCol = col
            }
        }
        
        var path = [Int]()
        path.append(minCol)
        
        while (row > 0) {
            row = row - 1
            let bottomLeft = (minCol == 0) ? Int.max : weightsArr[row * width! + (minCol - 1)]
            let bottom = weightsArr[row * width! + minCol]
            let bottomRight = (minCol == width! - 1) ? Int.max : weightsArr[row * width! + (minCol + 1)]
            
            let minValue = min(bottomLeft, bottom, bottomRight)
            
            if (minValue == bottomLeft) {
                minCol = minCol - 1
            } else if (minValue == bottomRight) {
                minCol = minCol + 1
            }
            
            path.append(minCol)
        }
        
        let trimmedArr = realArr.enumerated().filter({(index, element) in
            let row: Int = index / (width!*4)
            let col: Int = index % (width!*4)
            let pathIndex = (height!-1) - row
            let excludeCol = path[pathIndex]
            if (col == (excludeCol*4) || col == (excludeCol*4 + 1) || col == (excludeCol*4 + 2) || col == (excludeCol*4 + 3)) {
                return false
            } else {
                return true
            }
        }).map({$0.1})
        
        let bitsPerComp = 8
        let bitsPerPixel = 32
        
        let providerRef = CGDataProvider(data: NSData(bytes: trimmedArr, length: trimmedArr.count))
        
        let cgImage = CGImage(width: (width!) - 1,
                              height: height!,
                              bitsPerComponent: bitsPerComp,
                              bitsPerPixel: bitsPerPixel,
                              bytesPerRow: (width! - 1) * 4,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                              provider: providerRef!,
                              decode: nil,
                              shouldInterpolate: false,
                              intent: CGColorRenderingIntent.defaultIntent)
        
        self.testImage.image = UIImage(cgImage: cgImage!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        self.removeSeam()
//        self.removeSeam()
        
        for i in 0...50 {
            self.removeSeam()
            print(i)
        }
        print(self.testImage.image?.size.width)
    }

}

