#!/usr/bin/env python3
"""
Socket.IO Client Test Script
Tests the Python Socket.IO server endpoints with /socket prefix
"""

import socketio
import asyncio
import aiohttp
import json
from datetime import datetime

# Socket.IO client
sio = socketio.AsyncClient()

# Test configuration
BASE_URL = "http://localhost:30080"
SOCKET_URL = "http://localhost:30080/socket"  # Updated with /socket prefix

async def test_health_endpoint():
    """Test the health endpoint via KrakenD"""
    print("🔍 Testing Health Endpoint...")
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{BASE_URL}/health") as response:
                print(f"   Status: {response.status}")
                if response.status == 200:
                    data = await response.json()
                    print(f"   Response: {json.dumps(data, indent=2)}")
                    return True
                else:
                    print(f"   Error: {await response.text()}")
                    return False
    except Exception as e:
        print(f"   Error: {e}")
        return False

async def test_status_endpoint():
    """Test the status endpoint via KrakenD"""
    print("🔍 Testing Status Endpoint...")
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{BASE_URL}/status") as response:
                print(f"   Status: {response.status}")
                if response.status == 200:
                    data = await response.json()
                    print(f"   Response: {json.dumps(data, indent=2)}")
                    return True
                else:
                    print(f"   Error: {await response.text()}")
                    return False
    except Exception as e:
        print(f"   Error: {e}")
        return False

@sio.event
async def connect():
    """Called when connected to the server"""
    print("✅ Connected to Socket.IO server!")
    print(f"   Session ID: {sio.sid}")

@sio.event
async def disconnect():
    """Called when disconnected from the server"""
    print("❌ Disconnected from Socket.IO server")

@sio.event
async def message(data):
    """Called when receiving a message from the server"""
    print(f"📨 Received message: {data}")

@sio.event
async def update(data):
    """Called when receiving an update from the server"""
    print(f"🔄 Received update: {data}")

async def test_socketio_connection():
    """Test Socket.IO WebSocket connection"""
    print("🔌 Testing Socket.IO Connection...")
    try:
        await sio.connect(SOCKET_URL)
        
        # Wait for connection
        await asyncio.sleep(2)
        
        # Send a test message
        await sio.emit('test_message', {'message': 'Hello from Python client!'})
        print("   Sent test message")
        
        # Wait for background updates
        print("   Waiting for background updates...")
        await asyncio.sleep(15)  # Wait for potential updates
        
        # Disconnect
        await sio.disconnect()
        return True
        
    except Exception as e:
        print(f"   Error: {e}")
        return False

async def main():
    """Main test function"""
    print("🚀 Starting Socket.IO Server Tests (with /socket prefix)")
    print("=" * 60)
    
    # Test HTTP endpoints
    health_success = await test_health_endpoint()
    print()
    
    status_success = await test_status_endpoint()
    print()
    
    # Test Socket.IO connection
    socket_success = await test_socketio_connection()
    print()
    
    # Summary
    print("=" * 60)
    print("📊 Test Results Summary:")
    print(f"   Health Endpoint: {'✅ PASS' if health_success else '❌ FAIL'}")
    print(f"   Status Endpoint: {'✅ PASS' if status_success else '❌ FAIL'}")
    print(f"   Socket.IO Connection: {'✅ PASS' if socket_success else '❌ FAIL'}")
    
    if all([health_success, status_success, socket_success]):
        print("\n🎉 All tests passed! Your Socket.IO server is working correctly.")
    else:
        print("\n⚠️  Some tests failed. Check the logs above for details.")

if __name__ == "__main__":
    asyncio.run(main()) 