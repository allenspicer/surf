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
    let selectedId = "41110"
    let selectedBFD = 100.0
    var favoriteSnapshots : [String : Bool]  = ["41110" : false]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // determine what breaks are in favorites
        
        // load snapshot for each and add to array
        getSnapshot()
        

    }
    
    func segueWhenComplete(){
        if !favoriteSnapshots.values.contains(false){
            self.performSegue(withIdentifier: "segueInitalToHome", sender: self)
        }
    }
    
    
    func getSnapshot(){
        DispatchQueue.global(qos:.utility).async {
            let snapshotSetter = SnapshotSetter(stationId: self.selectedId, beachFaceDirection: self.selectedBFD)
            let snapshot = snapshotSetter.createSnapshot(finished: {})
            //remove spinner for response:
            if snapshot.waveHgt != nil && snapshot.waterTemp != nil {
                self.favoriteSnapshots["\(self.selectedId)"] = true
                self.segueWhenComplete()
            }else{
                DispatchQueue.main.async {
                    //if no data respond with alertview
//                    self.stopActivityIndicator()
                    let alert = UIAlertController.init(title: "Not enough Data", message: "This bouy is not providing much data at the moment", preferredStyle: .alert)
                    let doneAction = UIAlertAction(title: "Cancel", style: .destructive)
                    alert.addAction(doneAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destinationVC = segue.destination as? HomeViewController {
            destinationVC.arrayOfSnapshots = arrayOfSnapshots
        }
    }
 

}
