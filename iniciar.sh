#!/bin/bash

# La-Mezcla-Perfecta: Bun server + livestream game controller
# Unix/Linux/macOS start script

set -e

echo "🎮 La-Mezcla-Perfecta - Game Controller System"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if Bun is installed
if ! command -v bun &> /dev/null; then
    echo "📦 Bun not found. Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
fi

# Start the Bun server
PORT=${PORT:-3000}
echo "🚀 Starting Bun server on port $PORT..."
bun server.js &
BUN_PID=$!

# Wait for server to be ready
echo "⏳ Waiting for server to start..."
for i in {1..30}; do
    if curl -s "http://localhost:$PORT/controller.html" > /dev/null 2>&1; then
        echo "✅ Server ready!"
        break
    fi
    sleep 0.5
done

# Open browsers
echo "🌐 Opening browsers..."

if command -v xdg-open &> /dev/null; then
    # Linux
    xdg-open "http://localhost:$PORT/controller.html" 2>/dev/null &
    xdg-open "http://localhost:$PORT/index.html" 2>/dev/null &
elif command -v open &> /dev/null; then
    # macOS
    open "http://localhost:$PORT/controller.html"
    open "http://localhost:$PORT/index.html"
else
    echo "📋 Open these URLs manually:"
    echo "   Controller (Backstage): http://localhost:$PORT/controller.html"
    echo "   Live View (Screen):     http://localhost:$PORT/index.html"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎬 System running. Press Ctrl+C to stop."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Wait for Ctrl+C
trap "kill $BUN_PID 2>/dev/null; echo '⛔ Server stopped.'; exit 0" INT TERM

wait $BUN_PID
