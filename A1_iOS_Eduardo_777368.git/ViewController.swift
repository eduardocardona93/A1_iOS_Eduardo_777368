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
    //MARK: - Global variables
    
    
    var locationManager = CLLocationManager() // define location manager
    var currentLocation: CLLocationCoordinate2D? = nil // set current location variable
    var locationsLabels = ["A","B","C"] // points label array
    var locationsPolygon:MKPolygon? = nil // locations polygon variable
    var points:[LocationPoint] = [] // pinned points array
    
    //MARK: - Outlet variables
    @IBOutlet weak var navigationBtn: UIButton!  // navigation button
    @IBOutlet weak var mapKit: MKMapView! // map
    
    //MARK: - View loaded event handler
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationBtn.isHidden = true // hide navigation button
        mapKit.showsUserLocation = true // show user location
        mapKit.isZoomEnabled = false// disable zoom
        
        // ------------ location manager init -----------
        locationManager.delegate = self // assign location manager delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // define location manager accuracy
        locationManager.requestWhenInUseAuthorization() // define request authorization
        locationManager.startUpdatingLocation() // start updating the location
        
        // ------------ Double tap gesture recognizer definition -----------
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin)) // Gesture recognizer definition
        doubleTap.numberOfTapsRequired = 2 // taps required definition
        mapKit.addGestureRecognizer(doubleTap) // add the gesture recognizer to the map
      
        mapKit.delegate = self // this class handles the delegate mapkit
    }
    //MARK: - Elements Event handler Functions
    
    // Navigation button press handler
    @IBAction func drawRoute(_ sender: Any) {
        mapKit.removeOverlays(mapKit.overlays) // removes all the overlays
        locationsPolygon = nil // resets the polygon
        // iterates all the annotations
        for ann in mapKit.annotations{
            if ann.title == "Distance"{ // validates if it is a distance annotation
                mapKit.removeAnnotation(ann) // removes the distance annotation
            }
        }

        for (index, point) in points.enumerated(){ // iterates all the pinned points
            let sourcePlaceMark = MKPlacemark(coordinate: point.coordinates) // gets the origin placemark with the point coordinates
            var nextPointIndex:Int = index + 1 // gets the next pinned point
            if nextPointIndex  == points.count{ //validates if it is the last point
                nextPointIndex = 0 // gets the first point
            }
            let destinationPlaceMark = MKPlacemark(coordinate: points[nextPointIndex].coordinates) // gets the destination placemark with the point coordinates
            let directionRequest = MKDirections.Request() // request a direction
            
            // assign the source and destination properties of the request
            directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
            directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
            
            // transportation type automobile
            directionRequest.transportType = .automobile
            
            // calculate the direction
            let directions = MKDirections(request: directionRequest)
            directions.calculate { (response, error) in
                guard let directionResponse = response else {return}
                // creates the route
                let route = directionResponse.routes[0]
                // draws the polyline
                self.mapKit.addOverlay(route.polyline, level: .aboveRoads)
    
            }
        }
    }
    //MARK: - Obj C Functions
    
    // handler for the double tap gesture event
    @objc func dropPin(sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: mapKit) // gets the point touched in the map
        let coordinate = mapKit.convert(touchPoint, toCoordinateFrom: mapKit) // gets the coordinates
        
        getLocation(coordinate: coordinate)
        
    }
    //MARK: - Aux Functions


    func getLocation(coordinate: CLLocationCoordinate2D){
        // creates the location as CLLocation
        let newLocation: CLLocation =  CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        // get distance to current location
        let distanceKM = Double( newLocation.distance(from: CLLocation(latitude: currentLocation!.latitude, longitude: currentLocation!.longitude)) ) / 1000.0
        // gets the location placemark from the CLLocation variable and handles the result
        CLGeocoder().reverseGeocodeLocation(newLocation) { (placemarks, error) in
            if error != nil { // if there was an error
                print("error reverseGeocodeLocation" , error!) // print the error
            } else {
                if let placemark = placemarks?[0] { // validates and gets the first placemark
                    if placemark.country != "Canada"{ //validates if the placemark country is Canada
                        // shows an alert
                        let alert = UIAlertController(title: "Error", message: "This point is not in located Canada, please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    } else if placemark.administrativeArea != "ON" { //validates if the placemark administrative area is Ontario
                        // shows an alert
                        let alert = UIAlertController(title: "Error", message: "This point is not located in Ontario, please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                   } else if placemark.locality == nil || placemark.locality == "" { //validates if the placemark the point is in a locality
                        // shows an alert
                        let alert = UIAlertController(title: "Error", message: "This point is not available to select, please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                   }else{
                        let closerLocation = self.checkPointCloserToAnother(newCoordinate: coordinate) // gets the index of a pinned point if the new point is 3Km or closer
                        if closerLocation > -1 { // validates if the placemark coordinates are closer to an existing pinned point coordinates
                            
                            self.removePin(title: self.points[closerLocation].letter) // removes the pin from the map
                            self.points.remove(at: closerLocation) // removes the pinned point from the global array
                            self.mapKit.removeOverlays(self.mapKit.overlays) // remove overlays
                            self.locationsPolygon = nil // empties the polygon
                            self.navigationBtn.isHidden = true // hides the navigation button
                        }else{ // in any other valid case
                            self.navigationBtn.isHidden = true // hides the navigation button
                            if self.points.count == 3   { // checks if there are 3 pinned points
                                if (self.locationsPolygon != nil){ // checks if the locations polygon global variable is set
                                    let renderer = MKPolygonRenderer(overlay: self.locationsPolygon!) // gets the polygon renderer
                                    if renderer.path.contains(renderer.point(for:MKMapPoint(coordinate))) { // checks if the selected point is inside the polygon
                                        // shows an alert
                                        let alert = UIAlertController(title: "Error", message: "This point is inside the polygon, please try again", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                                        self.present(alert, animated: true, completion: nil)
                                    }else{
                                        self.mapKit.removeAnnotations(self.mapKit.annotations) // remove all annotations
                                        self.mapKit.removeOverlays(self.mapKit.overlays) // removes all the overlays
                                        self.points.removeAll() // removes all the pinned points
                                        self.addAnnotation(coordinate: self.currentLocation!, title: "Current Location", subtitle: "" ) // sets the curren location annotation
                                    }
                                }else{
                                    self.mapKit.removeAnnotations(self.mapKit.annotations) // remove all annotations
                                    self.mapKit.removeOverlays(self.mapKit.overlays) // removes all the overlays
                                    self.points.removeAll() // removes all the pinned points
                                    self.addAnnotation(coordinate: self.currentLocation!, title: "Current Location", subtitle: "" ) // sets the curren location annotation
                                }
                                
                                
                                
                            }
                            for point in self.locationsLabels{ // iterate the points labels array
                                let index = self.getIndexByLetter(letterSearch: point) // gets the index if the point is already set
                                if index == -1 { // if not set
                                    let newPoint = LocationPoint(cityName: placemark.locality ?? "", coordinates: coordinate, distanceToLocation: distanceKM, letter: point) // creates a new point
                                    self.points.append(newPoint) // append the new point to the existing ones
                                    self.addAnnotation(coordinate: coordinate, title: point, subtitle: "" )
                                    break // breaks the loop
                                }
                            }
                            if(self.points.count == 3){ // checks if there are 3 pinned points after all the process
                                let coordinates = self.points.map {$0.coordinates} // gets all points coordinates
                                self.locationsPolygon = MKPolygon(coordinates: coordinates, count: coordinates.count) // creates the polygon and sets it to the global variable
                                self.mapKit.addOverlay(self.locationsPolygon!)
                                self.navigationBtn.isHidden = false
                                self.setDistances()
                            }
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
        
        let latDelta: CLLocationDegrees = 0.2
        let lngDelta: CLLocationDegrees = 0.2
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        currentLocation = location
        
        let region = MKCoordinateRegion(center: location, span: span)
        //
        mapKit.setRegion(region, animated: true)
        
        addAnnotation(coordinate: location, title: "Current Location", subtitle: "" )
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
    
    
    func removePin(title:String) {
        for annotation in mapKit.annotations {
            if annotation.title == title {
                mapKit.removeAnnotation(annotation)
            }
        }
    }
    
    func setDistances(){
        for (index, point) in points.enumerated(){
            let pointLocation: CLLocation =  CLLocation(latitude: point.coordinates.latitude, longitude: point.coordinates.longitude)
            
            
            var nextPointIndex:Int = index + 1
            if nextPointIndex == points.count{
                nextPointIndex = 0
            }
            let destinationPlaceMark = CLLocation(latitude: points[nextPointIndex].coordinates.latitude, longitude: points[nextPointIndex].coordinates.longitude)
            
            point.distanceToNextPoint = pointLocation.distance(from: destinationPlaceMark)/1000.0
            let coordy = CLLocationCoordinate2D(latitude:  (point.coordinates.latitude + points[nextPointIndex].coordinates.latitude)/2, longitude: CLLocationDegrees(point.coordinates.longitude + points[nextPointIndex].coordinates.longitude)/2)
    
            addAnnotation(coordinate: coordy, title: "Distance", subtitle: point.letter + " to " + points[nextPointIndex].letter + " " + String(format: "%.2f", point.distanceToNextPoint) + " km")
            print(point.distanceToNextPoint)
        }
    }
    
    func checkPointCloserToAnother(newCoordinate:CLLocationCoordinate2D) -> Int {
        var iCloser = -1
        let newPoint : CLLocation =  CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
        for (index , point) in points.enumerated(){
            let pointLocation: CLLocation =  CLLocation(latitude: point.coordinates.latitude, longitude: point.coordinates.longitude)
            let distance = newPoint.distance(from: pointLocation)/1000.0

            if( distance <= 2.0){
                iCloser = index
            }
        }
        return iCloser
    }
}

//MARK: - MKMap Extension Class
extension ViewController: MKMapViewDelegate{
    // ViewFor annotation method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin" + annotation.title!!)
        annotationView.animatesDrop = true
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
        switch annotation.title {
            case "A":
                annotationView.pinTintColor = UIColor.systemPink
                return annotationView
            case "B":
                annotationView.pinTintColor = UIColor.orange
                return annotationView
            case "C":
                annotationView.pinTintColor = UIColor.cyan
                return annotationView
//        case "Distance":
//                let annotationViewCustom =  MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin" + annotation.title!!)
//            annotationView.animatesDrop = true
//            annotationView.canShowCallout = true
//            annotationView.addSubview(T##view: UIView##UIView)
//                return annotationViewCustom
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
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.purple
            renderer.lineWidth = 1

            return renderer
        } else if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(overlay: overlay)
            renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.green
            renderer.lineWidth = 2
            return renderer
        }
        // return default
        return MKOverlayRenderer()
    }
    
}
