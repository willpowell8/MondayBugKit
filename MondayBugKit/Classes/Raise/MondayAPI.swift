//
//  MondayAPI.swift
//  MondayBugKit
//
//  Created by Will Powell on 02/11/2020.
//

import Foundation
import Alamofire

public class MondayAPI {
    
    static func getMe(callback: @escaping (_ error:Bool, _: [String: Any]?)->Void){
        let queryString = "query {" +
        "me {" +
        "is_guest " +
        "join_date" +
        "}" +
        "}"
        performCall(query: queryString) { (error, data, jsonData) in
            callback(error, data)
        }
    }
    
    static func getBoard(boardId:Int, callback: @escaping (_ error:Bool, _: MondayBoard?)->Void){
        let queryString = "query {" +
        "boards (ids: \(boardId)) {" +
            "id " +
            "owner {" +
                "id" +
            "}" +
            "columns { " +
                "id " +
                "title " +
                "type " +
                "settings_str " +
            "}" +
            "}" +
        "}"
        performCall(query: queryString) { (error, data, jsonData) in
            if error {
                callback(error, nil)
                return
            }
            if let jsonData = jsonData {
                let decoder = JSONDecoder()

                do {
                    let boardResponse = try decoder.decode(MondayBoardResponse.self, from: jsonData)
                    if boardResponse.data.boards.count > 0 {
                        callback(false, boardResponse.data.boards.first)
                        return
                    }
                    
                } catch {
                    print(error.localizedDescription)
                }
            }
            callback(error, nil)
        }
    }
    
    static func createItem(boardId:Int, data:[String:Any?], columns:[MondayColumn]?,
                           completion: @escaping (Bool)->Void){
        let name = data["name"] as? String ?? ""
        var queryString = "mutation {" +
        "create_item (" +
            "board_id: \(boardId), " +
            "item_name: \"\(name)\", "
        
        var columnValueObj = [String:Any]()
        columns?.forEach({ (column) in
            let type = column.type
            let columnId = column.id ?? ""
            let columnIdStr = "\(columnId)"
            switch(type){
            case "long-text":
                if let val = data[columnIdStr] as? String {
                    columnValueObj[columnIdStr] = val
                }
                break;
            case "text":
                if let val = data[columnIdStr] as? String {
                    columnValueObj[columnIdStr] = val
                }
                break;
            default:
                if let val = data[columnIdStr] as? String {
                    columnValueObj[columnIdStr] = val
                }else if let val = data[columnIdStr] as? Date {
                    let dateFormatter = DateFormatter();
                    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                    columnValueObj[columnIdStr] = dateFormatter.string(from: val)
                }
                break;
            }
        })
        if columnValueObj.count > 0 {
            if let jsonData = try? JSONSerialization.data(withJSONObject: columnValueObj, options: .fragmentsAllowed), let jsonString = String(data: jsonData, encoding: .utf8) {
                let prepared = jsonString.escaped
                queryString += "column_values: \"\(prepared)\""
            }
        }
        queryString += ") {id}}"
        performCall(query: queryString) { (error, result, data) in
            print(error, result, data)
            guard let d = result?["data"] as? [String:Any] else{
                return
            }
            guard let createItem = d["create_item"] as? [String:Any] else{
                return
            }
            guard let itemId = createItem["id"] as? String else{
                return
            }
            let documentsDirectory = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0]
            let zipFilePath = documentsDirectory.appendingPathComponent("archive.zip")
            print("Got ItemId \(itemId)")
            uploadFile(itemId: itemId, filePath: zipFilePath, completion:completion)
            
        }
    }
    
    public static func uploadFile(itemId:String, columnName:String = "file", filePath:URL, fileName:String = "archive.zip",
                                  completion: @escaping (Bool)->Void){
        let queryString = "mutation ($file: File!) { add_file_to_column(file: $file, item_id: \(itemId), column_id: \"file\") { id } }"
        uploadFileProcess(queryString: queryString, paramName: "variables[file]", fileName: "archive.zip", filePath: filePath, completion: completion)
    }
    
    public static func uploadFileProcess(queryString:String, paramName: String, fileName: String, filePath: URL,
                                         completion: @escaping (Bool)->Void) {
        let urlValue = URL(string: "https://api.monday.com/v2/file")!

        let headers: HTTPHeaders = [
            "Authorization": MondayBugKit.context.access_token ?? "",
            "Content-type": "multipart/form-data"
        ]

                let url = try! URLRequest(url: urlValue, method: .post, headers: headers)
                guard let fileData = FileManager.default.contents(atPath: filePath.path) else{
                    print("ERROR Could not load file data")
                    return
                }
        
        AF.request("https://api.monday.com/v2/file", method: .post, parameters: ["query":queryString], encoder: URLEncodedFormParameterEncoder(), headers: headers).response { (resp) in
            print(String(data:resp.data!, encoding: .utf8))
        }
            
                AF.upload(multipartFormData: { multipartFormData in
                    if let queryData = queryString.data(using: .utf8) {
                        multipartFormData.append(queryData, withName: "query")
                    }
                    multipartFormData.append(fileData, withName: "variables[file]", fileName: "Archive.zip", mimeType: "application/zip")
                }, with: url).response(completionHandler: { (resp) in
                    let response = String(data: resp.data!, encoding: .utf8)
                    print(response)
                    switch resp.result {
                    case .success( _):
                        print("Success")
                        completion(true)
                    
                    case .failure(_):
                        print("Error")
                        completion(false)
                    }
                })
    }
    
    
    static func performCall(query:String, callback: @escaping (_ error:Bool, _: [String: Any]?,_ jsonData:Data?)->Void){
        let parameters = ["query": query]

        print(query)
        //create the url with URL
        let url = URL(string: "https://api.monday.com/v2")! //change the url

        //create the session object
        let session = URLSession.shared

        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST

        do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
            } catch let error {
                callback(true, nil, nil)
                print(error.localizedDescription)
            }
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            if let access_token = MondayBugKit.context.access_token {
                request.addValue(access_token, forHTTPHeaderField: "Authorization")
            }

            //create dataTask using the session object to send data to the server
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                guard error == nil else {
                    callback(true, nil, nil)
                    return
                }

                guard let data = data else {
                    callback(true, nil, nil)
                    return
                }

                do {
                    //create json object from data
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        
                        print(json)
                        callback(false, json, data)
                        // handle json...
                    }
                } catch let error {
                    print(error.localizedDescription)
                    callback(true, nil, nil)
                }
            })
            task.resume()
    }
}


extension String {
    var unescaped: String {
        let entities = ["\0": "\\0",
                        "\t": "\\t",
                        "\n": "\\n",
                        "\r": "\\r",
                        "\"": "\\\"",
                        "\'": "\\'",
                        ]

        return entities
            .reduce(self) { (string, entity) in
                string.replacingOccurrences(of: entity.value, with: entity.key)
            }
            .replacingOccurrences(of: "\\\\(?!\\\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
    
    var escaped: String {
        let entities = ["\0": "\\0",
                        "\t": "\\t",
                        "\n": "\\n",
                        "\r": "\\r",
                        "\"": "\\\"",
                        "\'": "\\'",
                        ]

        return entities
            .reduce(self) { (string, entity) in
                string.replacingOccurrences(of: entity.key, with: entity.value)
            }
    }
    
    
}
