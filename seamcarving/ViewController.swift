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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let seamCarver = SeamCarver(image: self.testImage.image!)
        
        for i in 0...5 {
            seamCarver.removeSeam()
            print(i)
        }
        
        self.testImage.image = seamCarver.image!
    }

}

