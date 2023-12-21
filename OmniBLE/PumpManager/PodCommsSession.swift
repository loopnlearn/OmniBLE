//
//  PodCommsSession.swift
//  OmnipodKit
//
//  From OmniKit/PumpManager/PodCommsSession.swift
//  Created by Pete Schwamb on 10/13/17.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKit
import os.log

public enum PodCommsError: Error {
    case noPodPaired
    case invalidData
    case noResponse
    case emptyResponse
    case podAckedInsteadOfReturningResponse
    case unexpectedResponse(response: MessageBlockType)
    case unknownResponseType(rawType: UInt8)
    case invalidAddress(address: UInt32, expectedAddress: UInt32)
    case podNotConnected
    case unfinalizedBolus
    case unfinalizedTempBasal
    case nonceResyncFailed
    case podSuspended
    case podFault(fault: DetailedStatus)
    case commsError(error: Error)
    case unacknowledgedMessage(sequenceNumber: Int, error: Error)
    case unacknowledgedCommandPending
    case rejectedMessage(errorCode: UInt8)
    case podChange
    case activationTimeExceeded
    case rssiTooLow
    case rssiTooHigh
    case diagnosticMessage(str: String)
    case podIncompatible(str: String)
    case noPodsFound
    case tooManyPodsFound
}

extension PodCommsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noPodPaired:
            return LocalizedString("No pod paired", comment: "Error message shown when no pod is paired")
        case .invalidData:
            return nil
        case .noResponse:
            return LocalizedString("No response from pod", comment: "Error message shown when no response from pod was received")
        case .emptyResponse:
            return LocalizedString("Empty response from pod", comment: "Error message shown when empty response from pod was received")
        case .podAckedInsteadOfReturningResponse:
            return LocalizedString("Pod sent ack instead of response", comment: "Error message shown when pod sends ack instead of response")
        case .unexpectedResponse:
            return LocalizedString("Unexpected response from pod", comment: "Error message shown when empty response from pod was received")
        case .unknownResponseType:
            return nil
        case .invalidAddress(address: let address, expectedAddress: let expectedAddress):
            return String(format: LocalizedString("Invalid address 0x%x. Expected 0x%x", comment: "Error message for when unexpected address is received (1: received address) (2: expected address)"), address, expectedAddress)
        case .podNotConnected:
            return LocalizedString("Pod not connected", comment: "Error message shown when the pod is not connected.")
        case .unfinalizedBolus:
            return LocalizedString("Bolus in progress", comment: "Error message shown when operation could not be completed due to existing bolus in progress")
        case .unfinalizedTempBasal:
            return LocalizedString("Temp basal in progress", comment: "Error message shown when temp basal could not be set due to existing temp basal in progress")
        case .nonceResyncFailed:
            return nil
        case .podSuspended:
            return LocalizedString("Pod is suspended", comment: "Error message action could not be performed because pod is suspended")
        case .podFault(let fault):
            let faultDescription = String(describing: fault.faultEventCode)
            return String(format: LocalizedString("Pod Fault: %1$@", comment: "Format string for pod fault code"), faultDescription)
        case .commsError(let error):
            return error.localizedDescription
        case .unacknowledgedMessage(_, let error):
            return error.localizedDescription
        case .unacknowledgedCommandPending:
            return LocalizedString("Communication issue: Unacknowledged command pending.", comment: "Error message when command is rejected because an unacknowledged command is pending.")
        case .rejectedMessage(let errorCode):
            return String(format: LocalizedString("Command error %1$u", comment: "Format string for invalid message error code (1: error code number)"), errorCode)
        case .podChange:
            return LocalizedString("Unexpected pod change", comment: "Format string for unexpected pod change")
        case .activationTimeExceeded:
            return LocalizedString("Activation time exceeded", comment: "Format string for activation time exceeded")
        case .rssiTooLow: // occurs when pod is too far for reliable pairing, but can sometimes occur at other distances & positions
            return LocalizedString("Poor signal strength", comment: "Format string for poor pod signal strength")
        case .rssiTooHigh: // only occurs when pod is too close for reliable pairing
            return LocalizedString("Signal strength too high", comment: "Format string for pod signal strength too high")
        case .diagnosticMessage(let str):
            return str
        case .podIncompatible(let str):
            return str
        case .noPodsFound:
            return LocalizedString("No pods found", comment: "Error message for PodCommsError.noPodsFound")
        case .tooManyPodsFound:
            return LocalizedString("Too many pods found", comment: "Error message for PodCommsError.tooManyPodsFound")

        }
    }
    
//    public var failureReason: String? {
//        return nil
//    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .noPodPaired:
            return nil
        case .invalidData:
            return nil
        case .noResponse:
            return LocalizedString("Check Bluetooth and make sure iPhone is nearby the active pod", comment: "Recovery suggestion when no response is received from pod")
        case .emptyResponse:
            return nil
        case .podAckedInsteadOfReturningResponse:
            return LocalizedString("Try again", comment: "Recovery suggestion when ack received instead of response")
        case .unexpectedResponse:
            return nil
        case .unknownResponseType:
            return nil
        case .invalidAddress:
            return LocalizedString("Crosstalk possible. Please move to a new location", comment: "Recovery suggestion when unexpected address received")
        case .podNotConnected:
            return LocalizedString("Check Bluetooth and make sure your pod is nearby", comment: "Recovery suggestion when no pod is available")
        case .unfinalizedBolus:
            return LocalizedString("Wait for existing bolus to finish, or cancel bolus", comment: "Recovery suggestion when operation could not be completed due to existing bolus in progress")
        case .unfinalizedTempBasal:
            return LocalizedString("Wait for existing temp basal to finish, or suspend to cancel", comment: "Recovery suggestion when operation could not be completed due to existing temp basal in progress")
        case .nonceResyncFailed:
            return nil
        case .podSuspended:
            return LocalizedString("Resume delivery", comment: "Recovery suggestion when pod is suspended")
        case .podFault:
            return nil
        case .commsError:
            return nil
        case .unacknowledgedMessage:
            return nil
        case .unacknowledgedCommandPending:
            return nil
        case .rejectedMessage:
            return nil
        case .podChange:
            return LocalizedString("Please bring only original pod in range or deactivate original pod", comment: "Recovery suggestion on unexpected pod change")
        case .activationTimeExceeded:
            return nil
        case .rssiTooLow:
            return LocalizedString("Please reposition iPhone relative to the pod", comment: "Recovery suggestion when pairing signal strength is too low")
        case .rssiTooHigh:
            return LocalizedString("Please reposition iPhone further from the pod", comment: "Recovery suggestion when pairing signal strength is too high")
        case .diagnosticMessage:
            return nil
        case .podIncompatible:
            return nil
        case .noPodsFound:
            return LocalizedString("Make sure your pod is filled and nearby", comment: "Recovery suggestion for PodCommsError.noPodsFound")
        case .tooManyPodsFound:
            return LocalizedString("Move to a new area away from any other pods", comment: "Recovery suggestion for PodCommsError.tooManyPodsFound")
        }
    }

    public var isFaulted: Bool {
        switch self {
        case .podFault, .activationTimeExceeded, .podIncompatible:
            return true
        default:
            return false
        }
    }
}

