//
//  LoginView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI

struct LoginView: View {
    var namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            NotebookShape()
                .stroke(Color.primary, lineWidth: 3)
                .frame(width: 120, height: 120)
                .matchedGeometryEffect(id: "notebook", in: namespace) // 👈 same id + namespace

            Text("Hey Baby!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Please log in to save your notes")
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 16) {
                Button("Login with Google") {}
                    .buttonStyle(.borderedProminent)

                Button("Login with Apple") {}
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// Custom Apple login style
struct SignInWithAppleButtonView: View {
    var body: some View {
        Button(action: {
            // handle apple login
        }) {
            HStack {
                Image(systemName: "apple.logo")
                Text("Continue with Apple")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.black)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Light Mode") {
    LoginView(namespace: Namespace().wrappedValue)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LoginView(namespace: Namespace().wrappedValue)
        .preferredColorScheme(.dark)
}
