import ArgumentParser
import BuildSettings
import Files
import LOC
import Pattern
import Types

@main
struct Scout: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scout",
        abstract: "Code analysis toolkit for mobile repositories",
        subcommands: [
            Types.self,
            Files.self,
            Pattern.self,
            LOC.self,
            BuildSettings.self,
        ]
    )
}
