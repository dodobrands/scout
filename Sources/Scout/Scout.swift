import ArgumentParser
import CountFiles
import CountImports
import CountLOC
import CountTypes
import ExtractBuildSettings

@main
struct Scout: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scout",
        abstract: "Code analysis toolkit for mobile repositories",
        subcommands: [
            Types.self,
            Files.self,
            Imports.self,
            LOC.self,
            BuildSettings.self,
        ]
    )
}
