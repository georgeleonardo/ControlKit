# ControlKit

A World of Warcraft addon for Vanilla (1.12.x) that displays controller glyph icons on action bar buttons, replacing the default hotkey text with intuitive controller button visuals.

![WoW Version](https://img.shields.io/badge/WoW-1.12.x%20Vanilla-yellow)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- **Multiple controller styles** - Xbox and PlayStation glyph sets
- **Controller glyph overlays** on action bar buttons
- **Multi-bar support** for three action bars:
  - Main Action Bar (no modifier)
  - Bottom Left Bar with **LB/L1 (Shift)** modifier display
  - Bottom Right Bar with **RB/R1 (Alt)** modifier display
- **Composite glyph display** showing modifier + button combinations (e.g., LB + RT)
- **Range indicator** - Glyphs fade to 50% opacity when out of casting range
- **Scalable icons** via slash commands
- Hides default hotkey text for a cleaner look

## Installation

1. Download or clone this repository
2. Copy the `Interface` folder to your WoW directory (e.g., `World of Warcraft/`)
3. The addon should appear at: `World of Warcraft/Interface/AddOns/ControlKit/`
4. Restart WoW or type `/reload` if already in-game

## Button Mapping

| Slot | Button | Main Bar | LB (Shift) Bar | RB (Alt) Bar |
|------|--------|----------|----------------|--------------|
| 1 | LT | LT | LB + LT | RB + LT |
| 2 | RT | RT | LB + RT | RB + RT |
| 3 | P1 | P1 (Left Paddle) | LB + P1 | RB + P1 |
| 4 | P2 | P2 (Right Paddle) | LB + P2 | RB + P2 |
| 5 | A | A | LB + A | RB + A |
| 6 | X | X | LB + X | RB + X |
| 7 | Y | Y | LB + Y | RB + Y |
| 8 | B | B | LB + B | RB + B |
| 9 | D-Down | D-Down | LB + D-Down | RB + D-Down |
| 10 | D-Left | D-Left | LB + D-Left | RB + D-Left |
| 11 | D-Up | D-Up | LB + D-Up | RB + D-Up |
| 12 | D-Right | D-Right | LB + D-Right | RB + D-Right |

## Slash Commands

| Command | Description |
|---------|-------------|
| `/ck` | Open the options panel |
| `/ck config` | Open the options panel |
| `/ck style <xbox\|playstation>` | Switch controller glyph style |
| `/ck scale <number>` | Set glyph scale (0.5 - 2.0, default: 1.0) |
| `/ck reset` | Reset to default settings |
| `/ck status` | Show current settings |
| `/ck help` | Show all available commands |

## Options Panel

Type `/ck` to open the graphical options panel where you can:
- **Select Controller Style** - Choose between Xbox and PlayStation glyphs via dropdown
- **Adjust Glyph Scale** - Use the slider to resize icons (0.5x to 2.0x)
- **Reset** - Restore all settings to defaults

The panel is draggable and closes with ESC.

## Controller Styles

### Xbox (default)
LT, RT, LB, RB, A, B, X, Y, LSB, RSB, D-Pad

### PlayStation
L2, R2, L1, R1, Cross, Circle, Square, Triangle, L3, R3, D-Pad

## Credits

- Controller glyph assets sourced from [ConsolePort](https://github.com/seblindfors/ConsolePort) by seblindfors

## License

MIT License - Feel free to use, modify, and distribute.

