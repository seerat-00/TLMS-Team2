//
//  CertificateView.swift
//  TLMS-project-main
//
//  Beautiful certificate design with download and share functionality
//

import SwiftUI
import PDFKit

struct CertificateView: View {
    let certificate: Certificate
    @State private var showShareSheet = false
    @State private var certificateImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Certificate Card
                certificateCard
                    .padding()
                
                // Actions
                VStack(spacing: 12) {
                    PremiumButton(
                        title: "Download Certificate",
                        icon: "arrow.down.circle.fill",
                        action: downloadCertificate
                    )
                    
                    SecondaryButton(
                        title: "Share",
                        icon: "square.and.arrow.up",
                        action: { showShareSheet = true }
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle("Certificate")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let image = certificateImage {
                ShareSheet(items: [image])
            }
        }
        .onAppear {
            generateCertificateImage()
        }
        .alert("Certificate Saved", isPresented: $showDownloadSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The certificate has been saved to your Photos library.")
        }
    }
    
    // MARK: - Certificate Card
    
    private var certificateCard: some View {
        ZStack {
            // Background with gradient border
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppTheme.primaryBlue,
                                    AppTheme.accentPurple,
                                    AppTheme.accentCyan
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(
                    color: AppTheme.elevatedShadow.color,
                    radius: AppTheme.elevatedShadow.radius,
                    x: AppTheme.elevatedShadow.x,
                    y: AppTheme.elevatedShadow.y
                )
            
            // Content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(AppTheme.oceanGradient)
                    
                    Text("Certificate of Completion")
                        .font(.title2.bold())
                        .foregroundColor(AppTheme.primaryText)
                }
                
                Divider()
                    .overlay(AppTheme.primaryBlue.opacity(0.3))
                
                // Main Content
                VStack(spacing: 16) {
                    Text("This certifies that")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Text(certificate.userName)
                        .font(.title.bold())
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text("has successfully completed")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Text(certificate.courseName)
                        .font(.title3.bold())
                        .foregroundColor(AppTheme.primaryBlue)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Divider()
                    .overlay(AppTheme.primaryBlue.opacity(0.3))
                
                // Footer
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Completion Date")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                            Text(certificate.formattedCompletionDate)
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.primaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Instructor")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                            Text(certificate.instructorName)
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.primaryText)
                        }
                    }
                    
                    Text("Certificate No: \(certificate.certificateNumber)")
                        .font(.caption2)
                        .foregroundColor(AppTheme.tertiaryText)
                        .padding(.top, 8)
                }
            }
            .padding(32)
        }
        .aspectRatio(1.414, contentMode: .fit) // A4 ratio
    }
    
    // MARK: - Actions
    
    private func generateCertificateImage() {
        // Generate image representation of certificate
        let renderer = ImageRenderer(content: certificateCard)
        renderer.scale = 3.0 // High resolution
        
        if let image = renderer.uiImage {
            certificateImage = image
        }
    }
    
    @State private var showDownloadSuccess = false

    private func downloadCertificate() {
        guard let image = certificateImage else { return }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Save to photo library
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Show success
        showDownloadSuccess = true
    }
}

// MARK: - Certificates List View

struct CertificatesListView: View {
    let userId: UUID
    
    @StateObject private var certificateService = CertificateService()
    @State private var certificates: [Certificate] = []
    
    var body: some View {
        Group {
            if certificateService.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if certificates.isEmpty {
                emptyState
            } else {
                certificatesList
            }
        }
        .navigationTitle("My Certificates")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.groupedBackground)
        .task {
            await loadCertificates()
        }
    }
    
    private var certificatesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(certificates) { certificate in
                    NavigationLink(destination: CertificateView(certificate: certificate)) {
                        CertificateCard(certificate: certificate)
                    }
                    .buttonStyle(.plain)
                    .fadeInOnAppear()
                }
            }
            .padding()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "seal")
                .font(.system(size: 80))
                .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Certificates Yet")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                Text("Complete courses to earn certificates")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func loadCertificates() async {
        certificates = await certificateService.fetchCertificates(userId: userId)
    }
}

// MARK: - Certificate Card (for list)

struct CertificateCard: View {
    let certificate: Certificate
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.primaryBlue.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "seal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.oceanGradient)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(certificate.courseName)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(2)
                
                Text("Completed \(certificate.formattedCompletionDate)")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                
                Text(certificate.certificateNumber)
                    .font(.caption2)
                    .foregroundColor(AppTheme.tertiaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding()
        .premiumCard()
        .pressableScale()
    }
}



#Preview {
    NavigationView {
        CertificateView(
            certificate: Certificate(
                userId: UUID(),
                courseId: UUID(),
                userName: "John Doe",
                courseName: "Advanced SwiftUI Development",
                certificateNumber: "TLMS-1234567890-5678",
                instructorName: "Jane Smith"
            )
        )
    }
}
