//
//  StationsTableViewController.swift
//  surf
//
//  Created by uBack on 5/14/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

class StationsTableViewController: UITableViewController{
    
    var tableData = [Station]()
    var selectedStationIndex = Int()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let stationIdArray = [41110, 41038]
        for id in stationIdArray {
            addStationWithId(id)
        }
    }
    
    func addStationWithId(_ id :Int){
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
        self.performSegue(withIdentifier: "showStationDetail", sender: self)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedStation = tableData[selectedStationIndex]
        let destinationVC : ViewController = ViewController()
        destinationVC.stationId = selectedStation.id

    }
 

}
