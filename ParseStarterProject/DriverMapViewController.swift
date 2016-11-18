//
//  DriverMapViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Xin Zou on 10/16/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit // with map, with MKMapViewDelegate ----v

class DriverMapViewController: UIViewController , MKMapViewDelegate{

    // this data comes from DriverViewController(): segue{}
    var requestLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    // and we use it in func viewDidLoad()
    var riderName = ""
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var acceptOrCancleButton: UIButton!
    @IBAction func acceptOrCancleBtnTapped(_ sender: UIButton) {
        let queue = PFQuery(className: "RiderRequest") // find RiderRequest class.
        queue.whereKey("username", equalTo: riderName)
        queue.findObjectsInBackground(block: { (objects, err) in
            if let riderRequests = objects {
                for request in riderRequests { //find request objects:
                    request["driverResponded"] = PFUser.current()?.username
                    request.saveInBackground() // set driverAccept status.
                    
                    // navigate to request location:
                    let requestLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
                    // calculate for path:
                    CLGeocoder().reverseGeocodeLocation(requestLocation, completionHandler: {(data, err) in
                        if let placemarks = data, placemarks.count > 0 { // usually 1st one mark:
                            let mkPlacemark = MKPlacemark(placemark: placemarks[0])
                            
                            let mapItem = MKMapItem(placemark: mkPlacemark)
                            mapItem.name = self.riderName
                            // then navigation the location by car: 
                            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                            mapItem.openInMaps(launchOptions: launchOptions)
                        }

                    })
                } // end of for.. find request objects.
            }
        }) // end of queue.findObjectsInBackground().
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: requestLocation, span: span)
        
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = requestLocation
        annotation.title = riderName

        mapView.addAnnotation(annotation)
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
