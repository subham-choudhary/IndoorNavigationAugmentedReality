//
//  ViewController.swift
//  ARdraw
//
//  Created by Choudhury,Subham on 08/01/18.
//  Copyright © 2018 Choudhury,Subham. All rights reserved.
//

import UIKit
import ARKit
import GameplayKit

class ViewController: UIViewController,ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var drawBtn: UIButton!
    
    let configuration = ARWorldTrackingConfiguration()
    var tempNodeFlag = false
    var poiFlag = false
    var pathNodes = [SCNNode(),SCNNode()]
    var counter = 0
    var dictPlanes = [ARPlaneAnchor:Plane]()
    let rootTempNode = SCNNode()
    let rootPathNode = SCNNode()
    let rootConnectingNode = SCNNode()
    let rootNavigationNode = SCNNode()
    let poiRootNode = SCNNode()
    let myQueue = DispatchQueue(label: "myQueue", qos: .userInitiated)
    var showFloorMesh = true
    let pathGraph = GKGraph()
    
    var tempNavStartEndPoints = [SCNVector3(),SCNVector3()]
    var tempNavFlag = false
    var tempYAxis = Float()
    //
    // MARK: ViewDelegate Methods //
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.autoenablesDefaultLighting = true
        configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.scene.rootNode.addChildNode(rootPathNode)
        self.sceneView.scene.rootNode.addChildNode(poiRootNode)
        self.sceneView.scene.rootNode.addChildNode(rootNavigationNode)
        self.sceneView.scene.rootNode.addChildNode(rootConnectingNode)
