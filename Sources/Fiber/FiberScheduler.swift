/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Log
import Async
import Foundation

public class FiberScheduler {
    private var fibers = [UnsafeMutablePointer<Fiber>]()
    private var scheduler: UnsafeMutablePointer<Fiber>
    private(set) var running: UnsafeMutablePointer<Fiber>

    init() {
        scheduler = UnsafeMutablePointer<Fiber>.allocate(capacity: 1)
        scheduler.initialize(to: Fiber(schedulerId: -1))
        running = scheduler

        ready.reserveCapacity(128)
    }

    deinit {
        for fiber in fibers {
            fiber.pointee.deallocate()
            fiber.deallocate(capacity: 1)
        }
        scheduler.deallocate(capacity: 1)
    }

    var ready = [UnsafeMutablePointer<Fiber>]()
    var cache = [UnsafeMutablePointer<Fiber>]()

    public var hasReady: Bool {
        return ready.count > 0
    }

    public func async(_ task: @escaping AsyncTask) {
        let fiber: UnsafeMutablePointer<Fiber>

        if let cached = cache.popLast() {
            fiber = cached
        } else {
            fiber = UnsafeMutablePointer<Fiber>.allocate(capacity: 1)
            fiber.initialize(to: Fiber(id: fibers.count))
            fibers.append(fiber)
        }

        fiber.pointee.state = .none
        fiber.pointee.task = task
        fiber.pointee.caller = running
        call(fiber: fiber)
    }

    // NOTE: do not change fiber caller here
    func call(fiber: UnsafeMutablePointer<Fiber>) {
        let caller = running
        running = fiber
        fiber.pointee.transfer(from: caller)
    }

    func sleep() {
        let child = running
        guard let parent = child.pointee.caller else {
            Log.critical("can't yield into the void")
            abort()
        }
        running = parent
        child.pointee.caller = scheduler
        child.pointee.state = .sleep
        child.pointee.yield(to: parent)
    }

    @_versioned
    func yield() {
        ready.append(running)
        sleep()
    }

    func lifecycle() {
        while true {
            let fiber = running

            guard let task = fiber.pointee.task else {
                Log.critical("don't know what to do")
                abort()
            }

            task()

            fiber.pointee.task = nil
            fiber.pointee.state = .cached
            cache.append(fiber)

            sleep()
        }
    }

    func cancelReady() {
        for fiber in ready {
            fiber.pointee.state = .canceled
        }
    }

    func schedule(fiber: UnsafeMutablePointer<Fiber>, state: Fiber.State)
    {
        fiber.pointee.state = state
        ready.append(fiber)
    }

    func runReadyChain() {
        assert(ready.count > 0)
        assert(running == scheduler)

        let first = ready.first!
        var last = first

        for next in ready.suffix(from: 1) {
            last.pointee.caller = next
            last = next
        }
        last.pointee.caller = running
        
        ready.removeAll(keepingCapacity: true)
        call(fiber: first)
    }
}
