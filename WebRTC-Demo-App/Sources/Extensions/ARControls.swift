//
//  ARControls.swift
//  WebRTC-Demo
//
//  Created by Luke Bermingham on 30/6/2022.
//

import Foundation
import ARKit


// Use ARKit to get device transform and send that over WebRTC
final class ARControls: NSObject, ARSessionDelegate {
    
    let arSession : ARSession
    let arConfiguration : ARWorldTrackingConfiguration
    let arRunOptions : ARSession.RunOptions
    let webRTCClient : WebRTCClient
    
    
    init(_ webRTCClient : WebRTCClient) {
        self.webRTCClient = webRTCClient
        self.arSession = ARSession()
        self.arConfiguration = ARWorldTrackingConfiguration()
        self.arRunOptions = ARSession.RunOptions([.resetTracking, .removeExistingAnchors])
        
        super.init()
        
        self.arSession.delegate = self
        self.restartAR()
    }
    
    func restartAR() {
        self.arSession.run(arConfiguration, options: self.arRunOptions)
    }
    
    // Called when ARFrame is updated
    func session(_ session: ARSession, didUpdate frame: ARFrame){
        
        // Grab the world transform of the iOS device
        let transform : simd_float4x4 = frame.camera.transform
        
        var bytes: [UInt8] = []
        
        // Write message type using 1 byte
        bytes.append(PixelStreamingToStreamerMessage.Transform.rawValue)
        
        // Write 4x4 transform each element to get 4 bytes e.g. float -> [UInt8]
        bytes.append(contentsOf: transform.columns.0.x.toBytes())
        bytes.append(contentsOf: transform.columns.0.y.toBytes())
        bytes.append(contentsOf: transform.columns.0.z.toBytes())
        bytes.append(contentsOf: transform.columns.0.w.toBytes())
        
        bytes.append(contentsOf: transform.columns.1.x.toBytes())
        bytes.append(contentsOf: transform.columns.1.y.toBytes())
        bytes.append(contentsOf: transform.columns.1.z.toBytes())
        bytes.append(contentsOf: transform.columns.1.w.toBytes())
        
        bytes.append(contentsOf: transform.columns.2.x.toBytes())
        bytes.append(contentsOf: transform.columns.2.y.toBytes())
        bytes.append(contentsOf: transform.columns.2.z.toBytes())
        bytes.append(contentsOf: transform.columns.2.w.toBytes())
        
        bytes.append(contentsOf: transform.columns.3.x.toBytes())
        bytes.append(contentsOf: transform.columns.3.y.toBytes())
        bytes.append(contentsOf: transform.columns.3.z.toBytes())
        bytes.append(contentsOf: transform.columns.3.w.toBytes())
        
        // Write timestamp 8 bytes
        let timestamp : Double = CFAbsoluteTimeGetCurrent()
        bytes.append(contentsOf: timestamp.toBytes())
        
        // Send the transform + timestamp across
        let data = Data(bytes)
        self.webRTCClient.sendData(data)
    }

    
}
