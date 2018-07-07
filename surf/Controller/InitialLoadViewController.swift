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
        
        DispatchQueue.global(qos:.utility).async{
            self.setUserFavorites(){ (favoritesDictionary) in
                self.addFavoriteStationsToCollectionData()
            }
        }
        
        // load snapshot for each and add to array
        getSnapshot()
        
        //transition when snapshot array is complete and pass it forward
        

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
                    let alert = UIAlertController.init(title: "Not enough Data", message: "This bouy is not providing much data at the moment", preferredStyle: .alert)
                    let doneAction = UIAlertAction(title: "Cancel", style: .destructive)
                    alert.addAction(doneAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func setUserFavorites (completion:@escaping ([String : Int])->Void){
        let defaults = UserDefaults.standard
        if let favorites = defaults.array(forKey: DefaultConstants.favorites) as? [Int], let names = defaults.array(forKey: DefaultConstants.nicknames) as? [String]{
            favoritesArray = favorites
            nicknamesArray = names
            for index in 0..<favorites.count {
                let favorite = favorites[index]
                let name = names[index]
                favoriteStationIdsFromMemory[name] = favorite
            }
        }
        completion(favoriteStationIdsFromMemory)
    }
    
    private func addFavoriteStationsToCollectionData(){
        if let path = Bundle.main.path(forResource: "regionalBuoyList", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                //meta data is all possible surf bouy stations
                //currently checking entire list against saved IDs
                //and appending matches to the collection view data
                
                if let metaData = jsonResult as? [[String : AnyObject]]{
                    for station in metaData {
                        guard let id = station["id"] as? Int else {return}
                        if !self.favoriteStationIdsFromMemory.values.contains(id) {continue}
                        guard let stationId = station["station"] as? Int else {return}
                        guard let beachFaceDirection = station["bfd"] as? Double else {return}
                        guard let name = station["name"] as? String else {return}
                        let favorite = Favorite(id: "\(id)", stationId: "\(stationId)", beachFaceDirection: beachFaceDirection, name: name)
                        favoritesData.append(favorite)
                    }
                    DispatchQueue.main.async{
//                        self.carousel.type = .rotary
//                        self.carousel.perspective = -0.0020
//                        self.carousel.viewpointOffset = CGSize(width: 0, height: -125)
//                        self.carousel.dataSource = self
//                        self.carousel.delegate = self
//                        self.stopActivityIndicator()
                    }
                }
            } catch {
                // handle error
                print("Problem accessing regional buoy list document: \(error)")
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
