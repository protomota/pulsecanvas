; ModuleID = 'work/shaders/shader_02.bc'
source_filename = "nebulaTunnelsFogFragment"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%struct._texture_2d_t = type opaque
%struct.NebulaTunnelsUniforms = type { %"struct.metal::matrix.9", float, float, float, float, <3 x float> }
%"struct.metal::matrix.9" = type { [4 x <4 x float>] }
%struct._sampler_t = type opaque

; Function Attrs: convergent nounwind readonly
define <4 x float> @nebulaTunnelsFogFragment(<4 x float> %0, <4 x float> %1, <2 x float> %2, float %3, float %4, float %5, %struct._texture_2d_t addrspace(1)* %6, %struct._texture_2d_t addrspace(1)* %7, %struct.NebulaTunnelsUniforms addrspace(2)* nocapture readonly dereferenceable(96) "air-buffer-no-alias" %8, %struct._sampler_t addrspace(2)* nocapture readonly %9) local_unnamed_addr #0 {
  %11 = getelementptr inbounds %struct.NebulaTunnelsUniforms, %struct.NebulaTunnelsUniforms addrspace(2)* %8, i64 0, i32 4
  %12 = load float, float addrspace(2)* %11, align 4, !tbaa !29, !alias.scope !35, !noalias !38
  %13 = tail call fast float @air.fast_fabs.f32(float %12) #1
  %14 = fcmp fast olt float %13, 0x3F1A36E2E0000000
  br i1 %14, label %30, label %15

15:                                               ; preds = %10
  %16 = fadd fast <2 x float> %2, <float -5.000000e-01, float -5.000000e-01>
  %17 = tail call fast float @air.fast_cos.f32(float %12) #1
  %18 = tail call fast float @air.fast_sin.f32(float %12) #1
  %19 = extractelement <2 x float> %16, i64 0
  %20 = fmul fast float %17, %19
  %21 = extractelement <2 x float> %16, i64 1
  %22 = fmul fast float %18, %21
  %23 = fsub fast float %20, %22
  %24 = insertelement <2 x float> undef, float %23, i64 0
  %25 = fmul fast float %18, %19
  %26 = fmul fast float %17, %21
  %27 = fadd fast float %25, %26
  %28 = insertelement <2 x float> %24, float %27, i64 1
  %29 = fadd fast <2 x float> %28, <float 5.000000e-01, float 5.000000e-01>
  br label %30

