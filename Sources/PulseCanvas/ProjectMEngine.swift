import Foundation
import Darwin
import OpenGL
import OpenGL.GL3
import IOSurface
import CoreVideo
@preconcurrency import Metal

private final class ProjectMAPI {
    typealias Handle = UnsafeMutableRawPointer
    let library: UnsafeMutableRawPointer
    let create: @convention(c) () -> Handle?
    let destroy: @convention(c) (Handle) -> Void
    let load: @convention(c) (Handle, UnsafePointer<CChar>, Bool) -> Void
    let loadData: @convention(c) (Handle, UnsafePointer<CChar>, Bool) -> Void
    let size: @convention(c) (Handle, Int, Int) -> Void
    let frameTime: @convention(c) (Handle, Double) -> Void
    let fps: @convention(c) (Handle, Int32) -> Void
    let lock: @convention(c) (Handle, Bool) -> Void
    let clean: @convention(c) (Handle, Bool) -> Void
    let pcm: @convention(c) (Handle, UnsafePointer<Float>, UInt32, Int32) -> Void
    let render: @convention(c) (Handle, UInt32) -> Void
    let texturePaths: @convention(c) (Handle, UnsafePointer<UnsafePointer<CChar>?>, Int) -> Void
    typealias Failure = @convention(c) (UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Void
    let failure: @convention(c) (Handle, Failure?, UnsafeMutableRawPointer?) -> Void

    init() throws {
        let candidates = [Bundle.main.privateFrameworksURL?.appendingPathComponent("libprojectM.dylib"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".build/projectm/install/lib/libprojectM-4.4.2.0.dylib")]
        guard let path = candidates.compactMap({$0}).first(where: {FileManager.default.fileExists(atPath: $0.path)}),
              let library = dlopen(path.path, RTLD_NOW | RTLD_LOCAL) else { throw ProjectMError("ProjectM engine is missing. Build with scripts/build-projectm.sh.") }
        self.library = library
        func symbol<T>(_ name: String, _ type: T.Type) throws -> T {
            guard let address = dlsym(library, name) else { throw ProjectMError("ProjectM API is missing \(name)") }
            return unsafeBitCast(address, to: type)
        }
        create = try symbol("projectm_create", (@convention(c) () -> Handle?).self)
        destroy = try symbol("projectm_destroy", (@convention(c) (Handle) -> Void).self)
        load = try symbol("projectm_load_preset_file", (@convention(c) (Handle, UnsafePointer<CChar>, Bool) -> Void).self)
        loadData = try symbol("projectm_load_preset_data", (@convention(c) (Handle, UnsafePointer<CChar>, Bool) -> Void).self)
        size = try symbol("projectm_set_window_size", (@convention(c) (Handle, Int, Int) -> Void).self)
        frameTime = try symbol("projectm_set_frame_time", (@convention(c) (Handle, Double) -> Void).self)
        fps = try symbol("projectm_set_fps", (@convention(c) (Handle, Int32) -> Void).self)
        lock = try symbol("projectm_set_preset_locked", (@convention(c) (Handle, Bool) -> Void).self)
        clean = try symbol("projectm_set_preset_start_clean", (@convention(c) (Handle, Bool) -> Void).self)
        pcm = try symbol("projectm_pcm_add_float", (@convention(c) (Handle, UnsafePointer<Float>, UInt32, Int32) -> Void).self)
        render = try symbol("projectm_opengl_render_frame_fbo", (@convention(c) (Handle, UInt32) -> Void).self)
        texturePaths = try symbol("projectm_set_texture_search_paths", (@convention(c) (Handle, UnsafePointer<UnsafePointer<CChar>?>, Int) -> Void).self)
        failure = try symbol("projectm_set_preset_switch_failed_event_callback", (@convention(c) (Handle, Failure?, UnsafeMutableRawPointer?) -> Void).self)
    }
    // Retain the loaded library for process lifetime: upstream caches GL entry points.
}

/// A separate OpenGL context hosts the unmodified ProjectM engine. IOSurface
/// shares its frames with Metal; no glReadPixels or CPU image copies are used.
final class ProjectMEngine {
    private let api: ProjectMAPI
    private let context: CGLContextObj
    private var instance: ProjectMAPI.Handle?
    private var surface: IOSurfaceRef?
    private var metalTexture: MTLTexture?
    private var glTexture: GLuint = 0
    private var framebuffer: GLuint = 0
    private var activePath: String?
    private var previousTime: Double?
    private var previousSourceTime: Double?
    private var loadError: String?
    private var timeOrigin: Double = 0
    private var previousChaos: Float?

