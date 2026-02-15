# The Temporal Apprentice — Story Flow

```mermaid
flowchart TD
    subgraph WORKSHOP["WORKSHOP (1895)"]
        W1[Knock on door] --> W2[Meet Dr. Thyme]
        W2 --> W3[Give spanner]
        W3 --> W4[Thyme departs for scones]
        W4 --> W5[Explore solarium]
        W5 --> W6[Cat steals rag, climbs machine]
        W6 --> W7["Grab cat → cat kicks lever"]
    end

    W7 ==>|"⚡ LODESTONE FADES<br/>847 activations + 1 uncontrolled transit"| R1

    subgraph ROMAN["ROMAN LONDINIUM (60 AD)"]
        R1[Arrive in Forum] --> R2[Trade aureus for lodestone]
        R2 --> R3[Show lodestone to Marcus]
        R3 --> R4{Side quests}
        R4 -->|"🪨 Carve inscription"| R4a["Temple wall inscription<br/>(inscription_carved)"]
        R4 -->|"⌚ Bury watch"| R4b["Thames dock time capsule<br/>(capsule_buried)"]
        R3 --> R5["GATE: Soldiers surround machine<br/>Show lodestone to Marcus"]
    end

    R5 ==>|"⚡ CROOKES TUBE FRACTURES<br/>web of cracks through hand-blown glass"| B1

    subgraph BLITZ["BLITZ LONDON (1941)"]
        B1[Arrive in blackout] --> B2[Fix Tommy's radio]
        B2 --> B3[Tommy helps dig out machine]
        B3 --> B4[Find vacuum tube in supply crate]
        B4 --> B5{Side quests}
        B5 -->|"🔥 Extinguish fire"| B5a["Save St. Margaret's Church<br/>(church_saved)"]
        B5 -->|"🎁 Give item to Eleanor"| B5b["Eleanor becomes artist<br/>(eleanor_gift)"]
        B3 --> B6["GATE: Machine buried under rubble<br/>Dig with Tommy's help"]
    end

    B6 ==>|"Lodestone flickers, tube whines<br/>Hawking's beacon does the heavy lifting"| C1

    subgraph CAMBRIDGE["CAMBRIDGE (2009)"]
        C1["Arrive at College Gates<br/>Hawking's Time Traveller's Party"] --> C2[Find invitation in garden]
        C2 --> C3[Give invitation to porter]
        C3 --> C4[Meet Hawking in Great Hall]
        C4 --> C5["Tell about time + show journal + show lodestone"]
        C5 --> C6["Hawking convinced → prints formula"]
        C6 --> C7[Take dot-matrix printout]
        C7 --> C8["GATE: None — convince Hawking,<br/>take printout, depart"]
    end

    C8 ==>|"⚡ CRYSTAL CRACKS<br/>fracture line through processor<br/>📰 Newspaper torn away by temporal wind"| F1

    subgraph FUTURE["FUTURE LONDON (2045)"]
        F1["Arrive in flooded street<br/>Machine barely functional"] --> F2[Help Kai → get diving gear]
        F2 --> F3["GATE: Machine underwater<br/>Haul up with diving gear"]
        F2 --> F4[Enter submerged lab]
        F4 --> F5["Hawking Temporal Research Centre<br/>(Founded 2031)"]
        F5 --> F6["Find dispatch log:<br/>UNIT 0001-ALPHA → J. THYME<br/>DO NOT LOG SENDER"]
        F5 --> F7[Open cabinet with formula code]
        F7 --> F8[Take crystalline processor]
    end

    F3 & F8 ==> E1

    subgraph ENDGAME["ENDGAME — WORKSHOP (1895)"]
        E1[Return to workshop] --> E2["Install all 4 components"]
        E2 --> E3["Lodestone → compass housing (click)"]
        E3 --> E4["Vacuum tube → bend contacts with pliers"]
        E4 --> E5["Formula → calibration matrix (machine can AIM)"]
        E5 --> E6["Crystal → brass harness (same perfect fit)"]
        E6 --> E7[Clean workshop]
        E7 --> E8["Dr. Thyme returns from tea ☕"]
    end
```

## Bootstrap Paradoxes