public protocol PodCommsSessionDelegate: AnyObject {
    func podCommsSession(_ podCommsSession: PodCommsSession, didChange state: PodState)
}

public class PodCommsSession {
    private var useCancelNoneForStatus: Bool = false             // whether to always use a cancel none to get status
    private var useGetStatusVerify = false

    public let log = OSLog(category: "PodCommsSession")
    
    private var podState: PodState {
        didSet {
            assertOnSessionQueue()
            delegate.podCommsSession(self, didChange: podState)
        }
    }
    
    private unowned let delegate: PodCommsSessionDelegate
    private var transport: MessageTransport

    init(podState: PodState, transport: MessageTransport, delegate: PodCommsSessionDelegate) {
        self.podState = podState
        self.transport = transport
        self.delegate = delegate
        self.transport.delegate = self
    }

    // Handles updating PodState on first pod fault seen
    private func handlePodFault(fault: DetailedStatus) {
        if podState.fault == nil {
            podState.fault = fault // save the first fault returned
            handleCancelDosing(deliveryType: .all, bolusNotDelivered: fault.bolusNotDelivered)
            let derivedStatusResponse = StatusResponse(detailedStatus: fault)
            podState.updateFromStatusResponse(derivedStatusResponse)
        }
        log.error("Pod Fault: %@", String(describing: fault))
    }

    // Will throw either PodCommsError.podFault or PodCommsError.activationTimeExceeded
    private func throwPodFault(fault: DetailedStatus) throws {
        handlePodFault(fault: fault)
        if fault.podProgressStatus == .activationTimeExceeded {
            // avoids a confusing "No fault" error when activation time is exceeded
            throw PodCommsError.activationTimeExceeded
        }
        throw PodCommsError.podFault(fault: fault)
    }

    /// Performs a message exchange, handling nonce resync, pod faults
    ///
    /// - Parameters:
    ///   - messageBlocks: The message blocks to send
    ///   - beepBlock: Optional confirmation beep block message to append to the message blocks to send
    ///   - expectFollowOnMessage: If true, the pod will expect another message within 4 minutes, or will alarm with an 0x33 (51) fault.
    /// - Returns: The received message response
    /// - Throws:
    ///     - PodCommsError.noResponse
    ///     - PodCommsError.podFault
    ///     - PodCommsError.unexpectedResponse
    ///     - PodCommsError.rejectedMessage
    ///     - PodCommsError.nonceResyncFailed
    ///     - MessageError
    func send<T: MessageBlock>(_ messageBlocks: [MessageBlock], beepBlock: MessageBlock? = nil, expectFollowOnMessage: Bool = false) throws -> T {
        
        var triesRemaining = 2  // Retries only happen for nonce resync
        var blocksToSend = messageBlocks
        
        // If a beep block was specified & pod isn't faulted, append the beep block to emit the confirmation beep
        if let beepBlock = beepBlock, podState.isFaulted == false {
            blocksToSend += [beepBlock]
        }

//        if blocksToSend.contains(where: { $0 as? NonceResyncableMessageBlock != nil }) {
//            podState.advanceToNextNonce()
//        }
        
        let messageNumber = transport.messageNumber

        var sentNonce: UInt32?

        while (triesRemaining > 0) {
            triesRemaining -= 1

            for command in blocksToSend {
                if let nonceBlock = command as? NonceResyncableMessageBlock {
                    sentNonce = nonceBlock.nonce
                    break // N.B. all nonce commands in single message should have the same value
                }
            }

            let message = Message(address: podState.address, messageBlocks: blocksToSend, sequenceNum: messageNumber, expectFollowOnMessage: expectFollowOnMessage)

            self.podState.lastCommsOK = false // mark last comms as not OK until we get the expected response
            let response = try transport.sendMessage(message)
            
            // Simulate fault
            //let podInfoResponse = try PodInfoResponse(encodedData: Data(hexadecimalString: "0216020d0000000000ab6a038403ff03860000285708030d0000")!)
            //let response = Message(address: podState.address, messageBlocks: [podInfoResponse], sequenceNum: message.sequenceNum)

            if let responseMessageBlock = response.messageBlocks[0] as? T {
                log.info("POD Response: %{public}@", String(describing: responseMessageBlock))
                self.podState.lastCommsOK = true // message successfully sent and expected response received
                return responseMessageBlock
            }

            if let fault = response.fault {
                try throwPodFault(fault: fault) // always throws
            }

            let responseType = response.messageBlocks[0].blockType
            guard let errorResponse = response.messageBlocks[0] as? ErrorResponse else {
                log.error("Unexpected response: %{public}@", String(describing: response.messageBlocks[0]))
                throw PodCommsError.unexpectedResponse(response: responseType)
            }

            switch errorResponse.errorResponseType {
            case .badNonce(let nonceResyncKey):
                guard let sentNonce = sentNonce else {
                    log.error("Unexpected bad nonce response: %{public}@", String(describing: response.messageBlocks[0]))
                    throw PodCommsError.unexpectedResponse(response: responseType)
                }
                podState.resyncNonce(syncWord: nonceResyncKey, sentNonce: sentNonce, messageSequenceNum: Int(message.sequenceNum))
                log.info("resyncNonce(syncWord: 0x%02x, sentNonce: 0x%04x, messageSequenceNum: %d) -> 0x%04x", nonceResyncKey, sentNonce, message.sequenceNum, podState.currentNonce)
                blocksToSend = blocksToSend.map({ (block) -> MessageBlock in
                    if var resyncableBlock = block as? NonceResyncableMessageBlock {
                        log.info("Replaced old nonce 0x%04x with resync nonce 0x%04x", resyncableBlock.nonce, podState.currentNonce)
                        resyncableBlock.nonce = podState.currentNonce
                        return resyncableBlock
                    }
                    return block
                })
                podState.advanceToNextNonce()
                break
            case .nonretryableError(let errorCode, let faultEventCode, let podProgress):
                log.error("Command error: code %u, %{public}@, pod progress %{public}@", errorCode, String(describing: faultEventCode), String(describing: podProgress))
                throw PodCommsError.rejectedMessage(errorCode: errorCode)
            }
        }
        throw PodCommsError.nonceResyncFailed
    }

