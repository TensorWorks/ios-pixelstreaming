//
//  Message.swift
//  WebRTC-Demo
//
//  Created by Stasel on 20/02/2019.
//  Copyright © 2019 Stasel. All rights reserved.
//

import Foundation

struct ListStreamersMessage: Codable {
    var type: String = "listStreamers"
}

struct SubscribeStreamerMessage: Codable {
    var type: String = "subscribe"
    var streamerId: String
    
    init(inStreamerId: String) {
        self.streamerId = inStreamerId
    }
}

enum Message {
    case sdp(SessionDescription)
    case candidate(IceCandidate)
    case config(PeerConnectionConfig)
    case playerCount(Int)
    case streamerList([String])
}

extension Message: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "config":
            self = .config(try container.decode(PeerConnectionConfig.self, forKey: .peerConnectionOptions))
        case "offer":
            let sdpStr = try container.decode(String.self, forKey: .sdp)
            let sdpType = try container.decode(SdpType.self, forKey: .type)
            self = .sdp(SessionDescription(from: sdpType, and: sdpStr))
        case "iceCandidate":
            self = .candidate(try container.decode(IceCandidate.self, forKey: .candidate))
        case "playerCount":
            self = .playerCount(try container.decode(Int.self, forKey: .count))
        case "streamerList":
            self = .streamerList(try container.decode([String].self, forKey: .ids))
        default:
            throw DecodeError.unknownType
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .config(let config):
            try container.encode("config", forKey: .type)
            try container.encode(config, forKey: .peerConnectionOptions)
        case .sdp(let answerSdp):
            try container.encode("answer", forKey: .type)
            try container.encode(answerSdp.sdp, forKey: .sdp)
        case .candidate(let candidate):
            try container.encode("iceCandidate", forKey: .type)
            try container.encode(candidate, forKey: .candidate)
        case .playerCount(let count):
            try container.encode("playerCount", forKey: .type)
            try container.encode(count, forKey: .count)
        case .streamerList(let ids):
            try container.encode("streamerList", forKey: .type)
            try container.encode(ids, forKey: .ids)
        }
    }
    
    enum DecodeError: Error {
        case unknownType
    }
    
    enum CodingKeys: String, CodingKey {
        case type, sdp, candidate, peerConnectionOptions, count, ids
    }
}
