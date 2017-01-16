import Foundation
import UIKit
import GPUImage

class SeamCarver: NSObject {
    var image: UIImage? = nil
    
    private var width: Int? = nil
    private var height: Int? = nil
    
    private var weightMatrix: [Int]? = nil
    
    private let bytesPerPixel = 4
    private let bitsPerComponent = 8
    
    private let colorspace = CGColorSpaceCreateDeviceRGB()
    private let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
    
    private let sobelOperator = SobelEdgeDetection()
    
    init(image: UIImage) {
        self.image = image
        self.width = self.image?.cgImage?.width
        self.height = self.image?.cgImage?.height
    }
    
    private func constructWeightMatrix(image: UIImage) {
        guard let width = self.width, let height = self.height else {
            print("width and height undefined")
            return
        }
        
        self.weightMatrix = Array(repeating: 0, count: width * height)
        
        let gradientImage = image.filterWithOperation(sobelOperator)
        
        let raw = malloc(self.bytesPerPixel * width * height)
        defer {
            free(raw)
        }
        
        guard let ctx = CGContext(data: raw, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: width * self.bytesPerPixel, space: self.colorspace, bitmapInfo: self.bitmapInfo) else {
            fatalError("UIImageColors.getColors failed: could not create CGBitmapContext")
        }
        
        let drawingRect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        ctx.draw((gradientImage.cgImage)!, in: drawingRect)
        let gradientArr = Array(UnsafeBufferPointer(start: ctx.data?.assumingMemoryBound(to: UInt8.self), count: width * height * 4))
        
        for index in 0...self.weightMatrix!.count {
            let gradientIndex = ((index + 1) * 4) - 1
            let gradientValue = gradientArr[gradientIndex]
            let row: Int = index / width
            let col: Int = index % width
            
            if row == 0 {
                self.weightMatrix![row * width + col] = Int(gradientValue)
                continue
            }
            
            let bottomLeft = (col == 0) ? Int.max : weightMatrix![(row - 1) * width + (col - 1)]
            let bottom = weightMatrix![(row - 1) * width + col]
            let bottomRight = (col == width - 1) ? Int.max : weightMatrix![(row - 1) * width + (col + 1)]
            
            weightMatrix![index] = Int(gradientValue) + min(bottomLeft, bottom, bottomRight)
        }
    }
    
    private func findOptimalVerticalSeam() -> [Int]? {
        guard let width = self.width, let height = self.height else {
            print("width and height undefined")
            return nil
        }
        
        var optimalSeam: [Int] = Array(repeating: -1, count: height)
        
        
        var row = height - 1
        var minCol = -1
        var minAccumulativeEnergy = Int.max
        for col in 0..<width {
            let minValue = min(minAccumulativeEnergy, weightMatrix![row * width + col])
            if minAccumulativeEnergy != minValue {
                minAccumulativeEnergy = minValue
                minCol = col
            }
        }
        
        optimalSeam[row] = minCol
        
        while (row > 0) {
            row = row - 1
            let bottomLeft = (minCol == 0) ? Int.max : weightMatrix![row * width + (minCol - 1)]
            let bottom = weightMatrix![row * width + minCol]
            let bottomRight = (minCol == width - 1) ? Int.max : weightMatrix![row * width + (minCol + 1)]
            
            let minValue = min(bottomLeft, bottom, bottomRight)
            
            if (minValue == bottomLeft) {
                minCol = minCol - 1
            } else if (minValue == bottomRight) {
                minCol = minCol + 1
            }
            
            optimalSeam[row] = minCol
        }
        
        return optimalSeam
    }
    
    func removeSeam() {
        
        self.constructWeightMatrix(image: self.image!)
        
        guard let width = self.width, let height = self.height else {
            print("width and height undefined")
            return
        }
        
        let raw = malloc(self.bytesPerPixel * width * height)
        defer {
            free(raw)
        }
        
        guard let ctx = CGContext(data: raw, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: width * self.bytesPerPixel, space: self.colorspace, bitmapInfo: self.bitmapInfo) else {
            fatalError("UIImageColors.getColors failed: could not create CGBitmapContext")
        }
        
        let drawingRect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        ctx.draw((self.image!.cgImage)!, in: drawingRect)
        let imagePixelData = Array(UnsafeBufferPointer(start: ctx.data?.assumingMemoryBound(to: UInt8.self), count: width * height * 4))
        
        guard let optimalVerticalSeam = self.findOptimalVerticalSeam() else {
            print("couldn't find optimal seam")
            return
        }
        
        
        let trimmedArr = imagePixelData.enumerated().filter({(index, element) in
            let row: Int = index / (width*4)
            let col: Int = index % (width*4)
            let excludeCol = optimalVerticalSeam[row]
            if (col == (excludeCol*4) || col == (excludeCol*4 + 1) || col == (excludeCol*4 + 2) || col == (excludeCol*4 + 3)) {
                return false
            } else {
                return true
            }
        }).map({$0.1})
        
        let providerRef = CGDataProvider(data: NSData(bytes: trimmedArr, length: trimmedArr.count))
        
        let cgImage = CGImage(width: width - 1,
                              height: height,
                              bitsPerComponent: self.bitsPerComponent,
                              bitsPerPixel: self.bitsPerComponent * self.bytesPerPixel,
                              bytesPerRow: (width - 1) * 4,
                              space: self.colorspace,
                              bitmapInfo: CGBitmapInfo(rawValue: self.bitmapInfo),
                              provider: providerRef!,
                              decode: nil,
                              shouldInterpolate: false,
                              intent: CGColorRenderingIntent.defaultIntent)
        
        self.width = self.width! - 1
        self.image = UIImage(cgImage: cgImage!)
    }
    
    
}
