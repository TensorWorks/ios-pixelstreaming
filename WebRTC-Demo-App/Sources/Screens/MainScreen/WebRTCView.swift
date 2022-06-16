//
//  WebRTCView.swift
//  WebRTC-Demo
//
//  Created by Luke Bermingham on 14/6/2022.

import Foundation
import UIKit
import WebRTC

final class WebRTCView: UIView, RTCVideoViewDelegate {
    
    #if targetEnvironment(simulator) || arch(arm64)
    let videoView = RTCEAGLVideoView(frame: .zero)
    #else
    let videoView = RTCMTLVideoView(frame: .zero)
    #endif

    var videoSize = CGSize.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        #if targetEnvironment(simulator) || arch(arm64)
        self.videoView.contentMode = .scaleAspectFit
        #else
        self.videoView.videoContentMode = .scaleAspectFit
        self.videoView.isEnabled = true
        #endif
        
        self.videoView.isHidden = false
        self.videoView.backgroundColor = UIColor.lightGray
        
        videoView.delegate = self
        addSubview(videoView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        videoView.delegate = self
        addSubview(videoView)
    }

    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        self.videoSize = size
        setNeedsLayout()
    }
    
    func attachVideoTrack(track: RTCVideoTrack) {
        track.remove(self.videoView)
        track.add(self.videoView)
        track.isEnabled = true
        self.videoView.renderFrame(nil)

        let trackState : RTCMediaStreamTrackState = track.readyState
        if trackState == RTCMediaStreamTrackState.live {
            print("Video track is live | id=\(track.trackId) | kind=\(track.kind)")
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard videoSize.width > 0 && videoSize.height > 0 else {
            videoView.frame = bounds
            return
        }

        var videoFrame = AVMakeRect(aspectRatio: videoSize, insideRect: bounds)
        let scale = videoFrame.size.aspectFitScale(in: bounds.size)
        videoFrame.size.width = videoFrame.size.width * CGFloat(scale)
        videoFrame.size.height = videoFrame.size.height * CGFloat(scale)

        videoView.frame = videoFrame
        videoView.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
}


extension CGSize {
    func aspectFitScale(in container: CGSize) -> CGFloat {

        if height <= container.height && width > container.width {
            return container.width / width
        }
        if height > container.height && width > container.width {
            return min(container.width / width, container.height / height)
        }
        if height > container.height && width <= container.width {
            return container.height / height
        }
        if height <= container.height && width <= container.width {
            return min(container.width / width, container.height / height)
        }
        return 1.0
    }
}
