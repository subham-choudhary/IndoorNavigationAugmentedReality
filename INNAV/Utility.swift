//
//  Utility.swift
//  INNAV
//
//  Created by Choudhury,Subham on 18/04/18.
//  Copyright © 2018 Choudhury,Subham. All rights reserved.
//

import Foundation
import ARKit

class Utility {
    
    var shouldSetYAxis = true
    
    func saveFile (stringPathMap:[String:[String]],mapName:String) {
        
            guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            let fileUrl: URL = documentDirectoryUrl.appendingPathComponent(mapName+".json")
            
            do {
                let dataOut = try JSONSerialization.data(withJSONObject: stringPathMap, options: [])
                try dataOut.write(to: fileUrl, options: [])
                //            self.label.text = "File saved"
            } catch {
                print (error)
                return;
            }
    }
    func savePOIData(poiPositionStringArray:[String],mapName:String) {
        
            guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            let fileUrl: URL = documentDirectoryUrl.appendingPathComponent(mapName+"_poi"+".json")
            
            do {
                let dataOut = try JSONSerialization.data(withJSONObject: poiPositionStringArray, options: [])
                try dataOut.write(to: fileUrl, options: [])
                //            self.label.text = "File saved"
            } catch {
                print (error)
                return;
            }
    }
    func setYAxisTo(value:Float) {
        
        if shouldSetYAxis
        {
            UserDefaults.standard.set(value, forKey: "yaxis")
            shouldSetYAxis = false
        }
    }
    func getYAxis()->Float {
        
        return UserDefaults.standard.float(forKey: "yaxis")
        
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
    func getVector3FromString(str:String) -> vector_double3 {
        
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
