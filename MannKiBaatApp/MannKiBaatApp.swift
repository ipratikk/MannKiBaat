//
//  MannKiBaatApp.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI
import SwiftData
import MannKiBaat
import SharedModels

@main
struct MannKiBaatApp: App {
    var body: some Scene {
        WindowGroup {
            AppEntryView()
        }
        .modelContainer(for: [NoteModel.self])
    }
}
