//
//  File.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
//

import Foundation
import SwiftUI

struct CourseEnrollmentBottomBar: View {
    let course: Course
    let isPaidCourse: Bool
    let isEnrolling: Bool
    let isLoading: Bool
    let onAction: () -> Void

    var body: some View {
        VStack {
            Divider()
            
            HStack {
                Button(action: onAction) {
                    HStack {
                        if isEnrolling || isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            if isPaidCourse, let price = course.price {
                                HStack(spacing: 8) {
                                    Image(systemName: "cart.fill")
                                    Text("Buy Now - \(price.formatted(.currency(code: "INR")))")
                                }
                                .font(.headline)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Enroll Free")
                                }
                                .font(.headline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.cornerRadius)
                }
                .disabled(isEnrolling || isLoading)
            }
            .padding()
            .background(AppTheme.secondaryGroupedBackground)
        }
    }
}
