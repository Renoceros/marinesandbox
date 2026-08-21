import Foundation

/// **PlaygroundMode: Bare Drag-and-Drop Field (temporary)**
///
/// Strips the Coral Screen down to one coral on an empty seabed so coral
/// placement can be tuned without the care loop moving underneath it — no
/// tools, no palette, no guide, and a frozen simulation, because a live tick
/// grows the coral, spawns pests on it and kills it within about two minutes.
///
/// Nothing is deleted to achieve this. Every overlay and the tick are gated on
/// this flag, so setting it to `false` restores the full care loop (DEC-007
/// tools, DEC-009/024 guided plant, DEC-012 pests, DEC-029 palette) exactly as
/// it was.
///
enum PlaygroundMode {

    /// `true` while the drag-and-drop field is being tuned. Flip to `false` to
    /// get the game back.
    static let isEnabled = true
}
