//
//  AppleSignInHelper.swift
//  EnPlace2
//
//  Helper for Sign in with Apple authentication flow
//

import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - Apple Sign In Helper

class AppleSignInHelper: NSObject, ObservableObject {
    
    // Current nonce for this sign-in attempt
    var currentNonce: String?
    
    // Completion handler for sign-in result
    var onSignIn: ((ASAuthorizationAppleIDCredential, String) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Nonce Generation
    
    /// Generate a random nonce string for secure Apple Sign In
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    /// SHA256 hash of the nonce (required by Apple)
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Sign In Request
    
    /// Start the Apple Sign In flow
    func startSignInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInHelper: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce else {
            onError?(NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: no nonce"]))
            return
        }
        
        onSignIn?(appleIDCredential, nonce)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle user cancellation gracefully
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled {
            print("ℹ️ User cancelled Apple Sign In")
            return
        }
        
        onError?(error)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInHelper: ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window for presenting the Apple Sign In sheet
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

