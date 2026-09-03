//
//  AnimatableVector.swift
//  Clarify
//
//  A small VectorArithmetic-conforming type that lets a single spring
//  animation drive an arbitrary number of independent "letter flight"
//  progress values at once (one per animated letter in
//  InteractiveDNSCanvas). Without this, animating N letters would need
//  N separate `@State` values and N separate animation modifiers, which
//  makes staggered, interruptible springs awkward to coordinate.
//

import SwiftUI

/// A vector of `Double` values that SwiftUI's animation system can
/// interpolate as a single unit, driven by ordinary spring physics.
struct AnimatableVector: VectorArithmetic {
    var values: [Double]

    init(_ values: [Double]) {
        self.values = values
    }

    static var zero: AnimatableVector { AnimatableVector([]) }

    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        AnimatableVector(combine(lhs.values, rhs.values, +))
    }

    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        AnimatableVector(combine(lhs.values, rhs.values, -))
    }

    static func += (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        lhs = lhs - rhs
    }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }

    /// Magnitude used internally by SwiftUI to decide when an animation
    /// has settled close enough to its target to stop.
    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }

    /// Pads the shorter array with zeros so element-wise combination is
    /// always safe, even mid-animation when the letter count changes
    /// (e.g. a new flight is queued while an old one is still settling).
    private static func combine(
        _ a: [Double],
        _ b: [Double],
        _ op: (Double, Double) -> Double
    ) -> [Double] {
        let count = max(a.count, b.count)
        return (0..<count).map { index in
            let left = index < a.count ? a[index] : 0
            let right = index < b.count ? b[index] : 0
            return op(left, right)
        }
    }
}
