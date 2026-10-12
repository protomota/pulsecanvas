; ModuleID = 'work/shaders/shader_22.bc'
source_filename = "galaxyJourneyRadialBlurFragment"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%struct._texture_2d_t = type opaque
%struct._sampler_t = type opaque

; Function Attrs: convergent nounwind readonly
define <4 x float> @galaxyJourneyRadialBlurFragment(<4 x float> %0, <2 x float> %1, %struct._texture_2d_t addrspace(1)* %2, float addrspace(2)* nocapture readonly dereferenceable(4) "air-buffer-no-alias" %3, %struct._sampler_t addrspace(2)* nocapture readonly %4) local_unnamed_addr #0 {
  %6 = fadd fast <2 x float> %1, <float -5.000000e-01, float -5.000000e-01>
  %7 = load float, float addrspace(2)* %3, align 4, !tbaa !23, !alias.scope !27, !noalias !30
  %8 = insertelement <2 x float> undef, float %7, i64 0
  %9 = shufflevector <2 x float> %8, <2 x float> undef, <2 x i32> zeroinitializer
  %10 = fmul fast <2 x float> %9, %6
  br label %13

11:                                               ; preds = %13
  %12 = fmul fast <4 x float> %24, <float 0x3FB5555560000000, float 0x3FB5555560000000, float 0x3FB5555560000000, float 0x3FB5555560000000>
  ret <4 x float> %12

13:                                               ; preds = %13, %5
  %14 = phi <4 x float> [ zeroinitializer, %5 ], [ %24, %13 ]
  %15 = phi i32 [ 0, %5 ], [ %25, %13 ]
  %16 = tail call fast float @air.convert.f.f32.s.i32(i32 %15) #2
  %17 = fmul fast float %16, 0x3FB745D180000000
  %18 = insertelement <2 x float> undef, float %17, i64 0
  %19 = shufflevector <2 x float> %18, <2 x float> undef, <2 x i32> zeroinitializer
  %20 = fmul fast <2 x float> %10, %19
  %21 = fadd fast <2 x float> %20, %1
  %22 = tail call { <4 x float>, i8 } @air.sample_texture_2d.v4f32(%struct._texture_2d_t addrspace(1)* nocapture readonly %2, %struct._sampler_t addrspace(2)* nocapture readonly %4, <2 x float> %21, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #1, !alias.scope !30, !noalias !27
  %23 = extractvalue { <4 x float>, i8 } %22, 0
  %24 = fadd fast <4 x float> %23, %14
  %25 = add nuw nsw i32 %15, 1
  %26 = icmp eq i32 %25, 12
  br i1 %26, label %11, label %13, !llvm.loop !33
}

; Function Attrs: argmemonly convergent nounwind readonly
declare { <4 x float>, i8 } @air.sample_texture_2d.v4f32(%struct._texture_2d_t addrspace(1)* nocapture readonly, %struct._sampler_t addrspace(2)* nocapture readonly, <2 x float>, i1, <2 x i32>, i1, float, float, i32) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.convert.f.f32.s.i32(i32) local_unnamed_addr #2

attributes #0 = { convergent nounwind readonly "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="128" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { argmemonly convergent nounwind readonly }
attributes #2 = { nounwind readnone }

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
!14 = !{<4 x float> (<4 x float>, <2 x float>, %struct._texture_2d_t addrspace(1)*, float addrspace(2)*, %struct._sampler_t addrspace(2)*)* @galaxyJourneyRadialBlurFragment, !15, !17}
!15 = !{!16}
!16 = !{!"air.render_target", i32 0, i32 0, !"air.arg_type_name", !"float4"}
!17 = !{!18, !19, !20, !21, !22}
!18 = !{i32 0, !"air.position", !"air.center", !"air.no_perspective", !"air.arg_type_name", !"float4", !"air.arg_name", !"position", !"air.arg_unused"}
!19 = !{i32 1, !"air.fragment_input", !"generated(8texCoordDv2_f)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!20 = !{i32 2, !"air.texture", !"air.location_index", i32 0, i32 1, !"air.sample", !"air.arg_type_name", !"texture2d<float, sample>", !"air.arg_name", !"currentFrame"}
!21 = !{i32 3, !"air.buffer", !"air.buffer_size", i32 4, !"air.location_index", i32 0, i32 1, !"air.read", !"air.address_space", i32 2, !"air.arg_type_size", i32 4, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"float", !"air.arg_name", !"blurStrength"}
!22 = !{i32 4, !"air.sampler", !"air.location_index", i32 0, i32 1, !"air.arg_type_name", !"sampler", !"air.arg_name", !"textureSampler"}
!23 = !{!24, !24, i64 0}
!24 = !{!"float", !25, i64 0}
!25 = !{!"omnipotent char", !26, i64 0}
!26 = !{!"Simple C++ TBAA"}
!27 = !{!28}
!28 = distinct !{!28, !29, !"air-alias-scope-arg(3)"}
!29 = distinct !{!29, !"air-alias-scopes(galaxyJourneyRadialBlurFragment)"}
!30 = !{!31, !32}
!31 = distinct !{!31, !29, !"air-alias-scope-textures"}
!32 = distinct !{!32, !29, !"air-alias-scope-samplers"}
!33 = distinct !{!33, !34}
!34 = !{!"llvm.loop.mustprogress"}
