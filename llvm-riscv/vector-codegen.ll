; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 2
; RUN: llc -mtriple=riscv64 -mattr=+v < %s | FileCheck %s

define <4 x i32> @insert_subvector_load(<4 x i32> %v1, ptr %p) {
; CHECK-LABEL: insert_subvector_load:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e32, mf2, ta, ma
; CHECK-NEXT:    vle32.v v9, (a0)
; CHECK-NEXT:    vsetivli zero, 2, e32, m1, tu, ma
; CHECK-NEXT:    vmv.v.v v8, v9
; CHECK-NEXT:    ret
  %v2 = load <2 x i32>, ptr %p
  %v3 = shufflevector <2 x i32> %v2, <2 x i32> poison, <4 x i32> <i32 0, i32 1, i32 undef, i32 undef>
  %v4 = shufflevector <4 x i32> %v3, <4 x i32> %v1, <4 x i32> <i32 0, i32 1, i32 6, i32 7>
  ret <4 x i32> %v4
}

; TODO: This is a type cast reverse on a <2 x i64>, can we do better here?
define <4 x i32> @reverse_high_low(<4 x i32> %a) {
; CHECK-LABEL: reverse_high_low:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; CHECK-NEXT:    vslidedown.vi v9, v8, 2
; CHECK-NEXT:    vslideup.vi v9, v8, 2
; CHECK-NEXT:    vmv.v.v v8, v9
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i32> %a, <4 x i32> poison, <4 x i32> <i32 2, i32 3, i32 0, i32 1>
  ret <4 x i32> %res
}

define <2 x i64> @high_low_elem(<4 x i64> %a) {
; CHECK-LABEL: high_low_elem:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m2, ta, ma
; CHECK-NEXT:    vslidedown.vi v10, v8, 2
; CHECK-NEXT:    vsetivli zero, 1, e64, m1, tu, ma
; CHECK-NEXT:    vmv.v.v v10, v8
; CHECK-NEXT:    vmv1r.v v8, v10
; CHECK-NEXT:    ret
  %res = shufflevector <4 x i64> %a, <4 x i64> poison, <2 x i32> <i32 0, i32 3>
  ret <2 x i64> %res
}

; Using the VID expansion here is really terrible, the result is simply
; 16 bits.  Can be either an insert, or a load from memory.
define <2 x i8> @small_constant() {
; CHECK-LABEL: small_constant:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e8, mf8, ta, ma
; CHECK-NEXT:    vmv.v.i v9, 3
; CHECK-NEXT:    vid.v v8
; CHECK-NEXT:    li a0, 3
; CHECK-NEXT:    vmadd.vx v8, a0, v9
; CHECK-NEXT:    ret
  ret <2 x i8> <i8 3, i8 6>
}


; TODO: We should be able to make the mask op e16 to remove the toggle
define <4 x i16> @vmerge_v4i16_simm5(<4 x i16> %x, <4 x i16> %y) {
; CHECK-LABEL: vmerge_v4i16_simm5:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 4, e16, mf2, ta, ma
; CHECK-NEXT:    vmv.v.i v0, 11
; CHECK-NEXT:    vmerge.vvm v8, v9, v8, v0
; CHECK-NEXT:    ret
  %s = shufflevector <4 x i16> %x, <4 x i16> %y, <4 x i32> <i32 0, i32 1, i32 6, i32 3>
  ret <4 x i16> %s
}

; TODO: This is effectively a build_vector_i8(C1, C2) and thus could be
; handled via a vmv.v.i, + vslide1down/li.  This is probably only profitable
; if one of the two halfs is zero.
define <16 x i16> @vmerge_v16i16(<16 x i16> %x, <16 x i16> %y) {
; CHECK-LABEL: vmerge_v16i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    lui a0, 6
; CHECK-NEXT:    addi a0, a0, -1
; CHECK-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; CHECK-NEXT:    vmv.s.x v0, a0
; CHECK-NEXT:    vmerge.vvm v8, v10, v8, v0
; CHECK-NEXT:    ret
  %s = shufflevector <16 x i16> %x, <16 x i16> %y, <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 29, i32 14, i32 31>
  ret <16 x i16> %s
}


