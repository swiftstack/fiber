/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Platform

#if os(macOS)
let SC_PAGE_SIZE = _SC_PAGE_SIZE
#else
let SC_PAGE_SIZE = Int32(_SC_PAGESIZE)
#endif

struct Stack {
    let pointer: UnsafeMutableRawPointer
    let size: Int
}

let pagesize = sysconf(SC_PAGE_SIZE)

extension Stack {
    private static let size = 64.kB

    // TODO: inject allocator
    static func allocate() -> Stack {
        let pointer = UnsafeMutableRawPointer.allocate(
            byteCount: size, alignment: pagesize)
        mprotect(pointer, pagesize, PROT_READ)
        return Stack(pointer: pointer, size: size)
    }

    func deallocate() {
        pointer.deallocate()
    }
}

extension Int {
    var kB: Int {
        return self * 1024
    }
}
