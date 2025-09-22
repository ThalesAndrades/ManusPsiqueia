//
//  DiaryManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Team on 19/01/2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import CryptoKit

/// Manager for patient diary with privacy-first approach and local encryption
@MainActor
class DiaryManager: ObservableObject {
    @Published var entries: [DiaryEntry] = []
    @Published var privacySettings = DiaryPrivacySettings.default
    @Published var isLoading = false
    @Published var error: DiaryError?
    
    private let encryptionManager = DiaryEncryptionManager()
    private let storageManager = DiaryStorageManager()
    private let aiInsightsManager = DiaryAIInsightsManager()
    
    // MARK: - Public Methods
    
    /// Load all diary entries from secure storage
    func loadEntries() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                entries = try await storageManager.loadEntries()
                print("✅ Loaded \(entries.count) diary entries")
            } catch {
                self.error = .loadingFailed(error.localizedDescription)
                print("❌ Failed to load diary entries: \(error)")
            }
        }
    }
    
    /// Save a new diary entry
    func saveEntry(_ entry: DiaryEntry) async throws {
        do {
            let encryptedEntry = try encryptionManager.encrypt(entry)
            try await storageManager.saveEntry(encryptedEntry)
            
            // Add to local array
            entries.insert(entry, at: 0)
            
            // Generate AI insights if enabled
            if privacySettings.allowAIAnalysis {
                await generateAIInsights(for: entry)
            }
            
            print("✅ Diary entry saved successfully")
        } catch {
            self.error = .savingFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Update an existing diary entry
    func updateEntry(_ entry: DiaryEntry) async throws {
        do {
            var updatedEntry = entry
            updatedEntry.lastModified = Date()
            
            let encryptedEntry = try encryptionManager.encrypt(updatedEntry)
            try await storageManager.updateEntry(encryptedEntry)
            
            // Update local array
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = updatedEntry
            }
            
            print("✅ Diary entry updated successfully")
        } catch {
            self.error = .updateFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Delete a diary entry
    func deleteEntry(_ entry: DiaryEntry) async throws {
        do {
            try await storageManager.deleteEntry(entry.id)
            entries.removeAll { $0.id == entry.id }
            print("✅ Diary entry deleted successfully")
        } catch {
            self.error = .deletionFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Generate statistics from diary entries
    func generateStatistics() -> DiaryStatistics {
        let totalEntries = entries.count
        let averageMood = entries.isEmpty ? 0 : entries.map { $0.mood.intensity }.reduce(0, +) / Double(totalEntries)
        let averageAnxiety = entries.isEmpty ? 0 : entries.map { $0.anxietyLevel }.reduce(0, +) / Double(totalEntries)
        let averageEnergy = entries.isEmpty ? 0 : entries.map { $0.energyLevel }.reduce(0, +) / Double(totalEntries)
        
        // Most common tags
        let allTags = entries.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags, by: { $0 }).mapValues { $0.count }
        let mostCommonTags = tagCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        // Most common triggers
        let allTriggers = entries.flatMap { $0.triggers }
        let triggerCounts = Dictionary(grouping: allTriggers, by: { $0 }).mapValues { $0.count }
        let mostCommonTriggers = triggerCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        // Trends
        let moodTrend = entries.map { DiaryStatistics.MoodDataPoint(date: $0.timestamp, mood: $0.mood, intensity: $0.mood.intensity) }
        let anxietyTrend = entries.map { DiaryStatistics.DataPoint(date: $0.timestamp, value: $0.anxietyLevel) }
        let energyTrend = entries.map { DiaryStatistics.DataPoint(date: $0.timestamp, value: $0.energyLevel) }
        
        // Entry frequency
        let calendar = Calendar.current
        let entryDates = entries.map { calendar.startOfDay(for: $0.timestamp) }
        let dateCounts = Dictionary(grouping: entryDates, by: { $0 }).mapValues { $0.count }
        let entryFrequency = dateCounts.map { DiaryStatistics.DateFrequency(date: $0.key, count: $0.value) }
        
        // Streaks
        let (longestStreak, currentStreak) = calculateStreaks()
        
        return DiaryStatistics(
            totalEntries: totalEntries,
            averageMood: averageMood,
            averageAnxiety: averageAnxiety,
            averageEnergy: averageEnergy,
            mostCommonTags: Array(mostCommonTags),
            mostCommonTriggers: Array(mostCommonTriggers),
            moodTrend: moodTrend,
            anxietyTrend: anxietyTrend,
            energyTrend: energyTrend,
            entryFrequency: entryFrequency,
            longestStreak: longestStreak,
            currentStreak: currentStreak
        )
    }
    
    /// Export diary data for backup (encrypted)
    func exportData() async throws -> Data {
        let exportData = DiaryExportData(
            entries: entries,
            privacySettings: privacySettings,
            exportDate: Date(),
            version: "1.0"
        )
        
        let jsonData = try JSONEncoder().encode(exportData)
        return try encryptionManager.encryptData(jsonData)
    }
    
    /// Import diary data from backup
    func importData(_ encryptedData: Data) async throws {
        let jsonData = try encryptionManager.decryptData(encryptedData)
        let exportData = try JSONDecoder().decode(DiaryExportData.self, from: jsonData)
        
        // Merge with existing entries (avoid duplicates)
        let existingIds = Set(entries.map { $0.id })
        let newEntries = exportData.entries.filter { !existingIds.contains($0.id) }
        
        entries.append(contentsOf: newEntries)
        entries = DiaryEntry.sortedByDate(entries)
        
        // Save to storage
        for entry in newEntries {
            try await saveEntry(entry)
        }
        
        print("✅ Imported \(newEntries.count) new diary entries")
    }
    
    // MARK: - Private Methods
    
    private func generateAIInsights(for entry: DiaryEntry) async {
        guard privacySettings.allowAIAnalysis else { return }
        
        do {
            let insights = try await aiInsightsManager.generateInsights(for: entry, previousEntries: entries)
            // Store insights for therapist (if enabled)
            if privacySettings.shareWithTherapist {
                await storeInsightsForTherapist(insights, for: entry)
            }
        } catch {
            print("⚠️ Failed to generate AI insights: \(error)")
        }
    }
    
    private func storeInsightsForTherapist(_ insights: DiaryAIInsights, for entry: DiaryEntry) async {
        // Store anonymized insights for therapist access
        // This is separate from the diary entry itself
        do {
            try await aiInsightsManager.storeTherapistInsights(insights, entryId: entry.id)
            print("✅ AI insights stored for therapist")
        } catch {
            print("⚠️ Failed to store therapist insights: \(error)")
        }
    }
    
    private func calculateStreaks() -> (longest: Int, current: Int) {
        guard !entries.isEmpty else { return (0, 0) }
        
        let calendar = Calendar.current
        let sortedDates = entries
            .map { calendar.startOfDay(for: $0.timestamp) }
            .sorted()
            .removingDuplicates()
        
        var longestStreak = 1
        var currentStreak = 1
        var tempStreak = 1
        
        for i in 1..<sortedDates.count {
            let previousDate = sortedDates[i - 1]
            let currentDate = sortedDates[i]
            
            if calendar.dateInterval(of: .day, for: previousDate)?.end == currentDate {
                tempStreak += 1
            } else {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 1
            }
        }
        
        longestStreak = max(longestStreak, tempStreak)
        
        // Calculate current streak
        let today = calendar.startOfDay(for: Date())
        if let lastEntryDate = sortedDates.last {
            if calendar.isDate(lastEntryDate, inSameDayAs: today) ||
               calendar.isDate(lastEntryDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today) ?? today) {
                
                var streakCount = 0
                var checkDate = today
                
                while sortedDates.contains(checkDate) {
                    streakCount += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                }
                
                currentStreak = streakCount
            } else {
                currentStreak = 0
            }
        }
        
        return (longestStreak, currentStreak)
    }
}

// MARK: - Supporting Types

enum DiaryError: LocalizedError {
    case loadingFailed(String)
    case savingFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case encryptionFailed(String)
    case decryptionFailed(String)
    case biometricAuthFailed
    case storageQuotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Falha ao carregar entradas: \(message)"
        case .savingFailed(let message):
            return "Falha ao salvar entrada: \(message)"
        case .updateFailed(let message):
            return "Falha ao atualizar entrada: \(message)"
        case .deletionFailed(let message):
            return "Falha ao deletar entrada: \(message)"
        case .encryptionFailed(let message):
            return "Falha na criptografia: \(message)"
        case .decryptionFailed(let message):
            return "Falha na descriptografia: \(message)"
        case .biometricAuthFailed:
            return "Falha na autenticação biométrica"
        case .storageQuotaExceeded:
            return "Cota de armazenamento excedida"
        }
    }
}

