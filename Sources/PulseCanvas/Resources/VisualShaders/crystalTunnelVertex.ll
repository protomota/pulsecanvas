; ModuleID = 'work/shaders/shader_23.bc'
source_filename = "crystalTunnelVertex"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v25-apple-ios16.0.0"

%"struct.metal::matrix.9" = type { [4 x <4 x float>] }
%struct.TextureModeParams = type { i32, i32 }

; Function Attrs: norecurse nounwind readnone
define <{ <4 x float>, <4 x float>, <2 x float> }> @crystalTunnelVertex(<3 x float> %0, <4 x float> %1, <2 x float> %2, %"struct.metal::matrix.9" addrspace(2)* nocapture readonly dereferenceable(64) "air-buffer-no-alias" %3, %struct.TextureModeParams addrspace(2)* nocapture readonly dereferenceable(8) "air-buffer-no-alias" %4, i32 %5) local_unnamed_addr #0 {
  %7 = getelementptr inbounds %"struct.metal::matrix.9", %"struct.metal::matrix.9" addrspace(2)* %3, i64 0, i32 0, i64 0
  %8 = load <4 x float>, <4 x float> addrspace(2)* %7, align 16, !tbaa !27, !alias.scope !30, !noalias !33
  %9 = getelementptr inbounds %"struct.metal::matrix.9", %"struct.metal::matrix.9" addrspace(2)* %3, i64 0, i32 0, i64 1
  %10 = load <4 x float>, <4 x float> addrspace(2)* %9, align 16, !tbaa !27, !alias.scope !30, !noalias !33
  %11 = getelementptr inbounds %"struct.metal::matrix.9", %"struct.metal::matrix.9" addrspace(2)* %3, i64 0, i32 0, i64 2
  %12 = load <4 x float>, <4 x float> addrspace(2)* %11, align 16, !tbaa !27, !alias.scope !30, !noalias !33
  %13 = getelementptr inbounds %"struct.metal::matrix.9", %"struct.metal::matrix.9" addrspace(2)* %3, i64 0, i32 0, i64 3
  %14 = load <4 x float>, <4 x float> addrspace(2)* %13, align 16, !tbaa !27, !alias.scope !30, !noalias !33
  %15 = getelementptr inbounds %struct.TextureModeParams, %struct.TextureModeParams addrspace(2)* %4, i64 0, i32 0
  %16 = load i32, i32 addrspace(2)* %15, align 4, !tbaa !35, !alias.scope !33, !noalias !30
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %44, label %18

18:                                               ; preds = %6
  %19 = getelementptr inbounds %struct.TextureModeParams, %struct.TextureModeParams addrspace(2)* %4, i64 0, i32 1
  %20 = load i32, i32 addrspace(2)* %19, align 4, !tbaa !38, !alias.scope !33, !noalias !30
  %21 = sdiv i32 %5, %20
  %22 = srem i32 %5, %20
  %23 = srem i32 %21, 4
  switch i32 %23, label %26 [
    i32 0, label %27
    i32 1, label %24
    i32 2, label %25
  ]

24:                                               ; preds = %18
  br label %27

25:                                               ; preds = %18
  br label %27

26:                                               ; preds = %18
  br label %27

27:                                               ; preds = %26, %25, %24, %18
  %28 = phi float [ 5.000000e-01, %24 ], [ 1.000000e+00, %25 ], [ 5.000000e-01, %26 ], [ 0.000000e+00, %18 ]
  %29 = sdiv i32 %20, 2
  %30 = icmp slt i32 %22, %29
  %31 = srem i32 %22, 4
  br i1 %30, label %32, label %36

32:                                               ; preds = %27
  switch i32 %31, label %35 [
    i32 0, label %40
    i32 1, label %33
    i32 2, label %34
  ]

33:                                               ; preds = %32
  br label %40

34:                                               ; preds = %32
  br label %40

35:                                               ; preds = %32
  br label %40

36:                                               ; preds = %27
  switch i32 %31, label %39 [
    i32 0, label %40
    i32 1, label %37
    i32 2, label %38
  ]

37:                                               ; preds = %36
  br label %40

38:                                               ; preds = %36
  br label %40

39:                                               ; preds = %36
  br label %40

