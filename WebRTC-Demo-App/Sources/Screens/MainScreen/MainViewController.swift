//
//  ViewController.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit
import AVFoundation
import WebRTC

class MainViewController: UIViewController {

    private var signalClient: SignalingClient?
    private let webRTCClient: WebRTCClient
    private var touchControls: TouchControls?
    private var enlargedVideo : Bool

    // A timer used for mocking sending high frequency of data channel messages
    private var mockTimer : Timer? = nil
    
    // static labels
    @IBOutlet private weak var signalingStatusText: UILabel?
    @IBOutlet private weak var localSDPText: UILabel?
    @IBOutlet private weak var localCandidatesText: UILabel?
    @IBOutlet private weak var remoteSDPText: UILabel?
    @IBOutlet private weak var remoteCandidatesText: UILabel?
    @IBOutlet private weak var webrtcStatusText: UILabel?
    @IBOutlet private weak var signalingAddressText: UILabel?
    @IBOutlet private weak var videoQualityText: UILabel?
    
    // text fields
    @IBOutlet private weak var signalingAddressTextField: UITextField?
    
    // buttons
    @IBOutlet private weak var connectButton: UIButton?
    @IBOutlet private weak var speakerButton: UIButton?
    @IBOutlet private weak var fullscreenButton: UIButton?
    
    // rtc video
    @IBOutlet private weak var webRTCView: WebRTCView?
    
    private var signalingConnected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.signalingConnected {
                    self.signalingStatusText?.text = "Signaling status: Connected"
                    self.signalingStatusText?.textColor = UIColor.green
                }
                else {
                    self.signalingStatusText?.text = "Signaling status: Not connected"
                    self.signalingStatusText?.textColor = UIColor.red
                }
            }
        }
    }
    
    private var quality: String = "N/A" {
        didSet {
            DispatchQueue.main.async {
                self.videoQualityText?.text = "Video quality: \(self.quality)"
            }
        }
    }
    
    private var hasLocalSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.localSDPText?.text = self.hasLocalSdp ? "Local SDP: ✅" : "Local SDP: ❌"
            }
        }
    }
    
    private var localCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.localCandidatesText?.text = "Local candidates: \(self.localCandidateCount)"
            }
        }
    }
    
    private var hasRemoteSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.remoteSDPText?.text = self.hasRemoteSdp ? "Remote SDP: ✅" : "Remote SDP: ❌"
            }
        }
    }
    
    private var remoteCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.remoteCandidatesText?.text = "Remote Candidates: \(self.remoteCandidateCount)"
            }
        }
    }
    
    private var speakerOn: Bool = true {
        didSet {
            let title = "Speaker: \(self.speakerOn ? "On" : "Off" )"
            self.speakerButton?.setTitle(title, for: .normal)
        }
    }
    
    init(webRTCClient: WebRTCClient) {
        self.webRTCClient = webRTCClient
        self.enlargedVideo = false
        super.init(nibName: String(describing: MainViewController.self), bundle: Bundle.main)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetUI()
        self.webRTCClient.delegate = self
    }
    
    @IBAction func connectButtonTapped(_ sender: UIButton) {
        
        // close any existing signalling client so we don't spam streamer with dead connections
        closeSignalingClient()
        
        let signalingStr : String = signalingAddressTextField?.text ?? "ws://127.0.0.1:80"
        let signalingUrl : URL? = URL(string: signalingStr)
        if let signalingUrl = signalingUrl {
            let client = createSignalingClient(url: signalingUrl)
            client.delegate = self
            self.signalClient = client
            client.connect()
        } else {
            debugPrint("The url string passed was an invalid url - \(signalingStr)")
        }
    }
    
    @IBAction func fullscreenTapped() {
        self.enlargedVideo = !self.enlargedVideo
        self.signalingStatusText?.isHidden = self.enlargedVideo
        self.localSDPText?.isHidden = self.enlargedVideo
        self.localCandidatesText?.isHidden = self.enlargedVideo
        self.remoteSDPText?.isHidden = self.enlargedVideo
        self.remoteCandidatesText?.isHidden = self.enlargedVideo
        self.webrtcStatusText?.isHidden = self.enlargedVideo
        self.signalingAddressText?.isHidden = self.enlargedVideo
        self.videoQualityText?.isHidden = self.enlargedVideo
        self.signalingAddressTextField?.isHidden = self.enlargedVideo
        self.connectButton?.isHidden = self.enlargedVideo
        self.speakerButton?.isHidden = self.enlargedVideo
    }
    
    func resetUI() {
        self.signalingConnected = false
        self.hasLocalSdp = false
        self.hasRemoteSdp = false
        self.localCandidateCount = 0
        self.remoteCandidateCount = 0
        self.speakerOn = true
        self.webrtcStatusText?.text = "WebRTC status: New"
        self.quality = "N/A"
    }
    
    func closeSignalingClient() {
        // close any existing signaling client - we should only have one active
        if let existingClient = self.signalClient {
            existingClient.close()
            resetUI()
        }
    }
    
    func createSignalingClient(url: URL) -> SignalingClient {
        
        closeSignalingClient()
        
        // We will use 3rd party library for websockets.
        let webSocketProvider: WebSocketProvider
        
        if #available(iOS 13.0, *) {
            webSocketProvider = NativeWebSocketProvider(url: url, timeout: 2.0)
        } else {
            webSocketProvider = StarscreamWebSocket(url: url)
        }
        
        let client : SignalingClient = SignalingClient(webSocket: webSocketProvider)
        return client
    }
    
    @IBAction private func speakerDidTap(_ sender: UIButton) {
        if self.speakerOn {
            self.webRTCClient.speakerOff()
        }
        else {
            self.webRTCClient.speakerOn()
        }
        self.speakerOn = !self.speakerOn
    }
    
}

