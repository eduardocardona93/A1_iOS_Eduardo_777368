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
    var currentLocation: CLLocationCoordinate2D? = nil
    var locationsCount = 0
    var locationsLabels = ["A","B","C"]
    var points:[LocationPoint] = []
    
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
        
        mapKit.delegate = self
    }
    
    
    //MARK: - Obj C Functions
    
    // Long press gesture recognizer for the annotation
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
    //MARK: - Aux Functions


    func getLocation(coordinate: CLLocationCoordinate2D){
        
        let newLocation: CLLocation =  CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        // get distance to current location
        let distanceKM = Double( newLocation.distance(from: CLLocation(latitude: currentLocation!.latitude, longitude: currentLocation!.longitude)) ) / 1000
        CLGeocoder().reverseGeocodeLocation(newLocation) { (placemarks, error) in
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
                   } else if placemark.subAdministrativeArea == nil || placemark.subAdministrativeArea == "" {
                    
                        let alert = UIAlertController(title: "Error", message: "This point is not available to select, please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                   }else if self.getIndexByCity(citySearch: placemark.subAdministrativeArea! ) > -1{
                        let alreadySelectedLocation = self.getIndexByCity(citySearch: placemark.subAdministrativeArea! )
                        self.removePin(title: self.points[alreadySelectedLocation].letter)
                        self.points[alreadySelectedLocation] = LocationPoint(cityName: placemark.subAdministrativeArea ?? "", coordinates: coordinate, distanceToLocation: distanceKM, letter: self.locationsLabels[alreadySelectedLocation])
                    self.addAnnotation(coordinate: coordinate, title: self.points[alreadySelectedLocation].letter, subtitle: "" )
                   }else{
                        if self.points.count >= 3  {
                            self.mapKit.removeAnnotations(self.mapKit.annotations)
                            self.points.removeAll()
                        }
                            
                        let newPoint = LocationPoint(cityName: placemark.subAdministrativeArea ?? "", coordinates: coordinate, distanceToLocation: distanceKM, letter: self.locationsLabels[self.points.count])
                        self.points.append(newPoint)
                        self.addAnnotation(coordinate: coordinate, title: newPoint.letter, subtitle: "" )
                            
                            
                        
                    }
                }
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        let latDelta: CLLocationDegrees = 1
        let lngDelta: CLLocationDegrees = 1
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        currentLocation = location
        
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapKit.setRegion(region, animated: true)
        
        addAnnotation(coordinate: location, title: "my location", subtitle: "you are here" )
    }
    
    

    
    func addAnnotation(coordinate: CLLocationCoordinate2D, title: String, subtitle: String ){
        let annotation = MKPointAnnotation()
        
        annotation.title = title
        annotation.subtitle = subtitle
        annotation.coordinate = coordinate
        mapKit.addAnnotation(annotation)
    }
    
    func getIndexByLetter(letterSearch: String) -> Int{
        for (index, point) in points.enumerated() {
            if point.letter == letterSearch {
                return index
            }
        }
        return -1
    }
    
    func getIndexByCity(citySearch: String) -> Int{
        for (index, point) in points.enumerated() {
            if point.cityName == citySearch {
                return index
            }
        }
        return -1
    }
    
    func removePin(title:String) {
        for annotation in mapKit.annotations {
            if annotation.title == title {
                mapKit.removeAnnotation(annotation)
            }
        }
    }
    
}

//MARK: - MKMap Extension Class
extension ViewController: MKMapViewDelegate{
    // ViewFor annotation method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        switch annotation.title {
            case "A":
                let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePinA")
                annotationView.animatesDrop = true
                annotationView.pinTintColor = UIColor.systemPink
                annotationView.canShowCallout = true
                annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)

                return annotationView
            case "B":
                let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePinB")
                annotationView.animatesDrop = true
                annotationView.pinTintColor = UIColor.orange
                annotationView.canShowCallout = true
                annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)

                return annotationView
            case "C":
                let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePinC")
                annotationView.animatesDrop = true
                annotationView.pinTintColor = UIColor.cyan
                annotationView.canShowCallout = true
                annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)

                return annotationView
            default:
                return nil
        }
    }
    // Callout accessory control tapped
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let index = getIndexByLetter(letterSearch: view.annotation!.title! ?? "")
        
        if index > -1 {
            let alertController = UIAlertController(title: "Distance to current location" , message: String(format: "%2.f", points[index].distanceToLocation) + " km", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }

    }
    // Rendrer for overlay func
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.red
            rendrer.lineWidth = 1
            return rendrer
        } else if overlay is MKPolygon {
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.5)
            rendrer.strokeColor = UIColor.green
            rendrer.lineWidth = 2
            return rendrer
        }
        return MKOverlayRenderer()
    }
}
