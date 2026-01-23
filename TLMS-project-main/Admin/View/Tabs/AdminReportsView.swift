import SwiftUI
import Charts

struct AdminReportsView: View {
    let activeCourses: [Course]
    let allEnrollments: [Enrollment]
    let allUsers: [User]
    let selectedTimeFilter: AnalyticsTimeFilter
    let isRevenueEnabled: Bool

    @Environment(\.dismiss) private var dismiss

    // MARK: - Filtered Data

    private var filteredEnrollments: [Enrollment] {
        allEnrollments.filter {
            if let date = $0.enrolledAt {
                return selectedTimeFilter.isDateInPeriod(date)
            }
            return false
        }
    }

    private var filteredUsersCount: Int {
        allUsers.filter { selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }

    private var filteredCoursesCount: Int {
        activeCourses.filter { selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }

    private var totalRevenue: Double {
        let coursePriceMap = Dictionary(uniqueKeysWithValues: activeCourses.map { ($0.id, $0.price ?? 0) })
        return filteredEnrollments.reduce(0) { total, e in
            total + (coursePriceMap[e.courseID] ?? 0)
        }
    }

    // MARK: - Charts Data

    struct DailyRevenuePoint: Identifiable {
        let id = UUID()
        let day: Date
        let revenue: Double
    }

    private var revenueTrend: [DailyRevenuePoint] {
        guard isRevenueEnabled else { return [] }

        let coursePriceMap = Dictionary(uniqueKeysWithValues: activeCourses.map { ($0.id, $0.price ?? 0) })

        // Group enrollments by day
        let grouped = Dictionary(grouping: filteredEnrollments) { enrollment -> Date in
            let date = enrollment.enrolledAt ?? Date()
            return Calendar.current.startOfDay(for: date)
        }

        // Create points sorted by date
        return grouped
            .map { day, enrollments in
                let revenue = enrollments.reduce(0) { $0 + (coursePriceMap[$1.courseID] ?? 0) }
                return DailyRevenuePoint(day: day, revenue: revenue)
            }
            .sorted { $0.day < $1.day }
    }

    // MARK: - Top Courses

    struct CoursePerformance: Identifiable {
        let id: UUID
        let title: String
        let enrollments: Int
        let revenue: Double
    }

    private var topCourses: [CoursePerformance] {
        let courseMap = Dictionary(uniqueKeysWithValues: activeCourses.map { ($0.id, $0) })
        let coursePriceMap = Dictionary(uniqueKeysWithValues: activeCourses.map { ($0.id, $0.price ?? 0) })

        // Enrollment count per course
        let grouped = Dictionary(grouping: filteredEnrollments, by: { $0.courseID })

        let performances: [CoursePerformance] = grouped.compactMap { courseID, enrollments in
            guard let course = courseMap[courseID] else { return nil }
            let count = enrollments.count
            let revenue = Double(count) * (coursePriceMap[courseID] ?? 0)
            return CoursePerformance(id: courseID, title: course.title, enrollments: count, revenue: revenue)
        }

        return performances
            .sorted { $0.enrollments > $1.enrollments }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - View

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Summary")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                            GridItem(.flexible(), spacing: 12)],
                                  spacing: 12) {

                            ReportMiniCard(
                                title: "Revenue",
                                value: isRevenueEnabled
                                ? totalRevenue.formatted(.currency(code: "INR").precision(.fractionLength(0)))
                                : "--",
                                icon: "banknote.fill",
                                tint: Color(uiColor: .systemGreen)
                            )

                            ReportMiniCard(
                                title: "Enrollments",
                                value: "\(filteredEnrollments.count)",
                                icon: "graduationcap.fill",
                                tint: Color(uiColor: .systemIndigo)
                            )

                            ReportMiniCard(
                                title: "Users",
                                value: "\(filteredUsersCount)",
                                icon: "person.3.fill",
                                tint: Color(uiColor: .systemBlue)
                            )

                            ReportMiniCard(
                                title: "Courses",
                                value: "\(filteredCoursesCount)",
                                icon: "book.closed.fill",
                                tint: Color(uiColor: .systemOrange)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Revenue Trend Chart
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Revenue Trend")
                                .font(.headline)
                            Spacer()
                            Text(selectedTimeFilter.rawValue)
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.secondary)
                        }

                        if isRevenueEnabled {
                            if revenueTrend.isEmpty {
                                EmptyReportState(
                                    icon: "chart.line.downtrend.xyaxis",
                                    title: "No data available",
                                    message: "Revenue trend will appear once there are enrollments in this period."
                                )
                                .frame(height: 180)
                            } else {
                                Chart(revenueTrend) { point in
                                    LineMark(
                                        x: .value("Day", point.day),
                                        y: .value("Revenue", point.revenue)
                                    )
                                    PointMark(
                                        x: .value("Day", point.day),
                                        y: .value("Revenue", point.revenue)
                                    )
                                }
                                .frame(height: 200)
                                .chartYAxis {
                                    AxisMarks(position: .leading)
                                }
                            }
                        } else {
                            EmptyReportState(
                                icon: "nosign",
                                title: "Revenue disabled",
                                message: "Enable pricing to view revenue analytics."
                            )
                            .frame(height: 180)
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Top Courses
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Courses")
                            .font(.headline)

                        if topCourses.isEmpty {
                            EmptyReportState(
                                icon: "book.closed",
                                title: "No enrollments yet",
                                message: "Top courses will show after learners enroll."
                            )
                            .padding(.vertical, 16)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(topCourses) { item in
                                    TopCourseRow(
                                        title: item.title,
                                        enrollments: item.enrollments,
                                        revenue: item.revenue,
                                        showRevenue: isRevenueEnabled
                                    )
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 14)
                }
                .padding(.bottom, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }
}

// MARK: - Components

struct ReportMiniCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint)

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

struct TopCourseRow: View {
    let title: String
    let enrollments: Int
    let revenue: Double
    let showRevenue: Bool

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(enrollments) enrollments")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if showRevenue {
                Text(revenue.formatted(.currency(code: "INR").precision(.fractionLength(0))))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct EmptyReportState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundColor(.secondary.opacity(0.6))

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }
}
