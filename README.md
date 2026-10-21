# GBA Pocket - Mobile-First Game Boy Advance Emulator in Flutter

A high-performance, mobile-first Game Boy Advance (GBA) emulator built with Flutter. Designed with tactile mobile thumb controls, authentic retro handheld ergonomics, 60 FPS audio/video emulation, save state slots, real-time shaders, and custom ROM support.

---

## Mobile-First Handheld Experience

- **Dual Orientation Adaptive Layout**:
  - **Portrait Mode**: Handheld SP / Classic layout with screen bevel on top, quick function toolbar in the middle, and tactile D-Pad + angled A/B buttons on the bottom.
  - **Landscape Mode**: Wide horizontal Game Boy Advance layout (centered screen with shoulder L/R triggers, D-Pad on the left thumb zone, and A/B buttons on the right thumb zone).
- **Tactile Virtual Controls**:
  - **8-Way Dynamic D-Pad**: Supports smooth sliding across diagonals (Up-Right, Down-Right, Down-Left, Up-Left) with visual active arm highlights.
  - **Angled A & B Buttons**: Angled ~22° for ergonomic thumb placement, with tactile 3D depression and haptic feedback.
  - **Dual A+B Touch Zone**: Tap directly between A and B to trigger simultaneous jump/attack/action inputs with one thumb.
  - **L & R Shoulder Bumpers**: Positioned naturally at the upper corners of the handheld body.
  - **Select & Start**: Pill-shaped rubber buttons with tactile feedback.
- **Haptic Feedback**: Subtle vibration on button presses (`HapticFeedback.lightImpact()`).

---

## Core Emulation & Audio Features

- **Full 60 FPS Emulation Engine**: Accurate ARM7TDMI 32-bit RISC CPU core (ARM & Thumb instruction sets), Mode 0-5 PPU rendering with background affine transformations, sprites, alpha blending, and DMA timers.
- **Web Audio & Stereo Sound**: Real-time PSG audio channels and DirectSound DMA sample mixing with master volume and mute controls.
- **Fast Forward / Turbo**: Toggle instantly between `1x` (normal 60 FPS), `2x` (fast forward), and `4x` (max turbo).
- **Save States**: 5 instant save slots with Quick Save (`F1` / Save icon) and Quick Load (`F2` / Restore icon).
- **Battery Saves (SRAM/Flash)**: Automatic battery save persistence to local device storage, fully compatible with standard `.sav` files.
- **7 Authentic Console Shell Skins**:
  - Classic Indigo (Launch purple-blue)
  - Glacier (Translucent icy cyan)
  - Atomic Purple (Translucent 90s retro purple)
  - Arctic White (Minimalist clean white with crimson buttons)
  - Flame Red (Arcade crimson with black buttons)
  - Stealth Onyx (Matte titanium black)
  - Triforce Gold (Collector's Zelda edition)
- **Retro Screen Filters**:
  - LCD Pixel Grid (Simulates original GBA front-lit screen subpixel mesh)
  - Crisp Pixel Art (Clean nearest-neighbor upscaling)
  - CRT Scanlines (Subtle arcade television phosphor lines)

---

## Built-In Games & Custom ROMs

The emulator includes two legally redistributable, open-source homebrew games ready to play out of the box with zero setup:
1. **Waimanu: Grinding** (Action platformer by Disjointed Studio)
2. **Yahtzee Advance** (Classic 5-dice strategy game)

### Loading Your Own Games:
- Tap **Settings & ROMs** (gear icon) -> **Load .GBA ROM from Storage**.
- Select any uncompressed `.gba`, `.bin`, or `.agb` ROM file from your phone's Files/Downloads folder or your computer.

---

## Physical Keyboard & Gamepad Mapping

If you connect a physical keyboard, Bluetooth controller, or test on desktop:

| GBA Button | Keyboard Key |
| :--- | :--- |
| **D-Pad Up** | `Up Arrow` or `W` |
| **D-Pad Down** | `Down Arrow` or `S` |
| **D-Pad Left** | `Left Arrow` or `A` |
| **D-Pad Right** | `Right Arrow` or `D` |
| **A Button** | `X` or `K` |
| **B Button** | `Z` or `J` |
| **L Shoulder** | `Q` or `U` |
| **R Shoulder** | `E` or `O` |
| **Start** | `Enter` |
| **Select** | `Space` or `Left Shift` |
| **Turbo Speed** | `Tab` |

---

## Running the Project

### 1. Fix Terminal PATH (If you saw "flutter not recognized")
Flutter is installed on your computer at `C:\src\flutter\bin`. It is already configured in your Windows User PATH.
To make your current PowerShell session recognize `flutter` immediately, run:
```powershell
$env:Path = "C:\src\flutter\bin;" + $env:Path
```

### 2. Run on Mobile Browser / Web
```bash
flutter run -d chrome
# or with edge:
flutter run -d edge
```

### 3. Build & Run on Android
```bash
flutter build appbundle --release
```
