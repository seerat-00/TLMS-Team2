//
//  LearnerDashboardHeader.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
//

//
//  LearnerDashboardHeader.swift
//  TLMS-project-main
//

import SwiftUI

struct LearnerDashboardHeader: View {
    let user: User
    let enrolledCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome back,")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)

                Text(user.fullName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            HStack(spacing: 16) {
                LearnerStatCard(
                    icon: "book.fill",
                    title: "Enrolled",
                    value: "\(enrolledCount)",
                    color: AppTheme.primaryBlue
                )

                LearnerStatCard(
                    icon: "checkmark.seal.fill",
                    title: "Completed",
                    value: "0",
                    color: AppTheme.successGreen
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 20)
    }
}
