//
//  Maps.swift
//  INNAV
//
//  Created by Choudhury,Subham on 12/04/18.
//  Copyright © 2018 Choudhury,Subham. All rights reserved.
//

import UIKit

class MapTableViewCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    
}

class Maps: UIViewController,UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate {
    
    @IBOutlet weak var newMapTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var mapDictionary = [String:String]()
    var mapArray = [String]()
    let label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newMapTextField.isHidden = true
        newMapTextField.delegate = self
        newMapTextField.returnKeyType = .done
        guard let mapDict = UserDefaults.standard.object(forKey: "mapList")
            else {return}
        self.mapDictionary = mapDict as! [String:String]
        for i in mapDictionary {
            
            mapArray.append(i.key)
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if mapArray.count == 0 {
            
            label.text = "Create a new map by tapping on (+) icon"
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
            label.alpha = 0.7
            label.frame = CGRect(x: 20, y: 80, width: self.view.frame.size.width-40, height: 40)
            self.view.addSubview(label)
        }
        else {
            label.removeFromSuperview()
        }
        return mapArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "mapCell", for: indexPath) as! MapTableViewCell
        
        cell.label.text = mapArray[indexPath.row]
        cell.selectionStyle = .none
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        UserDefaults.standard.set(mapArray[indexPath.row], forKey: "mapName")
        UserDefaults.standard.set(mapDictionary, forKey: "mapList")
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            removeItemFromDocDir(name: mapArray[indexPath.row])
            removeItemFromDocDir(name: mapArray[indexPath.row] + "_poi")
            
            self.mapDictionary.removeValue(forKey: mapArray[indexPath.row])
            self.mapArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            UserDefaults.standard.set(mapDictionary, forKey: "mapList")
            
        }
    }

    @IBAction func addMap(_ sender: Any) {
        
        newMapTextField.isHidden = false
        newMapTextField.becomeFirstResponder()
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        newMapTextField.isHidden = true
        mapArray.insert(newMapTextField.text!, at: 0)
        mapDictionary[mapArray.first!] = ""
        UserDefaults.standard.set(mapDictionary, forKey: "mapList")
        newMapTextField.text = ""
        textField.resignFirstResponder()
        tableView.reloadData()
        return true
    }
    func removeItemFromDocDir(name:String) {
        
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let filePath: URL = documentDirectoryUrl.appendingPathComponent(name+".json")
        
        let fileManager = FileManager.default
        // Check if file exists
        if fileManager.fileExists(atPath: filePath.path) {
            // Delete file
            do {
                try fileManager.removeItem(atPath: filePath.path)
            } catch {
                print("throws")
            }
        } else {
            print("File does not exist")
        }

    }
}

