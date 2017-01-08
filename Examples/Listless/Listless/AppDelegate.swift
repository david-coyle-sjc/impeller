//
//  AppDelegate.swift
//  Listless
//
//  Created by Drew McCormack on 07/01/2017.
//  Copyright © 2017 The Mental Faculty B.V. All rights reserved.
//

import UIKit
import Impeller
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var tasksViewController: TasksViewController!
    
    let localRepository = MemoryRepository()
    let cloudRepository = CloudKitRepository(withUniqueIdentifier: "Main", cloudDatabase: CKContainer.default().privateCloudDatabase)
    lazy var exchange: Exchange = { Exchange(coupling: [self.localRepository, self.cloudRepository], pathForSavedState: nil) }()
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        let navController = window!.rootViewController as! UINavigationController
        tasksViewController = navController.topViewController as! TasksViewController
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        sync()
    }
    
    @IBAction func sync() {
        exchange.exchange { error in
            if let error = error {
                print("Error during exchange: \(error)")
            }
            else {
                self.updateTaskList()
            }
        }
    }
    
    func updateTaskList() {
        if let taskList: TaskList = self.localRepository.fetchValue(identifiedBy: "MainList") {
            // Update the task list if it is changed
            if taskList != self.tasksViewController.taskList {
                self.tasksViewController.taskList = taskList
            }
        }
        else {
            // Create a new task list if one doesn't exist
            var newTaskList = TaskList()
            newTaskList.metadata = Metadata(uniqueIdentifier: "MainList")
            self.localRepository.save(&newTaskList)
            self.tasksViewController.taskList = newTaskList
            
            // Schedule a sync to push this new list to the cloud
            DispatchQueue.main.async { self.sync() }
        }
    }

}

