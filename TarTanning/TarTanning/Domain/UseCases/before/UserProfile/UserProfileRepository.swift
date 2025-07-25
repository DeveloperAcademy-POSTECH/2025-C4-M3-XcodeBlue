//
//  UserProfileRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

protocol UserProfileRepository {
    func getUserProfile() async throws -> UserProfile
    func updateSkinType(_ skinType: SkinType) async throws
    func saveUserProfile(_ profile: UserProfile) async throws
}
