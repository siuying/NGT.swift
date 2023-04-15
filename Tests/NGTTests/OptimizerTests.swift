import XCTest
@testable import NGT

final class OptimizerTests: XCTestCase {
    var testFolder: String!

    override func setUpWithError() throws {
        testFolder = FileManager.default.temporaryDirectory.path.appending("OptimizerTests")
        try FileManager.default.createDirectory(atPath: testFolder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        guard let testFolder = testFolder else { return }
        _ = try? FileManager.default.removeItem(atPath: testFolder)
    }

    func testOptimize() throws {
        let indexPath = testFolder.appending("index")
        let objects: [[Double]] = [
            [1, 1, 2, 1],
            [5, 4, 6, 5],
            [1, 2, 1, 2]
        ]
        let index = try Index(dimensions: 4)
        _ = try index.batchInsert(objects)
        _ = try index.save(path: indexPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: indexPath))

        // create temporary folder
        let optimizerPath = testFolder.appending("optimized")
        let optimizer = Optimizer(queries: 1)
        try optimizer.adjustSearchCoefficients(index: index)
        try optimizer.execute(inIndex: index, outIndexPath: optimizerPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: optimizerPath))
    }
}
