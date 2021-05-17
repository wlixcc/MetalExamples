import PlaygroundSupport
import MetalKit



guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("GPU is not supported")
}


//----------- 1.创建MTKView

let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
// MTKView在macOS下是NSView的子类,在iOS下是UIView的子类
let view = MTKView(frame: frame, device: device)
// 设置MTKView的背景颜色颜色,这里我们设置为白色
view.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)


//---------- 2. 创建model

// 1.allocator用于管理mesh data
let allocator = MTKMeshBufferAllocator(device: device)

// 2.我们使用Model I/O创建了一个球体
let mdlMesh = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75], segments: [100 , 100], inwardNormals: false, geometryType: .triangles, allocator: allocator)

// 3.将MDLMesh转为MTKMesh
let mesh = try MTKMesh(mesh: mdlMesh, device: device)


//------------ 3. Queues, buffers and encoder

//通常,我们需要在app启动的时候配置好device和command queue。并且在整个App生命周期中使用同一个device和command queue
guard let commandQueue = device.makeCommandQueue() else {
    fatalError("CommandQueue error")
}


// ----------- 4. Shader functions

// 一般情况下，我们会将shader函数写在别的文件中,这里我们直接使用。 其中vertex函数我们用于指定顶点位置, fragment用于指定像数点颜色
let shader = """
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
  float4 position [[ attribute(0) ]];
};

vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) {
  return vertex_in.position;
}

fragment float4 fragment_main() {
  return float4(1, 0, 0, 1);
}
"""

// metal使用shader
let library = try device.makeLibrary(source: shader, options: nil)
let vertexFunction = library.makeFunction(name: "vertex_main")
let fragmentFunction = library.makeFunction(name: "fragment_main")


// ------------ 5. The pipeline state

// 1.创建pipelineDescriptor。 它包含了所有pipeline需要的信息
let pipelineDescriptor = MTLRenderPipelineDescriptor()

// 2. 颜色配置32位 bgra
pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

// 3. 设置shader function
pipelineDescriptor.vertexFunction = vertexFunction
pipelineDescriptor.fragmentFunction = fragmentFunction

// 4. 配置vertexDescriptor
pipelineDescriptor.vertexDescriptor = try MTKMetalVertexDescriptorFromModelIOWithError(mesh.vertexDescriptor)

// 5. 创建pipeline state。 此工作十分耗时, 在实际App中，我们会为不同的shading function创建不同的pipeline state，并且只创建一次
let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)


// --------------- 6. 渲染
// 1. 创建commandBuffer
guard let commandBuffer = commandQueue.makeCommandBuffer()
      else {
    fatalError()
}

// 2. 获取renderPassDescriptor,  renderPassDescriptor保存了需要渲染的数据. 我们一般使用renderPassDescriptor创建renderEncoder
guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
    fatalError()
}

// 3.创建renderEncoder。 renderEncoder拥有所有GPU所需要的数据
guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
    fatalError()
}

// 4.关联PipelineState
renderEncoder.setRenderPipelineState(pipelineState)

// 5. 我们之前创建的sphere mesh拥有顶点的信息,我们需要把这些信息提交给renderEncoder. The offset is the position in the buffer where the vertex information starts. The index is how the GPU vertex shader function will locate this buffer.
renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)


// 6. mesh由多个submesh组成。 假如我们渲染一个汽车，我们可能会有车身和轮胎两个部分组成。当前我们的球体只有一个submesh
guard let submesh = mesh.submeshes.first else {
    fatalError()
}

// 7. 告知GPU我们需要渲染信息
renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: 0)

// 8.endEncoding
renderEncoder.endEncoding()

// 9. 从MTKView中获取drawable对象。 其本质是CAMetalLayer。
guard let drawable = view.currentDrawable else {
    fatalError()
}

// 10. 显示,并且提交给GPU
commandBuffer.present(drawable)
commandBuffer.commit()


// 在swiftplayground中显示
PlaygroundPage.current.liveView = view
