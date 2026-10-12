; ModuleID = 'work/shaders/shader_17.bc'
source_filename = "crystalMorphFragmentWithColorTint"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%struct._texture_2d_t = type opaque
%struct._sampler_t = type opaque

; Function Attrs: argmemonly convergent nounwind readonly
define <4 x float> @crystalMorphFragmentWithColorTint(<4 x float> %0, <4 x float> %1, <2 x float> %2, %struct._texture_2d_t addrspace(1)* nocapture readonly %3, %struct._texture_2d_t addrspace(1)* nocapture readonly %4, %struct._sampler_t addrspace(2)* nocapture readonly %5, float addrspace(2)* nocapture readonly dereferenceable(4) "air-buffer-no-alias" %6, float addrspace(2)* nocapture readonly dereferenceable(4) "air-buffer-no-alias" %7, <4 x float> addrspace(2)* nocapture readonly dereferenceable(16) "air-buffer-no-alias" %8) local_unnamed_addr #0 {
  %10 = tail call { <4 x float>, i8 } @air.sample_texture_2d.v4f32(%struct._texture_2d_t addrspace(1)* nocapture readonly %3, %struct._sampler_t addrspace(2)* nocapture readonly %5, <2 x float> %2, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #2, !alias.scope !27, !noalias !31
  %11 = extractvalue { <4 x float>, i8 } %10, 0
  %12 = tail call { <4 x float>, i8 } @air.sample_texture_2d.v4f32(%struct._texture_2d_t addrspace(1)* nocapture readonly %4, %struct._sampler_t addrspace(2)* nocapture readonly %5, <2 x float> %2, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #2, !alias.scope !27, !noalias !31
  %13 = extractvalue { <4 x float>, i8 } %12, 0
  %14 = load float, float addrspace(2)* %7, align 4, !tbaa !35, !alias.scope !39, !noalias !40
  %15 = insertelement <4 x float> undef, float %14, i64 0
  %16 = shufflevector <4 x float> %15, <4 x float> undef, <4 x i32> zeroinitializer
  %17 = tail call fast <4 x float> @air.mix.v4f32(<4 x float> %11, <4 x float> %13, <4 x float> %16) #1
  %18 = load <4 x float>, <4 x float> addrspace(2)* %8, align 16, !alias.scope !41, !noalias !42
  %19 = fmul fast <4 x float> %18, %17
  %20 = extractelement <4 x float> %17, i64 3
  %21 = extractelement <4 x float> %18, i64 3
  %22 = fmul fast float %21, %20
  %23 = insertelement <4 x float> %19, float %22, i64 3
  %24 = fmul fast <4 x float> %23, %1
  %25 = load float, float addrspace(2)* %6, align 4, !tbaa !35, !alias.scope !43, !noalias !44
  %26 = extractelement <4 x float> %24, i64 3
  %27 = fmul fast float %26, %25
  %28 = insertelement <4 x float> %24, float %27, i64 3
  ret <4 x float> %28
}

; Function Attrs: nounwind readnone
declare <4 x float> @air.mix.v4f32(<4 x float>, <4 x float>, <4 x float>) local_unnamed_addr #1

; Function Attrs: argmemonly convergent nounwind readonly
declare { <4 x float>, i8 } @air.sample_texture_2d.v4f32(%struct._texture_2d_t addrspace(1)* nocapture readonly, %struct._sampler_t addrspace(2)* nocapture readonly, <2 x float>, i1, <2 x i32>, i1, float, float, i32) local_unnamed_addr #2

attributes #0 = { argmemonly convergent nounwind readonly "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="128" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { nounwind readnone }
attributes #2 = { argmemonly convergent nounwind readonly }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}
!air.version = !{!9}
!air.language_version = !{!10}
!air.compile_options = !{!11, !12, !13}
!air.fragment = !{!14}

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
!14 = !{<4 x float> (<4 x float>, <4 x float>, <2 x float>, %struct._texture_2d_t addrspace(1)*, %struct._texture_2d_t addrspace(1)*, %struct._sampler_t addrspace(2)*, float addrspace(2)*, float addrspace(2)*, <4 x float> addrspace(2)*)* @crystalMorphFragmentWithColorTint, !15, !17}
!15 = !{!16}
!16 = !{!"air.render_target", i32 0, i32 0, !"air.arg_type_name", !"float4"}
!17 = !{!18, !19, !20, !21, !22, !23, !24, !25, !26}
!18 = !{i32 0, !"air.position", !"air.center", !"air.no_perspective", !"air.arg_type_name", !"float4", !"air.arg_name", !"position", !"air.arg_unused"}
!19 = !{i32 1, !"air.fragment_input", !"generated(5colorDv4_f)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!20 = !{i32 2, !"air.fragment_input", !"generated(8texCoordDv2_f)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!21 = !{i32 3, !"air.texture", !"air.location_index", i32 0, i32 1, !"air.sample", !"air.arg_type_name", !"texture2d<float, sample>", !"air.arg_name", !"texture1"}
!22 = !{i32 4, !"air.texture", !"air.location_index", i32 1, i32 1, !"air.sample", !"air.arg_type_name", !"texture2d<float, sample>", !"air.arg_name", !"texture2"}
!23 = !{i32 5, !"air.sampler", !"air.location_index", i32 0, i32 1, !"air.arg_type_name", !"sampler", !"air.arg_name", !"textureSampler"}
!24 = !{i32 6, !"air.buffer", !"air.buffer_size", i32 4, !"air.location_index", i32 2, i32 1, !"air.read", !"air.address_space", i32 2, !"air.arg_type_size", i32 4, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"float", !"air.arg_name", !"alpha"}
!25 = !{i32 7, !"air.buffer", !"air.buffer_size", i32 4, !"air.location_index", i32 3, i32 1, !"air.read", !"air.address_space", i32 2, !"air.arg_type_size", i32 4, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"float", !"air.arg_name", !"crossfadeAlpha"}
!26 = !{i32 8, !"air.buffer", !"air.buffer_size", i32 16, !"air.location_index", i32 4, i32 1, !"air.read", !"air.address_space", i32 2, !"air.arg_type_size", i32 16, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"float4", !"air.arg_name", !"colorTint"}
!27 = !{!28, !30}
!28 = distinct !{!28, !29, !"air-alias-scope-textures"}
!29 = distinct !{!29, !"air-alias-scopes(crystalMorphFragmentWithColorTint)"}
!30 = distinct !{!30, !29, !"air-alias-scope-samplers"}
!31 = !{!32, !33, !34}
!32 = distinct !{!32, !29, !"air-alias-scope-arg(6)"}
!33 = distinct !{!33, !29, !"air-alias-scope-arg(7)"}
!34 = distinct !{!34, !29, !"air-alias-scope-arg(8)"}
!35 = !{!36, !36, i64 0}
!36 = !{!"float", !37, i64 0}
!37 = !{!"omnipotent char", !38, i64 0}
!38 = !{!"Simple C++ TBAA"}
!39 = !{!33}
!40 = !{!28, !30, !32, !34}
!41 = !{!34}
!42 = !{!28, !30, !32, !33}
!43 = !{!32}
!44 = !{!28, !30, !33, !34}
