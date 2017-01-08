//
//  TasksViewController.swift
//  Listless
//
//  Created by Drew McCormack on 07/01/2017.
//  Copyright © 2017 The Mental Faculty B.V. All rights reserved.
//

import UIKit

class TasksViewController: UITableViewController {
    
    var taskList: TaskList? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if  let navController = self.presentedViewController as? UINavigationController,
            let taskController = navController.topViewController as? TaskViewController,
            var task = taskController.task {
            // Save and sync
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.localRepository.save(&task)
            appDelegate.sync()
            
            // In case the edited task hss moved due to a sync, use the identifier to find the right index
            let identifiers = taskList!.tasks.map({ $0.metadata.uniqueIdentifier })
            if let editedRow = identifiers.index(of: task.metadata.uniqueIdentifier) {
                taskList!.tasks[editedRow] = task
            }
        }
    }
    
    @IBAction func add(_ sender: Any?) {
        guard taskList != nil else { return }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let newTask = Task()
        taskList!.tasks.insert(newTask, at: 0)
        appDelegate.localRepository.save(&taskList!)
        
        let path = IndexPath(row: 0, section: 0)
        tableView.selectRow(at: path, animated: true, scrollPosition: .none)
        performSegue(withIdentifier: "toTask", sender: self)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskList?.tasks.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = taskList!.tasks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell", for: indexPath) as! TaskCell
        cell.contentLabel.text = task.text
        cell.tagsLabel.text = task.tagList.asString
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTask" {
            let navController = segue.destination as! UINavigationController
            let c = navController.topViewController as! TaskViewController
            c.task = taskList!.tasks[tableView.indexPathForSelectedRow!.row]
        }
    }

}
