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
    }
    
    func testParsingTriangle() throws {
        guard let path = assetsDir?.appendingPathComponent("plane.obj") else {
            XCTFail()
            return
        }

        let wavefront = Wavefront(filename: path, encoding: .utf8)
        try wavefront.parse()
        XCTAssert(wavefront.vertices.count == 6 * 3)
        XCTAssert(wavefront.textcoords.count == 6 * 2)
        XCTAssert(wavefront.normals.count == 6 * 3)
        XCTAssert(wavefront.shapes[0].indices.count == 6)
    }
}
