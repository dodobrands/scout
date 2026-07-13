import ArgumentParser
import FilesCLI
import LOCCLI
import PatternCLI
import TypesCLI

// BuildSettings shells out to `xcodebuild`, which only exists on macOS.
#if os(macOS)
    import BuildSettingsCLI
#endif

@main
struct Scout: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scout",
        abstract: "Code analysis toolkit for mobile repositories",
        version: scoutVersion,
        subcommands: subcommands
    )

    private static var subcommands: [any ParsableCommand.Type] {
        var commands: [any ParsableCommand.Type] = [
            TypesCLI.self,
            FilesCLI.self,
            PatternCLI.self,
            LOCCLI.self,
        ]
        #if os(macOS)
            commands.append(BuildSettingsCLI.self)
        #endif
        return commands
    }
}
