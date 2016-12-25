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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let op = SobelEdgeDetection()
        self.testImage.image = self.testImage.image?.filterWithOperation(op)
        
        
        let width = self.testImage.image?.cgImage?.width
        let height = self.testImage.image?.cgImage?.height
        let colorspace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue

        let bytesPerPixel: Int = 1
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
        ctx.draw((self.testImage.image?.cgImage)!, in: drawingRect)
        
        let data = ctx.data?.assumingMemoryBound(to: UInt8.self)
        print(data)
    }

}

