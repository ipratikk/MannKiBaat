//
//  ProfileView.swift
//

import SwiftUI
import LoginFeature

@MainActor
struct ProfileView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.accentColor)
                Text("Your Profile")
                    .font(.title)
                    .fontWeight(.bold)

                Button(role: .destructive) {
                    loginViewModel.logout()
                    dismiss()
                } label: {
                    Text("Logout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .clipShape(Capsule())
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
