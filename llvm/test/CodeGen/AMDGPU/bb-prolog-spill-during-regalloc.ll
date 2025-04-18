; NOTE: Assertions have been autogenerated by utils/update_mir_test_checks.py UTC_ARGS: --version 3
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx906 -O0 -verify-machineinstrs --stop-after=regallocfast,1 -o - %s | FileCheck -check-prefix=REGALLOC %s

; Test to check if the bb prolog spills are inserted correctly during regalloc.
define i32 @prolog_spill(i32 %arg0, i32 %arg1, i32 %arg2) {
  ; REGALLOC-LABEL: name: prolog_spill
  ; REGALLOC: bb.0.bb.0:
  ; REGALLOC-NEXT:   successors: %bb.3(0x40000000), %bb.1(0x40000000)
  ; REGALLOC-NEXT:   liveins: $vgpr0, $vgpr1, $vgpr2
  ; REGALLOC-NEXT: {{  $}}
  ; REGALLOC-NEXT:   [[COPY:%[0-9]+]]:vgpr_32 = COPY $vgpr2
  ; REGALLOC-NEXT:   [[COPY1:%[0-9]+]]:vgpr_32 = COPY $vgpr1
  ; REGALLOC-NEXT:   [[COPY2:%[0-9]+]]:vgpr_32 = COPY $vgpr0
  ; REGALLOC-NEXT:   renamable $sgpr4 = S_MOV_B32 49
  ; REGALLOC-NEXT:   renamable $sgpr4_sgpr5 = V_CMP_GT_I32_e64 [[COPY2]], killed $sgpr4, implicit $exec
  ; REGALLOC-NEXT:   renamable $sgpr6 = IMPLICIT_DEF
  ; REGALLOC-NEXT:   [[COPY3:%[0-9]+]]:vgpr_32 = COPY killed renamable $sgpr6
  ; REGALLOC-NEXT:   [[COPY4:%[0-9]+]]:vgpr_32 = COPY [[COPY3]]
  ; REGALLOC-NEXT:   renamable $sgpr6_sgpr7 = S_XOR_B64 renamable $sgpr4_sgpr5, $exec, implicit-def dead $scc
  ; REGALLOC-NEXT:   renamable $vgpr63 = IMPLICIT_DEF
  ; REGALLOC-NEXT:   $vgpr63 = SI_SPILL_S32_TO_VGPR killed $sgpr6, 0, $vgpr63, implicit-def $sgpr6_sgpr7, implicit $sgpr6_sgpr7
  ; REGALLOC-NEXT:   $vgpr63 = SI_SPILL_S32_TO_VGPR killed $sgpr7, 1, $vgpr63, implicit killed $sgpr6_sgpr7
  ; REGALLOC-NEXT:   SI_SPILL_WWM_V32_SAVE killed $vgpr63, %stack.2, $sgpr32, 0, implicit $exec :: (store (s32) into %stack.2, addrspace 5)
  ; REGALLOC-NEXT:   S_CMP_LG_U64_term renamable $sgpr4_sgpr5, 0, implicit-def $scc
  ; REGALLOC-NEXT:   $exec = S_CMOV_B64_term killed renamable $sgpr4_sgpr5, implicit $scc
  ; REGALLOC-NEXT:   S_CBRANCH_SCC1 %bb.3, implicit killed $scc
  ; REGALLOC-NEXT:   S_BRANCH %bb.1
  ; REGALLOC-NEXT: {{  $}}
  ; REGALLOC-NEXT: bb.1.Flow:
  ; REGALLOC-NEXT:   successors: %bb.2(0x40000000), %bb.4(0x40000000)
  ; REGALLOC-NEXT: {{  $}}
  ; REGALLOC-NEXT:   $vgpr63 = SI_SPILL_WWM_V32_RESTORE %stack.2, $sgpr32, 0, implicit $exec :: (load (s32) from %stack.2, addrspace 5)
  ; REGALLOC-NEXT:   $sgpr4 = SI_RESTORE_S32_FROM_VGPR $vgpr63, 0, implicit-def $sgpr4_sgpr5
  ; REGALLOC-NEXT:   $sgpr5 = SI_RESTORE_S32_FROM_VGPR $vgpr63, 1
  ; REGALLOC-NEXT:   [[COPY5:%[0-9]+]]:vgpr_32 = COPY [[COPY4]]
  ; REGALLOC-NEXT:   [[COPY6:%[0-9]+]]:vgpr_32 = COPY [[COPY5]]
  ; REGALLOC-NEXT:   renamable $sgpr6_sgpr7 = S_XOR_B64 renamable $sgpr4_sgpr5, $exec, implicit-def dead $scc
  ; REGALLOC-NEXT:   $vgpr63 = SI_SPILL_S32_TO_VGPR killed $sgpr6, 2, $vgpr63, implicit-def $sgpr6_sgpr7, implicit $sgpr6_sgpr7
  ; REGALLOC-NEXT:   $vgpr63 = SI_SPILL_S32_TO_VGPR killed $sgpr7, 3, $vgpr63, implicit killed $sgpr6_sgpr7
  ; REGALLOC-NEXT:   SI_SPILL_WWM_V32_SAVE killed $vgpr63, %stack.2, $sgpr32, 0, implicit $exec :: (store (s32) into %stack.2, addrspace 5)
  ; REGALLOC-NEXT:   S_CMP_LG_U64_term renamable $sgpr4_sgpr5, 0, implicit-def $scc
  ; REGALLOC-NEXT:   $exec = S_CMOV_B64_term killed renamable $sgpr4_sgpr5, implicit $scc
  ; REGALLOC-NEXT:   S_CBRANCH_SCC1 %bb.2, implicit killed $scc
  ; REGALLOC-NEXT:   S_BRANCH %bb.4
  ; REGALLOC-NEXT: {{  $}}
  ; REGALLOC-NEXT: bb.2.bb.1:
  ; REGALLOC-NEXT:   successors: %bb.4(0x80000000)
  ; REGALLOC-NEXT: {{  $}}
  ; REGALLOC-NEXT:   $vgpr63 = SI_SPILL_WWM_V32_RESTORE %stack.2, $sgpr32, 0, implicit $exec :: (load (s32) from %stack.2, addrspace 5)
  ; REGALLOC-NEXT:   $sgpr4 = SI_RESTORE_S32_FROM_VGPR $vgpr63, 2, implicit-def $sgpr4_sgpr5
  ; REGALLOC-NEXT:   $sgpr5 = SI_RESTORE_S32_FROM_VGPR $vgpr63, 3
  ; REGALLOC-NEXT:   renamable $sgpr6 = S_MOV_B32 10
  ; REGALLOC-NEXT:   [[V_ADD_U32_e64_:%[0-9]+]]:vgpr_32 = V_ADD_U32_e64 [[COPY1]], killed $sgpr6, 0, implicit $exec
  ; REGALLOC-NEXT:   [[COPY6:%[0-9]+]]:vgpr_32 = COPY [[V_ADD_U32_e64_]]
  ; REGALLOC-NEXT:   $exec = S_OR_B64_term $exec, killed renamable $sgpr4_sgpr5, implicit-def dead $scc
  ; REGALLOC-NEXT:   S_BRANCH %bb.4
  ; REGALLOC-NEXT: {{  $}}
  ; REGALLOC-NEXT: bb.3.bb.2:
  ; REGALLOC-NEXT:   successors: %bb.1(0x80000000)
  ; REGALLOC-NEXT: {{  $}}
  ; REGALLOC-NEXT:   $vgpr63 = SI_SPILL_WWM_V32_RESTORE %stack.2, $sgpr32, 0, implicit $exec :: (load (s32) from %stack.2, addrspace 5)
  ; REGALLOC-NEXT:   $sgpr4 = SI_RESTORE_S32_FROM_VGPR $vgpr63, 0, implicit-def $sgpr4_sgpr5
  ; REGALLOC-NEXT:   $sgpr5 = SI_RESTORE_S32_FROM_VGPR $vgpr63, 1
  ; REGALLOC-NEXT:   renamable $sgpr6 = S_MOV_B32 20
  ; REGALLOC-NEXT:   [[V_ADD_U32_e64_1:%[0-9]+]]:vgpr_32 = V_ADD_U32_e64 [[COPY]], killed $sgpr6, 0, implicit $exec
  ; REGALLOC-NEXT:   [[COPY4:%[0-9]+]]:vgpr_32 = COPY [[V_ADD_U32_e64_1]]
  ; REGALLOC-NEXT:   $exec = S_OR_B64_term $exec, killed renamable $sgpr4_sgpr5, implicit-def dead $scc
  ; REGALLOC-NEXT:   S_BRANCH %bb.1
  ; REGALLOC-NEXT: {{  $}}
  ; REGALLOC-NEXT: bb.4.bb.3:
  ; REGALLOC-NEXT:   [[COPY7:%[0-9]+]]:vgpr_32 = COPY [[COPY6]]
  ; REGALLOC-NEXT:   [[V_LSHL_ADD_U32_e64_:%[0-9]+]]:vgpr_32 = V_LSHL_ADD_U32_e64 [[COPY7]], 2, [[COPY7]], implicit $exec
  ; REGALLOC-NEXT:   $vgpr0 = COPY [[V_LSHL_ADD_U32_e64_]]
  ; REGALLOC-NEXT:   SI_RETURN implicit $vgpr0
bb.0:
  %cmp = icmp slt i32 %arg0, 50
  br i1 %cmp, label %bb.1, label %bb.2

bb.1:
  %val1 = add i32 %arg1, 10
  br label %bb.3

bb.2:
  %val2 = add i32 %arg2, 20
  br label %bb.3

bb.3:
  %val = phi i32 [ %val1, %bb.1 ], [ %val2, %bb.2 ]
  %ret = mul i32 %val, 5;
  ret i32 %ret
}
