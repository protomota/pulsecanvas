import Foundation
import Metal
import AppKit
struct Frame { var time: Float; var frame: UInt32; var style: UInt32; var pulse: Float }
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("experiments/metal-studies")
let device = MTLCreateSystemDefaultDevice()!, queue=device.makeCommandQueue()!
let library=try device.makeLibrary(source:String(contentsOf:root.appendingPathComponent("Creative.metal"),encoding:.utf8),options:nil)
let pipeline=try device.makeComputePipelineState(function:library.makeFunction(name:"creativeFrame")!)
let width=960,height=540
let descriptor=MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.rgba8Unorm,width:width,height:height,mipmapped:false)
descriptor.storageMode = .shared;descriptor.usage=[.shaderRead,.shaderWrite]
var previous=device.makeTexture(descriptor:descriptor)!,target=device.makeTexture(descriptor:descriptor)!
let blank=[UInt8](repeating:0,count:width*height*4)
func zero(_ t:MTLTexture) {blank.withUnsafeBytes {t.replace(region:MTLRegionMake2D(0,0,width,height),mipmapLevel:0,withBytes:$0.baseAddress!,bytesPerRow:width*4)}}
for style in 0..<2 {
 zero(previous);zero(target)
 let out=URL(fileURLWithPath:CommandLine.arguments.count>1 ? CommandLine.arguments[1] : ".build/metal-studies",isDirectory:true)
 try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
 let raw=out.appendingPathComponent("creative-\(style).rgba");FileManager.default.createFile(atPath:raw.path,contents:nil);let file=try FileHandle(forWritingTo:raw)
 var pixels=blank, middle=blank
 for index in 0..<240 {
  let t=Float(index)/60;var f=Frame(time:t,frame:UInt32(index),style:UInt32(style),pulse:pow(max(0,sin(t * .pi*4)),6))
  let command=queue.makeCommandBuffer()!,encoder=command.makeComputeCommandEncoder()!;encoder.setComputePipelineState(pipeline);encoder.setTexture(previous,index:0);encoder.setTexture(target,index:1);encoder.setBytes(&f,length:16,index:0)
  encoder.dispatchThreads(MTLSize(width:width,height:height,depth:1),threadsPerThreadgroup:MTLSize(width:16,height:16,depth:1));encoder.endEncoding();command.commit();command.waitUntilCompleted();precondition(command.status == .completed)
  pixels.withUnsafeMutableBytes {target.getBytes($0.baseAddress!,bytesPerRow:width*4,from:MTLRegionMake2D(0,0,width,height),mipmapLevel:0)}
  if index == 120 { middle = pixels }
  try file.write(contentsOf:Data(pixels));swap(&previous,&target)
 }
 try file.close()
 var rgbSum = 0.0, differenceSum = 0.0
 for pixel in stride(from: 0, to: pixels.count, by: 4) {
  for channel in 0..<3 {
   rgbSum += Double(pixels[pixel + channel])
   differenceSum += abs(Double(pixels[pixel + channel]) - Double(middle[pixel + channel]))
  }
 }
 let channelCount = Double(width * height * 3)
 let rgbMean = rgbSum / channelCount, movement = differenceSum / channelCount
 precondition(rgbMean > 2 && movement > 1)
 print("style \(style): mean RGB \(rgbMean), temporal difference \(movement)")
}
print("PASS: two creative Metal studies rendered at 960×540, 60 fps; all 480 GPU commands completed; last frames contain visible content; synthetic rhythm, no external assets or OpenGL")
