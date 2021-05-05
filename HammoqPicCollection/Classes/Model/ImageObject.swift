//
//  ImageObject.swift
//  HammoqPicCollection
//
//  Created by Paresh Nath Acharya on 05/05/21.
//

import Foundation

/*!
 {
         "image_id": "998687b60679c58773eb2ca7601f1224",
         "permalink_url": "https://gyazo.com/998687b60679c58773eb2ca7601f1224",
         "url": "https://i.gyazo.com/998687b60679c58773eb2ca7601f1224.jpg",
         "metadata": {
             "app": null,
             "title": null,
             "original_title": null,
             "url": null,
             "original_url": null,
             "desc": ""
         },
         "type": "jpg",
         "thumb_url": "https://thumb.gyazo.com/thumb/200/eyJhbGciOiJIUzI1NiJ9.eyJpbWciOiJfMTU1ZDdkMzhjNmI1NGFlY2MwMmJmYzgzODRjMDgwZmYifQ.CWN2lt4veWcqhPMfh0AIFavJEQxL7nFu4eAPVlbtl28-jpg.jpg",
         "created_at": "2021-05-05T06:26:48+0000"
     }
 */

struct ImageObject: Codable {
    var image_id: String?
    var permalink_url: String?
    var url: String?
    var type: String?
    var thumb_url: String?
    var created_at: String?
}