    init() throws {
        api = try ProjectMAPI()
        var format: CGLPixelFormatObj?, count: GLint = 0
        var attributes: [CGLPixelFormatAttribute] = [kCGLPFAOpenGLProfile, CGLPixelFormatAttribute(rawValue: UInt32(kCGLOGLPVersion_3_2_Core.rawValue)), kCGLPFAAccelerated, CGLPixelFormatAttribute(rawValue: 0)]
        guard CGLChoosePixelFormat(&attributes, &format, &count) == kCGLNoError, let format else { throw ProjectMError("OpenGL acceleration is unavailable") }
        defer { CGLDestroyPixelFormat(format) }
        var created: CGLContextObj?
        guard CGLCreateContext(format, nil, &created) == kCGLNoError, let created else { throw ProjectMError("Cannot create ProjectM graphics context") }
        context = created
    }
    deinit {
        let old = CGLGetCurrentContext(); CGLSetCurrentContext(context)
        if let instance { api.destroy(instance) }
        glDeleteFramebuffers(1, &framebuffer); glDeleteTextures(1, &glTexture)
        CGLSetCurrentContext(old); CGLDestroyContext(context)
    }

    func frame(preset: URL, texturePaths: [URL], device: MTLDevice, width: Int, height: Int,
               time: Double, sourceTime: Double, pcm: [Float], chaos: Float, fps: Int = 60) throws -> MTLTexture {
        let old = CGLGetCurrentContext(); CGLSetCurrentContext(context)
        defer { CGLSetCurrentContext(old) }
        // Presets own frame counters, feedback and audio filter history. A new
        // local clock must start with a new instance; rewinding a retained
        // instance makes its delta/progress negative and can corrupt beat values.
        let reset = instance == nil || activePath != preset.path || (previousTime.map {time < $0 - 0.001} ?? false) || (chaos == 0 && (previousChaos ?? 0) > 0)
        if reset {
            if let instance { api.destroy(instance) }
            instance = nil
            guard let created = api.create() else { throw ProjectMError("Cannot start ProjectM") }
            instance = created; activePath = nil
            api.failure(created, { _, message, user in
                guard let user else { return }
                let engine = Unmanaged<ProjectMEngine>.fromOpaque(user).takeUnretainedValue()
                engine.loadError = message.map {String(cString: $0)} ?? "Preset could not load"
            }, Unmanaged.passUnretained(self).toOpaque())
            api.frameTime(created, 0); api.fps(created, Int32(fps)); api.lock(created, true); api.clean(created, true)
        }
        if activePath != preset.path, let instance {
            timeOrigin = time; activePath = preset.path; loadError = nil; previousTime = nil; previousSourceTime = nil
            let strings = texturePaths.map {strdup($0.path)}
            defer { strings.forEach {free($0)} }
            let pointers = strings.map { $0.map {UnsafePointer<CChar>($0)} }
            pointers.withUnsafeBufferPointer { api.texturePaths(instance, $0.baseAddress!, $0.count) }
            api.size(instance, width, height)
            api.frameTime(instance, 0)
            preset.path.withCString {api.load(instance, $0, false)}
            if loadError != nil, let repaired = try MilkdropCompatibility.normalizedData(at: preset) {
                loadError = nil
                repaired.withCString {api.loadData(instance, $0, false)}
            }
        }
        if let loadError { throw ProjectMError("\(preset.lastPathComponent): \(loadError)") }
        guard let instance else { throw ProjectMError("ProjectM did not initialize") }
        let resized = metalTexture?.width != width || metalTexture?.height != height
        if resized {
            glDeleteFramebuffers(1, &framebuffer); glDeleteTextures(1, &glTexture)
            // Window drawable widths are arbitrary. Metal requires aligned row
            // strides even when the visible pixel width is not aligned.
            let rowBytes = IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, ((width * 4 + 255) / 256) * 256)
            let allocationSize = IOSurfaceAlignProperty(kIOSurfaceAllocSize, rowBytes * height)
            guard let surface = IOSurfaceCreate([kIOSurfaceWidth: width, kIOSurfaceHeight: height, kIOSurfaceBytesPerElement: 4, kIOSurfaceBytesPerRow: rowBytes, kIOSurfaceAllocSize: allocationSize, kIOSurfacePixelFormat: kCVPixelFormatType_32BGRA] as CFDictionary) else { throw ProjectMError("Cannot allocate ProjectM surface") }
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            descriptor.storageMode = .shared; descriptor.usage = [.shaderRead]
            guard let texture = device.makeTexture(descriptor: descriptor, iosurface: surface, plane: 0) else { throw ProjectMError("Cannot share ProjectM surface with Metal") }
            self.surface = surface; metalTexture = texture
            glGenTextures(1, &glTexture); glBindTexture(GLenum(GL_TEXTURE_RECTANGLE), glTexture)
            guard CGLTexImageIOSurface2D(context, GLenum(GL_TEXTURE_RECTANGLE), GLenum(GL_RGBA), GLsizei(width), GLsizei(height), GLenum(GL_BGRA), GLenum(GL_UNSIGNED_INT_8_8_8_8_REV), surface, 0) == kCGLNoError else { throw ProjectMError("Cannot share ProjectM surface with OpenGL") }
            glGenFramebuffers(1, &framebuffer); glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
            glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_RECTANGLE), glTexture, 0)
            guard glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) == GLenum(GL_FRAMEBUFFER_COMPLETE) else { throw ProjectMError("ProjectM framebuffer is incomplete") }
        }
        if !resized, previousTime == time, previousChaos == chaos, let metalTexture { return metalTexture }
        api.size(instance, width, height); api.fps(instance, Int32(fps))
        api.frameTime(instance, max(0, time - timeOrigin))
        if previousSourceTime != sourceTime || previousChaos != chaos {
            let samples = pcm.isEmpty ? [Float](repeating: 0, count: 1024) : pcm.map { min(1, max(-1, $0 * chaos)) }
            samples.withUnsafeBufferPointer {api.pcm(instance, $0.baseAddress!, UInt32($0.count / (pcm.isEmpty ? 1 : 2)), pcm.isEmpty ? 1 : 2)}
        }
        api.render(instance, framebuffer)
        // Complete OpenGL writes before the Metal compositor samples this IOSurface.
        glFinish()
        previousTime = time; previousSourceTime = sourceTime; previousChaos = chaos
        return metalTexture!
    }
}
struct ProjectMError: LocalizedError {
    let message: String
    init(_ message: String) {self.message = message}
    var errorDescription: String? {message}
}

