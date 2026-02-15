# Temporal Apprentice — Intro & Endgame Refactor Design Doc

## The Big Idea: A Closed Time Loop

The game is a bootstrap paradox. The apprentice's first day IS the time loop closing. Everything the player experiences — from the door opening to the final hiding spot — is one continuous loop that the player only understands at the very end.

---

## Current State (What Changes)

### Current Intro
- Apprentice starts outside, pocket watch on the ground
- Walks east into workshop, sees time machine immediately
- Dr. Thyme is there, barely interacts, leaves for tea
- Reads journal, examines machine → cat triggers accident
- Time machine is in the main workshop, fully visible

### Current Endgame
- Install 4 components, clean workshop
- "Dr. Thyme has returned from tea" → ending text based on score
- No time loop, no paradox, no self-encounter

---

## New Design

### 1. THE INTRO SEQUENCE

**Opening text (revised):**
```
London, 1895.

You are standing outside 14 Praed Street, clutching a copy of yesterday's
Times and trying to look like someone with an open mind regarding the
fundamental nature of causality.

The advert reads: "DR. J. THYME -- TEMPORAL ENGINEERING -- seeks
apprentice with good penmanship and a flexible relationship with linear
time. Competitive wages. No salesmen."

You answered because you needed the money. Also because "temporal
engineering" sounded considerably more interesting than your previous
position at the accounting firm of Greybaum, Tedium and Sons.

You fish your grandfather's pocket watch from your waistcoat pocket.
Three minutes fast, as always. But even by its optimistic reckoning,
you're right on time.
```

**Key changes:**
- Pocket watch is already in inventory (no picking it up off the ground)
- Full name "Justin Thyme" NOT revealed — just "Dr. J. Thyme" from the advert
- The apprentice checks the watch naturally (establishes the prop early)

### 2. THE DOOR

**Workshop Entrance room:**
- The brass plate reads "DR. J. THYME -- TEMPORAL ENGINEERING -- NO SALESMEN"
- The heavy oak door is closed
- Player must KNOCK on the door (new verb)
- First knock: "You rap on the door. No response."
- Second knock: "You knock again, louder. Still nothing. But you could swear you heard something move inside."
- Third knock: "You raise your fist to knock a third time — and the door swings open. No one behind it. The hinges creak in the silence."

**The truth (revealed at endgame):** Future-self opened the door from behind it, then hid. The player performs this action at the end of the game.

**Implementation:** New `knock` verb (BeforeParsing rewrite). Counter tracks knock count. On third knock, door opens and east exit unlocks.

### 3. MEETING DR. THYME

