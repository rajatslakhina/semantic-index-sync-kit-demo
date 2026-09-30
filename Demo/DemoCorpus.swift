import Foundation
import SemanticIndexSync
import SemanticIndexSyncUI

extension WorkbenchConfiguration {

    /// The compiled-in configuration this app hands the library's view.
    ///
    /// Both epochs share a `modelIdentifier` and differ only in `revision` —
    /// which is exactly the case that is dangerous in production, because the
    /// model's *name* does not change when an OS update reships it with
    /// retrained weights. If revision were not part of the epoch's identity,
    /// the two spaces would be indistinguishable and every vector on disk would
    /// silently start returning noise.
    static let demo = WorkbenchConfiguration(
        localDevice: DeviceID("iphone"),
        peerDevice: DeviceID("ipad"),
        baselineEpoch: EmbeddingEpoch(
            modelIdentifier: "com.apple.foundationmodels.text",
            revision: 3,
            dimension: 64
        ),
        upgradedEpoch: EmbeddingEpoch(
            modelIdentifier: "com.apple.foundationmodels.text",
            revision: 4,
            dimension: 64
        ),
        seeds: Self.seedDocuments,
        // Conservative: yields to thermal pressure and Low Power Mode, and does
        // 8 passages a pass so the migration is visible rather than instant.
        backgroundBudget: WorkBudget(
            maxChunksPerPass: 8,
            thermalCeiling: .fair,
            requiresExternalPower: false,
            batteryFloor: 0.2,
            yieldsToLowPowerMode: true
        ),
        // Used for the initial index build, while the user is watching a
        // progress indicator and a hotter device is acceptable.
        interactiveBudget: .foregroundInteractive,
        initialQuery: "thermal budget pauses the queue"
    )

    private static let seedDocuments: [SeedDocument] = [
        SeedDocument(
            id: "thermal-policy",
            title: "Background re-index policy",
            passages: [
                "The re-index queue pauses when the device thermal state exceeds the configured ceiling, and resumes on the next pass without losing its place.",
                "A deferred pass returns a typed reason rather than a bare false, because a support engineer eventually has to explain why a user's index stopped progressing.",
                "Low Power Mode yields unless the device is charging, since charging restores the runtime the battery floor exists to protect.",
            ],
            revision: "v1"
        ),
        SeedDocument(
            id: "sync-rules",
            title: "Multi-device reconciliation",
            passages: [
                "Version vectors distinguish a stale write from a concurrent one, which is the distinction a wall-clock timestamp throws away entirely.",
                "A tombstone is never resurrected by a concurrent edit; between losing an edit and resurfacing deleted personal content, only the first is recoverable by the user.",
                "Concurrent live edits resolve by content hash, an arbitrary rule that is nonetheless a pure function of the two records, so every replica converges without coordination.",
            ],
            revision: "v1"
        ),
        SeedDocument(
            id: "epoch-migration",
            title: "Embedding epoch migration",
            passages: [
                "Comparing a query vector against a stored vector from a different model revision produces a finite, sortable number that means nothing at all.",
                "Vectors from the previous epoch are retained rather than deleted, so a rollback restores full coverage instantly instead of triggering a second re-index.",
                "During a migration the index answers on the keyword floor for passages it has not re-embedded yet, and reports exactly how much of the corpus it could search by meaning.",
            ],
            revision: "v1"
        ),
        SeedDocument(
            id: "retrieval-floor",
            title: "Hybrid ranking",
            passages: [
                "BM25 is unbounded and cosine similarity is capped at one, so the two score spaces are normalised within each query before being combined.",
                "Okapi IDF goes negative for a term present in every document, silently inverting the ranking, which is why the smoothing term is not optional.",
            ],
            revision: "v1"
        ),
    ]
}