/// Milkdrop packs sometimes wrap identifiers or numeric literals between numbered
/// EEL lines. Retrying a failed preset with joined equation chunks preserves the
/// expression; HLSL shaders and all successfully parsed presets remain untouched.
enum MilkdropCompatibility {
    static func normalizedData(at url: URL) throws -> String? {
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {return nil}
        let pattern = try NSRegularExpression(pattern: #"^(per_frame_init_|per_frame_|per_pixel_|wave_[0-9]+_(?:init|per_frame|per_point)|shape_[0-9]+_(?:init|per_frame))([0-9]+)$"#)
        let numericSuffix = try NSRegularExpression(pattern: #"([0-9]+(?:\.[0-9]*)?)[lL]\b"#)
        let assignment = try NSRegularExpression(pattern: #"^[A-Za-z_][A-Za-z_0-9]*\s*="#)
        var groups: [String: [(Int, String)]] = [:], untouched: [String] = []
        for line in text.components(separatedBy: .newlines) {
            guard let equals = line.firstIndex(of: "=") else {untouched.append(line); continue}
            let key = String(line[..<equals]).trimmingCharacters(in: .whitespaces)
            let range = NSRange(key.startIndex..., in: key)
            guard let match = pattern.firstMatch(in: key, range: range),
                  let prefixRange = Range(match.range(at: 1), in: key),
                  let indexRange = Range(match.range(at: 2), in: key), let index = Int(key[indexRange]) else {untouched.append(line); continue}
            let raw = String(line[line.index(after:equals)...])
            let code = String(raw.components(separatedBy: "//")[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            groups[String(key[prefixRange]), default: []].append((index, code))
        }
        guard !groups.isEmpty else {return nil}
        for prefix in groups.keys.sorted() {
            var combined = ""
            for (_, chunk) in groups[prefix]!.sorted(by: {$0.0 < $1.0}) where !chunk.isEmpty {
                // An assignment at a new chunk starts a statement unless it is
                // still inside parentheses. Other chunks continue the same token.
                if !combined.isEmpty && !combined.hasSuffix(";") && combined.filter({$0 == "("}).count == combined.filter({$0 == ")"}).count,
                   assignment.firstMatch(in:chunk,range:NSRange(chunk.startIndex...,in:chunk)) != nil {combined += ";"}
                combined += chunk
            }
            combined = numericSuffix.stringByReplacingMatches(in:combined,range:NSRange(combined.startIndex...,in:combined),withTemplate:"$1")
            if !combined.isEmpty && !combined.hasSuffix(";") {combined += ";"}
            untouched.append(prefix+"1="+combined)
        }
        return untouched.joined(separator:"\n")
    }
}

/// Retina window size must not silently turn an interactive preview into a 4K render.
/// The Metal compositor scales this surface; offline export keeps its full resolution.
enum ProjectMPreviewSize {
    static func dimensions(width: Int, height: Int) -> (width: Int, height: Int) {
        let scale = min(1, 1280 / Double(max(width, height)))
        return (max(1, Int((Double(width) * scale).rounded())), max(1, Int((Double(height) * scale).rounded())))
    }
}
