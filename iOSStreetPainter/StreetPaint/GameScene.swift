//
//  GameScene.swift
//  StreetPaint
//
//  Created by Nathanael Beisiegel on 9/5/15.
//  Copyright (c) 2015 Nathanael Beisiegel. All rights reserved.
//

import SpriteKit



class GameScene: SKScene {
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate // grab reference to appdelegate for watches
  let players = Players()
  let board = Board()
  
//  var player1Position: Position?
//  var player2Position: Position?
  
  override func didMoveToView(view: SKView) {
    connectToWatches()
    setupPlayers()
    
    /* Setup your scene here */
    let myLabel = SKLabelNode(fontNamed:"Helevtica")
    myLabel.text = "Street Painter";
    myLabel.color = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0);
    myLabel.fontSize = 12;
    myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y: self.frame.height - 20);
    
//    let testSprite = SKSpriteNode(color: UIColor(red: 0.5, green: 0.5, blue: 2.0, alpha: 1.0), size: CGSize(width: self.frame.width - 20, height: self.frame.height - 40))
//    let testSprite = SKNode(size: CGSize(width: self.frame.width - 20, height: self.frame.height - 40))
    let testSprite = SKNode()
    testSprite.position = CGPoint(x: 0, y: 0);
    
    let testSprite2 = SKSpriteNode(color: UIColor(red: 1.0, green: 0.5, blue: 2.0, alpha: 1.0), size: CGSize(width: 20, height: 20))
    testSprite2.position = CGPoint(x: 20, y: 20);
    
    self.addChild(myLabel)
    self.addChild(testSprite)
    self.addChild(testSprite2)
    drawBoard(testSprite, origin: CGPoint(x: 20, y: 20), size: CGSize(width: self.frame.width - 20, height: self.frame.height - 40))
    board.setTwoPlayerPositions(testSprite)
    
//    board.tileArray[2][2].setColor(TileState.Blue)
//    player1Position = Position(x: 0, y: 0);
//    player2Position = Position(x: board.dimensions().x - 1, y: board.dimensions().y - 1)
  }
  
  func connectToWatches() {
    let watches = appDelegate.pebbleWatches

    for watch in watches {
      launchPebbleCompanionApps(watch)
      //      addWatchReceiveHandler(watch)
    }
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
  
  func setupPlayers() {
    let watches = appDelegate.pebbleWatches
    
    players.list = watches.map({(watch: PBWatch) -> String in
      return watch.serialNumber
    })
    
    println(players.list)
    setPlayerOnWatches(watches)
    addWatchReceiveHandler(watches)
  }
  
  func setPlayerOnWatches(watches: [PBWatch]) {
    for watch in watches {
      let playerId = players.playerIdForDeviceId(watch.serialNumber) // find id
      let seedData = [0: 99, 1: playerId]; // TODO make protocol function that puts together data
      watch.appMessagesPushUpdate(seedData as [NSObject : AnyObject], onSent: { (watch: PBWatch!, update: [NSObject : AnyObject]!, error: NSError!) -> Void in
        if (error == nil) {
          println("Successfully sent data", update)
        } else {
          println("Failed to send data to watch: ", watch.serialNumber)
        }
      })
    }
  }
  
  func addWatchReceiveHandler(watches: [PBWatch]) {
    for watch in watches {
      watch.appMessagesAddReceiveUpdateHandler({(watch: PBWatch!, update: [NSObject : AnyObject]!) -> Bool in
        println("Got update from watch app!")
        
        let updateDict = update as Dictionary
        println("Data from watch app!", updateDict)
        
        // move TODO use player info too
        if updateDict[1] != nil && updateDict[3] != nil {
          self.movePlayer(updateDict[1] as! Int, direction: updateDict[3] as! Int!)
        }
        
        return true
      })
    }
  }
  
  func movePlayer(player: Int, direction: Int) {
    board.movePlayer(player, direction: Direction(rawValue: direction)!)
//    var changeX = 0
//    var changeY = 0
//    
//    switch Direction(rawValue: direction)! {
//    case .Up:
//      changeY = 1
//    case .Down:
//      changeY = -1
//    case .Left:
//      changeX = -1
//    case .Right:
//      changeX = 1
//    }
//    
//    if player1Position!.x == 0 || player1Position!.x == (board.dimensions().x - 1) {
//      changeX = 0
//    }
//    else if player1Position!.y == 0 || player1Position!.y == (board.dimensions().y - 1) {
//      changeY = 0
//    }
//    
//    var newTile = Position(x: player1Position!.x + changeX, y: player1Position!.y + changeY)
//    player1Position = newTile
//    board.tileArray[newTile.x][newTile.y].setColor(TileState.Blue)
  }
  
  func drawBoard(parent: SKNode, origin: CGPoint, size: CGSize) {
    board.create(parent, origin: origin, bounds: size)
  }
  
  
  //    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
  //        /* Called when a touch begins */
  //
  //        for touch in (touches as! Set<UITouch>) {
  //            let location = touch.locationInNode(self)
  //
  //            let sprite = SKSpriteNode(imageNamed:"Spaceship")
  //
  //            sprite.xScale = 0.5
  //            sprite.yScale = 0.5
  //            sprite.position = location
  //
  //            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
  //
  //            sprite.runAction(SKAction.repeatActionForever(action))
  //
  //            self.addChild(sprite)
  //        }
  //    }
  
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
  }
}
