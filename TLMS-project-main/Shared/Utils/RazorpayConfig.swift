//
//  RazorpayConfig.swift
//  TLMS-project-main
//
//  Configuration for Razorpay payment gateway
//

import Foundation

struct RazorpayConfig {
    // MARK: - Test API Keys
    // Get your keys from: https://dashboard.razorpay.com/app/keys
    
    static let keyId = "rzp_test_S3IPM0EvTm8nqL" // Test API Key
    static let keySecret = "bquN9K3z3Qr53O8Ka1Wk7yzn" // Test Key Secret

    
    static let isTestMode = true
    static let currency = "INR" // Indian Rupees
    static let companyName = "TLMS"
    static let companyLogo = "https://your-logo-url.com/logo.png" // Optional
    
    // MARK: - Validation
    
    static var isConfigured: Bool {
        return !keyId.contains("YOUR_") && !keySecret.contains("YOUR_")
    }
    
    // MARK: - Test Card Details (for documentation)
    /*
     Test Card for Payments:
     - Card Number: 4111 1111 1111 1111
     - CVV: Any 3 digits (e.g., 123)
     - Expiry: Any future date (e.g., 12/25)
     - Name: Any name
     
     This card will always succeed in test mode.
     
     For testing failures, use:
     - Card Number: 4000 0000 0000 0002
     */
}
