//
//  NetworkManager.swift
//  HammoqPicCollection
//
//  Created by Paresh Nath Acharya on 04/05/21.
//

import Foundation
import MobileCoreServices
import UIKit

enum HTTPType: String {
    case GET
    case POST
    case DELETE
}

typealias DownloadHandler = ([ImageObject]?, Error?) -> Void
typealias DeleteHandler = (Bool) -> Void

class NetworkManager {
    let urlSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?

//    let baseUrl = "https://hammoqcollection.com/"
    let baseUrl = "https://api.gyazo.com/api/"
    let clientId = "97281af778d8366a7aec9cd7bee9e38d76dc13ec742a4dd7db95716639329549"
    let client_secret = "467f83428199633ab20cf7dee7dbefb53cc2621185bc306fc4f7a4be19ae5cd7"
    let accessToken = "fdc4ca867f053b2ed0361506c92bef297311feb33648dd2c064f3bf169ef0cff"
    
    func downloadImge(completion: @escaping DownloadHandler) {
        let queryItems = [URLQueryItem(name: "access_token", value: accessToken)]
        var urlComps = URLComponents(string: "https://api.gyazo.com/api/images")
        urlComps?.queryItems = queryItems
        
        guard let url = urlComps?.url! else {
            return
        }
        
        var urlReq = URLRequest(url: url)
        urlReq.httpMethod = HTTPType.GET.rawValue

        dataTask = urlSession.dataTask(with: urlReq, completionHandler: { (responseData, response, error) in
            // my code
            if(error != nil){
                print("\(error!)")
            }
            
            guard let responseData = responseData else {
                print("no response data")
                return
            }
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("Images: \(responseString)")
                let data = Data(responseString.utf8)
                do {
                let decoded = try JSONSerialization.jsonObject(with: data, options: [])
                guard let json = decoded as? [[String: Any]] else {
                    print("no response data")
                    return
                }
                print(json)
                    let jsonArray = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                    print(jsonArray) // use the json here
                    let decoder = JSONDecoder()
                    let imageArray = try decoder.decode([ImageObject].self, from: jsonArray)
                    completion(imageArray, nil)
                } catch let error as NSError {
                    print(error)
                }
            }

        })
        dataTask?.resume()
    }
    
    func uploadImage(image: UIImage, completion: @escaping DeleteHandler) {
        let filename = "image.jpg"
        
        let boundary = self.generateBoundaryString()
        let accessKey = "access_token"
        let imageKey = "imagedata"
        
        guard let url = URL(string: "https://upload.gyazo.com/api/upload") else {
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
        // And the boundary is also set here
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()

        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(accessKey)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(accessToken)".data(using: .utf8)!)

        // Add the image data to the raw http request data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(imageKey)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(image.jpegData(compressionQuality: 0.3)!)

        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        urlSession.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
            
            if(error != nil){
                completion(false)
                print("\(error!)")
            }
            
            guard let responseData = responseData else {
                print("no response data")
                completion(false)
                return
            }
            
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("uploaded to: \(responseString)")
                completion(true)
            }
        }).resume()
    }

    private func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    func deleteImage(imageId: String, completion: @escaping DeleteHandler) {
        let queryItems = [URLQueryItem(name: "access_token", value: accessToken)]
        let urlStr = "https://api.gyazo.com/api/images/" + imageId
        var urlComps = URLComponents(string: urlStr)
        urlComps?.queryItems = queryItems
        
        guard let url = urlComps?.url! else {
            return
        }
        var urlReq = URLRequest(url: url)
        urlReq.httpMethod = HTTPType.DELETE.rawValue
        
        dataTask = urlSession.dataTask(with: urlReq, completionHandler: { (data, response, error) in
            // my code
            if(error != nil){
                completion(false)
                print("\(error!)")
            }
            
            guard let responseData = data else {
                print("no response data")
                completion(false)
                return
            }
            
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("deleted to: \(responseString)")
                completion(true)
            }
        })
        dataTask?.resume()
    }
    
    func deleteImages(imageIds: [String], completion: @escaping DeleteHandler) {
        let group = DispatchGroup()
        var isSuccess = true
        for imageId in imageIds {
            group.enter()
            self.deleteImage(imageId: imageId) { (isDeleted) in
                if isSuccess == true {
                    isSuccess = isDeleted
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            completion(isSuccess)
        }
    }
}
