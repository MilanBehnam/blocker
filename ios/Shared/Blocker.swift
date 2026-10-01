import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

// Same list and hours as blocker.sh.
let sites = ["youtube.com", "reddit.com", "twitter.com", "x.com", "instagram.com", "facebook.com"]
let weekdays = 2...6 // Mon-Fri, Calendar counts Sunday as 1
let startHour = 9, endHour = 17

// App and extensions share "group.<app bundle id>"; extension ids are "<app bundle id>.<name>".
private let appID: String = {
    let id = Bundle.main.bundleIdentifier!
    return Bundle.main.bundlePath.hasSuffix(".appex") ? String(id[..<id.lastIndex(of: ".")!]) : id
}()
private let defaults = UserDefaults(suiteName: "group.\(appID)")!
private let store = ManagedSettingsStore()

// Apps/sites picked in the app; Apple only hands these out as opaque tokens.
var selection: FamilyActivitySelection {
    get { defaults.data(forKey: "selection").flatMap { try? JSONDecoder().decode(FamilyActivitySelection.self, from: $0) } ?? FamilyActivitySelection() }
    set { defaults.set(try? JSONEncoder().encode(newValue), forKey: "selection") }
}

func isActive(_ now: Date = .now) -> Bool {
    let c = Calendar.current.dateComponents([.weekday, .hour], from: now)
    return weekdays.contains(c.weekday!) && (startHour..<endHour).contains(c.hour!)
}

func block() {
    let s = selection
    store.webContent.blockedByFilter = .specific(Set(sites.flatMap { [$0, "www.\($0)", "m.\($0)"] }.map { WebDomain(domain: $0) }))
    store.shield.applications = s.applicationTokens.isEmpty ? nil : s.applicationTokens
    store.shield.webDomains = s.webDomainTokens.isEmpty ? nil : s.webDomainTokens
    store.shield.applicationCategories = s.categoryTokens.isEmpty ? nil : .specific(s.categoryTokens)
    store.shield.webDomainCategories = s.categoryTokens.isEmpty ? nil : .specific(s.categoryTokens)
}

func unblock() { store.clearAllSettings() }

func startSchedule() throws {
    let center = DeviceActivityCenter()
    for d in weekdays {
        try center.startMonitoring(DeviceActivityName("day\(d)"), during: DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, weekday: d),
            intervalEnd: DateComponents(hour: endHour, weekday: d),
            repeats: true))
    }
}