//        self.sceneView.scene.rootNode.worldPosition = rootTempNode.position
    }
    //
    // MARK: ARSCNViewDelegate Methods //
    //
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if showFloorMesh{
            DispatchQueue.main.async {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    let plane = Plane(anchor: planeAnchor)
                    node.addChildNode(plane)
                    self.dictPlanes[planeAnchor] = plane
                }
            }
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                let plane = self.dictPlanes[planeAnchor]
                plane?.updateWith(planeAnchor)
            }
            let hitTest = self.sceneView.hitTest(self.view.center, types: .existingPlaneUsingExtent)
            if self.tempNodeFlag && !hitTest.isEmpty {
                self.addTempNode(hitTestResult: hitTest.first!)
            }
            if self.poiFlag && !hitTest.isEmpty {
                self.addPointOfInterestNode(hitTestResult: hitTest.first!)
                self.poiFlag = false
            }
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            self.dictPlanes.removeValue(forKey: planeAnchor)
        }
    }
    //
    // MARK: Button Actions //
    //
    @IBAction func StartAction(_ sender: Any) {
        
        if tempNodeFlag {
            tempNodeFlag = false
            drawBtn.setTitle("Start", for: .normal)
            removeTempNode()
            pathNodes[0].position.y = pathNodes[1].position.y
            tempYAxis = pathNodes[0].position.y
            addPathNodes(n1: pathNodes[0].position,n2: pathNodes[1].position)
            counter = 0
        } else {
            tempNodeFlag = true
            drawBtn.setTitle("Stop", for: .normal)
        }
    }
    @IBAction func AddPOIAction(_ sender: Any) {
        poiFlag = true
    }
    @IBAction func NavigateAction(_ sender: Any) {
        
        for (key,_) in dictPlanes {
            let plane = key as ARAnchor
            self.sceneView.session.remove(anchor: plane)
        }
        dictPlanes = [ARPlaneAnchor:Plane]()
        self.sceneView.debugOptions.remove(
            [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin])
        rootPathNode.removeFromParentNode()
        rootTempNode.removeFromParentNode()
        rootConnectingNode.removeFromParentNode()

//        for path in dempoArray {
//            let navigationNode = CylinderLine(v1: path.start, v2: path.end, radius: 0.2, UIImageName:"arrow5")
//            rootNavigationNode.addChildNode(navigationNode)
//        }
        let startNode = GKGraphNode2D.node(withPoint: vector2(tempNavStartEndPoints[0].x, tempNavStartEndPoints[0].z))
        let destNode = GKGraphNode2D.node(withPoint: vector2(tempNavStartEndPoints[1].x, tempNavStartEndPoints[1].z))
        
        let wayPoints: [GKGraphNode] = pathGraph.findPath(from: startNode, to: destNode)
//        let path: [GKGraphNode] = myGraph.findPath(from: nodeA, to: nodeF)
        
        var x = SCNVector3(startNode.position.x, tempYAxis, startNode.position.y)
        
        var skipFlag = true;
        for path in wayPoints {
            
            print(path)
            let pathWithoutY = (path as! GKGraphNode2D).position
            let y = SCNVector3(pathWithoutY.x, tempYAxis, pathWithoutY.y)
            if skipFlag {
                skipFlag = false
                x = y
                continue
            }
            let navigationNode = CylinderLine(v1: x, v2: y, radius: 0.2, UIImageName:"arrow5")
            rootNavigationNode.addChildNode(navigationNode)
            x = y
        }
        
    }
    //
    // MARK: Custom Methods //
    //
    func addTempNode(hitTestResult:ARHitTestResult) {
        
        let node = SCNNode(geometry: SCNSphere(radius: 0.05))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        node.position = SCNVector3Make(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        if counter == 0 {
            pathNodes[0] = node
            counter = 1
            self.sceneView.scene.rootNode.addChildNode(rootTempNode)
        } else {
            pathNodes[1] = node
            rootTempNode.addChildNode(node)
        }
        
    }
    func addPointOfInterestNode(hitTestResult:ARHitTestResult) {
        
        let node = SCNNode(geometry:SCNCylinder(radius: 0.1, height: 1))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        node.position = SCNVector3Make(thirdColumn.x, thirdColumn.y+0.5, thirdColumn.z)
        poiRootNode.addChildNode(node)
    }
    
    func addPathNodes(n1:SCNVector3, n2:SCNVector3) {
        
        var node1Positon = n1
        var node2Positon = n2
        var isNode1exists = false
        var isNode2exists = false
        rootPathNode.enumerateChildNodes({ (child, _) in
            
            if child.parent == rootPathNode {
                print("*")
            }
                let dist0 = distanceBetween(n1: n1, n2: child.position)
                let dist1 = distanceBetween(n1: n2, n2: child.position)
                if(dist0 <= 0.5){
                    node1Positon = child.position
                    isNode1exists = true
                }
                if(dist1 <= 0.5){
                    node2Positon = child.position
                    isNode2exists = true
                }
            
        })
        if distanceBetween(n1: node1Positon, n2: node2Positon) > 0.5 {
            
            if (!tempNavFlag) {
                tempNavStartEndPoints[0] = node1Positon
                tempNavFlag = true
            } else {
                tempNavStartEndPoints[1] = node2Positon
            }
            
            let pathNode = SCNNode()
            let node = SCNNode(geometry: SCNSphere(radius: 0.05))
            let node2 = SCNNode(geometry: SCNSphere(radius: 0.05))
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            node2.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            node.position = node1Positon
            node2.position = node2Positon
            pathNode.addChildNode(node)
            pathNode.addChildNode(node2)
            rootPathNode.addChildNode(pathNode)
//            dempoArray.append((start: node.position, end:node2.position))
            let connectingNode = SCNNode()
            rootConnectingNode.addChildNode(
                connectingNode.buildLineInTwoPointsWithRotation(
                    from: node1Positon,
                    to: node2Positon,
                    radius: 0.02,
                    color: .cyan))
            
//            let position1String = "\(node1Positon)"
//            let position2String = "\(node2Positon)"
        ///////////////////////////////////////////////
//            var gameNode1 = GKGraphNode2D()
//            var gameNode2 = GKGraphNode2D()
//
//            if isNode1exists {
//
//                gameNode1 = GKGraphNode2D.node(withPoint: vector2(node1Positon.x, node1Positon.z))
//
//            } else { // Create new node
//
//                gameNode1.position = vector2(node1Positon.x, node1Positon.z)
//                pathGraph.add([gameNode1])
//            }
//            if isNode2exists {
//
//                gameNode2 = GKGraphNode2D.node(withPoint: vector2(node2Positon.x, node2Positon.z))
//
//            } else { // Create new node
//
//                gameNode2.position = vector2(node2Positon.x, node2Positon.z)
//                pathGraph.add([gameNode2])
//            }
//            gameNode1.addConnections(to: [gameNode2], bidirectional: true)
//
//            isNode1exists = false
//            isNode2exists = false
      }
    }
    func removeTempNode() {
        rootTempNode.removeFromParentNode()
        myQueue.async {
            self.rootTempNode.enumerateChildNodes { (node, _) in
                node.removeFromParentNode()
            }
        }
    }
    func distanceBetween(n1:SCNVector3,n2:SCNVector3) -> Float {
        return ((n1.x-n2.x)*(n1.x-n2.x) + (n1.z-n2.z)*(n1.z-n2.z)).squareRoot()
    }
    
    func midPointBetween(n1:SCNVector3,n2:SCNVector3) -> SCNVector3 {
        
        return SCNVector3Make(((n1.x+n2.x)/2), ((n1.y+n2.y)/2), ((n1.z+n2.z)/2))
    }
    
    func angleOfInclination(n1:SCNVector3,n2:SCNVector3)-> Float{
        
        let theta = ((n2.z-n1.z)/(n2.x-n1.x)).degreesToRadians // m = tan0 //
        return Float(tan(theta))
    }
}
