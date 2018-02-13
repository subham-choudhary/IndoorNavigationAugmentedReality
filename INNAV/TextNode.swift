//
//  TextNode.swift
//  INNAV
//
//  Created by Choudhury,Subham on 12/02/18.
//  Copyright © 2018 Choudhury,Subham. All rights reserved.
//

import UIKit
import SceneKit

class TextNode: SCNNode {
    
    private let extrusionDepth: CGFloat = 0.01                  // Text depth
    private let textNodeScale = SCNVector3Make(0.2, 0.2, 0.2)   // Scale applied to node
    private var text: SCNText?
    
    public var color = UIColor.black {
        didSet {
            text?.firstMaterial?.diffuse.contents = color
        }
    }
    
    public var font: UIFont? = UIFont.systemFont(ofSize: 0.1) {
        didSet {
            text?.font = UIFont(name: "AvenirNext-Bold", size: 0.1)
        }
    }
    
    public var alignmentMode = kCAAlignmentCenter {
        didSet {
            text?.alignmentMode = kCAAlignmentCenter
        }
    }
    
    init(_ string: String) {
        super.init()
        let constraint = SCNBillboardConstraint()
        let node = SCNNode()
        let max, min: SCNVector3
        let tx, ty, tz: Float
        
        constraint.freeAxes = .Y
        
        text = SCNText(string: string, extrusionDepth: extrusionDepth)
        text?.alignmentMode = alignmentMode
        text?.firstMaterial?.diffuse.contents = color
        text?.firstMaterial?.specular.contents = UIColor.white
        text?.firstMaterial?.isDoubleSided = true
        text?.chamferRadius = extrusionDepth
        text?.font = font
        
        max = text!.boundingBox.max
        min = text!.boundingBox.min
        
        tx = (max.x - min.x) / 2.0
        ty = min.y
        tz = Float(extrusionDepth) / 2.0
        
        node.geometry = text
        node.scale = scale
        node.pivot = SCNMatrix4MakeTranslation(tx, ty, tz)
        
        self.addChildNode(node)
        
//        self.constraints = constraint
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