```mermaid
flowchart LR
    subgraph CRYSTAL_LOOP["Crystalline Processor Loop"]
        CL1["Player attends<br/>Hawking's Party<br/>(2009)"] --> CL2["Hawking publishes<br/>temporal harmonics"]
        CL2 --> CL3["Hawking Research Centre<br/>founded (2031)"]
        CL3 --> CL4["Centre builds<br/>crystalline processor"]
        CL4 --> CL5["Someone posts crystal<br/>to Thyme (1895)<br/>DO NOT LOG SENDER"]
        CL5 --> CL6["Thyme solders crystal<br/>into brass harness"]
        CL6 --> CL7["Machine works →<br/>cat accident"]
        CL7 --> CL1
    end
```

```mermaid
flowchart LR
    subgraph NEWSPAPER_LOOP["Newspaper Loop"]
        NL1["Player carries<br/>yesterday's Times<br/>(1895)"] --> NL2["Temporal wind rips<br/>newspaper away<br/>(transit to 2045)"]
        NL2 --> NL3["Pages scatter<br/>through centuries"]
        NL3 --> NL4["Lands in sealed<br/>amphora, Roman era"]
        NL4 --> NL5["Wax seal preserves<br/>it for 2000 years"]
        NL5 --> NL6["Museum displays it<br/>(2045)<br/>INK CHANGES UNDER<br/>OBSERVATION"]
    end
```

## Cross-Era Causality

```mermaid
flowchart LR
    subgraph CAUSALITY["Side Quest Ripple Effects"]
        direction LR
        CE1["🪨 Carve inscription<br/>(Roman 60 AD)"] -->|"1900 years"| CE2["Inscription visible<br/>in bombed church<br/>(Blitz 1941)"]
        CE3["⌚ Bury watch<br/>(Roman 60 AD)"] -->|"2000 years"| CE4["Watch in museum<br/>(Future 2045)"]
        CE5["🎁 Give Eleanor item<br/>(Blitz 1941)"] -->|"104 years"| CE6["Morrison Retrospective<br/>at museum (Future 2045)"]
        CE7["🔥 Save church<br/>(Blitz 1941)"] -->|"68+ years"| CE8["Church stands in<br/>Cambridge & Future"]
    end
```

## Progressive Damage

```mermaid
flowchart LR
    subgraph DAMAGE["Machine Degradation"]
        D0["PRE-ACCIDENT<br/>✅ Lodestone (847 activations)<br/>✅ Crookes tube (marginal)<br/>✅ Crystal (mysterious parcel)<br/>❌ Navigation (imprecise)"]
        D0 -->|"Cat accident"| D1["ROMAN ERA<br/>⚠️ Lodestone FADING<br/>✅ Crookes tube<br/>✅ Crystal<br/>Range: limited"]
        D1 -->|"Transit"| D2["BLITZ ERA<br/>⚠️ Lodestone FADING<br/>⚠️ Tube FRACTURED<br/>✅ Crystal<br/>Range: extending"]
        D2 -->|"Transit<br/>(beacon assists)"| D3["CAMBRIDGE<br/>⚠️ Lodestone FADING<br/>⚠️ Tube FRACTURED<br/>✅ Crystal<br/>Narrative stop"]
        D3 -->|"Transit"| D4["FUTURE ERA<br/>⚠️ Lodestone NEAR DARK<br/>⚠️ Tube FRACTURED<br/>⚠️ Crystal CRACKED<br/>Machine exhausted"]
        D4 -->|"Repair"| D5["REPAIRED<br/>✅ New lodestone<br/>✅ Military tube (bent pins)<br/>✅ Formula transcribed<br/>✅ New crystal (same harness)"]
    end
```

## Newspaper Headlines (BTTF Effect)

| Causality Flag | Default Headline | Changed Headline | Ink Effect |
|---|---|---|---|
| `inscription_carved` | Restoration Works — Nothing of Interest | Mysterious Inscription — Latin Predates Foundation | Freshly printed, paper yellowed |
| `capsule_buried` | Thames Excavation — Pottery, Adequate | Victorian Pocket Watch in Roman Stratum | Letters shimmer and rearrange |
| `eleanor_gift` | Gallery Exhibition — Nothing Remarkable | Eleanor Morrison Retrospective | Photograph fades in/out |
| `church_saved` | Car Park on Church Site Approved | St. Margaret's 600th Anniversary | Ink almost smudges under thumb |
