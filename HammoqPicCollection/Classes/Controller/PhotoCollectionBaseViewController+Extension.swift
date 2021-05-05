//
//  PhotoCollectionBaseViewController+Extension.swift
//  HammoqPicCollection
//
//  Created by Paresh Nath Acharya on 05/05/21.
//

import Foundation
import UIKit

extension PhotoCollectionBaseViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionCell.reuseIdentifier, for: indexPath) as? PhotoCollectionCell else {
            return UICollectionViewCell()
        }
        cell.imageObject = imageArray[indexPath.row]
        cell.checkMark.isHidden = !isEditingMode
        cell.checkMark.setImageColor(color: .gray)
        cell.contentView.layer.borderWidth = 2.0
        cell.contentView.layer.borderColor = UIColor.green.cgColor
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widthNHeight = (collectionView.frame.size.width - padding * 2)/3
        return CGSize(width: widthNHeight, height: widthNHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionCell else {
            return
        }
        if selectedImageArray.contains(where: {$0.image_id == cell.imageObject?.image_id}) {
            selectedImageArray.removeAll(where: {$0.image_id == cell.imageObject?.image_id})
            cell.checkMark.setImageColor(color: UIColor.gray)
        } else {
            selectedImageArray.append(cell.imageObject!)
            cell.checkMark.setImageColor(color: UIColor.red)
        }
        if currentOperationType == OperationType.UPDATE {
            self.addAction()
        }
    }
}

extension PhotoCollectionBaseViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage), let imageData = image.jpegData(compressionQuality: 0.5) else {
            return
        }
        let searchDirectory = FileManager.SearchPathDirectory.documentDirectory
        let domainMask = FileManager.SearchPathDomainMask.userDomainMask
        
        var filePath = NSSearchPathForDirectoriesInDomains(searchDirectory, domainMask, true).first!
        filePath += "/image_temp.jpg"
        
        FileManager.default.createFile(atPath: filePath, contents: imageData, attributes: nil)
        FileManager.default.fileExists(atPath: filePath)
        isEditingMode = false
        if currentOperationType == OperationType.UPDATE {
            NetworkManager().deleteImage(imageId: (selectedImageArray.first?.image_id)!) { (isSuccess) in
                NetworkManager().uploadImage(image: image) { (isSuccess) in
                    self.view.isUserInteractionEnabled = true
                    var message = "Image updated Successfully"
                    if isSuccess == false {
                        message = "Error in image update"
                    }
                    _ = self.showAlert(title: "", message: message, actions: ["Ok"]) { (_) in
                        if isSuccess {
                            self.getImages()
                        }
                    }
                }
            }
        } else {
            NetworkManager().uploadImage(image: image) { (isSuccess) in
                self.view.isUserInteractionEnabled = true
                var message = "Uploaded Successfully"
                if isSuccess == false {
                    message = "Error in upload"
                }
                _ = self.showAlert(title: "", message: message, actions: ["Ok"]) { (_) in
                    if isSuccess {
                        self.getImages()
                    }
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)

    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.view.isUserInteractionEnabled = true
            self.currentOperationType = OperationType.NONE
        }
    }
    
    
}

extension UIViewController {
    func showAlert(title: String, message: String, actions: [String], completion: ((_ index: Int) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                
        for (index, action) in actions.enumerated() {
            let action = UIAlertAction(title: action, style: .default, handler: { _ in
                if completion != nil { completion?(index) }
            })
            alert.addAction(action)
        }
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        return alert
    }
}
