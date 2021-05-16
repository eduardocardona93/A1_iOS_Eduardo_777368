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
    var locationsLabels = ["A","B","C"]
    var locationsPolygon:MKPolygon? = nil

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
                   }else if self.checkPointCloserToAnother(newCoordinate: coordinate) > -1 {
                        let closerLocation = self.checkPointCloserToAnother(newCoordinate: coordinate)
                        self.removePin(title: self.points[closerLocation].letter)
                        self.points.remove(at: closerLocation)
                        self.mapKit.removeOverlays(self.mapKit.overlays)
                    self.navigationBtn.isHidden = true
                   }else{
                        self.navigationBtn.isHidden = true
                        if self.points.count == 3  {
                            let renderer = MKPolylineRenderer(overlay: self.locationsPolygon!)
                            if renderer.path.contains(renderer.point(for:MKMapPoint(coordinate))) {
                                let alert = UIAlertController(title: "Error", message: "This point is inside the polygon, please try again", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }else{
                                self.mapKit.removeAnnotations(self.mapKit.annotations)
                                self.mapKit.removeOverlays(self.mapKit.overlays)
                                self.points.removeAll()
                            }
   
                            
                        }
                        for point in self.locationsLabels{
                            let index = self.getIndexByLetter(letterSearch: point)
                            if index == -1 {
                                let newPoint = LocationPoint(cityName: placemark.locality ?? "", coordinates: coordinate, distanceToLocation: distanceKM, letter: point)
                                self.points.append(newPoint)
                                self.addAnnotation(coordinate: coordinate, title: point, subtitle: "" )
                                break
                            }
                        }
                        if(self.points.count == 3){
                            let coordinates = self.points.map {$0.coordinates}
                            self.locationsPolygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
                            self.mapKit.addOverlay(self.locationsPolygon!)
                            self.navigationBtn.isHidden = false
                            self.setDistances()
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
            default:
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "distance" + annotation.title!!)

                return annotationView
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
