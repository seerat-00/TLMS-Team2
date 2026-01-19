//
//  EducatorProfileView.swift
//  TLMS-project-main
//
//  Educator Profile UI
//

import SwiftUI
import PhotosUI

struct EducatorProfileView: View {
    @StateObject private var viewModel: EducatorProfileViewModel
    @EnvironmentObject var authService: AuthService
    @State private var showingEditSheet = false
    @State private var editedName = ""
    @State private var showSignOutAlert = false
    
    // Resume upload
    @State private var isImportingResume = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoOptions = false
    @State private var showLibraryPicker = false
    
    init(user: User?) {
        _viewModel = StateObject(wrappedValue: EducatorProfileViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        profileHeader
                        
                        // Professional Info
                        professionalInfoSection
                        
                        // Account Actions
                        accountActionsSection
                        
                        // Sign Out Button
                        signOutButton
                            .padding(.top, 20)
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadProfileData()
            }
            .refreshable {
                await viewModel.loadProfileData()
            }
            // Edit Sheet
            .sheet(isPresented: $showingEditSheet) {
                editProfileSheet
            }
            // Resume Importer
            .fileImporter(
                isPresented: $isImportingResume,
                allowedContentTypes: [.pdf, .text, .data], // Simplified types
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        guard url.startAccessingSecurityScopedResource() else { return }
                        defer { url.stopAccessingSecurityScopedResource() }
                        
                        // Read data synchronously while we have access
                        if let data = try? Data(contentsOf: url) {
                            let fileName = url.lastPathComponent
                            Task {
                                await viewModel.uploadResume(data: data, fileName: fileName)
                            }
                        } else {
                            print("Failed to read data from security scoped URL")
                        }
                    }
                case .failure(let error):
                    print("Import failed: \(error.localizedDescription)")
                }
            }
            // Photo Picker Changes
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                if let newValue = newValue {
                    Task {
                        await viewModel.uploadProfilePicture(item: newValue)
                        selectedPhotoItem = nil
                    }
                }
            }
            // Alert for messages
            .alert("Profile Update", isPresented: Binding<Bool>(
                get: { viewModel.saveMessage != nil || viewModel.errorMessage != nil },
                set: { _ in
                    viewModel.saveMessage = nil
                    viewModel.errorMessage = nil
                }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.saveMessage ?? viewModel.errorMessage ?? "")
            }
            // Reset Password Alert
            .alert("Password Reset", isPresented: $viewModel.resetEmailSent) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A password reset link has been sent to \(viewModel.user?.email ?? "your email").")
            }
            // Sign Out Confirmation
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authService.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Components
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                if let imageUrl = viewModel.profileImageURL, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primaryBlue.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                ProgressView()
                            }
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        case .failure:
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Circle()
                        .fill(AppTheme.primaryBlue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Text(initials(for: viewModel.user?.fullName ?? ""))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primaryBlue)
                }
                
                // Photo Picker Overlay
                if viewModel.isUploadingImage {
                    ProgressView()
                        .tint(.white)
                        .background(Circle().fill(.black.opacity(0.5)).frame(width: 100, height: 100))
                }
                
                // Edit/Remove Menu
                Menu {
                    Button(action: {
                        showLibraryPicker = true
                    }) {
                        Label("Choose New Photo", systemImage: "photo.on.rectangle")
                    }
                    
                    if viewModel.profileImageURL != nil {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.removeProfilePicture()
                            }
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "camera.circle.fill")
                        .font(.title)
                        .foregroundColor(AppTheme.primaryBlue)
                        .background(Circle().fill(.white))
                }
                .offset(x: 35, y: 35)
                .photosPicker(isPresented: $showLibraryPicker, selection: $selectedPhotoItem, matching: .images)
            }
            
            // Info
            VStack(spacing: 8) {
                HStack {
                    Text(viewModel.user?.fullName ?? "Educator")
                        .font(.title2.bold())
                        .foregroundColor(AppTheme.primaryText)
                    
                    Button(action: {
                        editedName = viewModel.user?.fullName ?? ""
                        showingEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
                
                Text(viewModel.user?.email ?? "")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                
                // Role Badge
                Text("Educator")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.primaryBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryBlue.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var professionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Professional Info")
                .font(.title3.bold())
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 12) {
                // Resume Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Resume / CV")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryText)
                        
                        if let _ = viewModel.user?.resumeUrl {
                             Text("Resume uploaded")
                                .font(.caption)
                                .foregroundColor(AppTheme.successGreen)
                        } else {
                            Text("No resume uploaded")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isImportingResume = true
                    }) {
                        if viewModel.isUploadingResume {
                            ProgressView()
                        } else {
                            Text(viewModel.user?.resumeUrl == nil ? "Upload" : "Update")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppTheme.primaryBlue)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(viewModel.isUploadingResume)
                }
                .padding()
                .background(AppTheme.secondaryGroupedBackground)
                .cornerRadius(12)
            }
        }
    }
    
    private var accountActionsSection: some View {
        VStack(spacing: 1) {
            // Change Password
            NavigationLink(destination: ChangePasswordView()) {
                HStack {
                    Label("Change Password", systemImage: "lock.rotation")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(AppTheme.secondaryGroupedBackground)
            }
            .buttonStyle(.plain)
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var signOutButton: some View {
        Button(role: .destructive, action: {
            showSignOutAlert = true
        }) {
            HStack {
                Spacer()
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(AppTheme.secondaryGroupedBackground)
            .foregroundColor(.red)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var editProfileSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $editedName)
                        .textContentType(.name)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingEditSheet = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.updateProfile(fullName: editedName)
                            showingEditSheet = false
                        }
                    }
                    .disabled(editedName.isEmpty || viewModel.isSaving)
                }
            }
        }
    }
    
    private func initials(for name: String) -> String {
        let components = name.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if components.isEmpty { return "" }
        
        if let first = components.first, let last = components.last, components.count > 1 {
            return "\(first.prefix(1))\(last.prefix(1))".uppercased()
        }
        
        return "\(components.first?.prefix(2) ?? "")".uppercased()
    }
}
