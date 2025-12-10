//
//  Extension+MTL4ArgumentTableDescriptor.swift
//  MUGE
//
//  Created by Kota on 12/8/25.
//
import typealias Metal.MTL4ArgumentTableDescriptor
extension MTL4ArgumentTableDescriptor {
    @_disfavoredOverload
    @inlinable
    package convenience init(maxBufferCount: Int = 0, maxTextureCount: Int = 0) {
        self.init()
        maxBufferBindCount = maxBufferCount
        maxTextureBindCount = maxTextureCount
    }
}
