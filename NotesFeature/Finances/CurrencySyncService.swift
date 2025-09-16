//
//  CurrencySyncService.swift
//  SpendsFeature
//

import SwiftUI
import Combine

@MainActor
public final class CurrencySyncService: ObservableObject {
    public static let shared = CurrencySyncService()
    private init() {}
    
    // MARK: - Stored Properties
    @AppStorage("budgetAmount") public var budgetAmount: Double = 0
    @AppStorage("budgetCurrency") public var budgetCurrency: String = "INR" {
        didSet { sync() }
    }
    @AppStorage("budgetPeriod") public var budgetPeriodRaw: String = PeriodFilter.month.rawValue
    @AppStorage("displayCurrency") public var displayCurrency: String = "INR" {
        didSet { sync() }
    }
    
    // MARK: - Derived
    public var budgetPeriod: PeriodFilter {
        PeriodFilter(rawValue: budgetPeriodRaw) ?? .month
    }
    
    // MARK: - Sync Logic
    /// Ensures display currency always follows budget currency.
    public func sync() {
        if budgetCurrency != displayCurrency {
            displayCurrency = budgetCurrency
        }
    }
    
    /// Updates both budget + display currency at once.
    public func updateCurrency(to newValue: String) {
        budgetCurrency = newValue
        displayCurrency = newValue
    }
}
