//
//  CurrencyCache.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 17/09/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class CurrencyCache: ObservableObject {
    public static let shared = CurrencyCache()
    private init() {
        Task { await refreshIfNeeded() }
    }
    
    @AppStorage("usdToInrRate") private var usdToInrRateValue: Double = 83.0
    @AppStorage("lastRateUpdate") private var lastRateUpdate: String = ""
    
    public var usdToInrRate: Double { usdToInrRateValue }
    
    public func refreshIfNeeded() async {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        guard today != lastRateUpdate else { return }
        
        do {
            let rate = try await CurrencyService.fetchLatestUSDToINR()
            usdToInrRateValue = rate
            lastRateUpdate = today
            print("💱 Updated USD→INR rate: \(rate)")
        } catch {
            print("⚠️ Failed to refresh rates: \(error)")
        }
    }
    
    public static func format(_ value: Double, currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currency
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    public func convertFromINR(_ amountINR: Double, to currency: String) -> Double {
        switch currency {
        case "USD":
            return amountINR / usdToInrRate
        default: return amountINR
        }
    }
    
    public func convertBudget(_ budgetINR: Double, to currency: String) -> Double {
        switch currency {
        case "USD":
            return budgetINR / usdToInrRate
        default: return budgetINR
        }
    }
    
    // ✅ New helper
    public func symbol(for currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.currencySymbol ?? currency
    }
}
