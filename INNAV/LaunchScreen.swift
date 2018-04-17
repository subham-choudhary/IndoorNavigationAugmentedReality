//
//  LaunchScreen.swift
//  INNAV
//
//  Created by Choudhury,Subham on 11/04/18.
//  Copyright © 2018 Choudhury,Subham. All rights reserved.
//

import UIKit

class LaunchScreen: UIViewController {
    
    @IBOutlet weak var heading: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        let loadingView = UIView(frame: CGRect(x: 0.0, y: heading.frame.origin.y + heading.frame.height + 6, width: 1.0, height: 2))
        loadingView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.85)
        self.view.addSubview(loadingView)
        
        UIView.animate(withDuration: 1, delay: 0.3, options: [],
                       animations: {
                        loadingView.frame.size.width = self.view.frame.size.width - 50.0
        },
                       completion: {_ in
                        UIView.animate(withDuration: 1, delay: 0.5, options: [],
                                       animations: {
                                        loadingView.frame.size.width = self.view.frame.size.width
                        },
                                       completion: {_ in
                                        self.performSegue(withIdentifier: "launchScreen", sender: nil)
                        })
        })
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
  
}

