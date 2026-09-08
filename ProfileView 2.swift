import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PROFILE")
                            .font(ForgeTheme.bebas(48))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Text("Your fitness journey")
                            .font(ForgeTheme.nunito(15, weight: .light))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    .padding(.top, 20)
                    
                    // Profile card
                    VStack(spacing: 20) {
                        // Avatar with photo picker
                        ZStack(alignment: .bottomTrailing) {
                            if let profileImage = appState.profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(appState.goal.color, lineWidth: 3)
                                    )
                            } else {
                                Circle()
                                    .fill(appState.goal.color)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(String(appState.userName.prefix(1)).uppercased())
                                            .font(ForgeTheme.bebas(48))
                                            .foregroundColor(.black)
                                    )
                            }
                            
                            // Camera button
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Circle()
                                    .fill(ForgeTheme.surface2)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(ForgeTheme.background, lineWidth: 2)
                                    )
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(appState.goal.color)
                                    )
                            }
                            .onChange(of: selectedPhotoItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        await MainActor.run {
                                            appState.profileImage = image
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Remove photo button (only show if there's a photo)
                        if appState.profileImage != nil {
                            Button {
                                withAnimation {
                                    appState.profileImage = nil
                                    selectedPhotoItem = nil
                                }
                            } label: {
                                Text("Remove Photo")
                                    .font(ForgeTheme.nunito(12, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Name section
                        if isEditingName {
                            VStack(spacing: 12) {
                                TextField("Your name", text: $editedName)
                                    .font(ForgeTheme.nunito(18, weight: .bold))
                                    .foregroundColor(ForgeTheme.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(ForgeTheme.surface)
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
                                    )
                                
                                HStack(spacing: 12) {
                                    Button("Cancel") {
                                        isEditingName = false
                                    }
                                    .font(ForgeTheme.nunito(14, weight: .bold))
                                    .foregroundColor(ForgeTheme.textMuted)
                                    
                                    Button("Save") {
                                        if !editedName.trimmingCharacters(in: .whitespaces).isEmpty {
                                            appState.userName = editedName.trimmingCharacters(in: .whitespaces)
                                            isEditingName = false
                                        }
                                    }
                                    .font(ForgeTheme.bebas(18))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(appState.goal.color)
                                    .cornerRadius(12)
                                }
                            }
                        } else {
                            VStack(spacing: 4) {
                                Text(appState.userName)
                                    .font(ForgeTheme.bebas(36))
                                    .foregroundColor(ForgeTheme.textPrimary)
                                
                                Button {
                                    editedName = appState.userName
                                    isEditingName = true
                                } label: {
                                    Text("Edit name")
                                        .font(ForgeTheme.nunito(13, weight: .semibold))
                                        .foregroundColor(appState.goal.color)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ForgeTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ForgeTheme.border, lineWidth: 1.5))
                    )
                    
                    // Stats section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("STATS")
                            .font(ForgeTheme.nunito(11, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        VStack(spacing: 12) {
                            StatRow(title: "Current Goal", value: appState.goal.rawValue, color: appState.goal.color)
                            StatRow(title: "Current Streak", value: "\(appState.streak) days", color: ForgeTheme.accentCut)
                            StatRow(title: "Today's Workout", value: appState.todayName, color: ForgeTheme.accentRecomp)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title.uppercased())
                .font(ForgeTheme.nunito(12, weight: .bold))
                .foregroundColor(ForgeTheme.textMuted)
            
            Spacer()
            
            Text(value)
                .font(ForgeTheme.bebas(20))
                .foregroundColor(ForgeTheme.textPrimary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ForgeTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
        )
    }
}
