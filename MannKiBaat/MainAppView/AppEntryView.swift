//
//  AppEntryView.swift
//  MannKiBaat
//

import SwiftUI
import AuthenticationServices

struct AppEntryView: View {
    @State private var showSplash = true
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @Namespace private var logoNamespace
    @State private var showLoginContent = false

    var body: some View {
        ZStack {
            GradientBackgroundView()

            if showSplash {
                SplashLogoView(namespace: logoNamespace)
                    .transition(.opacity)
            } else {
                if isLoggedIn {
                    MainAppView()
                        .transition(.opacity)
                } else {
                    LoginView(
                        namespace: logoNamespace,
                        showContent: $showLoginContent,
                        onLoginSuccess: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isLoggedIn = true
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showSplash = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showLoginContent = true
                    }
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
