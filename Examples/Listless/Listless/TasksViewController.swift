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
        if let taskController = self.presentedViewController as? TaskViewController {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            var task = taskController.task!
            appDelegate.localRepository.save(&task)
            taskList!.tasks[tableView.indexPathForSelectedRow!.row] = task
        }
        
        super.viewWillAppear(animated)
    }
    
    @IBAction func add() {
        guard taskList != nil else { return }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let newTask = Task()
        taskList!.tasks.insert(newTask, at: 0)
        appDelegate.localRepository.save(&taskList!)
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
            let c = segue.destination as! TaskViewController
            c.task = taskList!.tasks[tableView.indexPathForSelectedRow!.row]
        }
    }

}
