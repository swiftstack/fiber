# Fiber

Cooperative multitasking written in swift with only [one exception](https://github.com/swiftstack/fiber/tree/dev/Sources/CCoro/coro.c).

## Package.swift

```swift
.package(url: "https://github.com/swiftstack/fiber.git", .branch("dev"))
```

## Usage

### Transfer execution

```swift
fiber {
    print("hello from fiber 1")
    fiber {
        print("hello from fiber 2")
        yield()
        print("bye from fiber 2")
    }
    print("no, you first")
    yield()
    print("bye from fiber 1")
}

FiberLoop.main.run()

// hello from fiber 1
// hello from fiber 2
// no, you first
// bye from fiber 2
// bye from fiber 1
```

### Channel

```swift
var channel = Channel<Int>()

fiber {
    while let value = channel.read() {
        print("read: \(value)")
    }
    print("read: the channel is closed.")
}

fiber {
    for i in 0..<5 {
        channel.write(i)
    }
    channel.close()
}
// read: 0
// read: 1
// read: 2
// read: 3
// read: 4
// read: the channel is closed.
```

### Timer

```swift
import Time

fiber {
    fiber {
        sleep(until: .now.advanced(by: .milliseconds(2)))
        print("fiber 2 woke up")
    }
    sleep(until: .now.advanced(by: .milliseconds(1)))
    print("fiber 1 woke up")
}

FiberLoop.main.run(until: .now.advanced(by: .milliseconds(5)))

// fiber 1 woke up
// fiber 2 woke up
```
