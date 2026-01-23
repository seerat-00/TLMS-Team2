////
////  AdminOverviewView.swift
////  TLMS-project-main
////
////  Overview tab for Admin Dashboard
////
//
//import SwiftUI
//
//struct AdminOverviewView: View {
//    let activeCourses: [Course]
//    let allEnrollments: [Enrollment]
//    let allUsers: [User]
//    let isRevenueEnabled: Bool
//    let onRefresh: () async -> Void
//    let onLogout: () -> Void
//    
//    @State private var selectedTimeFilter: AnalyticsTimeFilter = .last30Days
//    
//    // Computed Stats
//    var filteredEnrollments: [Enrollment] {
//        allEnrollments.filter {
//            if let date = $0.enrolledAt {
//                return selectedTimeFilter.isDateInPeriod(date)
//            }
//            return false
//        }
//    }
//    
//    var filteredRevenue: Double {
//        let coursePriceMap = Dictionary(uniqueKeysWithValues: activeCourses.map { ($0.id, $0.price ?? 0) })
//        
//        let total = filteredEnrollments.reduce(0) { total, enrollment in
//            total + (coursePriceMap[enrollment.courseID] ?? 0)
//        }
//        
//        return total
//    }
//    
//    var filteredCoursesCount: Int {
//        activeCourses.filter { selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
//    }
//    
//    var avgEnrollmentValue: Double {
//        guard !filteredEnrollments.isEmpty else { return 0 }
//        return filteredRevenue / Double(filteredEnrollments.count)
//    }
//    
//
//    
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(spacing: 0) {
//                    // Header & Filter
//                    HStack {
//                        Text("Overview")
//                            .font(.title2.bold())
//                        Spacer()
//                        Picker("Time Period", selection: $selectedTimeFilter) {
//                            ForEach(AnalyticsTimeFilter.allCases) { filter in
//                                Text(filter.rawValue).tag(filter)
//                            }
//                        }
//                        .pickerStyle(.menu)
//                        .padding(.vertical, 4)
//                        .padding(.horizontal, 10)
//                        .background(Color(uiColor: .secondarySystemGroupedBackground))
//                        .cornerRadius(8)
//                    }
//                    .padding(.horizontal)
//                    .padding(.top)
//                    
//                    // Summary Stats
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 16) {
//                            AdminStatCard(
//                                icon: "banknote.fill",
//                                title: "Total Revenue",
//                                value: isRevenueEnabled ? filteredRevenue.formatted(.currency(code: "INR")) : "--",
//                                color: AppTheme.successGreen
//                            )
//                            .frame(width: 190, height: 140)
//                            
//
//                            
//                            AdminStatCard(
//                                icon: "person.2.fill",
//                                title: "Enrollments",
//                                value: "\(filteredEnrollments.count)",
//                                color: .purple
//                            )
//                            .frame(width: 190, height: 140)
//                            
//                            AdminStatCard(
//                                icon: "chart.bar.fill",
//                                title: "Avg. Value",
//                                value: isRevenueEnabled ? avgEnrollmentValue.formatted(.currency(code: "INR")) : "--",
//                                color: .indigo
//                            )
//                            .frame(width: 190, height: 140)
//                            
//                            AdminStatCard(
//                                icon: "book.fill",
//                                title: "Courses",
//                                value: "\(filteredCoursesCount)",
//                                color: .orange
//                            )
//                            .frame(width: 190, height: 140)
//                        }
//                        .padding(.horizontal)
//                        .padding(.top, 20)
//                    }
//                    
//                    // Analytics Charts
//                    let split = RevenueCalculator.calculateSplit(total: filteredRevenue)
//                    AdminAnalyticsView(
//                        totalRevenue: filteredRevenue,
//                        adminRevenue: split.admin,
//                        educatorRevenue: split.educator,
//                        totalLearners: allUsers.filter { $0.role == .learner && selectedTimeFilter.isDateInPeriod($0.createdAt) }.count,
//                        totalEducators: allUsers.filter { $0.role == .educator && selectedTimeFilter.isDateInPeriod($0.createdAt) }.count,
//                        showRevenue: isRevenueEnabled
//                    )
//                    .padding(.top, 20)
//                }
//                .padding(.bottom, 20)
//            }
//            .background(Color(uiColor: .systemGroupedBackground))
//            .navigationTitle("Dashboard")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Menu {
//                        Button(action: {
//                            Task { await onRefresh() }
//                        }) {
//                            Label("Refresh", systemImage: "arrow.clockwise")
//                        }
//                        
//                        Divider()
//                        
//                        Button(role: .destructive, action: onLogout) {
//                            Label("Sign Out", systemImage: "arrow.right.square")
//                        }
//                    } label: {
//                        Image(systemName: "ellipsis.circle.fill")
//                            .font(.system(size: 24))
//                            .foregroundColor(AppTheme.primaryBlue)
//                    }
//                }
//            }
//        }
//    }
//}
//import SwiftUI
//import Charts
//
//struct AdminOverviewView: View {
//    let activeCourses: [Course]
//    let allEnrollments: [Enrollment]
//    let allUsers: [User]
//    let isRevenueEnabled: Bool
//    let onRefresh: () async -> Void
//    let onLogout: () -> Void
//
//    // ✅ NEW: Tab switch for quick actions
//    @Binding var selectedTab: Int
//
//    @State private var selectedTimeFilter: AnalyticsTimeFilter = .last30Days
//
//    // ✅ Sheets (for now placeholders, functionality later)
//    @State private var showAddEducatorSheet = false
//    @State private var showReportsSheet = false
//
//    // MARK: - Computed Stats
//
//    var filteredEnrollments: [Enrollment] {
//        allEnrollments.filter {
//            if let date = $0.enrolledAt {
//                return selectedTimeFilter.isDateInPeriod(date)
//            }
//            return false
//        }
//    }
//
//    var filteredRevenue: Double {
//        let coursePriceMap = Dictionary(uniqueKeysWithValues: activeCourses.map { ($0.id, $0.price ?? 0) })
//        return filteredEnrollments.reduce(0) { total, enrollment in
//            total + (coursePriceMap[enrollment.courseID] ?? 0)
//        }
//    }
//
//    var filteredCoursesCount: Int {
//        activeCourses.filter { selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
//    }
//
//    var totalUsersCount: Int {
//        allUsers.filter { selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
//    }
//
//    var body: some View {
//        NavigationStack {
//            ScrollView(showsIndicators: false) {
//                VStack(alignment: .leading, spacing: 18) {
//
//                    // MARK: - Header Row (NO "Admin Overview")
//                    HStack(alignment: .center) {
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("Dashboard")
//                                .font(.title.bold())
//                            Text(selectedTimeFilter.rawValue)
//                                .font(.footnote.weight(.medium))
//                                .foregroundColor(.secondary)
//                        }
//
//                        Spacer()
//
//                        Picker("Time Period", selection: $selectedTimeFilter) {
//                            ForEach(AnalyticsTimeFilter.allCases) { filter in
//                                Text(filter.rawValue).tag(filter)
//                            }
//                        }
//                        .pickerStyle(.menu)
//                        .padding(.vertical, 6)
//                        .padding(.horizontal, 10)
//                        .background(Color(uiColor: .secondarySystemGroupedBackground))
//                        .clipShape(RoundedRectangle(cornerRadius: 10))
//                    }
//                    .padding(.top, 8)
//                    .padding(.horizontal)
//
//                    // MARK: - Overview Cards (4 cards only)
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 14) {
//
//                            AdminStatCard(
//                                icon: "person.3.fill",
//                                title: "Total Users",
//                                value: "\(totalUsersCount)",
//                                color: AppTheme.primaryBlue
//                            )
//                            .frame(width: 190, height: 140)
//
//                            AdminStatCard(
//                                icon: "banknote.fill",
//                                title: "Total Revenue",
//                                value: isRevenueEnabled ? filteredRevenue.formatted(.currency(code: "INR")) : "--",
//                                color: AppTheme.successGreen
//                            )
//                            .frame(width: 190, height: 140)
//
//                            AdminStatCard(
//                                icon: "book.fill",
//                                title: "Total Courses",
//                                value: "\(filteredCoursesCount)",
//                                color: .orange
//                            )
//                            .frame(width: 190, height: 140)
//
//                            AdminStatCard(
//                                icon: "graduationcap.fill",
//                                title: "Enrollments",
//                                value: "\(filteredEnrollments.count)",
//                                color: .purple
//                            )
//                            .frame(width: 190, height: 140)
//                        }
//                        .padding(.horizontal)
//                        .padding(.top, 6)
//                        .padding(.bottom, 6)
//                    }
//
//                    // MARK: - Revenue Distribution (Clean Donut)
//                    RevenueDistributionCard(
//                        totalRevenue: filteredRevenue,
//                        showRevenue: isRevenueEnabled
//                    )
//                    .padding(.horizontal)
//
//                    // MARK: - Quick Actions (3 Buttons)
//                    QuickActionsCard(
//                        onAddEducator: { showAddEducatorSheet = true },
//                        onManageUsers: { selectedTab = 3 }, // ✅ Jump to Users tab
//                        onReports: { showReportsSheet = true }
//                    )
//                    .padding(.horizontal)
//
//                    Spacer(minLength: 20)
//                }
//                .padding(.bottom, 20)
//            }
//            .background(Color(uiColor: .systemGroupedBackground))
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Menu {
//                        Button {
//                            Task { await onRefresh() }
//                        } label: {
//                            Label("Refresh", systemImage: "arrow.clockwise")
//                        }
//
//                        Divider()
//
//                        Button(role: .destructive, action: onLogout) {
//                            Label("Sign Out", systemImage: "arrow.right.square")
//                        }
//                    } label: {
//                        Image(systemName: "ellipsis.circle.fill")
//                            .font(.system(size: 22))
//                            .foregroundColor(AppTheme.primaryBlue)
//                    }
//                }
//            }
//            // ✅ Add Educator Sheet placeholder
//            .sheet(isPresented: $showAddEducatorSheet) {
//                NavigationStack {
//                    VStack(spacing: 12) {
//                        Image(systemName: "person.badge.plus")
//                            .font(.system(size: 48))
//                            .foregroundColor(AppTheme.primaryBlue)
//
//                        Text("Add Educator")
//                            .font(.system(size: 26, weight: .bold, design: .rounded))
//
//                        Text("UI ready ✅\nFunctionality will be connected next.")
//                            .font(.callout)
//                            .foregroundColor(.secondary)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal)
//
//                        Spacer()
//                    }
//                    .padding(.top, 30)
//                    .toolbar {
//                        ToolbarItem(placement: .topBarTrailing) {
//                            Button("Close") { showAddEducatorSheet = false }
//                        }
//                    }
//                }
//            }
//            // ✅ Reports Sheet placeholder
//            .sheet(isPresented: $showReportsSheet) {
//                NavigationStack {
//                    VStack(spacing: 12) {
//                        Image(systemName: "doc.text.magnifyingglass")
//                            .font(.system(size: 48))
//                            .foregroundColor(.purple)
//
//                        Text("Reports")
//                            .font(.system(size: 26, weight: .bold, design: .rounded))
//
//                        Text("Reports screen UI will be built next.")
//                            .font(.callout)
//                            .foregroundColor(.secondary)
//
//                        Spacer()
//                    }
//                    .padding(.top, 30)
//                    .toolbar {
//                        ToolbarItem(placement: .topBarTrailing) {
//                            Button("Close") { showReportsSheet = false }
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
////
//// MARK: - Revenue Distribution Card (Clean iPhone friendly)
////
//struct RevenueDistributionCard: View {
//    let totalRevenue: Double
//    let showRevenue: Bool
//
//    struct Segment: Identifiable {
//        let id = UUID()
//        let name: String
//        let value: Double
//        let color: Color
//    }
//
//    private var data: [Segment] {
//        let split = RevenueCalculator.calculateSplit(total: totalRevenue)
//        return [
//            Segment(name: "Admin", value: split.admin, color: AppTheme.primaryBlue),
//            Segment(name: "Educators", value: split.educator, color: .purple)
//        ]
//    }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 14) {
//            HStack {
//                Text("Revenue Distribution")
//                    .font(.headline)
//                Spacer()
//            }
//
//            if showRevenue {
//                HStack(spacing: 18) {
//                    Chart(data) { segment in
//                        SectorMark(
//                            angle: .value("Revenue", segment.value),
//                            innerRadius: .ratio(0.62),
//                            angularInset: 2
//                        )
//                        .foregroundStyle(segment.color)
//                    }
//                    .frame(width: 140, height: 140)
//
//                    VStack(alignment: .leading, spacing: 10) {
//                        ForEach(data) { item in
//                            HStack(spacing: 8) {
//                                Circle()
//                                    .fill(item.color)
//                                    .frame(width: 10, height: 10)
//
//                                Text(item.name)
//                                    .font(.subheadline.weight(.medium))
//                                    .foregroundColor(.secondary)
//
//                                Spacer()
//
//                                Text(item.value.formatted(.currency(code: "INR").precision(.fractionLength(0))))
//                                    .font(.subheadline.weight(.semibold))
//                            }
//                        }
//
//                        Divider().opacity(0.5)
//
//                        HStack {
//                            Text("Total")
//                                .font(.subheadline.weight(.medium))
//                                .foregroundColor(.secondary)
//                            Spacer()
//                            Text(totalRevenue.formatted(.currency(code: "INR").precision(.fractionLength(0))))
//                                .font(.headline)
//                        }
//                    }
//                }
//            } else {
//                Text("Revenue will show once pricing is enabled.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding(16)
//        .background(Color(uiColor: .secondarySystemGroupedBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 18))
//        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
//    }
//}
//
////
//// MARK: - Quick Actions (3 only)
////
//struct QuickActionsCard: View {
//    let onAddEducator: () -> Void
//    let onManageUsers: () -> Void
//    let onReports: () -> Void
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Quick Actions")
//                .font(.headline)
//
//            HStack(alignment: .top, spacing: 18) {
//                QuickActionButton(
//                    title: "Add Educator",
//                    icon: "person.badge.plus",
//                    tint: AppTheme.primaryBlue,
//                    action: onAddEducator
//                )
//
//                QuickActionButton(
//                    title: "Users",
//                    icon: "person.3.fill",
//                    tint: .purple,
//                    action: onManageUsers
//                )
//
//                QuickActionButton(
//                    title: "Reports",
//                    icon: "doc.text.magnifyingglass",
//                    tint: .orange,
//                    action: onReports
//                )
//            }
//        }
//        .padding(16)
//        .background(Color(uiColor: .secondarySystemGroupedBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 18))
//        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
//    }
//}
//
//struct QuickActionButton: View {
//    let title: String
//    let icon: String
//    let tint: Color
//    let action: () -> Void
//
//    var body: some View {
//        Button(action: action) {
//            VStack(spacing: 12) {
//                ZStack {
//                    Circle()
//                        .fill(tint.opacity(0.15))
//                        .frame(width: 44, height: 44)
//
//                    Image(systemName: icon)
//                        .font(.system(size: 18, weight: .semibold))
//                        .foregroundColor(tint)
//                }
//
//                Text(title)
//                    .font(.subheadline.weight(.semibold))
//                    .foregroundColor(.primary)
//                    .multilineTextAlignment(.center)
//                    .lineLimit(2)
//                    .frame(height: 40)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 14)
//        }
//    }
//}
//
//  AdminOverviewView.swift
//  TLMS-project-main
//
//  iOS Clean Dashboard (Option A)
//
import SwiftUI
import Charts

struct AdminOverviewView: View {
    let activeCourses: [Course]
    let allEnrollments: [Enrollment]
    let allUsers: [User]
    let isRevenueEnabled: Bool
    let onRefresh: () async -> Void
    let onLogout: () -> Void
    
    // ✅ Pending counts
    let pendingEducatorsCount: Int
    let pendingCoursesCount: Int
    
    // ✅ Tab switching for quick actions
    @Binding var selectedTab: Int
    
    @State private var selectedTimeFilter: AnalyticsTimeFilter = .last30Days
    
    // ✅ Pending sheet
    @State private var showPendingSheet = false
    
    // ✅ Reports sheet
    @State private var showReportsSheet = false
    
    // MARK: - Computed Stats
    
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
        return filteredEnrollments.reduce(0) { total, enrollment in
            total + (coursePriceMap[enrollment.courseID] ?? 0)
        }
    }
    
    var filteredCoursesCount: Int {
        activeCourses.filter { selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }
    
    var totalUsersCount: Int {
        allUsers.filter { selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }
    
    var totalPendingCount: Int {
        pendingEducatorsCount + pendingCoursesCount
    }
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // ✅ Overview stats (2x2 grid)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Overview")
                                .font(.headline)
                            
                            Spacer()
                            
                            timeFilterPillSmall
                        }
                        
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            AdminMiniStatCard(
                                title: "Total Users",
                                value: "\(totalUsersCount)",
                                icon: "person.3.fill",
                                tint: Color(uiColor: .systemBlue)
                            )
                            
                            AdminMiniStatCard(
                                title: "Total Revenue",
                                value: isRevenueEnabled
                                ? filteredRevenue.formatted(.currency(code: "INR").precision(.fractionLength(0)))
                                : "--",
                                icon: "banknote.fill",
                                tint: Color(uiColor: .systemGreen)
                            )
                            
                            AdminMiniStatCard(
                                title: "Courses",
                                value: "\(filteredCoursesCount)",
                                icon: "book.closed.fill",
                                tint: Color(uiColor: .systemOrange)
                            )
                            
                            AdminMiniStatCard(
                                title: "Enrollments",
                                value: "\(filteredEnrollments.count)",
                                icon: "graduationcap.fill",
                                tint: Color(uiColor: .systemIndigo)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // ✅ Revenue Distribution
                    RevenueDistributionCardIOS(
                        totalRevenue: filteredRevenue,
                        showRevenue: isRevenueEnabled
                    )
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // ✅ Quick Actions (Tiles)
                    QuickActionsTilesCard(
                        pendingEducatorsCount: pendingEducatorsCount,
                        pendingCoursesCount: pendingCoursesCount,
                        onPendingTap: { showPendingSheet = true },
                        onUsers: { selectedTab = 3 },
                        onReports: { showReportsSheet = true }
                    )
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    Spacer(minLength: 16)
                }
                .padding(.bottom, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task { await onRefresh() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: onLogout) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // ✅ Pending Sheet
            .sheet(isPresented: $showPendingSheet) {
                PendingSelectionSheet(
                    educatorsCount: pendingEducatorsCount,
                    coursesCount: pendingCoursesCount,
                    selectedTab: $selectedTab
                )
            }
            
            // ✅ Reports Sheet
            .sheet(isPresented: $showReportsSheet) {
                AdminReportsView(
                    activeCourses: activeCourses,
                    allEnrollments: allEnrollments,
                    allUsers: allUsers,
                    selectedTimeFilter: selectedTimeFilter,
                    isRevenueEnabled: isRevenueEnabled
                )
            }
        }
    }
    
    // MARK: - Time pill
    
    private var timeFilterPillSmall: some View {
        Picker("Time Period", selection: $selectedTimeFilter) {
            ForEach(AnalyticsTimeFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.menu)
        .font(.footnote.weight(.semibold))
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

//
// MARK: - Quick Actions Tiles
//

struct QuickActionsTilesCard: View {
    let pendingEducatorsCount: Int
    let pendingCoursesCount: Int
    
    let onPendingTap: () -> Void
    let onUsers: () -> Void
    let onReports: () -> Void
    
    private var totalPendingCount: Int {
        pendingEducatorsCount + pendingCoursesCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickTile(
                    title: "Pending",
                    icon: "hourglass",
                    tint: Color(uiColor: .systemOrange),
                    subtitle1: "\(pendingEducatorsCount)",
                    subtitle2: "\(pendingCoursesCount)",
                    badgeCount: totalPendingCount,
                    action: onPendingTap
                )
                
                QuickTile(
                    title: "Users",
                    icon: "person.3.fill",
                    tint: Color(uiColor: .systemIndigo),
                    subtitle1: nil,
                    subtitle2: nil,
                    badgeCount: nil,
                    action: onUsers
                )
                
                QuickTile(
                    title: "Reports",
                    icon: "doc.text.magnifyingglass",
                    tint: Color(uiColor: .systemOrange),
                    subtitle1: nil,
                    subtitle2: nil,
                    badgeCount: nil,
                    action: onReports
                )
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

//struct QuickTile: View {
//    let title: String
//    let icon: String
//    let tint: Color
//    
//    let subtitle1: String?
//    let subtitle2: String?
//    
//    let badgeCount: Int?
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            VStack(spacing: 8) {
//                ZStack {
//                    Circle()
//                        .fill(tint.opacity(0.12))
//                        .frame(width: 42, height: 42)
//                    
//                    Image(systemName: icon)
//                        .font(.system(size: 18, weight: .semibold))
//                        .foregroundColor(tint)
//                }
//                
//                Text(title)
//                    .font(.subheadline.weight(.semibold))
//                    .foregroundColor(.primary)
//                    .lineLimit(1)
//                
//                if let subtitle1 {
//                    Text(subtitle1)
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//                
//                if let subtitle2 {
//                    Text(subtitle2)
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//            }
//            .frame(maxWidth: .infinity)
//            .frame(height: 120)
//            .background(Color(uiColor: .systemBackground))
//            .clipShape(RoundedRectangle(cornerRadius: 18))
//            .overlay(
//                RoundedRectangle(cornerRadius: 18)
//                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
//            )
//            .overlay(alignment: .topTrailing) {
//                if let badgeCount, badgeCount > 0 {
//                    Text("\(badgeCount)")
//                        .font(.caption2.bold())
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 7)
//                        .padding(.vertical, 4)
//                        .background(Color(uiColor: .systemRed))
//                        .clipShape(Capsule())
//                        .offset(x: 6, y: -6)
//                }
//            }
//            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
//        }
//        .buttonStyle(.plain)
//    }
//}
struct QuickTile: View {
    let title: String
    let icon: String
    let tint: Color
    
    let subtitle1: String?
    let subtitle2: String?
    
    let badgeCount: Int?
    let action: () -> Void
    
    private var hasSubtitles: Bool {
        (subtitle1 != nil) || (subtitle2 != nil)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                
                // Icon
                ZStack {
                    Circle()
                           .fill(tint.opacity(0.12))
                           .frame(width: 48, height: 48)   // ✅ bigger circle

                       Image(systemName: icon)
                           .font(.system(size: 20, weight: .semibold)) // ✅ thoda clean
                           .foregroundColor(tint)
                           .frame(width: 26, height: 26)   // ✅ prevents clipping
                           .minimumScaleFactor(0.7)
                           .lineLimit(1)
                }
                .padding(.top, 8)
                
                // Title
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Subtitles as chips (ONLY for Pending)
                if hasSubtitles {
                    HStack(spacing: 8) {
                        if let count1 = subtitle1 {
                            PendingMiniRow(icon: "person.2.fill", text: count1)
                        }
                        if let count2 = subtitle2 {
                            PendingMiniRow(icon: "book.fill", text: count2)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }

                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140) // ✅ fixed height so all tiles match
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if let badgeCount, badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color(uiColor: .systemRed))
                        .clipShape(Capsule())
                        .offset(x: 10, y: 10)
                }
            }
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
private struct PendingMiniRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


private struct Chip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(Capsule())
    }
}

//
// MARK: - Mini Stat Card
//

struct AdminMiniStatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(tint)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

//
// MARK: - Revenue Donut Card
//

struct RevenueDistributionCardIOS: View {
    let totalRevenue: Double
    let showRevenue: Bool
    
    struct Segment: Identifiable {
        let id = UUID()
        let name: String
        let value: Double
        let color: Color
    }
    
    private var data: [Segment] {
        let split = RevenueCalculator.calculateSplit(total: totalRevenue)
        return [
            Segment(name: "Admin", value: split.admin, color: Color(uiColor: .systemBlue)),
            Segment(name: "Educators", value: split.educator, color: Color(uiColor: .systemIndigo))
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Revenue Distribution")
                .font(.headline)
            
            if showRevenue {
                HStack(alignment: .center, spacing: 18) {
                    Chart(data) { segment in
                        SectorMark(
                            angle: .value("Revenue", segment.value),
                            innerRadius: .ratio(0.64),
                            angularInset: 2
                        )
                        .foregroundStyle(segment.color)
                    }
                    .frame(width: 120, height: 120)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(data) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 9, height: 9)
                                
                                Text(item.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(item.value.formatted(.currency(code: "INR").precision(.fractionLength(0))))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        
                        Divider().opacity(0.45)
                        
                        HStack {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(totalRevenue.formatted(.currency(code: "INR").precision(.fractionLength(0))))
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
            } else {
                Text("Revenue will show once pricing is enabled.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct PendingSelectionSheet: View {
    let educatorsCount: Int
    let coursesCount: Int
    @Binding var selectedTab: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Handle indicator
            Capsule()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            Text("Pending Review")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                Button {
                    selectedTab = 1
                    dismiss()
                } label: {
                    HStack {
                        Label {
                            Text("Pending Educators")
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "person.2.badge.gearshape.fill")
                                .foregroundColor(.orange)
                        }
                        .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(educatorsCount)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    selectedTab = 2
                    dismiss()
                } label: {
                    HStack {
                        Label {
                            Text("Pending Courses")
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "book.closed.fill")
                                .foregroundColor(.orange)
                        }
                        .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(coursesCount)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.hidden)
    }
}
