//
//  UIViewController+Extensions.swift
//  StrepScan
//
//  Created by Samuel Folledo on 7/27/20.
//  Copyright © 2020 SamuelFolledo. All rights reserved.
//

import UIKit.UIViewController
//import NVActivityIndicatorView

extension UIViewController {
    
    //takes a view and add
//    func startActivityIndicator(type: NVActivityIndicatorType = .ballClipRotateMultiple) {
//        Constants.Views.indicatorView.center = view.center
//        view.addSubview(Constants.Views.indicatorView)
//        Constants.Views.indicatorView.snp.makeConstraints { (make) in
//            make.centerX.equalToSuperview()
//            make.centerY.equalToSuperview()
//        }
//        UIView.animate(withDuration: 0.2) {
//            self.view.isUserInteractionEnabled = false
//            Constants.Views.indicatorView.startAnimating()
//        }
//    }
//    
//    func stopActivityIndicator() {
//        UIView.animate(withDuration: 0.2) {
//            self.view.isUserInteractionEnabled = true
//        }
//        self.view.isUserInteractionEnabled = true
//        Constants.Views.indicatorView.stopAnimating()
//        Constants.Views.indicatorView.removeFromSuperview()
//    }
    
    ///Transparent Navigation Bar
    func transparentNavigationBar() {
        // Make the navigation bar background clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.backgroundColor = .clear
    }
    
    func removeTransparentNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }
    
    ///remove keyboard when view is tapped
    func hideKeyboardOnTap() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func presentAlert(title: String, message: String = "") {
      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
      alertController.addAction(OKAction)
      self.present(alertController, animated: true, completion: nil)
    }
    
    func presentAlertWithTextField(title:String? = nil,
                         subtitle:String? = nil,
                         actionTitle:String? = "Confirm",
                         cancelTitle:String? = "Cancel",
                         inputPlaceholder:String? = nil,
                         inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                         inputKeyboardAutoCapitalizationType: UITextAutocapitalizationType = .none,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
            textField.autocapitalizationType = inputKeyboardAutoCapitalizationType
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))
        self.present(alert, animated: true, completion: nil)
    }
}
