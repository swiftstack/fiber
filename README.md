# Fiber

Cooperative multitasking written in swift with only [one exception](https://github.com/tris-foundation/fiber/tree/master/Sources/CCoro).

## Package.swift

```swift
.Package(url: "https://github.com/tris-foundation/fiber.git", majorVersion: 0, minor: 3)
```

## Usage

You can find this code and more in [examples](https://github.com/tris-foundation/examples).

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
let now = Date()
fiber {
    fiber {
        sleep(until: now.addingTimeInterval(2))
        print("fiber 2 woke up")
    }
    sleep(until: now.addingTimeInterval(1))
    print("fiber 1 woke up")
}

FiberLoop.main.run(until: Date().addingTimeInterval(5.0))

// fiber 1 woke up
// fiber 2 woke up
```
