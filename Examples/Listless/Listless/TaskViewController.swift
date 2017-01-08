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
        task.text = contentTextView.text
        
        let newList = TagList(fromText: tagsTextField.text ?? "")
        if (task.tagList != newList) {
            task.tagList = newList
        }
    }
}
