//
//  AdminEducatorsView.swift
//  TLMS-project-main
//
//  Educators tab for Admin Dashboard
//

import SwiftUI

struct AdminEducatorsView: View {
    let pendingEducators: [User]
    let isLoading: Bool
    let onApprove: (User) async -> Void
    let onReject: (User) async -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding(40)
                        } else if pendingEducators.isEmpty {
                            EmptyStateView(
                                icon: "checkmark.circle.fill",
                                title: "No pending educators",
                                message: "All educator requests have been reviewed"
                            )
                        } else {
                            ForEach(pendingEducators) { educator in
                                PendingEducatorCard(educator: educator) {
                                    await onApprove(educator)
                                } onReject: {
                                    await onReject(educator)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Educators")
        }
    }
}
