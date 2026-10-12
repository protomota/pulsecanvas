; ModuleID = 'work/shaders/shader_06.bc'
source_filename = "viz_tunnel_vertex"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%struct.VisualizationUniforms = type <{ %"struct.metal::matrix.9", %"struct.metal::matrix.9", %"struct.metal::matrix.9", float, i32, float, float, <3 x float>, float, [12 x i8] }>
%"struct.metal::matrix.9" = type { [4 x <4 x float>] }

; Function Attrs: nounwind readnone
define <{ <4 x float>, <4 x float>, float, float }> @viz_tunnel_vertex(<3 x float> %0, <4 x float> %1, %struct.VisualizationUniforms addrspace(2)* nocapture readonly align 16 dereferenceable(228) "air-buffer-no-alias" %2) local_unnamed_addr #0 {
  %4 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 0, i32 0, i64 0
  %5 = load <4 x float>, <4 x float> addrspace(2)* %4, align 16, !tbaa !25, !alias.scope !28
  %6 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> zeroinitializer
  %7 = fmul fast <4 x float> %5, %6
  %8 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 0, i32 0, i64 1
  %9 = load <4 x float>, <4 x float> addrspace(2)* %8, align 16, !tbaa !25, !alias.scope !28
  %10 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %11 = fmul fast <4 x float> %9, %10
  %12 = fadd fast <4 x float> %11, %7
  %13 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 0, i32 0, i64 2
  %14 = load <4 x float>, <4 x float> addrspace(2)* %13, align 16, !tbaa !25, !alias.scope !28
  %15 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 2, i32 2, i32 2, i32 2>
  %16 = fmul fast <4 x float> %14, %15
  %17 = fadd fast <4 x float> %12, %16
  %18 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 0, i32 0, i64 3
  %19 = load <4 x float>, <4 x float> addrspace(2)* %18, align 16, !tbaa !25, !alias.scope !28
  %20 = fadd fast <4 x float> %17, %19
  %21 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 1, i32 0, i64 0
  %22 = load <4 x float>, <4 x float> addrspace(2)* %21, align 16, !tbaa !25, !alias.scope !28
  %23 = shufflevector <4 x float> %20, <4 x float> undef, <4 x i32> zeroinitializer
  %24 = fmul fast <4 x float> %23, %22
  %25 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 1, i32 0, i64 1
  %26 = load <4 x float>, <4 x float> addrspace(2)* %25, align 16, !tbaa !25, !alias.scope !28
  %27 = shufflevector <4 x float> %20, <4 x float> undef, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %28 = fmul fast <4 x float> %27, %26
  %29 = fadd fast <4 x float> %24, %28
  %30 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 1, i32 0, i64 2
  %31 = load <4 x float>, <4 x float> addrspace(2)* %30, align 16, !tbaa !25, !alias.scope !28
  %32 = shufflevector <4 x float> %20, <4 x float> undef, <4 x i32> <i32 2, i32 2, i32 2, i32 2>
  %33 = fmul fast <4 x float> %31, %32
  %34 = fadd fast <4 x float> %29, %33
  %35 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 1, i32 0, i64 3
  %36 = load <4 x float>, <4 x float> addrspace(2)* %35, align 16, !tbaa !25, !alias.scope !28
  %37 = shufflevector <4 x float> %20, <4 x float> undef, <4 x i32> <i32 3, i32 3, i32 3, i32 3>
  %38 = fmul fast <4 x float> %36, %37
  %39 = fadd fast <4 x float> %34, %38
  %40 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 2, i32 0, i64 0
  %41 = load <4 x float>, <4 x float> addrspace(2)* %40, align 16, !tbaa !25, !alias.scope !28
  %42 = shufflevector <4 x float> %39, <4 x float> undef, <4 x i32> zeroinitializer
  %43 = fmul fast <4 x float> %42, %41
  %44 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 2, i32 0, i64 1
  %45 = load <4 x float>, <4 x float> addrspace(2)* %44, align 16, !tbaa !25, !alias.scope !28
  %46 = shufflevector <4 x float> %39, <4 x float> undef, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %47 = fmul fast <4 x float> %46, %45
  %48 = fadd fast <4 x float> %43, %47
  %49 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 2, i32 0, i64 2
  %50 = load <4 x float>, <4 x float> addrspace(2)* %49, align 16, !tbaa !25, !alias.scope !28
  %51 = shufflevector <4 x float> %39, <4 x float> undef, <4 x i32> <i32 2, i32 2, i32 2, i32 2>
  %52 = fmul fast <4 x float> %51, %50
  %53 = fadd fast <4 x float> %48, %52
  %54 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %2, i64 0, i32 2, i32 0, i64 3
  %55 = load <4 x float>, <4 x float> addrspace(2)* %54, align 16, !tbaa !25, !alias.scope !28
  %56 = shufflevector <4 x float> %39, <4 x float> undef, <4 x i32> <i32 3, i32 3, i32 3, i32 3>
  %57 = fmul fast <4 x float> %55, %56
  %58 = fadd fast <4 x float> %53, %57
  %59 = extractelement <4 x float> %58, i64 3
  %60 = extractelement <4 x float> %58, i64 2
  %61 = tail call fast float @air.fast_fmax.f32(float %59, float 0x3F50624DE0000000) #1
  %62 = fdiv fast float %60, %61
  %63 = insertvalue <{ <4 x float>, <4 x float>, float, float }> undef, <4 x float> %58, 0
  %64 = insertvalue <{ <4 x float>, <4 x float>, float, float }> %63, <4 x float> %1, 1
  %65 = insertvalue <{ <4 x float>, <4 x float>, float, float }> %64, float %62, 2
  %66 = insertvalue <{ <4 x float>, <4 x float>, float, float }> %65, float %59, 3
  ret <{ <4 x float>, <4 x float>, float, float }> %66
}

