import SwiftUI

// MARK: - Interactive User Guide & Shortcuts View
struct GuideView: View {
    @EnvironmentObject var vm: IslandViewModel
    @State private var diagnosticResult: String?
    @State private var isRunningDiagnostic = false
    @State private var diagnosticSuccess: Bool?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Banner Header
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color(hex: "#1DB954"), Color(hex: "#10853B")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Panduan Interaksi & Gesture")
                            .font(.headline)
                        Text("Dibuat khusus untuk kenyamanan notch macOS • by @uwayxt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 6)

                // MARK: - Gestures & Hover
                VStack(alignment: .leading, spacing: 12) {
                    Text("Interaksi Mouse & Hover")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    guideRow(
                        icon: "cursorarrow.rays",
                        color: .blue,
                        title: "Hover Mouse ke Island",
                        desc: "Dekatkan kursor ke bawah notch untuk efek animasi zoom halus (1.02x scale peek)."
                    )

                    guideRow(
                        icon: "arrow.up.left.and.arrow.down.right",
                        color: .green,
                        title: "Klik Sekali (Tap to Expand)",
                        desc: "Klik pil compact untuk memperluas menjadi kartu lirik lengkap tersinkronisasi dan kontrol lagu."
                    )

                    guideRow(
                        icon: "arrow.down.right.and.arrow.up.left",
                        color: .orange,
                        title: "Klik Lagi untuk Collapse",
                        desc: "Klik sekali lagi pada header kartu untuk merampingkan kembali ukuran island ke notch."
                    )

                    guideRow(
                        icon: "slider.horizontal.below.rectangle",
                        color: .purple,
                        title: "Scrubbing Lirik & Durasi",
                        desc: "Tarik progress bar untuk melompat ke bagian lagu yang Anda inginkan secara instan."
                    )
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))

                // MARK: - Keyboard Shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Keyboard Shortcuts Global")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    shortcutRow(keys: "⌘ ⇧ L", label: "Show / Hide Island", desc: "Sembunyikan atau tampilkan island sewaktu-waktu")
                    shortcutRow(keys: "⌘ ⇧ E", label: "Expand / Collapse", desc: "Buka tampilan lirik penuh tanpa klik mouse")
                    shortcutRow(keys: "⌘ ⇧ D", label: "Toggle Demo Track", desc: "Putar atau hentikan lagu demo bawaan")
                    shortcutRow(keys: "⌘ ,", label: "Buka Preferences", desc: "Buka jendela kustomisasi tema & pengaturan")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))

                // MARK: - Spotify Diagnostics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Diagnostik Izin & Koneksi Spotify")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("MelodyIsland membutuhkan izin Apple Events untuk membaca lagu dari aplikasi Spotify.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            runDiagnostic()
                        } label: {
                            HStack {
                                if isRunningDiagnostic {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "waveform.badge.magnifyingglass")
                                }
                                Text("Cek Koneksi Spotify Sekarang")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#1DB954"))
                        .disabled(isRunningDiagnostic)

                        Spacer()
                    }

                    if let result = diagnosticResult {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: diagnosticSuccess == true ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(diagnosticSuccess == true ? .green : .orange)
                            Text(result)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))
            }
            .padding(20)
        }
    }

    private func runDiagnostic() {
        isRunningDiagnostic = true
        Task {
            let res = await vm.testMusicPlayerConnection()
            self.diagnosticSuccess = res.success
            self.diagnosticResult = res.message
            self.isRunningDiagnostic = false
        }
    }

    private func guideRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(Circle().fill(color.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func shortcutRow(keys: String, label: String, desc: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(keys)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.08)))
        }
    }
}
