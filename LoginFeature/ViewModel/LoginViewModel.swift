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
public class LoginViewModel: ObservableObject {
    @Published public var isLoggedIn = false
    @Published public var errorMessage: String?

    private let loginManager: LoginManaging

    public init(loginManager: LoginManaging = LoginManager.shared) {
        self.loginManager = loginManager
        self.isLoggedIn = loginManager.getUserID() != nil
    }

    public func handleAppleLogin(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                loginManager.saveUserID(credential.user)
                isLoggedIn = true
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    public func checkLogin() {
        isLoggedIn = loginManager.getUserID() != nil
    }

    public func logout() {
        loginManager.removeUserID()
        isLoggedIn = false
    }
}
