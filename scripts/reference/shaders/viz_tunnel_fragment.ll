; ModuleID = 'work/shaders/shader_07.bc'
source_filename = "viz_tunnel_fragment"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%struct.VisualizationUniforms = type <{ %"struct.metal::matrix.9", %"struct.metal::matrix.9", %"struct.metal::matrix.9", float, i32, float, float, <3 x float>, float, [12 x i8] }>
%"struct.metal::matrix.9" = type { [4 x <4 x float>] }

; Function Attrs: nounwind readnone
define <4 x float> @viz_tunnel_fragment(<4 x float> %0, <4 x float> %1, float %2, float %3, %struct.VisualizationUniforms addrspace(2)* nocapture readonly align 16 dereferenceable(228) "air-buffer-no-alias" %4) local_unnamed_addr #0 {
  %6 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %4, i64 0, i32 5
  %7 = load float, float addrspace(2)* %6, align 8, !tbaa !24, !alias.scope !31
  %8 = fcmp fast olt float %7, 0x3F1A36E2E0000000
  br i1 %8, label %9, label %11

9:                                                ; preds = %5
  %10 = insertelement <4 x float> %1, float 1.000000e+00, i64 3
  br label %27

11:                                               ; preds = %5
  %12 = fmul fast float %3, %2
  %13 = tail call fast float @air.fast_fmin.f32(float %12, float 4.000000e+02) #1
  %14 = fmul fast float %13, %7
  %15 = fmul fast float %14, %14
  %16 = fmul fast float %15, 0xBFF7154760000000
  %17 = tail call fast float @air.fast_exp2.f32(float %16) #1
  %18 = tail call fast float @air.fast_clamp.f32(float %17, float 0.000000e+00, float 1.000000e+00) #1
  %19 = getelementptr inbounds %struct.VisualizationUniforms, %struct.VisualizationUniforms addrspace(2)* %4, i64 0, i32 7
  %20 = load <3 x float>, <3 x float> addrspace(2)* %19, align 16, !tbaa !34, !alias.scope !31
  %21 = shufflevector <4 x float> %1, <4 x float> undef, <3 x i32> <i32 0, i32 1, i32 2>
  %22 = insertelement <3 x float> undef, float %18, i64 0
  %23 = shufflevector <3 x float> %22, <3 x float> undef, <3 x i32> zeroinitializer
  %24 = tail call fast <3 x float> @air.mix.v3f32(<3 x float> %20, <3 x float> %21, <3 x float> %23) #1
  %25 = shufflevector <3 x float> %24, <3 x float> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 undef>
  %26 = insertelement <4 x float> %25, float 1.000000e+00, i64 3
  br label %27

27:                                               ; preds = %11, %9
  %28 = phi <4 x float> [ %10, %9 ], [ %26, %11 ]
  ret <4 x float> %28
}

; Function Attrs: nounwind readnone
declare <3 x float> @air.mix.v3f32(<3 x float>, <3 x float>, <3 x float>) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.fast_clamp.f32(float, float, float) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.fast_exp2.f32(float) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.fast_fmin.f32(float, float) local_unnamed_addr #1

attributes #0 = { nounwind readnone "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="128" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { nounwind readnone }

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
!14 = !{<4 x float> (<4 x float>, <4 x float>, float, float, %struct.VisualizationUniforms addrspace(2)*)* @viz_tunnel_fragment, !15, !17}
!15 = !{!16}
!16 = !{!"air.render_target", i32 0, i32 0, !"air.arg_type_name", !"float4"}
!17 = !{!18, !19, !20, !21, !22}
!18 = !{i32 0, !"air.position", !"air.center", !"air.no_perspective", !"air.arg_type_name", !"float4", !"air.arg_name", !"position", !"air.arg_unused"}
!19 = !{i32 1, !"air.fragment_input", !"generated(5colorDv4_f)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!20 = !{i32 2, !"air.fragment_input", !"generated(5depthf)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float", !"air.arg_name", !"depth"}
!21 = !{i32 3, !"air.fragment_input", !"generated(5clipWf)", !"air.center", !"air.perspective", !"air.arg_type_name", !"float", !"air.arg_name", !"clipW"}
!22 = !{i32 4, !"air.buffer", !"air.buffer_size", i32 240, !"air.location_index", i32 0, i32 1, !"air.read", !"air.address_space", i32 2, !"air.struct_type_info", !23, !"air.arg_type_size", i32 240, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"VisualizationUniforms", !"air.arg_name", !"uniforms"}
!23 = !{i32 0, i32 64, i32 0, !"float4x4", !"model", i32 64, i32 64, i32 0, !"float4x4", !"view", i32 128, i32 64, i32 0, !"float4x4", !"projection", i32 192, i32 4, i32 0, !"float", !"time", i32 196, i32 4, i32 0, !"int", !"quality", i32 200, i32 4, i32 0, !"float", !"fogDensity", i32 204, i32 4, i32 0, !"float", !"padding", i32 208, i32 16, i32 0, !"float3", !"fogColor", i32 224, i32 4, i32 0, !"float", !"padding2"}
!24 = !{!25, !29, i64 200}
!25 = !{!"_ZTS21VisualizationUniforms", !26, i64 0, !26, i64 64, !26, i64 128, !29, i64 192, !30, i64 196, !29, i64 200, !29, i64 204, !27, i64 208, !29, i64 224}
!26 = !{!"_ZTSN5metal6matrixIfLi4ELi4EvEE", !27, i64 0}
!27 = !{!"omnipotent char", !28, i64 0}
!28 = !{!"Simple C++ TBAA"}
!29 = !{!"float", !27, i64 0}
!30 = !{!"int", !27, i64 0}
!31 = !{!32}
!32 = distinct !{!32, !33, !"air-alias-scope-arg(4)"}
!33 = distinct !{!33, !"air-alias-scopes(viz_tunnel_fragment)"}
!34 = !{!27, !27, i64 0}
