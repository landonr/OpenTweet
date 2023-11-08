//
//  ImageService.swift
//  OpenTweet
//
//  Created by Landon Rohatensky on 2023-11-02.
//

import SwiftUI

class ImageService {
    private static func saveImage(image: UIImage, url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
                return
            }
            guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
                return
            }
            do {
                try data.write(to: directory.appendingPathComponent(url.lastPathComponent)!)
                print("saved image to cache")
                return
            } catch {
                print(error.localizedDescription)
                return
            }
        }
    }

    private static func getImageFromCache(url: URL) async throws -> UIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let data = try Data(contentsOf: directory.appendingPathComponent(url.lastPathComponent))
                    DispatchQueue.main.async {
                        continuation.resume(with: .success(UIImage(data: data)))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func downloadImage(url: URL) async throws -> UIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    print("downloading image \(url)")
                    let data = try Data(contentsOf: url)
                    let image = UIImage(data: data)
                    if let image = image {
                        saveImage(image: image, url: url)
                    }
                    DispatchQueue.main.async {
                        continuation.resume(with: .success(image))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func getImage(url: URL) async throws -> UIImage? {
        if let image = try await getImageFromCache(url: url) {
            return image
        }
        return try await downloadImage(url: url)
    }
}
