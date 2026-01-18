//
//  LearnerEmptyStateView.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
//

import Foundation
import SwiftUI

struct LearnerEmptyState: View {
    let icon: String
    let title: String
    let message: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
