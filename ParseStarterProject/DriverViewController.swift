//
//  DriverViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Xin Zou on 10/16/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse

class DriverViewController: UITableViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    var requestUserNames = [String]() // for saving current riders location.
    var requestLocations = [CLLocationCoordinate2D]()
    var userDriverLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0) // cache for table cells
    
    
    func alertPopOneReply(title: String, msg: String, reply: String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: reply, style: UIAlertActionStyle.default, handler: {(action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // for view jump:
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "driverLogOutSegue" { // back to login page
            locationManager.stopUpdatingLocation()
            self.navigationController?.navigationBar.isHidden = true
            PFUser.logOut()
        }
        if segue.identifier == "showRiderMapSegue" { // go to map page
            if let destination = segue.destination as? DriverMapViewController {
                // send this.tableview row num to NEXT page:
                if let fromRow = (tableView.indexPathForSelectedRow?.row), fromRow < requestLocations.count{
                    // set the parameter in other class: 
                    destination.requestLocation = requestLocations[fromRow]
                    destination.riderName = requestUserNames[fromRow]
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation() // go to following func:
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        requestUserNames.removeAll() // cleare all old data before getting new in
        requestLocations.removeAll() // is CLLocationCoordinate2D inside, not PFGeoPoint.
        
        if let location = manager.location?.coordinate {
            userDriverLocation = location
            
            // one class in Parse can have only one PFGeoPoint(), so make a new class:
            let driverLocationQueue = PFQuery(className: "DriverLocation")
            driverLocationQueue.whereKey("username", equalTo: (PFUser.current()?.username)!)
            driverLocationQueue.findObjectsInBackground(block: { (objs, err) in
                
                if let driverLocations = objs {
                    for driverlocation in driverLocations {
                        driverlocation["location"] = PFGeoPoint(latitude: self.userDriverLocation.latitude, longitude: self.userDriverLocation.longitude)
                        driverlocation.deleteInBackground() // delete the old location, and
                    }
                }
                // make a new one to replace it.
                let driverLocation = PFObject(className: "DriverLocation")
                driverLocation["username"] = (PFUser.current()?.username)!
                driverLocation["location"] = PFGeoPoint(latitude: self.userDriverLocation.latitude, longitude: self.userDriverLocation.longitude)
                driverLocation.saveInBackground()
                
            })
            
            // get driver location, then search for users location:
            let queue = PFQuery(className: "RiderRequest")
            queue.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: location.latitude, longitude: location.longitude))
            queue.limit = 10
            queue.findObjectsInBackground(block: {(obj, err) in
                if let riderRequests = obj {
                    for request in riderRequests { // get request objects{}
                        
                        if request["driverResponded"] == nil {
                            if let getUsername = request["username"] as? String {
                                self.requestUserNames.append(getUsername)
                            }
                            if let getLoc = request["location"] as? PFGeoPoint {
                                self.requestLocations.append(CLLocationCoordinate2D(latitude: getLoc.latitude, longitude: getLoc.longitude))
                            }
                        }
                    }
                    self.tableView.reloadData()
                }
                else {
                    print("Error in loading riders table: \(err)")
                }
            })
        }else{
            alertPopOneReply(title: "Missing GPS", msg: "Can not update your location, please try turn on or reboot your GPS.", reply: "OK")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestUserNames.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "waiting request..."
        
        var distance : Double = 0.01
        let driverLocation = PFGeoPoint(latitude: userDriverLocation.latitude, longitude: userDriverLocation.longitude)
        if indexPath.row < requestLocations.count {
            let riderLocation = PFGeoPoint(latitude: requestLocations[indexPath.row].latitude, longitude: requestLocations[indexPath.row].longitude)
            distance = round(driverLocation.distanceInKilometers(to: riderLocation) * 100) / 100
            cell.textLabel?.text = requestUserNames[indexPath.row] + "     \(distance) km"
        }

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
