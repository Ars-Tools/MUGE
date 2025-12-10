//
//  Protocol.swift
//  MUGE
//
//  Created by Kota on 12/7/25.
//
import CoreVideo
import CIArtwork
public protocol AVArtwork: CIArtwork {
    func start()
    func stop()
    func cvImageBuffer(at timestamp: CFTimeInterval) -> Optional<CVImageBuffer>
}
extension AVArtwork {
    public func ciImage(at timestamp: CFTimeInterval) -> Optional<CIImage> {
        cvImageBuffer(at: timestamp).map(CIImage.init(cvImageBuffer:))
    }
}
