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
    var filteredEnrollments: [Enrollment] {
        allEnrollments.filter {
            if let date = $0.enrolledAt {
                return selectedTimeFilter.isDateInPeriod(date)
            }
            return false
        }
    }
    
    var filteredRevenue: Double {
        let coursePriceMap = Dictionary(uniqueKeysWithValues: activeCourses.map { ($0.id, $0.price ?? 0) })
        
        let total = filteredEnrollments.reduce(0) { total, enrollment in
            total + (coursePriceMap[enrollment.courseID] ?? 0)
        }
        
        return total
    }
    
    var filteredCoursesCount: Int {
        activeCourses.filter { selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }
    
    var avgEnrollmentValue: Double {
        guard !filteredEnrollments.isEmpty else { return 0 }
        return filteredRevenue / Double(filteredEnrollments.count)
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
                            

                            
                            AdminStatCard(
                                icon: "person.2.fill",
                                title: "Enrollments",
                                value: "\(filteredEnrollments.count)",
                                color: .purple
                            )
                            .frame(width: 170, height: 140)
                            
                            AdminStatCard(
                                icon: "chart.bar.fill",
                                title: "Avg. Value",
                                value: isRevenueEnabled ? avgEnrollmentValue.formatted(.currency(code: "INR")) : "--",
                                color: .indigo
                            )
                            .frame(width: 170, height: 140)
                            
                            AdminStatCard(
                                icon: "book.fill",
                                title: "Courses",
                                value: "\(filteredCoursesCount)",
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
                        totalLearners: allUsers.filter { $0.role == .learner && selectedTimeFilter.isDateInPeriod($0.createdAt) }.count,
                        totalEducators: allUsers.filter { $0.role == .educator && selectedTimeFilter.isDateInPeriod($0.createdAt) }.count,
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
