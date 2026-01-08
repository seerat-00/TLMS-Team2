//
//  SupabaseConfig.swift
//  TLMS-project-main
//
//  Configuration file for Supabase integration
//

import Foundation

struct SupabaseConfig {
    // TODO: Replace these with your actual Supabase credentials
    // You can find these in your Supabase project settings
    static let supabaseURL = Secrets.supabaseURL
    static let supabaseAnonKey = Secrets.supabaseAnonKey
    
    // Validate configuration
    static var isConfigured: Bool {
        return !supabaseURL.contains("YOUR_") && !supabaseAnonKey.contains("YOUR_")
    }
}
