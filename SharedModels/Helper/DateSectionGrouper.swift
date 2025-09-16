//
//  DateSectionGrouper.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 16/09/25.
//

import Foundation

public enum DateSectionGrouper {
    public static func sectionTitle(for date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        
        if date.isToday() {
            return "Today"
        } else if date.isYesterday() {
            return "Yesterday"
        } else if let daysAgo = date.daysAgo() {
            if daysAgo <= 7 {
                return "This Week"
            } else if daysAgo <= 30 {
                return "Last 30 Days"
            }
        }
        
        if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            return date.monthYearString()
        } else {
            return date.yearString()
        }
    }
    
    public static func sectionSort(_ a: String, _ b: String) -> Bool {
        let fixedOrder: [String] = ["Today", "Yesterday", "This Week", "Last 30 Days"]
        if fixedOrder.contains(a), fixedOrder.contains(b) {
            return fixedOrder.firstIndex(of: a)! < fixedOrder.firstIndex(of: b)!
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        if let dateA = formatter.date(from: a), let dateB = formatter.date(from: b) {
            return dateA > dateB
        }
        
        if let yearA = Int(a), let yearB = Int(b) {
            return yearA > yearB
        }
        
        return a > b
    }
}