40:                                               ; preds = %39, %38, %37, %36, %35, %34, %33, %32
  %41 = phi float [ 5.000000e-01, %33 ], [ 1.000000e+00, %34 ], [ 5.000000e-01, %35 ], [ 0.000000e+00, %32 ], [ 0x3FD554C980000000, %37 ], [ 0x3FE5559B40000000, %38 ], [ 1.000000e+00, %39 ], [ 0.000000e+00, %36 ]
  %42 = insertelement <2 x float> undef, float %41, i64 0
  %43 = insertelement <2 x float> %42, float %28, i64 1
  br label %44

44:                                               ; preds = %40, %6
  %45 = phi <2 x float> [ %43, %40 ], [ %2, %6 ]
  %46 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> zeroinitializer
  %47 = fmul fast <4 x float> %8, %46
  %48 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %49 = fmul fast <4 x float> %10, %48
  %50 = fadd fast <4 x float> %49, %47
  %51 = shufflevector <3 x float> %0, <3 x float> undef, <4 x i32> <i32 2, i32 2, i32 2, i32 2>
  %52 = fmul fast <4 x float> %12, %51
  %53 = fadd fast <4 x float> %50, %52
  %54 = fadd fast <4 x float> %53, %14
  %55 = insertvalue <{ <4 x float>, <4 x float>, <2 x float> }> undef, <4 x float> %54, 0
  %56 = insertvalue <{ <4 x float>, <4 x float>, <2 x float> }> %55, <4 x float> %1, 1
  %57 = insertvalue <{ <4 x float>, <4 x float>, <2 x float> }> %56, <2 x float> %45, 2
  ret <{ <4 x float>, <4 x float>, <2 x float> }> %57
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
!14 = !{<{ <4 x float>, <4 x float>, <2 x float> }> (<3 x float>, <4 x float>, <2 x float>, %"struct.metal::matrix.9" addrspace(2)*, %struct.TextureModeParams addrspace(2)*, i32)* @crystalTunnelVertex, !15, !19}
!15 = !{!16, !17, !18}
!16 = !{!"air.position", !"air.arg_type_name", !"float4", !"air.arg_name", !"position"}
!17 = !{!"air.vertex_output", !"generated(5colorDv4_f)", !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!18 = !{!"air.vertex_output", !"generated(8texCoordDv2_f)", !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!19 = !{!20, !21, !22, !23, !24, !26}
!20 = !{i32 0, !"air.vertex_input", !"air.location_index", i32 0, i32 1, !"air.arg_type_name", !"float3", !"air.arg_name", !"position"}
!21 = !{i32 1, !"air.vertex_input", !"air.location_index", i32 1, i32 1, !"air.arg_type_name", !"float4", !"air.arg_name", !"color"}
!22 = !{i32 2, !"air.vertex_input", !"air.location_index", i32 2, i32 1, !"air.arg_type_name", !"float2", !"air.arg_name", !"texCoord"}
!23 = !{i32 3, !"air.buffer", !"air.buffer_size", i32 64, !"air.location_index", i32 1, i32 1, !"air.read", !"air.address_space", i32 2, !"air.arg_type_size", i32 64, !"air.arg_type_align_size", i32 16, !"air.arg_type_name", !"float4x4", !"air.arg_name", !"mvpMatrix"}
!24 = !{i32 4, !"air.buffer", !"air.buffer_size", i32 8, !"air.location_index", i32 3, i32 1, !"air.read", !"air.address_space", i32 2, !"air.struct_type_info", !25, !"air.arg_type_size", i32 8, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"TextureModeParams", !"air.arg_name", !"texParams"}
!25 = !{i32 0, i32 4, i32 0, !"int", !"texMode", i32 4, i32 4, i32 0, !"int", !"kmax"}
!26 = !{i32 5, !"air.vertex_id", !"air.arg_type_name", !"uint", !"air.arg_name", !"vertexID"}
!27 = !{!28, !28, i64 0}
!28 = !{!"omnipotent char", !29, i64 0}
!29 = !{!"Simple C++ TBAA"}
!30 = !{!31}
!31 = distinct !{!31, !32, !"air-alias-scope-arg(3)"}
!32 = distinct !{!32, !"air-alias-scopes(crystalTunnelVertex)"}
!33 = !{!34}
!34 = distinct !{!34, !32, !"air-alias-scope-arg(4)"}
!35 = !{!36, !37, i64 0}
!36 = !{!"_ZTS17TextureModeParams", !37, i64 0, !37, i64 4}
!37 = !{!"int", !28, i64 0}
!38 = !{!36, !37, i64 4}
