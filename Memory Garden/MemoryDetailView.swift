import SwiftUI
import AVKit

struct MemoryDetailView: View {
    let memory: Memory
    @StateObject private var audioPlayer = AudioPlayer()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(memory.title)
                .font(.title2).bold()

            Text(memory.createdAt.formatted(date: .abbreviated, time: .shortened))
                .foregroundStyle(.secondary)

            Divider()

            switch memory.mediaType {
            case .text:
                Text(memory.text ?? "")
                Spacer()

            case .photo:
                if let fn = memory.fileName,
                   let ui = UIImage(contentsOfFile: MediaFileStore.url(for: fn).path) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Text("Photo missing.")
                }
                Spacer()

            case .video:
                if let fn = memory.fileName {
                    VideoPlayer(player: AVPlayer(url: MediaFileStore.url(for: fn)))
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Text("Video missing.")
                }
                Spacer()

            case .audio:
                voicePlayerUI()
                Spacer()
            }
        }
        .padding()
        .onAppear {
            // Load audio file when view opens
            if memory.mediaType == .audio, let fn = memory.fileName {
                audioPlayer.load(url: MediaFileStore.url(for: fn))
            }
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }

    @ViewBuilder
    private func voicePlayerUI() -> some View {
        if let fn = memory.fileName {
            let url = MediaFileStore.url(for: fn)

            VStack(alignment: .leading, spacing: 12) {
                Text("Voice memory")
                    .font(.headline)

                HStack(spacing: 12) {
                    Button {
                        if audioPlayer.isPlaying { audioPlayer.pause() }
                        else {
                            // If not loaded (or file changed), load again then play
                            audioPlayer.load(url: url)
                            audioPlayer.play()
                        }
                    } label: {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }

                    // Simple scrubber
                    Slider(
                        value: Binding(
                            get: { audioPlayer.currentTime },
                            set: { audioPlayer.seek(to: $0) }
                        ),
                        in: 0...(max(audioPlayer.duration, 0.01))
                    )

                    Button {
                        audioPlayer.stop()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.title3)
                    }
                }

                HStack {
                    Text(formatTime(audioPlayer.currentTime))
                    Spacer()
                    Text(formatTime(audioPlayer.duration))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } else {
            Text("Audio missing.")
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let total = max(0, Int(t.rounded()))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
