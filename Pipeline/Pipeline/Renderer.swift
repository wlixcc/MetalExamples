//
//  Renderer.swift
//  Pipeline
//
//  Created by wl on 2021/5/17.
//

import MetalKit

class Renderer: NSObject {
    
    // 在绝大多数情况下,我们会有1个MTLDevice, 1个MTLCommandQueue, 1个MTLLibrary(这里我们无需持有)。 多个vertexBuffer和多个pipelineStateMTLRenderPipelineState
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    var mesh: MTKMesh!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    
    
    init(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 1.0, green: 0.8, blue: 1.0, alpha: 1.0)
        metalView.delegate = self
        
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        print("draw")
    }
    
  
}


