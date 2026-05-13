import AppKit
import Carbon.HIToolbox
import Foundation
import os

/// Global keyboard shortcut service backed by the Carbon HotKey API.
///
/// Unlike `NSEvent.addGlobalMonitorForEvents`, `RegisterEventHotKey` does **not**
/// require Accessibility permission, fires even when the app is in the
/// background, and is delivered system-wide. This is the canonical way to
/// expose global hotkeys for a menubar (LSUIElement) app on macOS.
@MainActor
final class GlobalShortcutService {
    // MARK: - Public API (kept identical to legacy implementation)

    var onAction: ((ShortcutAction) -> Void)?

    func start(with bindings: [ShortcutBinding]) {
        stop()
        installHandlerIfNeeded()

        let active = bindings.filter { $0.isEnabled && $0.keyCode != nil }
        guard !active.isEmpty else { return }

        for binding in active {
            register(binding)
        }
    }

    func stop() {
        for entry in registrations.values {
            UnregisterEventHotKey(entry.ref)
        }
        registrations.removeAll()
    }

    deinit {
        for entry in registrations.values {
            UnregisterEventHotKey(entry.ref)
        }
        registrations.removeAll()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    // MARK: - Internals

    private struct Registration {
        let ref: EventHotKeyRef
        let action: ShortcutAction
    }

    /// hotKey signature ('LCSC' fourCC) — arbitrary identifier for our app
    private static let hotKeySignature: OSType = {
        let chars: [Character] = ["L", "C", "S", "C"]
        var value: OSType = 0
        for ch in chars {
            value = (value << 8) | OSType(ch.asciiValue ?? 0)
        }
        return value
    }()

    private var registrations: [UInt32: Registration] = [:]
    private var eventHandler: EventHandlerRef?
    private var nextHotKeyID: UInt32 = 1
    private let log = Logger(subsystem: "fr.hugoinformatique.lampcontrol", category: "GlobalShortcutService")

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        var handlerRef: EventHandlerRef?

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<GlobalShortcutService>.fromOpaque(userData).takeUnretainedValue()

                var hkID = EventHotKeyID()
                let getStatus = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                guard getStatus == noErr else { return OSStatus(eventNotHandledErr) }

                service.handleHotKey(id: hkID.id)
                return noErr
            },
            1,
            &spec,
            selfPtr,
            &handlerRef
        )

        if status == noErr {
            eventHandler = handlerRef
        } else {
            log.error("InstallEventHandler failed: \(status, privacy: .public)")
        }
    }

    private func register(_ binding: ShortcutBinding) {
        guard let keyCode = binding.keyCode else { return }

        let nsFlags = NSEvent.ModifierFlags(rawValue: binding.modifierFlags)
        let carbonMods = Self.carbonModifiers(from: nsFlags)

        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: nextHotKeyID)
        var ref: EventHotKeyRef?

        let status = RegisterEventHotKey(
            UInt32(keyCode),
            carbonMods,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status == noErr, let ref {
            registrations[nextHotKeyID] = Registration(ref: ref, action: binding.action)
            nextHotKeyID &+= 1
        } else {
            log.error("RegisterEventHotKey failed for \(binding.action.rawValue, privacy: .public) (status=\(status, privacy: .public)). Combo may already be taken.")
        }
    }

    private func handleHotKey(id: UInt32) {
        guard let entry = registrations[id] else { return }
        let action = entry.action
        if Thread.isMainThread {
            onAction?(action)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onAction?(action)
            }
        }
    }

    /// Convert `NSEvent.ModifierFlags` (device-independent) to the Carbon modifier mask
    /// expected by `RegisterEventHotKey` (`cmdKey`, `optionKey`, `controlKey`, `shiftKey`).
    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command)  { carbon |= UInt32(cmdKey) }
        if flags.contains(.option)   { carbon |= UInt32(optionKey) }
        if flags.contains(.control)  { carbon |= UInt32(controlKey) }
        if flags.contains(.shift)    { carbon |= UInt32(shiftKey) }
        return carbon
    }
}
