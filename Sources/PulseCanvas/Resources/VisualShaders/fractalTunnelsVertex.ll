; ModuleID = 'work/shaders/shader_29.bc'
source_filename = "fractalTunnelsVertex"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%struct.FractalTunnelsUniforms = type <{ %"struct.metal::matrix.9", float, float, float, [4 x i8], <3 x float>, float, [12 x i8] }>
%"struct.metal::matrix.9" = type { [4 x <4 x float>] }

; Function Attrs: nounwind readnone
define <{ <4 x float>, <4 x float>, <2 x float>, float, float, float }> @fractalTunnelsVertex(<3 x float> %0, <4 x float> %1, <2 x float> %2, %struct.FractalTunnelsUniforms addrspace(2)* nocapture readonly align 16 dereferenceable(100) "air-buffer-no-alias" %3) local_unnamed_addr #0 {
  %5 = getelementptr inbounds %struct.FractalTunnelsUniforms, %struct.FractalTunnelsUniforms addrspace(2)* %3, i64 0, i32 0, i32 0, i64 0
  %6 = load <4 x float>, <4 x float> addrspace(2)* %5, align 16, !tbaa !28, !alias.scope !31
  %7 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> zeroinitializer
  %8 = fmul fast <4 x float> %6, %7
  %9 = getelementptr inbounds %struct.FractalTunnelsUniforms, %struct.FractalTunnelsUniforms addrspace(2)* %3, i64 0, i32 0, i32 0, i64 1
  %10 = load <4 x float>, <4 x float> addrspace(2)* %9, align 16, !tbaa !28, !alias.scope !31
  %11 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %12 = fmul fast <4 x float> %10, %11
  %13 = fadd fast <4 x float> %12, %8
  %14 = getelementptr inbounds %struct.FractalTunnelsUniforms, %struct.FractalTunnelsUniforms addrspace(2)* %3, i64 0, i32 0, i32 0, i64 2
  %15 = load <4 x float>, <4 x float> addrspace(2)* %14, align 16, !tbaa !28, !alias.scope !31
  %16 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 2, i32 2, i32 2, i32 2>
  %17 = fmul fast <4 x float> %15, %16
  %18 = fadd fast <4 x float> %13, %17
  %19 = getelementptr inbounds %struct.FractalTunnelsUniforms, %struct.FractalTunnelsUniforms addrspace(2)* %3, i64 0, i32 0, i32 0, i64 3
  %20 = load <4 x float>, <4 x float> addrspace(2)* %19, align 16, !tbaa !28, !alias.scope !31
  %21 = fadd fast <4 x float> %18, %20
  %22 = extractelement <4 x float> %21, i64 3
  %23 = extractelement <4 x float> %21, i64 2
  %24 = tail call fast float @air.fast_fmax.f32(float %22, float 0x3F50624DE0000000) #1
  %25 = fdiv fast float %23, %24
  %26 = insertvalue <{ <4 x float>, <4 x float>, <2 x float>, float, float, float }> undef, <4 x float> %21, 0
  %27 = insertvalue <{ <4 x float>, <4 x float>, <2 x float>, float, float, float }> %26, <4 x float> %1, 1
  %28 = insertvalue <{ <4 x float>, <4 x float>, <2 x float>, float, float, float }> %27, <2 x float> %2, 2
  %29 = insertvalue <{ <4 x float>, <4 x float>, <2 x float>, float, float, float }> %28, float 1.000000e+00, 3
  %30 = insertvalue <{ <4 x float>, <4 x float>, <2 x float>, float, float, float }> %29, float %25, 4
  %31 = insertvalue <{ <4 x float>, <4 x float>, <2 x float>, float, float, float }> %30, float %22, 5
  ret <{ <4 x float>, <4 x float>, <2 x float>, float, float, float }> %31
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
!14 = !{<{ <4 x float>, <4 x float>, <2 x float>, float, float, float }> (<3 x float>, <4 x float>, <2 x float>, %struct.FractalTunnelsUniforms addrspace(2)*)* @fractalTunnelsVertex, !15, !22}
!15 = !{!16, !17, !18, !19, !20, !21}
!16 = !{!"air.position", !"air.arg_type_name", !"float4", !"air.arg_name", !"position"}
!17 = !{!"air.vertex_output", !"generated(5colorDv4_f)", !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!18 = !{!"air.vertex_output", !"generated(8texCoordDv2_f)", !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!19 = !{!"air.vertex_output", !"generated(9fogFactorf)", !"air.arg_type_name", !"float", !"air.arg_name", !"fogFactor"}
!20 = !{!"air.vertex_output", !"generated(5depthf)", !"air.arg_type_name", !"float", !"air.arg_name", !"depth"}
!21 = !{!"air.vertex_output", !"generated(5clipWf)", !"air.arg_type_name", !"float", !"air.arg_name", !"clipW"}
!22 = !{!23, !24, !25, !26}
!23 = !{i32 0, !"air.vertex_input", !"air.location_index", i32 0, i32 1, !"air.arg_type_name", !"float3", !"air.arg_name", !"position"}
!24 = !{i32 1, !"air.vertex_input", !"air.location_index", i32 1, i32 1, !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!25 = !{i32 2, !"air.vertex_input", !"air.location_index", i32 2, i32 1, !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!26 = !{i32 3, !"air.buffer", !"air.buffer_size", i32 112, !"air.location_index", i32 1, i32 1, !"air.read", !"air.address_space", i32 2, !"air.struct_type_info", !27, !"air.arg_type_size", i32 112, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"FractalTunnelsUniforms", !"air.arg_name", !"uniforms"}
!27 = !{i32 0, i32 64, i32 0, !"float4x4", !"mvpMatrix", i32 64, i32 4, i32 0, !"float", !"fogDensity", i32 68, i32 4, i32 0, !"float", !"crossfadeBlend", i32 72, i32 4, i32 0, !"float", !"alpha", i32 80, i32 16, i32 0, !"float3", !"fogColor", i32 96, i32 4, i32 0, !"float", !"textureRotation"}
!28 = !{!29, !29, i64 0}
!29 = !{!"omnipotent char", !30, i64 0}
!30 = !{!"Simple C++ TBAA"}
!31 = !{!32}
!32 = distinct !{!32, !33, !"air-alias-scope-arg(3)"}
!33 = distinct !{!33, !"air-alias-scopes(fractalTunnelsVertex)"}
