; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mattr=+avx < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-scei-ps4"

@G1 = common dso_local global <2 x float> zeroinitializer, align 8
@G2 = common dso_local global <8 x float> zeroinitializer, align 32

define <4 x float> @foo() {
; CHECK-LABEL: foo:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vmovaps G2(%rip), %xmm0
; CHECK-NEXT:    vmovlps {{.*#+}} xmm0 = mem[0,1],xmm0[2,3]
; CHECK-NEXT:    vshufps {{.*#+}} xmm0 = xmm0[2,0],mem[0,2]
; CHECK-NEXT:    vshufps {{.*#+}} xmm0 = xmm0[2,0,3,1]
; CHECK-NEXT:    retq
entry:
  %V = load <2 x float>, <2 x float>* @G1, align 8
  %shuffle = shufflevector <2 x float> %V, <2 x float> undef, <8 x i32> <i32 undef, i32 undef, i32 undef, i32 undef, i32 0, i32 undef, i32 undef, i32 undef>
  %L = load <8 x float>, <8 x float>* @G2, align 32
  %shuffle1 = shufflevector <8 x float> %shuffle, <8 x float> %L, <4 x i32> <i32 12, i32 10, i32 14, i32 4>
  ret <4 x float> %shuffle1
}
