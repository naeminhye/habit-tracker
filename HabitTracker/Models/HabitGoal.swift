//
//  HabitGoal.swift
//  HabitTracker
//
//  Created by JaceyNguyen on 20/04/2026.
//

import Foundation
import SwiftData

enum GoalType: String, Codable, CaseIterable {
    case oncePer    = "oncePer"      // complete once per period
    case nTimes     = "nTimes"       // N times per period
    case amount     = "amount"       // reach a target amount

    var displayName: String {
        switch self {
        case .oncePer: return "Complete once"
        case .nTimes:  return "N times per period"
        case .amount:  return "Target amount"
        }
    }

    var icon: String {
        switch self {
        case .oncePer: return "checkmark.circle"
        case .nTimes:  return "repeat"
        case .amount:  return "gauge.with.needle"
        }
    }
}

enum GoalPeriod: String, Codable, CaseIterable {
    case day   = "day"
    case week  = "week"
    case month = "month"

    var displayName: String {
        switch self {
        case .day:   return "day"
        case .week:  return "week"
        case .month: return "month"
        }
    }
}

@Model
final class HabitGoal {
    var id: UUID
    var type: GoalType
    var period: GoalPeriod
    var targetCount: Int        // for nTimes
    var targetAmount: Double    // for amount
    var unit: String            // e.g. "liters", "minutes", "km"
    var currentAmount: Double   // today's logged amount

    init(
        type: GoalType = .oncePer,
        period: GoalPeriod = .day,
        targetCount: Int = 1,
        targetAmount: Double = 0,
        unit: String = ""
    ) {
        self.id = UUID()
        self.type = type
        self.period = period
        self.targetCount = targetCount
        self.targetAmount = targetAmount
        self.unit = unit
        self.currentAmount = 0
    }

    var displayTarget: String {
        switch type {
        case .oncePer:
            return "Once per \(period.displayName)"
        case .nTimes:
            return "\(targetCount)x per \(period.displayName)"
        case .amount:
            return "\(formatAmount(targetAmount)) \(unit) per \(period.displayName)"
        }
    }

    private func formatAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}
