//
//  CustomDueDateSheet.swift
//

import SwiftUI

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
            List {
                // Date row (no Section)
                HStack {
                    Image(systemName: "calendar")
                    Text("Date")
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
                HStack {
                    Image(systemName: "clock")
                    Text("Time")
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
            .navigationTitle("Date & Time")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dueDate = (enableDate && (showDatePicker || showTimePicker)) ? tempDate : nil
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
