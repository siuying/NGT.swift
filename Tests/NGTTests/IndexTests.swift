import XCTest
@testable import NGT

final class IndexTests: XCTestCase {
    func testBasic() throws {
        let objects: [[Double]] = [
            [1, 1, 2, 1],
            [5, 4, 6, 5],
            [1, 2, 1, 2]
        ]
        let index = try Index(dimensions: 4)
        XCTAssertEqual(Index.DistanceType.l2, index.distanceType)
        XCTAssertEqual(10, index.edgeSizeForCreation)
        XCTAssertEqual(40, index.edgeSizeForSearch)
        XCTAssertEqual(Index.ObjectType.float, index.objectType)

        let ids = try index.batchInsert(objects)
        XCTAssertEqual([1, 2, 3], ids)

        let result = try index.search(query: objects[0], size: 3)
        XCTAssertEqual(3, result.count)
        try XCTSkipIf(result.count != 3)

        XCTAssertEqual([1, 3, 2], result.map { $0.id })
        XCTAssertEqual(0, result[0].distant)
        XCTAssertEqual(1.732050776481628, result[1].distant)
        XCTAssertEqual(7.549834251403809, result[2].distant)
    }

    func testZeroVector() throws {
        let objects: [[Double]] = [
          [1, 1, 2, 1],
          [0, 0, 0, 0],
          [1, 2, 1, 2],
        ]

        let index = try Index(dimensions: 4, distanceType: .cosine)
        let ids = try index.batchInsert(objects)
        XCTAssertEqual([1, 2, 3], ids)

        let result = try index.search(query: objects[0], size: 3)
        XCTAssertEqual([1], result.map { $0.id })
    }

    func testNan() throws {
        let objects: [[Double]] = [
          [1, 1, 2, 1],
          [Double.nan, 0, 0, 0],
          [1, 2, 1, 2],
        ]

        let index = try Index(dimensions: 4, distanceType: .cosine)
        let ids = try index.batchInsert(objects)
        XCTAssertEqual([1, 2, 3], ids)

        let result = try index.search(query: objects[0], size: 3)
        XCTAssertEqual([1], result.map { $0.id })
    }

    func testInfinite() throws {
        let objects: [[Double]] = [
          [1, 1, 2, 1],
          [Double.infinity, 0, 0, 0],
          [1, 2, 1, 2],
        ]

        let index = try Index(dimensions: 4, distanceType: .cosine)
        let ids = try index.batchInsert(objects)
        XCTAssertEqual([1, 2, 3], ids)

        let result = try index.search(query: objects[0], size: 3)
        XCTAssertEqual([1], result.map { $0.id })
    }

    func testRemove() throws {
        let objects: [[Double]] = [
            [1, 1, 2, 1],
            [5, 4, 6, 5],
            [1, 2, 1, 2]
        ]
        let index = try Index(dimensions: 4, distanceType: .cosine)
        XCTAssertEqual([1, 2, 3], try index.batchInsert(objects))

        try index.remove(id: 3)

        do {
            try index.remove(id: 3)
            XCTFail("expected to throw")
        } catch Index.Error.unexpected(let message) {
            XCTAssertTrue(message.contains("Not in-memory or invalid offset of node."))
        }

        do {
            try index.remove(id: 4)
            XCTFail("expected to throw")
        } catch Index.Error.unexpected(let message) {
            XCTAssertTrue(message.contains("Not in-memory or invalid offset of node."))
        }

        let result = try index.search(query: objects[0])
        XCTAssertEqual(2, result.count)
    }

    func testEmpty() throws {
        let index = try Index(dimensions: 3)
        XCTAssertEqual([], try index.batchInsert([]))
    }

    func testInsertBadDimensions() throws {
        let index = try Index(dimensions: 3)
        do {
            _ = try index.insert([1, 2])
            XCTFail("expected to throw")
        } catch Index.Error.invalidDimension {
            // expected
        }
    }

    func testBatchInsertBadDimensions() throws {
        let index = try Index(dimensions: 3)
        do {
            _ = try index.batchInsert([[1, 2]])
            XCTFail("expected to throw")
        } catch Index.Error.invalidDimension {
            // expected
        }
    }

    func testSearchBadDimensions() throws {
        let index = try Index(dimensions: 3)
        _ = try index.insert([1, 2, 3])
        do {
            _ = try index.search(query: [1,2])
            XCTFail("expected to throw")
        } catch Index.Error.invalidDimension {
            // expected
        }
    }

    func testSaveAndLoad() throws {
        let folder = FileManager.default.temporaryDirectory.appending(component: "IndexTestsSaveLoad")

        let index: Index! = try Index(dimensions: 3)
        _ = try index.batchInsert([[1, 2, 3]])
        try index.save(path: folder.path)
        let result1 = try index.search(query: [1, 2, 3], size: 1)
        XCTAssertEqual([UInt32(1)], result1.map { $0.id })

        let index2 = try Index(path: folder.path)
        let result2 = try index2.search(query: [1, 2, 3], size: 1)
        XCTAssertEqual([UInt32(1)], result2.map { $0.id })
    }
}
