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
import Placenote

class ViewController: UIViewController,ARSCNViewDelegate,PNDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var drawBtn: UIButton!
    @IBOutlet weak var navigateBtn: UIButton!
    @IBOutlet weak var addPOIBtn: UIButton!
    
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
    let rootPOINode = SCNNode()
    let myQueue = DispatchQueue(label: "myQueue", qos: .userInitiated)
    var showFloorMesh = false
    
    var pathGraph = GKGraph()
    let origin = SCNVector3Make(0, 0, 0)
    var tempYAxis = Float()
    
    var stringMap = [String:[String]]()
    var dictOfNodes = [String:GKGraphNode2D]()
    var poiNode = [String]()
    var strNode = String()
    var cameraLocation = SCNVector3()
    var poiName = [String]()
    var poiCounter = 0
    weak var timer: Timer?
    
    private var camManager: CameraManager? = nil;
    private var ptViz: FeaturePointVisualizer? = nil;
    private var placenoteSessionRunning: Bool = false
    
    //
    // MARK: ViewDelegate Methods //
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        LibPlacenote.instance.multiDelegate += self
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.autoenablesDefaultLighting = true
        configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        if let camera: SCNNode = sceneView?.pointOfView {
            camManager = CameraManager(scene: sceneView.scene, cam: camera)
        }
        ptViz = FeaturePointVisualizer(inputScene: sceneView.scene);
        ptViz?.enableFeaturePoints()
        
        self.sceneView.scene.rootNode.addChildNode(rootPathNode)
        self.sceneView.scene.rootNode.addChildNode(rootPOINode)
        self.sceneView.scene.rootNode.addChildNode(rootNavigationNode)
        self.sceneView.scene.rootNode.addChildNode(rootConnectingNode)
        poiName.append("Garrage X")
        poiName.append("Cafe")
    }
    //
    // MARK: PNDelegate Methods
    //
    func onPose(_ outputPose: matrix_float4x4, _ arkitPose: matrix_float4x4) {
        
    }
    
    func onStatusChange(_ prevStatus: LibPlacenote.MappingStatus, _ currStatus: LibPlacenote.MappingStatus) {
        
    }
    //
    // MARK: ARSCNViewDelegate Methods
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
            guard let pointOfView = self.sceneView.pointOfView else { return }
            let transform = pointOfView.transform
            self.cameraLocation = SCNVector3(transform.m41, transform.m42, transform.m43)
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
            addPOIBtn.isHidden = false
        } else {
            tempNodeFlag = true
            drawBtn.setTitle("Stop", for: .normal)
        }
    }
    @IBAction func AddPOIAction(_ sender: Any) {
        
//        let alertCtrlr = UIAlertController(title: "Point of Interest", message: nil , preferredStyle: .alert)
//        alertCtrlr.addTextField { (textField) in
//            textField.placeholder = "Enter a name for POI"
//        }
//        let action = UIAlertAction(title: "Done", style: .default) { (alertAction) in
//            let textField = alertCtrlr.textFields![0] as UITextField
//            self.poiName.append(textField.text!)
//            self.poiFlag = true
//        }
//
//        alertCtrlr.addAction(action)
//        self.present(alertCtrlr,animated:true,completion:nil)
       self.poiFlag = true
        poiCounter += 1
        
    }
    @IBAction func NavigateAction(_ sender: Any) {
        
        let alertCtrlr = UIAlertController(title: "Select POI", message: nil , preferredStyle: .alert)
        
        timer?.invalidate()

        let action1 = UIAlertAction(title: poiName.first, style: .default) { (alertAction) in
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.tempFunc(destNode: (self?.poiNode.first!)!)
            }
        }
        let action2 = UIAlertAction(title: poiName[1], style: .default) { (alertAction) in
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.tempFunc(destNode: (self?.poiNode[1])!)
            }
            
        }
        
        alertCtrlr.addAction(action1)
        alertCtrlr.addAction(action2)
        self.present(alertCtrlr,animated:true,completion:nil)
        
    }
    //
    // MARK: Custom Methods //
    //
    func tempFunc(destNode:String) {
        
        for (key,_) in dictPlanes {
            let plane = key as ARAnchor
            self.sceneView.session.remove(anchor: plane)
        }
        dictPlanes = [ARPlaneAnchor:Plane]()
        self.sceneView.debugOptions.remove(
            [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin])
//                rootPathNode.removeFromParentNode()
        rootTempNode.removeFromParentNode()
                rootConnectingNode.removeFromParentNode()
        
        var minDistanc = Float()
        minDistanc = 1000
        var nearestNode = SCNNode()
        
        rootPathNode.enumerateChildNodes { (child, _) in
            if !isEqual(n1: origin, n2: child.position) {
                
                let dist0 = distanceBetween(n1: cameraLocation, n2: child.position)
                if minDistanc>dist0 {
                    
                    minDistanc = dist0
                    nearestNode = child
                }
            }
        }
        
        stringMap["\(cameraLocation)"] = ["\(nearestNode.position)"]
        strNode = "\(cameraLocation)"
        
        retrieveFromDictAndNavigate(destNode:destNode)
    }
    func retrieveFromDictAndNavigate(destNode:String) {
        
        rootNavigationNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        for data in stringMap {
            let myVector = self.getVector2FromString(str: data.key)
            dictOfNodes[data.key] = GKGraphNode2D(point: vector2(Float(myVector.x),Float(myVector.z)))
            pathGraph.add([dictOfNodes[data.key]!])
        }
        for data in stringMap {
            print(data)
            
            let keyNode = dictOfNodes[data.key]!
            
            for data2 in data.value {
                keyNode.addConnections(to: [dictOfNodes["\(data2)"]!], bidirectional: true)
            }
        }
        let startKeyVectorString = strNode
        let destKeyVectorString = destNode
        
        let startNodeFromDict = dictOfNodes[startKeyVectorString]
        let destNodeFromDict = dictOfNodes[destKeyVectorString]
        let wayPoint:[GKGraphNode2D] = pathGraph.findPath(from: startNodeFromDict!, to: destNodeFromDict!) as! [GKGraphNode2D]
        
        var x = wayPoint[0]
        var skipWaypointFlag = true
        for path in wayPoint {
            
            if skipWaypointFlag {
                skipWaypointFlag = false
                continue
            }
            let str = SCNVector3(x.position.x, tempYAxis, x.position.y)
            let dst = SCNVector3(path.position.x, tempYAxis, path.position.y)
            let navigationNode = CylinderLine(v1: str, v2: dst, radius: 0.2, UIImageName:"arrow5")
            navigationNode.startTimer()
            rootNavigationNode.addChildNode(navigationNode)
            x = path
        }
        pathGraph = GKGraph()
        stringMap.removeValue(forKey: strNode)
        
    }
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
       
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        
        let node = SCNNode(geometry:SCNCylinder(radius: 0.04, height: 1.7))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        node.position = SCNVector3Make(thirdColumn.x, thirdColumn.y+0.85, thirdColumn.z)
        rootPOINode.addChildNode(node)
        
        let node2 = SCNNode(geometry:SCNBox(width: 0.25, height: 0.25, length: 0.25, chamferRadius: 0.01))
        
        switch poiCounter {
        case 1:
            node2.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "G")
        case 2:
            node2.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "C")
            self.navigateBtn.isHidden = false
        default:
            node2.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "C")
        }
        node2.position = SCNVector3Make(thirdColumn.x, thirdColumn.y+1.5, thirdColumn.z)
        rootPOINode.addChildNode(node2)
        
        var minDistanc1 = Float()
        minDistanc1 = 1000
        var nearestNode1 = SCNNode()
        
        rootPathNode.enumerateChildNodes { (child, _) in
            if !isEqual(n1: origin, n2: child.position) {
                
                let dist0 = distanceBetween(n1: node.position, n2: child.position)
                if minDistanc1>dist0 {
                    
                    minDistanc1 = dist0
                    nearestNode1 = child
                }
            }
        }
        var minDistanc2 = Float()
        minDistanc2 = 1000
        var nearestNode2 = SCNNode()
        
        rootPathNode.enumerateChildNodes { (child, _) in
            if !isEqual(n1: origin, n2: child.position) && !isEqual(n1: child.position, n2: nearestNode1.position) {
                
                let dist0 = distanceBetween(n1: node.position, n2: child.position)
                if minDistanc2>dist0 {
                    
                    minDistanc2 = dist0
                    nearestNode2 = child
                }
            }
        }
        stringMap["\(node.position)"] = ["\(nearestNode2.position)"]
        poiNode.append("\(node.position)")
    }
    
    func addPathNodes(n1:SCNVector3, n2:SCNVector3) {
        
        var node1Position = n1
        var node2Position = n2
        var isNode1exists = false
        var isNode2exists = false
        rootPathNode.enumerateChildNodes({ (child, _) in
            
            // To merge path node less than 0.5 meters
            if !isEqual(n1: origin, n2: child.position) {
                
                let dist0 = distanceBetween(n1: n1, n2: child.position)
                let dist1 = distanceBetween(n1: n2, n2: child.position)
                if(dist0 <= 0.5){
                    node1Position = child.position
                    isNode1exists = true
                }
                if(dist1 <= 0.5){
                    node2Position = child.position
                    isNode2exists = true
                }
            }
        })
        addPathNodeWithConnectingNode(node1Position: node1Position, node2Positon: node2Position)
        mapNodePositionToStringMap(node1Positon: node1Position, node2Positon: node2Position, isNode1exists: isNode1exists, isNode2exists: isNode2exists)
        
        isNode1exists = false
        isNode2exists = false
    }
    //TO add path nodes and connecting node
    func addPathNodeWithConnectingNode(node1Position:SCNVector3,node2Positon:SCNVector3) {
        
        let pathNode = SCNNode()
        let node = SCNNode(geometry: SCNSphere(radius: 0.05))
        let node2 = SCNNode(geometry: SCNSphere(radius: 0.05))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node2.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node.position = node1Position
        node2.position = node2Positon
        pathNode.addChildNode(node)
        pathNode.addChildNode(node2)
        rootPathNode.addChildNode(pathNode)
        let connectingNode = SCNNode()
        rootConnectingNode.addChildNode(
            connectingNode.buildLineInTwoPointsWithRotation(
                from: node1Position,
                to: node2Positon,
                radius: 0.02,
                color: .cyan))
        
    }
    //TO map nodes into String Dictionary
    func mapNodePositionToStringMap (node1Positon:SCNVector3,node2Positon:SCNVector3,
                               isNode1exists:Bool,isNode2exists:Bool ) {
        
        let position1String = "\(node1Positon)"
        let position2String = "\(node2Positon)"
        
        if isNode1exists {
            
            var arr = stringMap[position1String]
            arr?.append(position2String)
            stringMap[position1String] = arr
            
        } else { // Create new node
            stringMap[position1String] = [position2String]
        }
        if isNode2exists {
            
            var arr = stringMap[position2String]
            arr?.append(position1String)
            stringMap[position2String] = arr
            
        } else { // Create new node
            stringMap[position2String] = [position1String]
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
    func isEqual(n1:SCNVector3,n2:SCNVector3)-> Bool {
        if (n1.x == n2.x) && (n1.y == n2.y) && (n1.z == n2.z) {
            return true
        } else {
            return false
        }
    }
    func getVector2FromString(str:String) -> vector_double3 {
        
        let xrange = str.index(str.startIndex, offsetBy: 10)...str.index(str.endIndex, offsetBy: -1)
        let str1 = str[xrange]
        
        var x:String = ""
        var y:String = ""
        var z:String = ""
        var counter = 1
        for i in str1 {
            //    print (i)
            if (i == "-" || i == "." || i == "0" || i == "1" || i == "2" || i == "3" || i == "4" || i == "5" || i == "6" || i == "7" || i == "8" || i == "9") {
                switch counter {
                case 1 : x = x + "\(i)"
                case 2 : y = y + "\(i)"
                case 3 : z = z + "\(i)"
                default : break
                }
            } else if (i == ",") {
                counter = counter + 1
            }
        }
        return vector3(Double(x)!,Double(y)!,Double(z)!)
    }
}

