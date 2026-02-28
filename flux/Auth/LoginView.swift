//
//  LoginView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI

struct LoginView: View {

    @Bindable var auth: AuthViewModel

    @State private var handle: String = ""
    @State private var appPassword: String = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case handle, password
    }

    private var isLoading: Bool {
        switch auth.state {
        case .resolvingPDS, .authenticating: return true
        default: return false
        }
    }

    private var loadingLabel: String {
        if case .resolvingPDS = auth.state { return "Resolving PDS…" }
        return "Signing in…"
    }

    private var errorMessage: String? {
        if case .failed(let message) = auth.state { return message }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo / wordmark
            VStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.blue)
                Text("flux")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("A Bluesky client")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)

            // Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Handle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("you.bsky.social", text: $handle)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .handle)
                        .onSubmit { focusedField = .password }
                        .disabled(isLoading)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("App Password")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Link("Get one →", destination: URL(string: "https://bsky.app/settings/app-passwords")!)
                            .font(.caption)
                    }
                    SecureField("xxxx-xxxx-xxxx-xxxx", text: $appPassword)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .password)
                        .onSubmit { attemptLogin() }
                        .disabled(isLoading)
                }

                // Error banner
                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(2)
                        Spacer()
                    }
                    .padding(10)
                    .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }

                // Sign in button
                Button(action: attemptLogin) {
                    Group {
                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text(loadingLabel)
                            }
                        } else {
                            Text("Sign in")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(handle.isEmpty || appPassword.isEmpty || isLoading)
            }
            .frame(maxWidth: 320)

            Spacer()

            // Footer
            Text("Use an App Password, not your main password.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 500)
        .onAppear { focusedField = .handle }
    }

    private func attemptLogin() {
        guard !handle.isEmpty, !appPassword.isEmpty else { return }
        Task { await auth.login(handle: handle, appPassword: appPassword) }
    }
}

#Preview {
    LoginView(auth: AuthViewModel())
}
