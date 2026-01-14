//
//  AdminUsersView.swift
//  TLMS-project-main
//
//  Users tab for Admin Dashboard
//

import SwiftUI

struct AdminUsersView: View {
    let allUsers: [User]
    let isLoading: Bool
    
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
                        } else if allUsers.isEmpty {
                            EmptyStateView(
                                icon: "person.3.fill",
                                title: "No users yet",
                                message: "Users will appear here once they sign up"
                            )
                        } else {
                            ForEach(allUsers) { user in
                                UserCard(user: user)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Users")
        }
    }
}
