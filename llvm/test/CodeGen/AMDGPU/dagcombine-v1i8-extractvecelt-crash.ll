; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=amdgcn -mcpu=gfx908 < %s | FileCheck %s

define void @wombat(i1 %cond, ptr addrspace(5) %addr) {
; CHECK-LABEL: wombat:
; CHECK:       ; %bb.0: ; %entry
; CHECK-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; CHECK-NEXT:    buffer_load_ubyte v2, v1, s[0:3], 0 offen
; CHECK-NEXT:    v_and_b32_e32 v0, 1, v0
; CHECK-NEXT:    v_cmp_eq_u32_e32 vcc, 1, v0
; CHECK-NEXT:    s_mov_b64 s[4:5], exec
; CHECK-NEXT:    s_cmp_lg_u64 vcc, 0
; CHECK-NEXT:    s_cmov_b64 exec, vcc
; CHECK-NEXT:    s_cbranch_scc0 .LBB0_2
; CHECK-NEXT:  ; %bb.1: ; %then
; CHECK-NEXT:    s_waitcnt vmcnt(0)
; CHECK-NEXT:    v_mov_b32_e32 v2, 0
; CHECK-NEXT:    s_or_b64 exec, exec, s[4:5]
; CHECK-NEXT:  .LBB0_2: ; %end
; CHECK-NEXT:    s_waitcnt vmcnt(0)
; CHECK-NEXT:    buffer_store_byte v2, v1, s[0:3], 0 offen
; CHECK-NEXT:    s_waitcnt vmcnt(0)
; CHECK-NEXT:    s_setpc_b64 s[30:31]
entry:
  %load = load <1 x i8>, ptr addrspace(5) %addr, align 1
  br i1 %cond, label %then, label %end

then:
  br label %end

end:
  %phi_value = phi <1 x i8> [%load, %entry], [zeroinitializer, %then]
  store <1 x i8> %phi_value, ptr addrspace(5) %addr, align 1
  ret void
}
