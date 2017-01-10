//
//  TaskViewController.swift
//  Listless
//
//  Created by Drew McCormack on 07/01/2017.
//  Copyright © 2017 The Mental Faculty B.V. All rights reserved.
//

import UIKit

class TaskViewController: UIViewController {
    
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var tagsTextField: UITextField!
    
    var task: Task!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contentTextView.text = task.text
        tagsTextField.text = task.tagList.asString
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard task != nil else { return }
        
        task.text = contentTextView.text
        
        let newList = TagList(fromText: tagsTextField.text ?? "")
        if (task.tagList != newList) {
            task.tagList = newList
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        task = nil
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func commit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