extension MainViewController: SignalClientDelegate {
    
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        self.signalingConnected = true
        print("Connected to signaling server")
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient, error: Error?) {
        self.signalingConnected = false
        print("Disconnected from signaling server")
    }
    
    func signalClientDidReceiveError(_ signalClient: SignalingClient, error: Error?) {
        if error != nil {
            debugPrint("Signalling got error: \(error!)")
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveConfig config: RTCConfiguration) {
        print("Received peer connection configuration - ICE servers: \(config.iceServers)")
        self.webRTCClient.setupPeerConnection(rtcConfiguration: config)
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        
        var sdpTypeStr : String = ""
        switch sdp.type {
        case RTCSdpType.answer:
            sdpTypeStr = "answer"
        case RTCSdpType.offer:
            sdpTypeStr = "offer"
        case RTCSdpType.prAnswer:
            sdpTypeStr = "prAnswer"
        case RTCSdpType.rollback:
            sdpTypeStr = "rollback"
        @unknown default:
            sdpTypeStr = "unknown"
        }
        
        print("Received remote sdp. Type=\(sdpTypeStr)")
        print(sdp.sdp)
        
        if self.webRTCClient.hasPeerConnnection() {
            self.webRTCClient.handleRemoteSdp(remoteSdp: sdp) { (error) in
                self.hasRemoteSdp = true
                
                // If we get an offer from the streamer we send an answer back
                if sdp.type == RTCSdpType.offer {
                    self.signalClientSendAnswer(signalClient)
                }
                else {
                    debugPrint("We only support replying to offer, but we got \(sdpTypeStr)")
                }
            }
        } else {
            debugPrint("WebRTC peer connection not setup yet - cannot handle remote sdp.")
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        print("Received remote candidate - \(candidate.sdp)")
        
        if self.webRTCClient.hasPeerConnnection() {
            self.webRTCClient.handleRemoteCandidate(remoteCandidate: candidate) { error in
                self.remoteCandidateCount += 1
            }
        } else {
            debugPrint("WebRTC peer connection not setup yet - cannot handle remote candidate")
        }
    }
    
    func signalClientSendAnswer(_ signalClient: SignalingClient){
        if self.webRTCClient.hasPeerConnnection() {
            print("Sending answer sdp")
            self.webRTCClient.answer { (localSdp) in
                print(localSdp.sdp)
                self.hasLocalSdp = true
                signalClient.send(sdp: localSdp)
            }
        } else {
            debugPrint("WebRTC peer connection not setup yet - cannot handle sending answer.")
        }
    }
    
}

extension MainViewController: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, onStartReceiveVideo video: RTCVideoTrack) {
        self.touchControls = TouchControls(self.webRTCClient, touchView: self.webRTCView!.videoView)
        webRTCView!.attachVideoTrack(track: video)
        webRTCView!.attachTouchDelegate(delegate: self.touchControls!)
    }
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        self.localCandidateCount += 1
        self.signalClient?.send(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: UIColor
        switch state {
        case .connected:
            
            // WebRTC connection is "connected" so try to show remote video track if we got one some time during the connection
            // IMPORTANT: Even though we do the same in onStartReceiveVideo above, this one actually makes the video show up due
            // peer connection needing to be connected before video can reasonably be displayed - the other callback is more useful
            // if video is added later on into the call.
            if let videoTrack = self.webRTCClient.getRemoteVideoTrack() {
                webRTCView!.attachVideoTrack(track: videoTrack)
            } else {
                debugPrint("Could not attach video track - there was no valid remoteVideoTrack yet.")
            }
            
            DispatchQueue.main.async {
                // Start sending mock data down the data channel at roughly 60fps
                self.mockTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
                    self.sendMockData()
                }
            }
            
            textColor = .green
            
        case .completed:
            textColor = .green
        case .disconnected:
            
            DispatchQueue.main.async {
                // end the mock timer if we disconnected
                if let mockTimer = self.mockTimer {
                    mockTimer.invalidate()
                }
            }
            
            textColor = .orange
        case .failed, .closed:
            textColor = .red
        case .new, .checking, .count:
            textColor = .black
        @unknown default:
            textColor = .black
        }
        DispatchQueue.main.async {
            self.webrtcStatusText?.text = "WebRTC status: \(state.description.capitalized)"
            self.webrtcStatusText?.textColor = textColor
        }
    }
    
    func sendMockData() {
        // ToDo: Replace this with sending back meaningful data
        let bytes: [UInt8] = [50] // 50 is a special message type for json data, we'll use this as an example of sending data back
        let data = Data(bytes)
        self.webRTCClient.sendData(data)
        //debugPrint("Sending mock data to UE")
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        
        if(data.count > 0) {
            let payloadTypeInt : UInt8 = data[0]
            if let payloadType = PixelStreamingToClientMessage(rawValue: payloadTypeInt) {
                switch payloadType {
                case .VideoEncoderAvgQP:
                    let qp : String? = String(data: data.dropFirst(), encoding: .utf16LittleEndian)
                    self.quality = qp ?? "N/A"
                case .QualityControlOwnership:
                    fallthrough
                case .Response:
                    fallthrough
                case .Command:
                    fallthrough
                case .FreezeFrame:
                    fallthrough
                case .UnfreezeFrame:
                    fallthrough
                case .LatencyTest:
                    fallthrough
                case .InitialSettings:
                    fallthrough
                case .FileExtension:
                    fallthrough
                case .FileMimeType:
                    fallthrough
                case .FileContents:
                    print("Skipping payload type \(payloadType) - we have no implementation for it.")
                }
            }
        }
    }
}

