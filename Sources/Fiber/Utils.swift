public typealias Instant = ContinuousClock.Instant

extension ContinuousClock.Instant {
    public static var distantFuture: Self {
        ContinuousClock.now.advanced(by: .seconds(60 * 60 * 24))
    }
}
