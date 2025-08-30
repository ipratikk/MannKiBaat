//
//  NoteModel.swift
//  MannKiBaat
//

import SwiftData
import Foundation
internal import UIKit

@Model
public class NoteModel: Identifiable {
    @Attribute public var id: UUID = UUID()
    @Attribute public var title: String = ""
    @Attribute public var createdAt: Date = Date()
    @Attribute public var tags: Set<String> = []

    // Store rich text as Data
    @Attribute public var richTextData: Data = NSAttributedString(string: "").archivedData()

    public init(
        id: UUID = UUID(),
        title: String = "",
        createdAt: Date = Date(),
        tags: Set<String> = [],
        richTextData: Data = Data()
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.tags = tags
        if richTextData.isEmpty {
            self.richTextData = NSAttributedString(string: "").archivedData()
        } else {
            self.richTextData = richTextData
        }
    }

    public var attributedContent: NSAttributedString {
        get { NSAttributedString.unarchive(data: richTextData) }
        set { richTextData = newValue.archivedData() }
    }
}

// MARK: - NSAttributedString archiving helpers
extension NSAttributedString {
    func archivedData() -> Data {
        try! self.data(from: NSRange(location: 0, length: length),
                       documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd])
    }

    static func unarchive(data: Data) -> NSAttributedString {
        try! NSAttributedString(data: data,
                                 options: [.documentType: NSAttributedString.DocumentType.rtfd],
                                 documentAttributes: nil)
    }
}
