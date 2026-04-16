import Foundation

// MARK: - GitHub API response

struct GitHubRelease: Decodable {
    let tagName: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }

    var version: String {
        tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
    }

    var dmgURL: URL? {
        assets.first { $0.name.lowercased().hasSuffix(".dmg") }?.browserDownloadURL
    }
}

struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

// MARK: - Update state machine

enum UpdateState: Equatable {
    case idle
    case available(version: String, downloadURL: URL)
    case downloading(progress: Double)
    case downloaded(fileURL: URL)
    case installing
    case error(String)
}

// MARK: - Version comparison

enum VersionComparator {
    static func isNewer(_ v1: String, than v2: String) -> Bool {
        let nums1 = v1.components(separatedBy: ".").compactMap { Int($0) }
        let nums2 = v2.components(separatedBy: ".").compactMap { Int($0) }
        let maxLen = max(nums1.count, nums2.count)
        for i in 0..<maxLen {
            let n1 = i < nums1.count ? nums1[i] : 0
            let n2 = i < nums2.count ? nums2[i] : 0
            if n1 > n2 { return true }
            if n1 < n2 { return false }
        }
        return false
    }
}
