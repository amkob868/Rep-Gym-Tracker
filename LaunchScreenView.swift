import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Blue gradient background with fallback
            Color(hex: "0a84ff")
                .ignoresSafeArea()
            
            // Orange background image
            Image("orangebackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Dumbbell logo on top
            Image("dumbbell")
                .resizable()
                .scaledToFit()
                .frame(width: 260, height: 260)
                .foregroundColor(.white)
                .offset(y: -120)
        }
    }
}

#Preview {
    LaunchScreenView()
}
