// RUN: llvm-tblgen -I %p/../../../include -gen-global-isel-combiner \
// RUN:     -combiners=MyCombiner %s | \
// RUN: FileCheck %s

include "llvm/Target/Target.td"
include "llvm/Target/GlobalISel/Combine.td"

def MyTargetISA : InstrInfo;
def MyTarget : Target { let InstructionSet = MyTargetISA; }

def dummy;

def HasAnswerToEverything : Predicate<"Subtarget->getAnswerToUniverse() == 42 && Subtarget->getAnswerToLife() == 42">;

def WipOpcodeTest0 : GICombineRule<
  (defs root:$d),
  (match (wip_match_opcode G_TRUNC):$d),
  (apply [{ APPLY }])>;

def WipOpcodeTest1 : GICombineRule<
  (defs root:$d),
  (match (wip_match_opcode G_TRUNC, G_SEXT):$d),
  (apply [{ APPLY }])>;

// Note: also checks that spaces in the type name are removed.
def reg_matchinfo : GIDefMatchData<"Register  ">;
def InstTest0 : GICombineRule<
  (defs root:$d, reg_matchinfo:$r0, reg_matchinfo:$r1),
  (match (COPY $a, $b):$d),
  (apply [{ APPLY ${r0}, ${r1} }])>;

let Predicates = [HasAnswerToEverything] in
def InstTest1 : GICombineRule<
  (defs root:$d, reg_matchinfo:$r0),
  (match (COPY $a, $b):$d,
         (G_ZEXT $b, $c),
         [{ return CHECK ${a}, ${b}, ${c}, ${d} }]),
  (apply [{ APPLY }])>;

def InOutInstTest0 : GICombineRule<
  (defs root:$root),
  (match (G_ZEXT $tmp, $ext),
         (G_STORE $tmp, $ptr):$root),
  (apply (G_STORE $ext, $ptr):$root, "APPLY ${ext} ${ptr} ${root}")>;

// Imm operand of G_CONSTANT should match a literal int, while the second
// should match a constant.
def InOutInstTest1 : GICombineRule<
  (defs root:$dst),
  (match
      (G_CONSTANT $x, -42:$z),
      (G_AND $dst, $x, (i32 43))),
  (apply (G_TRUNC $dst, $z))>;

def MatchICst: GICombinePatFrag<
    (outs),
    (ins gi_mo:$foo, gi_imm:$cst),
    [(pattern "return matchIConstant(${foo}, ${cst});")]>;

def PatFragTest0 : GICombineRule<
  (defs root:$dst),
  (match (G_ZEXT $dst, $cst), (MatchICst $cst, (i32 0))),
  (apply (COPY $dst, (i32 0)))>;

// TODO: add test with temp reg use

def MyCombiner: GICombiner<"GenMyCombiner", [
  WipOpcodeTest0,
  WipOpcodeTest1,
  InstTest0,
  InstTest1,
  InOutInstTest0,
  InOutInstTest1,
  PatFragTest0
]>;

// We have at most 2 registers used by one rule at a time, so we should only have 2 registers MDInfos.

// CHECK:      struct MatchInfosTy {
// CHECK-NEXT:   Register MDInfo0, MDInfo1;
// CHECK-NEXT: };

// Check predicates
// CHECK:      switch (PredicateID) {
// CHECK-NEXT: case GICXXPred_MI_Predicate_GICombiner0: {
// CHECK-NEXT:   return CHECK State.MIs[0]->getOperand(0), State.MIs[0]->getOperand(1), State.MIs[1]->getOperand(1), State.MIs[0]
// CHECK-NEXT: }
// CHECK-NEXT: case GICXXPred_MI_Predicate_GICombiner1: {
// CHECK-NEXT:   return matchIConstant(State.MIs[0]->getOperand(1), 0);
// CHECK-NEXT: }

// Verify we reset MatchData on each tryCombineAll
// CHECK:      bool GenMyCombiner::tryCombineAll(MachineInstr &I) const {
// CHECK-NEXT:   const TargetSubtargetInfo &ST = MF.getSubtarget();
// CHECK-NEXT:   const PredicateBitset AvailableFeatures = getAvailableFeatures();
// CHECK-NEXT:   B.setInstrAndDebugLoc(I);
// CHECK-NEXT:   State.MIs.clear();
// CHECK-NEXT:   State.MIs.push_back(&I);
// CHECK-NEXT:   MatchInfos = MatchInfosTy();
// CHECK-EMPTY:
// CHECK-NEXT:   if (executeMatchTable(*this, State, ExecInfo, B, getMatchTable(), *ST.getInstrInfo(), MRI, *MRI.getTargetRegisterInfo(), *ST.getRegBankInfo(), AvailableFeatures, /*CoverageInfo*/ nullptr))
// CHECK-NEXT:     return true;
// CHECK-NEXT:   }
// CHECK-EMPTY:
// CHECK-NEXT:   return false;
// CHECK-NEXT: }

