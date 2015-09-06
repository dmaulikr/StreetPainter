//
//  GameData.swift
//  StreetPaint
//
//  Created by Nathanael Beisiegel on 9/5/15.
//  Copyright (c) 2015 Nathanael Beisiegel. All rights reserved.
//

import Foundation
import SpriteKit

enum TileState: Int {
  case Blank = 0
  case Red
  case Blue
  case Yellow
  case Purple
}

enum Direction: Int {
  case Up = 0
  case Down
  case Left
  case Right
}

struct Position {
  let x: Int
  let y: Int
}

func colorForTileState(state: TileState) -> UIColor {
  switch state {
  case .Red:
    return UIColor(red: 0.94, green: 0.29, blue: 0.29, alpha: 1.0)
  case .Blue:
    return UIColor(red: 0.26, green: 0.68, blue: 0.87, alpha: 1.0)
    //    case .Yellow:
    //      return UIColor(red: <#CGFloat#>, green: <#CGFloat#>, blue: <#CGFloat#>, alpha: <#CGFloat#>)
    //    case .Purple:
    //      return UIColor(red: <#CGFloat#>, green: <#CGFloat#>, blue: <#CGFloat#>, alpha: <#CGFloat#>)
  default:
    return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
  }
}

func colorForPlayerId(playerId: Int) -> TileState {
  return TileState(rawValue: playerId)!
}

class Tile {
  var color: TileState = TileState.Blank
  var sprite: SKSpriteNode
  var size: CGSize
  var position: CGPoint
  
//  func colorForTileState(state: TileState) -> UIColor {
//    switch state {
//    case .Red:
//      return UIColor(red: 0.94, green: 0.29, blue: 0.29, alpha: 1.0)
//    case .Blue:
//      return UIColor(red: 0.26, green: 0.68, blue: 0.87, alpha: 1.0)
////    case .Yellow:
////      return UIColor(red: <#CGFloat#>, green: <#CGFloat#>, blue: <#CGFloat#>, alpha: <#CGFloat#>)
////    case .Purple:
////      return UIColor(red: <#CGFloat#>, green: <#CGFloat#>, blue: <#CGFloat#>, alpha: <#CGFloat#>)
//    default:
//      return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
//    }
//  }
  
  init(parentNode: SKNode, size: CGSize, position: CGPoint, color: TileState) {
    self.size = size
    self.position = position
    sprite = SKSpriteNode(color: colorForTileState(color), size: size)
    sprite.position = position
    parentNode.addChild(sprite)
  }
  
  func setColor(color: TileState) {
    self.color = color
    // TODO change actual color based on tilestate
    let action = SKAction.colorizeWithColor(colorForTileState(color), colorBlendFactor: 1, duration: 0.5)
    sprite.runAction(action)
  }
  
  func reset() {
    setColor(TileState.Blank)
  }
}

class Board {
  var tileArray: [[Tile]] = []
  var playerPositions: [Int:Position] = [:]
  var p1Brush: SKSpriteNode?
  var p2Brush: SKSpriteNode?
  
  
  func create(parent: SKNode, origin: CGPoint, bounds: CGSize) {
    let size = 50
    let padding = 5
    
    var multi: [[Tile]] = []
    println("\(bounds)")
    
    for column in 0...16 {
      var columnArray: [Tile] = []
      for row in 0...11 {
        // TODO untangle logic / hack of manual padding
        let positionX = origin.x + CGFloat(column * (size + padding)) + CGFloat(50)
        let positionY = (bounds.height + origin.y) - CGFloat(row * (size + padding)) - CGFloat(50)
        let tile = Tile(parentNode: parent, size: CGSize(width: size, height: size), position: CGPoint(x: positionX, y: positionY), color: TileState.Blank)
        columnArray.append(tile)
      }
      multi.append(columnArray)
    }
    
    tileArray = multi
  }
  
  func setTwoPlayerPositions(parent: SKNode) {
    let player1Position = Position(x: 0, y: 0)
    let player2Position = dimensions()
    
    playerPositions = [1: player1Position, 2: player2Position];
    
    // Draw brushes
    p1Brush = SKSpriteNode(imageNamed:"Player1")
    p2Brush = SKSpriteNode(imageNamed:"Player2")
    
    let p1TilePosition = tileArray[player1Position.x][player1Position.y].position
    let p2TilePosition = tileArray[player2Position.x][player2Position.y].position
    p1Brush!.position = CGPoint(x: p1TilePosition.x - 20.0, y: p1TilePosition.y + 20.0) // tileArray[player1Position.x][player1Position.y].position
    tileArray[player1Position.x][player1Position.y].setColor(TileState.Red)
    p2Brush!.position = CGPoint(x: p2TilePosition.x - 20.0, y: p2TilePosition.y + 20.0)
    tileArray[player2Position.x][player2Position.y].setColor(TileState.Blue)
    parent.addChild(p1Brush!)
    parent.addChild(p2Brush!)
  }
  
  func moveBrush(player: Int, playerTile: Position) {
    let playerBrush = (player == 1) ? p1Brush! : p2Brush!
    let tilePoint = tileArray[playerTile.x][playerTile.y].position
    
    let moveToTile = SKAction.moveTo(CGPoint(x: tilePoint.x - 20.0, y: tilePoint.y + 20.0), duration: 0.2)
    playerBrush.runAction(moveToTile)
  }
  
  func movePlayer(player: Int, direction: Direction) {
    var changeX = 0
    var changeY = 0
    
    var playerPosition = playerPositions[player]
    
    switch direction {
    case .Up:
      if playerPosition!.y != 0 {
        changeY = -1
      }
    case .Down:
      if playerPosition!.y != dimensions().y {
        changeY = 1
      }
    case .Left:
      if playerPosition!.x != 0 {
        changeX = -1
      }
    case .Right:
      if playerPosition!.x != dimensions().x {
        changeX = 1
      }
    }
    
    var newTile = Position(x: playerPosition!.x + changeX, y: playerPosition!.y + changeY)
    println("player \(player) new position: x: \(newTile.x) \(newTile.y)")
    playerPositions[player]  = newTile
    moveBrush(player, playerTile: newTile)
    tileArray[newTile.x][newTile.y].setColor(colorForPlayerId(player))
  }
  
  // 0 based
  func dimensions() -> Position {
    if tileArray.count == 0 {
      return Position(x: 0, y: 0)
    } else {
      return Position(x: tileArray.count - 1, y: tileArray[0].count - 1)
    }
  }
  
  func reset() {
    for row in tileArray {
      for tile in row {
        tile.reset()
      }
    }
  }
}

class Players {
  var list: [String] = []
  
  func playerIdForDeviceId(deviceId: String) -> Int {
    for (index, id) in enumerate(list) {
      if deviceId == id {
        return index + 1 // 1 based index for enum
      }
    }
    
    return -1 // error
  }

}

class GameData {
  let players = Players()
  let board = Board()
}

  
