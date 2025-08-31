//
//  Date+Extension.swift
//  SharedModels
//
//  Created by Pratik Goel on 31/08/25.
//

import Foundation

public extension Date {
    
        // MARK: - Relative Checks
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isYesterday() -> Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    func daysAgo() -> Int? {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let startOfSelf = Calendar.current.startOfDay(for: self)
        return Calendar.current.dateComponents([.day], from: startOfSelf, to: startOfToday).day
    }
    
        // MARK: - String Formatting
        /// For today/yesterday: shows time only, respecting 12/24-hour clock
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: self)
    }
    
        /// For notes within last 30 days: medium date style (e.g., Aug 31, 2025)
    func dayMonthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
        /// For grouping by month (current year)
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
    
        /// For grouping by year
    func yearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: self)
    }
}
