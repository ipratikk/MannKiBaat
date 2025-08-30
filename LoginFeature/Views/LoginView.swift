//
//  LoginView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI
import SharedModels
import AuthenticationServices

public struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    var namespace: Namespace.ID
    @Binding var showContent: Bool

    public init(viewModel: LoginViewModel, namespace: Namespace.ID, showContent: Binding<Bool>) {
        self.viewModel = viewModel
        self.namespace = namespace
        self._showContent = showContent
    }

    public var body: some View {
        VStack {
            Spacer()
            
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
                        viewModel.handleAppleLogin(result: result)
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
