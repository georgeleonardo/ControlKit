# ControlKit

A World of Warcraft addon for Vanilla (1.12.x) that displays Xbox controller glyph icons on action bar buttons, replacing the default hotkey text with intuitive controller button visuals.

![WoW Version](https://img.shields.io/badge/WoW-1.12.x%20Vanilla-yellow)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- **Controller glyph overlays** on action bar buttons showing Xbox-style icons
- **Multi-bar support** for three action bars:
  - Main Action Bar (no modifier)
  - Bottom Left Bar with **LB (Shift)** modifier display
  - Bottom Right Bar with **RB (Alt)** modifier display
- **Composite glyph display** showing modifier + button combinations (e.g., LB + RT)
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
| 3 | L3 | L-Stick | LB + L-Stick | RB + L-Stick |
| 4 | R3 | R-Stick | LB + R-Stick | RB + R-Stick |
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
| `/ck` | Show help and available commands |
| `/ck scale <number>` | Set glyph scale (0.1 - 5.0, default: 1.0) |
| `/ck reset` | Reset to default settings |
| `/ck status` | Show current settings |

## Credits

- Controller glyph assets sourced from [ConsolePort](https://github.com/seblindfors/ConsolePort) by seblindfors

## License

MIT License - Feel free to use, modify, and distribute.

