#!/usr/bin/env bash
# Test harness for The Temporal Apprentice
# Compiles the game and runs automated tests using dfrotz

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INF="temporal_apprentice.inf"
Z5="temporal_apprentice.z5"
DFROTZ="/usr/games/dfrotz"
INFORM6="inform6"
LIB="+/usr/local/share/inform6/lib/"

PASS=0
FAIL=0
TOTAL=0

run_test() {
    local name="$1"
    local commands="$2"
    local expected="$3"
    TOTAL=$((TOTAL + 1))
    local output
    output=$(echo "$commands" | "$DFROTZ" -h 999 -w 200 "$Z5" 2>&1)
    if echo "$output" | grep -qi "$expected"; then
        PASS=$((PASS + 1))
        echo "  PASS: $name"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $name (expected: $expected)"
    fi
}

run_test_absent() {
    local name="$1"
    local commands="$2"
    local unexpected="$3"
    TOTAL=$((TOTAL + 1))
    local output
    output=$(echo "$commands" | "$DFROTZ" -h 999 -w 200 "$Z5" 2>&1)
    if echo "$output" | grep -qi "$unexpected"; then
        FAIL=$((FAIL + 1))
        echo "  FAIL: $name (should NOT contain: $unexpected)"
    else
        PASS=$((PASS + 1))
        echo "  PASS: $name"
    fi
}

echo "=== Compiling $INF ==="
"$INFORM6" "$LIB" "$INF" "$Z5"
echo ""

echo "=== Running tests ==="

# Knock three times to open door and enter workshop
ENTER_WORKSHOP="knock
knock
knock
east"

# Enter workshop, do Thyme sequence, auto-unlock and enter solarium
ENTER_SOLARIUM="knock
knock
knock
east
take spanner
give spanner to dr thyme
talk to dr thyme
east"

# Common trigger: the multi-step cat accident sequence
# 1) give spanner to dr thyme (introduces you)
# 2) talk to dr thyme (gives rags + key, Thyme leaves)
# 3) east (auto-unlocks and enters solarium)
# 4) clean (cat steals rag, climbs onto machine in solarium)
# 5) take cat (cat kicks lever, accident fires -> Roman Forum)
CAT_ACCIDENT="take spanner
give spanner to dr thyme
talk to dr thyme
east
clean
take cat"

# --- Compilation ---
echo "[Compilation]"
run_test "Game compiles and runs" "look" "Praed Street"

# --- Knock Mechanic ---
echo "[Knock Mechanic]"
run_test "Open door before knock" "open door" "locked from the inside"
run_test "First knock" "knock" "No response"
run_test "Second knock" "knock
knock" "something move inside"
run_test "Third knock opens door" "knock
knock
knock" "beginning to rain"
run_test "East blocked before knock" "east" "should knock"
run_test "East open after knock" "$ENTER_WORKSHOP" "cathedral"
run_test "Enter works after knock" "knock
knock
knock
enter" "cathedral"
run_test "Close door from outside" "knock
knock
knock
close door" "No point closing it now"

# --- Spanner Puzzle ---
echo "[Spanner Puzzle]"
run_test "Spanner on shelf" "$ENTER_WORKSHOP
look" "spanner"
run_test "Take spanner" "$ENTER_WORKSHOP
take spanner" "Taken"
run_test "Give spanner to Thyme" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme" "new apprentice"
run_test "Give wrench to Thyme" "$ENTER_WORKSHOP
take spanner
give wrench to dr thyme" "new apprentice"
run_test "Hand spanner to Thyme" "$ENTER_WORKSHOP
take spanner
hand spanner to dr thyme" "new apprentice"
run_test "Hand wrench to Thyme" "$ENTER_WORKSHOP
take spanner
hand wrench to dr thyme" "new apprentice"
run_test "Thyme won't talk without spanner" "$ENTER_WORKSHOP
talk to dr thyme" "spanner"
run_test "Thyme departure gives key" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
talk to dr thyme" "front door key"

# --- Pocket Watch ---
echo "[Pocket Watch]"
run_test "Watch in inventory at start" "inventory" "pocket watch"
run_test_absent "No watch on ground" "look" "You can.*see.*pocket watch"

# --- Workshop Hub ---
echo "[Workshop Hub]"
run_test "Start location" "look" "Praed Street"
run_test "Go to workshop" "$ENTER_WORKSHOP" "cathedral of improbable engineering"
run_test "Take journal" "$ENTER_WORKSHOP
take journal" "Taken"
run_test "Store room accessible" "$ENTER_WORKSHOP
north" "Store Room"
run_test "Take toolkit" "$ENTER_WORKSHOP
north
take toolkit" "Taken"
run_test "Dr. Thyme present" "$ENTER_WORKSHOP" "Dr. Thyme"
run_test "Cat shown as ginger tabby" "$ENTER_WORKSHOP" "ginger tabby cat"
run_test_absent "Cat not named Copernicus initially" "$ENTER_WORKSHOP
look" "You can also see.*Copernicus"
run_test "Workshop mentions corridor" "$ENTER_WORKSHOP" "corridor runs east"
run_test_absent "No time machine in workshop" "$ENTER_WORKSHOP" "magnificent contraption"
run_test_absent "No 'This would be the time machine' text" "$ENTER_WORKSHOP" "This would be the time machine"

# --- Solarium ---
echo "[Solarium]"
run_test "Corridor blocked before Thyme departs" "$ENTER_WORKSHOP
east" "Dr. Thyme seems to need your attention"
run_test "Solarium auto-unlock with key" "$ENTER_SOLARIUM" "master key"
run_test "First entry glimpse" "$ENTER_SOLARIUM" "flicker of movement"
run_test "Machine in solarium" "$ENTER_SOLARIUM
look" "contraption"
run_test "Ferns in solarium" "$ENTER_SOLARIUM" "ferns"
run_test "Cat appears in solarium" "$ENTER_SOLARIUM" "already here"

# --- Cat naming ---
echo "[Cat Naming]"
run_test "Examine name tag reveals name" "$ENTER_WORKSHOP
examine tag
look" "Copernicus"
run_test "Name tag has solar system" "$ENTER_WORKSHOP
examine tag" "solar system"
run_test "Ask Thyme about cat reveals name" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
ask dr thyme about cat
look" "Copernicus"