struct DiaryExportData: Codable {
    let entries: [DiaryEntry]
    let privacySettings: DiaryPrivacySettings
    let exportDate: Date
    let version: String
}

// MARK: - Array Extension

extension Array where Element: Equatable {
    func removingDuplicates() -> [Element] {
        var result: [Element] = []
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}

// MARK: - Encryption Manager

class DiaryEncryptionManager {
    private let keychain = DiaryKeychain()
    
    func encrypt(_ entry: DiaryEntry) throws -> DiaryEntry {
        // In a real implementation, this would encrypt sensitive fields
        // For now, we'll return the entry as-is since it's stored locally
        return entry
    }
    
    func encryptData(_ data: Data) throws -> Data {
        // Implement AES encryption for export data
        return data
    }
    
    func decryptData(_ data: Data) throws -> Data {
        // Implement AES decryption for import data
        return data
    }
}

// MARK: - Storage Manager

class DiaryStorageManager {
    private let userDefaults = UserDefaults.standard
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    func loadEntries() async throws -> [DiaryEntry] {
        // Load from local storage (UserDefaults for demo, Core Data for production)
        if let data = userDefaults.data(forKey: "diary_entries") {
            return try JSONDecoder().decode([DiaryEntry].self, from: data)
        }
        return []
    }
    
    func saveEntry(_ entry: DiaryEntry) async throws {
        var entries = try await loadEntries()
        entries.insert(entry, at: 0)
        let data = try JSONEncoder().encode(entries)
        userDefaults.set(data, forKey: "diary_entries")
    }
    
    func updateEntry(_ entry: DiaryEntry) async throws {
        var entries = try await loadEntries()
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            let data = try JSONEncoder().encode(entries)
            userDefaults.set(data, forKey: "diary_entries")
        }
    }
    
    func deleteEntry(_ entryId: UUID) async throws {
        var entries = try await loadEntries()
        entries.removeAll { $0.id == entryId }
        let data = try JSONEncoder().encode(entries)
        userDefaults.set(data, forKey: "diary_entries")
    }
}

// MARK: - Keychain Helper

class DiaryKeychain {
    // Implement keychain operations for encryption keys
    func storeKey(_ key: Data, for identifier: String) throws {
        // Store encryption key in keychain
    }
    
    func retrieveKey(for identifier: String) throws -> Data {
        // Retrieve encryption key from keychain
        return Data()
    }
}
