//
//  AppEntryView.swift
//  MannKiBaat
//

import SwiftUI
import LoginFeature
import NotesFeature
import SharedModels

@MainActor
public struct AppEntryView: View {
    @StateObject private var loginViewModel = LoginViewModel()
    @Environment(\.modelContext) private var modelContext
    
    // Splash animation state
    @State private var showSplash = true
    @Namespace private var logoNamespace
    @State private var showLoginContent = false

    public init() {}

    public var body: some View {
        ZStack {
            // Background
            GradientBackgroundView()

            if showSplash {
                SplashLogoView(namespace: logoNamespace)
                    .transition(.opacity)
            } else {
                if loginViewModel.isLoggedIn {
                    MainAppView(modelContext: modelContext)
                        .environmentObject(loginViewModel)
                        .transition(.opacity)
                } else {
                    LoginView(
                        viewModel: loginViewModel,
                        namespace: logoNamespace,
                        showContent: $showLoginContent
                    )
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            // Check login during splash
            loginViewModel.checkLogin()

            // Splash delay animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.6)) { showSplash = false }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeInOut(duration: 0.6)) { showLoginContent = true }
                }
            }
        }
    }
}

#Preview("Logged Out") {
    AppEntryView()
        .environment(\.colorScheme, .light)
}

#Preview("Logged In") {
    AppEntryView()
        .environment(\.colorScheme, .dark)
}
