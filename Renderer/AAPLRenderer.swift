//
//  AAPLRenderer.swift
//  CPU-GPU-Synchronization-macOS
//
//  Created by 開発 on 3/24/21.
//  Copyright © 2021 Apple. All rights reserved.
//

///*
//See LICENSE folder for this sample’s licensing information.
//
//Abstract:
//Header for a renderer class that performs Metal setup and per-frame rendering.
//*/
//
//@import MetalKit;
import MetalKit
//
//// A platform-independent renderer class.
//@interface AAPLRenderer : NSObject<MTKViewDelegate>
//
//- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;
//
//@end
///*
//See LICENSE folder for this sample’s licensing information.
//
//Abstract:
//Implementation for a renderer class that performs Metal setup and per-frame rendering.
//*/
//
//@import MetalKit;
//
//#import "AAPLRenderer.h"
//#import "AAPLTriangle.h"
//#import "AAPLShaderTypes.h"
//
//// The maximum number of frames in flight.
//static const NSUInteger MaxFramesInFlight = 3;
let MaxFramesInFlight = 3
//
//// The number of triangles in the scene, determined to fit the screen.
//static const NSUInteger NumTriangles = 50;
let NumTriangles = 60
//
//// The main class performing the rendering.
//@implementation AAPLRenderer
//{
@objc(AAPLRenderer)
class AAPLRenderer: NSObject, MTKViewDelegate {
//    // A semaphore used to ensure that buffers read by the GPU are not simultaneously written by the CPU.
//    dispatch_semaphore_t _inFlightSemaphore;
    private var _inFlightSemaphore: DispatchSemaphore
//
//    // A series of buffers containing dynamically-updated vertices.
//    id<MTLBuffer> _vertexBuffers[MaxFramesInFlight];
    private var _vertexBuffers: [MTLBuffer] = .init()
//
//    // The index of the Metal buffer in _vertexBuffers to write to for the current frame.
//    NSUInteger _currentBuffer;
    private var _currentBuffer: Int = .init()
//
//    id<MTLDevice> _device;
    private var _device: MTLDevice
//
//    id<MTLCommandQueue> _commandQueue;
    private var _commandQueue: MTLCommandQueue
//
//    id<MTLRenderPipelineState> _pipelineState;
    private var _pipelineState: MTLRenderPipelineState
//
//    vector_uint2 _viewportSize;
    private var _viewportSize: vector_uint2 = .init()
//
//    NSArray<AAPLTriangle*> *_triangles;
    private var _triangles: [AAPLTriangle] = .init()
//
//    NSUInteger _totalVertexCount;
    private var _totalVertexCount: Int = .init()
//
//    float _wavePosition;
    private var _wavePosition: Float = .init()
//}
//
///// Initializes the renderer with the MetalKit view from which you obtain the Metal device.
//- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
//{
    @objc init(metalKitView mtkView: MTKView) {
//    self = [super init];
//    if(self)
//    {
//        _device = mtkView.device;
        _device = mtkView.device!  //#Simplifying error handling...
//
//        _inFlightSemaphore = dispatch_semaphore_create(MaxFramesInFlight);
        _inFlightSemaphore = DispatchSemaphore(value: MaxFramesInFlight)
//
//        // Load all the shader files with a metal file extension in the project.
//        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        let defaultLibrary = _device.makeDefaultLibrary()!  //#Simplifying error handling...
//
//        // Load the vertex shader.
//        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
//
//        // Load the fragment shader.
//        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")
//
//        // Create a reusable pipeline state object.
//        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
//        pipelineStateDescriptor.label = @"MyPipeline";
        pipelineStateDescriptor.label = "MyPipeline"
//        pipelineStateDescriptor.sampleCount = mtkView.sampleCount;
        pipelineStateDescriptor.sampleCount = mtkView.sampleCount
//        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.vertexFunction = vertexFunction
//        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
//        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
//        pipelineStateDescriptor.vertexBuffers[AAPLVertexInputIndexVertices].mutability = MTLMutabilityImmutable;
//
//        NSError *error;
        do {
//
//        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            _pipelineState = try _device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
//
//        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
//
//        // Create the command queue.
//        _commandQueue = [_device newCommandQueue];
        _commandQueue = _device.makeCommandQueue()!  //#Simplifying error handling...
//
        super.init()
//        // Generate the triangles rendered by the app.
//        [self generateTriangles];
        generateTriangles()
//
//        // Calculate vertex data and allocate vertex buffers.
//        const NSUInteger triangleVertexCount = [AAPLTriangle vertexCount];
        let triangleVertexCount = AAPLTriangle.vertexCount
//        _totalVertexCount = triangleVertexCount * _triangles.count;
        _totalVertexCount = triangleVertexCount * _triangles.count
//        const NSUInteger triangleVertexBufferSize = _totalVertexCount * sizeof(AAPLVertex);
        let triangleVertexBufferSize = _totalVertexCount * MemoryLayout<AAPLVertex>.stride
//
//        for(NSUInteger bufferIndex = 0; bufferIndex < MaxFramesInFlight; bufferIndex++)
//        {
        for bufferIndex in 0..<MaxFramesInFlight {
//            _vertexBuffers[bufferIndex] = [_device newBufferWithLength:triangleVertexBufferSize
            let buffer = _device.makeBuffer(length: triangleVertexBufferSize,
//                                                               options:MTLResourceStorageModeShared];
                                            options: .storageModeShared)!
//            _vertexBuffers[bufferIndex].label = [NSString stringWithFormat:@"Vertex Buffer #%lu", (unsigned long)bufferIndex];
            buffer.label = "Vertex Buffer #\(bufferIndex)"
            _vertexBuffers.append(buffer)
//        }
        }
//    }
//    return self;
//}
    }
//
///// Generates an array of triangles, initializing each and inserting it into `_triangles`.
//- (void)generateTriangles
//{
    private func generateTriangles() {
//    // Array of colors.
//    const vector_float4 Colors[] =
//    {
        let Colors: [vector_float4] = [
//        { 1.0, 0.0, 0.0, 1.0 },  // Red
            .init(1.0, 0.0, 0.0, 1.0),  // Red
//        { 0.0, 1.0, 0.0, 1.0 },  // Green
            .init(0.0, 1.0, 0.0, 1.0),  // Green
//        { 0.0, 0.0, 1.0, 1.0 },  // Blue
            .init(0.0, 0.0, 1.0, 1.0),  // Blue
//        { 1.0, 0.0, 1.0, 1.0 },  // Magenta
            .init(1.0, 0.0, 1.0, 1.0),  // Magenta
//        { 0.0, 1.0, 1.0, 1.0 },  // Cyan
            .init(0.0, 1.0, 1.0, 1.0),  // Cyan
//        { 1.0, 1.0, 0.0, 1.0 },  // Yellow
            .init(1.0, 1.0, 0.0, 1.0),  // Yellow
//    };
        ]
//
//    const NSUInteger NumColors = sizeof(Colors) / sizeof(vector_float4);
        var NumColors: Int {Colors.count}
//
//    // Horizontal spacing between each triangle.
//    const float horizontalSpacing = 16;
        let horizontalSpacing: Float = 16
//
//    NSMutableArray *triangles = [[NSMutableArray alloc] initWithCapacity:NumTriangles];
        var triangles: [AAPLTriangle] = []
        triangles.reserveCapacity(NumTriangles)
//
//    // Initialize each triangle.
//    for(NSUInteger t = 0; t < NumTriangles; t++)
//    {
        for t in 0..<NumTriangles {
//        vector_float2 trianglePosition;
            let trianglePosition = vector_float2(
//
//        // Determine the starting position of the triangle in a horizontal line.
//        trianglePosition.x = ((-((float)NumTriangles) / 2.0) + t) * horizontalSpacing;
                ((-Float(NumTriangles) / 2.0) + Float(t)) * horizontalSpacing,
//        trianglePosition.y = 0.0;
                0.0)
//
//        // Create the triangle, set its properties, and add it to the array.
//        AAPLTriangle * triangle = [AAPLTriangle new];
            let triangle = AAPLTriangle()
//        triangle.position = trianglePosition;
            triangle.position = trianglePosition
//        triangle.color = Colors[t % NumColors];
            triangle.color = Colors[t % NumColors]
//        [triangles addObject:triangle];
            triangles.append(triangle)
//    }
        }
//    _triangles = triangles;
        _triangles = triangles
//}
    }
//
///// Updates the position of each triangle and also updates the vertices for each triangle in the current buffer.
//- (void)updateState
//{
    private func updateState() {
//    // Simplified wave properties.
//    const float waveMagnitude = 128.0;  // Vertical displacement.
        let waveMagnitude: Float = 128.0  // Vertical displacement.
//    const float waveSpeed     = 0.05;   // Displacement change from the previous frame.
        let waveSpeed: Float     = 0.05   // Displacement change from the previous frame.
//
//    // Increment wave position from the previous frame
//    _wavePosition += waveSpeed;
        _wavePosition += waveSpeed
//
//    // Vertex data for a single default triangle.
//    const AAPLVertex *triangleVertices = [AAPLTriangle vertices];
        let triangleVertices = AAPLTriangle.vertices
//    const NSUInteger triangleVertexCount = [AAPLTriangle vertexCount];
        let triangleVertexCount = AAPLTriangle.vertexCount
//
//    // Vertex data for the current triangles.
//    AAPLVertex *currentTriangleVertices = _vertexBuffers[_currentBuffer].contents;
        let currentTriangleVertices = _vertexBuffers[_currentBuffer].contents().assumingMemoryBound(to: AAPLVertex.self)
//
//    // Update each triangle.
//    for(NSUInteger triangle = 0; triangle < NumTriangles; triangle++)
//    {
        for triangle in 0..<NumTriangles {
//        vector_float2 trianglePosition = _triangles[triangle].position;
            var trianglePosition = _triangles[triangle].position
//
//        // Displace the y-position of the triangle using a sine wave.
//        trianglePosition.y = (sin(trianglePosition.x/waveMagnitude + _wavePosition) * waveMagnitude);
            trianglePosition.y = (sin(trianglePosition.x/waveMagnitude + _wavePosition) * waveMagnitude)
//
//        // Update the position of the triangle.
//        _triangles[triangle].position = trianglePosition;
            _triangles[triangle].position = trianglePosition
//
//        // Update the vertices of the current vertex buffer with the triangle's new position.
//        for(NSUInteger vertex = 0; vertex < triangleVertexCount; vertex++)
//        {
            for vertex in 0..<triangleVertexCount {
//            NSUInteger currentVertex = vertex + (triangle * triangleVertexCount);
                let currentVertex = vertex + (triangle * triangleVertexCount)
//            currentTriangleVertices[currentVertex].position = triangleVertices[vertex].position + _triangles[triangle].position;
                currentTriangleVertices[currentVertex].position = triangleVertices[vertex].position + _triangles[triangle].position
//            currentTriangleVertices[currentVertex].color = _triangles[triangle].color;
                currentTriangleVertices[currentVertex].color = _triangles[triangle].color
//        }
            }
//    }
        }
//}
    }
//
//#pragma mark - MetalKit View Delegate
//
///// Handles view orientation or size changes.
//- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
//{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//    // Regenerate the triangles.
//    [self generateTriangles];
        generateTriangles()
//
//    // Save the size of the drawable as you'll pass these
//    // values to the vertex shader when you render.
//    _viewportSize.x = size.width;
        _viewportSize.x = UInt32(size.width)
//    _viewportSize.y = size.height;
        _viewportSize.y = UInt32(size.height)
//}
    }
//
///// Handles view rendering for a new frame.
//- (void)drawInMTKView:(nonnull MTKView *)view
//{
    func draw(in view: MTKView) {
//    // Wait to ensure only `MaxFramesInFlight` number of frames are getting processed
//    // by any stage in the Metal pipeline (CPU, GPU, Metal, Drivers, etc.).
//    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
        _ = _inFlightSemaphore.wait(timeout: .distantFuture)
//
//    // Iterate through the Metal buffers, and cycle back to the first when you've written to the last.
//    _currentBuffer = (_currentBuffer + 1) % MaxFramesInFlight;
        _currentBuffer = (_currentBuffer + 1) % MaxFramesInFlight
//
//    // Update buffer data.
//    [self updateState];
        updateState()
//
//    // Create a new command buffer for each rendering pass to the current drawable.
//    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
//    commandBuffer.label = @"MyCommandBuffer";
        let commandBuffer = _commandQueue.makeCommandBuffer()!
//
//    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
//    if(renderPassDescriptor != nil)
//    {
//        // Create a render command encoder to encode the rendering pass.
//        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
//        renderEncoder.label = @"MyRenderEncoder";
            renderEncoder.label = "MyRenderEncoder"
//
//        // Set render command encoder state.
//        [renderEncoder setRenderPipelineState:_pipelineState];
            renderEncoder.setRenderPipelineState(_pipelineState)
//
//        // Set the current vertex buffer.
//        [renderEncoder setVertexBuffer:_vertexBuffers[_currentBuffer]
            renderEncoder.setVertexBuffer(_vertexBuffers[_currentBuffer],
                                          offset: 0,
                                          index: Int(AAPLVertexInputIndexVertices.rawValue))
//                                offset:0
//                               atIndex:AAPLVertexInputIndexVertices];
//
//        // Set the viewport size.
//        [renderEncoder setVertexBytes:&_viewportSize
            renderEncoder.setVertexBytes(&_viewportSize,
                                         length: MemoryLayout.stride(ofValue: _viewportSize),
                                         index: Int(AAPLVertexInputIndexViewportSize.rawValue))
//                               length:sizeof(_viewportSize)
//                              atIndex:AAPLVertexInputIndexViewportSize];
//
//        // Draw the triangle vertices.
//        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
            renderEncoder.drawPrimitives(type: .triangle,
                                         vertexStart: 0,
                                         vertexCount: _totalVertexCount)
//                          vertexStart:0
//                          vertexCount:_totalVertexCount];
//
//        // Finalize encoding.
//        [renderEncoder endEncoding];
            renderEncoder.endEncoding()
//
//        // Schedule a drawable's presentation after the rendering pass is complete.
//        [commandBuffer presentDrawable:view.currentDrawable];
            commandBuffer.present(view.currentDrawable!)
//    }
        }
//
//    // Add a completion handler that signals `_inFlightSemaphore` when Metal and the GPU have fully
//    // finished processing the commands that were encoded for this frame.
//    // This completion indicates that the dynamic buffers that were written-to in this frame, are no
//    // longer needed by Metal and the GPU; therefore, the CPU can overwrite the buffer contents
//    // without corrupting any rendering operations.
//    __block dispatch_semaphore_t block_semaphore = _inFlightSemaphore;
        let block_semaphore = _inFlightSemaphore
//    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
//     {
        commandBuffer.addCompletedHandler {buffer in
//         dispatch_semaphore_signal(block_semaphore);
            block_semaphore.signal()
//     }];
        }
//
//    // Finalize CPU work and submit the command buffer to the GPU.
//    [commandBuffer commit];
        commandBuffer.commit()
//}
    }
//
//@end
}
