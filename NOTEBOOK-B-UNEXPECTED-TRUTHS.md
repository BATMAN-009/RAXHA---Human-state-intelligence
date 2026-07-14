# Notebook B — Unexpected Truths

> Every time implementation teaches something nobody predicted, one entry. These become patents, doctrine, blog posts, and competitive advantage — *the advisor's bet: this notebook ends up more valuable than Notebook A.*

| # | What implementation taught us | Nobody predicted it because | Where it goes (patent / doctrine RFC / product / post) |
|---|---|---|---|
| B-01 (2026-07-15) | Decision-log hashes are **bit-identical across Windows (local), macOS CI, and Windows CI** on the very first VV-101 run — cross-platform replay determinism held with zero extra work, given integer-ms timestamps, injected IDs (IdSource port), and sorted-key JSON encoding | 13 §VV-101 assumed cross-platform bit-identity would need deliberate later effort (float/encoder divergence expected); it fell out of the design constraints instead | Strengthens ADR-109 evidence; keep integer-only hashed payloads as a standing rule; candidate post |
| B-02 (2026-07-15) | VV-110's first-ever run caught a real defect — in the rig itself (NSNumber 0/1 misclassified as booleans on BOTH platforms, flagging quality 0.0 / risk 1.0 / seq 1) | The contract rig was expected to catch pipeline drift, not its own validator; boundary values (0/1) hit the platform's Bool-bridging quirk on day one | Harness lesson recorded in SchemaValidator comment; reinforces D20 (two-sided evidence: a rig must be testable against itself) |
