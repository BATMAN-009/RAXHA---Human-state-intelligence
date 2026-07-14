---
source: ScienceDaily / ACM CCS 2025
url: https://www.sciencedaily.com/releases/2026/05/260522023127.htm
paper: "BFId: Identity Inference Attacks Utilizing Beamforming Feedback Information" (ACM SIGSAC CCS 2025)
institution: Karlsruhe Institute of Technology (KIT), KASTEL Institute
confidence: ✅ peer-reviewed (CCS 2025); accuracy claims from one study (197 participants)
relevance: Competency 8 Domain 3 (Gait Recognition & Privacy); Chapter 1.7 (Wi-Fi/RF sensing cousin)
---

# RF / Wi-Fi Sensing — device-free human identification (BFId, KIT 2025)

**What:** identifies individuals from ordinary Wi-Fi signals with **no device on the person**, by analyzing **beamforming feedback information (BFI)** — unencrypted data Wi-Fi devices send routers. AI reads body radio-wave reflections ("imaging through walls" without cameras).

**Claim:** "near 100% accuracy," 197 participants, robust to viewing angle / walking pattern.

**Framing:** presented as a **privacy attack / surveillance risk**, NOT a product feature. Researchers stress authoritarian-surveillance danger.

**Why it matters for RAXHA (to expand in Competency 8, Domain 3):**
1. **Competing/complementary tech:** device-free RF sensing can detect presence, motion, gait, even falls *without a wearable* — the ambient-sensing alternative to RAXHA's wearable model. Note the trade: infrastructure-bound, indoor, privacy-fraught vs. RAXHA's wear-it-anywhere model. (Ties to the "why wearable at all?" strategic question.)
2. **Privacy threat model:** gait/body-reflection is a biometric emittable *passively* — reinforces that gait is identifying data (Doctrine privacy tier), and that RAXHA's own motion data is a fingerprint (Ch 1.1 §11, AccelPrint lineage).
3. **Confidence discipline:** "near 100% on 197 people" is ✅ peer-reviewed but ★★★ for real-world generalization — a perfect Confidence-Ledger teaching case (lab accuracy ≠ field accuracy, the SisFall→FARSEEING lesson again).

**Related RF-sensing line (for the chapter):** WiFi CSI-based activity/fall detection (a large research literature — e.g., device-free fall detection from channel state information); mmWave radar fall detection (Google Soli / Nest, and academic radar HAR). Cross-link to [[gait recognition]] and Chapter 1.7 indoor positioning.
