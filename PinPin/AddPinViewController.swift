//
//  AddPinViewController.swift
//  PinPin
//
//  Created by Richard Yang on 3/4/18.
//  Copyright © 2018 Richard Yang. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation
import Firebase
import FirebaseDatabase

class AddPinViewController: UIViewController{
    var coord: CLLocationCoordinate2D? // Get from VC
    var marker: GMSMarker! // Pass to VC
    var ref: DatabaseReference!

    @IBOutlet weak var AddressField: UITextField!
    @IBOutlet weak var NeedSelector: UISegmentedControl!
    @IBOutlet weak var AddPinButton: UIButton!
    @IBOutlet weak var AddressTextField: UITextField!
    @IBOutlet weak var NeedsField: UISegmentedControl!
    @IBOutlet weak var DescTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the address label to where the marker is tapped
        GMSGeocoder().reverseGeocodeCoordinate(coord!, completionHandler: {response, Error in
            guard let address = response?.firstResult(), let lines = address.lines else {
                return
            }

            self.AddressTextField.text = lines.joined(separator: "\n")
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Tapped the Add Pin Button
    @IBAction func AddPinButton(_ sender: Any) {
        // Add marker to map
        marker = GMSMarker()
        marker.position = coord!
        switch NeedsField.selectedSegmentIndex {
        case 1:
            marker.icon = UIImage(named: "money")
        case 2:
            marker.icon = UIImage(named: "firstaid")
        case 3:
            marker.icon = UIImage(named: "ride")
        default:
            marker.icon = UIImage(named: "food")
        }
        
        // Generate unique user ID using Java String's hashCode() function based on the latlng
        let hash = String(describing: coord?.latitude) + String(describing: coord?.longitude)
        let id = String(hash.hashCode())
       
        // Add marker to Firebase - LatLng, TimePlaced, Address, Need, Desc, TimesHelped, DeviceID
        ref = Database.database().reference()
        ref.child(id).child("Lat").setValue(coord?.latitude)
        ref.child(id).child("Lng").setValue(coord?.longitude)
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm  MM-dd-yyyy"
        let timePlaced = formatter.string(from: Date())
        ref.child(id).child("Placed").setValue(timePlaced)
        ref.child(id).child("Addr").setValue(AddressTextField.text)

        switch NeedsField.selectedSegmentIndex {
        case 1:
            ref.child(id).child("Needs").setValue("Money")
        case 2:
            ref.child(id).child("Needs").setValue("First Aid")
        case 3:
            ref.child(id).child("Needs").setValue("Ride")
        default:
            ref.child(id).child("Needs").setValue("Food")
        }

        ref.child(id).child("Desc").setValue(DescTextField.text)
        ref.child(id).child("DeviceID").setValue(UIDevice.current.identifierForVendor!.uuidString)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "returnAddedPin" {
            if let destinationVC = segue.destination as? ViewController {
                destinationVC.addedMarker = marker // Add the marker to the mapView in main VC
            }
        }
    }
}
