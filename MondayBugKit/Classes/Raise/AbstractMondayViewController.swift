//
//  AbstractMondayViewController.swift
//  MondayBugKit
//
//  Created by Will Powell on 30/11/2020.
//

import Foundation

open class AbstractMondayViewController : UIViewController{
    var tapGestureRecognizer: UITapGestureRecognizer!

    override open func viewDidLoad() {

        // Instantiate gesture recognizer
        tapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(self.navigationBarTapped(_:)))
    }

    override open func viewWillAppear(_ animated: Bool) {

        // Add gesture recognizer to the navigation bar when the view is about to appear
        self.navigationController?.navigationBar.addGestureRecognizer(tapGestureRecognizer)

        // This allows controlls in the navigation bar to continue receiving touches
        tapGestureRecognizer.cancelsTouchesInView = false
    }

    override open func viewWillDisappear(_ animated: Bool) {

        // Remove gesture recognizer from navigation bar when view is about to disappear
        self.navigationController?.navigationBar.removeGestureRecognizer(tapGestureRecognizer)
    }

    // Action called when navigation bar is tapped anywhere
    @objc open func navigationBarTapped(_ sender: UITapGestureRecognizer){

        // Make sure that a button is not tapped.
        let location = sender.location(in: self.navigationController?.navigationBar)
        let hitView = self.navigationController?.navigationBar.hitTest(location, with: nil)

        guard !(hitView is UIControl) else { return }

        // Here, we know that the user wanted to tap the navigation bar and not a control inside it
        print("Navigation bar tapped")
        let alert = UIAlertController(title: "", message: "Raise a bug", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Raise", style: .default, handler: { (alert) in
            MondayBugKit.context.raiseBug(self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (alert) in
            MondayBugKit.context.raiseBug(self)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
