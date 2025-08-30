//
//  LoginViewModel.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import CloudKit

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Apple Login
    func signInWithApple(request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAppleLogin(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = credential.user
                let fullName = credential.fullName
                let email = credential.email

                // Persist user identifier securely (Keychain recommended)
                KeychainHelper.shared.save(userIdentifier, forKey: "appleUserId")

                // Optional: You can store additional user info in CloudKit
                saveUserToCloudKit(userId: userIdentifier,
                                   name: fullName?.givenName ?? "",
                                   email: email ?? "")

                isLoggedIn = true
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - CloudKit: Store User
    private func saveUserToCloudKit(userId: String, name: String, email: String) {
        let record = CKRecord(recordType: "User")
        record["userId"] = userId as CKRecordValue
        record["name"] = name as CKRecordValue
        record["email"] = email as CKRecordValue

        CKContainer.default().privateCloudDatabase.save(record) { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - CloudKit storage
    func saveNoteToCloudKit(title: String, content: String) {
        let record = CKRecord(recordType: "Note")
        record["title"] = title as CKRecordValue
        record["content"] = content as CKRecordValue

        CKContainer.default().privateCloudDatabase.save(record) { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func saveMediaToCloudKit(data: Data, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)

        let record = CKRecord(recordType: "Media")
        record["file"] = CKAsset(fileURL: tempURL)

        CKContainer.default().privateCloudDatabase.save(record) { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
