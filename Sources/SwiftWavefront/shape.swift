//
//  shape.swift
//  SwiftWavefront
//
//  Created by Francis Beauchamp on 2024-06-21.
//

import Foundation

final class Shape {
    /**
     Array of VertexAttributes. Each entry has the associated index to vertices, normals and textcoords.
     
     ```
     |    face[0]   |    face[1]   |     | face[n-1] |
     +----+----+----+----+----+----+     +-----------+
     | i0 | i1 | i2 | i3 | i4 | i5 | ... |   i(n-1)  |
     +----+----+----+----+----+----+     +-----------+
     ```
     */
    public internal(set) var indices: [VertexAttributes] = []
    
    // For now force quads into 2 triangles with simple triangulation
    public internal(set) var numFaceVertices: [Int] = []
}
