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
       
        removePin(title: "Distance")  // removes all the distance annotations
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
                let route = directionResponse.routes[0] // creates the route
                self.mapKit.addOverlay(route.polyline, level: .aboveRoads) // draws the polyline
    
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
    
    //MARK: - Location manager class functions
    
    // gets the current location and creates the annotation for it, as well as centers the map into the region closer to the location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0] // gets the location of the user
        let latitude = userLocation.coordinate.latitude // user latitude
        let longitude = userLocation.coordinate.longitude // user longitude
        let latDelta: CLLocationDegrees = 0.2 // latitude delta
        let lngDelta: CLLocationDegrees = 0.2 // longitude delta
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta) // sets the span for the coordinates
        currentLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude) // sets the current location into the global variable
        mapKit.setRegion(MKCoordinateRegion(center: currentLocation!, span: span), animated: true) // sets the region for the map
        addAnnotation(coordinate: currentLocation!, title: "Current Location", subtitle: "" ) // sets the annotation
    }
    //MARK: - Aux Functions
    
    // gets the location of the pin and sets the logic for the annotations and overlays
    func getLocation(coordinate: CLLocationCoordinate2D){
        let newLocation: CLLocation =  CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude) // creates the location as CLLocation
        let distanceKM = Double( newLocation.distance(from: CLLocation(latitude: currentLocation!.latitude, longitude: currentLocation!.longitude)) ) / 1000.0  // get distance to current location
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
                        let closerLocation = self.checkPointCloserToAnother(newCoordinate: coordinate) // gets the index of a pinned point if the new point is 2Km or closer
                        if closerLocation > -1 { // validates if the placemark coordinates are closer to an existing pinned point coordinates
                            self.removePin(title: "Distance")  // removes all the distance annotations
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
                            self.removePin(title: "Distance")  // removes all the distance annotations
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
                                self.mapKit.addOverlay(self.locationsPolygon!) // adds the overlay to the map
                                self.navigationBtn.isHidden = false // shows the navigation button
                                self.setDistances() // sets the distances between all the points
                            }
                        }
                   }
                }
            }
        }
    }
    
    // creates an annotation depending on the coordinates
    func addAnnotation(coordinate: CLLocationCoordinate2D, title: String, subtitle: String ){
        let annotation = MKPointAnnotation() // creates the point annotation object
        annotation.title = title // sets the annotation title
        annotation.subtitle = subtitle // sets the annotation subtitle
        annotation.coordinate = coordinate // sets the annotation coordinate
        mapKit.addAnnotation(annotation) // adds the annotation to the map
    }
    // gets the index of the points array by searching the letter/label
    func getIndexByLetter(letterSearch: String) -> Int{
        for (index, point) in points.enumerated() { // iterates all the points
            if point.letter == letterSearch { // validates if the point letter is the one searched
                return index // returns the index found
            }
        }
        return -1 // letter not found
    }
    
    // removes the desired annotation by its title/letter
    func removePin(title:String) {
        for annotation in mapKit.annotations { // iterates all pins
            if annotation.title == title { // validates if the annotation title is the selected one
                mapKit.removeAnnotation(annotation) // remove the annotation from the map
            }
        }
    }
    // sets the distances between all the points
    func setDistances(){
        for (index, point) in points.enumerated(){ // iterates all the points
            let pointLocation: CLLocation =  CLLocation(latitude: point.coordinates.latitude, longitude: point.coordinates.longitude) // gets the current point CLLocation Object with the coordinates
            var nextPointIndex:Int = index + 1 // get the next point
            if nextPointIndex == points.count{ //validates if it is the last point
                nextPointIndex = 0 // gets the first point
            }
            let destinationPlaceMark = CLLocation(latitude: points[nextPointIndex].coordinates.latitude, longitude: points[nextPointIndex].coordinates.longitude) // gets the next point CLLocation Object with the coordinates
            
            point.distanceToNextPoint = pointLocation.distance(from: destinationPlaceMark)/1000.0 // sets the distance in km
            
            
            // Todo:
            let coordy = CLLocationCoordinate2D(latitude:  (point.coordinates.latitude + points[nextPointIndex].coordinates.latitude)/2, longitude: CLLocationDegrees(point.coordinates.longitude + points[nextPointIndex].coordinates.longitude)/2)
            
            addAnnotation(coordinate: coordy, title: "Distance", subtitle: point.letter + " to " + points[nextPointIndex].letter + " " + String(format: "%.2f", point.distanceToNextPoint) + " km")
        }
    }
    // gets the index of the closest point if it is located within 2km
    func checkPointCloserToAnother(newCoordinate:CLLocationCoordinate2D) -> Int {
        var iCloser = -1 // index definition
        var minimumDistance = 2.0 // minimum distance definition
        let newPoint : CLLocation =  CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude) // gets the new point CLLocation Object with the coordinates
        for (index , point) in points.enumerated(){ // iterates all the coordinates
            let pointLocation: CLLocation =  CLLocation(latitude: point.coordinates.latitude, longitude: point.coordinates.longitude) // gets the point CLLocation Object with the coordinates
            let distance = newPoint.distance(from: pointLocation) / 1000.0 // gets the distance in km
            if( distance <= minimumDistance){ // if the current distance is within the minimum distance
                iCloser = index // gets the index of the point
                minimumDistance = distance // sets the new minimum distance
            }
        }
        return iCloser // returns the closest index
    }
}

