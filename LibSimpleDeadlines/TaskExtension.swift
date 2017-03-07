//
//  TaskExtension.swift
//  LibSimpleDeadlines
//
//  Created by Edric MILARET on 17-02-14.
//  Copyright © 2017 Edric MILARET. All rights reserved.
//

import Foundation

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
            return UIColor(red:0.80, green:0.00, blue:0.00, alpha:1.0)
        case .URGENT:
            return UIColor(red:1.00, green:0.53, blue:0.00, alpha:1.0)
        case .WORRYING:
            return UIColor(red:0.80, green:0.80, blue:0.00, alpha:1.0)
        case .NICE:
            return UIColor(red:0.00, green:0.80, blue:0.00, alpha:1.0)
        default:
            return UIColor(red:0.00, green:0.00, blue:0.80, alpha:1.0)
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
