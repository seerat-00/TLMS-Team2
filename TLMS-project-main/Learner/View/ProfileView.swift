//
//  ProfileView.swift
//  TLMS-project-main
//
//  Learner Profile UI
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var authService: AuthService
    @State private var showingEditSheet = false
    @State private var editedName = ""
    @State private var showSignOutAlert = false
    @AppStorage("reminders_enabled") private var remindersEnabled = false

    
    init(user: User?) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
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
                        
                        // Certificates Section (Prominent)
                        certificatesSection
                        
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
                // ✅ If toggle already ON, ensure reminder exists
                   if remindersEnabled {
                       let granted = await LocalNotificationManager.shared.requestPermission()
                       if granted {
                           await LocalNotificationManager.shared.scheduleDailyReminder(hour: 9, minute: 0)
                       }
                   }
            }
            .refreshable {
                await viewModel.loadProfileData()
            }
            // Edit Sheet
            .sheet(isPresented: $showingEditSheet) {
                editProfileSheet
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
                Circle()
                    .fill(AppTheme.primaryBlue.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Text(initials(for: viewModel.user?.fullName ?? ""))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primaryBlue)
                
                // Edit Badge
                Button(action: {
                    editedName = viewModel.user?.fullName ?? ""
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title)
                        .foregroundColor(AppTheme.primaryBlue)
                        .background(Circle().fill(.white))
                }
                .offset(x: 35, y: 35)
            }
            
            // Info
            VStack(spacing: 8) {
                Text(viewModel.user?.fullName ?? "Learner")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                Text(viewModel.user?.email ?? "")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var certificatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Certificates")
                    .font(.title3.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if !viewModel.certificates.isEmpty {
                    Text("\(viewModel.certificates.count)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.primaryBlue)
                        .clipShape(Capsule())
                }
            }
            
            if viewModel.certificates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "seal")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.secondaryText.opacity(0.3))
                    
                    Text("No certificates earned yet.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(AppTheme.secondaryGroupedBackground)
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.certificates) { certificate in
                        NavigationLink(destination: CertificateView(certificate: certificate)) {
                            CertificateCard(certificate: certificate)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    // Study Reminder Section ✅ NEW
    private var studyReminderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study Reminder")
                .font(.title3.bold())
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 12) {
                Toggle("Enable daily reminder", isOn: $viewModel.reminderEnabled)
                    .onChange(of: viewModel.reminderEnabled) { _ in
                        Task {
                            await viewModel.updateReminderSettings()
                        }
                    }
                
                if viewModel.reminderEnabled {
                    DatePicker(
                        "Reminder time",
                        selection: $viewModel.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .onChange(of: viewModel.reminderTime) { _ in
                        Task {
                            await viewModel.updateReminderSettings()
                        }
                    }
                }
            }
            .padding()
            .background(AppTheme.secondaryGroupedBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }

    
    private var accountActionsSection: some View {
        VStack(spacing: 1) {
            
            // ✅ Reminders Toggle
            HStack {
                Label("Daily Study Reminder", systemImage: "bell.badge.fill")
                    .foregroundColor(AppTheme.primaryText)

                Spacer()

                Toggle("", isOn: $remindersEnabled)
                    .labelsHidden()
                    .tint(AppTheme.primaryBlue)
                    .onChange(of: remindersEnabled) { newValue in
                        Task {
                            if newValue {
                                let granted = await LocalNotificationManager.shared.requestPermission()
                                if granted {
                                    await LocalNotificationManager.shared.scheduleDailyReminder(hour: 9, minute: 0)
                                } else {
                                    // permission denied → toggle OFF
                                    remindersEnabled = false
                                }
                            } else {
                                await LocalNotificationManager.shared.cancelDailyReminder()
                            }
                        }
                    }
            }
            .padding()
            .background(AppTheme.secondaryGroupedBackground)
            .cornerRadius(12)


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

// Sub-component for Completed Course
struct CompletedCourseCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                Rectangle()
                    .fill(course.categoryColor.opacity(0.1))
                    .frame(height: 100)
                
                Image(systemName: course.categoryIcon)
                    .font(.largeTitle)
                    .foregroundColor(course.categoryColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(AppTheme.primaryText)
                
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(AppTheme.successGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.successGreen.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(12)
        }
        .frame(width: 160)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
