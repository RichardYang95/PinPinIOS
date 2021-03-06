//
//  ViewController.swift
//  PinPin
//
//  Created by Richard Yang on 3/3/18.
//  Copyright © 2018 Richard Yang. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, GMSAutocompleteViewControllerDelegate {
    let manager = CLLocationManager()
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var updateTimer: Timer! // Used to read coords from the database every X seconds

    var addedCoord: CLLocationCoordinate2D! // Pass to AddPinVC
    var addedMarker: GMSMarker? // Get from AddPinVC
    var tappedCoord: CLLocationCoordinate2D! // Pass to PinDetailVC
    
    struct coordInfo : Hashable {
        var coord = CLLocationCoordinate2D()
        var icon = UIImage()
        var hashValue: Int
        
        static func ==(lhs: ViewController.coordInfo, rhs: ViewController.coordInfo) -> Bool {
            return lhs.coord.latitude == rhs.coord.latitude && lhs.coord.longitude == rhs.coord.longitude
        }
    }
    
    //var coords = [coordInfo]() // Array of coords from the firebase database
    var coords = Set<coordInfo>()
    
    @IBOutlet weak var searchButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placesClient = GMSPlacesClient.shared()
        
        // Get the user's current location
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        // Show the user's current location on the map
        let camera = GMSCameraPosition.camera(withLatitude: (manager.location?.coordinate.latitude)!, longitude: (manager.location?.coordinate.longitude)!, zoom: 18.0)

        // Create the Google Map
        let screenWidth = UIScreen.main.fixedCoordinateSpace.bounds.width
        let screenHeight = UIScreen.main.fixedCoordinateSpace.bounds.height
        mapView = GMSMapView.map(withFrame: CGRect.init(x: 0, y: 65, width: screenWidth, height: screenHeight - 65), camera: camera)
        mapView.delegate = self
        self.view.addSubview(mapView)
        
        // Settings for the Google Map
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.indoorPicker = false

        // Read in coords from the database every X seconds
        _ = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.getCoords), userInfo: nil, repeats: true)
    }

    // Read in coords from the database every X seconds
    @objc func getCoords() {
        // Read in each coord from the database
        let url = URL(string: "http://129.65.221.101/php/getPinPinGPSdata.php")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!)
            }
            else {
                if let dbCoords = String(data: data!, encoding: .utf8) {
                    var lines: [String] = []
                    dbCoords.enumerateLines {line, _ in
                        lines.append(line)
                    }

                    for coord in lines {
                        if !coord.isEmpty {
                            let arr = coord.components(separatedBy: " ")
                            
                            let coord = CLLocationCoordinate2D(latitude: Double(arr[0])!, longitude: Double(arr[1])!)
                            var icon = UIImage(named: "food")!
                            switch(arr[2]) {
                            case "Money":
                                icon = UIImage(named: "money")!
                            case "Ride":
                                icon = UIImage(named: "ride")!
                            case "FirstAid":
                                icon = UIImage(named: "firstaid")!
                            default:
                                icon = UIImage(named: "food")!
                            }
                            
                            let ci = coordInfo(coord: coord, icon: icon, hashValue: 0)
                            if (!self.coords.contains(ci)) {
                                self.coords.insert(ci)
                            }
                        }
                    }
                }
            }
        }
        task.resume()
        
        // Add the markers from the database to the map
        addPins()
    }
    
    
    // Add each coord from the database as a marker onto the map
    func addPins() {
        // First delete all the current markers on the map
        self.mapView.clear()

        for c in self.coords {
            // Only show Pins within 20 km of user.
            if 20 >= getDistance(lat1: (manager.location?.coordinate.latitude)!, lng1: (manager.location?.coordinate.longitude)!, lat2: c.coord.latitude, lng2: c.coord.longitude) {
                let marker = GMSMarker()
                marker.position = c.coord
                marker.map = mapView
                marker.icon = c.icon
            }
        }
        
        self.coords.removeAll()
    }
    
    // Add pin to database when user taps an empty space
    func mapView(_ mapView: GMSMapView, didTapAt coord: CLLocationCoordinate2D) {
        let alert = UIAlertController(title: "Pick a Need", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.addAction(UIAlertAction(title: "Food", style: UIAlertActionStyle.default, handler: {(action) in
            let ci = coordInfo(coord: coord, icon: UIImage(named: "food")!, hashValue: 0)
            //ci.icon = UIImage(named: "food")!
            self.coords.insert(ci)
            self.addToDB(ci: ci, need: "Food")
            self.addPins()
        }))
        alert.addAction(UIAlertAction(title: "Money", style: UIAlertActionStyle.default, handler: {(action) in
            let ci = coordInfo(coord: coord, icon: UIImage(named: "money")!, hashValue: 0)
            //ci.icon = UIImage(named: "money")!
            self.coords.insert(ci)
            self.addToDB(ci: ci, need: "Money")
            self.addPins()}))
        alert.addAction(UIAlertAction(title: "First Aid", style: UIAlertActionStyle.default, handler: {(action) in
            let ci = coordInfo(coord: coord, icon: UIImage(named: "firstaid")!, hashValue: 0)
            //ci.icon = UIImage(named: "firstaid")!
            self.coords.insert(ci)
            self.addToDB(ci: ci, need: "FirstAid")
            self.addPins()}))
        alert.addAction(UIAlertAction(title: "Ride", style: UIAlertActionStyle.default, handler: {(action) in
            let ci = coordInfo(coord: coord, icon: UIImage(named: "ride")!, hashValue: 0)
            //ci.icon = UIImage(named: "ride")!
            self.coords.insert(ci)
            self.addToDB(ci: ci, need: "Ride")
            self.addPins()}))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Add the coordinate to the database
    func addToDB(ci: coordInfo, need: String) {
        let s = ("http://129.65.221.101/php/sendPinPinGPSdata.php?gps=" + String(ci.coord.latitude) + " " + String(ci.coord.longitude) + " " + need).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: s!)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print(error!)
            }
        }
        task.resume()
    }
    
    // Launch Google Maps or Apple Maps when user taps a pin
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let coord = CLLocationCoordinate2D(latitude: marker.position.latitude, longitude: marker.position.longitude)
        let alert = UIAlertController(title: "Get Directions To This Pin?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: {(action) in
            if (UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)) {
                UIApplication.shared.open(URL(string: "comgooglemaps://?saddr=&daddr=\(coord.latitude), \(coord.longitude)&directionsmode=driving")!, options: [:], completionHandler: nil)
            }
            else {
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord, addressDictionary:nil))
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coord: CLLocationCoordinate2D) {
        // Can't get the marker's exact coords, so have to find the one nearest to the tap.
        var shortestDist = Double.infinity
        var temp = coordInfo(coord: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                             icon: UIImage(named: "food")!,
                             hashValue: 0)
        for pin in self.coords {
            let distance = self.getDistance(lat1: pin.coord.latitude, lng1: pin.coord.longitude, lat2: coord.latitude, lng2: coord.longitude);
            
            if distance < shortestDist {
                shortestDist = distance
                temp = pin
            }
        }
        
        if (shortestDist > 0.03) {
            return;
        }
        
        let alert = UIAlertController(title: "Do you want to flag this Pin?",
                                      message: "Flag this Pin if the person is not at the location anymore.",
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: {(action) in
            // Remove the flagged marker from the map.
            self.coords.remove(temp)
            self.addPins()
            
            // Remove the flagged marker from the database.
            let s = ("http://129.65.221.101/php/deleteFlaggedEntry?gps=" + String(temp.coord.latitude) + " " + String(temp.coord.longitude)).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let url = URL(string: s!)
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    print(error!)
                }
            }
            task.resume()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func degreesToRadians(degrees: Double) -> Double{
        return degrees * Double.pi / 180
    }
    
    func getDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double{
        let earthRadiusKm = 6371.00;
        
        let dLat = degreesToRadians(degrees: lat2 - lat1)
        let dLng = degreesToRadians(degrees: lng2 - lng1)
        
        let newLat1 = degreesToRadians(degrees: lat1)
        let newLat2 = degreesToRadians(degrees: lat2)
        
        let a = sin(dLat / 2) * sin(dLat / 2) + sin(dLng / 2) * sin(dLng / 2) * cos(newLat1) * cos(newLat2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadiusKm * c
    }
    
    //---------------------------------------------- Search Functionality -----------------------------------------------
    
    // When user taps the search button
    @IBAction func searchButtonTapped(_ sender: Any) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    // User selects a search result
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        print("Place Coords: \(place.coordinate)")
        dismiss(animated: true, completion: nil)
        self.coords.removeAll()
        
        self.mapView.animate(toLocation: place.coordinate)
    }
    
    // Error while searching
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    // User cancelled the search
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    //-------------------------------------------------------------------------------------------------------------------
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension Double {
    func roundTo(places:Int) -> String {
        return String(format: "%.\(places)f", self)
    }
}
