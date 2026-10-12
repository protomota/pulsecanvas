; ModuleID = 'work/shaders/shader_34.bc'
source_filename = "fractalMotionBlurFragment"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%struct._texture_2d_t = type opaque
%struct._sampler_t = type opaque

; Function Attrs: convergent nounwind readonly
define <4 x float> @fractalMotionBlurFragment(<4 x float> %0, <4 x float> %1, <2 x float> %2, float %3, float %4, float %5, %struct._texture_2d_t addrspace(1)* %6, %struct._texture_2d_t addrspace(1)* nocapture readnone %7, float addrspace(2)* nocapture readonly dereferenceable(4) "air-buffer-no-alias" %8, %struct._sampler_t addrspace(2)* nocapture readonly %9) local_unnamed_addr #0 {
  %11 = fadd fast <2 x float> %2, <float -5.000000e-01, float -5.000000e-01>
  %12 = load float, float addrspace(2)* %8, align 4, !tbaa !28, !alias.scope !32, !noalias !35
  %13 = insertelement <2 x float> undef, float %12, i64 0
  %14 = shufflevector <2 x float> %13, <2 x float> undef, <2 x i32> zeroinitializer
  %15 = fmul fast <2 x float> %14, %11
  br label %18

16:                                               ; preds = %18
  %17 = fmul fast <4 x float> %29, <float 0x3FB5555560000000, float 0x3FB5555560000000, float 0x3FB5555560000000, float 0x3FB5555560000000>
  ret <4 x float> %17

18:                                               ; preds = %18, %10
  %19 = phi <4 x float> [ zeroinitializer, %10 ], [ %29, %18 ]
  %20 = phi i32 [ 0, %10 ], [ %30, %18 ]
  %21 = tail call fast float @air.convert.f.f32.s.i32(i32 %20) #2
  %22 = fmul fast float %21, 0x3FB745D180000000
  %23 = insertelement <2 x float> undef, float %22, i64 0
  %24 = shufflevector <2 x float> %23, <2 x float> undef, <2 x i32> zeroinitializer
  %25 = fmul fast <2 x float> %15, %24
  %26 = fadd fast <2 x float> %25, %2
  %27 = tail call { <4 x float>, i8 } @air.sample_texture_2d.v4f32(%struct._texture_2d_t addrspace(1)* nocapture readonly %6, %struct._sampler_t addrspace(2)* nocapture readonly %9, <2 x float> %26, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #1, !alias.scope !35, !noalias !32
  %28 = extractvalue { <4 x float>, i8 } %27, 0
  %29 = fadd fast <4 x float> %28, %19
  %30 = add nuw nsw i32 %20, 1
  %31 = icmp eq i32 %30, 12
  br i1 %31, label %16, label %18, !llvm.loop !38
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
!14 = !{<4 x float> (<4 x float>, <4 x float>, <2 x float>, float, float, float, %struct._texture_2d_t addrspace(1)*, %struct._texture_2d_t addrspace(1)*, float addrspace(2)*, %struct._sampler_t addrspace(2)*)* @fractalMotionBlurFragment, !15, !17}
!15 = !{!16}
!16 = !{!"air.render_target", i32 0, i32 0, !"air.arg_type_name", !"float4"}
!17 = !{!18, !19, !20, !21, !22, !23, !24, !25, !26, !27}
!18 = !{i32 0, !"air.position", !"air.center", !"air.no_perspective", !"air.arg_type_name", !"float4", !"air.arg_name", !"position", !"air.arg_unused"}
!19 = !{i32 1, !"air.fragment_input", !"generated(5colorDv4_f)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float4", !"air.arg_name", !"color", !"air.arg_unused"}
!20 = !{i32 2, !"air.fragment_input", !"generated(8texCoordDv2_f)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!21 = !{i32 3, !"air.fragment_input", !"generated(9fogFactorf)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float", !"air.arg_name", !"fogFactor", !"air.arg_unused"}
!22 = !{i32 4, !"air.fragment_input", !"generated(5depthf)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float", !"air.arg_name", !"depth", !"air.arg_unused"}
!23 = !{i32 5, !"air.fragment_input", !"generated(5clipWf)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float", !"air.arg_name", !"clipW", !"air.arg_unused"}
!24 = !{i32 6, !"air.texture", !"air.location_index", i32 0, i32 1, !"air.sample", !"air.arg_type_name", !"texture2d<float, sample>", !"air.arg_name", !"currentFrame"}
!25 = !{i32 7, !"air.texture", !"air.location_index", i32 1, i32 1, !"air.sample", !"air.arg_type_name", !"texture2d<float, sample>", !"air.arg_name", !"previousFrame", !"air.arg_unused"}
!26 = !{i32 8, !"air.buffer", !"air.buffer_size", i32 4, !"air.location_index", i32 0, i32 1, !"air.read", !"air.address_space", i32 2, !"air.arg_type_size", i32 4, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"float", !"air.arg_name", !"blurStrength"}
!27 = !{i32 9, !"air.sampler", !"air.location_index", i32 0, i32 1, !"air.arg_type_name", !"sampler", !"air.arg_name", !"textureSampler"}
!28 = !{!29, !29, i64 0}
!29 = !{!"float", !30, i64 0}
!30 = !{!"omnipotent char", !31, i64 0}
!31 = !{!"Simple C++ TBAA"}
!32 = !{!33}
!33 = distinct !{!33, !34, !"air-alias-scope-arg(8)"}
!34 = distinct !{!34, !"air-alias-scopes(fractalMotionBlurFragment)"}
!35 = !{!36, !37}
!36 = distinct !{!36, !34, !"air-alias-scope-textures"}
!37 = distinct !{!37, !34, !"air-alias-scope-samplers"}
!38 = distinct !{!38, !39}
!39 = !{!"llvm.loop.mustprogress"}
