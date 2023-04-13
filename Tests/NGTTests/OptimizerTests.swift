import XCTest
@testable import NGT

final class OptimizerTests: XCTestCase {
    var testFolder: URL!

    override func setUpWithError() throws {
        testFolder = FileManager.default.temporaryDirectory.appending(component: "OptimizerTests")
        try FileManager.default.createDirectory(atPath: testFolder.path(), withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        guard let testFolder = testFolder else { return }
        _ = try? FileManager.default.removeItem(at: testFolder)
    }

    func testOptimize() throws {
        let indexPath = testFolder.appending(component: "index").path()
        let objects: [[Double]] = [
            [1, 1, 2, 1],
            [5, 4, 6, 5],
            [1, 2, 1, 2]
        ]
        let index = Index(dimensions: 4)
        _ = try index.batchInsert(objects)
        _ = try index.save(path: indexPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: indexPath))

        // create temporary folder
        let optimizerURL = testFolder.appending(component: "optimized")
        let optimizer = Optimizer(queries: 1)
        try optimizer.adjustSearchCoefficients(index: index)
        try optimizer.execute(inIndex: index, outIndexPath: optimizerURL.path())
        XCTAssertTrue(FileManager.default.fileExists(atPath: optimizerURL.path()))
    }
}
