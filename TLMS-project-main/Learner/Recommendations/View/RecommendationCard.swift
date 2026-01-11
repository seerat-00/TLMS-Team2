import SwiftUI

struct RecommendationCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail
            AsyncImage(url: URL(string: course.thumbnailUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 140)
            .clipped()
            .cornerRadius(12)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(course.category ?? "General")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .textCase(.uppercase)
                
                Text(course.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack {
                    Label(course.level.rawValue, systemImage: "chart.bar.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .frame(width: 240)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
