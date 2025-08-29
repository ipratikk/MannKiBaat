//
//  AppEntryView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI

struct AppEntryView: View {
    @State private var showSplash = true
    @Namespace private var namespace

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView(namespace: namespace)
                    .transition(.opacity)
            } else {
                LoginView(namespace: namespace)
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview("Logged Out") {
    AppEntryView()
        .environment(\.colorScheme, .light)
        .onAppear {
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
        }
}

#Preview("Logged In") {
    AppEntryView()
        .environment(\.colorScheme, .dark)
        .onAppear {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
        }
}