# --- Dr. Thyme expanded dialog ---
echo "[Dr. Thyme Dialog]"
run_test "Ask about machine" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
ask dr thyme about machine" "Temporal Displacement Engine"
run_test "Ask about marmalade" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
ask dr thyme about marmalade" "Seville orange"
run_test "Ask about Mrs Pemberton" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
ask dr thyme about pemberton" "scone"
run_test "Ask about research" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
ask dr thyme about research" "twenty-seven years"
run_test "Ask about journal" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
ask dr thyme about journal" "temporal feedback loop"

# --- Multi-step accident sequence ---
echo "[Cat Accident]"
run_test "Talk to Thyme gives rags" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
talk to dr thyme" "tidy up"
run_test "Thyme warns about solarium" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
talk to dr thyme" "do NOT go into the solarium"
run_test "Thyme departs" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
talk to dr thyme" "front door slams"
run_test "Cat on machine with rag" "$ENTER_SOLARIUM
clean
look" "cleaning rag dangling"
run_test "Cat steals rag" "$ENTER_SOLARIUM
clean" "snatches the rag"
run_test "Take cat triggers accident" "$ENTER_WORKSHOP
$CAT_ACCIDENT" "ABSOLUTELY DO NOT TOUCH"
run_test "Sent to Roman forum" "$ENTER_WORKSHOP
$CAT_ACCIDENT" "Roman Londinium"
run_test "Lodestone depleted in cat accident" "$ENTER_WORKSHOP
$CAT_ACCIDENT" "lodestone"
run_test "Score for accident" "$ENTER_WORKSHOP
$CAT_ACCIDENT
score" "9 out of"
run_test "Dropped key survives cat accident" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
talk to dr thyme
east
drop key
clean
take cat
inventory" "front door key"
run_test "Dropped watch survives cat accident" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
talk to dr thyme
east
drop watch
clean
take cat
inventory" "pocket watch"

# --- Clean guard ---
echo "[Clean Guard]"
run_test_absent "No cleaning before spanner" "$ENTER_WORKSHOP
clean" "Tools are returned"
run_test "Cleaning refused before spanner" "$ENTER_WORKSHOP
clean" "spanner"
run_test "Cleaning refused before talking to Thyme" "$ENTER_WORKSHOP
give spanner to dr thyme
clean" "talk to Dr. Thyme"
run_test "Workshop clean is superficial" "$ENTER_SOLARIUM
west
clean" "marginally less chaotic"
run_test "Cannot clean while rag on machine" "$ENTER_SOLARIUM
clean
clean" "cat has stolen"

# --- Cleaning synonyms (issue #70) ---
echo "[Cleaning Synonyms]"
run_test "wipe workbench with rag" "$ENTER_SOLARIUM
west
wipe workbench with rag" "marginally less chaotic"
run_test "clean workbench with rag" "$ENTER_SOLARIUM
west
clean workbench with rag" "marginally less chaotic"
run_test "scrub workshop" "$ENTER_SOLARIUM
west
scrub workshop" "marginally less chaotic"
run_test "polish workbench" "$ENTER_SOLARIUM
west
polish workbench" "marginally less chaotic"
run_test "tidy up the workshop" "$ENTER_SOLARIUM
west
tidy up the workshop" "marginally less chaotic"
run_test "tidy up some more (regression #68)" "$ENTER_SOLARIUM
west
tidy up some more" "marginally less chaotic"
run_test_absent "no zcl leak in tidy up some more (#68)" "$ENTER_SOLARIUM
west
tidy up some more" "zcl"
run_test "bare clean still works" "$ENTER_SOLARIUM
west
clean" "marginally less chaotic"
run_test "bare tidy still works" "$ENTER_SOLARIUM
west
tidy" "marginally less chaotic"
run_test "bare sweep still works" "$ENTER_SOLARIUM
west
sweep" "marginally less chaotic"
run_test "clean workshop with rag (#67)" "$ENTER_SOLARIUM
west
clean workshop with rag" "marginally less chaotic"
run_test "wipe workshop with rag (#67)" "$ENTER_SOLARIUM
west
wipe workshop with rag" "marginally less chaotic"

# --- Examine machine before accident ---
echo "[Machine Examine Pre-Accident]"
run_test "Examine machine in solarium" "$ENTER_SOLARIUM
examine machine" "barely contained energy"
run_test_absent "Examine machine does not trigger accident" "$ENTER_SOLARIUM
examine machine" "ABSOLUTELY DO NOT TOUCH"

echo "[Progressive Damage]"
# After cat accident (Roman): only lodestone mentioned
run_test "Roman era: lodestone fading" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine machine" "lodestone is fading"
run_test_absent "Roman era: no Crookes tube damage yet" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine machine" "Crookes tube is webbed"
# After Blitz transit: Crookes tube also broken
run_test "Blitz transit: Crookes tube shattered" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
examine machine" "Crookes tube is webbed"
# Crystal cracking during Future transit

# --- Install-As-You-Go ---
echo "[Install-As-You-Go]"
# Roman: repair machine installs lodestone
run_test "Roman: repair installs lodestone" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine" "lodestone into the compass housing"

# Roman: can't travel to Blitz without lodestone installed
run_test "Roman: blocked without lodestone installed" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to blitz" "compass housing is dark"

# Blitz: repair machine installs tube (needs toolkit)
run_test "Blitz: repair installs tube" "$ENTER_WORKSHOP
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine" "oscillation circuit is restored"

# Blitz: tube install needs toolkit
run_test "Blitz: tube needs toolkit" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine" "needle-nose pliers"

# Blitz: can't travel to Cambridge without tube installed
run_test "Blitz: blocked without tube installed" "$ENTER_WORKSHOP
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
travel to cambridge" "Crookes tube is fractured"

# (Cambridge and Future install-as-you-go tests are below, after their setups are defined)

