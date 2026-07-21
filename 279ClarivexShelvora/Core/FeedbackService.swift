import UIKit
import AudioToolbox

enum FeedbackService {
    static func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func mediumTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func softSuccess() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func successNotification() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warningNotification() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func playSuccessPing() {
        AudioServicesPlaySystemSound(1057)
    }

    static func playSaveTick() {
        AudioServicesPlaySystemSound(1104)
    }

    static func playEntrySaved() {
        AudioServicesPlaySystemSound(1105)
    }

    static func playTick() {
        AudioServicesPlaySystemSound(1003)
    }

    static func achievementUnlocked() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1057)
    }

    static func completeMeaningfulAction() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1057)
    }
}
