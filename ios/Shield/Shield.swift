import ManagedSettings
import ManagedSettingsUI
import UIKit

// Replaces Apple's "Restricted" screen for picked apps/sites with a quote (same list as quote.py).
let quotes = [
    ("You have power over your mind, not outside events. Realize this, and you will find strength.", "Marcus Aurelius"),
    ("It is not that we have a short time to live, but that we waste a lot of it.", "Seneca"),
    ("We suffer more often in imagination than in reality.", "Seneca"),
    ("Well begun is half done.", "Aristotle"),
    ("The secret of getting ahead is getting started.", "Mark Twain"),
    ("Lost time is never found again.", "Benjamin Franklin"),
    ("Concentrate all your thoughts upon the work at hand.", "Alexander Graham Bell"),
    ("Do not wait; the time will never be just right.", "Napoleon Hill"),
    ("First say to yourself what you would be; and then do what you have to do.", "Epictetus"),
    ("How we spend our days is, of course, how we spend our lives.", "Annie Dillard"),
]

class Shield: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration { quote() }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { quote() }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { quote() }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { quote() }

    private func quote() -> ShieldConfiguration {
        let (q, a) = quotes.randomElement()!
        return ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: .black,
            title: .init(text: "Back to work", color: .white),
            subtitle: .init(text: "“\(q)”\n— \(a)", color: .lightGray),
            primaryButtonLabel: .init(text: "OK", color: .black),
            primaryButtonBackgroundColor: .white)
    }
}