//MARK: - MKMap Extension Class
extension ViewController: MKMapViewDelegate {
    // ViewFor annotation method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation { // if the annotation is the user location
            return nil // return nothing
        }
        
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin" + annotation.title!!) // create the annotation view
        annotationView.animatesDrop = true // set true annotation animation
        annotationView.canShowCallout = true // set true can show callout
        annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) // set callout button
        // switch annotation title
        switch annotation.title {
            case "A":
                annotationView.pinTintColor = UIColor.systemPink // set the pin tint color as pink
                return annotationView // return annotation view
            case "B":
                annotationView.pinTintColor = UIColor.orange  // set the pin tint color as orange
                return annotationView // return annotation view
            case "C":
                annotationView.pinTintColor = UIColor.cyan  // set the pin tint color as cyan
                return annotationView // return annotation view
        case "Distance":
            let annotationViewCustom = mapKit.dequeueReusableAnnotationView(withIdentifier: "customPin") ?? MKPinAnnotationView() // create a custom annotation
            annotationViewCustom.frame = CGRect(x: 0, y: 0, width: 100, height: 20) // define the frame
            annotationViewCustom.canShowCallout = false // set false can show callout
            let img = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: 20)) //creates an image view with a frame
            img.backgroundColor = UIColor.lightGray // sets the background color
             let name  = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 20)) // creates a label
            name.text = annotation.subtitle as? String // sets the
            name.font = name.font.withSize(10.0) // sets font size
            annotationViewCustom.addSubview(img) // add the image to the annotationview
            annotationViewCustom.addSubview(name) // add the label to the annotationview
                return annotationViewCustom // return annotation view
            default:
                return nil // returns nothing
        }
    }
    
    // Callout accessory control tapped
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let index = getIndexByLetter(letterSearch: view.annotation!.title! ?? "") // get the index in the points array depending on the annotation title
        if index > -1 { // if the point was found
            // create the alert
            let alertController = UIAlertController(title: "Distance to current location" , message: String(format: "%2.f", points[index].distanceToLocation) + " km", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil) // create the dismiss button
            alertController.addAction(cancelAction) // add the button to the alert
            present(alertController, animated: true, completion: nil) //show the alert
        }

    }
    // Rendrer for overlay func
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline { // if the overlay is a polyline
            let renderer = MKPolylineRenderer(overlay: overlay) // get the polyline renderer
            renderer.strokeColor = UIColor.purple // set the stroke color as purple
            renderer.lineWidth = 1 // set the line width as 1
            return renderer // return renderer
        } else if overlay is MKPolygon { // if the overlay is a polygon
            let renderer = MKPolygonRenderer(overlay: overlay)  // get the polygon renderer
            renderer.fillColor = UIColor.red.withAlphaComponent(0.5) // set the fill color as red with a transparency of 50%
            renderer.strokeColor = UIColor.green // set the stroke color as green
            renderer.lineWidth = 2 // set the line width as 1
            return renderer // return renderer
        }
        return MKOverlayRenderer() // return default
    }
    
}
