import SwiftUI
import PhotosUI
import UIKit
import AVFoundation

struct AddMemoryView: View {
    @Environment(\.dismiss) private var dismiss

    // Inputs
    let onSave: (Memory) -> Void
    
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var draftID = UUID()
    // Form state
    @State private var title: String = ""
    @State private var selectedType: MemoryMediaType = .text

    // Text
    @State private var textBody: String = ""

    // Photo / Video picker
    @State private var photoItem: PhotosPickerItem?
    @State private var videoItem: PhotosPickerItem?

    // Loaded results
    @State private var pickedImage: UIImage?
    @State private var pickedVideoTempURL: URL?
    
    @State private var plantType: PlantType = .daisy

    // Errors
    @State private var errorMessage: String?

    // Helpers
    private var titleTrimmed: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var textTrimmed: String { textBody.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canSave: Bool {
        if titleTrimmed.isEmpty { return false }

        switch selectedType {
        case .text:
            return !textTrimmed.isEmpty
        case .photo:
            return pickedImage != nil
        case .video:
            return pickedVideoTempURL != nil
        case .audio:
            return audioRecorder.recordedURL != nil && !audioRecorder.isRecording
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. First snow in Chicago", text: $title)
                }

                Section("Type") {
                    Picker("Type", selection: $selectedType) {
                        Text("Text").tag(MemoryMediaType.text)
                        Text("Photo").tag(MemoryMediaType.photo)
                        Text("Video").tag(MemoryMediaType.video)
                        Text("Voice").tag(MemoryMediaType.audio)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Choose a plant") {
                    Picker("Plant", selection: $plantType) {
                        ForEach(PlantType.allCases, id: \.self) { p in
                            Text("\(p.emoji) \(p.name)").tag(p)
                        }
                    }
                }

                // Text
                if selectedType == .text {
                    Section("Memory") {
                        TextEditor(text: $textBody)
                            .frame(minHeight: 160)
                    }
                }

                // Photo
                if selectedType == .photo {
                    Section("Photo") {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo")
                                Text(pickedImage == nil ? "Pick a photo" : "Change photo")
                            }
                        }

                        if let img = pickedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 260)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            Text("No photo selected yet.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Video
                if selectedType == .video {
                    Section("Video") {
                        PhotosPicker(selection: $videoItem, matching: .videos) {
                            HStack {
                                Image(systemName: "video")
                                Text(pickedVideoTempURL == nil ? "Pick a video" : "Change video")
                            }
                        }

                        if pickedVideoTempURL != nil {
                            Text("Video selected ✅")
                        } else {
                            Text("No video selected yet.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Voice
                if selectedType == .audio {
                    Section("Voice") {

                        Button(audioRecorder.isRecording ? "Stop Recording"
                                                         : "Start Recording") {

                            if audioRecorder.isRecording {
                                audioRecorder.stopRecording()

                            } else {
                                let fileName = "\(draftID.uuidString).m4a"
                                let url = MediaFileStore.url(for: fileName)

                                do {
                                    try audioRecorder.startRecording(to: url)
                                } catch {
                                    errorMessage =
                                      "Couldn’t start recording. Check microphone permission."
                                }
                            }
                        }

                        if audioRecorder.recordedURL != nil &&
                           !audioRecorder.isRecording {

                            Text("Voice recorded ✅")
                                .foregroundStyle(.green)

                        } else {
                            Text("Record a voice note for this memory.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Plant a Memory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTapped() }
                        .disabled(!canSave)
                }
            }
        }
        // handlers
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            errorMessage = nil
            pickedImage = nil

            Task {
                do {
                    // Load image data -> UIImage
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        pickedImage = ui
                    } else {
                        errorMessage = "Couldn’t load that photo."
                    }
                } catch {
                    errorMessage = "Couldn’t load that photo."
                }
            }
        }
        .onChange(of: videoItem) { _, newItem in
            guard let newItem else { return }
            errorMessage = nil
            pickedVideoTempURL = nil

            Task {
                do {
                    // This is often a temporary URL; we’ll copy it into Documents when saving.
                    if let url = try await newItem.loadTransferable(type: URL.self) {
                        pickedVideoTempURL = url
                    } else {
                        errorMessage = "Couldn’t load that video."
                    }
                } catch {
                    errorMessage = "Couldn’t load that video."
                }
            }
        }
        .onChange(of: selectedType) { _, _ in
            // Clear type-specific state when switching types (prevents confusion)
            errorMessage = nil
        }
    }

    // Save
    private func saveTapped() {
        errorMessage = nil
        let now = Date()

        let id = UUID()

        switch selectedType {
        case .text:
            let memory = Memory(
                id: id,
                title: titleTrimmed,
                createdAt: now,
                mediaType: .text,
                text: textTrimmed,
                fileName: nil,
                plantType: plantType
            )
            onSave(memory)
            dismiss()

        case .photo:
            guard let img = pickedImage else {
                errorMessage = "Pick a photo first."
                return
            }
            let fileName = "\(id.uuidString).jpg"
            do {
                try MediaFileStore.saveJPEG(img, fileName: fileName)
                let memory = Memory(
                    id: id,
                    title: titleTrimmed,
                    createdAt: now,
                    mediaType: .photo,
                    text: nil,
                    fileName: fileName,
                    plantType: plantType
                )
                onSave(memory)
                dismiss()
            } catch {
                errorMessage = "Couldn’t save photo."
            }

        case .video:
            guard let tempURL = pickedVideoTempURL else {
                errorMessage = "Pick a video first."
                return
            }
            let fileName = "\(id.uuidString).mov"
            do {
                try MediaFileStore.copyItem(from: tempURL, toFileName: fileName)
                let memory = Memory(
                    id: id,
                    title: titleTrimmed,
                    createdAt: now,
                    mediaType: .video,
                    text: nil,
                    fileName: fileName,
                    plantType: plantType
                )
                onSave(memory)
                dismiss()
            } catch {
                errorMessage = "Couldn’t save video."
            }

        case .audio:

            guard audioRecorder.recordedURL != nil else {
                errorMessage = "Record something first."
                return
            }

            let fileName = "\(draftID.uuidString).m4a"

            let memory = Memory(
                id: draftID,
                title: titleTrimmed,
                createdAt: now,
                mediaType: .audio,
                text: nil,
                fileName: fileName,
                plantType: plantType
            )

            onSave(memory)
            dismiss()
        }
    }
}
