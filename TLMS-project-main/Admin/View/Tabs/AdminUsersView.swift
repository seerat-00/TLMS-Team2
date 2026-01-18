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
    
    @State private var selectedFilter: FilterOption = .all
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 8)
                        
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
                            let filteredUsers = allUsers.filter { user in
                                guard let role = selectedFilter.role else { return true }
                                return user.role == role
                            }
                            
                            if filteredUsers.isEmpty {
                                EmptyStateView(
                                    icon: "magnifyingglass",
                                    title: "No users found",
                                    message: "No users match the selected role"
                                )
                                .padding(.top, 40)
                            } else {
                                ForEach(filteredUsers) { user in
                                    UserCard(user: user)
                                }
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

enum FilterOption: String, CaseIterable {
    case all = "All"
    case learner = "Learner"
    case educator = "Educator"
    case admin = "Admin"
    
    var role: UserRole? {
        switch self {
        case .all: return nil
        case .learner: return .learner
        case .educator: return .educator
        case .admin: return .admin
        }
    }
}
