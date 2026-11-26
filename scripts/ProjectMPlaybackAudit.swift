import Foundation
import Metal
struct AuditPreset: Codable {let id:String;let path:String;let title:String;let category:String}
struct Result: Codable {
 let id:String; let title:String; let path:String; let category:String
 var error:String?; var coverage:Double = 0; var whiteCoverage:Double = 0; var motion:Double = 0
 var medianMS:Double = 0; var p95MS:Double = 0
}
@main struct Audit {
 static func main() throws {
 let device = MTLCreateSystemDefaultDevice()!
 let root=URL(fileURLWithPath:"Sources/PulseCanvas/Resources/ProjectM")
 let presets=try JSONDecoder().decode([AuditPreset].self,from:Data(contentsOf:root.appendingPathComponent("catalog.json")))
 let output=URL(fileURLWithPath:CommandLine.arguments.count>1 ? CommandLine.arguments[1] : ".build/validation/projectm-playback-audit.json")
 let limit=CommandLine.arguments.count>2 ? Int(CommandLine.arguments[2])! : presets.count
 let part=CommandLine.arguments.count>3 ? Int(CommandLine.arguments[3])! : 0
 let partitions=CommandLine.arguments.count>4 ? Int(CommandLine.arguments[4])! : 1
 let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
 var results=(try? JSONDecoder().decode([Result].self,from:Data(contentsOf:output))) ?? []
 let checked=Set(results.map(\.id))
 let w=Int(ProcessInfo.processInfo.environment["AUDIT_WIDTH"] ?? "256")!,h=Int(ProcessInfo.processInfo.environment["AUDIT_HEIGHT"] ?? "144")!,frames=Int(ProcessInfo.processInfo.environment["AUDIT_FRAMES"] ?? "90")!
 let windows=(0..<frames).map { frame in (0..<1024).flatMap {sample -> [Float] in
 let t=Double(frame)/30 + Double(sample-1024)/44100
 let kick=exp(-max(0,t.truncatingRemainder(dividingBy:0.5))*28)
 let hat=exp(-max(0,t.truncatingRemainder(dividingBy:0.125))*90)
 let l=Float(0.48*sin(t*2*Double.pi*65)*kick+0.3*sin(t*2*Double.pi*7901)*hat+0.16*sin(t*2*Double.pi*340))
 let r=Float(0.42*sin(t*2*Double.pi*90)*kick+0.3*sin(t*2*Double.pi*11003)*hat+0.16*sin(t*2*Double.pi*510))
 return [l,r]
 }}
 let skipped=ProcessInfo.processInfo.environment["AUDIT_SKIP_IDS_FILE"].flatMap {try? JSONDecoder().decode([String].self,from:Data(contentsOf:URL(fileURLWithPath:$0)))}.map {Set($0)} ?? []
 let matching=ProcessInfo.processInfo.environment["AUDIT_MATCH"].map {Set($0.components(separatedBy:"|"))}
 let engine=try ProjectMEngine(); let start=Date()
 for (index,preset) in presets.prefix(limit).enumerated() where index % partitions == part && !checked.contains(preset.id) && (matching?.contains(preset.title) ?? true) {
 var result=Result(id:preset.id,title:preset.title,path:preset.path,category:preset.category)
 if skipped.contains(preset.id) { result.error="High-instance custom-shape family"; results.append(result); continue }
 var elapsed:[Double]=[], previous:[UInt8]?; var changes:[Double]=[], whites:[Double]=[]
 do {
 for frame in 0..<frames {
 let begin=Date()
 let texture=try engine.frame(preset:root.appendingPathComponent("Presets/"+preset.path),texturePaths:[root.appendingPathComponent("Presets/"+preset.path).deletingLastPathComponent(),root.appendingPathComponent("Textures")],device:device,width:w,height:h,time:Double(frame)/30,sourceTime:Double(frame)/30,pcm:windows[frame],chaos:1,fps:30)
 if frame>=1 {elapsed.append(Date().timeIntervalSince(begin)*1000)}
 if frame >= 5 && elapsed.sorted()[elapsed.count/2] > 33 { result.error="Slow playback at audit resolution"; break }
 if frame>=30 && frame % 10 == 0 {
 var pixels=[UInt8](repeating:0,count:w*h*4)
 texture.getBytes(&pixels,bytesPerRow:w*4,from:MTLRegionMake2D(0,0,w,h),mipmapLevel:0)
 var visible=0,white=0,difference=0
 for i in stride(from:0,to:pixels.count,by:4) {
 if max(pixels[i],pixels[i+1],pixels[i+2])>24 {visible+=1}
 if min(pixels[i],pixels[i+1],pixels[i+2])>245 {white+=1}
 if let previous {difference+=abs(Int(pixels[i])-Int(previous[i]))+abs(Int(pixels[i+1])-Int(previous[i+1]))+abs(Int(pixels[i+2])-Int(previous[i+2]))}
 }
 result.coverage=max(result.coverage,Double(visible)/Double(w*h))
 whites.append(Double(white)/Double(w*h))
 if previous != nil {changes.append(Double(difference)/Double(w*h*3*255))}
 previous=pixels
 }
 }
 elapsed.sort();result.medianMS=elapsed[elapsed.count/2];result.p95MS=elapsed[Int(Double(elapsed.count-1)*0.95)]
 result.motion=changes.max() ?? 0;result.whiteCoverage=whites.min() ?? 0
 } catch {result.error=error.localizedDescription}
 results.append(result)
 if results.count % 25 == 0 || results.count==limit {
 try encoder.encode(results).write(to:output,options:.atomic)
 let bad=results.filter{$0.error != nil || $0.coverage<0.01 || $0.motion<0.00005 || $0.whiteCoverage>0.98}.count
 print("Checked \(results.count)/\(limit), suspect \(bad), elapsed \(Int(Date().timeIntervalSince(start)))s");fflush(stdout)
 }
 }
 try encoder.encode(results).write(to:output,options:.atomic)
 }
}
