//
//  GameViewController.swift
//  StreetPaint
//
//  Created by Nathanael Beisiegel on 9/5/15.
//  Copyright (c) 2015 Nathanael Beisiegel. All rights reserved.
//

import UIKit
import SpriteKit

extension SKNode {
  class func unarchiveFromFile(file : String) -> SKNode? {
    if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
      var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
      var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
      
      archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
      let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
      archiver.finishDecoding()
      return scene
    } else {
      return nil
    }
  }
}

class GameViewController: UIViewController {
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate // grab reference to appdelegate for watches
//  var gameData = GameData()
  let players = Players()
  let board = Board()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
      // Configure the view.
      let skView = self.view as! SKView
      skView.showsFPS = true
      skView.showsNodeCount = true
      
      /* Sprite Kit applies additional optimizations to improve rendering performance */
      skView.ignoresSiblingOrder = true
      
      /* Set the scale mode to scale to fit the window */
      scene.scaleMode = .ResizeFill
      skView.presentScene(scene)
    }
  }
  
  override func shouldAutorotate() -> Bool {
    return true
  }
  
  override func supportedInterfaceOrientations() -> Int {
    return Int(UIInterfaceOrientationMask.Landscape.rawValue)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Release any cached data, images, etc that aren't in use.
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
//  @IBAction func handleNotifyPebbleWatches(sender: UIButton) {
//    println("'Notify Pebble Watches' Pressed")
//    let watches = appDelegate.pebbleWatches
//    
//    for watch in watches {
//      let playerId = players.playerIdForDeviceId(watch.serialNumber) // find id
//      let seedData = [0: 99, 1: playerId]; // TODO make protocol function that puts together data
//      
//      watch.appMessagesPushUpdate(seedData as [NSObject : AnyObject], onSent: { (watch: PBWatch!, update: [NSObject : AnyObject]!, error: NSError!) -> Void in
//        if (error == nil) {
//          println("Successfully sent data", update)
//        } else {
//          println("Failed to send data to watches")
//        }
//      })
//    }
//  }
}
