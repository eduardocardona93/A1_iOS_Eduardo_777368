//
//  ViewController.swift
//  A1_iOS_Eduardo_777368.git
//
//  Created by MacStudent on 2021-05-15.
//  Copyright © 2021 MacStudent. All rights reserved.
//

import UIKit
import MapKit
class ViewController: UIViewController, CLLocationManagerDelegate {
    // define location manager
    var locationManager = CLLocationManager()
    
    var locationsCount = 0
    var locationsLabels = ["A","B","C"]
    
    @IBOutlet weak var mapKit: MKMapView!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        mapKit.showsUserLocation = true // show user location
        mapKit.isZoomEnabled = false// disable zoom
        
        // ------------ location manager init -----------
        locationManager.delegate = self // assign location manager delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // define location manager accuracy
        locationManager.requestWhenInUseAuthorization() // define request authorization
        locationManager.startUpdatingLocation() // start updating the location
        
        // ------------ Triple tap gesture recognizer definition -----------
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin)) // Gesture recognizer definition
        doubleTap.numberOfTapsRequired = 2 // taps required definition
        mapKit.addGestureRecognizer(doubleTap) // add the gesture recognizer to the map
        // ------------ Long press gesture recognizer definition -----------
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(addLongPressAnnotattion))
        mapKit.addGestureRecognizer(uilpgr)
    }
    //MARK: - long press gesture recognizer for the annotation
    @objc func addLongPressAnnotattion(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapKit)
        let coordinate = mapKit.convert(touchPoint, toCoordinateFrom: mapKit)
        getLocation(coordinate: coordinate)
    }
    @objc func dropPin(sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: mapKit)
        let coordinate = mapKit.convert(touchPoint, toCoordinateFrom: mapKit)
        
        getLocation(coordinate: coordinate)
        
    }
    
    func getLocation(coordinate: CLLocationCoordinate2D){
        let location: CLLocation =  CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            if error != nil {
                print(error!)
            } else {
                if let placemark = placemarks?[0] {
                    if placemark.country != "Canada"{
                        let alert = UIAlertController(title: "Error", message: "This point is not in located Canada, please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    } else if placemark.administrativeArea != "ON" {
                        let alert = UIAlertController(title: "Error", message: "This point is not located in Ontario, please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        if self.locationsCount >= 3  {
                            
                        }else{
                            self.addAnnotation(coordinate: coordinate, title: self.locationsLabels[self.locationsCount], subtitle: "Point " + self.locationsLabels[self.locationsCount])
                            self.locationsCount += 1
                        }
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        displayLocation(latitude: latitude, longitude: longitude, title: "my location", subtitle: "you are here")
    }
    
    
    func displayLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, subtitle: String) {
        let latDelta: CLLocationDegrees = 1
        let lngDelta: CLLocationDegrees = 1
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapKit.setRegion(region, animated: true)
        
        addAnnotation(coordinate: location, title: title, subtitle: subtitle )
    }
    
    func addAnnotation(coordinate: CLLocationCoordinate2D, title: String, subtitle: String ){
        let annotation = MKPointAnnotation()
        
        annotation.title = title
        annotation.subtitle = subtitle
        annotation.coordinate = coordinate
        mapKit.addAnnotation(annotation)
    }
    
}
//extension ViewController: MKMapViewDelegate{
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        if overlay is MKPolyline {
//            let rendrer = MKPolylineRenderer(overlay: overlay)
//            rendrer.strokeColor = UIColor.red
//            rendrer.lineWidth = 1
//            return rendrer
//        } else if overlay is MKPolygon {
//            let rendrer = MKPolygonRenderer(overlay: overlay)
//            rendrer.fillColor = UIColor.red.withAlphaComponent(0.5)
//            rendrer.strokeColor = UIColor.greeen
//            rendrer.lineWidth = 2
//            return rendrer
//        }
//        return MKOverlayRenderer()
//    }
//}
