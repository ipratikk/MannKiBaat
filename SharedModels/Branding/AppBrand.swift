//
//  AppBrand.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 14/04/26.
//


import Foundation

public protocol AppBrand {
    
    // Identity
    var appName: String { get }
    
    // Login
    var loginGreeting: String { get }
    var loginSubtitle: String { get }
    
    // Notes
    var notesTitle: String { get }
    var emptyStateMessage: String { get }
    
    // Defaults
    var defaultNoteTitle: String { get }
}
