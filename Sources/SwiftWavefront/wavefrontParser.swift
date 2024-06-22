//
//  wavefrontParser.swift
//  SwiftWavefront
//
//  Created by Francis Beauchamp on 2024-06-20.
//

import Foundation
import Cocoa

// TODO Support vertex color
private enum WavefrontObject: String {
    enum ParseError: Error {
        case invalidFormat
    }

    case comment = "#"
    case vertex = "v"
    case normal = "vn"
    case textcoord = "vt"
    case object = "o"
    case group = "g"
    case face = "f"
    case usemtl = "usemtl"
    case mtllib = "mtllib"
    
    func consume(elements: [String], for wavefront: Wavefront, using parser: WavefrontParser) {
        switch self {
        case .comment:
            break
        case .vertex:
            guard let (x, y, z) = try? WavefrontObject.parseFloat3(elements) else {
                fatalError("Invalid vertex format") // TODO Give line
            }
            wavefront.vertices.append(contentsOf: [x, y, z])
        case .normal:
            guard let (x, y, z) = try? WavefrontObject.parseFloat3(elements) else {
                fatalError("Invalid vertex format") // TODO Give line
            }
            wavefront.normals.append(contentsOf: [x, y, z])
        case .textcoord:
            guard let (u, v) = try? WavefrontObject.parseFloat2(elements) else {
                fatalError("Invalid vertex format") // TODO Give line
            }
            wavefront.textcoords.append(contentsOf: [u, v])
        case .object:
            break
        case .group:
            break
        case .face:
            var face = Face()
            for e in elements[1...] {
                let attrib = Self.parseTriple(e, vSize: wavefront.vertices.count, vnSize: wavefront.normals.count, vtSize: wavefront.textcoords.count)
                face.vertexIndices.append(attrib)
            }
            
            parser.faces.append(face)
        case .usemtl:
            break
        case .mtllib:
            break
        }
    }

    private static func parseFloat3(_ elements: [String]) throws -> (Float, Float, Float) {
        guard let x = Float(elements[1]), let y = Float(elements[2]), let z = Float(elements[3]) else {
            throw ParseError.invalidFormat
        }
        
        return (x, y, z)
    }
    
    private static func parseFloat2(_ elements: [String]) throws -> (Float, Float) {
        guard let x = Float(elements[1]), let y = Float(elements[2]) else {
            throw ParseError.invalidFormat
        }
        
        return (x, y)
    }

    /// Parse triples with index offsets: i, i/j/k, i//k, i/j
    private static func parseTriple(_ s: String, vSize: Int, vnSize: Int, vtSize: Int) -> VertexAttributes {
        if s.contains("/") {
            let parts = s.components(separatedBy: "/")
            guard let idxv = Int(parts[0]), let v = try? fix(index: idxv, n: vSize) else { fatalError("Invalid index format for faces") }
            
            var vt: Int = -1
            var vn: Int = -1

            // i//k
            if parts[1] == "", let idxn = Int(parts[2]), let v = try? fix(index: idxn, n: vnSize)  {
                vn = v
            } else {
                // i/j
                guard let idxt = Int(parts[1]), let fvt = try? fix(index: idxt, n: vtSize) else { fatalError("Invalid index format for faces") }
                vt = fvt
                
                // i/j/k
                guard parts.count == 3 else { return VertexAttributes(vIndex: v, vnIndex: vn, vtIndex: vt) }
                guard let idxn = Int(parts[2]), let fvn = try? fix(index: idxn, n: vnSize) else { fatalError("Invalid index format for faces") }
                vn = fvn
            }
            
            return VertexAttributes(vIndex: v, vnIndex: vn, vtIndex: vt)
        } else {
            guard let i = Int(s), let v = try? fix(index: i, n: vSize) else { fatalError("Invalid index format for faces") }
            return VertexAttributes(vIndex: v, vnIndex: -1, vtIndex: -1)
        }
    }
    
    /// Convert a obj 1 base index into a 0 based index,
    private static func fix(index: Int, n: Int) throws -> Int {
        switch index {
        case let x where x > 0:
            return x - 1
        case let x where x == 0 :
            throw ParseError.invalidFormat
        case let x where x < 0:
            // negative value means a relative value
            let result = x + n
            guard result >= 0 else { throw ParseError.invalidFormat }
            return result
        default:
            return -1 // Cannot happen
        }
    }
}

final class WavefrontParser {
    var faces: [Face] = []

