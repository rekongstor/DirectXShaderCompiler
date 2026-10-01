// RUN: %dxc -HV 2021 -T cs_6_5 -E main %s | FileCheck %s

// Bitfield members must be reported in the disassembled buffer definitions.
// https://github.com/microsoft/DirectXShaderCompiler/issues/8489

struct PPP {
  uint test : 1;
  uint pad : 31;
};

struct Spill {
  int i0 : 8;
  int i1 : 8;
  int i2 : 8;
  int i3 : 8;
  int i4 : 8; // spills into the second storage integer
  int : 4;    // anonymous bitfield
  int i5 : 5;
  int : 0;
  int i6 : 6; // starts the third storage integer
};

cbuffer Constants : register(b0) {
  PPP inner;
  Spill spill;
};

RWStructuredBuffer<Spill> OB : register(u0);

[numthreads(8, 1, 1)] void main(uint3 tid : SV_DispatchThreadID) {
  OB[tid.x] = spill;
  OB[tid.x].i0 = inner.test + spill.i6;
}

// The storage integer has no HLSL name, so it must not be printed as an
// empty-named field. Each bitfield gets its own line, sharing the byte offset
// of the integer it is packed into.

// CHECK: struct struct.PPP
// CHECK: uint test : 1; ; Offset: 0
// CHECK: uint pad : 31; ; Offset: 0
// CHECK: } inner;

// CHECK: struct struct.Spill
// CHECK: int i0 : 8; ; Offset: 16
// CHECK: int i1 : 8; ; Offset: 16
// CHECK: int i2 : 8; ; Offset: 16
// CHECK: int i3 : 8; ; Offset: 16
// CHECK: int i4 : 8; ; Offset: 20
// CHECK: int : 4; ; Offset: 20
// CHECK: int i5 : 5; ; Offset: 20
// CHECK: int i6 : 6; ; Offset: 24
// CHECK: } spill;

// CHECK: Resource bind info for OB
// CHECK: int i0 : 8; ; Offset: 0
// CHECK: int : 4; ; Offset: 4
// CHECK: int i6 : 6; ; Offset: 8