; Function Attrs: nounwind readnone
declare float @air.fast_fmax.f32(float, float) local_unnamed_addr #1

attributes #0 = { nounwind readnone "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="128" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { nounwind readnone }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}
!air.version = !{!9}
!air.language_version = !{!10}
!air.compile_options = !{!11, !12, !13}
!air.vertex = !{!14}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"air.max_device_buffers", i32 31}
!3 = !{i32 7, !"air.max_constant_buffers", i32 31}
!4 = !{i32 7, !"air.max_threadgroup_buffers", i32 31}
!5 = !{i32 7, !"air.max_textures", i32 128}
!6 = !{i32 7, !"air.max_read_write_textures", i32 8}
!7 = !{i32 7, !"air.max_samplers", i32 16}
!8 = !{!"Apple metal version 32023.864 (metalfe-32023.864)"}
!9 = !{i32 2, i32 5, i32 0}
!10 = !{!"Metal", i32 3, i32 0, i32 0}
!11 = !{!"air.compile.denorms_disable"}
!12 = !{!"air.compile.fast_math_enable"}
!13 = !{!"air.compile.framebuffer_fetch_enable"}
!14 = !{<{ <4 x float>, <4 x float>, float, float }> (<3 x float>, <4 x float>, %struct.VisualizationUniforms addrspace(2)*)* @viz_tunnel_vertex, !15, !20}
!15 = !{!16, !17, !18, !19}
!16 = !{!"air.position", !"air.arg_type_name", !"float4", !"air.arg_name", !"position"}
!17 = !{!"air.vertex_output", !"generated(5colorDv4_f)", !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!18 = !{!"air.vertex_output", !"generated(5depthf)", !"air.arg_type_name", !"float", !"air.arg_name", !"depth"}
!19 = !{!"air.vertex_output", !"generated(5clipWf)", !"air.arg_type_name", !"float", !"air.arg_name", !"clipW"}
!20 = !{!21, !22, !23}
!21 = !{i32 0, !"air.vertex_input", !"air.location_index", i32 0, i32 1, !"air.arg_type_name", !"float3", !"air.arg_name", !"position"}
!22 = !{i32 1, !"air.vertex_input", !"air.location_index", i32 1, i32 1, !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!23 = !{i32 2, !"air.buffer", !"air.buffer_size", i32 240, !"air.location_index", i32 1, i32 1, !"air.read", !"air.address_space", i32 2, !"air.struct_type_info", !24, !"air.arg_type_size", i32 240, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"VisualizationUniforms", !"air.arg_name", !"uniforms"}
!24 = !{i32 0, i32 64, i32 0, !"float4x4", !"model", i32 64, i32 64, i32 0, !"float4x4", !"view", i32 128, i32 64, i32 0, !"float4x4", !"projection", i32 192, i32 4, i32 0, !"float", !"time", i32 196, i32 4, i32 0, !"int", !"quality", i32 200, i32 4, i32 0, !"float", !"fogDensity", i32 204, i32 4, i32 0, !"float", !"padding", i32 208, i32 16, i32 0, !"float3", !"fogColor", i32 224, i32 4, i32 0, !"float", !"padding2"}
!25 = !{!26, !26, i64 0}
!26 = !{!"omnipotent char", !27, i64 0}
!27 = !{!"Simple C++ TBAA"}
!28 = !{!29}
!29 = distinct !{!29, !30, !"air-alias-scope-arg(2)"}
!30 = distinct !{!30, !"air-alias-scopes(viz_tunnel_vertex)"}
