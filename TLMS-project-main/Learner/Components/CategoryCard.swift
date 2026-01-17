//
//  CategoryCard.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
//

import Foundation
import SwiftUI

struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            LinearGradient(
                colors: [color.opacity(0.8), color.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(16)
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.white.opacity(0.3))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(20)
            
            // Title
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(20)
        }
        .frame(height: 140)
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

