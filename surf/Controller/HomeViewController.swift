//
//  HomeViewController.swift
//  surf
//
//  Created by uBack on 6/6/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var proximalCollectionView: UICollectionView!
    var proximalData = [Station]()
    var proximalSelectedIndex = Int()
    var selectedSnapshot = Snapshot()

    private let imageArray = [#imageLiteral(resourceName: "crash.png"), #imageLiteral(resourceName: "wave.png"), #imageLiteral(resourceName: "flat.png"), #imageLiteral(resourceName: "wave.png"), #imageLiteral(resourceName: "flat.png")]
    override func viewDidLoad() {
        super.viewDidLoad()
        parseStationList()
    }
    
    
    func parseStationList(){
        if let path = Bundle.main.path(forResource: "regionalBuoyList", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let metaData = jsonResult as? [[String : AnyObject]]{
                    for station in metaData {
                        guard let stationId = station["station"] else {return}
                        guard let lon = station["longitude"] as? Double else {return}
                        guard let lat = station["latitude"] as? Double else {return}
                        addStationWithIdLatLon(id: "\(stationId)", lat: lat, lon: lon, name: station["name"] as? String ?? "" )
                    }
                }
            } catch {
                // handle error
            }
        }
    }
    
    func addStationWithIdLatLon(id :String, lat : Double, lon : Double, name: String){
        let station : Station = Station(id: id, lat: lat, lon: lon, owner: nil, name: name, distance: 10000.0, distanceInMiles: 10000)
        proximalData.append(station)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedStation = proximalData[proximalSelectedIndex]
        
        if let destinationVC = segue.destination as? ViewController {
            destinationVC.stationId = selectedStation.id
            destinationVC.currentSnapShot = selectedSnapshot
            if destinationVC.currentSnapShot != nil {
                destinationVC.snapshotComponents = ["wave" : true, "tide" : false, "wind" : false, "air" : false]
            }
        }
    }
    
    
}


extension HomeViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        proximalSelectedIndex = indexPath.row
        let selectedId = proximalData[proximalSelectedIndex].id
        
//        startActivityIndicator("Loading")
        
        DispatchQueue.main.async{
            let data = createSnapshot(stationId: selectedId, finished: {})
            //remove spinner for response:
            if data.waveHgt != nil && data.waterTemp != nil {
//                self.stopActivityIndicator()
                self.selectedSnapshot = data
                self.selectedSnapshot.stationName = self.proximalData[indexPath.row].name
                self.performSegue(withIdentifier: "showStationDetail", sender: self)
            }else{
                //if no data respond with alertview
//                self.stopActivityIndicator()
                let alert = UIAlertController.init(title: "Not enough Data", message: "This bouy is not providing much data at the moment", preferredStyle: .alert)
                let doneAction = UIAlertAction(title: "Cancel", style: .destructive)
                alert.addAction(doneAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = proximalCollectionView.dequeueReusableCell(withReuseIdentifier: "ProximalCollectionViewCell", for: indexPath) as! ProxCollectionViewCell
        cell.imageView.image = imageArray[indexPath.row]
        cell.titleLabel.textColor = .black
        cell.titleLabel.text = self.proximalData[indexPath.row].name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 140)
    }
    

}
