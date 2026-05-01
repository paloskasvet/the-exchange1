# The Exchange — Setup Guide

**Global Markets Manipulation Simulator**
A single-player strategy game where you trade, manipulate, and dominate global financial markets.

---

## Quick Start (5 minutes)

### Step 1 — Install Godot 4
Go to: https://godotengine.org/download
Download **Godot Engine 4.x — Standard** (not Mono/C#).
Extract the zip anywhere. It's a single .exe — no installer needed.

### Step 2 — Open the project
1. Launch Godot
2. Click **"Import"**
3. Navigate to the `TheExchange/` folder
4. Select `project.godot`
5. Click **"Import & Edit"**

### Step 3 — Run the game
Press **F5** (or the ▶ Play button in the top-right).
The game will open in a new window.

---

## Controls
| Action | Input |
|---|---|
| Select asset from list | Click ticker in left panel |
| Buy | Set qty → click ▲ BUY |
| Sell | Set qty → click ▼ SELL |
| Open contacts panel | Click 👥 Contacts |
| Pause / Resume | ⏸ Pause button |
| Change game speed | Speed: x1 button (cycles 1/2/5/10×) |

---

## Game Systems

### Market Engine
- 19 assets across Tech, Finance, Energy, Commodities, Indices
- All companies are **fictionalized** (legally distinct from real companies)
- Prices follow geometric Brownian motion + mean reversion + event shocks

### Historical Events
Real-world crises are simulated when the in-game calendar reaches that date:
- **1929** — The Great Crash
- **1973** — OPEC Oil Embargo
- **1987** — Black Monday
- **1997** — Asian Financial Crisis
- **2000** — The Tech Bubble Burst
- **2008** — The Great Recession
- **2020** — Global Pandemic Crash

### Contacts & Manipulation
Unlock NPC contacts by growing your net worth (influence levels 1–5).
Each contact offers manipulation actions: plant rumors, obtain advance rate decisions,
orchestrate short squeezes, or — if you reach the highest tier — trigger coordinated global crashes.

**Influence levels:**
| Level | Net Worth Required |
|---|---|
| 1 | $200K |
| 2 | $500K |
| 3 | $1M |
| 4 | $10M |
| 5 | $50M |

### Starting Capital
You begin with **$100,000**. The game has no set end condition — play until you've
broken every market, or until you go bankrupt.

---

## Project Structure
```
TheExchange/
├── project.godot          — Godot project config
├── icon.svg               — Game icon
├── scenes/
│   └── Main.tscn          — Main scene (minimal, all UI built in code)
└── scripts/
	├── GameState.gd        — Global state, time, player cash (Autoload)
	├── MarketEngine.gd     — Price simulation, 19 assets (Autoload)
	├── NewsSystem.gd       — Events, historical crises, dynamic news (Autoload)
	├── Portfolio.gd        — Buy/sell, positions, P&L (Autoload)
	├── ContactsSystem.gd   — NPC contacts, manipulation actions (Autoload)
	├── ChartControl.gd     — Custom price chart renderer
	└── Main.gd             — Main scene controller, entire UI
```

---

## Legal Note
All company names and tickers in this game are fictional and do not represent real companies.
Any resemblance to real corporations is coincidental. Historical event names are used
for educational/creative purposes under fair use.

---

## Next Steps (future development)
- [ ] Short selling
- [ ] Options / derivatives
- [ ] Multiple save slots
- [ ] Steam Achievements integration (Steamworks SDK)
- [ ] Sound design
- [ ] Expanded contact tree
- [ ] Player office / desk scene
- [ ] Steam Workshop for custom event packs