    // Returns time at which prime is expected to finish.
    public func prime() throws -> TimeInterval {
        let primeDuration: TimeInterval = .seconds(Pod.primeUnits / Pod.primeDeliveryRate) + 3 // as per PDM
        
        // If priming has never been attempted on this pod, handle the pre-prime setup tasks.
        // A FaultConfig can only be done before the prime bolus or the pod will generate an 049 fault.
        if podState.setupProgress.primingNeverAttempted {
            // This FaultConfig command will set Tab5[$16] to 0 during pairing, which disables $6x faults
            let _: StatusResponse = try send([FaultConfigCommand(nonce: podState.currentNonce, tab5Sub16: 0, tab5Sub17: 0)])

            // Set up the finish pod setup reminder alert which beeps every 5 minutes for 1 hour
            let finishSetupReminder = PodAlert.finishSetupReminder
            try configureAlerts([finishSetupReminder])
        } else {
            // Not the first time through, check to see if prime bolus was successfully started
            let status: StatusResponse = try send([GetStatusCommand()])
            podState.updateFromStatusResponse(status)
            if status.podProgressStatus == .priming || status.podProgressStatus == .primingCompleted {
                podState.setupProgress = .priming
                return podState.primeFinishTime?.timeIntervalSinceNow ?? primeDuration
            }
        }

        // Mark Pod.primeUnits (2.6U) bolus delivery with Pod.primeDeliveryRate (1) between pulses for prime
        
        let primeFinishTime = Date() + primeDuration
        podState.primeFinishTime = primeFinishTime
        podState.setupProgress = .startingPrime

        let timeBetweenPulses = TimeInterval(seconds: Pod.secondsPerPrimePulse)
        let scheduleCommand = SetInsulinScheduleCommand(nonce: podState.currentNonce, units: Pod.primeUnits, timeBetweenPulses: timeBetweenPulses)
        let bolusExtraCommand = BolusExtraCommand(units: Pod.primeUnits, timeBetweenPulses: timeBetweenPulses)
        let status: StatusResponse = try send([scheduleCommand, bolusExtraCommand])
        podState.updateFromStatusResponse(status)
        podState.setupProgress = .priming
        return primeFinishTime.timeIntervalSinceNow
    }
    
    public func programInitialBasalSchedule(_ basalSchedule: BasalSchedule, scheduleOffset: TimeInterval) throws {
        if podState.setupProgress == .settingInitialBasalSchedule {
            // We started basal schedule programming, but didn't get confirmation somehow, so check status
            let status: StatusResponse = try send([GetStatusCommand()])
            podState.updateFromStatusResponse(status)
            if status.podProgressStatus == .basalInitialized {
                podState.setupProgress = .initialBasalScheduleSet
                return
            }
        }
        
        podState.setupProgress = .settingInitialBasalSchedule
        // Set basal schedule
        let _ = try setBasalSchedule(schedule: basalSchedule, scheduleOffset: scheduleOffset)
        podState.setupProgress = .initialBasalScheduleSet
        podState.finalizedDoses.append(UnfinalizedDose(resumeStartTime: Date(), scheduledCertainty: .certain))
    }

    @discardableResult
    func configureAlerts(_ alerts: [PodAlert], acknowledgeAll: Bool = false, beepBlock: MessageBlock? = nil) throws -> StatusResponse {
        let configurations = alerts.map { $0.configuration }
        let configureAlerts = ConfigureAlertsCommand(nonce: podState.currentNonce, configurations: configurations)
        var blocksToSend: [MessageBlock] = [configureAlerts]
        if acknowledgeAll {
            // requested to acknowledge any possible pending pod alerts out of an abundnace of caution
            let acknowledgeAll = AcknowledgeAlertCommand(nonce: podState.currentNonce, alerts: AlertSet(rawValue: ~0))
            blocksToSend += [acknowledgeAll]
        }
        let status: StatusResponse = try send(blocksToSend, beepBlock: beepBlock)
        for alert in alerts {
            podState.registerConfiguredAlert(slot: alert.configuration.slot, alert: alert)
        }
        podState.updateFromStatusResponse(status)
        return status
    }

    // emits the specified beep type and sets the completion beep flags, doesn't throw
    public func beepConfig(beepType: BeepType, tempBasalCompletionBeep: Bool, bolusCompletionBeep: Bool) -> Result<StatusResponse, Error> {
        if let fault = self.podState.fault {
            log.info("Skip beep config with faulted pod")
            return .failure(PodCommsError.podFault(fault: fault))
        }
        
        let beepConfigCommand = BeepConfigCommand(beepType: beepType, tempBasalCompletionBeep: tempBasalCompletionBeep, bolusCompletionBeep: bolusCompletionBeep)
        do {
            let statusResponse: StatusResponse = try send([beepConfigCommand])
            podState.updateFromStatusResponse(statusResponse)
            return .success(statusResponse)
        } catch let error {
            return .failure(error)
        }
    }

    private func markSetupProgressCompleted(statusResponse: StatusResponse) {
        if (podState.setupProgress != .completed) {
            podState.setupProgress = .completed
            podState.setupUnitsDelivered = statusResponse.insulinDelivered // stash the current insulin delivered value as the baseline
            log.info("Total setup units delivered: %@", String(describing: statusResponse.insulinDelivered))
        }
    }

