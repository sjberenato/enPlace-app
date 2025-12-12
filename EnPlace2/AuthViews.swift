//
//  AuthViews.swift
//  EnPlace2
//
//  Authentication views for sign in, sign up, and household management
//

import SwiftUI

// MARK: - Auth Container View

struct AuthContainerView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                Image("welcome-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                
                // Auth form
                if showSignUp {
                    SignUpView(showSignUp: $showSignUp)
                } else {
                    SignInView(showSignUp: $showSignUp)
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.background.ignoresSafeArea())
        }
    }
}

// MARK: - Sign In View

struct SignInView: View {
    @Binding var showSignUp: Bool
    @EnvironmentObject var firebaseService: FirebaseService
    
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome Back!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.textPrimary)
            
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(EnPlaceTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(EnPlaceTextFieldStyle())
                    .textContentType(.password)
            }
            
            if let error = firebaseService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task {
                    do {
                        try await firebaseService.signIn(email: email, password: password)
                    } catch {
                        showError = true
                    }
                }
            } label: {
                if firebaseService.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(EnPlacePrimaryButtonStyle())
            .disabled(email.isEmpty || password.isEmpty || firebaseService.isLoading)
            
            Button {
                withAnimation { showSignUp = true }
            } label: {
                Text("Don't have an account? **Sign Up**")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding()
    }
}

// MARK: - Sign Up View

struct SignUpView: View {
    @Binding var showSignUp: Bool
    @EnvironmentObject var firebaseService: FirebaseService
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Create Account")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.textPrimary)
            
            VStack(spacing: 12) {
                TextField("Your Name", text: $displayName)
                    .textFieldStyle(EnPlaceTextFieldStyle())
                    .textContentType(.name)
                
                TextField("Email", text: $email)
                    .textFieldStyle(EnPlaceTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(EnPlaceTextFieldStyle())
                    .textContentType(.newPassword)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(EnPlaceTextFieldStyle())
                    .textContentType(.newPassword)
                
                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            if let error = firebaseService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task {
                    try? await firebaseService.signUp(email: email, password: password, displayName: displayName)
                }
            } label: {
                if firebaseService.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Account")
                }
            }
            .buttonStyle(EnPlacePrimaryButtonStyle())
            .disabled(!passwordsMatch || email.isEmpty || displayName.isEmpty || firebaseService.isLoading)
            
            Button {
                withAnimation { showSignUp = false }
            } label: {
                Text("Already have an account? **Sign In**")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding()
    }
}

// MARK: - Household Setup View

struct HouseholdSetupView: View {
    var onContinue: () -> Void
    
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var showJoinSheet = false
    @State private var showShareSheet = false
    @State private var inviteCodeInput = ""
    @State private var generatedCode: String?
    @State private var isCreating = false
    @State private var isJoining = false
    @State private var errorMessage: String?
    @State private var codeCopied = false
    @State private var hasJoinedKitchen = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppTheme.primary)
                    
                    Text("Set Up Your Kitchen")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    Text("Connect with your partner to start matching on recipes!")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                if hasJoinedKitchen {
                    // Successfully joined a kitchen
                    VStack(spacing: 16) {
                        Text("🎉 You're In!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        Text("You've joined your partner's kitchen. Time to start swiping!")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            onContinue()
                        } label: {
                            Label("Let's Go!", systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(EnPlacePrimaryButtonStyle())
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.cardBackground)
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    )
                } else if let code = generatedCode ?? firebaseService.currentHousehold?.inviteCode {
                    // Show invite code after creation (check both local state and Firebase)
                    VStack(spacing: 16) {
                        Text("🎉 Kitchen Created!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        Text("Your Invite Code")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        Text(code)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.primary.opacity(0.1))
                            )
                        
                        Text("Share this code with your partner!")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        // Share Button
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share with Partner", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(EnPlacePrimaryButtonStyle())
                        
                        // Copy Button
                        Button {
                            UIPasteboard.general.string = code
                            codeCopied = true
                            // Reset after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                codeCopied = false
                            }
                        } label: {
                            Label(codeCopied ? "Copied!" : "Copy Code", systemImage: codeCopied ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(EnPlaceSecondaryButtonStyle())
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Continue Button
                        Button {
                            onContinue()
                        } label: {
                            Text("Continue to Preferences →")
                                .font(.headline)
                        }
                        .foregroundStyle(AppTheme.primary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.cardBackground)
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    )
                } else if isCreating {
                    // Show loading while creating
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Creating your kitchen...")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding()
                } else {
                    // Options to create or join
                    VStack(spacing: 16) {
                        Button {
                            createHousehold()
                        } label: {
                            Label("Create Kitchen", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(EnPlacePrimaryButtonStyle())
                        .disabled(isCreating || isJoining)
                        
                        Text("or")
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        Button {
                            showJoinSheet = true
                        } label: {
                            Label("Join Kitchen", systemImage: "person.badge.plus")
                        }
                        .buttonStyle(EnPlaceSecondaryButtonStyle())
                        .disabled(isCreating || isJoining)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Sign out option
                Button {
                    try? firebaseService.signOut()
                } label: {
                    Text("Sign Out")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding()
            .background(AppTheme.background.ignoresSafeArea())
            .sheet(isPresented: $showJoinSheet) {
                JoinHouseholdSheet(
                    inviteCode: $inviteCodeInput,
                    isJoining: $isJoining,
                    errorMessage: $errorMessage,
                    onJoin: joinHousehold
                )
                .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $showShareSheet) {
                if let code = generatedCode {
                    ShareSheet(items: ["Join my EnPlace kitchen! Use this code: \(code)"])
                }
            }
        }
    }
    
    private func createHousehold() {
        isCreating = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let code = try await firebaseService.createHousehold()
                self.generatedCode = code
                self.isCreating = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isCreating = false
            }
        }
    }
    
    private func joinHousehold() {
        isJoining = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                try await firebaseService.joinHousehold(inviteCode: inviteCodeInput)
                showJoinSheet = false
                hasJoinedKitchen = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isJoining = false
        }
    }
}

// MARK: - Join Household Sheet

struct JoinHouseholdSheet: View {
    @Binding var inviteCode: String
    @Binding var isJoining: Bool
    @Binding var errorMessage: String?
    var onJoin: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Join Kitchen")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.textPrimary)
            
            Text("Enter the invite code from your partner")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            
            TextField("PASTA-1234", text: $inviteCode)
                .textFieldStyle(EnPlaceTextFieldStyle())
                .autocapitalization(.allCharacters)
                .multilineTextAlignment(.center)
                .font(.system(.title3, design: .monospaced))
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Button {
                onJoin()
            } label: {
                if isJoining {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Join")
                }
            }
            .buttonStyle(EnPlacePrimaryButtonStyle())
            .disabled(inviteCode.isEmpty || isJoining)
        }
        .padding()
    }
}

// MARK: - Custom Styles

struct EnPlaceTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
    }
}

struct EnPlacePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? AppTheme.primary : AppTheme.primary.opacity(0.5))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct EnPlaceSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    AuthContainerView()
}

