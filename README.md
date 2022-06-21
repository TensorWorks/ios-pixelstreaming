# iOS Pixel Streaming
A simple native WebRTC demo iOS app using swift that has been modified to work with UE Pixel Streaming. 


## Requirements
1. Xcode 12.1 or later
2. iOS 12 or later
3. Node.js + npm (For running Cirrus Signaling server)  


## Run instructions
1. Run the signaling server using `node cirrus.js` somewhere on your LAN - take note of its LAN address.
2. Run a Pixel Streaming UE application and point it at the signalling server with address with `-PixelStreamingURL=ws://{your-signaling-address}:8888`
3. Build and run the iOS application from this repo (real devices work better than simulator for this).
4. In the iOS app, in the text field for signaling address put in `ws://{your-signaling-address}` (can drop the port as it is connecting over 80 here)
5. Click the connect button in the iOS app
6. Done! You should see streaming.

## Credits:
Most of the code is a heavy modification of https://github.com/stasel/WebRTC-iOS
