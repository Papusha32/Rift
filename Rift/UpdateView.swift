import SwiftUI

struct UpdateView: View {
    @EnvironmentObject private var store: UpdateStore

    var body: some View {
        ZStack {
            // Dark card background
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.10))
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.07), lineWidth: 0.5)

            // Content by state
            switch store.state {
            case .available(let version, _):
                availableContent(newVersion: version)
            case .downloading(let progress):
                downloadingContent(progress: progress)
            case .downloaded:
                downloadedContent
            case .installing:
                installingContent
            case .error(let msg):
                errorContent(msg)
            default:
                EmptyView()
            }
        }
        .frame(width: 320, height: 200)
    }

    // MARK: - Available

    private func availableContent(newVersion: String) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Versions
            HStack(spacing: 20) {
                versionLabel(store.currentVersion, dimmed: true)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                versionLabel(newVersion, dimmed: false)
            }

            Spacer().frame(height: 10)

            Text("Update available")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            Text("A new version of Rift is ready.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.35))
                .padding(.top, 3)

            Spacer()

            // Buttons
            HStack(spacing: 10) {
                Button("Later") {
                    store.dismiss()
                }
                .buttonStyle(RiftUpdateButtonStyle(filled: false))

                Button("Download & Install") {
                    store.downloadUpdate()
                }
                .buttonStyle(RiftUpdateButtonStyle(filled: true))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    // MARK: - Downloading

    private func downloadingContent(progress: Double) -> some View {
        VStack(spacing: 14) {
            Text("Downloading…")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.6))
                        .frame(width: geo.size.width * CGFloat(progress), height: 3)
                        .animation(.linear(duration: 0.2), value: progress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 24)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Downloaded

    private var downloadedContent: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 28, weight: .thin))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 4) {
                Text("Ready to install")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                Text("Rift will restart automatically.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.35))
            }

            Button("Install & Restart") {
                store.installUpdate()
            }
            .buttonStyle(RiftUpdateButtonStyle(filled: true))
            .padding(.horizontal, 20)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Installing

    private var installingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.white.opacity(0.5))

            Text("Installing…")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Text("Rift will relaunch in a moment.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24, weight: .thin))
                .foregroundColor(.white.opacity(0.4))

            Text("Update failed")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text(message)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 20)

            Button("Dismiss") {
                store.dismiss()
            }
            .buttonStyle(RiftUpdateButtonStyle(filled: false))
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func versionLabel(_ version: String, dimmed: Bool) -> some View {
        Text("v\(version)")
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundColor(dimmed ? .white.opacity(0.3) : .white.opacity(0.85))
    }
}

// MARK: - Button style matching Rift's minimal aesthetic

struct RiftUpdateButtonStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(filled ? .black : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(filled ? Color.white.opacity(configuration.isPressed ? 0.7 : 0.85) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(filled ? Color.clear : Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
