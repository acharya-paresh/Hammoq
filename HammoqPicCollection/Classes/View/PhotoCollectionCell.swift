//
//  PhotoCollectionCell.swift
//  HammoqPicCollection
//
//  Created by Paresh Nath Acharya on 04/05/21.
//

import Foundation
import UIKit

class PhotoCollectionCell: UICollectionViewCell {
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var checkMark: UIImageView!
    
    static let nibName = "PhotoCollectionCell"
    static let reuseIdentifier = "photoCollectionCell"

    var imageObject: ImageObject? {
        didSet {
            self.loadImage()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func loadImage() {
        if let urlStr = imageObject?.url, let url = URL(string: urlStr) {
            cellImage.downloaded(from: url)
        }
    }
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFill) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    
    func setImageColor(color: UIColor) {
      let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
      self.image = templateImage
      self.tintColor = color
    }
}
