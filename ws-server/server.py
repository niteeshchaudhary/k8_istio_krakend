import socketio
import uvicorn
import asyncio
from datetime import datetime
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse

# Create FastAPI app
app = FastAPI()

# Create Socket.IO server
sio = socketio.AsyncServer(async_mode="asgi", cors_allowed_origins="*")

COUNTER = 0
BACKGROUND_TASK: asyncio.Task | None = None
CONNECTED_CLIENTS = 0
WEBSOCKET_CLIENTS = []

# When a client connects, we start the background task to send updates
@sio.event
async def connect(sid, environ):
    global BACKGROUND_TASK, CONNECTED_CLIENTS
    CONNECTED_CLIENTS += 1
    print(f"Client connected: {sid}, total clients: {CONNECTED_CLIENTS}")
    await sio.emit("message", {"data": f"Welcome to the server - {sid}"}, to=sid)

    if BACKGROUND_TASK is None or BACKGROUND_TASK.done():
        await sio.emit("message", {"data": "Background task started"})
        BACKGROUND_TASK = sio.start_background_task(send_updates)
        print("Background task started")

# When a client disconnects, we stop the background task
@sio.event
async def disconnect(sid):
    global BACKGROUND_TASK, CONNECTED_CLIENTS
    CONNECTED_CLIENTS = max(0, CONNECTED_CLIENTS - 1)
    print(f"Client disconnected: {sid}, total clients: {CONNECTED_CLIENTS}")
    if BACKGROUND_TASK and not BACKGROUND_TASK.done():
        BACKGROUND_TASK.cancel()
        print("Background task stopped")
        BACKGROUND_TASK = None

# This is the background task that sends updates to all connected clients every 10 minutes
async def send_updates():
    global COUNTER
    try:
        while True:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            message = {"update": f"Counter: {COUNTER} at {timestamp}"}
            print(f"Sending update: {message}")
            await sio.emit("update", message)
            COUNTER += 1
            await asyncio.sleep(600) # 10 minutes
    except asyncio.CancelledError:
        print("Background task cancelled")

# Root endpoint (for KrakenD /socket/status routing)
@app.get("/")
async def root():
    return JSONResponse({
        "status": "running",
        "timestamp": datetime.now().isoformat(),
        "service": "ws-server-python",
        "connected_clients": CONNECTED_CLIENTS,
        "counter": COUNTER
    })

# Health endpoint (for KrakenD /socket/health routing)
@app.get("/health")
async def health_check():
    return JSONResponse({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "ws-server-python",
        "connected_clients": CONNECTED_CLIENTS,
        "counter": COUNTER
    })

# WebSocket endpoint (for direct /socket/ws routing)
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    WEBSOCKET_CLIENTS.append(websocket)
    print(f"WebSocket client connected. Total WebSocket clients: {len(WEBSOCKET_CLIENTS)}")
    
    try:
        # Send welcome message
        await websocket.send_text("Welcome to WebSocket endpoint!")
        
        # Keep connection alive and handle messages
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            print(f"Received WebSocket message: {data}")
            
            # Echo back with timestamp
            response = {
                "message": f"Echo: {data}",
                "timestamp": datetime.now().isoformat(),
                "service": "ws-server-python"
            }
            await websocket.send_json(response)
            
    except WebSocketDisconnect:
        print("WebSocket client disconnected")
    except Exception as e:
        print(f"WebSocket error: {e}")
    finally:
        if websocket in WEBSOCKET_CLIENTS:
            WEBSOCKET_CLIENTS.remove(websocket)
        print(f"WebSocket client removed. Total WebSocket clients: {len(WEBSOCKET_CLIENTS)}")

# Create ASGI app that combines FastAPI and Socket.IO
socket_app = socketio.ASGIApp(sio, app)

if __name__ == "__main__":
    uvicorn.run(socket_app, host="0.0.0.0", port=8080) 