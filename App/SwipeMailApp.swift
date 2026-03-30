import SwiftUI

@main
struct SwipeMailApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var sessionController: AppSessionController

    init() {
        let dependencies = AppDependencies.live()
        _sessionController = StateObject(
            wrappedValue: AppSessionController(
                authService: dependencies.authService,
                gmailService: dependencies.gmailService,
                queueService: dependencies.queueService,
                syncEngine: dependencies.syncEngine,
                connectivityMonitor: dependencies.connectivityMonitor,
                analyticsService: dependencies.analyticsService,
                logger: dependencies.logger
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch sessionController.route {
                case .launching:
                    ProgressView("Loading SwipeMail")
                        .accessibilityLabel("Loading SwipeMail")
                case .onboarding:
                    OnboardingView(
                        emailAddress: $sessionController.onboardingEmailAddress,
                        connectAction: sessionController.beginSignIn
                    )
                case .inbox:
                    ZStack(alignment: .leading) {
                        InboxPlaceholderView(
                            state: sessionController.inboxViewState,
                            isOffline: !sessionController.connectivityStatus.isOnline,
                            actionHandler: sessionController.apply,
                            retryAction: sessionController.reloadInbox,
                            signOutAction: sessionController.signOut
                        )
                        .overlay(alignment: .topLeading) {
                            Button(action: sessionController.toggleDrawer) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(.thinMaterial, in: Circle())
                            }
                            .accessibilityLabel("Open navigation menu")
                            .accessibilityHint("Opens the side drawer with resume, exit, and settings.")
                            .padding(.leading, 16)
                            .padding(.top, 12)
                        }

                        if sessionController.isDrawerPresented {
                            Color.black.opacity(0.24)
                                .ignoresSafeArea()
                                .contentShape(Rectangle())
                                .onTapGesture(perform: sessionController.closeDrawer)

                            drawerPanel
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.28, dampingFraction: 0.84), value: sessionController.isDrawerPresented)
                case .settings:
                    settingsScreen
                case .exited:
                    exitedPlaceholder
                }
            }
            .overlay(alignment: .top) {
                if let bannerState = sessionController.bannerState {
                    StatusBanner(state: bannerState, dismissAction: sessionController.dismissBanner)
                        .padding(.top, 12)
                }
            }
            .task {
                await sessionController.bootstrap()
            }
            .onOpenURL { url in
                sessionController.handleOpenURL(url)
            }
            .onChange(of: scenePhase) { _, newPhase in
                sessionController.handleScenePhaseChange(newPhase)
            }
        }
    }

    private var drawerPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("SwipeMail")
                    .font(.title3.weight(.bold))

                Spacer()

                Button("Close", action: sessionController.closeDrawer)
                    .font(.subheadline.weight(.semibold))
                    .accessibilityHint("Closes the navigation drawer.")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Navigation")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                drawerPlaceholderRow(title: "Resume", systemImage: "play.fill")
                    .onTapGesture(perform: sessionController.resumeSignedInFlow)
                    .accessibilityAddTraits(.isButton)

                drawerPlaceholderRow(title: "Exit", systemImage: "rectangle.portrait.and.arrow.right")
                    .onTapGesture(perform: sessionController.exitSignedInFlow)
                    .accessibilityAddTraits(.isButton)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text("More")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                drawerPlaceholderRow(title: "Settings", systemImage: "gearshape.fill")
                    .onTapGesture(perform: sessionController.openSettings)
                    .accessibilityAddTraits(.isButton)
            }
        }
        .padding(24)
        .frame(maxWidth: 280, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 18, y: 8)
        .padding(.leading, 12)
        .padding(.vertical, 12)
    }

    private func drawerPlaceholderRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 18)
                .foregroundStyle(.primary)

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 10)
    }

    private var settingsScreen: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: sessionController.closeSettings) {
                        Label("Back", systemImage: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                    }
                    .accessibilityHint("Returns to the inbox without changing account state.")

                    Spacer()

                    Text("Settings")
                        .font(.headline.weight(.bold))

                    Spacer()

                    Button("Close", action: sessionController.closeSettings)
                        .font(.subheadline.weight(.semibold))
                        .accessibilityHint("Closes settings and returns to the inbox.")
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                Spacer()

                VStack(spacing: 18) {
                    Text("Settings")
                        .font(.title.bold())

                    Text("Account and session controls live here.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)

                    VStack(spacing: 14) {
                        Button(action: sessionController.disconnectFromSettings) {
                            settingsActionLabel(title: "DISCONNECT", tint: .red)
                        }
                        .accessibilityHint("Disconnects the account and returns to onboarding.")

                        Button(action: sessionController.exitFromSettings) {
                            settingsActionLabel(title: "EXIT")
                        }
                        .accessibilityHint("Leaves the signed-in flow but preserves the current session.")
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: 360)
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: 10)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }

    private var exitedPlaceholder: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "pause.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("SwipeMail paused")
                .font(.title.bold())

            Text("Your session is preserved. Resume to return to your inbox.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Button("Resume", action: sessionController.resumeSignedInFlow)
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Returns to the inbox using the preserved session.")

            Spacer()
        }
        .padding()
    }

    private func settingsActionLabel(title: String, tint: Color = .primary) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }

}
