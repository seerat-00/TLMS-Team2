//
//  CourseCompletionView.swift
//  TLMS-project-main
//
//  Created by Chehak on 20/01/26.
//

import Foundation
import SwiftUI
import Supabase

struct CourseCompletionView: View {
    let course: Course
    let userId: UUID
    var onDismiss: () -> Void
    var onViewCertificate: () -> Void
    
    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @State private var publishedCourses: [Course] = [] // For recommendations
    @State private var isLoadingRecommendations = true
    
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var courseService = CourseService()
    
    // MARK: - Subviews broken out to help the type-checker
    
    // Gradient definitions
    private var bannerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.3, green: 0.5, blue: 1.0),
                Color(red: 0.5, green: 0.3, blue: 0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var certificateFillGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.95, blue: 0.97), .white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var certificateBorderGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.7, green: 0.6, blue: 0.9), Color(red: 0.4, green: 0.6, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var rosetteGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var coursePlaceholderGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3), Color(red: 0.5, green: 0.4, blue: 0.9).opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var certificatePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(certificateFillGradient)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(certificateBorderGradient, lineWidth: 3)
            
            VStack(spacing: 6) {
                Image(systemName: "rosette")
                    .font(.system(size: 32))
                    .foregroundStyle(rosetteGradient)
                
                Text("Certificate")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(width: 100, height: 120)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var bannerView: some View {
        ZStack {
            bannerGradient

            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .offset(x: -100, y: -50)

            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 150, height: 150)
                .offset(x: 120, y: 80)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                }
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                Text("Congratulations!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                Text("You've completed")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))

                Text(course.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .lineLimit(2)

                Text("Completed on \(Date().formatted(date: .long, time: .omitted))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.top, 4)
            }
            .padding(.vertical, 60)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(30, corners: [.bottomLeft, .bottomRight])
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
        .edgesIgnoringSafeArea(.top)
    }

    private var certificateSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Certificate")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
            }

            Text("Share your achievement")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                certificatePreview
                
                VStack(spacing: 12) {
                    Button(action: onViewCertificate) {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("View Certificate")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.12))
                        .cornerRadius(12)
                    }

                    Button(action: {
                        // LinkedIn Share Action
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add to LinkedIn")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.47, blue: 0.71), Color(red: 0.0, green: 0.40, blue: 0.60)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(red: 0.0, green: 0.47, blue: 0.71).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(20)
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 30)
    }

    private var ratingSection: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Rate this course")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
            }

            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 32))
                        .foregroundColor(star <= rating ? Color(red: 1.0, green: 0.7, blue: 0.0) : AppTheme.secondaryText.opacity(0.3))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                rating = star
                            }
                        }
                        .scaleEffect(star == rating ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
                }
            }
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Write a review (optional)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)

                TextEditor(text: $reviewText)
                    .frame(height: 100)
                    .padding(12)
                    .background(AppTheme.secondaryGroupedBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.primaryBlue.opacity(0.2), lineWidth: 1)
                    )
            }

            if rating > 0 {
                Button(action: {
                    Task {
                        let success = await courseService.submitReview(
                            courseID: course.id,
                            userID: userId,
                            rating: rating,
                            reviewText: reviewText
                        )
                        
                        if success {
                            // Close the view or show thanks
                            onDismiss()
                        }
                    }
                }) {
                    if courseService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Submit Rating")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.5, green: 0.4, blue: 0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3), radius: 8, x: 0, y: 4)
                .disabled(courseService.isLoading)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("You might also find these helpful")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
            }
            .padding(.horizontal, 20)

            if isLoadingRecommendations {
                ProgressView()
                    .padding(40)
                    .frame(maxWidth: .infinity)
            } else if publishedCourses.isEmpty {
                Text("No recommendations available right now.")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(publishedCourses.prefix(5)), id: \.id) { recommendedCourse in
                            RecommendationCard(course: recommendedCourse, placeholderGradient: coursePlaceholderGradient)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 40)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                bannerView

                VStack(spacing: 24) {
                    certificateSection
                    ratingSection
                    recommendationsSection
                }
            }
        }
        .background(AppTheme.groupedBackground)
        .overlay(
            Button(action: onDismiss) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 36, height: 36)

                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 50)
            .padding(.trailing, 20)
            , alignment: .topTrailing
        )
        .task {
            await fetchRecommendations()
        }
    }
    
    private func fetchRecommendations() async {
        // Fetch published courses excluding current one
        // Mock query or reuse logic
        do {
            isLoadingRecommendations = true
             let supabase = SupabaseManager.shared.client
             let result: [Course] = try await supabase
                 .from("courses")
                 .select()
                 .eq("status", value: "published")
                 .neq("id", value: course.id.uuidString)
                 .limit(5)
                 .execute()
                 .value
             
            publishedCourses = result
        } catch {
            print("Error fetching recommendations: \(error)")
        }
        isLoadingRecommendations = false
    }
}

// MARK: - Recommendation Card Component

struct RecommendationCard: View {
    let course: Course
    let placeholderGradient: LinearGradient
    
    var body: some View {
        NavigationLink(destination: EmptyView()) {
            VStack(alignment: .leading, spacing: 12) {
                // Course Image
                courseImage
                
                // Course Info
                VStack(alignment: .leading, spacing: 6) {
                    // Category Badge
                    Text(course.category)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.12))
                        .cornerRadius(6)
                    
                    Text(course.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                        .foregroundColor(AppTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                        Text("4.8")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
            .frame(width: 180)
            .padding(14)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }
    
    private var courseImage: some View {
        ZStack {
            if let imageURL = course.courseCoverUrl, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_), .empty:
                        placeholderView
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(placeholderGradient)
            .overlay(
                Image(systemName: "book.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
            )
    }
}

// Extension for specific corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

