import SwiftUI

// Coordinates shared canvas state for the sandbox screen.
//
// `scrollX` is hoisted here (DEC-021, issue #6) so the entity layer can
// hit-test taps against the same scroll offset ParallaxScrollView is
// actively panning/rubber-banding, instead of tracking a second,
// potentially desynced copy.
@Observable
final class SandboxViewModel {
    var scrollX: CGFloat = 0.0
}
