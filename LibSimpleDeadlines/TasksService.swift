//
//  TasksService.swift
//  LibSimpleDeadlines
//
//  Created by Edric MILARET on 17-01-12.
//  Copyright © 2017 Edric MILARET. All rights reserved.
//

import Foundation
import AERecord

public class TasksService {
    
    public static var sharedInstance = TasksService()
    
    init() {
        guard let modelURL = Bundle.main.url(forResource: "SimpleDeadlinesModel", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        let myStoreURL = AERecord.storeURL(for: "SimpleDeadlinesModel")
        let myOptions = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption: true]
        do {
            try AERecord.loadCoreDataStack(managedObjectModel: mom, storeURL: myStoreURL, options: myOptions)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
