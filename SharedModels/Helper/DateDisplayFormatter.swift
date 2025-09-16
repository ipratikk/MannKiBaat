//
//  DateDisplayFormatter.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 17/09/25.
//

import Foundation

public enum DateDisplayFormatter {
    
    /// Returns a compact display string for row-level dates
    public static func formattedRowDate(_ date: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        
        if cal.isDateInToday(date) {
            return date.timeString()
        }
        if cal.isDateInYesterday(date) {
            return date.timeString()
        }
        if let days = date.daysAgo(), days <= 30 {
            return date.dayMonthYearString()
        }
        if cal.component(.year, from: date) == cal.component(.year, from: now) {
            return date.monthYearString()
        }
        return date.yearString()
    }
    
    /// Returns a longer version, if needed for detail screens
    public static func formattedDetailDate(_ date: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        
        if cal.isDateInToday(date) {
            return "Today at \(date.timeString())"
        }
        if cal.isDateInYesterday(date) {
            return "Yesterday at \(date.timeString())"
        }
        if let days = date.daysAgo(), days <= 30 {
            return date.dayMonthYearString() + " at \(date.timeString())"
        }
        if cal.component(.year, from: date) == cal.component(.year, from: now) {
            return date.dayMonthYearString()
        }
        return date.monthYearString() + " \(date.yearString())"
    }
}