; TODO: The expansion of this shuffle mask is obsurd.  We should be able to
; use either a constant pool load, or a vsext.vfN(load) here.  In theory,
; we only need two bits per element (i.e. 32) if we had a good expansion from
; the compressed form.  Actually, we might be able to do predicate OR for the
; individual bits.  This would require two 16-bit mask constants which aren't
; super cheap though.
define void @shuffle_constant_mask(<16 x ptr> %a, ptr %p) {
; CHECK-LABEL: shuffle_constant_mask:
; CHECK:       # %bb.0:
; CHECK-NEXT:    lui a1, 2
; CHECK-NEXT:    addi a1, a1, 545
; CHECK-NEXT:    vsetivli zero, 1, e16, m1, ta, ma
; CHECK-NEXT:    vmv.s.x v0, a1
; CHECK-NEXT:    vsetivli zero, 16, e8, m1, ta, ma
; CHECK-NEXT:    vmv.v.i v16, 3
; CHECK-NEXT:    vmerge.vim v17, v16, 0, v0
; CHECK-NEXT:    lui a1, 1
; CHECK-NEXT:    addi a1, a1, 274
; CHECK-NEXT:    vsetvli zero, zero, e16, m2, ta, ma
; CHECK-NEXT:    vmv.s.x v0, a1
; CHECK-NEXT:    lui a1, 4
; CHECK-NEXT:    addi a1, a1, 1092
; CHECK-NEXT:    vmv.s.x v16, a1
; CHECK-NEXT:    vsetvli zero, zero, e8, m1, ta, ma
; CHECK-NEXT:    vmerge.vim v17, v17, 1, v0
; CHECK-NEXT:    vmv1r.v v0, v16
; CHECK-NEXT:    vmerge.vim v16, v17, 2, v0
; CHECK-NEXT:    vsetvli zero, zero, e16, m2, ta, ma
; CHECK-NEXT:    vsext.vf2 v18, v16
; CHECK-NEXT:    vsetvli zero, zero, e64, m8, ta, ma
; CHECK-NEXT:    vrgatherei16.vv v24, v8, v18
; CHECK-NEXT:    vse64.v v24, (a0)
; CHECK-NEXT:    ret
  %res = shufflevector <16 x ptr> %a, <16 x ptr> poison, <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 1, i32 0, i32 2, i32 3, i32 1, i32 0, i32 2, i32 3, i32 1, i32 0, i32 2, i32 3>
  store <16 x ptr> %res, ptr %p
  ret void
}

; For these odd types, we could consider using a masked load and store
; to widen the illegal types.
define void @v3i64_vadd(ptr %p) {
; CHECK-LABEL: v3i64_vadd:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 3, e64, m2, ta, ma
; CHECK-NEXT:    vle64.v v8, (a0)
; CHECK-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; CHECK-NEXT:    vadd.vi v8, v8, 1
; CHECK-NEXT:    vsetivli zero, 3, e64, m2, ta, ma
; CHECK-NEXT:    vse64.v v8, (a0)
; CHECK-NEXT:    ret
  %v1 = load <3 x i64>, ptr %p
  %v2 = add <3 x i64> %v1, <i64 1, i64 1, i64 1>
  store <3 x i64> %v2, ptr %p
  ret void
}

define void @v3i64_vadd_elem_aligned(ptr %p) {
; CHECK-LABEL: v3i64_vadd_elem_aligned:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 3, e64, m2, ta, ma
; CHECK-NEXT:    vle64.v v8, (a0)
; CHECK-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; CHECK-NEXT:    vadd.vi v8, v8, 1
; CHECK-NEXT:    vsetivli zero, 3, e64, m2, ta, ma
; CHECK-NEXT:    vse64.v v8, (a0)
; CHECK-NEXT:    ret
  %v1 = load <3 x i64>, ptr %p, align 8
  %v2 = add <3 x i64> %v1, <i64 1, i64 1, i64 1>
  store <3 x i64> %v2, ptr %p, align 8
  ret void
}

define void @v6i64_vadd(ptr %p) {
; CHECK-LABEL: v6i64_vadd:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 6, e64, m4, ta, ma
; CHECK-NEXT:    vle64.v v8, (a0)
; CHECK-NEXT:    vsetivli zero, 8, e64, m4, ta, ma
; CHECK-NEXT:    vadd.vi v8, v8, 1
; CHECK-NEXT:    vsetivli zero, 6, e64, m4, ta, ma
; CHECK-NEXT:    vse64.v v8, (a0)
; CHECK-NEXT:    ret
  %v1 = load <6 x i64>, ptr %p
  %v2 = add <6 x i64> %v1, <i64 1, i64 1, i64 1, i64 1, i64 1, i64 1>
  store <6 x i64> %v2, ptr %p
  ret void
}

