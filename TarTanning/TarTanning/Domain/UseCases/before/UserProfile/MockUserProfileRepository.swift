//
//  MockUserProfileRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

class MockUserProfileRepository: UserProfileRepository {
    func getUserProfile() async throws -> UserProfile {
        return UserProfile.mockUser
    }
    
    func updateSkinType(_ skinType: SkinType) async throws {
        
    }
    
    func saveUserProfile(_ profile: UserProfile) async throws {
        
    }
}
