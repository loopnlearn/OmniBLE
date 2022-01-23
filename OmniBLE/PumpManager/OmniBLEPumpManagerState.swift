//
//  OmniBLEPumpManagerState.swift
//  OmniBLE
//
//  Based on OmniKit/PumpManager/OmnipodPumpManagerState.swift
//  Created by Pete Schwamb on 8/4/18.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import LoopKit


public struct OmniBLEPumpManagerState: RawRepresentable, Equatable {
    public typealias RawValue = PumpManager.RawStateValue
    
    public static let version = 2
    
    public var podState: PodState?

    public var pairingAttemptAddress: UInt32?

    public var timeZone: TimeZone
    
    public var basalSchedule: BasalSchedule
    
    public var unstoredDoses: [UnfinalizedDose]

    public var expirationReminderDate: Date?

    public var confirmationBeeps: Bool

    // Temporal state not persisted

    internal enum EngageablePumpState: Equatable {
        case engaging
        case disengaging
        case stable
    }

    internal var suspendEngageState: EngageablePumpState = .stable

    internal var bolusEngageState: EngageablePumpState = .stable

    internal var tempBasalEngageState: EngageablePumpState = .stable

    internal var lastPumpDataReportDate: Date?
    
    // MARK: -

    public init(podState: PodState?, timeZone: TimeZone, basalSchedule: BasalSchedule) {
        self.podState = podState
        self.timeZone = timeZone
        self.basalSchedule = basalSchedule
        self.unstoredDoses = []
        self.confirmationBeeps = false
    }
    
    public init?(rawValue: RawValue) {
        
        guard let version = rawValue["version"] as? Int else {
            return nil
        }
        
        let basalSchedule: BasalSchedule
        
        if version == 1 {
            // migrate: basalSchedule moved from podState to oppm state
            if let podStateRaw = rawValue["podState"] as? PodState.RawValue,
                let rawBasalSchedule = podStateRaw["basalSchedule"] as? BasalSchedule.RawValue,
                let migrateSchedule = BasalSchedule(rawValue: rawBasalSchedule)
            {
                basalSchedule = migrateSchedule
            } else {
                return nil
            }
        } else {
            guard let rawBasalSchedule = rawValue["basalSchedule"] as? BasalSchedule.RawValue,
                let schedule = BasalSchedule(rawValue: rawBasalSchedule) else
            {
                return nil
            }
            basalSchedule = schedule
        }
        
        let podState: PodState?
        if let podStateRaw = rawValue["podState"] as? PodState.RawValue {
            podState = PodState(rawValue: podStateRaw)
        } else {
            podState = nil
        }

        let timeZone: TimeZone
        if let timeZoneSeconds = rawValue["timeZone"] as? Int,
            let tz = TimeZone(secondsFromGMT: timeZoneSeconds) {
            timeZone = tz
        } else {
            timeZone = TimeZone.currentFixed
        }

        self.init(
            podState: podState,
            timeZone: timeZone,
            basalSchedule: basalSchedule
        )

        if let expirationReminderDate = rawValue["expirationReminderDate"] as? Date {
            self.expirationReminderDate = expirationReminderDate
        } else if let expiresAt = podState?.expiresAt {
            self.expirationReminderDate = expiresAt.addingTimeInterval(-Pod.expirationReminderAlertDefaultTimeBeforeExpiration)
        }

        if let rawUnstoredDoses = rawValue["unstoredDoses"] as? [UnfinalizedDose.RawValue] {
            self.unstoredDoses = rawUnstoredDoses.compactMap( { UnfinalizedDose(rawValue: $0) } )
        } else {
            self.unstoredDoses = []
        }

        self.confirmationBeeps = rawValue["confirmationBeeps"] as? Bool ?? rawValue["bolusBeeps"] as? Bool ?? false
        
        if let pairingAttemptAddress = rawValue["pairingAttemptAddress"] as? UInt32 {
            self.pairingAttemptAddress = pairingAttemptAddress
        }
        
    }
    
    public var rawValue: RawValue {
        var value: [String : Any] = [
            "version": OmniBLEPumpManagerState.version,
            "timeZone": timeZone.secondsFromGMT(),
            "basalSchedule": basalSchedule.rawValue,
            "unstoredDoses": unstoredDoses.map { $0.rawValue },
            "confirmationBeeps": confirmationBeeps,
        ]
        
        value["podState"] = podState?.rawValue
        value["expirationReminderDate"] = expirationReminderDate
        value["pairingAttemptAddress"] = pairingAttemptAddress

        return value
    }
}

extension OmniBLEPumpManagerState {
    var hasActivePod: Bool {
        return podState?.isActive == true
    }

    var hasSetupPod: Bool {
        return podState?.isSetupComplete == true
    }

    var isPumpDataStale: Bool {
        let pumpStatusAgeTolerance = TimeInterval(minutes: 6)
        let pumpDataAge = -(self.lastPumpDataReportDate ?? .distantPast).timeIntervalSinceNow
        return pumpDataAge > pumpStatusAgeTolerance
    }
}


extension OmniBLEPumpManagerState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "## OmniBLEPumpManagerState",
            "* timeZone: \(timeZone)",
            "* basalSchedule: \(String(describing: basalSchedule))",
            "* expirationReminderDate: \(String(describing: expirationReminderDate))",
            "* unstoredDoses: \(String(describing: unstoredDoses))",
            "* suspendEngageState: \(String(describing: suspendEngageState))",
            "* bolusEngageState: \(String(describing: bolusEngageState))",
            "* tempBasalEngageState: \(String(describing: tempBasalEngageState))",
            "* lastPumpDataReportDate: \(String(describing: lastPumpDataReportDate))",
            "* isPumpDataStale: \(String(describing: isPumpDataStale))",
            "* confirmationBeeps: \(String(describing: confirmationBeeps))",
            "* pairingAttemptAddress: \(String(describing: pairingAttemptAddress))",
            String(reflecting: podState),
        ].joined(separator: "\n")
    }
}
