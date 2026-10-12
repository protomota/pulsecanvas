; ModuleID = 'work/shaders/shader_14.bc'
source_filename = "crystalMorphVertex"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%"struct.metal::matrix.9" = type { [4 x <4 x float>] }

; Function Attrs: norecurse nounwind readnone
define <{ <4 x float>, <4 x float>, <2 x float> }> @crystalMorphVertex(<3 x float> %0, <4 x float> %1, <2 x float> %2, %"struct.metal::matrix.9" addrspace(2)* nocapture readonly dereferenceable(64) "air-buffer-no-alias" %3) local_unnamed_addr #0 {
  %5 = getelementptr inbounds %"struct.metal::matrix.9", %"struct.metal::matrix.9" addrspace(2)* %3, i64 0, i32 0, i64 0
  %6 = load <4 x float>, <4 x float> addrspace(2)* %5, align 16, !tbaa !24, !alias.scope !27
  %7 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> zeroinitializer
  %8 = fmul fast <4 x float> %6, %7
  %9 = getelementptr inbounds %"struct.metal::matrix.9", %"struct.metal::matrix.9" addrspace(2)* %3, i64 0, i32 0, i64 1
  %10 = load <4 x float>, <4 x float> addrspace(2)* %9, align 16, !tbaa !24, !alias.scope !27
  %11 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %12 = fmul fast <4 x float> %10, %11
  %13 = fadd fast <4 x float> %12, %8
  %14 = getelementptr inbounds %"struct.metal::matrix.9", %"struct.metal::matrix.9" addrspace(2)* %3, i64 0, i32 0, i64 2
  %15 = load <4 x float>, <4 x float> addrspace(2)* %14, align 16, !tbaa !24, !alias.scope !27
  %16 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 2, i32 2, i32 2, i32 2>
  %17 = fmul fast <4 x float> %15, %16
  %18 = fadd fast <4 x float> %13, %17
  %19 = getelementptr inbounds %"struct.metal::matrix.9", %"struct.metal::matrix.9" addrspace(2)* %3, i64 0, i32 0, i64 3
  %20 = load <4 x float>, <4 x float> addrspace(2)* %19, align 16, !tbaa !24, !alias.scope !27
  %21 = fadd fast <4 x float> %18, %20
  %22 = insertvalue <{ <4 x float>, <4 x float>, <2 x float> }> undef, <4 x float> %21, 0
  %23 = insertvalue <{ <4 x float>, <4 x float>, <2 x float> }> %22, <4 x float> %1, 1
  %24 = insertvalue <{ <4 x float>, <4 x float>, <2 x float> }> %23, <2 x float> %2, 2
  ret <{ <4 x float>, <4 x float>, <2 x float> }> %24
}

attributes #0 = { norecurse nounwind readnone "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="128" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }

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
!14 = !{<{ <4 x float>, <4 x float>, <2 x float> }> (<3 x float>, <4 x float>, <2 x float>, %"struct.metal::matrix.9" addrspace(2)*)* @crystalMorphVertex, !15, !19}
!15 = !{!16, !17, !18}
!16 = !{!"air.position", !"air.arg_type_name", !"float4", !"air.arg_name", !"position"}
!17 = !{!"air.vertex_output", !"generated(5colorDv4_f)", !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!18 = !{!"air.vertex_output", !"generated(8texCoordDv2_f)", !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!19 = !{!20, !21, !22, !23}
!20 = !{i32 0, !"air.vertex_input", !"air.location_index", i32 0, i32 1, !"air.arg_type_name", !"float3", !"air.arg_name", !"position"}
!21 = !{i32 1, !"air.vertex_input", !"air.location_index", i32 1, i32 1, !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!22 = !{i32 2, !"air.vertex_input", !"air.location_index", i32 2, i32 1, !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!23 = !{i32 3, !"air.buffer", !"air.buffer_size", i32 64, !"air.location_index", i32 1, i32 1, !"air.read", !"air.address_space", i32 2, !"air.arg_type_size", i32 64, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"float4x4", !"air.arg_name", !"mvpMatrix"}
!24 = !{!25, !25, i64 0}
!25 = !{!"omnipotent char", !26, i64 0}
!26 = !{!"Simple C++ TBAA"}
!27 = !{!28}
!28 = distinct !{!28, !29, !"air-alias-scope-arg(3)"}
!29 = distinct !{!29, !"air-alias-scopes(crystalMorphVertex)"}
