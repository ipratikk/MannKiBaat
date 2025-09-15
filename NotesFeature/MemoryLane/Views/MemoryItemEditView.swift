import SwiftUI
import SwiftData
import SharedModels
import MapKit

@MainActor
public struct MemoryItemEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MemoryViewModel
    
    @Bindable var lane: MemoryLane
    @Bindable var item: MemoryItem
    
    @State private var title: String
    @State private var details: String
    @State private var date: Date
    @State private var location: CLLocationCoordinate2D?
    
    public init(item: MemoryItem,
                lane: MemoryLane,
                viewModel: MemoryViewModel) {
        self._item = Bindable(item)
        self._lane = Bindable(lane)
        self.viewModel = viewModel
        
        _title = State(initialValue: item.title)
        _details = State(initialValue: item.details)
        _date = State(initialValue: item.createdAt)
        _location = State(initialValue: {
            guard let lat = item.latitude, let lon = item.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }())
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $details)
                        .frame(minHeight: 100, maxHeight: 200)
                }
                
                Section(header: Text("Date")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Location")) {
                    if let loc = location {
                        HStack {
                            Text("Lat: \(loc.latitude.formatted()), Lon: \(loc.longitude.formatted())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Clear") { location = nil }
                        }
                    } else {
                        Button("Add Current Location") {
                            // Stub: replace with CoreLocation picker if desired
                            location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                        }
                    }
                }
                
                Section(header: Text("Picture")) {
                    Button("Add Photo") {
                        // Hook up PHPicker here if needed
                    }
                }
            }
            .navigationTitle(item.title.isEmpty ? "New Memory" : "Edit Memory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveItem() {
        item.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        item.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        item.createdAt = date
        
        if let loc = location {
            item.latitude = loc.latitude
            item.longitude = loc.longitude
        } else {
            item.latitude = nil
            item.longitude = nil
        }
        
        try? modelContext.save()
    }
}
