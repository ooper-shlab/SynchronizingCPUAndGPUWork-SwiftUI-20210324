//
//  MyMtkView.swift
//  CPU-GPU-Synchronization-iOS
//
//  Created by 開発 on 3/24/21.
//  Copyright © 2021 OOPer's. All rights reserved.
//

import SwiftUI
import MetalKit

struct MyMtkView: UIViewRepresentable {
    typealias UIViewType = MTKView
    var mtkView: MTKView
    
    init() {
        self.mtkView = MTKView()
    }
            
    func makeCoordinator() -> Coordinator {
        Coordinator(self, mtkView: mtkView)
    }
    
    func makeUIView(context: UIViewRepresentableContext<MyMtkView>) -> MTKView {
        mtkView.delegate = context.coordinator
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = true
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<MyMtkView>) {
        //
    }
    
    class Coordinator : AAPLRenderer {
        var parent: MyMtkView
        
        init(_ parent: MyMtkView, mtkView: MTKView) {
            self.parent = parent
            guard let metalDevice = MTLCreateSystemDefaultDevice() else {
                fatalError("Metal is not supported on this device")
            }
            mtkView.device = metalDevice
            
            super.init(metalKitView: mtkView)
            mtkView.framebufferOnly = false
            mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            mtkView.drawableSize = mtkView.frame.size
            mtkView.enableSetNeedsDisplay = true
            
            self.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        }
    }
}