    // if silent, configure the shutdownImminentAlarm & expirationAdvisoryAlarm for silent pod alerts
    func insertCannula(silent: Bool) throws -> TimeInterval {
        let cannulaInsertionUnits = Pod.cannulaInsertionUnits + Pod.cannulaInsertionUnitsExtra
        let insertionWait: TimeInterval = .seconds(cannulaInsertionUnits / Pod.primeDeliveryRate)

        guard podState.activatedAt != nil else {
            throw PodCommsError.noPodPaired
        }

        if podState.setupProgress == .startingInsertCannula || podState.setupProgress == .cannulaInserting {
            // We started cannula insertion, but didn't get confirmation somehow, so check status
            let status: StatusResponse = try send([GetStatusCommand()])
            if status.podProgressStatus == .insertingCannula {
                podState.setupProgress = .cannulaInserting
                podState.updateFromStatusResponse(status)
                return insertionWait // Not sure when it started, wait full time to be sure
            }
            if status.podProgressStatus.readyForDelivery {
                markSetupProgressCompleted(statusResponse: status)
                podState.updateFromStatusResponse(status)
                return TimeInterval(0) // Already done; no need to wait
            }
            podState.updateFromStatusResponse(status)
        } else {
            let elapsed: TimeInterval = -(podState.podTimeUpdated?.timeIntervalSinceNow ?? 0)
            let podTime = podState.podTime + elapsed

            // Configure the Pod Alerts for shutdown imminent alert (79 hours) and pod expiration alert (72 hours)
            let shutdownImminentAlarm = PodAlert.shutdownImminent(offset: podTime, absAlertTime: Pod.serviceDuration - Pod.endOfServiceImminentWindow, silent: silent)
            let expirationAdvisoryAlarm = PodAlert.expired(offset: podTime, absAlertTime: Pod.nominalPodLife, duration: Pod.expirationAdvisoryWindow, silent: silent)
            try configureAlerts([shutdownImminentAlarm, expirationAdvisoryAlarm])
        }
        
        // Mark cannulaInsertionUnits (0.5U) bolus delivery with Pod.secondsPerPrimePulse (1) between pulses for cannula insertion

        let timeBetweenPulses = TimeInterval(seconds: Pod.secondsPerPrimePulse)
        let bolusScheduleCommand = SetInsulinScheduleCommand(nonce: podState.currentNonce, units: cannulaInsertionUnits, timeBetweenPulses: timeBetweenPulses)
        
        podState.setupProgress = .startingInsertCannula
        let bolusExtraCommand = BolusExtraCommand(units: cannulaInsertionUnits, timeBetweenPulses: timeBetweenPulses)
        let status2: StatusResponse = try send([bolusScheduleCommand, bolusExtraCommand])
        podState.updateFromStatusResponse(status2)
        
        podState.setupProgress = .cannulaInserting
        return insertionWait
    }

    public func checkInsertionCompleted() throws {
        if podState.setupProgress == .cannulaInserting {
            let response: StatusResponse = try send([GetStatusCommand()])
            if response.podProgressStatus.readyForDelivery {
                markSetupProgressCompleted(statusResponse: response)
            }
            podState.updateFromStatusResponse(response)
        }
    }

    // Throws SetBolusError
    public enum DeliveryCommandResult {
        case success(statusResponse: StatusResponse)
        case certainFailure(error: PodCommsError)
        case unacknowledged(error: PodCommsError)
    }

    public enum CancelDeliveryResult {
        case success(statusResponse: StatusResponse, canceledDose: UnfinalizedDose?)
        case certainFailure(error: PodCommsError)
        case unacknowledged(error: PodCommsError)
    }

    
    public func bolus(units: Double, automatic: Bool = false, acknowledgementBeep: Bool = false, completionBeep: Bool = false, programReminderInterval: TimeInterval = 0, extendedUnits: Double = 0.0, extendedDuration: TimeInterval = 0) -> DeliveryCommandResult {

        guard podState.unacknowledgedCommand == nil else {
            return DeliveryCommandResult.certainFailure(error: .unacknowledgedCommandPending)
        }

        let timeBetweenPulses = TimeInterval(seconds: Pod.secondsPerBolusPulse)
        let bolusScheduleCommand = SetInsulinScheduleCommand(nonce: podState.currentNonce, units: units, timeBetweenPulses: timeBetweenPulses, extendedUnits: extendedUnits, extendedDuration: extendedDuration)
        
        if podState.unfinalizedBolus != nil {
            if let statusResponse: StatusResponse = try? send([GetStatusCommand()]) {
                podState.updateFromStatusResponse(statusResponse)
            }
            guard podState.unfinalizedBolus == nil else {
                return DeliveryCommandResult.certainFailure(error: .unfinalizedBolus)
            }
        }

        let bolusExtraCommand = BolusExtraCommand(units: units, timeBetweenPulses: timeBetweenPulses, extendedUnits: extendedUnits, extendedDuration: extendedDuration, acknowledgementBeep: acknowledgementBeep, completionBeep: completionBeep, programReminderInterval: programReminderInterval)
        do {
            podState.unacknowledgedCommand = PendingCommand.program(.bolus(volume: units, automatic: automatic), transport.messageNumber, Date())
            let status: StatusResponse = try send([bolusScheduleCommand, bolusExtraCommand])
            podState.unacknowledgedCommand = nil
            podState.unfinalizedBolus = UnfinalizedDose(bolusAmount: units, startTime: Date(), scheduledCertainty: .certain, automatic: automatic)
            podState.updateFromStatusResponse(status)
            return DeliveryCommandResult.success(statusResponse: status)
        } catch PodCommsError.unacknowledgedMessage(let seq, let error) {
            podState.unacknowledgedCommand = podState.unacknowledgedCommand?.commsFinished
            log.error("Unacknowledged bolus: command seq = %d, error = %{public}@", seq, String(describing: error))
            // let podCommsError = error as? PodCommsError ?? PodCommsError.commsError(error: error)
            let podCommsError = error as? PodCommsError ?? PodCommsError.noResponse
            if useGetStatusVerify {
                // Attempt to verify bolus using getStatus
                let startTime = Date()
                guard let getStatusResult = try? getStatus() else {
                    self.log.debug("Status check failed; could not resolve bolus uncertainty")
                    // podState.unfinalizedBolus should be set up later as certain in unacknowledgedCommandWasReceived() if verified
                    return DeliveryCommandResult.unacknowledged(error: podCommsError)
                }
                // podState.podState.unacknowledgedCommand should be nil after successful call to getStatus()
                if getStatusResult.deliveryStatus.bolusing {
                    self.log.debug("getStatus resolved bolus uncertainty (bolus started)")
                    // Paranoid check since podStatus.unfinalizedBolus should have been set in unacknowledgedCommandWasReceived()
                    if podState.unfinalizedBolus == nil {
                        podState.unfinalizedBolus = UnfinalizedDose(bolusAmount: units, startTime: startTime, scheduledCertainty: .certain, automatic: automatic)
                    } else {
                        self.log.debug("getStatus resolved bolus uncertainty (bolus not started)")
                        return DeliveryCommandResult.certainFailure(error: podCommsError)
                    }
                }
            }
            return DeliveryCommandResult.unacknowledged(error: podCommsError)
        } catch let error {
            podState.unacknowledgedCommand = nil
            // let podCommsError = error as? PodCommsError ?? PodCommsError.commsError(error: error)
            let podCommsError = error as? PodCommsError ?? PodCommsError.noResponse
            return DeliveryCommandResult.certainFailure(error: podCommsError)
        }
    }
    