**Main Workshop (revised):**
- The room description emphasizes the workshop chaos but NOT the time machine (it's in a different room now)
- Dr. J. Thyme is hunched over the workbench, intensely focused on something small and intricate
- He does NOT look up when the apprentice enters

**First interaction:**
```
A man is hunched over the workbench, his back to you. Dark hair, slightly
unkempt, shot through with a single streak of grey at the temple. He wears
a waistcoat over rolled shirtsleeves, both dusted with copper filings.

He doesn't look up. His hands move with extraordinary precision over
something small and mechanical.

"The number four spanner," he says, without turning around. "On the
shelf behind you. The brass one. Not the steel one. The steel one is
for Tuesdays."
```

**The apprentice must GIVE/HAND the spanner to Thyme.** This is a mini puzzle — find the right tool on the shelf.

**After giving the spanner:**
```
He takes it without looking, makes a minute adjustment, and finally
turns. You get your first proper look at Dr. J. Thyme.

He has the face of a man who has spent twenty years thinking about
something that nobody else can see — dark eyes set deep beneath
heavy brows, skin the warm brown of old tea, and an expression that
suggests he has just remembered you exist and is moderately pleased
about it.

"Ah. The new apprentice. Yes. Good." He peers at you as if reading
very small print. "I'm Dr. Thyme. You'll call me Doctor, or sir,
or 'that madman with the spanner,' whichever comes most naturally."
```

**Reveals:** Dr. Thyme's appearance — dark-haired, brown-skinned (half Indian/Middle Eastern heritage implied). Brilliant but socially awkward. Intense focus. The "Tuesdays" line hints at his eccentric relationship with time.

**NOTE:** His full name "Justin Thyme" is still not revealed. Just "Dr. Thyme." The player/apprentice won't learn the first name until they find the journal or see his full signature somewhere — and the pun lands.

### 4. THYME'S DEPARTURE

After a brief conversation (expanded `talk to thyme` / `ask thyme about` topics):

```
Dr. Thyme suddenly freezes, stares at the clock on the wall, and
leaps to his feet with the urgency of a man who has just remembered
something catastrophic.

"Mrs. Pemberton's! The scones! She only holds them until half three
and it's—" He checks three separate watches, each showing a different
time. "—it's NEARLY that. Or possibly past. Time is—" He waves his
hand vaguely. "—a matter of perspective."

He grabs an enormous overcoat from the hooks by the door and shoves
a brass key into your hand.

"Front door key. Lock up when I'm back. Or before. Temporal
engineering." He's already halfway out. "DO tidy up while I'm out.
Place is a state. And do NOT go into the solarium. The door at the
end of the corridor. Under ANY circumstances."

The front door slams. You are alone. Well — alone except for the cat,
who watches you from atop a shelf with an expression of absolute
calculation.
```

**Key beats:**
- Hands over the FRONT DOOR KEY (important for endgame — player needs this)
- Explicitly tells the apprentice NOT to go into the solarium (irresistible temptation)
- The "half three" / 30 minutes creates the ticking clock
- The cat is now the player's sole companion

### 5. THE HIDDEN TIME MACHINE

**New room: The Solarium** (or Conservatory, or Courtyard — an adjoining space)

The time machine is NOT in the main workshop. It's behind a locked door. The puzzle to reach it:

**Option A: Locked door + forbidden key**
- The corridor has a locked door at the end
- The front door key Thyme gave you ALSO opens this door (he didn't realize, or it's a master key)
- Player tries key → door opens → solarium revealed
- This is simple, clean, and plays on the "DO NOT go in there" temptation

**Option B: Hidden passage**
- While cleaning/exploring, player discovers a draft behind the shelves
- Move shelves → reveal door → enter solarium
- More of a puzzle but might slow the pace

**Recommendation: Option A.** The forbidden door is a classic adventure game beat. The player is TOLD not to go there, which means they absolutely will.

### 6. THE GLIMPSE (First Entry to Solarium)

When the player first enters the solarium:

```
The solarium is drenched in grey London light filtering through a
glass ceiling streaked with rain and pigeon evidence. Potted ferns
and brass instruments crowd the perimeter. And in the centre—

Something extraordinary.

A contraption of brass, crystal, and what might be a repurposed
church organ, occupying most of the floor space. Dials, levers,
and components you have no name for. It hums with barely contained
energy, as if the air itself is vibrating at a frequency just
below hearing.

As you step through the doorway, you catch a flicker of movement
in the corner of your eye — a shadow, there and gone, behind the
far side of the machine. You spin around. Nothing. Just the ferns
swaying slightly, as if someone brushed past them.

Your heart is hammering. You could have sworn—

But no. Old building. Drafts. Your imagination.
```

**The truth:** Future-self was hiding behind the machine, having just returned from the time-travel adventures. The ferns sway because they brushed past them ducking behind cover. The player will BE that shadow at the end.

### 7. REVISED CAT ACCIDENT

The cat follows the player into the solarium (or is already there — cats find forbidden rooms). The trigger should feel natural:

**Option:** The cat jumps onto the machine while the player examines it. The player tries to grab the cat → cat kicks the lever → accident.

This can largely keep the current mechanic but relocated to the solarium:
- Player examines machine or journal (which could be on a desk in the solarium)
- Cat steals something and jumps on the machine
- Player tries to take cat → accident triggers

### 8. THE ENDGAME — CLOSING THE LOOP

After installing all components and repairing the machine, the game does NOT end with "Thyme returns from tea." Instead:

**The Return:**
```
The machine shudders, hums, and deposits you back in the solarium
with a sound like a grandfather clock having a nervous breakdown.

You check your pocket watch. Three minutes fast, as always. But
according to the solarium clock, it's—

Half two. Thirty minutes BEFORE you arrived for your interview.

You are in the workshop. Your PAST SELF is about to knock on
the front door.
```

**The player must now:**
1. **Clean the solarium** — put the machine back to how they found it
2. **Close the solarium door** — it was locked when they arrived
3. **Tidy the workshop** — it needs to look like Thyme just left
4. **Wait for the knock** — three knocks on the front door
5. **Open the door** — player opens the door and hides behind it
6. **Hide** — duck behind the door / into the store room as past-self enters
7. **Sneak to the solarium** — while past-self is in the workshop
8. **Hide behind the machine** — the player IS the shadow from the beginning
9. **Wait** — past-self enters the solarium, sees the "flicker"
10. **Slip out** — past-self is distracted by the machine; player exits through the front door using the key

**Final text (when player exits through front door):**
```
You pull the door shut behind you. The lock clicks. The key is warm
in your hand.

Outside, Praed Street is grey and wet and blessedly, boringly linear.
A hansom cab rattles past. A newspaper boy shouts about something
that won't matter for a hundred years.

You lean against the wall and breathe.

Your pocket watch ticks. Three minutes fast. As always.

From inside, very faintly, you hear the sound of a cat discovering
something it shouldn't.

You smile. You're going to be a very good apprentice.

You're already one.
```

Then the score-based endings can still apply as flavor text after this.

---

## Score Implications

The scoring system largely stays the same. New points could be awarded for:
- Knocking on the door (0 — it's the entry point)
- Giving Thyme the spanner (5 — first puzzle)
- Discovering the solarium (5 — replaces old "examine machine" trigger)
- The endgame loop sequence (10-15 — for each step of the loop)

**New max score:** TBD based on how many endgame steps award points.

---

## New Verbs / Mechanics Needed

| Verb | Purpose |
|------|---------|
| `knock` | Knock on the front door (intro) / knock on solarium door |
| `hide` | Hide behind door / behind machine (endgame) |
| `wait` (modified) | Wait for knocks during endgame |

The existing verbs (`clean`, `travel`, `enter`, `open`, `lock`) should cover most other needs.

---

## Rooms Changes Summary

| Current | New |
|---------|-----|
| Workshop Entrance (has pocket watch on ground) | Workshop Entrance (door locked, must knock; watch in inventory) |
| Main Workshop (has time machine, Thyme, cat, journal) | Main Workshop (has workbench, Thyme, cat, tools; NO time machine) |
| Store Room (toolkit) | Store Room (toolkit, possible hiding spot for endgame) |
| — | **Solarium** (NEW: time machine, journal, the "glimpse") |

The four eras (Roman, Blitz, Cambridge, Future) are **unchanged**.

---

## Files Affected

- `temporal_apprentice.inf` — Major rewrite of intro, workshop rooms, cat trigger, endgame
- `temporal_apprentice.z5` — Recompile
- `test_temporal_apprentice.sh` — All workshop/intro/endgame tests need updating
- `CLAUDE.md` — Update game overview, puzzle flow, room list, NPC list

---

## Open Questions

1. **Full name reveal:** When does the player learn his first name is "Justin"? Options:
   - The journal: "Property of Dr. Justin Thyme" on the cover
   - His signature on a letter in the solarium
   - Mrs. Pemberton yells "JUSTIN!" when he returns (if we add her)
   - The brass plate could remain "J. THYME" and the journal reveals the rest

2. **Where does the journal live now?** Currently in the workshop. Should it move to the solarium (near the machine) or stay on the workbench?

3. **Copernicus naming:** Currently the cat is named by examining a name tag. Does this change?

4. **Cross-era causality display:** The museum in 2045 shows consequences of player actions. Does the time loop change any of this?

5. **Endgame complexity:** How many steps should the "close the loop" sequence require? Too few feels anticlimactic; too many risks frustrating the player who just wants to finish.

6. **Multiple endings still?** The score-based endings (Perfect/Good/Rough/Paradox) could still work as flavor after the loop closes. Or the loop IS the ending regardless of score.

---

## Implementation Order

1. **Phase 1: New intro sequence** — Rewrite Initialise, workshop entrance (knock mechanic), meeting Thyme, spanner puzzle, Thyme's departure
2. **Phase 2: Solarium** — New room, move time machine and journal there, "the glimpse," relocate cat accident trigger
3. **Phase 3: Endgame rewrite** — Time loop return, hide sequence, door opening, final exit
4. **Phase 4: Testing** — Rewrite all affected tests, full playthrough QA
5. **Phase 5: Polish** — Tune the text, pacing, and scoring

Each phase should be a separate issue/PR to keep changes reviewable.
