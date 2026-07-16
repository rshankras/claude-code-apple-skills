enum Config {
    static var apiKey: String { Keychain.read("api-key") ?? "" }
}
