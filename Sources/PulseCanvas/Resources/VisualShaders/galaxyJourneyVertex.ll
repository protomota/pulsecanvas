; ModuleID = 'work/shaders/shader_18.bc'
source_filename = "galaxyJourneyVertex"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%struct.PointUniforms = type { %"struct.metal::matrix.9", float, float, <2 x float>, <4 x float> }
%"struct.metal::matrix.9" = type { [4 x <4 x float>] }

; Function Attrs: nounwind readnone
define <{ <4 x float>, float, <4 x float> }> @galaxyJourneyVertex(<3 x float> %0, %struct.PointUniforms addrspace(2)* nocapture readonly dereferenceable(96) "air-buffer-no-alias" %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %1, i64 0, i32 0, i32 0, i64 0
  %4 = load <4 x float>, <4 x float> addrspace(2)* %3, align 16, !tbaa !23, !alias.scope !26
  %5 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> zeroinitializer
  %6 = fmul fast <4 x float> %4, %5
  %7 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %1, i64 0, i32 0, i32 0, i64 1
  %8 = load <4 x float>, <4 x float> addrspace(2)* %7, align 16, !tbaa !23, !alias.scope !26
  %9 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %10 = fmul fast <4 x float> %8, %9
  %11 = fadd fast <4 x float> %10, %6
  %12 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %1, i64 0, i32 0, i32 0, i64 2
  %13 = load <4 x float>, <4 x float> addrspace(2)* %12, align 16, !tbaa !23, !alias.scope !26
  %14 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 2, i32 2, i32 2, i32 2>
  %15 = fmul fast <4 x float> %13, %14
  %16 = fadd fast <4 x float> %11, %15
  %17 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %1, i64 0, i32 0, i32 0, i64 3
  %18 = load <4 x float>, <4 x float> addrspace(2)* %17, align 16, !tbaa !23, !alias.scope !26
  %19 = fadd fast <4 x float> %16, %18
  %20 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %1, i64 0, i32 1
  %21 = load float, float addrspace(2)* %20, align 16, !tbaa !29, !alias.scope !26
  %22 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %1, i64 0, i32 2
  %23 = load float, float addrspace(2)* %22, align 4, !tbaa !33, !alias.scope !26
  %24 = fmul fast float %23, %21
  %25 = extractelement <4 x float> %19, i64 3
  %26 = tail call fast float @air.fast_fmax.f32(float %25, float 0x3F50624DE0000000) #1
  %27 = fdiv fast float %24, %26
  %28 = tail call fast float @air.fast_clamp.f32(float %27, float 1.000000e+00, float 6.400000e+01) #1
  %29 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %1, i64 0, i32 4
  %30 = load <4 x float>, <4 x float> addrspace(2)* %29, align 16, !tbaa !23, !alias.scope !26
  %31 = insertvalue <{ <4 x float>, float, <4 x float> }> undef, <4 x float> %19, 0
  %32 = insertvalue <{ <4 x float>, float, <4 x float> }> %31, float %28, 1
  %33 = insertvalue <{ <4 x float>, float, <4 x float> }> %32, <4 x float> %30, 2
  ret <{ <4 x float>, float, <4 x float> }> %33
}

; Function Attrs: nounwind readnone
declare float @air.fast_clamp.f32(float, float, float) local_unnamed_addr #1

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
!14 = !{<{ <4 x float>, float, <4 x float> }> (<3 x float>, %struct.PointUniforms addrspace(2)*)* @galaxyJourneyVertex, !15, !19}
!15 = !{!16, !17, !18}
!16 = !{!"air.position", !"air.arg_type_name", !"float4", !"air.arg_name", !"position"}
!17 = !{!"air.point_size", !"air.arg_type_name", !"float", !"air.arg_name", !"pointSize"}
!18 = !{!"air.vertex_output", !"generated(5colorDv4_f)", !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!19 = !{!20, !21}
!20 = !{i32 0, !"air.vertex_input", !"air.location_index", i32 0, i32 1, !"air.arg_type_name", !"float3", !"air.arg_name", !"position"}
!21 = !{i32 1, !"air.buffer", !"air.buffer_size", i32 96, !"air.location_index", i32 1, i32 1, !"air.read", !"air.address_space", i32 2, !"air.struct_type_info", !22, !"air.arg_type_size", i32 96, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"GalaxyJourneyUniforms", !"air.arg_name", !"uniforms"}
!22 = !{i32 0, i32 64, i32 0, !"float4x4", !"mvpMatrix", i32 64, i32 4, i32 0, !"float", !"pointSize", i32 68, i32 4, i32 0, !"float", !"heightOfNearPlane", i32 72, i32 8, i32 0, !"float2", !"_pad0", i32 80, i32 16, i32 0, !"float4", !"color"}
!23 = !{!24, !24, i64 0}
!24 = !{!"omnipotent char", !25, i64 0}
!25 = !{!"Simple C++ TBAA"}
!26 = !{!27}
!27 = distinct !{!27, !28, !"air-alias-scope-arg(1)"}
!28 = distinct !{!28, !"air-alias-scopes(galaxyJourneyVertex)"}
!29 = !{!30, !32, i64 64}
!30 = !{!"_ZTS21GalaxyJourneyUniforms", !31, i64 0, !32, i64 64, !32, i64 68, !24, i64 72, !24, i64 80}
!31 = !{!"_ZTSN5metal6matrixIfLi4ELi4EvEE", !24, i64 0}
!32 = !{!"float", !24, i64 0}
!33 = !{!30, !32, i64 68}
