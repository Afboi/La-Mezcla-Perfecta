# La-Mezcla-Perfecta 🎮

**Interactive game controller system** — A real-time game scoreboard with backstage control and live display.

## Architecture

This is a **three-part system**:

```
┌──────────────────┐
│  Controller UI   │  (Backstage)
│  (Admin Panel)   │  Sends control events
└────────┬─────────┘
         │ HTTP POST
         │
┌────────▼─────────┐
│  Bun Server      │  Broadcasts SSE events
│  (Event Hub)     │  to all connected viewers
└────────┬─────────┘
         │ SSE stream
         │
┌────────▼─────────┐
│  Live View       │  (Screen Display)
│  + Game Board    │  Shows scores + overlays
└──────────────────┘
```

### Three Interfaces

1. **Controller** (`controller.html`) — Backstage
   - Quick event buttons (game starts, win/fail states)
   - Player names editor (4 pairs)
   - Space toggles (5×4 grid)

2. **Server** (`server.js`) — Bun-based event hub
   - `GET /` → serves live view
   - `GET /controller.html` → serves backstage UI
   - `POST /api/event` → accepts control events
   - `GET /events` → SSE endpoint (broadcasts to all clients)

3. **Live View** (`index.html`) — Screen display
   - Embedded game board (4 pairs × 4 rounds, clickable score board)
   - Animated overlay scenes (triggered by controller)
   - Player names display (updated from controller)
   - Safe margins with animated gradients
   - Particle effects on scene transitions

## Installation

### Requirements
- **Bun** runtime (auto-installs if missing)

### Quick Start

#### Unix/Linux/macOS
```bash
chmod +x iniciar.sh
./iniciar.sh
```

#### Windows (PowerShell)
```powershell
.\iniciar.ps1
```

#### Manual
```bash
bun server.js
```
Then open:
- **Controller:** http://localhost:3000/controller.html
- **Live View:** http://localhost:3000/index.html

## Event Format

The server broadcasts JSON events via SSE. Events are sent by the controller and received by all connected live views.

### Control Event (trigger overlays)
```json
{
  "type": "control",
  "action": "Iniciar Juego 1",
  "ts": 1693401234567
}
```

**Mapped scene texts:**
- `Iniciar Juego 1` → `PRIMER JUEGO: LA COREOGRAFÍA`
- `Iniciar Juego 2` → `SEGUNDO JUEGO: EL CORTEJO`
- `Iniciar Juego 3` → `TERCER JUEGO: LOS GLOBOS`
- `Iniciar Juego 4` → `CUARTO JUEGO: CANTALA SI PUEDES`
- `Pareja Ganadora` → `PAREJA GANADORA`
- `Intento Fallido` → `INTENTO FALLIDO`

### Names Event (update player display)
```json
{
  "type": "names",
  "names": ["Pareja A", "Pareja B", "Pareja C", "Pareja D"],
  "ts": 1693401234567
}
```

### Space Event (toggle grid spaces)
```json
{
  "type": "space",
  "index": 3,
  "value": true,
  "ts": 1693401234567
}
```

**Note:** Space events also update the game board if the space index maps to a casilla (square).

## Usage

### During a Game Session

1. **Start the system** (runs all three parts):
   ```bash
   ./iniciar.sh
   ```

2. **Place on display:**
   - Fullscreen `http://localhost:3000/index.html` on the projection/screen

3. **From backstage controller** (`http://localhost:3000/controller.html`):
   - Enter player names (top form)
   - Click "Iniciar Juego N" to trigger overlay scenes
   - Click squares in the game board to score points
   - Use space toggles to control adjacent UI elements
   - Press ESC in the live view to reset all scores

### Game Board

The embedded board displays:
- **4 rows** (pairs 1–4) × **4 columns** (rounds 1–4)
- Click squares to toggle scores (1 point each)
- Double-click (or enable "Logo x2 mode") final round (ronda4) to toggle 2-point markers
- Totals auto-calculate in the rightmost column

**Mode toggle:** Click the top invisible zone to toggle double-logo mode (only affects ronda4).

## Overlay Scenes

When you click a "Iniciar Juego" button on the controller:
1. The live view blurs the game board
2. A fullscreen overlay appears with:
   - Big animated text
   - Colored particle burst
   - Auto-hides after ~2.8 seconds

Particle colors are mapped to each scene for visual distinction.

## Layout

### Live View Margins
The live view is designed with **fixed side/top/bottom panels**:
- Game board: 1536×1024 (centered, 16:9)
- Left/right margins: 256px (animated gradients)
- Top/bottom margins: 256px (animated gradients)
- Gradients fade and wave smoothly
- Responsive: margins scale down on small screens

### Player Names Display
- Top border shows current player pair names
- Updated in real-time from controller
- Format: `Pair 1 · Pair 2 · Pair 3 · Pair 4`

## API Reference

### POST /api/event
Send an event to all connected clients.

**Request:**
```bash
curl -X POST http://localhost:3000/api/event \
  -H "Content-Type: application/json" \
  -d '{"type":"control","action":"Iniciar Juego 1","ts":1693401234567}'
```

**Response:**
```json
{ "ok": true }
```

### GET /events
Server-Sent Events endpoint. Connect with:
```javascript
const es = new EventSource('http://localhost:3000/events');
es.onmessage = (e) => {
  const event = JSON.parse(e.data);
  console.log('Received:', event);
};
```

## Customization

### Change Port
```bash
PORT=8080 bun server.js
```

### Modify Overlay Texts
Edit `index.html`, search for `const map =` in the scene overlay logic (~line 419).

### Adjust Margin Sizes
Edit `index.html`, CSS variable `--margin-size` (default: 256px).

### Game Board Styling
Modify `.embedded-game` CSS classes in `index.html`.

## Troubleshooting

### Server won't start
- Check that Bun is installed: `bun --version`
- Verify port 3000 is not in use: `lsof -i :3000`
- Try a different port: `PORT=3001 bun server.js`

### Overlay doesn't appear on live view
- Confirm browser is at `http://localhost:3000/index.html` (not file://)
- Check browser console (F12) for errors
- Verify SSE connection: you should see "Connected to events" in the top border

### Images not loading
- Ensure `resources/` folder contains `Logo.png`, `Logo2.png`, `Plantilla.jpg`
- Server must be run from the repo root

### Particle effects frozen
- Check GPU acceleration is enabled in browser
- Try Firefox if Chrome/Edge fails
- Reduce particle count in code if performance is poor

## Production Considerations

1. **Authentication** — Add origin checks and/or API keys for the `/api/event` endpoint
2. **Persistence** — Currently scores reset on page reload; add LocalStorage or a database if needed
3. **CORS** — Restrict cross-origin requests if hosting remotely
4. **Scaling** — Current SSE scales to ~500 concurrent clients; use a proper WebSocket library for larger audiences
5. **Branding** — Replace Logo.png, Logo2.png, Plantilla.jpg with your own assets

## License

All files in this repository are provided as-is.

---

**Questions or issues?** Check the event flow in browser DevTools (F12 → Network → EventSource, Console logs).
