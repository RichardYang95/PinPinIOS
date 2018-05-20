//
//  AppDelegate.swift
//  PinPin
//
//  Created by Richard Yang on 3/3/18.
//  Copyright © 2018 Richard Yang. All rights reserved.
//
//  ADDITIONAL INFO: Google Maps API: Main viewscreen, Reverse Geocoding for address, Markers on map,
//                   Google Places API: Search for location functionality. Tapping a location of the search moves the map to that location but it shows a random place first but if you drag the map, it will show the correct place.
//                                      Don't really know why this is happening or how to fix.
//                   Firebase database: Marker information (Address, Description, lat, lng, etc.). Timer runs every 10 sec and updates the map with any added or removed markers.

import UIKit
import GoogleMaps
import GooglePlaces

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GMSPlacesClient.provideAPIKey("AIzaSyCGPvtGaX3D3JWVJmkTf_mRNEnZBq1pbug")
        GMSServices.provideAPIKey("AIzaSyCGPvtGaX3D3JWVJmkTf_mRNEnZBq1pbug")
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

