//
//  TasksService.swift
//  LibSimpleDeadlines
//
//  Created by Edric MILARET on 17-01-12.
//  Copyright © 2017 Edric MILARET. All rights reserved.
//

import Foundation
import AERecord
import DateHelper

public protocol TaskEventsDelegate {
    func onDoneOrDelete(taskID: String)
}

public class TasksService {
    
    // MARK: - Singleton
    public static var sharedInstance = TasksService()
    public var taskEventsDelegate: TaskEventsDelegate? = nil
    
    init() {
        let model: NSManagedObjectModel = AERecord.modelFromBundle(for: TasksService.self)
        let containerURL = FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.org.auroralab.Simple-Deadlines-Group")
        let storeURL = containerURL!.appendingPathComponent("db.sqlite")
        
        let options = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption: true]
        do {
            try AERecord.loadCoreDataStack(managedObjectModel: model, storeURL: storeURL, options: options)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    // MARK: - Public API
    
    public func getNewTask() -> Task {
        return Task.create()
    }
    
    public func markAsDone(task: Task) {
        task.isDone = !task.isDone
        if task.isDone {
            task.doneDate = Date()
        } else {
            task.doneDate = nil
        }
        taskEventsDelegate?.onDoneOrDelete(taskID: task.title!)
        AERecord.save()
    }
    
    public func markAsDone(objectID: String) {
        let url = URL(string: objectID)
        if let nsObjId = AERecord.storeCoordinator?.managedObjectID(forURIRepresentation: url!) {
            if let task = AERecord.Context.main.object(with: nsObjId) as? Task{
                markAsDone(task: task)
                taskEventsDelegate?.onDoneOrDelete(taskID: task.title!)
            }
        }
    }
    
    public func deleteTask(task: Task) {
        taskEventsDelegate?.onDoneOrDelete(taskID: task.title!)
        task.delete()
        AERecord.save()
    }
    
    public func save() {
        AERecord.save()
    }
    
    public func getOrCreateCategory(name: String) -> TaskCategory {
        return TaskCategory.firstOrCreate(with: ["name" : name.trimmingCharacters(in: .whitespacesAndNewlines)])
    }
    
    public func getAllCategory() -> [TaskCategory]? {
        return TaskCategory.all()
    }
    
    public func getNumberOfExpiredTask() -> Int {
        let now = Date().dateFor(.startOfDay)
        return Task.count(with: NSPredicate(format: "date <= %@ AND doneDate == nil", now as NSDate))
    }
    
    public func getTasks(undoneOnly: Bool = false, category: String? = nil) -> [Task] {
        var attributes: [AnyHashable: Any] = [:]
        if undoneOnly {
            attributes["isDone"] = false
        }
        if let category = category, category != "All" {
            attributes["category.name"] = category
        }
        if let response = Task.all(with: attributes, predicateType: .and, orderedBy: [NSSortDescriptor(key: "date", ascending: true)]) as? [Task] {
            return response
        } else {
            return []
        }
    }
    
    public func getFetchedResultsController(urgentOnly: Bool = false) -> NSFetchedResultsController<Task> {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        if urgentOnly {
            let now = Date()
            let threeDays = now.dateFor(.startOfDay).adjust(.day, offset: 3).dateFor(.endOfDay)
            fetchRequest.predicate = NSPredicate(format: "date <= %@ AND doneDate == nil",
                        threeDays as NSDate)
        } else {
            fetchRequest.predicate = getPredicate()
        }
        return NSFetchedResultsController<Task>(fetchRequest: fetchRequest, managedObjectContext: AERecord.Context.default, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    public func filterFetchedResultsByCategory(fetchedResultsController: NSFetchedResultsController<Task>, categoryName: String? = nil) {
        fetchedResultsController.fetchRequest.predicate = getPredicate(categoryName: categoryName)
        do {
            try fetchedResultsController.performFetch()
        } catch {
            //TODO
            print("ERROR")
        }
    }
    
    // MARK: Private API
    
    func getPredicate(categoryName: String? = nil) -> NSPredicate {
        let now = Date()
        let todayStart = now.dateFor(.startOfDay)
        let todayEnd = todayStart.dateFor(.endOfDay)
        if let categoryName = categoryName {
            return NSPredicate(format: "(doneDate >= %@ AND doneDate <= %@ AND category.name == %@) OR (doneDate == nil AND category.name == %@)",
                               todayStart as NSDate,
                               todayEnd as NSDate,
                               categoryName,
                               categoryName)
        } else {
            return NSPredicate(format: "(doneDate >= %@ AND doneDate <= %@) OR doneDate == nil",
                               todayStart as NSDate,
                               todayEnd as NSDate)
        }
    }
}
