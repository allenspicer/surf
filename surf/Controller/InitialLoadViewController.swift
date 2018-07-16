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
    var favoriteSnapshots = [Favorite : Bool]()
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
            print("Failed to retrieve Wave Entity from context.")
        }
    }
    
    func segueWhenComplete(){
        if !favoriteSnapshots.values.contains(false){
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "segueInitalToHome", sender: self)
            }
        }
    }
    
    
    func getSnapshotWith(id : Int, stationId: String, beachFaceDirection : Double){
        DispatchQueue.global(qos:.utility).async {
            let snapshotSetter = SnapshotSetter(stationId: stationId, beachFaceDirection: beachFaceDirection, id: id)
            var snapshot = snapshotSetter.createSnapshot(finished: {})
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
                    if let frequency = snapshot.waveAveragePeriod {
                        wave.frequency = frequency
                    }
                    
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                }
                
                for favorite in self.favoriteSnapshots.keys {
                    if favorite.id == id {
                        self.favoriteSnapshots[favorite] = true
                    }
                }
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
                let favorite = Favorite.init(id: favorites[index], stationId: "", beachFaceDirection: 0.0, name: names[index])
                favoriteSnapshots[favorite] = false
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
            for favorite in self.favoriteSnapshots.keys {
                if favorite.id == Int(wave.id){
                    if abs(timestamp.timeIntervalSinceNow) < fiveMinutes{
                        self.favoriteSnapshots[favorite] = true
                        //make snapshot here
                        var snapshot = Snapshot.init()
                        snapshot.timeStamp = timestamp
                        snapshot.waveHgt = wave.waveHeight
                        snapshot.waveAveragePeriod = wave.frequency
                        snapshot.id = Int(wave.id)
                        snapshot.nickname = favorite.name
                        self.arrayOfSnapshots.append(snapshot)
                        //segue when all snapshots are available
                        self.segueWhenComplete()
                    }else{
                        //remove from persistent container
                        DispatchQueue.main.async {
                            self.context.delete(wave)
                        }
                    }
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
                
                for snapshot in favoriteSnapshots {
                    let id = snapshot.key.id
                    if let stationsFromJSON = jsonResult as? [[String : AnyObject]]{
                        for station in stationsFromJSON {
                            guard let idFromJSON = station["id"] as? Int else {return}
                            if idFromJSON == id {
                                guard let stationId = station["station"] as? Int else {return}
                                guard let beachFaceDirection = station["bfd"] as? Double else {return}
                                guard let name = station["name"] as? String else {return}
                                var favorite = snapshot.key
                                favorite.stationId = "\(stationId)"
                                favorite.beachFaceDirection = beachFaceDirection
                                favorite.name = name
                                self.getSnapshotWith(id: favorite.id, stationId: favorite.stationId, beachFaceDirection: favorite.beachFaceDirection)
                            }
                        }
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
