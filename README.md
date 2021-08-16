# Fiber

Cooperative multitasking written in swift with only [one exception](https://github.com/swiftstack/fiber/tree/fiber/Sources/CCoro/coro.c).

## Package.swift

```swift
.package(url: "https://github.com/swiftstack/fiber.git", .branch("fiber"))
```

## Usage

You can find this code and more in [examples](https://github.com/swiftstack/examples/tree/fiber).

### Real World Example (using [Network](https://github.com/swiftstack/network))

As you can see, no callback hell:
```swift
import Network

async {
    let service = client.connect("http://election.online")
    service.login(using: cookies)
    guard service.vote(for: "Thor") == .success else {
        fatalError("we're doomed")
    }
    service.syscall(.coverMyTracks)
    service.logout()
}

loop.run()
```

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
        sleep(until: .now + 2.ms)
        print("fiber 2 woke up")
    }
    sleep(until: .now + 1.ms)
    print("fiber 1 woke up")
}

FiberLoop.main.run(until: .now + 5.ms)

// fiber 1 woke up
// fiber 2 woke up
```