    public func setTempBasal(rate: Double, duration: TimeInterval, automatic: Bool, isHighTemp: Bool, acknowledgementBeep: Bool = false, completionBeep: Bool = false, programReminderInterval: TimeInterval = 0) -> DeliveryCommandResult {

        guard podState.unacknowledgedCommand == nil else {
            return DeliveryCommandResult.certainFailure(error: .unacknowledgedCommandPending)
        }

        let tempBasalCommand = SetInsulinScheduleCommand(nonce: podState.currentNonce, tempBasalRate: rate, duration: duration)
        let tempBasalExtraCommand = TempBasalExtraCommand(rate: rate, duration: duration, acknowledgementBeep: acknowledgementBeep, completionBeep: completionBeep, programReminderInterval: programReminderInterval)

        guard podState.unfinalizedBolus?.isFinished() != false else {
            return DeliveryCommandResult.certainFailure(error: .unfinalizedBolus)
        }

        let startTime = Date()

        do {
            podState.unacknowledgedCommand = PendingCommand.program(.tempBasal(unitsPerHour: rate, duration: duration, isHighTemp: isHighTemp, automatic: automatic), transport.messageNumber, startTime)
            let status: StatusResponse = try send([tempBasalCommand, tempBasalExtraCommand])
            podState.unacknowledgedCommand = nil
            podState.unfinalizedTempBasal = UnfinalizedDose(tempBasalRate: rate, startTime: startTime, duration: duration, isHighTemp: isHighTemp, scheduledCertainty: .certain, automatic: automatic)
            podState.updateFromStatusResponse(status)
            return DeliveryCommandResult.success(statusResponse: status)
        } catch PodCommsError.unacknowledgedMessage(let seq, let error) {
            podState.unacknowledgedCommand = podState.unacknowledgedCommand?.commsFinished
            log.error("Unacknowledged temp basal: command seq = %d, error = %{public}@", seq, String(describing: error))
            let podCommsError = error as? PodCommsError ?? PodCommsError.commsError(error: error)
            if useGetStatusVerify {
                // Attempt to verify temp basal using getStatus
                guard let getStatusResult = try? getStatus() else {
                    self.log.debug("Status check failed; could not resolve temp basal uncertainty")
                    // podState.unfinalizedTempBasal should be set up later as certain in unacknowledgedCommandWasReceived() if verified
                    // podState.unfinalizedTempBasal = UnfinalizedDose(tempBasalRate: rate, startTime: startTime, duration: duration, isHighTemp: isHighTemp, scheduledCertainty: .uncertain, automatic: automatic)
                    return DeliveryCommandResult.unacknowledged(error: podCommsError)
                }
                // podState.podState.unacknowledgedCommand should be nil after successful call to getStatus()
                if getStatusResult.deliveryStatus.tempBasalRunning {
                    self.log.debug("getStatus resolved temp basal uncertainty (succeeded)")
                    // Paranoid check since podStatus.unfinalizedTempBasal should have been set in unacknowledgedCommandWasReceived()
                    if podState.unfinalizedTempBasal == nil {
                        podState.unfinalizedTempBasal = UnfinalizedDose(tempBasalRate: rate, startTime: startTime, duration: duration, isHighTemp: isHighTemp, scheduledCertainty: .certain, automatic: automatic)
                    }
                    return DeliveryCommandResult.success(statusResponse: getStatusResult)
                }
                self.log.debug("getStatus resolved temp basal uncertainty (failed)")
            }
            return DeliveryCommandResult.unacknowledged(error: podCommsError)
        } catch let error {
            podState.unacknowledgedCommand = nil
            let podCommsError = error as? PodCommsError ?? PodCommsError.commsError(error: error)
            return DeliveryCommandResult.certainFailure(error: podCommsError)
        }
    }

    @discardableResult
    private func handleCancelDosing(deliveryType: CancelDeliveryCommand.DeliveryType, bolusNotDelivered: Double) -> UnfinalizedDose? {
        var canceledDose: UnfinalizedDose? = nil
        let now = Date()

        if deliveryType.contains(.basal) {
            podState.unfinalizedSuspend = UnfinalizedDose(suspendStartTime: now, scheduledCertainty: .certain)
            podState.suspendState = .suspended(now)
        }

        if let unfinalizedTempBasal = podState.unfinalizedTempBasal,
            let finishTime = unfinalizedTempBasal.finishTime,
            deliveryType.contains(.tempBasal),
            finishTime > now
        {
            podState.unfinalizedTempBasal?.cancel(at: now)
            if !deliveryType.contains(.basal) {
                podState.suspendState = .resumed(now)
            }
            canceledDose = podState.unfinalizedTempBasal
            log.info("Interrupted temp basal: %@", String(describing: canceledDose))
        }

        if let unfinalizedBolus = podState.unfinalizedBolus,
            let finishTime = unfinalizedBolus.finishTime,
            deliveryType.contains(.bolus),
            finishTime > now
        {
            podState.unfinalizedBolus?.cancel(at: now, withRemaining: bolusNotDelivered)
            canceledDose = podState.unfinalizedBolus
            log.info("Interrupted bolus: %@", String(describing: canceledDose))
        }

        return canceledDose
    }
    
