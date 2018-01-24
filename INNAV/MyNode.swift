import GameplayKit

class MyNode: GKGraphNode3D {
    let name: String
    var travelCost: [GKGraphNode: Float] = [:]
    
    init() {
        self.name = "myNode"
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.name = ""
        super.init()
    }
    
    override func cost(to node: GKGraphNode) -> Float {
        return travelCost[node] ?? 0
    }
    
    func addConnection(to node: GKGraphNode, bidirectional: Bool = true, weight: Float) {
        self.addConnections(to: [node], bidirectional: bidirectional)
        travelCost[node] = weight
        guard bidirectional else { return }
        (node as? MyNode)?.travelCost[self] = weight
    }
}

func print(_ path: [GKGraphNode]) {
    path.flatMap({ $0 as? MyNode}).forEach { node in
        print(node)
    }
}

func printCost(for path: [GKGraphNode]) {
    var total: Float = 0
    for i in 0..<(path.count-1) {
        total += path[i].cost(to: path[i+1])
    }
    print(total)
}
