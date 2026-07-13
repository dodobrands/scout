import Foundation
import Testing

@testable import Types

struct SymbolGraphParserTests {
    @Test
    func `Parses inheritsFrom relationships into class inheritance edges`() throws {
        let json = """
            {
              "symbols": [
                { "identifier": { "precise": "s:5UIKit20UICollectionViewCellC" },
                  "names": { "title": "UICollectionViewCell" },
                  "kind": { "identifier": "swift.class" } },
                { "identifier": { "precise": "s:5UIKit24UICollectionReusableViewC" },
                  "names": { "title": "UICollectionReusableView" },
                  "kind": { "identifier": "swift.class" } },
                { "identifier": { "precise": "s:5UIKit6UIViewC" },
                  "names": { "title": "UIView" },
                  "kind": { "identifier": "swift.class" } }
              ],
              "relationships": [
                { "kind": "inheritsFrom",
                  "source": "s:5UIKit20UICollectionViewCellC",
                  "target": "s:5UIKit24UICollectionReusableViewC" },
                { "kind": "inheritsFrom",
                  "source": "s:5UIKit24UICollectionReusableViewC",
                  "target": "s:5UIKit6UIViewC" }
              ]
            }
            """

        let objects = try SymbolGraphParser.objects(fromSymbolGraphJSON: Data(json.utf8))
        let inheritance = Dictionary(
            uniqueKeysWithValues: objects.map { ($0.name, $0.inheritedTypes) }
        )

        #expect(inheritance["UICollectionViewCell"] == ["UICollectionReusableView"])
        #expect(inheritance["UICollectionReusableView"] == ["UIView"])
        #expect(objects.allSatisfy { $0.kind == .classType })
    }

    @Test
    func `Falls back to Objective-C USR name when target symbol is absent`() throws {
        let json = """
            {
              "symbols": [
                { "identifier": { "precise": "s:5UIKit11UIResponderC" },
                  "names": { "title": "UIResponder" },
                  "kind": { "identifier": "swift.class" } }
              ],
              "relationships": [
                { "kind": "inheritsFrom",
                  "source": "s:5UIKit11UIResponderC",
                  "target": "c:objc(cs)NSObject" }
              ]
            }
            """

        let objects = try SymbolGraphParser.objects(fromSymbolGraphJSON: Data(json.utf8))
        let responder = try #require(objects.first { $0.name == "UIResponder" })

        #expect(responder.inheritedTypes == ["NSObject"])
    }

    @Test
    func `Ignores non-inheritance relationships such as conformsTo`() throws {
        let json = """
            {
              "symbols": [
                { "identifier": { "precise": "s:5UIKit6UIViewC" },
                  "names": { "title": "UIView" },
                  "kind": { "identifier": "swift.class" } }
              ],
              "relationships": [
                { "kind": "conformsTo",
                  "source": "s:5UIKit6UIViewC",
                  "target": "s:s8SendableP" }
              ]
            }
            """

        let objects = try SymbolGraphParser.objects(fromSymbolGraphJSON: Data(json.utf8))

        #expect(objects.isEmpty)
    }
}
