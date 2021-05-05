//
//  PhotoCollectionBaseViewController.swift
//  HammoqPicCollection
//
//  Created by Paresh Nath Acharya on 04/05/21.
//

import Foundation
import UIKit
import AVFoundation

enum OperationType: String {
    case ADD
    case UPDATE
    case DELETE
    case NONE
}

class PhotoCollectionBaseViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    
    let padding: CGFloat = 10.0
    var imageArray = [ImageObject]()
    var isEditingMode: Bool = false {
        didSet {
            updateEditButton()
        }
    }
    
    override var isEditing: Bool {
        didSet {
            print(isEditing)
        }
    }
    
    var currentOperationType = OperationType.NONE
    var selectedImageArray = [ImageObject]()
    var editButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let rightButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItem.Style.plain, target: self, action: #selector(editButtonAction))
        self.navigationItem.rightBarButtonItem = rightButton
        self.registerCell()
        self.getImages()
    }
    
    func getImages() {
//        isEditingMode = false
        NetworkManager().downloadImge { (result, error) in
            self.currentOperationType = OperationType.NONE
            guard error == nil else {
                // show alert
                return
            }
            if let data = result {
                self.imageArray = data
                self.refreshScreen()
            }
        }
    }
    
    func registerCell() {
        self.photoCollectionView.register(UINib(nibName: PhotoCollectionCell.nibName, bundle: nil), forCellWithReuseIdentifier: PhotoCollectionCell.reuseIdentifier)
    }
    
    @objc
    @IBAction func editButtonAction(_ sender: Any) {
        if isEditingMode {
            isEditingMode = false
            
            if selectedImageArray.count > 0 {
                NetworkManager().deleteImages(imageIds: selectedImageArray.compactMap({$0.image_id})) { (isSuccess) in
                    var message = "Deleted Successfully"
                    if isSuccess == false {
                        message = "Error in deletion"
                    }
                    self.selectedImageArray.removeAll()
                    _ = self.showAlert(title: "", message: message, actions: ["Ok"]) { (_) in
                        self.getImages()
                    }
                }
            } else {
                self.refreshScreen()
            }
            
            return
        }
        
        let actionSheet = UIAlertController(title: "", message: "Edit mode", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Add Image", style: UIAlertAction.Style.default, handler: { (action) in
            self.currentOperationType = OperationType.ADD
            self.addAction()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Modify Image", style: .default, handler: { (action) in
            self.isEditingMode = true
            self.currentOperationType = OperationType.UPDATE
            self.refreshScreen()
            actionSheet.dismiss(animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Delete Image", style: .default, handler: { (action) in
            self.isEditingMode = true
            self.currentOperationType = OperationType.DELETE
            self.refreshScreen()
            actionSheet.dismiss(animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            self.currentOperationType = OperationType.NONE
        }))

        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func addAction() {
        let actionSheet = UIAlertController(title: "", message: "Choose Image from below options", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: UIAlertAction.Style.default, handler: { (action) in
            // Open Gallery
            self.openGallery()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            // Open Camera
            self.checkCameraAccess()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(actionSheet, animated: true, completion: nil)

    }
    
    private func openGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }

    func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            print("Denied, request permission from settings")
            presentCameraSettings()
        case .restricted:
            print("Restricted, device owner must approve")
        case .authorized:
            print("Authorized, proceed")
            self.openCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                if success {
                    print("Permission granted, proceed")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.openCamera()
                    }
                } else {
                    print("Permission denied")
                }
            }
        @unknown default:
            fatalError()
        }
    }
    
    func presentCameraSettings() {
        let alertController = UIAlertController(title: "Permission Required",
                                      message: "Camera permission is required to capture image. Kindly provide the permission from Settings.",
                                      preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Deny", style: .default))
        alertController.addAction(UIAlertAction(title: "Allow", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: { (_) in
                })
            }
        })
        present(alertController, animated: true)
    }
    
    // MARK: - Choose image from camera roll
    private func openCamera() {
        DispatchQueue.main.async {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
      }
    }
    
    func addEditButton() {
        editButton.frame = CGRect(x: 0, y: -10, width: 45, height: 30)
        editButton.imageView?.contentMode = .scaleAspectFit
        editButton.addTarget(self, action: #selector(editButtonAction), for: .touchUpInside)
        editButton.setTitle("Edit", for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
        let viewRightItem = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        viewRightItem.addSubview(editButton)
        editButton.center.x = viewRightItem.center.x
        
        // Setup the right Navigation Item
        let rightBarButton = UIBarButtonItem(customView: viewRightItem)
        navigationItem.rightBarButtonItems = [rightBarButton]
    }
    
    func updateEditButton() {
        if(self.isEditing == true) {
            self.isEditing = false
            self.navigationItem.rightBarButtonItem?.title = "Edit"
        } else {
            self.isEditing = true
            self.navigationItem.rightBarButtonItem?.title = "Done"
        }
    }
    
    func refreshScreen() {
        DispatchQueue.main.async {
            self.photoCollectionView.reloadData()
        }
    }
}
