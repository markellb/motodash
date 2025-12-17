#!/usr/bin/env python3

import asyncio
import json
import os
import can
import websockets
import argparse
from datetime import datetime

WS_HOST = "0.0.0.0"
WS_PORT = 8765

clients = set()

# ---------- CAN ----------
def setup_can_interface(iface: str, bitrate: int):
    os.system(f"sudo ip link set {iface} down 2>/dev/null")
    os.system(f"sudo ip link set {iface} up type can bitrate {bitrate}")

def can_reader(iface: str, queue: asyncio.Queue):
    bus = can.Bus(channel=iface, interface="socketcan")
    for msg in bus:
        payload = {
            "timestamp": datetime.utcnow().isoformat(),
            "id": msg.arbitration_id,
            "is_extended": msg.is_extended_id,
            "dlc": msg.dlc,
            "data": list(msg.data),
        }
        asyncio.run_coroutine_threadsafe(queue.put(payload), loop)

# ---------- WebSocket ----------
async def ws_handler(websocket):
    clients.add(websocket)
    print(f"🟢 Cliente conectado ({len(clients)})")
    try:
        await websocket.wait_closed()
    finally:
        clients.remove(websocket)
        print(f"🔴 Cliente desconectado ({len(clients)})")

async def broadcaster(queue: asyncio.Queue):
    while True:
        msg = await queue.get()
        if clients:
            data = json.dumps(msg)
            await asyncio.gather(
                *(client.send(data) for client in clients),
                return_exceptions=True,
            )

# ---------- Main ----------
async def main(iface: str, bitrate: int):
    setup_can_interface(iface, bitrate)

    queue = asyncio.Queue()

    # Lector CAN en thread separado
    import threading
    t = threading.Thread(target=can_reader, args=(iface, queue), daemon=True)
    t.start()

    # WebSocket server
    async with websockets.serve(ws_handler, WS_HOST, WS_PORT):
        print(f"🚀 WebSocket activo en ws://{WS_HOST}:{WS_PORT}")
        await broadcaster(queue)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--interface", default="can0")
    parser.add_argument("-b", "--bitrate", type=int, default=500000)
    args = parser.parse_args()

    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(main(args.interface, args.bitrate))
    except KeyboardInterrupt:
        print("\nSaliendo…")
        os.system(f"sudo ip link set {args.interface} down")
