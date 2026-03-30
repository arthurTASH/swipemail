import SwiftUI

struct OnboardingView: View {
    @Binding var emailAddress: String
    let connectAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Text("SwipeMail")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Connect your Gmail account to start processing unread messages one card at a time.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                TextField("name@gmail.com", text: $emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Email address")
                    .accessibilityHint("Enter the Gmail or work email you want to connect.")

                Button("Continue", action: connectAction)
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("Starts the sign-in flow for the entered email address.")

                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}
