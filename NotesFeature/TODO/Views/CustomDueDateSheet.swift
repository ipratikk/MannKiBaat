//
//  CustomDueDateSheet.swift
//

import SwiftUI
import SharedModels

public struct CustomDueDateSheet: View {
    @Binding var dueDate: Date?
    @Binding var reminderEnabled: Bool
    @Binding var reminderMinutesBefore: Int
    @Binding var isPresented: Bool
    
    @State private var enableDate: Bool = false
    @State private var enableTime: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showTimePicker: Bool = false
    @State private var showReminder: Bool = false
    
    @State private var tempDate = Date()
    
    public init(
        dueDate: Binding<Date?>,
        reminderEnabled: Binding<Bool>,
        reminderMinutesBefore: Binding<Int>,
        isPresented: Binding<Bool>
    ) {
        self._dueDate = dueDate
        self._reminderEnabled = reminderEnabled
        self._reminderMinutesBefore = reminderMinutesBefore
        self._isPresented = isPresented
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                GradientBackgroundView()
                List {
                    // Date row (no Section)
                    Button {
                        if enableDate {
                            showDatePicker.toggle()
                            if showDatePicker {
                                showTimePicker = false
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                            VStack(alignment: .leading) {
                                Text("Date")
                                if let due = enableDate ? tempDate : nil {
                                    Text(due.formattedRelativeOrDate())
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { enableDate },
                                set: { newValue in
                                    if newValue {
                                        enableDate = true
                                        showDatePicker = true
                                        showReminder = true
                                        reminderEnabled = false
                                    } else {
                                        enableDate = false
                                        enableTime = false
                                        showDatePicker = false
                                        showTimePicker = false
                                        reminderEnabled = false
                                        showReminder = false
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if showDatePicker && !showTimePicker {
                        DatePicker(
                            "",
                            selection: $tempDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                    }
                    
                    // Time row (no Section)
                    Button {
                        if enableTime {
                            showTimePicker.toggle()
                            if showTimePicker {
                                showDatePicker = false
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "clock")
                            VStack(alignment: .leading) {
                                Text("Time")
                                if enableTime {
                                    Text(tempDate.formattedTime())
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { enableTime },
                                set: { newValue in
                                    if newValue {
                                        enableTime = true
                                        enableDate = true
                                        showDatePicker = false
                                        showTimePicker = true
                                    } else {
                                        enableTime = false
                                        showTimePicker = false
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if showTimePicker {
                        DatePicker(
                            "",
                            selection: $tempDate,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    }
                    
                    // Reminder row
                    if showReminder {
                        Section {
                            HStack {
                                Image(systemName: "bell")
                                Text("Reminder")
                                Spacer()
                                Toggle("", isOn: $reminderEnabled)
                                    .labelsHidden()
                            }
                            if reminderEnabled {
                                Stepper(
                                    "\(reminderMinutesBefore) minutes before",
                                    value: $reminderMinutesBefore,
                                    in: 5...1440,
                                    step: 5
                                )
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .navigationTitle("Date & Time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            dueDate = (enableDate && (showDatePicker || showTimePicker)) ? tempDate : nil
                            isPresented = false
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Date Formatting Helpers
extension Date {
    func formattedRelativeOrDate() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInTomorrow(self) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: self)
    }
    
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
