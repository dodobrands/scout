import ArgumentParser
import CountFiles
import CountLOC
import CountTypes
import ExtractBuildSettings
import Search

@main
struct Scout: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scout",
        abstract: "Code analysis toolkit for mobile repositories",
        subcommands: [
            Types.self,
            Files.self,
            Search.self,
            LOC.self,
            BuildSettings.self,
        ]
    )
}
