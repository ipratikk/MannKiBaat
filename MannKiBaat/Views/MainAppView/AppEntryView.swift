//
//  AppEntryView.swift
//  MannKiBaat
//

import SwiftUI
import LoginFeature
import NotesFeature
import SharedModels

import SwiftUI
import LoginFeature
import NotesFeature

@MainActor
public struct AppEntryView: View {
    @StateObject private var loginViewModel: LoginViewModel = {
        LoginViewModel(loginManager: LoginManager.shared)
    }()

    @State private var showSplash = true
    @Namespace private var logoNamespace
    @State private var showLoginContent = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            GradientBackgroundView()

            if showSplash {
                SplashLogoView(namespace: logoNamespace)
                    .transition(.opacity)
            } else {
                if loginViewModel.isLoggedIn {
                    MainAppView()
                        .transition(.opacity)
                        .environmentObject(loginViewModel)
                } else {
                    LoginView(viewModel: loginViewModel, namespace: logoNamespace, showContent: $showLoginContent)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            loginViewModel.checkLogin()

            // Splash delay animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.6)) { showSplash = false }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeInOut(duration: 0.6)) { showLoginContent = true }
                }
            }
        }
    }
}