// Check apply
// CHECK:      enum {
// CHECK-NEXT:   GICXXCustomAction_CombineApplyGICombiner0 = GICXXCustomAction_Invalid + 1,
// CHECK-NEXT:   GICXXCustomAction_CombineApplyGICombiner1,
// CHECK-NEXT:   GICXXCustomAction_CombineApplyGICombiner2,
// CHECK-NEXT: };
// CHECK-NEXT: void GenMyCombiner::runCustomAction(unsigned ApplyID, const MatcherState &State, NewMIVector &OutMIs) const {
// CHECK-NEXT:   switch(ApplyID) {
// CHECK-NEXT:   case GICXXCustomAction_CombineApplyGICombiner0:{
// CHECK-NEXT:     APPLY
// CHECK-NEXT:     return;
// CHECK-NEXT:   }
// CHECK-NEXT:   case GICXXCustomAction_CombineApplyGICombiner1:{
// CHECK-NEXT:     APPLY MatchInfos.MDInfo0, MatchInfos.MDInfo1
// CHECK-NEXT:     return;
// CHECK-NEXT:   }
// CHECK-NEXT:   case GICXXCustomAction_CombineApplyGICombiner2:{
// CHECK-NEXT:     APPLY State.MIs[1]->getOperand(1) State.MIs[0]->getOperand(1) OutMIs[0]
// CHECK-NEXT:     return;
// CHECK-NEXT:   }
// CHECK-NEXT: }
// CHECK-NEXT:   llvm_unreachable("Unknown Apply Action");
// CHECK-NEXT: }