# --- Roman Londinium ---
echo "[Roman Londinium]"
run_test "Forum description" "$ENTER_WORKSHOP
$CAT_ACCIDENT
look" "Forum"
run_test "Marcus blocks north" "$ENTER_WORKSHOP
$CAT_ACCIDENT
north" "Roman citizens and military"
run_test "Livia blocks temple" "$ENTER_WORKSHOP
$CAT_ACCIDENT
east" "Only the initiated"
run_test "Bathhouse accessible" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west" "Steam billows"
run_test_absent "Gold aureus not visible before retrieval" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west" "gold aureus"
run_test "Ask Copernicus about grate retrieves aureus" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate" "gold coin skitters"
run_test "Take aureus after retrieval" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus" "Taken"
run_test "Swim in bathhouse" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
swim" "strigil"
run_test "Enter pool in bathhouse" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
enter pool" "caldarium"
run_test "Merchant quarter" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south" "Merchant"
run_test "Trade for lodestone" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix" "lodestone"
run_test "Show lodestone to Marcus" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus" "commands iron"
run_test "Temple accessible after Marcus" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east" "Temple of Mithras"
run_test "Carve inscription" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east
carve" "TEMPUS FUGIT"
run_test "Bury time capsule" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
south
bury" "two thousand years"
run_test "Machine present after accident" "$ENTER_WORKSHOP
$CAT_ACCIDENT
look" "surrounded by wary Roman soldiers"
run_test "Machine gate: soldiers block travel" "$ENTER_WORKSHOP
$CAT_ACCIDENT
travel to blitz" "impress their centurion"
run_test "Machine gate: soldiers block repair" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
fix machine" "impress their centurion"
run_test "Travel to workshop from Roman" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to workshop" "back in the solarium"
run_test "Solarium has machine after travel home" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to workshop
look" "worse for wear"
run_test "Already home guard" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to workshop
travel to workshop" "already home"
TOTAL=$((TOTAL + 1))
_home_output=$(echo "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to workshop
travel to workshop" | "$DFROTZ" -h 999 -w 200 "$Z5" 2>&1)
_after_home=$(echo "$_home_output" | grep -n "already home" | tail -1 | cut -d: -f1)
if [ -n "$_after_home" ]; then
    _tail=$(echo "$_home_output" | tail -n +"$_after_home")
    if echo "$_tail" | grep -qi "reality folds"; then
        FAIL=$((FAIL + 1))
        echo "  FAIL: Already home no animation (should NOT contain: reality folds after already home)"
    else
        PASS=$((PASS + 1))
        echo "  PASS: Already home no animation"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  FAIL: Already home no animation (could not find already home marker)"
fi

# --- Time Travel ---
echo "[Time Travel]"
run_test "Travel to Blitz" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz" "1941"
run_test "Crookes tube shatters in Blitz transit" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz" "champagne flute"
run_test "Eras must be sequential" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to cambridge" "reach that far yet"

# --- WWII London ---
echo "[WWII London]"
# Get lodestone, impress Marcus, install lodestone, then travel to Blitz
BLITZ_SETUP="$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz"
run_test "Blitz street" "$BLITZ_SETUP" "blackout"
run_test "Shelter accessible" "$BLITZ_SETUP
down" "air raid shelter"
run_test "Tommy present" "$BLITZ_SETUP
down" "Corporal Tommy"
run_test "Eleanor present" "$BLITZ_SETUP
down" "Young Eleanor"
run_test "Rubble site" "$BLITZ_SETUP
west" "Finch"
run_test "Take radio valve" "$BLITZ_SETUP
west
take valve" "Taken"
# Regression: after taking valve, room description should not mention it (issue #2)
TOTAL=$((TOTAL + 1))
_valve_output=$(echo "$BLITZ_SETUP
west
take valve
look" | "$DFROTZ" -h 999 -w 200 "$Z5" 2>&1)
# Extract text after the LAST "Taken" line (multiple items are taken during setup)
_last_taken=$(echo "$_valve_output" | grep -n "^Taken" | tail -1 | cut -d: -f1)
_after_taken=$(echo "$_valve_output" | tail -n +"$_last_taken")
if echo "$_after_taken" | grep -qi "A radio valve lies in the accessible rubble"; then
    FAIL=$((FAIL + 1))
    echo "  FAIL: Valve not in rubble desc after taking (should NOT contain: A radio valve lies in the accessible rubble)"
else
    PASS=$((PASS + 1))
    echo "  PASS: Valve not in rubble desc after taking"
fi
TOTAL=$((TOTAL + 1))
if echo "$_after_taken" | grep -qi "metal box glinting under heavy debris"; then
    PASS=$((PASS + 1))
    echo "  PASS: Metal box still mentioned after taking valve"
else
    FAIL=$((FAIL + 1))
    echo "  FAIL: Metal box still mentioned after taking valve (expected: metal box glinting under heavy debris)"
fi
run_test "Fix Tommy's radio" "$BLITZ_SETUP
west
take valve
east
down
give valve to tommy" "crackles to life"
run_test "Tommy helps dig" "$BLITZ_SETUP
west
take valve
east
down
give valve to tommy
ask tommy about rubble" "willing to help"
run_test "Dig rubble" "$BLITZ_SETUP
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig" "Military supply"
run_test "Get vacuum tube" "$BLITZ_SETUP
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube" "temporal resonance"
run_test "Church inscription visible" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east
carve
west
south
repair machine
travel to blitz
north" "TEMPUS FUGIT"
run_test "Fire extinguish" "$BLITZ_SETUP
north
up
extinguish" "sputters and dies"
run_test "Throw sandbag at fire extinguishes" "$BLITZ_SETUP
north
up
throw sandbag at fire" "sputters and dies"
run_test "Throw sandbag at fire awards points" "$BLITZ_SETUP
north
up
throw sandbag at fire" "score has just gone up"
run_test "Throw sandbag at fire already out" "$BLITZ_SETUP
north
up
extinguish
throw sandbag at fire" "already out"
run_test_absent "Throw sandbag at fire no hint text" "$BLITZ_SETUP
north
up
throw sandbag at fire" "Try: extinguish"
run_test "Examine regulars by plural name" "$BLITZ_SETUP
east
examine regulars" "friendly suspicion"
run_test "Examine patrons by plural name" "$BLITZ_SETUP
east
examine patrons" "friendly suspicion"
run_test "Examine drinkers by plural name" "$BLITZ_SETUP
east
examine drinkers" "friendly suspicion"
run_test "Police box easter egg" "$BLITZ_SETUP
east
examine poster" "just an ordinary"
run_test "Give soldier to Eleanor" "$BLITZ_SETUP
east
take soldier
west
down
give soldier to eleanor" "tin soldier"
run_test "Blitz machine buried" "$BLITZ_SETUP
look" "half-buried under rubble"
run_test "Blitz dig without Tommy" "$BLITZ_SETUP
dig" "someone strong"
run_test "Blitz dig machine with Tommy" "$BLITZ_SETUP
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
dig" "stands free"
run_test "Travel home from Blitz" "$BLITZ_SETUP
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
dig
travel to workshop" "back in the solarium"

# --- Cambridge ---
echo "[Cambridge 2009]"
# Get lodestone, impress Marcus, install lodestone, travel to Blitz, get tube, install tube, dig machine, travel to Cambridge
CAMBRIDGE_SETUP="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine
travel to cambridge"
run_test "Cambridge gates" "$CAMBRIDGE_SETUP" "Gonville"
run_test "Cambridge machine stable" "$CAMBRIDGE_SETUP
examine machine" "stable here"
run_test "Find invitation" "$CAMBRIDGE_SETUP
north
east" "invitation"
run_test "Porter blocks without invite" "$CAMBRIDGE_SETUP
north
north" "Invitation, please"
run_test "Give invitation to porter" "$CAMBRIDGE_SETUP
north
east
take invitation
west
give invitation to porter" "Great Hall"
run_test "Meet Hawking" "$CAMBRIDGE_SETUP
north
east
take invitation
west
give invitation to porter
north" "Hawking"

HAWKING_SETUP="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine
travel to cambridge
north
east
take invitation
west
give invitation to porter
north"
run_test "Tell Hawking about time" "$HAWKING_SETUP
tell hawking about time" "claim to be a time traveller"
run_test "Show journal to Hawking" "$HAWKING_SETUP
tell hawking about time
show journal to hawking" "Victorian"
CONVINCE_SETUP="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine
travel to cambridge
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show toolkit to hawking"
run_test "Convince Hawking" "$CONVINCE_SETUP" "you really are a time traveller"
run_test "Get formula printout" "$CONVINCE_SETUP
east
take printout" "seed of everything"

# --- Cambridge Install-As-You-Go ---
echo "[Cambridge Install-As-You-Go]"
# Cambridge: repair machine transcribes formula
run_test "Cambridge: repair transcribes formula" "$CAMBRIDGE_SETUP
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show toolkit to hawking
east
take printout
west
south
south
repair machine" "machine can AIM"

# Cambridge: transcribe formula synonym works
run_test "Cambridge: transcribe formula synonym" "$CAMBRIDGE_SETUP
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show toolkit to hawking
east
take printout
west
south
south
transcribe formula" "machine can AIM"

# Cambridge: can't travel to Future without formula transcribed
run_test "Cambridge: blocked without formula" "$CAMBRIDGE_SETUP
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show toolkit to hawking
east
take printout
west
south
south
travel to future" "can.t aim this far"

# --- Future London ---
echo "[Future London 2045]"
# Full path: Roman (lodestone + repair + marcus) -> Blitz (tube + repair + dig) -> Cambridge (formula + repair) -> Future
FUTURE_SETUP="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine
travel to cambridge
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show toolkit to hawking
east
take printout
west
south
south
repair machine
travel to future"
run_test "Future transit: crystal cracked" "$FUTURE_SETUP" "fracture line"
run_test "Future machine: all three damaged" "$FUTURE_SETUP
examine machine" "crack runs clean through"
run_test "Future flooded street" "$FUTURE_SETUP" "Thames won"
run_test "Future machine sank" "$FUTURE_SETUP
look" "sank on arrival"
run_test "Future gate blocks without diving gear" "$FUTURE_SETUP
travel to workshop" "sank when it arrived"
run_test "Museum accessible" "$FUTURE_SETUP
north" "Thames Barrier Museum"
run_test "DeLorean easter egg" "$FUTURE_SETUP
north
examine delorean" "documentary"
run_test "Kai on walkway" "$FUTURE_SETUP
east" "Kai"
run_test "Open panel with toolkit" "$FUTURE_SETUP
north
up
open panel" "fixed it"
run_test "Get diving gear" "$FUTURE_SETUP
north
up
open panel" "diving gear"
run_test "Submerged lab accessible" "$FUTURE_SETUP
north
up
open panel
down
south
down" "research laboratory"
run_test "Swim in floodwater" "$FUTURE_SETUP
swim" "unusual method of suicide"
run_test "Museum display cases" "$FUTURE_SETUP
north
examine cases" "sausage roll"
run_test "Museum display cases (displays)" "$FUTURE_SETUP
north
examine displays" "sausage roll"
run_test "Museum telephone box" "$FUTURE_SETUP
north
examine telephone" "K6 telephone box"
run_test "Museum telephone box (box)" "$FUTURE_SETUP
north
examine box" "K6 telephone box"
run_test "Museum underground signs" "$FUTURE_SETUP
north
examine signs" "Underground roundels"
run_test "Museum underground signs (underground)" "$FUTURE_SETUP
north
examine underground" "Underground roundels"
run_test "Museum Evening Standard" "$FUTURE_SETUP
north
examine standard" "THAMES BARRIER FAILS"
run_test "Museum Evening Standard (copies)" "$FUTURE_SETUP
north
examine copies" "THAMES BARRIER FAILS"
run_test "Museum Evening Standard (evening)" "$FUTURE_SETUP
north
examine evening" "THAMES BARRIER FAILS"
run_test "Cabinet needs formula" "$FUTURE_SETUP
north
up
open panel
down
south
down
open cabinet" "temporal harmonic sequence"

# --- Future Install-As-You-Go ---
echo "[Future Install-As-You-Go]"
# Future: repair machine installs processor
run_test "Future: repair installs processor" "$FUTURE_SETUP
north
up
open panel
down
south
down
open cabinet
take processor
up
repair machine" "temporal field generator is restored"

# Future: 'take crystal' synonym works (issue #96)
run_test "Take crystal synonym for processor" "$FUTURE_SETUP
north
up
open panel
down
south
down
open cabinet
take crystal" "crystalline processor"

# Future: can't travel to Workshop without processor installed
run_test "Future: blocked without processor" "$FUTURE_SETUP
north
up
open panel
down
south
down
open cabinet
take processor
up
travel to workshop" "crystal is cracked"

# --- Endgame ---
echo "[Endgame]"
# Full endgame: repair at each era, collect components, travel home, clean
ENDGAME_CMD="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine
travel to cambridge
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show toolkit to hawking
east
take printout
west
south
south
repair machine
travel to future
north
up
open panel
down
south
down
open cabinet
take processor
up
repair machine
travel to workshop
west
clean
open front door"
run_test "Install all components" "$ENDGAME_CMD" "fully repaired"
run_test "Game ends with win" "$ENDGAME_CMD" "ENDING"
run_test "Final score displayed" "$ENDGAME_CMD" "out of a possible 183"

# --- Bootstrap Paradox Endgame ---
echo "[Bootstrap Paradox]"
run_test "Three knocks after tidying" "$ENDGAME_CMD" "Knock. Knock. Knock"
run_test "Player recognises own knocks" "$ENDGAME_CMD" "Your knocks"
run_test "Bootstrap loop closes" "$ENDGAME_CMD" "loop is closed"
run_test "Dr Thyme returns after bootstrap" "$ENDGAME_CMD" "Dr. Thyme has returned from tea"

# Auto-trigger bootstrap after 2 turns
ENDGAME_AUTO="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine
travel to cambridge
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show toolkit to hawking
east
take printout
west
south
south
repair machine
travel to future
north
up
open panel
down
south
down
open cabinet
take processor
up
repair machine
travel to workshop
west
clean
look
look"
run_test "Bootstrap auto-triggers after delay" "$ENDGAME_AUTO" "loop is closed"

# --- Ending Tiers ---
echo "[Ending Tiers]"
# Paradox ending: critical path only, no side quests (score = 85)
run_test "Paradox ending (critical path only)" "$ENDGAME_CMD" "PARADOX ENDING"

# Rough ending: critical path + give soldier to Eleanor (+25 = 110)
ROUGH_ENDGAME="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
east
take soldier
west
down
give soldier to eleanor
up
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine
travel to cambridge
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show toolkit to hawking
east
take printout
west
south
south
repair machine
travel to future
north
up
open panel
down
south
down
open cabinet
take processor
up
repair machine
travel to workshop
west
clean
open front door"
run_test "Rough ending (critical path + Eleanor gift)" "$ROUGH_ENDGAME" "ROUGH ENDING"

# Good ending: critical path + Eleanor (+25) + inscription (+20) + capsule (+20) = 150
GOOD_ENDGAME="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east
carve
west
south
south
bury
north
north
repair machine
travel to blitz
east
take soldier
west
down
give soldier to eleanor
up
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine
travel to cambridge
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show toolkit to hawking
east
take printout
west
south
south
repair machine
travel to future
north
up
open panel
down
south
down
open cabinet
take processor
up
repair machine
travel to workshop
west
clean
open front door"
run_test "Good ending (critical path + 3 side quests)" "$GOOD_ENDGAME" "GOOD ENDING"

# Perfect ending: all events (score = 180)
PERFECT_ENDGAME="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east
carve
west
south
south
bury
north
north
repair machine
travel to blitz
east
take soldier
west
down
give soldier to eleanor
up
north
up
extinguish
down
south
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open box
take tube
east
dig
repair machine
travel to cambridge
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show toolkit to hawking
east
take printout
west
south
south
repair machine
travel to future
north
up
open panel
down
south
down
open cabinet
take processor
up
repair machine
travel to workshop
west
clean
open front door"
run_test "Perfect ending (all side quests)" "$PERFECT_ENDGAME" "PERFECT ENDING"

# --- Copernicus ---
echo "[Copernicus]"
run_test "Cat follows player" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
look" "Copernicus"
run_test "Cat examine" "$ENTER_WORKSHOP
examine cat" "magnificently smug ginger tabby"
run_test "Can't take cat before accident" "$ENTER_WORKSHOP
take cat" "boneless"

# --- Help ---
echo "[Help System]"
run_test "Help command" "help" "TEMPORAL APPRENTICE"

# --- Kill Hitler Easter Egg ---
echo "[Easter Eggs]"
run_test "Kill Hitler response" "$BLITZ_SETUP
kill hitler" "family-friendly"

# --- Buffer overflow on long input ---
echo "[Buffer Overflow]"
run_test_absent "No programming error on long input" "knock on door
knock on door
knock on door
enter
the quick brown fox jumps over the lazy dog and then does it again because why not keep going with this absurdly long sentence that serves no purpose whatsoever
quit
y" "Programming error"

# --- Travel-to scope outside workshop ---
echo "[Travel-to Scope]"
run_test "Travel to dest where machine is not" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
travel to blitz" "time machine isn.t here"
run_test "Travel to dest before cat accident not in scope" "travel to roman" "can.t see any such thing"

# --- Scenery objects ---
echo "[Scenery Objects]"
run_test "Examine door in Workshop Entrance" "examine door" "heavy oak door"
run_test "Examine brass plate in Workshop Entrance" "examine brass plate" "TEMPORAL ENGINEERING"
run_test "Examine shelves in Main Workshop" "$ENTER_WORKSHOP
examine shelves" "Floor-to-ceiling shelves"
run_test "Examine marmalade in Main Workshop" "$ENTER_WORKSHOP
examine marmalade" "Seville orange"
run_test "Examine column in Roman Forum" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine column" "Corinthian column"
run_test "Examine citizens in Roman Forum" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine citizens" "Toga-clad citizens"
run_test "Examine citizen in Roman Bathhouse" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
examine citizen" "Toga-clad citizens"
run_test "Examine pools in Roman Bathhouse" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
examine pools" "tepidarium"
run_test "Examine stained glass in Bombed Church" "$BLITZ_SETUP
north
examine stained glass" "fragments of saints"
run_test "Examine church in Bombed Church" "$BLITZ_SETUP
north
examine church" "St. Margaret"
run_test "Examine parapet on Rooftop" "$BLITZ_SETUP
north
up
examine parapet" "low stone parapet"
run_test "Examine pub in Crown and Anchor" "$BLITZ_SETUP
east
examine pub" "Crown and Anchor"
run_test "Examine sign in Rubble Site" "$BLITZ_SETUP
west
examine sign" "FI CH"
run_test "Examine stalls in Merchant Quarter" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
examine stalls" "Ramshackle wooden stalls"
run_test "Examine boats at Roman Docks" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
south
examine boats" "flat-bottomed cargo"

# --- New scenery: Main Workshop ---
echo "[Scenery: Main Workshop]"
run_test "Examine jars in Main Workshop" "$ENTER_WORKSHOP
examine jars" "not found in any paint catalogue"
run_test "Examine liquids in Main Workshop" "$ENTER_WORKSHOP
examine liquids" "not found in any paint catalogue"
run_test "Examine diagrams in Main Workshop" "$ENTER_WORKSHOP
examine diagrams" "inner workings"
run_test "Examine instruments in Main Workshop" "$ENTER_WORKSHOP
examine instruments" "emotional state of copper"
run_test "Examine scorch mark in Main Workshop" "$ENTER_WORKSHOP
examine scorch" "TUESDAY"

# --- New scenery: Solarium ---
echo "[Scenery: Solarium]"
run_test "Examine controls in Solarium" "$ENTER_SOLARIUM
examine controls" "bicycle bell"
run_test "Examine levers in Solarium" "$ENTER_SOLARIUM
examine levers" "bicycle bell"
run_test "Examine bell in Solarium" "$ENTER_SOLARIUM
examine bell" "bicycle bell"
run_test "Examine compass in Solarium" "$ENTER_SOLARIUM
examine compass" "bicycle bell"
run_test "Corridor door from Solarium" "$ENTER_SOLARIUM
examine door" "corridor"

# --- New scenery: Store Room ---
echo "[Scenery: Store Room]"
run_test "Examine crates in Store Room" "$ENTER_WORKSHOP
north
examine crates" "TEMPORAL BITS"
run_test "Examine labels in Store Room" "$ENTER_WORKSHOP
north
examine labels" "TEMPORAL BITS"

# --- New scenery: Roman Forum ---
echo "[Scenery: Roman Forum]"
run_test "Examine forum in Roman Forum" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine forum" "civic heart"
run_test "Examine soldiers at Marcus" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine soldiers" "centurion"

# --- New scenery: Via Principalis ---
echo "[Scenery: Via Principalis]"
run_test "Examine soldiers on Via" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north
examine soldiers" "mechanical precision"
run_test "Examine barracks on Via" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north
examine barracks" "paved with meticulous"
run_test "Examine road on Via" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north
examine road" "paved with meticulous"
run_test "Examine horizon on Via" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north
examine horizon" "columns of smoke"

# --- New scenery: Temple of Mithras ---
echo "[Scenery: Temple of Mithras]"
run_test "Examine torches in Temple" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east
examine torches" "iron brackets"
run_test "Examine altar in Temple" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east
examine altar" "clay figurines"
run_test "Examine carvings in Temple" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east
examine carvings" "cosmic bull"

# --- New scenery: Merchant's Quarter ---
echo "[Scenery: Merchant's Quarter]"
run_test "Examine merchants in Quarter" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
examine merchants" "elevated commerce"
run_test "Examine amulets in Quarter" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
examine amulets" "ward off everything"

# --- New scenery: Blacked-Out Street ---
echo "[Scenery: Blacked-Out Street]"
run_test "Examine rubble on street" "$BLITZ_SETUP
examine rubble" "scattered across the street"
run_test "Examine darkness on street" "$BLITZ_SETUP
examine darkness" "blackout is absolute"
run_test "Examine blackout on street" "$BLITZ_SETUP
examine blackout" "blackout is absolute"
run_test "Examine sky on street" "$BLITZ_SETUP
examine sky" "blackout is absolute"

# --- New scenery: Underground Shelter ---
echo "[Scenery: Underground Shelter]"
run_test "Examine blankets in shelter" "$BLITZ_SETUP
down
examine blankets" "Blitz spirit"
run_test "Examine thermoses in shelter" "$BLITZ_SETUP
down
examine thermoses" "Blitz spirit"
run_test "Examine platform in shelter" "$BLITZ_SETUP
down
examine platform" "tube station platform"
run_test "Examine drawings in shelter" "$BLITZ_SETUP
down
examine drawings" "salvaged paper"

# --- New scenery: Bombed Church ---
echo "[Scenery: Bombed Church]"
run_test "Examine roof in church" "$BLITZ_SETUP
north
examine roof" "Half the roof is gone"
run_test "Examine inscription on church walls" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east
carve
west
south
repair machine
travel to blitz
north
examine inscription" "TEMPUS FUGIT"

# --- New scenery: Fire Watch Rooftop ---
echo "[Scenery: Rooftop]"
run_test "Examine London from rooftop" "$BLITZ_SETUP
north
up
examine london" "blacked-out London"
run_test "Examine skyline from rooftop" "$BLITZ_SETUP
north
up
examine skyline" "blacked-out London"
run_test "Examine view from rooftop" "$BLITZ_SETUP
north
up
examine view" "blacked-out London"

# --- New scenery: Rubble Site ---
echo "[Scenery: Rubble Site]"
run_test "Examine rubble in rubble site" "$BLITZ_SETUP
west
examine rubble" "Finch"
run_test "Examine debris in rubble site" "$BLITZ_SETUP
west
examine debris" "Finch"

# --- New scenery: Crown & Anchor ---
echo "[Scenery: Crown & Anchor]"
run_test "Examine beer in pub" "$BLITZ_SETUP
east
examine beer" "well-stocked"
run_test "Examine pint in pub" "$BLITZ_SETUP
east
examine pint" "well-stocked"
run_test "Examine curtains in pub" "$BLITZ_SETUP
east
examine curtains" "blackout curtains"
run_test "Examine fireplace in pub" "$BLITZ_SETUP
east
examine fireplace" "coal fire"
run_test "Examine fire in pub" "$BLITZ_SETUP
east
examine fire" "coal fire"

# --- New scenery: College Gates ---
echo "[Scenery: College Gates]"
run_test "Examine student in Gonville Hall" "$CAMBRIDGE_SETUP
north
east
take invitation
west
give invitation to porter
north
examine student" "academically terrified"
run_test "Examine notice at gates" "$CAMBRIDGE_SETUP
examine notice" "PROFESSOR HAWKING"
run_test "Examine gate at gates" "$CAMBRIDGE_SETUP
examine gate" "ancient stone gateway"

# --- New scenery: College Garden ---
echo "[Scenery: College Garden]"
run_test "Examine pond in garden" "$CAMBRIDGE_SETUP
north
east
examine pond" "ancient carp"
run_test "Examine carp in garden" "$CAMBRIDGE_SETUP
north
east
examine carp" "ancient carp"
run_test "Examine trees in garden" "$CAMBRIDGE_SETUP
north
east
examine trees" "immaculate lawns"
run_test "Examine lawn in garden" "$CAMBRIDGE_SETUP
north
east
examine lawn" "immaculate lawns"

# --- New scenery: Gonville Hall ---
echo "[Scenery: Gonville Hall]"
run_test "Examine balloons in hall" "$CAMBRIDGE_SETUP
north
east
take invitation
west
give invitation to porter
north
examine balloons" "feast for one"
run_test "Examine wheelchair in hall" "$CAMBRIDGE_SETUP
north
east
take invitation
west
give invitation to porter
north
examine wheelchair" "speech synthesiser"

# --- New scenery: Hawking's Study ---
echo "[Scenery: Hawking's Study]"
run_test "Examine desk in study" "$CONVINCE_SETUP
east
examine desk" "speech synthesiser"
run_test "Examine computer in study" "$CONVINCE_SETUP
east
examine computer" "speech synthesiser"
run_test "Examine books in study" "$CONVINCE_SETUP
east
examine books" "cosmology"
run_test "Examine models in study" "$CONVINCE_SETUP
east
examine models" "black holes"

# --- New scenery: Flooded Street ---
echo "[Scenery: Flooded Street]"
run_test "Examine catwalks in future" "$FUTURE_SETUP
examine catwalks" "rope bridges"
run_test "Examine bridges in future" "$FUTURE_SETUP
examine bridges" "rope bridges"
run_test "Examine water in future" "$FUTURE_SETUP
examine water" "Murky brown water"

# --- New scenery: Elevated Walkway ---
echo "[Scenery: Elevated Walkway]"
run_test "Examine railing on walkway" "$FUTURE_SETUP
east
examine railing" "salvaged metal"
run_test "Examine scaffolding on walkway" "$FUTURE_SETUP
east
examine scaffolding" "reclaimed scaffolding"

# --- New scenery: Museum ---
echo "[Scenery: Museum]"
run_test "Examine antenna on rooftop" "$FUTURE_SETUP
north
up
examine antenna" "panel"

# --- Issue #45: Missing scenery ---
echo "[Issue #45: Missing Scenery]"
run_test "Newspaper in inventory at start" "inventory" "newspaper"
run_test "Examine newspaper pre-accident" "examine newspaper" "tea stain"
run_test "Examine advert in newspaper" "examine advert" "TEMPORAL ENGINEERING"
run_test "Examine clock in Main Workshop" "$ENTER_WORKSHOP
examine clock" "brass clock"
run_test "Examine overcoat in Workshop Entrance" "examine overcoat" "overcoat"
run_test "Examine aspidistra in Solarium" "$ENTER_SOLARIUM
examine aspidistra" "aspidistras and maidenhair"
run_test "Examine maidenhair in Solarium" "$ENTER_SOLARIUM
examine maidenhair" "aspidistras and maidenhair"
run_test "Examine crystal in Solarium" "$ENTER_SOLARIUM
examine crystal" "crystal resonators"
run_test "Examine crystals in Solarium" "$ENTER_SOLARIUM
examine crystals" "crystal resonators"

# --- Newspaper Mechanics ---
echo "[Newspaper Mechanics]"
run_test "Cannot drop newspaper" "drop newspaper" "fold"
run_test "Post-accident headline defaults: Nothing of Interest" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine newspaper" "Nothing of Interest"
run_test "Post-accident headline defaults: Car Park" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine newspaper" "Car Park"
run_test "Post-accident ink not committed" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine newspaper" "not quite committed"

# Headline shift: inscription_carved
run_test "Headline shifts after inscription_carved" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east
carve
examine newspaper" "MYSTERIOUS INSCRIPTION"

# Headline shift: capsule_buried
run_test "Headline shifts after capsule_buried" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
south
bury
examine newspaper" "POCKET WATCH IN ROMAN STRATUM"

# Headline shift: eleanor_gift
run_test "Headline shifts after eleanor_gift" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
east
take soldier
west
down
give soldier to eleanor
up
examine newspaper" "ELEANOR MORRISON RETROSPECTIVE"

# Headline shift: church_saved
run_test "Headline shifts after church_saved" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
repair machine
travel to blitz
north
up
extinguish
down
south
examine newspaper" "600TH ANNIVERSARY"

# Newspaper lost during Future transit
run_test "Newspaper torn away message" "$FUTURE_SETUP" "rips the newspaper from your hands"
TOTAL=$((TOTAL + 1))
_future_inv_output=$(echo "$FUTURE_SETUP
inventory" | "$DFROTZ" -h 999 -w 200 "$Z5" 2>&1)
# Extract text after the last "inventory" prompt (the actual inventory listing)
_inv_line=$(echo "$_future_inv_output" | grep -n "carrying" | tail -1 | cut -d: -f1)
if [ -n "$_inv_line" ]; then
    _inv_tail=$(echo "$_future_inv_output" | tail -n +"$_inv_line")
    if echo "$_inv_tail" | grep -qi "newspaper"; then
        FAIL=$((FAIL + 1))
        echo "  FAIL: Newspaper gone from inventory after Future transit (should NOT contain: newspaper in inventory)"
    else
        PASS=$((PASS + 1))
        echo "  PASS: Newspaper gone from inventory after Future transit"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  FAIL: Newspaper gone from inventory after Future transit (could not find inventory listing)"
fi

# Museum newspaper display
run_test "Museum newspaper display: tea stain" "$FUTURE_SETUP
north" "tea stain"
run_test "Museum newspaper display: SEALED AMPHORA" "$FUTURE_SETUP
north" "SEALED AMPHORA"
run_test "Museum newspaper examine: display case sealed" "$FUTURE_SETUP
north
take newspaper" "display case is sealed"
run_test "Museum newspaper examine: tea stain through glass" "$FUTURE_SETUP
north
examine newspaper" "tea stain"

# --- Issue #75: insert/enter/board machine ---
echo "[Issue #75: Machine Insert/Enter/Board]"
# Setup: get to Roman forum with lodestone in inventory, machine present
MACHINE_CMD_SETUP="$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus"
run_test "Insert lodestone in machine hints repair" "$MACHINE_CMD_SETUP
insert lodestone in machine" "REPAIR MACHINE"
run_test_absent "Insert lodestone no generic refusal" "$MACHINE_CMD_SETUP
insert lodestone in machine" "can.t contain things"
run_test "Enter machine hints travel" "$MACHINE_CMD_SETUP
enter machine" "TRAVEL TO"
run_test_absent "Enter machine no generic refusal" "$MACHINE_CMD_SETUP
enter machine" "not something you can enter"
run_test "Board machine hints travel" "$MACHINE_CMD_SETUP
board machine" "TRAVEL TO"
run_test_absent "Board machine no unrecognised verb" "$MACHINE_CMD_SETUP
board machine" "not a verb I recognise"

# --- Issue #72: climb onto machine ---
echo "[Issue #72: Climb Machine]"
run_test "Climb machine hints travel" "$MACHINE_CMD_SETUP
climb machine" "TRAVEL TO"
run_test_absent "Climb machine no generic refusal" "$MACHINE_CMD_SETUP
climb machine" "can.t see any such thing"
run_test "Get on machine hints travel" "$ENTER_SOLARIUM
get on machine" "TRAVEL TO"

# --- Issue #77: Praed Street & Brass Tap ---
echo "[Issue #77: Praed Street & Brass Tap]"

# Sequence to reach Praed Street (after Thyme departs)
REACH_PRAED="knock
knock
knock
east
take spanner
give spanner to dr thyme
talk to dr thyme
west
west"

# West blocked before Thyme departs (from workshop entrance, before entering workshop)
run_test "West blocked before Thyme departs" "knock
knock
knock
west" "literally just started this job"

# West accessible after Thyme departs
run_test "Praed Street accessible post-departure" "$REACH_PRAED" "Praed Street"

# Praed Street room description
run_test "Praed Street description: fog" "$REACH_PRAED" "curtain of London fog"
run_test "Praed Street description: Brass Tap sign" "$REACH_PRAED" "BRASS TAP"

# Workshop entrance description updates after Thyme departs
run_test "Workshop entrance mentions street post-departure" "knock
knock
knock
east
take spanner
give spanner to dr thyme
talk to dr thyme
west
look" "Praed Street"

# Praed Street scenery
run_test "Examine street gas lamps" "$REACH_PRAED
examine lamps" "disapproving aunts"
run_test "Examine street fog" "$REACH_PRAED
examine fog" "pea-soup"
run_test "Examine hansom cabs" "$REACH_PRAED
examine cabs" "ghosts with hooves"
run_test "Examine hanging sign" "$REACH_PRAED
examine sign" "wrought-iron bracket"
run_test "Examine street cobblestones" "$REACH_PRAED
examine cobblestones" "horse-related matter"

# Praed Street directional blocks
run_test "Praed Street north blocked" "$REACH_PRAED
north" "hansom cab"
run_test "Praed Street west blocked" "$REACH_PRAED
west" "fog thickens"

# Return east to workshop entrance
run_test "Return to workshop from Praed Street" "$REACH_PRAED
east" "narrow alley off Praed Street"

# Brass Tap accessible from Praed Street
run_test "Brass Tap accessible from Praed Street" "$REACH_PRAED
south" "Brass Tap"
run_test "Brass Tap description: bar" "$REACH_PRAED
south" "mahogany bar"
run_test "Brass Tap description: barkeep" "$REACH_PRAED
south" "barkeep"
run_test "Brass Tap description: coal fire" "$REACH_PRAED
south" "coal fire"

# Brass Tap scenery
run_test "Examine mahogany bar" "$REACH_PRAED
south
examine bar" "dinner plates"

# Brass Tap: use 'in' from Praed Street
run_test "Enter Brass Tap with 'in'" "$REACH_PRAED
in" "Brass Tap"

# Brass Tap scenery examination
run_test "Examine fire in Brass Tap" "$REACH_PRAED
south
examine fire" "OLD TOM"
run_test "Examine bottles in Brass Tap" "$REACH_PRAED
south
examine bottles" "amber whisky"
run_test "Examine dartboard in Brass Tap" "$REACH_PRAED
south
examine dartboard" "lunar surface"

# Brass Tap directional blocks
run_test "Brass Tap east blocked" "$REACH_PRAED
south
east" "dartboard"
run_test "Brass Tap west blocked" "$REACH_PRAED
south
west" "coal fire"
run_test "Brass Tap south blocked" "$REACH_PRAED
south
south" "solid brick"

# Return north from Brass Tap
run_test "Return to Praed Street from Brass Tap" "$REACH_PRAED
south
north" "Praed Street"

# Barkeep NPC
run_test "Examine barkeep" "$REACH_PRAED
south
examine barkeep" "Victorian dreadnought"
run_test "Talk to barkeep" "$REACH_PRAED
south
talk to barkeep" "kidney pie"

# Barkeep Ask topics
run_test "Ask barkeep about Thyme" "$REACH_PRAED
south
ask barkeep about thyme" "tips well"
run_test "Ask barkeep about beer" "$REACH_PRAED
south
ask barkeep about beer" "Whitbread"
run_test "Ask barkeep about pub" "$REACH_PRAED
south
ask barkeep about pub" "1847"
run_test "Ask barkeep about time travel" "$REACH_PRAED
south
ask barkeep about time" "parrot"
run_test "Ask barkeep about Praed Street" "$REACH_PRAED
south
ask barkeep about praed" "Paddington"
run_test "Ask barkeep about pie" "$REACH_PRAED
south
ask barkeep about pie" "Mrs. Gresham"
run_test "Ask barkeep about cat" "$REACH_PRAED
south
ask barkeep about cat" "Old Tom"
run_test "Ask barkeep about Mrs Pemberton" "$REACH_PRAED
south
ask barkeep about pemberton" "scones"
run_test "Ask barkeep unknown topic" "$REACH_PRAED
south
ask barkeep about quantum" "bitter"

echo ""
echo "--- Kick verb ---"
run_test "Kick cat shaming response" "$ENTER_WORKSHOP
kick cat" "withering contempt"
run_test "Kick non-cat generic refusal" "$ENTER_WORKSHOP
kick workbench" "decide against kicking"
run_test "Bare kick" "$ENTER_WORKSHOP
kick" "air"

echo ""
echo "--- Meow verb ---"
run_test "Meow at cat" "$ENTER_WORKSHOP
meow at cat" "chirrup"
run_test "Meow alone near cat" "$ENTER_WORKSHOP
meow" "chirrup"
run_test "Mew at cat synonym" "$ENTER_WORKSHOP
mew at cat" "chirrup"
run_test "Miaow at cat synonym" "$ENTER_WORKSHOP
miaow at cat" "chirrup"
run_test "Meow at NPC" "$ENTER_WORKSHOP
meow at dr thyme" "visible concern"
run_test "Meow alone no cat" "meow" "empty room"
run_test "Meow at named Copernicus" "$ENTER_WORKSHOP
examine tag
meow at cat" "Copernicus"
run_test_absent "Meow not unrecognised verb" "$ENTER_WORKSHOP
meow at cat" "not a verb I recognise"

echo ""
echo "=== Results ==="
echo "  Passed: $PASS / $TOTAL"
if [ "$FAIL" -gt 0 ]; then
    echo "  Failed: $FAIL"
    exit 1
else
    echo "  All tests passed!"
    exit 0
fi
