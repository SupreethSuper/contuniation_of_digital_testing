# Verichip Testbench Debug Report

## Simulation Output

```
bad read, got 0000 but expected ffff  at   30000
bad read, got ffff but expected 30ff  at   60000
bad read, got ffff but expected ff30  at   80000
good read, got ffff and expected ffff at  100000
```

---

## Root Cause: Write and Read in the Same Clock Edge

Every failing test performs a **`SET_WRITE` and `SET_READ` (+ `CHECK_VAL`) in the same `@(negedge clk)` block**. This means both the write-bus signals and the read-bus signals are driven at the *same* simulation instant (the negedge). The `verichip` registers update on the **next `posedge clk`**, so the read sees the *old* register value — not the value just written.

### Timing Diagram

```
        negedge          posedge          negedge
  ─────────┤─────────────────┤─────────────────┤──
           │                 │                 │
  SET_WRITE signals driven   │  Register       │
  SET_READ signals driven    │  latches the    │
  CHECK_VAL reads data_out   │  write here     │
  (sees OLD value) ──────────┘                 │
                                               │
                                  A read HERE would
                                  see the new value
```

---

## Error-by-Error Breakdown

### Error 1 — `bad read, got 0000 but expected ffff at 30000`

**Testbench lines 124-127:**
```systemverilog
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hFF_FF)
```

| Detail | Value |
|--------|-------|
| **Expected** | `ffff` |
| **Got** | `0000` |
| **Why** | `alu_left` is `0000` after reset. The write of `FFFF` and the read happen on the same negedge. The register hasn't been clocked yet, so `data_out` still reflects the reset value `0000`. |

---

### Error 2 — `bad read, got ffff but expected 30ff at 60000`

**Testbench lines 134-138:**
```systemverilog
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h30_CD, 2'b10, 1'b1)   // high-byte only
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
   `CHECK_VAL(16'h30_FF)
```

| Detail | Value |
|--------|-------|
| **Expected** | `30ff` (high byte `30`, low byte `FF` kept from prior write) |
| **Got** | `ffff` (the *previous* full value of `alu_left`) |
| **Why** | Same issue — the partial write (`byte_en=2'b10`, high byte only) hasn't been clocked in yet. `alu_left` still holds `FFFF` from the previous cycle. |

---

### Error 3 — `bad read, got ffff but expected ff30 at 80000`

**Testbench lines 142-146:**
```systemverilog
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hCD_30, 2'b01, 1'b1)   // low-byte only
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
   `CHECK_VAL(16'hFF_30)
```

| Detail | Value |
|--------|-------|
| **Expected** | `ff30` (low byte `30`, high byte `FF` kept) |
| **Got** | `ffff` (value restored by the full write on line 141) |
| **Why** | Identical timing issue. The low-byte partial write hasn't been latched. |

---

### Pass 4 — `good read, got ffff and expected ffff at 100000`

**Testbench lines 150-153:**
```systemverilog
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hCD_30, 2'b00, 1'b1)   // byte_en = 00 → NO bytes written
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
   `CHECK_VAL(16'hFF_FF)
```

This passes *by accident*: `byte_en = 2'b00` means neither byte is actually written, so `alu_left` stays `FFFF`. The read-back of `FFFF` matches the expected value, hiding the timing bug.

---

## The Fix

**Separate the write and the read into different clock cycles.** Drive the write on one negedge, wait for the posedge to latch it, then read on the following negedge.

### Corrected Pattern

```systemverilog
// ── Write cycle ──
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1)

// ── Read cycle (register is now updated) ──
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hFF_FF)
```

### Fixed Testbench Stimulus (full replacement for lines 119–154)

```systemverilog
@(negedge clk)
   maroon <= 1'b0;
@(negedge clk)
   gold <= 1'b1;

// ── Test 1: Full write FFFF, then read back ──
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hFF_FF)
@(negedge clk)
   `CLEAR_BUS

// ── Restore FFFF for partial-write tests ──
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1)

// ── Test 2: Partial high-byte write (byte_en=10), expect 30FF ──
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h30_CD, 2'b10, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h30_FF)
   `CLEAR_BUS

// ── Restore FFFF ──
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1)

// ── Test 3: Partial low-byte write (byte_en=01), expect FF30 ──
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hCD_30, 2'b01, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hFF_30)
   `CLEAR_BUS

// ── Restore FFFF ──
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1)

// ── Test 4: No-byte write (byte_en=00), expect FFFF unchanged ──
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hCD_30, 2'b00, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hFF_FF)
   `CLEAR_BUS
```

> [!TIP]
> The key rule: **always allow at least one `posedge clk` between a write and its corresponding read** so the register has time to latch the new value.
