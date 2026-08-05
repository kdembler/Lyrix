import OSLog

enum Log {
    private static let subsystem = "dev.kdembler.lyrix"

    static let nowPlaying = Logger(subsystem: subsystem, category: "nowplaying")
    static let lyrics = Logger(subsystem: subsystem, category: "lyrics")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let app = Logger(subsystem: subsystem, category: "app")
}
