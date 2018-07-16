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
    var favoritesToBeLoaded = [Favorite]()
    var favoriteSnapshots = [String : Bool]()
    var activityIndicatorView = ActivityIndicatorView()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var waves: [Wave] = []



    override func viewDidLoad() {
        super.viewDidLoad()
        
        let activityIndicatorView = ActivityIndicatorView().setupActivityIndicator(view: self.view, widthView: nil, backgroundColor:UIColor.black.withAlphaComponent(0.1), textColor: UIColor.gray, message: "loading...")
        self.view.addSubview(activityIndicatorView)
        
        self.getData()
        
        // determine what breaks are in favorites
        DispatchQueue.global(qos:.utility).async{
            self.setUserFavorites(){ (favoritesDictionary) in
                if self.favoriteSnapshots.count > 0 { self.addFavoriteStationsToCollectionData() }
                self.segueWhenComplete()
            }
        }
    }
    
    func getData() {
        do {
            waves = try context.fetch(Wave.fetchRequest())
        }
        catch {
            print("Fetching Failed")
        }
    }
    
    func segueWhenComplete(){
        if !favoriteSnapshots.values.contains(false){
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "segueInitalToHome", sender: self)
            }
        }
    }
    
    
    func getSnapshotWith(id : String, stationId: String, beachFaceDirection : Double){
        DispatchQueue.global(qos:.utility).async {
            let snapshotSetter = SnapshotSetter(stationId: stationId, beachFaceDirection: beachFaceDirection)
            let snapshot = snapshotSetter.createSnapshot(finished: {})
            //if snapshot worked update snapshot array
            if snapshot.waveHgt != nil && snapshot.waterTemp != nil {
                
                DispatchQueue.main.async {
                    //add to persistent container
                    let wave = Wave(context: self.context)
                    wave.timestamp = Date()
                    if let waveId = snapshot.id {
                        wave.id = Int32(waveId)
                    }
                    if let waveHeight = snapshot.waveHgt {
                        wave.waveHeight = waveHeight
                    }
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                }

                self.favoriteSnapshots[id] = true
                self.arrayOfSnapshots.append(snapshot)
                //segue when all snapshots are available
                self.segueWhenComplete()
//            }else{
                
                //delay then try creating endpoint again
                //eventually show user error. 
                
                
//                DispatchQueue.main.async {
//                    //if no data respond with alertview
//                    let alert = UIAlertController.init(title: "Not enough Data", message: "This bouy is not providing much data at the moment", preferredStyle: .alert)
//                    let doneAction = UIAlertAction(title: "Cancel", style: .destructive)
//                    alert.addAction(doneAction)
//                    self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func setUserFavorites (completion:@escaping ([String : Int])->Void){
        
        // retrieve defaults and set up a local dictionary with the users favorites and a false flag
        // false here is a default value to indicate this favorite has not been downloaded
        
        let defaults = UserDefaults.standard
        if let favorites = defaults.array(forKey: DefaultConstants.favorites) as? [Int], let names = defaults.array(forKey: DefaultConstants.nicknames) as? [String]{
            
            for index in 0..<favorites.count {
                let favorite = favorites[index]
                // currently doing nothing with the nickname chosen by the user and saved in defaults
//                let name = names[index]
                    favoriteSnapshots["\(favorite)"] = false
            }
        }
        completion([String : Int]())
    }
    
    private func addFavoriteStationsToCollectionData(){
        
        
        
        //if a wave is availabe in persistence from the last 5 minutes
        //with the right id
        //load that as snapshot
        let fiveMinutes: TimeInterval = 5.0 * 60.0
        print("there are \(waves.count) saved waves")
        print("the wave timestamps are :")

        for wave in waves{
            print(wave.id)
            print(wave.timestamp)
            guard let timestamp = wave.timestamp else {return}
            if abs(timestamp.timeIntervalSinceNow) < fiveMinutes {
                if self.favoriteSnapshots["\(wave.id)"] == false {
                    print("snapshot being taken from persistence")
                    self.favoriteSnapshots["\(wave.id)"] = true
                    //make snapshot here
                    var snapshot = Snapshot.init()
                    snapshot.timeStamp = timestamp
                    snapshot.waveHgt = wave.waveHeight
                    snapshot.id = Int(wave.id)
                    self.arrayOfSnapshots.append(snapshot)
                    //segue when all snapshots are available
                    self.segueWhenComplete()
                }
            }else {
                //remove from persistent container
                DispatchQueue.main.async {
                    self.context.delete(wave)
                }
            }
        }
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }

        
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
                        if !self.favoriteSnapshots.keys.contains("\(id)") {continue}
                        guard let stationId = station["station"] as? Int else {return}
                        guard let beachFaceDirection = station["bfd"] as? Double else {return}
                        guard let name = station["name"] as? String else {return}
                        let favorite = Favorite(id: "\(id)", stationId: "\(stationId)", beachFaceDirection: beachFaceDirection, name: name)
                        favoritesToBeLoaded.append(favorite)
                    }
                        // load snapshot for each Favorite
                        for favorite in favoritesToBeLoaded {
                                self.getSnapshotWith(id: favorite.id, stationId: favorite.stationId, beachFaceDirection: favorite.beachFaceDirection)
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
            destinationVC.favoritesSnapshots = arrayOfSnapshots
        }
    }
 

}
