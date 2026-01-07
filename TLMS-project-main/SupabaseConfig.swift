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
    static let supabaseURL = "https://noytvjhajmehzjexjjmx.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5veXR2amhham1laHpqZXhqam14Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3NzU4MDAsImV4cCI6MjA4MzM1MTgwMH0.nrE57V5gpcX9Uj97gWJvmroPUZUnkNGheiW-uwonM4M"
    
    // Validate configuration
    static var isConfigured: Bool {
        return !supabaseURL.contains("YOUR_") && !supabaseAnonKey.contains("YOUR_")
    }
}
