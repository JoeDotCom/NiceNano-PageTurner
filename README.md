# ProMicro NRF52840 Page Turner
NRF52840 (Nice!Nano v2, ProMicro form factor) · ZMK firmware · BLE Keyboard HID → e-reader

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
| LiPo battery | 1 | Nice!Nano has onboard charger. 100mAh gives ~10–20 hrs with sleep disabled. |
| Battery switch (recommended) | 1 | Small slide switch on battery + lead — hardware off when not in use |
| Breadboard + jumper wires | — | — |

> **Battery note:** Deep sleep is disabled in this firmware to prevent the reader dropping
> the BLE connection mid-session. A hardware switch on the battery positive lead is the
> recommended way to preserve battery when the device is packed away.

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
011          LEFT     →   ENC1 A  (3-pin side, outer)
100          LEFT     →   ENC1 B  (3-pin side, outer)
             (common) →   GND     (3-pin side, centre)
111          RIGHT    →   ENC1 SW  one leg  (2-pin side, other leg → GND)

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

### Default layer

| Input | Action on reader |
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

### SYS layer (hold BTN5)

| Input | Action | LED feedback |
|---|---|---|
| BTN1 | Switch to BT profile 0 | 1 blink |
| BTN2 | Switch to BT profile 1 | 2 blinks |
| BTN3 | Switch to BT profile 2 | 3 blinks |
| BTN4 | Clear / unpair current profile | — |
| ENC1 click | Enter bootloader (flash mode) | — |
| ENC2 click | Previous BT profile | — |

> **Flash mode tip:** Holding BTN5 + clicking ENC1 enters the bootloader and mounts the
> `NICENANO` drive on your computer. Alternatively, double-press the physical reset button
> on the board — this always works regardless of firmware state.

---

## BT Profiles

Up to 3 devices can be paired simultaneously (profiles 0–2). The LED blinks tell you
which profile is active after switching:

- **1 blink** = Profile 0
- **2 blinks** = Profile 1
- **3 blinks** = Profile 2

To pair a new device to a profile: hold BTN5 → tap BTN4 (clear current profile) →
then pair from the new device's Bluetooth settings.

---

## Building

### Option A — GitHub Actions (recommended, no toolchain setup)

1. Push changes to GitHub.
2. Actions → Build ZMK firmware → Run workflow (or push triggers it automatically).
3. Download the `firmware.zip` artifact.
4. Enter bootloader (hold BTN5 + click ENC1, or double-press reset button).
5. Drag `page_turner-nice_nano_v2-zmk.uf2` onto the `NICENANO` drive.

### Option B — Local build

```bash
west init -l config
west update
west build -s zmk/app -b nice_nano_v2 -- -DSHIELD=page_turner
```

---

## Pairing with your reader

1. Flash firmware. Nice!Nano will advertise over BLE.
2. On reader: Settings → Accessibility → External keyboard → pair.
3. The device supports up to 3 paired profiles (see SYS layer above).

---

## Firmware notes

### BLE keep-alive
ZMK's default 30-second idle timeout renegotiates BLE connection parameters when it
fires. Some readers drop the connection when this happens. This firmware sets the idle
timeout to 1 hour and disables deep sleep entirely so the connection stays stable
throughout a reading session.

### Encoder reliability
The EC11 encoder uses its own dedicated processing thread (`OWN_THREAD`) rather than
ZMK's global thread. This prevents encoder pulses being dropped when BLE events are
being processed, eliminating the occasional missed page turn.

### Profile LED feedback
Switching BT profiles (hold BTN5 + BTN1/2/3) blinks the onboard LED N times to confirm
which profile is now active. The LED node is declared in `page_turner.overlay` using
GPIO0 pin 15 (Nice!Nano v2 onboard blue LED).

---

## Tuning tips

- **Encoder direction reversed?** Swap `a-gpios` and `b-gpios` in `page_turner.overlay`, or swap `RIGHT`/`LEFT` in the `inc_dec_kp` sensor bindings in the keymap.
- **Encoder too sensitive/slow?** Adjust `triggers-per-rotation` in `page_turner.overlay` (lower = one keypress per fewer detents = faster).
- **Bouncy buttons on breadboard?** Increase `ZMK_KSCAN_DEBOUNCE_PRESS_MS` in `page_turner.conf`.
- **Want PgUp/PgDn instead of arrow keys?** Swap `RIGHT`/`LEFT` for `PG_DN`/`PG_UP` in the keymap.
- **Only using 1 encoder?** Comment out `right_encoder` in the overlay and remove it from the `sensors` node.
- **Battery life too short?** Re-enable `CONFIG_ZMK_SLEEP=y` and set `CONFIG_ZMK_IDLE_SLEEP_TIMEOUT` — the reader will occasionally need a manual reconnect after idle periods. Or add a hardware power switch on the battery lead.

---

## File structure

```
NiceNano-PageTurner/
├── config/
│   ├── west.yml                    ← ZMK source manifest
│   └── build.yaml                  ← board + shield selection (nice_nano_v2)
└── config/boards/shields/page_turner/
    ├── page_turner.overlay         ← GPIO pin assignments + backlight LED
    ├── page_turner.keymap          ← all keybindings, layers, and profile macros
    ├── page_turner.conf            ← encoder, BLE keep-alive, and LED settings
    ├── Kconfig.shield              ← shield name declaration
    └── Kconfig.defconfig           ← keyboard name + poll config
```
