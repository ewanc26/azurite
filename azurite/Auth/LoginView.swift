//
//  LoginView.swift
//  azurite

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
        ZStack {
            // Bluesky-style blue radial background glow
            RadialGradient(
                colors: [Color.bskyBlue.opacity(0.10), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.bskyPrimary)
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.bskyBlue.opacity(0.45), radius: 16)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text("azurite")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.bskyBlue)

                    Text("A Bluesky client")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 44)

                // Form card
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Handle")
                            .font(.caption)
                            .fontWeight(.medium)
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
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Link("Get one →", destination: URL(string: "https://bsky.app/settings/app-passwords")!)
                                .font(.caption)
                                .foregroundStyle(Color.bskyBlue)
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
                                    ProgressView().controlSize(.small)
                                    Text(loadingLabel)
                                }
                            } else {
                                Text("Sign in")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.bskyBlue)
                    .controlSize(.large)
                    .shadow(color: Color.bskyBlue.opacity(0.30), radius: 8, y: 4)
                    .disabled(handle.isEmpty || appPassword.isEmpty || isLoading)
                }
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
                .frame(maxWidth: 340)

                Spacer()

                Text("Use an App Password, not your main password.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 20)
            }
            .padding(32)
        }
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
