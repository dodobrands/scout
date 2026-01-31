import Foundation
import Testing

@testable import CodeReader

struct CodeReaderTests {
    @Test("Read UIView classes")
    func readUIView() throws {
        let sut = CodeReader()
        let objects = try sut.parseFile(from: CodeFiles.uiviews)
        let types = objects.filter {
            sut.isInherited(objectFromCode: $0, from: "UIView", allObjects: objects)
        }.map { $0.name }
        #expect(types == ["AwesomeView", "DodoView"])
    }

    @Test("Read SwiftUI View classes")
    func readSwiftUIView() throws {
        let sut = CodeReader()
        let objects = try sut.parseFile(from: CodeFiles.swiftuiviews)
        let types = objects.filter {
            sut.isInherited(objectFromCode: $0, from: "View", allObjects: objects)
        }.map { $0.name }
        #expect(types == ["SelectFullDateView"])
    }

    @Test("Read JsonAsyncRequest generic types")
    func readJsonAsyncRequest() throws {
        let sut = CodeReader()
        let objects = try sut.parseFile(from: CodeFiles.genericTypes)
        let types = objects.filter {
            sut.isInherited(objectFromCode: $0, from: "JsonAsyncRequest", allObjects: objects)
        }.map { $0.name }
        #expect(types == ["CancelOrderRequest", "OrderListRequest", "ProfileRequest"])
    }
}

enum CodeFiles {
    static var uiviews: URL {
        get throws {
            try codeFile(name: "UIViews", extension: "swift")
        }
    }

    static var swiftuiviews: URL {
        get throws {
            try codeFile(name: "SwftUIViews", extension: "swift")
        }
    }

    static var genericTypes: URL {
        get throws {
            try codeFile(name: "GenericTypes", extension: "swift")
        }
    }
}

private func codeFile(name: String, extension ext: String) throws -> URL {
    guard
        let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Samples")
    else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
