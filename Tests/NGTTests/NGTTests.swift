import XCTest
@testable import NGT

final class NGTTests: XCTestCase {
    func testBasic() throws {
        let objects: [[Double]] = [
            [1, 1, 2, 1],
            [5, 4, 6, 5],
            [1, 2, 1, 2]
        ]
        let index = Index(dimensions: 4)
        XCTAssertEqual(Index.DistanceType.l2, index.distanceType)
        XCTAssertEqual(10, index.edgeSizeForCreation)
        XCTAssertEqual(40, index.edgeSizeForSearch)
        XCTAssertEqual(Index.ObjectType.float, index.objectType)

        let ids = index.batchInsert(objects)
        XCTAssertEqual([1, 2, 3], ids)

        let result = index.search(query: objects[0], size: 3)
        XCTAssertEqual(3, result.count)
        try XCTSkipIf(result.count != 3)

        XCTAssertEqual([1, 3, 2], result.map { $0.id })
        XCTAssertEqual(0, result[0].distant)
        XCTAssertEqual(1.732050776481628, result[1].distant)
        XCTAssertEqual(7.549834251403809, result[2].distant)
    }
}
