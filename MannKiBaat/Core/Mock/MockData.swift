//
//  MockData.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 14/04/26.
//

import Foundation

struct MockData: Decodable {
    let notes: [MockNote]
}

struct MockNote: Decodable {
    let title: String
    let createdAt: Date
}
