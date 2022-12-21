//
//  DetailViewController.swift
//  PlayerScoutBook
//
//  Created by 김남주 on 2022/12/03.
//

import UIKit
import PhotosUI
import CoreData

class DetailViewController: UIViewController {
    
    // Views
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nationTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var positionTextField: UITextField!
    @IBOutlet weak var strengthTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var containerView: UIView!
    
    let textViewPlaceholder = "Strength"
    
    // Seguge Variable
    
    var chosenPlayerId: UUID?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - Retreive Player Data
        if chosenPlayerId != nil {
            // player data
            
            let stringUUID = chosenPlayerId!.uuidString
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Player")
            
            fetchRequest.returnsObjectsAsFaults = false
            // filter id
            fetchRequest.predicate = NSPredicate(format: "id = %@", stringUUID)
            
            do {
                let results = try context.fetch(fetchRequest)
                if !results.isEmpty {
                    if let result = results.first as? NSManagedObject {
                        nameTextField.text = result.value(forKey: "name") as? String
                        nationTextField.text = result.value(forKey: "nation") as? String
                        ageTextField.text = String(result.value(forKey: "age") as! Int)
                        positionTextField.text = result.value(forKey: "position") as? String
                        strengthTextView.text = result.value(forKey: "strength") as? String
                        
                        if let imageData = result.value(forKey: "image") as? Data {
                            let image = UIImage(data: imageData)
                            profileImageView.image = image
                        }
                    }
                }
            } catch {
                let alertController = UIAlertController(title: "불러오기 실패", message: "선수 데이터를 불러오는데 실패했습니다.", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "확인", style: .default)
                alertController.addAction(alertAction)
                
                self.present(alertController, animated: true)
            }
            
        } else {
            nameTextField.text = nil
            profileImageView.image = UIImage(named: "image-placeholder")
            nationTextField.text = nil
            ageTextField.text = nil
            positionTextField.text = nil
            strengthTextView.text = nil
        }
 
        profileImageView.layer.cornerRadius = 16
        
        strengthTextView.delegate = self
        if strengthTextView.text.isEmpty {
            strengthTextView.text = textViewPlaceholder
            strengthTextView.textColor = .lightGray
        }
        strengthTextView.layer.borderColor = .init(gray: 2/3, alpha: 1.0)
        strengthTextView.layer.borderWidth = 0.5
        strengthTextView.layer.cornerRadius = 16

        let hideKeyboardGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        
        self.view.addGestureRecognizer(hideKeyboardGestureRecognizer)
        
        let imagePickerGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pickImage))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(imagePickerGestureRecognizer)
    }
    
    // MARK: - pickImage

    @objc func pickImage() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        
        picker.delegate = self
        
        self.present(picker, animated: true, completion: nil)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    
    // MARK: - isValidate

    /// 입력한 필드 값이 유효한지 확인
    /// - Returns: 필드값이 유효하면 ``true``를 반환
    func isValidate() -> Bool {
        if nameTextField.text?.isEmpty ?? true || nameTextField.text?.isEmpty ?? true || ageTextField.text?.isEmpty ?? true ||
            positionTextField.text?.isEmpty ?? true ||
            strengthTextView.text?.isEmpty ?? true {
            return false
        }
        
        return true
    }
    
    // MARK: - saveClicked
    @IBAction func saveClicked(_ sender: Any) {
        
        // 필드 값이 유효하지 않으면
        if !isValidate() {
            let alertController = UIAlertController(title: "빈 필드", message: "모든 필드에 값을 입력해주세요", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "확인", style: .default)
            alertController.addAction(alertAction)
            
            self.present(alertController, animated: true)
            return
        }
        
        // Core Data 저장
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // 새 선수를 추가하는 경우
        if chosenPlayerId == nil {
            let newPlayer = NSEntityDescription.insertNewObject(forEntityName: "Player", into: context)
            
            newPlayer.setValue(UUID(), forKey: "id")
            newPlayer.setValue(nameTextField.text!, forKey: "name")
            newPlayer.setValue(nationTextField.text!, forKey: "nation")
            newPlayer.setValue(Int(ageTextField.text!), forKey: "age")
            newPlayer.setValue(positionTextField.text!, forKey: "position")
            newPlayer.setValue(strengthTextView.text!, forKey: "strength")
            
            let jepgImageData = profileImageView.image?.jpegData(compressionQuality: 0.5)
            
            newPlayer.setValue(jepgImageData, forKey: "image")
        } else {
            // 기존에 있던 선수 정보를 수정하는 경우
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Player")
            let stringUUID = chosenPlayerId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", stringUUID)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let result = results.first as? NSManagedObject {
                    result.setValue(nameTextField.text!, forKey: "name")
                    result.setValue(nationTextField.text!, forKey: "nation")
                    result.setValue(Int(ageTextField.text!), forKey: "age")
                    result.setValue(positionTextField.text!, forKey: "position")
                    result.setValue(strengthTextView.text!, forKey: "strength")
                    
                    let jpegImageData = profileImageView.image?.jpegData(compressionQuality: 0.5)
                    
                    result.setValue(jpegImageData, forKey: "image")
                }
            } catch {
                
            }
        }
        
        do {
            try context.save()
            
            // ViewController에 데이터 갱신 메세지 전달
            NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)
            
            self.navigationController?.popViewController(animated: true)
            
        } catch {
            let alertController = UIAlertController(title: "저장 오류", message: "저장에 실패했습니다. 다시 시도해주세요", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "확인", style: .default)
            alertController.addAction(alertAction)
            
            self.present(alertController, animated: true)
        }
    }
    
    
}

// MARK: - PHPickerViewControllerDelegate

extension DetailViewController: PHPickerViewControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let itemProvider = results.first?.itemProvider
        
        if let itemProvider = itemProvider,
           itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    self.profileImageView.image = image as? UIImage
                }
            }
        }
    }
    
}

// MARK: - UITextViewDelegate

extension DetailViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == textViewPlaceholder {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = textViewPlaceholder
            textView.textColor = .lightGray
        }
    }
}
