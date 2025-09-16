//
//  CurrencyService.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 17/09/25.
//


import SwiftData
import Foundation

public enum CurrencyService {
    public static func fetchExchangeRate(from currency: String, to target: String = "INR", date: Date = Date()) async -> Double {
        guard currency != target else { return 1.0 }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        guard let url = URL(string: "https://api.frankfurter.app/\(dateString)?from=\(currency)&to=\(target)") else {
            return 1.0
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rates = json["rates"] as? [String: Double],
               let value = rates[target] {
                return value
            }
        } catch {
            print("⚠️ Failed to fetch exchange rate: \(error)")
        }
        return 1.0
    }
    
    public static func fetchLatestUSDToINR() async throws -> Double {
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=USD&to=INR") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let rates = json["rates"] as? [String: Double],
           let value = rates["INR"] {
            return value
        }
        throw URLError(.badServerResponse)
    }
    
    public static func refreshMissingRates(in context: ModelContext) async -> Int {
        let descriptor = FetchDescriptor<Spend>(
            predicate: #Predicate { $0.exchangeRateToINR == 1.0 && $0.currency != "INR" }
        )
        
        guard let spends = try? context.fetch(descriptor), !spends.isEmpty else {
            return 0
        }
        
        var updatedCount = 0
        for spend in spends {
            let rate = await fetchExchangeRate(from: spend.currency, to: "INR", date: spend.date)
            if rate != 1.0 {
                spend.exchangeRateToINR = rate
                updatedCount += 1
            }
        }
        
        try? context.save()
        return updatedCount
    }
}
