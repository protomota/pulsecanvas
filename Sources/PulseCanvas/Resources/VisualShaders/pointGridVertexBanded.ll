; ModuleID = 'work/shaders/shader_10.bc'
source_filename = "pointGridVertexBanded"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%struct.PointUniforms = type { %"struct.metal::matrix.9", float, float, <2 x float>, <4 x float> }
%"struct.metal::matrix.9" = type { [4 x <4 x float>] }

; Function Attrs: nounwind readnone
define <{ <4 x float>, float, <4 x float> }> @pointGridVertexBanded(<3 x float> %0, i32 %1, %struct.PointUniforms addrspace(2)* nocapture readonly dereferenceable(96) "air-buffer-no-alias" %2, <4 x float> addrspace(2)* nocapture readonly "air-buffer-no-alias" %3, i32 addrspace(2)* nocapture readonly dereferenceable(4) "air-buffer-no-alias" %4, i32 addrspace(2)* nocapture readonly dereferenceable(4) "air-buffer-no-alias" %5) local_unnamed_addr #0 {
  %7 = bitcast <3 x float> %0 to <3 x i32>
  %8 = and <3 x i32> %7, <i32 2139095040, i32 2139095040, i32 2139095040>
  %9 = icmp ne <3 x i32> %8, <i32 2139095040, i32 2139095040, i32 2139095040>
  %10 = tail call i1 @air.all.v3i1(<3 x i1> %9) #1
  br i1 %10, label %11, label %62

11:                                               ; preds = %6
  %12 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %2, i64 0, i32 0, i32 0, i64 0
  %13 = load <4 x float>, <4 x float> addrspace(2)* %12, align 16, !tbaa !27, !alias.scope !30, !noalias !33
  %14 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> zeroinitializer
  %15 = fmul fast <4 x float> %13, %14
  %16 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %2, i64 0, i32 0, i32 0, i64 1
  %17 = load <4 x float>, <4 x float> addrspace(2)* %16, align 16, !tbaa !27, !alias.scope !30, !noalias !33
  %18 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %19 = fmul fast <4 x float> %17, %18
  %20 = fadd fast <4 x float> %19, %15
  %21 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %2, i64 0, i32 0, i32 0, i64 2
  %22 = load <4 x float>, <4 x float> addrspace(2)* %21, align 16, !tbaa !27, !alias.scope !30, !noalias !33
  %23 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 2, i32 2, i32 2, i32 2>
  %24 = fmul fast <4 x float> %22, %23
  %25 = fadd fast <4 x float> %20, %24
  %26 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %2, i64 0, i32 0, i32 0, i64 3
  %27 = load <4 x float>, <4 x float> addrspace(2)* %26, align 16, !tbaa !27, !alias.scope !30, !noalias !33
  %28 = fadd fast <4 x float> %25, %27
  %29 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %2, i64 0, i32 1
  %30 = load float, float addrspace(2)* %29, align 16, !tbaa !37, !alias.scope !30, !noalias !33
  %31 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %2, i64 0, i32 2
  %32 = load float, float addrspace(2)* %31, align 4, !tbaa !41, !alias.scope !30, !noalias !33
  %33 = fmul fast float %32, %30
  %34 = extractelement <4 x float> %28, i64 3
  %35 = tail call fast float @air.fast_fmax.f32(float %34, float 0x3F50624DE0000000) #1
  %36 = fdiv fast float %33, %35
  %37 = tail call fast float @air.fast_clamp.f32(float %36, float 1.000000e+00, float 6.400000e+01) #1
  %38 = bitcast <4 x float> %28 to <4 x i32>
  %39 = and <4 x i32> %38, <i32 2139095040, i32 2139095040, i32 2139095040, i32 2139095040>
  %40 = icmp ne <4 x i32> %39, <i32 2139095040, i32 2139095040, i32 2139095040, i32 2139095040>
  %41 = tail call i1 @air.all.v4i1(<4 x i1> %40) #1
  br i1 %41, label %42, label %62

42:                                               ; preds = %11
  %43 = bitcast float %37 to i32
  %44 = and i32 %43, 2139095040
  %45 = icmp eq i32 %44, 2139095040
  br i1 %45, label %62, label %46

46:                                               ; preds = %42
  %47 = load i32, i32 addrspace(2)* %4, align 4, !tbaa !42, !alias.scope !44, !noalias !45
  %48 = icmp eq i32 %47, 0
  br i1 %48, label %54, label %49

49:                                               ; preds = %46
  %50 = load i32, i32 addrspace(2)* %5, align 4, !tbaa !42, !alias.scope !46, !noalias !47
  %51 = tail call i32 @air.max.u.i32(i32 %50, i32 1) #1
  %52 = udiv i32 %1, %51
  %53 = urem i32 %52, %47
  br label %54

54:                                               ; preds = %49, %46
  %55 = phi i32 [ %53, %49 ], [ 0, %46 ]
  %56 = zext i32 %55 to i64
  %57 = getelementptr inbounds <4 x float>, <4 x float> addrspace(2)* %3, i64 %56
  %58 = load <4 x float>, <4 x float> addrspace(2)* %57, align 16, !alias.scope !48, !noalias !49
  %59 = getelementptr inbounds %struct.PointUniforms, %struct.PointUniforms addrspace(2)* %2, i64 0, i32 4
  %60 = load <4 x float>, <4 x float> addrspace(2)* %59, align 16, !alias.scope !30, !noalias !33
  %61 = shufflevector <4 x float> %58, <4 x float> %60, <4 x i32> <i32 0, i32 1, i32 2, i32 7>
  br label %62

