//
//  swiftWavefrontTest.swift
//  SwiftWavefrontTest
//
//  Created by Francis Beauchamp on 2024-06-21.
//

@testable import SwiftWavefront
import XCTest

final class SwiftWavefrontTest: XCTestCase {
    var assetsDir: URL?
    override func setUp() {
        let currentFile = URL(fileURLWithPath: #file)
        let currentDir = currentFile.deletingLastPathComponent()
        assetsDir = currentDir.appendingPathComponent("assets")
    }

    func testParsingQuad() throws {
        guard let path = assetsDir?.appendingPathComponent("cube.obj") else {
            XCTFail()
            return
        }

        let wavefront = Wavefront(filename: path, encoding: .utf8)
        try wavefront.parse()
        XCTAssert(wavefront.vertices.count == 8 * 3)
        XCTAssert(wavefront.textcoords.count == 14 * 2)
        XCTAssert(wavefront.normals.count == 6 * 3)
        XCTAssert(wavefront.shapes[0].indices.count == 36)
        
        let twoTrianglesFromFirstQuad = wavefront.shapes[0].indices[0 ..< 6].map { $0.vIndex }
        XCTAssert(twoTrianglesFromFirstQuad == [0, 4, 6, 0, 6, 2] || twoTrianglesFromFirstQuad == [0, 4, 2, 4, 6, 2])
    }
    
    func testParsingTriangle() throws {
        guard let path = assetsDir?.appendingPathComponent("plane.obj") else {
            XCTFail()
            return
        }

        let wavefront = Wavefront(filename: path, encoding: .utf8)
        try wavefront.parse()
        XCTAssertEqual(wavefront.vertices.count, 6 * 3)
        XCTAssertEqual(wavefront.textcoords.count, 6 * 2)
        XCTAssertEqual(wavefront.normals.count, 6 * 3)
        XCTAssertEqual(wavefront.shapes[0].indices.map { $0.vIndex }, [0, 1, 2, 3, 4, 5])
        XCTAssertEqual(wavefront.shapes[0].indices.map { $0.vtIndex }, [0, 1, 2, 3, 4, 5])
        XCTAssertEqual(wavefront.shapes[0].indices.map { $0.vnIndex }, [0, 1, 2, 3, 4, 5])
    }
}
