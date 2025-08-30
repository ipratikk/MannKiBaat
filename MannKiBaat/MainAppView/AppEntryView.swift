//
//  AppEntryView.swift
//  MannKiBaat
//

import SwiftUI

struct AppEntryView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showSplash = true
    @Namespace private var logoNamespace
    @State private var showLoginContent = false

    var body: some View {
        ZStack {
            // Gradient background
            GradientBackgroundView()

            if showSplash {
                SplashLogoView(namespace: logoNamespace)
                    .transition(.opacity)
            } else {
                if viewModel.isLoggedIn {
                    MainAppView()
                        .transition(.opacity)
                } else {
                    LoginView(namespace: logoNamespace, showContent: $showLoginContent) { result in
                        viewModel.handleAppleLogin(result: result)
                    }
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            viewModel.checkLogin() // check Keychain on launch

            // Splash delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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
        .onAppear { UserDefaults.standard.set(false, forKey: "isLoggedIn") }
}

#Preview("Logged In") {
    AppEntryView()
        .environment(\.colorScheme, .dark)
        .onAppear { UserDefaults.standard.set(true, forKey: "isLoggedIn") }
}