62:                                               ; preds = %54, %42, %11, %6
  %63 = phi <4 x float> [ %28, %54 ], [ <float 0.000000e+00, float 0.000000e+00, float -2.000000e+00, float 1.000000e+00>, %6 ], [ <float 0.000000e+00, float 0.000000e+00, float -2.000000e+00, float 1.000000e+00>, %42 ], [ <float 0.000000e+00, float 0.000000e+00, float -2.000000e+00, float 1.000000e+00>, %11 ]
  %64 = phi float [ %37, %54 ], [ 0.000000e+00, %6 ], [ 0.000000e+00, %42 ], [ 0.000000e+00, %11 ]
  %65 = phi <4 x float> [ %61, %54 ], [ zeroinitializer, %6 ], [ zeroinitializer, %42 ], [ zeroinitializer, %11 ]
  %66 = insertvalue <{ <4 x float>, float, <4 x float> }> undef, <4 x float> %63, 0
  %67 = insertvalue <{ <4 x float>, float, <4 x float> }> %66, float %64, 1
  %68 = insertvalue <{ <4 x float>, float, <4 x float> }> %67, <4 x float> %65, 2
  ret <{ <4 x float>, float, <4 x float> }> %68
}

; Function Attrs: nounwind readnone
declare i32 @air.max.u.i32(i32, i32) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare i1 @air.all.v4i1(<4 x i1>) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.fast_clamp.f32(float, float, float) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare float @air.fast_fmax.f32(float, float) local_unnamed_addr #1

; Function Attrs: nounwind readnone
declare i1 @air.all.v3i1(<3 x i1>) local_unnamed_addr #1

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
!14 = !{<{ <4 x float>, float, <4 x float> }> (<3 x float>, i32, %struct.PointUniforms addrspace(2)*, <4 x float> addrspace(2)*, i32 addrspace(2)*, i32 addrspace(2)*)* @pointGridVertexBanded, !15, !19}
!15 = !{!16, !17, !18}
!16 = !{!"air.position", !"air.arg_type_name", !"float4", !"air.arg_name", !"position"}
!17 = !{!"air.point_size", !"air.arg_type_name", !"float", !"air.arg_name", !"pointSize"}
!18 = !{!"air.vertex_output", !"generated(5colorDv4_f)", !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!19 = !{!20, !21, !22, !24, !25, !26}
!20 = !{i32 0, !"air.vertex_input", !"air.location_index", i32 0, i32 1, !"air.arg_type_name", !"float3", !"air.arg_name", !"position"}
!21 = !{i32 1, !"air.vertex_id", !"air.arg_type_name", !"uint", !"air.arg_name", !"vid"}
!22 = !{i32 2, !"air.buffer", !"air.buffer_size", i32 96, !"air.location_index", i32 1, i32 1, !"air.read", !"air.address_space", i32 2, !"air.struct_type_info", !23, !"air.arg_type_size", i32 96, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"PointUniforms", !"air.arg_name", !"uniforms"}
!23 = !{i32 0, i32 64, i32 0, !"float4x4", !"mvpMatrix", i32 64, i32 4, i32 0, !"float", !"pointSize", i32 68, i32 4, i32 0, !"float", !"heightOfNearPlane", i32 72, i32 8, i32 0, !"float2", !"_pad0", i32 80, i32 16, i32 0, !"float4", !"color"}
!24 = !{i32 3, !"air.buffer", !"air.location_index", i32 2, i32 1, !"air.read", !"air.address_space", i32 2, !"air.arg_type_size", i32 16, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"float4", !"air.arg_name", !"bandColors"}
!25 = !{i32 4, !"air.buffer", !"air.buffer_size", i32 4, !"air.location_index", i32 3, i32 1, !"air.read", !"air.address_space", i32 2, !"air.arg_type_size", i32 4, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"uint", !"air.arg_name", !"bandCount"}
!26 = !{i32 5, !"air.buffer", !"air.buffer_size", i32 4, !"air.location_index", i32 4, i32 1, !"air.read", !"air.address_space", i32 2, !"air.arg_type_size", i32 4, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"uint", !"air.arg_name", !"clusterSize"}
!27 = !{!28, !28, i64 0}
!28 = !{!"omnipotent char", !29, i64 0}
!29 = !{!"Simple C++ TBAA"}
!30 = !{!31}
!31 = distinct !{!31, !32, !"air-alias-scope-arg(2)"}
!32 = distinct !{!32, !"air-alias-scopes(pointGridVertexBanded)"}
!33 = !{!34, !35, !36}
!34 = distinct !{!34, !32, !"air-alias-scope-arg(3)"}
!35 = distinct !{!35, !32, !"air-alias-scope-arg(4)"}
!36 = distinct !{!36, !32, !"air-alias-scope-arg(5)"}
!37 = !{!38, !40, i64 64}
!38 = !{!"_ZTS13PointUniforms", !39, i64 0, !40, i64 64, !40, i64 68, !28, i64 72, !28, i64 80}
!39 = !{!"_ZTSN5metal6matrixIfLi4ELi4EvEE", !28, i64 0}
!40 = !{!"float", !28, i64 0}
!41 = !{!38, !40, i64 68}
!42 = !{!43, !43, i64 0}
!43 = !{!"int", !28, i64 0}
!44 = !{!35}
!45 = !{!31, !34, !36}
!46 = !{!36}
!47 = !{!31, !34, !35}
!48 = !{!34}
!49 = !{!31, !35, !36}
