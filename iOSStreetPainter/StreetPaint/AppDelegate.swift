//
//  AppDelegate.swift
//  StreetPaint
//
//  Created by Nathanael Beisiegel on 9/5/15.
//  Copyright (c) 2015 Nathanael Beisiegel. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PBPebbleCentralDelegate {

  var window: UIWindow?
  var pebbleWatches: [PBWatch] = []
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    initPebble()
    setPebbleAppUUID()
    connectToWatches()
    
    return true
  }
  
  func initPebble() {
    // Grab Watches and set callbacks for connection changes
    self.pebbleWatches = PBPebbleCentral.defaultCentral().connectedWatches as! [PBWatch]
    PBPebbleCentral.defaultCentral().delegate = self
    println(pebbleWatches)
  }
  
  func setPebbleAppUUID() {
    let UUID = "6d444859-ed00-4e64-a486-f9e1ffaabb67"
    let bufferSize = 16
    
    var advertisementBytes = [CUnsignedChar](count: bufferSize, repeatedValue: 0)
    let streetPaintUUID = NSUUID(UUIDString: UUID)
    streetPaintUUID!.getUUIDBytes(&advertisementBytes)
    
    println("\(streetPaintUUID)")
    println("\(advertisementBytes)")
    
    PBPebbleCentral.defaultCentral().appUUID = NSData(bytes: advertisementBytes, length: 16)
  }
  
  func connectToWatches() {
    for watch in pebbleWatches {
      launchPebbleCompanionApps(watch)
      addWatchReceiveHandler(watch)
    }
  }
  
  func addWatchReceiveHandler(watch: PBWatch) {
    watch.appMessagesAddReceiveUpdateHandler({(watch: PBWatch!, update: [NSObject : AnyObject]!) -> Bool in
      println("Got update from watch app!")
      
      let updateDict = update as Dictionary
      println("Data from watch app!", updateDict)
      
      return true
    })
  }
  
  func launchPebbleCompanionApps(watch: PBWatch) {
    println("Attempting to load streetpainter")
    watch.appMessagesLaunch { (watch: PBWatch!, error: NSError?) -> Void in
      if (error == nil) {
        println("Successfully launched StreetPainter")
      } else {
        println("Failed to launch StreetPainter")
      }
    }
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  func pebbleCentral(central: PBPebbleCentral!, watchDidConnect watch: PBWatch!, isNew: Bool) {
    println("Pebble connected: \(watch.name)")
    self.pebbleWatches = PBPebbleCentral.defaultCentral().connectedWatches as! [PBWatch]
    println(pebbleWatches)
  }
  
  func pebbleCentral(central: PBPebbleCentral!, watchDidDisconnect watch: PBWatch!) {
    println("Pebble disconnected: \(watch.name)")
    self.pebbleWatches = PBPebbleCentral.defaultCentral().connectedWatches as! [PBWatch]
    println(pebbleWatches)
  }
  
  func getPebbleWatches() -> [PBWatch] {
    return self.pebbleWatches
  }
}

