# Fiber

Cooperative multitasking written in swift with only [one exception](https://github.com/tris-foundation/fiber/tree/master/Sources/CCoro).
Doesn't have channels yet.

## Package.swift

```swift
.Package(url: "https://github.com/tris-foundation/fiber.git", majorVersion: 0)
```

## Usage

You can find this code and more in [examples](https://github.com/tris-foundation/examples).

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
