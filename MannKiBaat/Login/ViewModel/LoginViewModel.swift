//
//  LoginViewModel.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import Foundation
import SwiftUI
import AuthenticationServices
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage: String?

    func handleAppleLogin(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                // Save userID securely in Keychain
                KeychainManager.shared.saveAppleUserID(credential.user)
                isLoggedIn = true
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func checkLogin() {
        isLoggedIn = KeychainManager.shared.getAppleUserID() != nil
    }

    func logout() {
        KeychainManager.shared.removeAppleUserID()
        isLoggedIn = false
    }
}