30:                                               ; preds = %15, %10
  %31 = phi <2 x float> [ %29, %15 ], [ %2, %10 ]
  %32 = tail call { <4 x float>, i8 } @air.sample_texture_2d.v4f32(%struct._texture_2d_t addrspace(1)* nocapture readonly %6, %struct._sampler_t addrspace(2)* nocapture readonly %9, <2 x float> %31, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #2, !alias.scope !38, !noalias !35
  %33 = extractvalue { <4 x float>, i8 } %32, 0
  %34 = tail call { <4 x float>, i8 } @air.sample_texture_2d.v4f32(%struct._texture_2d_t addrspace(1)* nocapture readonly %7, %struct._sampler_t addrspace(2)* nocapture readonly %9, <2 x float> %31, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #2, !alias.scope !38, !noalias !35
  %35 = extractvalue { <4 x float>, i8 } %34, 0
  %36 = getelementptr inbounds %struct.NebulaTunnelsUniforms, %struct.NebulaTunnelsUniforms addrspace(2)* %8, i64 0, i32 2
  %37 = load float, float addrspace(2)* %36, align 4, !tbaa !41, !alias.scope !35, !noalias !38
  %38 = insertelement <4 x float> undef, float %37, i64 0
  %39 = shufflevector <4 x float> %38, <4 x float> undef, <4 x i32> zeroinitializer
  %40 = tail call fast <4 x float> @air.mix.v4f32(<4 x float> %33, <4 x float> %35, <4 x float> %39) #1
  %41 = fmul fast <4 x float> %40, %1
  %42 = shufflevector <4 x float> %41, <4 x float> undef, <3 x i32> <i32 0, i32 1, i32 2>
  %43 = getelementptr inbounds %struct.NebulaTunnelsUniforms, %struct.NebulaTunnelsUniforms addrspace(2)* %8, i64 0, i32 1
  %44 = load float, float addrspace(2)* %43, align 16, !tbaa !42, !alias.scope !35, !noalias !38
  %45 = fcmp fast olt float %44, 0x3F50624DE0000000
  br i1 %45, label %59, label %46

46:                                               ; preds = %30
  %47 = fmul fast float %4, 2.000000e+00
  %48 = fmul fast float %47, %5
  %49 = fmul fast float %48, %44
  %50 = fmul fast float %49, %49
  %51 = fmul fast float %50, 0xBFF7154760000000
  %52 = tail call fast float @air.fast_exp2.f32(float %51) #1
  %53 = tail call fast float @air.fast_clamp.f32(float %52, float 0.000000e+00, float 1.000000e+00) #1
  %54 = getelementptr inbounds %struct.NebulaTunnelsUniforms, %struct.NebulaTunnelsUniforms addrspace(2)* %8, i64 0, i32 5
  %55 = load <3 x float>, <3 x float> addrspace(2)* %54, align 16, !tbaa !43, !alias.scope !35, !noalias !38
  %56 = insertelement <3 x float> undef, float %53, i64 0
  %57 = shufflevector <3 x float> %56, <3 x float> undef, <3 x i32> zeroinitializer
  %58 = tail call fast <3 x float> @air.mix.v3f32(<3 x float> %55, <3 x float> %42, <3 x float> %57) #1
  br label %59

59:                                               ; preds = %46, %30
  %60 = phi <3 x float> [ %58, %46 ], [ %42, %30 ]
  %61 = extractelement <4 x float> %40, i64 3
  %62 = getelementptr inbounds %struct.NebulaTunnelsUniforms, %struct.NebulaTunnelsUniforms addrspace(2)* %8, i64 0, i32 3
  %63 = load float, float addrspace(2)* %62, align 8, !tbaa !44, !alias.scope !35, !noalias !38
  %64 = fmul fast float %63, %61
  %65 = shufflevector <3 x float> %60, <3 x float> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 undef>
  %66 = insertelement <4 x float> %65, float %64, i64 3
  ret <4 x float> %66
}

; Function Attrs: nounwind readnone
declare <3 x float> @air.mix.v3f32(<3 x float>, <3 x float>, <3 x float>) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.fast_clamp.f32(float, float, float) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.fast_exp2.f32(float) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare <4 x float> @air.mix.v4f32(<4 x float>, <4 x float>, <4 x float>) local_unnamed_addr #1

; Function Attrs: argmemonly convergent nounwind readonly
declare { <4 x float>, i8 } @air.sample_texture_2d.v4f32(%struct._texture_2d_t addrspace(1)* nocapture readonly, %struct._sampler_t addrspace(2)* nocapture readonly, <2 x float>, i1, <2 x i32>, i1, float, float, i32) local_unnamed_addr #2

; Function Attrs: nounwind readnone
declare float @air.fast_sin.f32(float) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.fast_cos.f32(float) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.fast_fabs.f32(float) local_unnamed_addr #1

attributes #0 = { convergent nounwind readonly "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="128" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
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
!14 = !{<4 x float> (<4 x float>, <4 x float>, <2 x float>, float, float, float, %struct._texture_2d_t addrspace(1)*, %struct._texture_2d_t addrspace(1)*, %struct.NebulaTunnelsUniforms addrspace(2)*, %struct._sampler_t addrspace(2)*)* @nebulaTunnelsFogFragment, !15, !17}
!15 = !{!16}
!16 = !{!"air.render_target", i32 0, i32 0, !"air.arg_type_name", !"float4"}
!17 = !{!18, !19, !20, !21, !22, !23, !24, !25, !26, !28}
!18 = !{i32 0, !"air.position", !"air.center", !"air.no_perspective", !"air.arg_type_name", !"float4", !"air.arg_name", !"position", !"air.arg_unused"}
!19 = !{i32 1, !"air.fragment_input", !"generated(5colorDv4_f)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!20 = !{i32 2, !"air.fragment_input", !"generated(8texCoordDv2_f)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!21 = !{i32 3, !"air.fragment_input", !"generated(9fogFactorf)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float", !"air.arg_name", !"fogFactor", !"air.arg_unused"}
!22 = !{i32 4, !"air.fragment_input", !"generated(5depthf)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float", !"air.arg_name", !"depth"}
!23 = !{i32 5, !"air.fragment_input", !"generated(5clipWf)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float", !"air.arg_name", !"clipW"}
!24 = !{i32 6, !"air.texture", !"air.location_index", i32 0, i32 1, !"air.sample", !"air.arg_type_name", !"texture2d<float, sample>", !"air.arg_name", !"texture1"}
!25 = !{i32 7, !"air.texture", !"air.location_index", i32 1, i32 1, !"air.sample", !"air.arg_type_name", !"texture2d<float, sample>", !"air.arg_name", !"texture2"}
!26 = !{i32 8, !"air.buffer", !"air.buffer_size", i32 96, !"air.location_index", i32 0, i32 1, !"air.read", !"air.address_space", i32 2, !"air.struct_type_info", !27, !"air.arg_type_size", i32 96, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"NebulaTunnelsUniforms", !"air.arg_name", !"uniforms"}
!27 = !{i32 0, i32 64, i32 0, !"float4x4", !"mvpMatrix", i32 64, i32 4, i32 0, !"float", !"fogDensity", i32 68, i32 4, i32 0, !"float", !"crossfadeBlend", i32 72, i32 4, i32 0, !"float", !"alpha", i32 76, i32 4, i32 0, !"float", !"textureRotation", i32 80, i32 16, i32 0, !"float3", !"fogColor"}
!28 = !{i32 9, !"air.sampler", !"air.location_index", i32 0, i32 1, !"air.arg_type_name", !"sampler", !"air.arg_name", !"textureSampler"}
!29 = !{!30, !34, i64 76}
!30 = !{!"_ZTS21NebulaTunnelsUniforms", !31, i64 0, !34, i64 64, !34, i64 68, !34, i64 72, !34, i64 76, !32, i64 80}
!31 = !{!"_ZTSN5metal6matrixIfLi4ELi4EvEE", !32, i64 0}
!32 = !{!"omnipotent char", !33, i64 0}
!33 = !{!"Simple C++ TBAA"}
!34 = !{!"float", !32, i64 0}
!35 = !{!36}
!36 = distinct !{!36, !37, !"air-alias-scope-arg(8)"}
!37 = distinct !{!37, !"air-alias-scopes(nebulaTunnelsFogFragment)"}
!38 = !{!39, !40}
!39 = distinct !{!39, !37, !"air-alias-scope-textures"}
!40 = distinct !{!40, !37, !"air-alias-scope-samplers"}
!41 = !{!30, !34, i64 68}
!42 = !{!30, !34, i64 64}
!43 = !{!32, !32, i64 0}
!44 = !{!30, !34, i64 72}
