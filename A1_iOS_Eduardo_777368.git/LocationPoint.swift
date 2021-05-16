//
//  Location.swift
//  A1_iOS_Eduardo_777368.git
//
//  Created by Eduardo Cardona on 2021-05-15.
//  Copyright © 2021 MacStudent. All rights reserved.
//

import Foundation
import MapKit
class LocationPoint{
    var cityName: String
    var coordinates: CLLocationCoordinate2D
    var distanceToLocation: Double
    var distanceToNextPoint: Double
    var letter: String
    
    
    init(cityName: String,
         coordinates: CLLocationCoordinate2D,
         distanceToLocation: Double,
         distanceToNextPoint: Double,
         letter: String) {
        self.cityName = cityName
        self.coordinates = coordinates
        self.distanceToLocation = distanceToLocation
        self.distanceToNextPoint = distanceToNextPoint


        self.letter = letter
    }
    
    init(cityName: String,
         coordinates: CLLocationCoordinate2D,
         distanceToLocation: Double,
         letter: String) {
        self.cityName = cityName
        self.coordinates = coordinates
        self.distanceToLocation = distanceToLocation
        self.distanceToNextPoint = 0
        self.letter = letter
    }
}
