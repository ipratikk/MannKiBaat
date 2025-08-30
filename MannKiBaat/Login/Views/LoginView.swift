//
//  LoginView.swift
//  MannKiBaat
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    var namespace: Namespace.ID
    @Binding var showContent: Bool
    var onLoginSuccess: (() -> Void)?  // called when login succeeds

    var body: some View {
        VStack {
            Spacer()

            // Notebook in center
            NotebookShape()
                .stroke(Color.primary, lineWidth: 3)
                .frame(width: 120, height: 120)
                .matchedGeometryEffect(id: "notebook", in: namespace)

            if showContent {
                VStack(spacing: 16) {
                    Text("Hey Baby!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Please log in to save your notes")
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
                .padding(.top, 24)
            }

            Spacer()

            if showContent {
                SignInWithAppleButton(
                    .continue,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success:
                            // Login succeeded → call the handler
                            onLoginSuccess?()
                        case .failure(let error):
                            print("Apple SignIn failed: \(error.localizedDescription)")
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal)
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
    }
}

// MARK: - Preview Wrapper
fileprivate struct LoginViewPreviewWrapper: View {
    @State private var showContent = false
    let namespace = Namespace().wrappedValue

    var body: some View {
        LoginView(namespace: namespace, showContent: $showContent)
            .onAppear {
                // Simulate notebook transition then show content
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showContent = true
                    }
                }
            }
    }
}

#Preview("Light Mode") {
    LoginViewPreviewWrapper()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LoginViewPreviewWrapper()
        .preferredColorScheme(.dark)
}
