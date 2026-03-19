# ProMicro NRF52840 Page Turner
NRF52840 (ProMicro form factor) · ZMK firmware · BLE Keyboard HID → Kobo Clara / x4

Breadboard prototype for testing button + EC11 knob layouts before committing to a PCB.

> **Note on pin labels:** This board labels its pads with raw GPIO numbers directly —
> `008` = P0.08, `100` = P1.00, `111` = P1.11, etc. No "D0/D1" style aliases.
> See `boards/shields/page_turner/page_turner.overlay` for exact GPIO assignments.

![Board pinout](promicro-nrf52840-pinout.png)

---

## Hardware

| Part | Qty | Notes |
|---|---|---|
| Nice!Nano v2 | 1 | NRF52840, Pro Micro footprint |
| EC11 rotary encoder | 1–2 | Any standard EC11 with switch |
| Momentary push button | 4–5 | 6mm tactile switches work great on breadboard |
| 10kΩ resistor (optional) | — | Not needed — internal pull-ups are used |
| Breadboard + jumper wires | — | — |
| LiPo battery (optional) | 1 | Nice!Nano has onboard charger |

---

## Wiring (breadboard)

Pin labels on this board are the GPIO numbers directly. All pins below are on the
main through-hole rows — no soldering to underside pads needed.

```
Board label  Side     →   Connect to
──────────────────────────────────────────────────────────────────────
008          LEFT     →   BTN1  one leg  (other leg → GND) — Next Page →
017          LEFT     →   BTN2  one leg  (other leg → GND) — Prev Page ←
020          LEFT     →   BTN3  one leg  (other leg → GND) — Up        ↑
022          LEFT     →   BTN4  one leg  (other leg → GND) — Down      ↓
024          LEFT     →   BTN5  one leg  (other leg → GND) — Select / hold = BT layer

                          EC11 Encoder 1  (primary page turner)
                          ──────────────────────────────────────
011          LEFT     →   ENC1 A
111          RIGHT    →   ENC1 B
             (common) →   GND
100          LEFT     →   ENC1 SW  one leg  (other leg → GND)

                          EC11 Encoder 2  (scroll / chapter jump)
                          ─────────────────────────────────────────
029          RIGHT    →   ENC2 A
010          RIGHT    →   ENC2 B
             (common) →   GND
104          LEFT     →   ENC2 SW  one leg  (other leg → GND)
```

Free through-hole pins for expansion: `006`, `031`, `002`, `115`, `113`

All pin assignments are in `boards/shields/page_turner/page_turner.overlay` — easy to change if you rewire.

---

## Controls

| Input | Action on Kobo |
|---|---|
| BTN1 | Next page (→) |
| BTN2 | Prev page (←) |
| BTN3 | Up arrow |
| BTN4 | Down arrow |
| BTN5 (tap) | Enter / Select |
| BTN5 (hold) | BT management layer |
| ENC1 rotate CW | Next page |
| ENC1 rotate CCW | Prev page |
| ENC1 click | Enter |
| ENC2 rotate CW | Scroll down |
| ENC2 rotate CCW | Scroll up |
| ENC2 click | Escape / Back |

### BT Layer (hold BTN5)

| Input | Action |
|---|---|
| BTN1 | Connect profile 0 (your Kobo) |
| BTN2 | Connect profile 1 |
| BTN3 | Connect profile 2 |
| BTN4 | **Clear/unpair** current profile |
| ENC1 click | Next BT profile |
| ENC2 click | Prev BT profile |

---

## Building

### Option A — GitHub Actions (recommended, no toolchain setup)

1. Fork / push this repo to GitHub.
2. Actions → Build ZMK firmware → Run workflow.
3. Download the `firmware.zip` artifact.
4. Flash `page_turner-nice_nano_v2-zmk.uf2` by double-pressing reset (bootloader mode) and dragging onto the `NICENANO` drive.

### Option B — Local build

```bash
west init -l config
west update
west build -s zmk/app -b nice_nano_v2 -- -DSHIELD=page_turner
```

---

## Pairing with Kobo

1. Flash firmware. Nice!Nano LED will blink rapidly = advertising.
2. On Kobo: Settings → Accessibility → External keyboard → pair.
3. If re-pairing: hold BTN5 → tap BTN4 (clear profile) → restart Kobo BT.

---

## Tuning tips

- **Encoder too sensitive/slow?** Adjust `triggers-per-rotation` in `page_turner.overlay` (lower = faster).
- **Bouncy buttons on breadboard?** Increase `ZMK_KSCAN_DEBOUNCE_PRESS_MS` in `page_turner.conf`.
- **Want PgUp/PgDn instead of arrow keys?** Swap `RIGHT`/`LEFT` for `PG_DN`/`PG_UP` in the keymap — test which Kobo responds to better.
- **Only using 1 encoder?** Comment out `right_encoder` in the overlay and remove it from `sensors`.

---

## File structure

```
NiceNano-PageTurner/
├── config/
│   ├── west.yml            ← ZMK source manifest
│   └── build.yaml          ← board + shield selection
├── boards/shields/page_turner/
│   ├── page_turner.overlay ← GPIO pin assignments (edit this for rewiring)
│   ├── page_turner.keymap  ← all keybindings and layers
│   ├── page_turner.conf    ← encoder + debounce settings
│   ├── Kconfig.shield      ← shield name declaration
│   └── Kconfig.defconfig   ← keyboard name + poll config
└── .github/workflows/
    └── build.yml           ← GitHub Actions CI build
```
