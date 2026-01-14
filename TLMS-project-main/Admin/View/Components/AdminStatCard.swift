//
//  AdminStatCard.swift
//  TLMS-project-main
//
//  Reusable statistic card for admin dashboard
//

import SwiftUI

struct AdminStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.secondaryGroupedBackground)
                .shadow(
                    color: color.opacity(colorScheme == .dark ? 0.3 : 0.15),
                    radius: 15,
                    y: 5
                )
        )
    }
}
