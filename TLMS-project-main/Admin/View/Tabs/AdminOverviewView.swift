//
//  AdminOverviewView.swift
//  TLMS-project-main
//
//  Overview tab for Admin Dashboard
//

import SwiftUI

struct AdminOverviewView: View {
    let activeCourses: [Course]
    let allEnrollments: [Enrollment]
    let allUsers: [User]
    let isRevenueEnabled: Bool
    let onRefresh: () async -> Void
    let onLogout: () -> Void
    
    @State private var selectedTimeFilter: AnalyticsTimeFilter = .last30Days
    
    // Computed Stats
    var filteredRevenue: Double {
        let filtered = allEnrollments.filter {
            if let date = $0.enrolledAt {
                return selectedTimeFilter.isDateInPeriod(date)
            }
            return false
        }
        
        let coursePriceMap = Dictionary(uniqueKeysWithValues: activeCourses.map { ($0.id, $0.price ?? 0) })
        
        let total = filtered.reduce(0) { total, enrollment in
            total + (coursePriceMap[enrollment.courseID] ?? 0)
        }
        
        return total
    }
    
    var filteredCoursesCount: Int {
        activeCourses.filter { selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }
    
    var filteredLearnersCount: Int {
        allUsers.filter { $0.role == .learner && selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }
    
    var filteredEducatorsCount: Int {
        allUsers.filter { $0.role == .educator && selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header & Filter
                    HStack {
                        Text("Overview")
                            .font(.title2.bold())
                        Spacer()
                        Picker("Time Period", selection: $selectedTimeFilter) {
                            ForEach(AnalyticsTimeFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Summary Stats
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            AdminStatCard(
                                icon: "banknote.fill",
                                title: "Total Revenue",
                                value: isRevenueEnabled ? filteredRevenue.formatted(.currency(code: "INR")) : "--",
                                color: AppTheme.successGreen
                            )
                            .frame(width: 170, height: 140)
                            
                            let split = RevenueCalculator.calculateSplit(total: filteredRevenue)
                            
                            AdminStatCard(
                                icon: "building.columns.fill",
                                title: "Admin (20%)",
                                value: isRevenueEnabled ? split.admin.formatted(.currency(code: "INR")) : "--",
                                color: AppTheme.primaryBlue
                            )
                            .frame(width: 170, height: 140)
                            
                            AdminStatCard(
                                icon: "person.crop.circle.badge.checkmark",
                                title: "Educators (80%)",
                                value: isRevenueEnabled ? split.educator.formatted(.currency(code: "INR")) : "--",
                                color: Color.purple
                            )
                            .frame(width: 170, height: 140)
                            
                            AdminStatCard(
                                icon: "book.fill",
                                title: "Courses",
                                value: "\(filteredCoursesCount)",
                                color: .orange
                            )
                            .frame(width: 170, height: 140)
                            
                            AdminStatCard(
                                icon: "person.2.fill",
                                title: "Learners",
                                value: "\(filteredLearnersCount)",
                                color: AppTheme.successGreen
                            )
                            .frame(width: 170, height: 140)
                            
                            AdminStatCard(
                                icon: "graduationcap.fill",
                                title: "Educators",
                                value: "\(filteredEducatorsCount)",
                                color: .orange
                            )
                            .frame(width: 170, height: 140)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    
                    // Analytics Charts
                    let split = RevenueCalculator.calculateSplit(total: filteredRevenue)
                    AdminAnalyticsView(
                        totalRevenue: filteredRevenue,
                        adminRevenue: split.admin,
                        educatorRevenue: split.educator,
                        totalLearners: filteredLearnersCount,
                        totalEducators: filteredEducatorsCount,
                        showRevenue: isRevenueEnabled
                    )
                    .padding(.top, 20)
                }
                .padding(.bottom, 20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            Task { await onRefresh() }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: onLogout) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            }
        }
    }
}
