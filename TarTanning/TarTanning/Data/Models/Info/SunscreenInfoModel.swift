import Foundation

struct SunscreenInfoResponse: Codable {
    let sunscreenInfo: [SunscreenInfoItem]
    
    enum CodingKeys: String, CodingKey {
        case sunscreenInfo = "sunscreen_info"
    }
}

struct SunscreenInfoItem: Codable, Identifiable {
    let id: Int
    let thumbnail: String
    let category: String
    let title: String
    let content: String
}

class SunscreenInfoLoader {
    static let shared = SunscreenInfoLoader()
    
    private init() {}
    
    func loadSunscreenInfo() -> [SunscreenInfoItem] {
        guard let url = Bundle.main.url(forResource: "sunscreen_uv_info", withExtension: "json") else {
            print("❌ [SunscreenInfoLoader] JSON 파일을 찾을 수 없습니다.")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(SunscreenInfoResponse.self, from: data)
            print("✅ [SunscreenInfoLoader] JSON 로드 성공: \(response.sunscreenInfo.count)개 항목")
            return response.sunscreenInfo
        } catch {
            print("❌ [SunscreenInfoLoader] JSON 디코딩 실패: \(error)")
            return []
        }
    }
}
