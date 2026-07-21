import Foundation

enum AppLink: String {
    case privacyPolicy = "https://clarivex279shelvora.site/privacy/368"
    case termsOfUse = "https://clarivex279shelvora.site/terms/368"

    var url: URL? {
        URL(string: rawValue)
    }
}
