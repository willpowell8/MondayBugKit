//
//  ProtocolTransmit.swift
//  RemoteLogTest
//


import Foundation


public enum TransmitState{
    case off
    case broadcasting
}

public protocol Transmit {
    var state:TransmitState { get }
    
    func start()
    func stop()
    func sendEvent(_ event:RemoteEvent)
}