    func parse(wavefront: Wavefront) throws {
        guard FileManager.default.fileExists(atPath: wavefront.filename.path) else {
            preconditionFailure("file expected at \(wavefront.filename.absoluteString) is missing")
        }
        
        guard let filePointer:UnsafeMutablePointer<FILE> = fopen(wavefront.filename.path,"r") else {
            preconditionFailure("Could not open file at \(wavefront.filename.absoluteString)")
        }
        var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
        defer {
            fclose(filePointer)
            lineByteArrayPointer?.deallocate()
        }
        
        var lineCap: Int = 0
        var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
        
        while (bytesRead > 0) {
            
            // note: this translates the sequence of bytes to a string using UTF-8 interpretation
            let lineAsString = String.init(cString:lineByteArrayPointer!).trimmingCharacters(in: .newlines)
            
            parse(line: lineAsString, for: wavefront)
            
            // updates number of bytes read, for the next iteration
            bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
        }
        
        triangulate(into: Shape(), for: wavefront)
    }
    
    private func parse(line: String, for wavefront: Wavefront) {
        let elements = line.components(separatedBy: " ").filter { !$0.isEmpty }
        // Skip unknown markers
        guard let marker = elements.first, let object = WavefrontObject(rawValue: marker) else { return }
        object.consume(elements: elements, for: wavefront, using: self)
    }
    
    /**
     Converts quads into pairs of triangles using one of the two possible configurations.
     
     ```
     0   1      0   1
     +---+      +---+
     |\  |      |  /|
     | \ |  OR  | / |
     |  \|      |/  |
     +---+      +---+
     2   3      2   3
     ```
     */
    private func triangulate(into shape: Shape, for wavefront: Wavefront) {
        for face in faces {
            guard face.vertexIndices.count >= 3 else {
                print("Warning! Degenerate face with less then 3 vertices.")
                continue
            }
            
            
            switch face.vertexIndices.count {
            case let x where x == 3: // Normal triangles
                shape.indices.append(contentsOf: face.vertexIndices)
                shape.numFaceVertices.append(3) // Add two triangles
            case let x where x == 4: // Quads
                let i0 = face.vertexIndices[0]
                let i1 = face.vertexIndices[1]
                let i2 = face.vertexIndices[2]
                let i3 = face.vertexIndices[3]
                
                
                let vi0 = i0.vIndex
                let vi1 = i1.vIndex
                let vi2 = i2.vIndex
                let vi3 = i3.vIndex
                
                guard [vi0, vi1, vi2, vi3].allSatisfy({ 3 * $0 + 2 < wavefront.vertices.count }) else {
                    print("Warning! Degenerate face with less then 3 vertices.")
                    continue
                }
                
                let v0x = wavefront.vertices[vi0 * 3 + 0]
                let v0y = wavefront.vertices[vi0 * 3 + 1]
                let v0z = wavefront.vertices[vi0 * 3 + 2]
                let v1x = wavefront.vertices[vi1 * 3 + 0]
                let v1y = wavefront.vertices[vi1 * 3 + 1]
                let v1z = wavefront.vertices[vi1 * 3 + 2]
                let v2x = wavefront.vertices[vi2 * 3 + 0]
                let v2y = wavefront.vertices[vi2 * 3 + 1]
                let v2z = wavefront.vertices[vi2 * 3 + 2]
                let v3x = wavefront.vertices[vi3 * 3 + 0]
                let v3y = wavefront.vertices[vi3 * 3 + 1]
                let v3z = wavefront.vertices[vi3 * 3 + 2]
                
                let e02x = v2x - v0x
                let e02y = v2y - v0y
                let e02z = v2z - v0z
                let e13x = v3x - v1x
                let e13y = v3y - v1y
                let e13z = v3z - v1z
                
                let sqr02 = e02x * e02x + e02y * e02y + e02z * e02z
                let sqr13 = e13x * e13x + e13y * e13y + e13z * e13z
                
                let attrib = [i0, i1, i2, i3].map {
                    VertexAttributes(
                        vIndex: $0.vIndex,
                        vnIndex: $0.vnIndex,
                        vtIndex: $0.vtIndex
                    )
                }
                
                if sqr02 < sqr13 { // [0, 1, 2], [0, 2, 3]
                    shape.indices.append(contentsOf: [attrib[0], attrib[1], attrib[2], attrib[0], attrib[2], attrib[3]])
                } else { // [0, 1, 3], [1, 2, 3]
                    shape.indices.append(contentsOf: [attrib[0], attrib[1], attrib[3], attrib[1], attrib[2], attrib[3]])
                }

                shape.numFaceVertices.append(contentsOf: [3, 3]) // Add two triangles
            default:
                fatalError("Found face with more than 4 vertices! This is not supported.")
            }
        }

        wavefront.shapes.append(shape)
    }
}
