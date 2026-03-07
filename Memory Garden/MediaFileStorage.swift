import Foundation
import UIKit

enum MediaFileStore {
    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func url(for fileName: String) -> URL {
        documentsURL.appendingPathComponent(fileName)
    }

    static func saveJPEG(_ image: UIImage, fileName: String) throws {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        try data.write(to: url(for: fileName), options: [.atomic])
    }

    static func copyItem(from src: URL, toFileName fileName: String) throws {
        let dst = url(for: fileName)
        if FileManager.default.fileExists(atPath: dst.path) {
            try FileManager.default.removeItem(at: dst)
        }
        try FileManager.default.copyItem(at: src, to: dst)
    }
}
