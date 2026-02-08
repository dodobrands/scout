import ArgumentParser
import BuildSettingsCLI
import FilesCLI
import LOCCLI
import PatternCLI
import TypesCLI

@main
struct Scout: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scout",
        abstract: "Code analysis toolkit for mobile repositories",
        version: scoutVersion,
        subcommands: [
            TypesCLI.self,
            FilesCLI.self,
            PatternCLI.self,
            LOCCLI.self,
            BuildSettingsCLI.self,
        ]
    )
}
