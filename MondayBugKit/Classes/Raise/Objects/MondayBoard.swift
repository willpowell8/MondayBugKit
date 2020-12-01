//
//  MondayBoard.swift
//  MondayBugKit
//
//  Created by Will Powell on 02/11/2020.
//

import Foundation

struct MondayColumn:Codable{
    var id:String?
    var settings_str:String
    var title:String
    var type:String
}
struct  MondayUser:Codable {
    var id:Int
}

struct MondayBoardResponse:Codable {
    var account_id:Int
    var data:MondayBoards
}

struct MondayBoards:Codable {
    var boards:[MondayBoard]
}

struct MondayBoard:Codable {
    var id:String
    var owner:MondayUser
    var columns:[MondayColumn]?
}
