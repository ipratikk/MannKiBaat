//
//  NotesView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI

struct NotesView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var title = ""
    @State private var content = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Note title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextEditor(text: $content)
                    .frame(height: 200)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                    .padding(.horizontal)

                Button(action: {
                    Task {
                        await viewModel.saveNote(title: title, content: content)
                        title = ""
                        content = ""
                    }
                }) {
                    Text("Save Note")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("My Notes")
            .onAppear {
                Task { await viewModel.fetchNotes() }
            }
        }
    }
}

#Preview {
    NotesView()
}
