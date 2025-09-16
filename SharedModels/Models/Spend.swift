//
//  Spend.swift
//  SharedModels
//

import SwiftData
import Foundation

@Model
public class Spend {
    @Attribute(.unique) public var id: UUID
    public var amount: Double
    public var currency: String   // "INR" or "USD"
    public var date: Date
    @Relationship public var category: SpendCategory?   // ✅ Reference
    public var receiptImageData: Data?
    public var exchangeRateToINR: Double
    
    public init(
        amount: Double,
        currency: String,
        date: Date,
        category: SpendCategory?,
        receiptImageData: Data? = nil,
        exchangeRateToINR: Double = 1.0
    ) {
        self.id = UUID()
        self.amount = amount
        self.currency = currency
        self.date = date
        self.category = category
        self.receiptImageData = receiptImageData
        self.exchangeRateToINR = exchangeRateToINR
    }
}