    // Suspends insulin delivery and sets appropriate podSuspendedReminder & suspendTimeExpired alerts.
    // A nil suspendReminder is an untimed suspend with no suspend reminders.
    // A suspendReminder of 0 is an untimed suspend which only uses podSuspendedReminder alert beeps.
    // A suspendReminder of 1-5 minutes will only use suspendTimeExpired alert beeps.
    // A suspendReminder of > 5 min will have periodic podSuspendedReminder beeps followed by suspendTimeExpired alerts.
    // The configured alerts will set up as silent pod alerts if silent is true.
    func suspendDelivery(suspendReminder: TimeInterval? = nil, silent: Bool, beepBlock: MessageBlock? = nil) -> CancelDeliveryResult {

        guard podState.unacknowledgedCommand == nil else {
            return .certainFailure(error: .unacknowledgedCommandPending)
        }

        do {
            var alertConfigurations: [AlertConfiguration] = []
            var podSuspendedReminderAlert: PodAlert? = nil
            var suspendTimeExpiredAlert: PodAlert? = nil
            let suspendTime = suspendReminder ?? 0
            let elapsed: TimeInterval = -(podState.podTimeUpdated?.timeIntervalSinceNow ?? 0)
            let podTime = podState.podTime + elapsed
            log.debug("suspendDelivery: podState.podTime=%@, elapsed=%.2fs, computed podTime %@", podState.podTime.timeIntervalStr, elapsed, podTime.timeIntervalStr)

            let cancelDeliveryCommand = CancelDeliveryCommand(nonce: podState.currentNonce, deliveryType: .all, beepType: .noBeepCancel)
            var commandsToSend: [MessageBlock] = [cancelDeliveryCommand]

            // podSuspendedReminder provides a periodic pod suspended reminder beep until the specified suspend time.
            if suspendReminder != nil && (suspendTime == 0 || suspendTime > .minutes(5)) {
                // using reminder beeps for an untimed or long enough suspend time requiring pod suspended reminders
                podSuspendedReminderAlert = PodAlert.podSuspendedReminder(active: true, offset: podTime, suspendTime: suspendTime, silent: silent)
                alertConfigurations += [podSuspendedReminderAlert!.configuration]
            }

            // suspendTimeExpired provides suspend time expired alert beeping after the expected suspend time has passed.
            if suspendTime > 0 {
                // a timed suspend using a suspend time expired alert
                suspendTimeExpiredAlert = PodAlert.suspendTimeExpired(offset: podTime, suspendTime: suspendTime, silent: silent)
                alertConfigurations += [suspendTimeExpiredAlert!.configuration]
            }

            // append a ConfigureAlert command if we have any reminder alerts for this suspend
            if alertConfigurations.count != 0 {
                let configureAlerts = ConfigureAlertsCommand(nonce: podState.currentNonce, configurations: alertConfigurations)
                commandsToSend += [configureAlerts]
            }

            podState.unacknowledgedCommand = PendingCommand.stopProgram(.all, transport.messageNumber, Date())
            let status: StatusResponse = try send(commandsToSend, beepBlock: beepBlock)
            podState.unacknowledgedCommand = nil
            let canceledDose = handleCancelDosing(deliveryType: .all, bolusNotDelivered: status.bolusNotDelivered)
            podState.updateFromStatusResponse(status)

            if let alert = podSuspendedReminderAlert {
                podState.registerConfiguredAlert(slot: alert.configuration.slot, alert: alert)
            }
            if let alert = suspendTimeExpiredAlert {
                podState.registerConfiguredAlert(slot: alert.configuration.slot, alert: alert)
            }

            return CancelDeliveryResult.success(statusResponse: status, canceledDose: canceledDose)

        } catch PodCommsError.unacknowledgedMessage(let seq, let error) {
            podState.unacknowledgedCommand = podState.unacknowledgedCommand?.commsFinished
            log.error("Unacknowledged suspend: command seq = %d, error = %{public}@", seq, String(describing: error))
            // let podCommsError = error as? PodCommsError ?? PodCommsError.commsError(error: error)
            let podCommsError = error as? PodCommsError ?? PodCommsError.noResponse
            return .unacknowledged(error: podCommsError)
        } catch let error {
            podState.unacknowledgedCommand = nil
            // let podCommsError = error as? PodCommsError ?? PodCommsError.commsError(error: error)
            let podCommsError = error as? PodCommsError ?? PodCommsError.noResponse
            return .certainFailure(error: podCommsError)
        }
    }

    // Cancels any suspend related alerts, called when setting a basal schedule with active suspend alerts
    @discardableResult
    private func cancelSuspendAlerts() throws -> StatusResponse {
        do {
            let podSuspendedReminder = PodAlert.podSuspendedReminder(active: false, offset: 0, suspendTime: 0)
            let suspendTimeExpired = PodAlert.suspendTimeExpired(offset: 0, suspendTime: 0) // A suspendTime of 0 deactivates this alert

            let status = try configureAlerts([podSuspendedReminder, suspendTimeExpired])
            return status
        } catch let error {
            throw error
        }
    }

    // Cancel beeping can be done implemented using beepType (for a single delivery type) or a separate confirmation beep message block (for cancel all).
    // N.B., Using the built-in cancel delivery command beepType method when cancelling all insulin delivery will emit 3 different sets of cancel beeps!!!
    public func cancelDelivery(deliveryType: CancelDeliveryCommand.DeliveryType, beepType: BeepType = .noBeepCancel, beepBlock: MessageBlock? = nil) -> CancelDeliveryResult {

        guard podState.unacknowledgedCommand == nil else {
            return .certainFailure(error: .unacknowledgedCommandPending)
        }

        do {
            podState.unacknowledgedCommand = PendingCommand.stopProgram(deliveryType, transport.messageNumber, Date())
            let cancelDeliveryCommand = CancelDeliveryCommand(nonce: podState.currentNonce, deliveryType: deliveryType, beepType: beepType)
            let status: StatusResponse = try send([cancelDeliveryCommand], beepBlock: beepBlock)
            podState.unacknowledgedCommand = nil

            let canceledDose = handleCancelDosing(deliveryType: deliveryType, bolusNotDelivered: status.bolusNotDelivered)
            podState.updateFromStatusResponse(status)

            return CancelDeliveryResult.success(statusResponse: status, canceledDose: canceledDose)
        } catch PodCommsError.unacknowledgedMessage(let seq, let error) {
            podState.unacknowledgedCommand = podState.unacknowledgedCommand?.commsFinished
            log.debug("Unacknowledged stop program: command seq = %d", seq)
            return .unacknowledged(error: .commsError(error: error))
        } catch let error {
            podState.unacknowledgedCommand = nil
            return .certainFailure(error: .commsError(error: error))
        }
    }

