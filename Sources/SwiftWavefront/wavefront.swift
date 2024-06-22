//
//  wavefront.swift
//  SwiftWavefront
//
//  Created by Francis Beauchamp on 2024-06-20.
//

import Foundation

/// Contains single and linear arrays of vertex data (position, normal and texcoord)
/// Only supports triangles for now.
public final class Wavefront {
    let filename: URL
    let encoding: String.Encoding
    /**
     3 float per vertex
     
     ```
        v[0]        v[1]        v[2]               v[n-1]
    +-----------+-----------+-----------+      +-----------+
    | x | y | z | x | y | z | x | y | z | .... | x | y | z |
    +-----------+-----------+-----------+      +-----------+
     ```
     */
    public internal(set) var vertices: [Float] = []
    
    /**
     3 float per vertex
     
     ```
        n[0]        n[1]        n[2]               n[n-1]
    +-----------+-----------+-----------+      +-----------+
    | x | y | z | x | y | z | x | y | z | .... | x | y | z |
    +-----------+-----------+-----------+      +-----------+
     ```
     */
    public internal(set) var normals: [Float] = []
    
    /**
     2 float per vertex
     
     ```
       t[0]    t[1]    t[2]          t[n-1]
    +-------+-------+-------+      +-------+
    | u | v | u | v | u | v | .... | u | v |
    +-------+-------+-------+      +-------+
     ```
     */
    public internal(set) var textcoords: [Float] = []
    public internal(set) var tangents: [Float] = []
    public internal(set) var shapes: [Shape] = []
    
    private let parser = WavefrontParser()

    public init(filename: URL, encoding: String.Encoding) {
        self.filename = filename
        self.encoding = encoding
    }
    
    public func parse() throws {
        try parser.parse(wavefront: self)
    }
}
