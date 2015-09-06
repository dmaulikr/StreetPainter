//
//  GameData.swift
//  StreetPaint
//
//  Created by Nathanael Beisiegel on 9/5/15.
//  Copyright (c) 2015 Nathanael Beisiegel. All rights reserved.
//

import Foundation

enum TileState: Int {
  case Blank = 0
  case Red
  case Blue
  case Yellow
  case Purple
}

class Tile {
  var color: TileState = TileState.Blank
  
  func reset() {
    color = TileState.Blank
  }
}

class Board {
  let tileArray: [[Tile]] = []
  
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
  
  func colorForPlayerId(playerId: Int) -> TileState {
    return TileState(rawValue: playerId)!
  }
}

class GameData {
  let players = Players()
  let board = Board()
}

  