    public func testingCommands(beepBlock: MessageBlock? = nil) throws {
        try cancelNone(beepBlock: beepBlock) // reads status by doing a cancel none
    }

    public func setTime(timeZone: TimeZone, basalSchedule: BasalSchedule, date: Date, acknowledgementBeep: Bool = false) throws -> StatusResponse {

        let result = cancelDelivery(deliveryType: .all)
        switch result {
        case .certainFailure(let error):
            throw error
        case .unacknowledged(let error):
            throw error
        case .success:
            let scheduleOffset = timeZone.scheduleOffset(forDate: date)
            let status = try setBasalSchedule(schedule: basalSchedule, scheduleOffset: scheduleOffset, acknowledgementBeep: acknowledgementBeep)
            return status
        }
    }
    
    public func setBasalSchedule(schedule: BasalSchedule, scheduleOffset: TimeInterval, acknowledgementBeep: Bool = false, programReminderInterval: TimeInterval = 0) throws -> StatusResponse {

        guard podState.unacknowledgedCommand == nil else {
            throw PodCommsError.unacknowledgedCommandPending
        }

        func handleResumeState(resumeStartTime: Date, status: StatusResponse) -> StatusResponse {
            podState.suspendState = .resumed(resumeStartTime)
            podState.unfinalizedResume = UnfinalizedDose(resumeStartTime: resumeStartTime, scheduledCertainty: .certain)
            if hasActiveSuspendAlert(configuredAlerts: podState.configuredAlerts),
                let cancelSuspendAlertsResults = try? cancelSuspendAlerts()
            {
                podState.updateFromStatusResponse(cancelSuspendAlertsResults)
                return cancelSuspendAlertsResults
            }
            podState.updateFromStatusResponse(status)
            return status
        }

        let basalScheduleCommand = SetInsulinScheduleCommand(nonce: podState.currentNonce, basalSchedule: schedule, scheduleOffset: scheduleOffset)
        let basalExtraCommand = BasalScheduleExtraCommand.init(schedule: schedule, scheduleOffset: scheduleOffset, acknowledgementBeep: acknowledgementBeep, programReminderInterval: programReminderInterval)

        do {
            if podState.setupProgress == .completed && !(podState.lastCommsOK && podState.deliveryStatusVerified) {
                // The pod setup is complete and the current delivery state can't be trusted so
                // do a cancel all to be sure that setting the basal program won't fault the pod.
                let _: StatusResponse = try send([CancelDeliveryCommand(nonce: podState.currentNonce, deliveryType: .all, beepType: .noBeepCancel)])
            }
            let status: StatusResponse = try send([basalScheduleCommand, basalExtraCommand])
            return handleResumeState(resumeStartTime: Date(), status: status)
        } catch PodCommsError.unacknowledgedMessage(let seq, let error) {
            podState.unacknowledgedCommand = podState.unacknowledgedCommand?.commsFinished
            log.error("Unacknowledged set basal program: command seq = %d, error = %{public}@", seq, String(describing: error))
            let podCommsError = error as? PodCommsError ?? PodCommsError.commsError(error: error)
            if useGetStatusVerify {
                // Attempt to verify basal using getStatus
                let resumeStartTime = Date()
                guard let getStatusResult = try? getStatus() else {
                    self.log.debug("Status check failed; could not resolve set basal uncertainty")
                    // podState.unfinalizedResume should be set up later as certain in unacknowledgedCommandWasReceived() if verified
                    // podState.suspendState = .resumed(startTime)
                    // podState.unfinalizedResume = UnfinalizedDose(resumeStartTime: resumeStartTime, scheduledCertainty: .uncertain)
                    throw error
                }
                // podState.podState.unacknowledgedCommand should be nil after successful call to getStatus()
                if getStatusResult.deliveryStatus != .suspended {
                    self.log.debug("getStatus resolved set basal uncertainty (succeeded)")
                    return handleResumeState(resumeStartTime: resumeStartTime, status: getStatusResult)
                }
                self.log.debug("getStatus resolved set basal uncertainty (failed)")
            }
            throw podCommsError
        } catch let error {
            podState.unacknowledgedCommand = nil
            // let podCommsError = error as? PodCommsError ?? PodCommsError.commsError(error: error)
            let podCommsError = error as? PodCommsError ?? PodCommsError.noResponse
            throw podCommsError
        }
    }
    
    public func resumeBasal(schedule: BasalSchedule, scheduleOffset: TimeInterval, acknowledgementBeep: Bool = false, programReminderInterval: TimeInterval = 0) throws -> StatusResponse {

        let status = try setBasalSchedule(schedule: schedule, scheduleOffset: scheduleOffset, acknowledgementBeep: acknowledgementBeep, programReminderInterval: programReminderInterval)

        return status
    }
    
    // use cancelDelivery with .none to get status as well as to validate & advance the nonce
    // Throws PodCommsError
    @discardableResult
    public func cancelNone(beepBlock: MessageBlock? = nil) throws -> StatusResponse {
        var statusResponse: StatusResponse

        let cancelResult: CancelDeliveryResult = cancelDelivery(deliveryType: .none, beepBlock: beepBlock)
        switch cancelResult {
        case .certainFailure(let error):
            throw error
        case .unacknowledged(let error):
            throw error
        case .success(let response, _):
            statusResponse = response
        }
        podState.updateFromStatusResponse(statusResponse)
        return statusResponse
    }

    // Throws PodCommsError
    @discardableResult
    public func getStatus(beepBlock: MessageBlock? = nil) throws -> StatusResponse {
        if useCancelNoneForStatus {
            return try cancelNone(beepBlock: beepBlock) // functional replacement for getStatus
        }
        let statusResponse: StatusResponse = try send([GetStatusCommand()], beepBlock: beepBlock)

        if podState.unacknowledgedCommand != nil {
            recoverUnacknowledgedCommand(using: statusResponse)
        }
        podState.updateFromStatusResponse(statusResponse)
        return statusResponse
    }
    
