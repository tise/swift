import Foundation
import PackagePlugin

@main
public struct TiseFormatterPlugin: BuildToolPlugin {

    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }
        return [
            format(
                inputFiles: sourceTarget.sourceFiles(withSuffix: "swift").map(\.path),
                packageDirectory: context.package.directory,
                workingDirectory: context.pluginWorkDirectory,
                tool: try context.tool(named: "swiftformat")
            ),
            lint(
                inputFiles: sourceTarget.sourceFiles(withSuffix: "swift").map(\.path),
                packageDirectory: context.package.directory,
                workingDirectory: context.pluginWorkDirectory,
                tool: try context.tool(named: "swiftlint")
            ),
        ].compactMap { $0 }
    }

    // MARK: Private

    private func format(
        inputFiles: [Path],
        packageDirectory: Path,
        workingDirectory: Path,
        tool: PluginContext.Tool
    ) -> Command? {

        if inputFiles.isEmpty {
            return nil
        }

        var arguments: [String] = [
            "--config", "\(packageDirectory.string + "/FormatRules/tise.swiftformat")"
        ]

        arguments += inputFiles.map(\.string)
        let outputFilesDirectory = workingDirectory.appending("Output")

        return
            .prebuildCommand(
                displayName: "SwiftFormat",
                executable: tool.path,
                arguments: arguments,
                outputFilesDirectory: outputFilesDirectory
            )
    }

    private func lint(
        inputFiles: [Path],
        packageDirectory: Path,
        workingDirectory: Path,
        tool: PluginContext.Tool
    ) -> Command? {

        if inputFiles.isEmpty {
            // Don't lint anything if there are no Swift source files in this target
            return nil
        }

        var arguments = [
            "lint",
            "--quiet",
            // We always pass all of the Swift source files in the target to the tool,
            // so we need to ensure that any exclusion rules in the configuration are
            // respected.
            "--force-exclude",
            "--cache-path", "\(workingDirectory)"
        ]

        // Manually look for configuration files, to avoid issues when the plugin does not execute our tool from the
        // package source directory.

        arguments.append(contentsOf: ["--config", "\(packageDirectory.string + "/FormatRules/swiftlint.yml")"])
        arguments += inputFiles.map(\.string)

        // We are not producing output files and this is needed only to not include cache files into bundle
        let outputFilesDirectory = workingDirectory.appending("Output")

        return
            .prebuildCommand(
                displayName: "SwiftLint",
                executable: tool.path,
                arguments: arguments,
                outputFilesDirectory: outputFilesDirectory
            )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension TiseFormatterPlugin: XcodeBuildToolPlugin {
    public func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {

        let inputFilePaths = target.inputFiles
            .filter { $0.type == .source && $0.path.extension == "swift" }
            .map(\.path)

        return [
            lint(
                inputFiles: inputFilePaths,
                packageDirectory: context.xcodeProject.directory,
                workingDirectory: context.pluginWorkDirectory,
                tool: try context.tool(named: "swiftlint")
            ),
            format(
                inputFiles: inputFilePaths,
                packageDirectory: context.xcodeProject.directory,
                workingDirectory: context.pluginWorkDirectory,
                tool: try context.tool(named: "swiftformat")
            )
        ].compactMap { $0 }
    }
}
#endif