; TODO: Can be a slidedown1 + a vfslide1down
define <2 x double> @rotatedown_v2f64_a(<2 x double> %v, double %b) {
; CHECK-LABEL: rotatedown_v2f64_a:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v9, v8, 1
; CHECK-NEXT:    vfmv.s.f v8, fa0
; CHECK-NEXT:    vslideup.vi v9, v8, 1
; CHECK-NEXT:    vmv.v.v v8, v9
; CHECK-NEXT:    ret
  %v1 = shufflevector <2 x double> %v, <2 x double> poison, <2 x i32> <i32 1, i32 1>
  %v2 = insertelement <2 x double> %v1, double %b, i64 1
  ret <2 x double> %v2
}

define <2 x double> @rotatedown_v2f64_b(<2 x double> %v, double %b) {
; CHECK-LABEL: rotatedown_v2f64_b:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v9, v8, 1
; CHECK-NEXT:    vfmv.s.f v8, fa0
; CHECK-NEXT:    vslideup.vi v9, v8, 1
; CHECK-NEXT:    vmv.v.v v8, v9
; CHECK-NEXT:    ret
  %v1 = shufflevector <2 x double> %v, <2 x double> poison, <2 x i32> <i32 1, i32 undef>
  %v2 = insertelement <2 x double> %v1, double %b, i64 1
  ret <2 x double> %v2
}

define <2 x double> @redundant_splat_v2f64_a(<2 x double> %v, double %b) {
; CHECK-LABEL: redundant_splat_v2f64_a:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v9, v8, 0
; CHECK-NEXT:    vfmv.s.f v8, fa0
; CHECK-NEXT:    vslideup.vi v9, v8, 1
; CHECK-NEXT:    vmv.v.v v8, v9
; CHECK-NEXT:    ret
  %v1 = shufflevector <2 x double> %v, <2 x double> poison, <2 x i32> <i32 0, i32 0>
  %v2 = insertelement <2 x double> %v1, double %b, i64 1
  ret <2 x double> %v2
}

; TODO: this should be a single vfslide1up
define <2 x double> @rotateup_v2f64_a(<2 x double> %v, double %b) {
; CHECK-LABEL: rotateup_v2f64_a:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v9, v8, 0
; CHECK-NEXT:    vsetvli zero, zero, e64, m1, tu, ma
; CHECK-NEXT:    vfmv.s.f v9, fa0
; CHECK-NEXT:    vmv1r.v v8, v9
; CHECK-NEXT:    ret
  %v1 = shufflevector <2 x double> %v, <2 x double> poison, <2 x i32> <i32 0, i32 0>
  %v2 = insertelement <2 x double> %v1, double %b, i64 0
  ret <2 x double> %v2
}

; TODO: This shouldn't have to go through the scalar domain!
define <2 x double> @rotatedown_v2f64_c(<2 x double> %v, double %b) {
; CHECK-LABEL: rotatedown_v2f64_c:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vslidedown.vi v8, v8, 1
; CHECK-NEXT:    vfmv.f.s fa5, v8
; CHECK-NEXT:    vfmv.v.f v8, fa5
; CHECK-NEXT:    vfslide1down.vf v8, v8, fa0
; CHECK-NEXT:    ret
  %a = extractelement <2 x double> %v, i64 1
  %v1 = insertelement <2 x double> poison, double %a, i64 0
  %v2 = insertelement <2 x double> %v1, double %b, i64 1
  ret <2 x double> %v2
}

define <4 x double> @rotatedown_42f64_2(<4 x double> %v, double %b) {
; CHECK-LABEL: rotatedown_42f64_2:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; CHECK-NEXT:    vslidedown.vi v8, v8, 1
; CHECK-NEXT:    vfmv.s.f v10, fa0
; CHECK-NEXT:    vslideup.vi v8, v10, 3
; CHECK-NEXT:    ret
  %v1 = shufflevector <4 x double> %v, <4 x double> poison, <4 x i32> <i32 1, i32 2, i32 3, i32 undef>
  %v2 = insertelement <4 x double> %v1, double %b, i64 3
  ret <4 x double> %v2
}

; TODO: Consider using PerfectShuffle tool for VF=4?
