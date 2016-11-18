//
//  RiderViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Xin Zou on 9/18/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    
    func alertPopOneReply(title: String, msg: String, reply: String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: reply, style: UIAlertActionStyle.default, handler: {(action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    

    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    var riderRequestActive = false
    var driverOnTheWay = false
    
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var callAnUberButton: UIButton!
    @IBAction func callAnUberButtonTapped(_ sender: AnyObject) {
        //--- button animate --------------------------
        let thisButton = sender as! UIButton
        let bounce = thisButton.bounds
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 10, options: .curveEaseInOut, animations: {
                thisButton.bounds = CGRect(x: bounce.origin.x - 20, y: bounce.origin.y, width: bounce.size.width + 60, height: bounce.size.height - 10)
        }) { (success: Bool) in
            if success {
                UIView.animate(withDuration: 0.5, animations: {
                    thisButton.bounds = bounce
                })
            }
        }
        //--- button animate --------------------------
        
        if riderRequestActive {
            callAnUberButton.setTitleColor(UIColor.white, for: [])
            callAnUberButton.setTitle("Call An UBER", for: [])
            riderRequestActive = false
            
            let queue = PFQuery(className: "RiderRequest")
            queue.whereKey("username", equalTo: ( PFUser.current()?.username)! )
            queue.findObjectsInBackground(block: { (arrayObjects, error) in
                if let getObjects = arrayObjects {
                    
                    for riderRequest in getObjects {    // already be PFObject.
                        riderRequest.deleteInBackground() // remove it from server.
                    }
                    
                }
            })
            
        }else{ // send request to server:
            
            riderRequestActive = true
            self.callAnUberButton.setTitleColor(UIColor.red, for: [])
            self.callAnUberButton.setTitle("Cancle My Request", for: [])

            if userLocation.latitude == 0 || userLocation.longitude == 0 {
                callAnUberButton.setTitleColor(UIColor.white, for: [])
                callAnUberButton.setTitle("Call An UBER", for: [])
                riderRequestActive = false
                self.alertPopOneReply(title: "Need GPS", msg: "We need your GPS on for calling UBER. Please turn on your location servers.", reply: "OK, I see.")
                return
            }
            // else set up request object and connect to parse:
            
            let riderRequest = PFObject(className: "RiderRequest")
            riderRequest["username"] = PFUser.current()?.username
            riderRequest["location"] = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
            riderRequest.saveInBackground(block: { (success, error) in
                if success {
                    self.callAnUberButton.setTitleColor(UIColor.red, for: [])
                    self.callAnUberButton.setTitle("Cancle My Request", for: [])
                    self.riderRequestActive = true
                }else{
                    self.callAnUberButton.setTitleColor(UIColor.white, for: [])
                    self.callAnUberButton.setTitle("Call An UBER", for: [])
                    self.riderRequestActive = false
                    self.alertPopOneReply(title: "We are so Sory!", msg: "Unable to call UBER: \(error)", reply: "Try Again Later")
                }
            })
            
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logoutSegue" {
            locationManager.stopUpdatingLocation() // if not stop, app will crash.
            PFUser.logOut()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        callAnUberButton.isHidden = true
        
        // check in database if already has a request, and allow user to cancle it:
        let queue = PFQuery(className: "RiderRequest")
        queue.whereKey("username", equalTo: (  PFUser.current()?.username)!  )
        queue.findObjectsInBackground(block: { (objects, error) in
            
            if let objects = objects , (objects.count) > 0 {
                self.callAnUberButton.setTitleColor(UIColor.red, for: [])
                self.callAnUberButton.setTitle("Cancle My Request", for: [])
                self.riderRequestActive = true
            }else{
                self.callAnUberButton.setTitleColor(UIColor.white, for: [])
                self.callAnUberButton.setTitle("Call An UBER", for: [])
                self.riderRequestActive = false
            }
            
            self.callAnUberButton.isHidden = false
        })
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
        if let location = manager.location?.coordinate {
        
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
         
            if driverOnTheWay == false { // then updata rider map:
                let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                self.map.setRegion(region, animated: true)
            
                for oldAnnotation in self.map.annotations {
                    if let oldAnnotation = oldAnnotation as MKAnnotation? {
                        self.map.removeAnnotation(oldAnnotation)
                    }
                }
                let annotation = MKPointAnnotation()
                annotation.coordinate = userLocation
                annotation.title = "My location"
                self.map.addAnnotation(annotation)
            }
            
            // update(/s) the user location in server for driver:
            let queue = PFQuery(className: "RiderRequest") // here MUST unwarp!, or it crashes.
            queue.whereKey("username", equalTo: (  PFUser.current()?.username)!  )
            queue.findObjectsInBackground(block: { (objects, error) in
                if let getObjs = objects {
                    for request in getObjs {
                        request["location"] = PFGeoPoint(latitude:self.userLocation.latitude, longitude: self.userLocation.longitude)
                        request.saveInBackground()
                    }
                }
            })
        }
        // then, if request already responsed by driver, get info and show to user:
        if riderRequestActive {
            let queue = PFQuery(className: "RiderRequest")
            queue.whereKey("username", equalTo: ( PFUser.current()?.username)! ) // must unwarp!!!
            queue.findObjectsInBackground(block: { (objs, err) in
                if let riderRequests = objs {
                    
                    for request in riderRequests {
                        if let driverName = request["driverResponded"] { // find the driver.
                            
                            let queue = PFQuery(className: "DriverLocation")
                            queue.whereKey("username", equalTo: driverName)
                            queue.findObjectsInBackground(block: { (objs, err) in
                                if let locationObjs = objs {
                    
                                    for locationObj in locationObjs {
                                        if let driverLocation = locationObj["location"] as? PFGeoPoint {
                                            
                                            self.driverOnTheWay = true
                                            
                                            // tell rider how far driver on his way: 
                                            let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            let riderCLLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                            let disdence = riderCLLocation.distance(from: driverCLLocation) / 1000
                                            let getkm = round(disdence * 100) / 100
                                            
                                            // and change button to show this info:
                                            self.callAnUberButton.setTitle("\(driverName) is \(getkm)km away", for: [])
                                            
                                            // and show that driver on the map: 
                                            let latDelta = abs(driverLocation.latitude - self.userLocation.latitude) * 2 + 0.005
                                            let lonDelta = abs(driverLocation.longitude - self.userLocation.longitude) * 2 + 0.005
                                            let mkSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
                                            let region = MKCoordinateRegion(center: self.userLocation, span: mkSpan)
                                            self.map.setRegion(region, animated: true)
                                            
                                            // and add both annotation on the map;
                                            self.map.removeAnnotations(self.map.annotations) // remove them 1st.
                                            let userAnnotation = MKPointAnnotation()
                                            userAnnotation.coordinate = self.userLocation
                                            userAnnotation.title = "My location"
                                            self.map.addAnnotation(userAnnotation)
                                            
                                            let driverAnnotation = MKPointAnnotation()
                                            driverAnnotation.coordinate = CLLocationCoordinate2D(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            driverAnnotation.title = "Driver"
                                            self.map.addAnnotation(driverAnnotation)
                                        }
                                    }
                                    // end of for location.
                                }
                            })
                        }
                    }
                    // end of for request.
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