// Verify match table.
// CHECK:      const uint8_t *GenMyCombiner::getMatchTable() const {
// CHECK-NEXT:   constexpr static uint8_t MatchTable0[] = {
// CHECK-NEXT:     GIM_SwitchOpcode, /*MI*/0, /*[*/GIMT_Encode2(21), GIMT_Encode2(129), /*)*//*default:*//*Label 6*/ GIMT_Encode4(657),
// CHECK-NEXT:     /*TargetOpcode::COPY*//*Label 0*/ GIMT_Encode4(442), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0),
// CHECK-NEXT:     /*TargetOpcode::G_AND*//*Label 1*/ GIMT_Encode4(484), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0),
// CHECK-NEXT:     /*TargetOpcode::G_STORE*//*Label 2*/ GIMT_Encode4(537), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0),
// CHECK-NEXT:     /*TargetOpcode::G_TRUNC*//*Label 3*/ GIMT_Encode4(579), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0), GIMT_Encode4(0),
// CHECK-NEXT:     /*TargetOpcode::G_SEXT*//*Label 4*/ GIMT_Encode4(604), GIMT_Encode4(0),
// CHECK-NEXT:     /*TargetOpcode::G_ZEXT*//*Label 5*/ GIMT_Encode4(617),
// CHECK-NEXT:     // Label 0: @442
// CHECK-NEXT:     GIM_Try, /*On fail goto*//*Label 7*/ GIMT_Encode4(471), // Rule ID 4 //
// CHECK-NEXT:       GIM_CheckFeatures, GIMT_Encode2(GIFBS_HasAnswerToEverything),
// CHECK-NEXT:       GIM_CheckSimplePredicate, GIMT_Encode2(GICXXPred_Simple_IsRule3Enabled),
// CHECK-NEXT:       // MIs[0] a
// CHECK-NEXT:       // No operand predicates
// CHECK-NEXT:       // MIs[0] b
// CHECK-NEXT:       GIM_RecordInsnIgnoreCopies, /*DefineMI*/1, /*MI*/0, /*OpIdx*/1, // MIs[1]
// CHECK-NEXT:       GIM_CheckOpcode, /*MI*/1, GIMT_Encode2(TargetOpcode::G_ZEXT),
// CHECK-NEXT:       // MIs[1] c
// CHECK-NEXT:       // No operand predicates
// CHECK-NEXT:       GIM_CheckCxxInsnPredicate, /*MI*/0, /*FnId*/GIMT_Encode2(GICXXPred_MI_Predicate_GICombiner0),
// CHECK-NEXT:       GIM_CheckIsSafeToFold, /*InsnID*/1,
// CHECK-NEXT:       // Combiner Rule #3: InstTest1
// CHECK-NEXT:       GIR_CustomAction, GIMT_Encode2(GICXXCustomAction_CombineApplyGICombiner0),
// CHECK-NEXT:       GIR_Done,
// CHECK-NEXT:     // Label 7: @471
// CHECK-NEXT:     GIM_Try, /*On fail goto*//*Label 8*/ GIMT_Encode4(483), // Rule ID 3 //
// CHECK-NEXT:       GIM_CheckSimplePredicate, GIMT_Encode2(GICXXPred_Simple_IsRule2Enabled),
// CHECK-NEXT:       // MIs[0] a
// CHECK-NEXT:       // No operand predicates
// CHECK-NEXT:       // MIs[0] b
// CHECK-NEXT:       // No operand predicates
// CHECK-NEXT:       // Combiner Rule #2: InstTest0
// CHECK-NEXT:       GIR_CustomAction, GIMT_Encode2(GICXXCustomAction_CombineApplyGICombiner1),
// CHECK-NEXT:       GIR_Done,
// CHECK-NEXT:     // Label 8: @483
// CHECK-NEXT:     GIM_Reject,
// CHECK-NEXT:     // Label 1: @484
// CHECK-NEXT:     GIM_Try, /*On fail goto*//*Label 9*/ GIMT_Encode4(536), // Rule ID 6 //
// CHECK-NEXT:       GIM_CheckSimplePredicate, GIMT_Encode2(GICXXPred_Simple_IsRule5Enabled),
// CHECK-NEXT:       GIM_CheckType, /*MI*/0, /*Op*/2, /*Type*/GILLT_s32,
// CHECK-NEXT:       // MIs[0] dst
// CHECK-NEXT:       // No operand predicates
// CHECK-NEXT:       // MIs[0] x
// CHECK-NEXT:       GIM_RecordInsnIgnoreCopies, /*DefineMI*/1, /*MI*/0, /*OpIdx*/1, // MIs[1]
// CHECK-NEXT:       GIM_CheckOpcode, /*MI*/1, GIMT_Encode2(TargetOpcode::G_CONSTANT),
// CHECK-NEXT:       // MIs[1] z
// CHECK-NEXT:       GIM_CheckLiteralInt, /*MI*/1, /*Op*/1, GIMT_Encode8(-42),
// CHECK-NEXT:       GIM_CheckConstantInt8, /*MI*/0, /*Op*/2, 43,
// CHECK-NEXT:       GIM_CheckIsSafeToFold, /*InsnID*/1,
// CHECK-NEXT:       // Combiner Rule #5: InOutInstTest1
// CHECK-NEXT:       GIR_BuildMI, /*InsnID*/0, /*Opcode*/GIMT_Encode2(TargetOpcode::G_TRUNC),
// CHECK-NEXT:       GIR_Copy, /*NewInsnID*/0, /*OldInsnID*/0, /*OpIdx*/0, // dst
// CHECK-NEXT:       GIR_Copy, /*NewInsnID*/0, /*OldInsnID*/1, /*OpIdx*/1, // z
// CHECK-NEXT:       GIR_EraseFromParent, /*InsnID*/0,
// CHECK-NEXT:       GIR_Done,
// CHECK-NEXT:     // Label 9: @536
// CHECK-NEXT:     GIM_Reject,
// CHECK-NEXT:     // Label 2: @537
// CHECK-NEXT:     GIM_Try, /*On fail goto*//*Label 10*/ GIMT_Encode4(578), // Rule ID 5 //
// CHECK-NEXT:       GIM_CheckSimplePredicate, GIMT_Encode2(GICXXPred_Simple_IsRule4Enabled),
// CHECK-NEXT:       // MIs[0] tmp
// CHECK-NEXT:       GIM_RecordInsnIgnoreCopies, /*DefineMI*/1, /*MI*/0, /*OpIdx*/0, // MIs[1]
// CHECK-NEXT:       GIM_CheckOpcode, /*MI*/1, GIMT_Encode2(TargetOpcode::G_ZEXT),
// CHECK-NEXT:       // MIs[1] ext
// CHECK-NEXT:       // No operand predicates
// CHECK-NEXT:       // MIs[0] ptr
// CHECK-NEXT:       // No operand predicates
// CHECK-NEXT:       GIM_CheckIsSafeToFold, /*InsnID*/1,
// CHECK-NEXT:       // Combiner Rule #4: InOutInstTest0
// CHECK-NEXT:       GIR_BuildMI, /*InsnID*/0, /*Opcode*/GIMT_Encode2(TargetOpcode::G_STORE),
// CHECK-NEXT:       GIR_Copy, /*NewInsnID*/0, /*OldInsnID*/1, /*OpIdx*/1, // ext
// CHECK-NEXT:       GIR_Copy, /*NewInsnID*/0, /*OldInsnID*/0, /*OpIdx*/1, // ptr
// CHECK-NEXT:       GIR_MergeMemOperands, /*InsnID*/0, /*NumInsns*/2, /*MergeInsnID's*/0, 1,
// CHECK-NEXT:       GIR_CustomAction, GIMT_Encode2(GICXXCustomAction_CombineApplyGICombiner2),
// CHECK-NEXT:       GIR_EraseFromParent, /*InsnID*/0,
// CHECK-NEXT:       GIR_Done,
// CHECK-NEXT:     // Label 10: @578
// CHECK-NEXT:     GIM_Reject,
// CHECK-NEXT:     // Label 3: @579
// CHECK-NEXT:     GIM_Try, /*On fail goto*//*Label 11*/ GIMT_Encode4(591), // Rule ID 0 //
// CHECK-NEXT:       GIM_CheckSimplePredicate, GIMT_Encode2(GICXXPred_Simple_IsRule0Enabled),
// CHECK-NEXT:       // Combiner Rule #0: WipOpcodeTest0; wip_match_opcode 'G_TRUNC'
// CHECK-NEXT:       GIR_CustomAction, GIMT_Encode2(GICXXCustomAction_CombineApplyGICombiner0),
// CHECK-NEXT:       GIR_Done,
// CHECK-NEXT:     // Label 11: @591
// CHECK-NEXT:     GIM_Try, /*On fail goto*//*Label 12*/ GIMT_Encode4(603), // Rule ID 1 //
// CHECK-NEXT:       GIM_CheckSimplePredicate, GIMT_Encode2(GICXXPred_Simple_IsRule1Enabled),
// CHECK-NEXT:       // Combiner Rule #1: WipOpcodeTest1; wip_match_opcode 'G_TRUNC'
// CHECK-NEXT:       GIR_CustomAction, GIMT_Encode2(GICXXCustomAction_CombineApplyGICombiner0),
// CHECK-NEXT:       GIR_Done,
// CHECK-NEXT:     // Label 12: @603
// CHECK-NEXT:     GIM_Reject,
// CHECK-NEXT:     // Label 4: @604
// CHECK-NEXT:     GIM_Try, /*On fail goto*//*Label 13*/ GIMT_Encode4(616), // Rule ID 2 //
// CHECK-NEXT:       GIM_CheckSimplePredicate, GIMT_Encode2(GICXXPred_Simple_IsRule1Enabled),
// CHECK-NEXT:       // Combiner Rule #1: WipOpcodeTest1; wip_match_opcode 'G_SEXT'
// CHECK-NEXT:       GIR_CustomAction, GIMT_Encode2(GICXXCustomAction_CombineApplyGICombiner0),
// CHECK-NEXT:       GIR_Done,
// CHECK-NEXT:     // Label 13: @616
// CHECK-NEXT:     GIM_Reject,
// CHECK-NEXT:     // Label 5: @617
// CHECK-NEXT:     GIM_Try, /*On fail goto*//*Label 14*/ GIMT_Encode4(656), // Rule ID 7 //
// CHECK-NEXT:       GIM_CheckSimplePredicate, GIMT_Encode2(GICXXPred_Simple_IsRule6Enabled),
// CHECK-NEXT:       // MIs[0] dst
// CHECK-NEXT:       // No operand predicates
// CHECK-NEXT:       // MIs[0] cst
// CHECK-NEXT:       // No operand predicates
// CHECK-NEXT:       GIM_CheckCxxInsnPredicate, /*MI*/0, /*FnId*/GIMT_Encode2(GICXXPred_MI_Predicate_GICombiner1),
// CHECK-NEXT:       GIR_MakeTempReg, /*TempRegID*/0, /*TypeID*/GILLT_s32,
// CHECK-NEXT:       GIR_BuildConstant, /*TempRegID*/0, /*Val*/GIMT_Encode8(0),
// CHECK-NEXT:       // Combiner Rule #6: PatFragTest0 @ [__PatFragTest0_match_1[0]]
// CHECK-NEXT:       GIR_BuildMI, /*InsnID*/0, /*Opcode*/GIMT_Encode2(TargetOpcode::COPY),
// CHECK-NEXT:       GIR_Copy, /*NewInsnID*/0, /*OldInsnID*/0, /*OpIdx*/0, // dst
// CHECK-NEXT:       GIR_AddSimpleTempRegister, /*InsnID*/0, /*TempRegID*/0,
// CHECK-NEXT:       GIR_EraseFromParent, /*InsnID*/0,
// CHECK-NEXT:       GIR_Done,
// CHECK-NEXT:     // Label 14: @656
// CHECK-NEXT:     GIM_Reject,
// CHECK-NEXT:     // Label 6: @657
// CHECK-NEXT:     GIM_Reject,
// CHECK-NEXT:     }; // Size: 658 bytes
// CHECK-NEXT:   return MatchTable0;
// CHECK-NEXT: }
