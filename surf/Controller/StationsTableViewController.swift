//
//  StationsTableViewController.swift
//  surf
//
//  Created by Allen Spicer on 5/14/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

class StationsTableViewController: UITableViewController{
    
    var tableData = [Station]()
    var selectedStationIndex = Int()
    var selectedSnapshot = Snapshot()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        parseStationList()
    }
    
    override func viewWillAppear(_ animated: Bool) {

        
//        let stationIdArray = [41110, 41038]
//        let stationNameArray = ["Masenboro Inlet", "Wrightsville Beach Nearshore"]
//        for index in 0...1 {
//            addStationWithId(id: stationIdArray[index], name: stationNameArray[index])
//        }
    }
    
    func addStationWithId(id :String){
        let station : Station = Station(id: id, lat: "", lon: "", owner: "", name: "")
        tableData.append(station)
    }
    
    // 41110 Masenboro Inlet ILM2
    // 41038 Wrightsville Beach Nearshore ILM2
    // JMPN7 Johnny Mercer Pier

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tableData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = "\(tableData[indexPath.row].id)"
        return cell
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedStationIndex = indexPath.row
        let selectedId = tableData[selectedStationIndex].id
        
        //display spinner here
        
        DispatchQueue.main.async{
            let data = bouyDataServiceRequest(stationId: selectedId, finished: {})
            
            //remove spinner for response:
            if data.waveHgt != nil {
                self.selectedSnapshot = data
                self.performSegue(withIdentifier: "showStationDetail", sender: self)
            }else{
                //if no data respond with alertview
                let alert = UIAlertController.init(title: "Not enough Data", message: "This bouy is not providing much data at the moment", preferredStyle: .alert)
                let doneAction = UIAlertAction(title: "Cancel", style: .destructive)
                alert.addAction(doneAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedStation = tableData[selectedStationIndex]
        
        if let destinationVC = segue.destination as? ViewController {
            destinationVC.stationId = selectedStation.id
            destinationVC.stationName = selectedStation.name
            destinationVC.currentSnapShot = selectedSnapshot
        }
    }
 
    // MARK: - Parse Data from JSON

//    Parsing for full data set: bouys.json
//    func parseStationList(){
//        if let path = Bundle.main.path(forResource: "staticStationList", ofType: "json") {
//            do {
//                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
//                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
//                if let metaData = jsonResult as? Dictionary<String, AnyObject>{
//                    if let stationDataArray = metaData["station"] as? [[String : String]]{
//                        for station in stationDataArray{
//                            if let stationId = station["-id"]{
//                                addStationWithId(id: stationId)
//                            }
//                        }
//                    }
//
//                }
//            } catch {
//                // handle error
//            }
//        }
//    }
    
    func parseStationList(){
        if let path = Bundle.main.path(forResource: "staticStationList", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let metaData = jsonResult as? [[String : AnyObject]]{
                    for station in metaData {
                        if let stationId = station["station"]{
                            addStationWithId(id: "\(stationId)")
                        }
                    }
                }
            } catch {
                // handle error
            }
        }
    }
    
}
