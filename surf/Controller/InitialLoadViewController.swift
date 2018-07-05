//
//  InitialLoadViewController.swift
//  surf
//
//  Created by Allen Spicer on 7/5/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

class InitialLoadViewController: UIViewController {
    
    var arrayOfSnapshots = [Snapshot]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // determine what breaks are in favorites
        
        // load initial data for each favorite
        
        

    }
    

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destinationVC = segue.destination as? HomeViewController {
            destinationVC.arrayOfSnapshots = arrayOfSnapshots
        }
    }
 

}
