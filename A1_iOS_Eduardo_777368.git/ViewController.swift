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
    
    @IBOutlet weak var navigationBtn: UIButton!
    @IBOutlet weak var mapKit: MKMapView!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationBtn.isHidden = true
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
    //MARK: - Event handler Functions
    
    @IBAction func drawRoute(_ sender: Any) {
        mapKit.removeOverlays(mapKit.overlays)
        for (index, point) in points.enumerated(){
            
            
            let sourcePlaceMark = MKPlacemark(coordinate: point.coordinates)
            var nextPointIndex:Int = index + 1
            if nextPointIndex  == points.count{
                nextPointIndex = 0
            }
            let destinationPlaceMark = MKPlacemark(coordinate: points[nextPointIndex].coordinates)
            
            // request a direction
            let directionRequest = MKDirections.Request()
            
            // assign the source and destination properties of the request
            directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
            directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
            
            // transportation type
            directionRequest.transportType = .automobile
            
            // calculate the direction
            let directions = MKDirections(request: directionRequest)
            directions.calculate { (response, error) in
                guard let directionResponse = response else {return}
                // create the route
                let route = directionResponse.routes[0]
                // drawing a polyline
                self.mapKit.addOverlay(route.polyline, level: .aboveRoads)
    
            }
        }
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
        let distanceKM = Double( newLocation.distance(from: CLLocation(latitude: currentLocation!.latitude, longitude: currentLocation!.longitude)) ) / 1000.0
        CLGeocoder().reverseGeocodeLocation(newLocation) { (placemarks, error) in
            if error != nil {
                print(error!)
            } else {
                if let placemark = placemarks?[0] {
                    print(placemark.locality!)
                    if placemark.country != "Canada"{
                        let alert = UIAlertController(title: "Error", message: "This point is not in located Canada, please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    } else if placemark.administrativeArea != "ON" {
                        let alert = UIAlertController(title: "Error", message: "This point is not located in Ontario, please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                   } else if placemark.locality == nil || placemark.locality == "" {
                    
                        let alert = UIAlertController(title: "Error", message: "This point is not available to select, please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                   }else if self.getIndexByCity(citySearch: placemark.locality! ) > -1{
                        let alreadySelectedLocation = self.getIndexByCity(citySearch: placemark.locality! )
                        self.removePin(title: self.points[alreadySelectedLocation].letter)
                        self.points[alreadySelectedLocation] = LocationPoint(cityName: placemark.locality ?? "", coordinates: coordinate, distanceToLocation: distanceKM, letter: self.locationsLabels[alreadySelectedLocation])
                        self.addAnnotation(coordinate: coordinate, title: self.points[alreadySelectedLocation].letter, subtitle: "" )
                   }else{
                        self.navigationBtn.isHidden = true
                        if self.points.count == 3  {
                            self.mapKit.removeAnnotations(self.mapKit.annotations)
                            self.mapKit.removeOverlays(self.mapKit.overlays)
                            self.points.removeAll()
                            self.addAnnotation(coordinate: self.currentLocation!, title: "Current Location", subtitle: "" )
                        }
                            
                        let newPoint = LocationPoint(cityName: placemark.locality ?? "", coordinates: coordinate, distanceToLocation: distanceKM, letter: self.locationsLabels[self.points.count])
                        self.points.append(newPoint)
                        self.addAnnotation(coordinate: coordinate, title: newPoint.letter, subtitle: "" )
                                
                        if(self.points.count == 3){
                            let coordinates = self.points.map {$0.coordinates}
                            let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
                            self.mapKit.addOverlay(polygon)
                            self.navigationBtn.isHidden = false
                            self.calculateDistances()
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
        
        let latDelta: CLLocationDegrees = 0.3
        let lngDelta: CLLocationDegrees = 0.3
        
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
    
    func calculateDistances(){
        for (index, point) in points.enumerated(){
            let pointLocation: CLLocation =  CLLocation(latitude: point.coordinates.latitude, longitude: point.coordinates.longitude)
            
            
            var nextPointIndex:Int = index + 1
            if nextPointIndex == points.count{
                nextPointIndex = 0
            }
            let destinationPlaceMark = CLLocation(latitude: points[nextPointIndex].coordinates.latitude, longitude: points[nextPointIndex].coordinates.longitude)
            
            point.distanceToNextPoint = pointLocation.distance(from: destinationPlaceMark)/1000.0
            

            print(point.distanceToNextPoint)
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
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin" + annotation.title!!)
        annotationView.animatesDrop = true
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
        switch annotation.title {
            case "A":
                annotationView.pinTintColor = UIColor.systemPink
                return annotationView
            case "B":
                let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePinB")
                annotationView.pinTintColor = UIColor.orange
                return annotationView
            case "C":
                let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePinC")
                annotationView.pinTintColor = UIColor.cyan
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
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 1
            renderer.polyline.accessibilityLabel?.append("aaaaaa")
            return renderer
        } else if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(overlay: overlay)
            renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.green
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }
    
}
