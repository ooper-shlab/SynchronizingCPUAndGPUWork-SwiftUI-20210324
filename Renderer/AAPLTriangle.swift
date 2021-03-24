//
//  AAPLTriangle.swift
//  CPU-GPU-Synchronization-macOS
//
//  Created by 開発 on 3/24/21.
//  Copyright © 2021 Apple. All rights reserved.
//

///*
//See LICENSE folder for this sample’s licensing information.
//
//Abstract:
//Header for a simple class that represents a colored triangle object.
//*/
//
//@import MetalKit;
import MetalKit
//#import "AAPLShaderTypes.h"
//
//@interface AAPLTriangle : NSObject
@objc(AAPLTriangle)
class AAPLTriangle: NSObject {
//
//@property (nonatomic) vector_float2 position;
    @objc var position: vector_float2 = .zero
//@property (nonatomic) vector_float4 color;
    @objc var color: vector_float4 = .zero
//
//+(const AAPLVertex*)vertices;
//+(NSUInteger)vertexCount;
//
//@end
///*
//See LICENSE folder for this sample’s licensing information.
//
//Abstract:
//Implementation for a simple class that represents a colored triangle object.
//*/
//
//#import "AAPLTriangle.h"
//
//@implementation AAPLTriangle
//
///// Returns the vertices of one triangle.
///// The default position is centered at the origin.
///// The default color is white.
//+(const AAPLVertex *)vertices
//{
    @objc static var vertices: UnsafePointer<AAPLVertex> {
//    const float TriangleSize = 64;
        enum My {
            static let TriangleSize: Float = 64
//    static const AAPLVertex triangleVertices[] =
//    {
            static let triangleVerticesBuffer: UnsafeMutableBufferPointer<AAPLVertex> = {
                let buffer = UnsafeMutableBufferPointer<AAPLVertex>.allocate(capacity: 3)
        _ = buffer.initialize(from: [
//        // Pixel Positions,                          RGBA colors.
//        { { -0.5*TriangleSize, -0.5*TriangleSize },  { 1, 1, 1, 1 } },
                AAPLVertex(position: vector_float2(-0.5*TriangleSize, -0.5*TriangleSize),
                           color: vector_float4(1, 1, 1, 1)),
//        { {  0.0*TriangleSize, +0.5*TriangleSize },  { 1, 1, 1, 1 } },
                AAPLVertex(position: vector_float2( 0.0*TriangleSize, +0.5*TriangleSize),
                           color: vector_float4(1, 1, 1, 1)),
//        { { +0.5*TriangleSize, -0.5*TriangleSize },  { 1, 1, 1, 1 } }
                AAPLVertex(position: vector_float2(+0.5*TriangleSize, -0.5*TriangleSize),
                           color: vector_float4(1, 1, 1, 1)),
//    };
        ])
                return buffer
            }()
        }
//    return triangleVertices;
        return UnsafePointer(My.triangleVerticesBuffer.baseAddress!)
//}
    }
//
///// Returns the number of vertices for each triangle.
//+(const NSUInteger)vertexCount
//{
    @objc static let vertexCount: Int = 3
//    return 3;
//}
//
//@end
}