    @discardableResult
    public func getDetailedStatus(beepBlock: MessageBlock? = nil) throws -> DetailedStatus {
        let infoResponse: PodInfoResponse = try send([GetStatusCommand(podInfoType: .detailedStatus)], beepBlock: beepBlock)
        
        guard let detailedStatus = infoResponse.podInfo as? DetailedStatus else {
            throw PodCommsError.unexpectedResponse(response: .podInfoResponse)
        }
        if detailedStatus.isFaulted && self.podState.fault == nil {
            // just detected that the pod has faulted, handle setting the fault state but don't throw
            handlePodFault(fault: detailedStatus)
        } else {
            let derivedStatusResponse = StatusResponse(detailedStatus: detailedStatus)
            if podState.unacknowledgedCommand != nil {
                recoverUnacknowledgedCommand(using: derivedStatusResponse)
            }
            podState.updateFromStatusResponse(derivedStatusResponse)
        }
        return detailedStatus
    }

    public func finalizeFinishedDoses() {
        podState.finalizeFinishedDoses()
    }

    @discardableResult
    public func readPodInfo(podInfoResponseSubType: PodInfoResponseSubType, beepBlock: MessageBlock? = nil) throws -> PodInfoResponse {
        let podInfoCommand = GetStatusCommand(podInfoType: podInfoResponseSubType)
        let podInfoResponse: PodInfoResponse = try send([podInfoCommand], beepBlock: beepBlock)
        return podInfoResponse
    }

    // Reconnected to the pod, and we know program was successful
    private func unacknowledgedCommandWasReceived(pendingCommand: PendingCommand, podStatus: StatusResponse) {
        switch pendingCommand {
        case .program(let program, _, let commandDate, _):
            if let dose = program.unfinalizedDose(at: commandDate, withCertainty: .certain) {
                switch dose.doseType {
                case .bolus:
                    podState.unfinalizedBolus = dose
                case .tempBasal:
                    podState.unfinalizedTempBasal = dose
                case .resume:
                    podState.suspendState = .resumed(commandDate)
                default:
                    break
                }
            }
        case .stopProgram(let stopProgram, _, let commandDate, _):

            if stopProgram.contains(.bolus), let bolus = podState.unfinalizedBolus, !bolus.isFinished(at: commandDate) {
                podState.unfinalizedBolus?.cancel(at: commandDate, withRemaining: podStatus.bolusNotDelivered)
            }
            if stopProgram.contains(.tempBasal), let tempBasal = podState.unfinalizedTempBasal, !tempBasal.isFinished(at: commandDate) {
                podState.unfinalizedTempBasal?.cancel(at: commandDate)
            }
            if stopProgram.contains(.basal) {
                podState.finalizedDoses.append(UnfinalizedDose(suspendStartTime: commandDate, scheduledCertainty: .certain))
                podState.suspendState = .suspended(commandDate)
            }
        }
    }

    public func recoverUnacknowledgedCommand(using status: StatusResponse) {
        if let pendingCommand = podState.unacknowledgedCommand {
            self.log.default("Recovering from unacknowledged command %{public}@, status = %{public}@", String(describing: pendingCommand), String(describing: status))

            if status.lastProgrammingMessageSeqNum == pendingCommand.sequence {
                self.log.debug("Unacknowledged command was received by pump")
                unacknowledgedCommandWasReceived(pendingCommand: pendingCommand, podStatus: status)
            } else {
                self.log.debug("Unacknowledged command was not received by pump")
            }
            podState.unacknowledgedCommand = nil
        }
    }

    // Can be called a second time to deactivate a given pod
    public func deactivatePod() throws {

        // Don't try to cancel if the pod hasn't completed its setup as it will either receive no response
        // (pod progress state <= 2) or creates a $31 pod fault (pod progress states 3 through 7).
        if podState.setupProgress == .completed && podState.fault == nil && !podState.isSuspended {
            let result = cancelDelivery(deliveryType: .all)
            switch result {
            case .certainFailure(let error):
                throw error
            case .unacknowledged(let error):
                throw error
            default:
                break
            }
        }

        // Try to read the most recent pulse log entries for possible later analysis
        _ = try? readPodInfo(podInfoResponseSubType: .pulseLogRecent)
        if podState.fault != nil {
            // Try to read the previous pulse log entries on the faulted pod
            _ = try? readPodInfo(podInfoResponseSubType: .pulseLogPrevious)
        }

        podState.resolveAnyPendingCommandWithUncertainty()
        podState.finalizeFinishedDoses()

        do {
            let deactivatePod = DeactivatePodCommand(nonce: podState.currentNonce)
            let status: StatusResponse = try send([deactivatePod])

            if podState.unacknowledgedCommand != nil {
                recoverUnacknowledgedCommand(using: status)
            }
            podState.updateFromStatusResponse(status)
        } catch let error as PodCommsError {
            switch error {
            case .podFault, .activationTimeExceeded, .unexpectedResponse:
                break
            default:
                throw error
            }
        }
    }

    func acknowledgePodAlerts(alerts: AlertSet, beepBlock: MessageBlock? = nil) throws -> AlertSet {
        let cmd = AcknowledgeAlertCommand(nonce: podState.currentNonce, alerts: alerts)
        let status: StatusResponse = try send([cmd], beepBlock: beepBlock)
        podState.updateFromStatusResponse(status)
        return podState.activeAlertSlots
    }

    func dosesForStorage(_ storageHandler: ([UnfinalizedDose]) -> Bool) {
        assertOnSessionQueue()

        let dosesToStore = podState.dosesToStore

        if storageHandler(dosesToStore) {
            log.info("Stored doses: %@", String(describing: dosesToStore))
            self.podState.finalizedDoses.removeAll()
        }
    }

    public func assertOnSessionQueue() {
        transport.assertOnSessionQueue()
    }
}

extension PodCommsSession: MessageTransportDelegate {
    func messageTransport(_ messageTransport: MessageTransport, didUpdate state: MessageTransportState) {
        messageTransport.assertOnSessionQueue()
        podState.messageTransportState = state
    }
}
