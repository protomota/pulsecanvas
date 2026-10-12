; ModuleID = 'work/shaders/shader_19.bc'
source_filename = "galaxyJourneyRadialBlurVertex"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

; Function Attrs: nounwind readnone
define <{ <4 x float>, <2 x float> }> @galaxyJourneyRadialBlurVertex(i32 %0) local_unnamed_addr #0 {
  %2 = alloca [4 x <2 x float>], align 8
  %3 = alloca [4 x <2 x float>], align 8
  %4 = bitcast [4 x <2 x float>]* %2 to i8*
  call void @llvm.lifetime.start.p0i8(i64 32, i8* nonnull %4) #2
  %5 = getelementptr inbounds [4 x <2 x float>], [4 x <2 x float>]* %2, i64 0, i64 0
  store <2 x float> <float -1.000000e+00, float -1.000000e+00>, <2 x float>* %5, align 8
  %6 = getelementptr inbounds [4 x <2 x float>], [4 x <2 x float>]* %2, i64 0, i64 1
  store <2 x float> <float 1.000000e+00, float -1.000000e+00>, <2 x float>* %6, align 8
  %7 = getelementptr inbounds [4 x <2 x float>], [4 x <2 x float>]* %2, i64 0, i64 2
  store <2 x float> <float -1.000000e+00, float 1.000000e+00>, <2 x float>* %7, align 8
  %8 = getelementptr inbounds [4 x <2 x float>], [4 x <2 x float>]* %2, i64 0, i64 3
  store <2 x float> <float 1.000000e+00, float 1.000000e+00>, <2 x float>* %8, align 8
  %9 = bitcast [4 x <2 x float>]* %3 to i8*
  call void @llvm.lifetime.start.p0i8(i64 32, i8* nonnull %9) #2
  %10 = getelementptr inbounds [4 x <2 x float>], [4 x <2 x float>]* %3, i64 0, i64 0
  store <2 x float> <float 0.000000e+00, float 1.000000e+00>, <2 x float>* %10, align 8
  %11 = getelementptr inbounds [4 x <2 x float>], [4 x <2 x float>]* %3, i64 0, i64 1
  store <2 x float> <float 1.000000e+00, float 1.000000e+00>, <2 x float>* %11, align 8
  %12 = getelementptr inbounds [4 x <2 x float>], [4 x <2 x float>]* %3, i64 0, i64 2
  store <2 x float> zeroinitializer, <2 x float>* %12, align 8
  %13 = getelementptr inbounds [4 x <2 x float>], [4 x <2 x float>]* %3, i64 0, i64 3
  store <2 x float> <float 1.000000e+00, float 0.000000e+00>, <2 x float>* %13, align 8
  %14 = zext i32 %0 to i64
  %15 = getelementptr inbounds [4 x <2 x float>], [4 x <2 x float>]* %2, i64 0, i64 %14
  %16 = load <2 x float>, <2 x float>* %15, align 8, !tbaa !20
  %17 = shufflevector <2 x float> %16, <2 x float> undef, <4 x i32> <i32 0, i32 1, i32 undef, i32 undef>
  %18 = shufflevector <4 x float> %17, <4 x float> <float undef, float undef, float 0.000000e+00, float 1.000000e+00>, <4 x i32> <i32 0, i32 1, i32 6, i32 7>
  %19 = getelementptr inbounds [4 x <2 x float>], [4 x <2 x float>]* %3, i64 0, i64 %14
  %20 = load <2 x float>, <2 x float>* %19, align 8, !tbaa !20
  call void @llvm.lifetime.end.p0i8(i64 32, i8* nonnull %9) #2
  call void @llvm.lifetime.end.p0i8(i64 32, i8* nonnull %4) #2
  %21 = insertvalue <{ <4 x float>, <2 x float> }> undef, <4 x float> %18, 0
  %22 = insertvalue <{ <4 x float>, <2 x float> }> %21, <2 x float> %20, 1
  ret <{ <4 x float>, <2 x float> }> %22
}

; Function Attrs: argmemonly nocallback nofree nosync nounwind willreturn
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #1

; Function Attrs: argmemonly nocallback nofree nosync nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #1

attributes #0 = { nounwind readnone "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { argmemonly nocallback nofree nosync nounwind willreturn }
attributes #2 = { nounwind }

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
!14 = !{<{ <4 x float>, <2 x float> }> (i32)* @galaxyJourneyRadialBlurVertex, !15, !18}
!15 = !{!16, !17}
!16 = !{!"air.position", !"air.arg_type_name", !"float4", !"air.arg_name", !"position"}
!17 = !{!"air.vertex_output", !"generated(8texCoordDv2_f)", !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!18 = !{!19}
!19 = !{i32 0, !"air.vertex_id", !"air.arg_type_name", !"uint", !"air.arg_name", !"vertexID"}
!20 = !{!21, !21, i64 0}
!21 = !{!"omnipotent char", !22, i64 0}
!22 = !{!"Simple C++ TBAA"}
