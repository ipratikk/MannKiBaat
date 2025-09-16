//
//  Spend.swift
//  SharedModels
//

import SwiftData
import Foundation

@Model
public class Spend {
    public var id: UUID = UUID()
    public var amount: Double = 0.0
    public var currency: String = "INR"
    public var date: Date = Date()
    public var exchangeRateToINR: Double = 1.0
    
    public var category: SpendCategory?
    
    public var receiptImageData: Data? = nil
    
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
