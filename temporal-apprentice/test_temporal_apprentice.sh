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

# --- Spanner Puzzle ---
echo "[Spanner Puzzle]"
run_test "Spanner on shelf" "$ENTER_WORKSHOP
look" "spanner"
run_test "Take spanner" "$ENTER_WORKSHOP
take spanner" "Taken"
run_test "Give spanner to Thyme" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme" "new apprentice"
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
run_test "Score for accident" "$ENTER_WORKSHOP
$CAT_ACCIDENT
score" "15 out of"

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

# --- Examine machine before accident ---
echo "[Machine Examine Pre-Accident]"
run_test "Examine machine in solarium" "$ENTER_SOLARIUM
examine machine" "barely contained energy"
run_test_absent "Examine machine does not trigger accident" "$ENTER_SOLARIUM
examine machine" "ABSOLUTELY DO NOT TOUCH"

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
run_test "Gold aureus in bath" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west" "gold aureus"
run_test "Take aureus" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take aureus" "Taken"
run_test "Merchant quarter" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south" "Merchant"
run_test "Trade for lodestone" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take aureus
east
south
give aureus to felix" "lodestone"
run_test "Show lodestone to Marcus" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take aureus
east
south
give aureus to felix
north
show lodestone to marcus" "commands iron"
run_test "Temple accessible after Marcus" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
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
run_test "Travel to workshop from Roman" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
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
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to workshop
look" "worse for wear"

# --- Time Travel ---
echo "[Time Travel]"
run_test "Travel to Blitz" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to blitz" "1941"
run_test "Eras must be sequential" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to cambridge" "hasn.t stabilised"

# --- WWII London ---
echo "[WWII London]"
# Get lodestone, impress Marcus, then travel to Blitz
BLITZ_SETUP="$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
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
# Get lodestone, impress Marcus, travel to Blitz, dig machine, travel to Cambridge
CAMBRIDGE_SETUP="$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
dig
travel to cambridge"
run_test "Cambridge gates" "$CAMBRIDGE_SETUP" "Gonville"
run_test "Cambridge machine dial jammed" "$CAMBRIDGE_SETUP
travel to future" "dial has seized"
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
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
dig
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
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
dig
travel to cambridge
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show lodestone to hawking"
run_test "Convince Hawking" "$CONVINCE_SETUP" "you really are a time traveller"
run_test "Get formula napkin" "$CONVINCE_SETUP
east
take napkin" "calibration formula"

# --- Future London ---
echo "[Future London 2045]"
# Full path: Roman (lodestone + marcus) -> Blitz (dig) -> Cambridge (formula) -> Future
FUTURE_SETUP="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
travel to blitz
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
dig
travel to cambridge
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show lodestone to hawking
east
take napkin
west
south
south
travel to future"
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
run_test "Museum Evening Standard (newspaper)" "$FUTURE_SETUP
north
examine newspaper" "THAMES BARRIER FAILS"
run_test "Cabinet needs formula" "$FUTURE_SETUP
north
up
open panel
down
south
down
open cabinet" "temporal harmonic sequence"

# --- Endgame ---
echo "[Endgame]"
# Minimal run: just get the 4 required components
# Full endgame: collect all 4 components, travel home, install, clean
ENDGAME_CMD="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
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
travel to cambridge
north
east
take invitation
west
give invitation to porter
north
tell hawking about time
show journal to hawking
show lodestone to hawking
east
take napkin
west
south
south
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
travel to workshop
install
west
clean"
run_test "Install all components" "$ENDGAME_CMD" "Temporal Displacement Engine is repaired"
run_test "Game ends with win" "$ENDGAME_CMD" "ENDING"
run_test "Final score displayed" "$ENDGAME_CMD" "out of a possible 180"

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
