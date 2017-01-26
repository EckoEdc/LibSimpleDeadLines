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

extension Task {
    
    public enum State {
        case TODAY
        case URGENT
        case WORRYING
        case NICE
        case NEVERMIND
    }
    
    
    public func getStatus(remainingDays: Int? = nil) -> State {
        
        var remain = 0
        if remainingDays == nil {
            remain = getDaysBeforeEnd()
        } else {
            remain = remainingDays!
        }
        
        switch remain {
        case Int.min...1:
            return .TODAY
        case 2...3:
            return .URGENT
        case 4...7:
            return .WORRYING
        case 8...15:
            return .NICE
        default:
            return .NEVERMIND
        }
    }
    
    public func getCircleColor(remainingDays: Int? = nil) -> UIColor {
        
        let status = getStatus(remainingDays: remainingDays)
        switch status {
        case.TODAY:
            return UIColor.red
        case .URGENT:
            return UIColor.orange
        case .WORRYING:
            return UIColor.yellow
        case .NICE:
            return UIColor.green
        default:
            return UIColor.blue
        }
    }
    
    public func getDaysBeforeEnd() -> Int {
        guard date != nil else {return 0}
        
        let now = Date()
        let today = now.dateAtStartOfDay()

        let remainingDays = NSCalendar.current.dateComponents(
            [Calendar.Component.day],
            from: today,
            to: (date as! Date).dateAtStartOfDay())
        return remainingDays.day!
    }
    
    public func getRemainingDaysAndColor() -> (Int, UIColor) {
        let remainingDays = getDaysBeforeEnd()
        let color = getCircleColor(remainingDays: remainingDays)
        return (remainingDays, color)
    }
    
    public func toSimpleMessage() -> [String: Any] {
        let daysLeft = getDaysBeforeEnd()
        let colorData = NSKeyedArchiver.archivedData(withRootObject: self.getCircleColor(remainingDays: daysLeft))
        return ["title": self.title, "category" : category?.name ?? "", "color": colorData, "daysLeft": String(daysLeft), "id" : self.objectID.uriRepresentation().absoluteString]
    }
}

public class TasksService {
    
    public static var sharedInstance = TasksService()
    
    init() {
        let model: NSManagedObjectModel = AERecord.modelFromBundle(for: TasksService.self)
        let containerURL = FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.org.auroralab.Simple-Deadlines")
        let storeURL = containerURL!.appendingPathComponent("db.sqlite")
        
        let options = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption: true]
        do {
            try AERecord.loadCoreDataStack(managedObjectModel: model, storeURL: storeURL, options: options)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public func getNewTask() -> Task {
        return Task.create()
    }
    
    public func markAsDone(task: Task) {
        task.isDone = !task.isDone
        if task.isDone {
            task.doneDate = Date() as NSDate
        } else {
            task.doneDate = nil
        }
        AERecord.save()
    }
    
    public func markAsDone(objectID: String) {
        let url = URL(string: objectID)
        if let nsObjId = AERecord.storeCoordinator?.managedObjectID(forURIRepresentation: url!) {
            if let task = AERecord.Context.main.object(with: nsObjId) as? Task{
                markAsDone(task: task)
            }
        }
    }
    
    public func deleteTask(task: Task) {
        task.delete()
        AERecord.save()
    }
    
    public func save() {
        AERecord.save()
    }
    
    public func getCategory(name: String) -> TaskCategory {
        return TaskCategory.firstOrCreate(with: ["name" : name])
    }
    
    public func getAllCategory() -> [TaskCategory]? {
        return TaskCategory.all()
    }
    
    public func getTasks(undoneOnly: Bool = false) -> [Task] {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        if undoneOnly {
            fetchRequest.predicate = NSPredicate(format: "isDone == false")
        }
        let fetchedTasks = AERecord.execute(fetchRequest: fetchRequest)
        return fetchedTasks
    }
    
    public func getFetchedResultsController(urgentOnly: Bool = false) -> NSFetchedResultsController<Task> {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        if urgentOnly {
            let now = Date()
            let threeDays = now.dateAtStartOfDay().dateByAddingDays(3).dateAtEndOfDay()
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
    
    // MARK: Private func
    
    func getPredicate(categoryName: String? = nil) -> NSPredicate {
        let now = Date()
        let todayStart = now.dateAtStartOfDay()
        let todayEnd = todayStart.dateAtEndOfDay()
        if let categoryName = categoryName {
            return NSPredicate(format: "(doneDate >= %@ AND doneDate <= %@ AND category.name == %@) OR (doneDate == nil AND category.name == %@)"
                , todayStart as NSDate,
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
