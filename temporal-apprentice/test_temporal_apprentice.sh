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

# --- Compilation ---
echo "[Compilation]"
run_test "Game compiles and runs" "look" "Praed Street"

# --- Workshop Hub ---
echo "[Workshop Hub]"
run_test "Start location" "look" "Praed Street"
run_test "Go to workshop" "east" "cathedral of improbable engineering"
run_test "Take journal" "east
take journal" "Taken"
run_test "Store room accessible" "east
north" "Store Room"
run_test "Take toolkit" "east
north
take toolkit" "Taken"
run_test "Dr. Hartley present" "east" "Dr. Hartley"
run_test "Copernicus present" "east" "Copernicus"

# --- Cat accident ---
echo "[Cat Accident]"
run_test "Cat activates machine" "east
examine machine" "ABSOLUTELY DO NOT TOUCH"
run_test "Sent to Roman forum" "east
examine machine" "Roman Londinium"
run_test "Score for accident" "east
examine machine
score" "5 out of"

# --- Clean guard ---
echo "[Clean Guard]"
run_test_absent "No cleaning before cat accident" "east
clean" "Tools are returned"
run_test "Cleaning refused before cat accident" "east
clean" "doesn.t need cleaning yet"

# --- Roman Londinium ---
echo "[Roman Londinium]"
run_test "Forum description" "east
examine machine
look" "Forum"
run_test "Marcus blocks north" "east
examine machine
north" "Roman citizens and military"
run_test "Livia blocks temple" "east
examine machine
east" "Only the initiated"
run_test "Bathhouse accessible" "east
examine machine
west" "Steam billows"
run_test "Gold aureus in bath" "east
examine machine
west" "gold aureus"
run_test "Take aureus" "east
examine machine
west
take aureus" "Taken"
run_test "Merchant quarter" "east
examine machine
south" "Merchant"
run_test "Trade for lodestone" "east
examine machine
west
take aureus
east
south
give aureus to felix" "lodestone"
run_test "Show lodestone to Marcus" "east
examine machine
west
take aureus
east
south
give aureus to felix
north
show lodestone to marcus" "commands iron"
run_test "Temple accessible after Marcus" "east
examine machine
west
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east" "Temple of Mithras"
run_test "Carve inscription" "take watch
east
take journal
north
take toolkit
south
examine machine
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
run_test "Bury time capsule" "take watch
east
examine machine
south
south
bury" "two thousand years"
run_test "Temporal rift return" "east
examine machine
enter rift" "back in the workshop"

# --- Time Travel ---
echo "[Time Travel]"
run_test "Travel to Blitz" "east
examine machine
enter rift
travel to blitz" "1941"
run_test "Eras must be sequential" "east
examine machine
enter rift
travel to cambridge" "hasn.t stabilised"

# --- WWII London ---
echo "[WWII London]"
BLITZ_SETUP="east
examine machine
enter rift
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
_after_taken=$(echo "$_valve_output" | sed -n '/^Taken/,$p')
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
run_test "Church inscription visible" "take watch
east
take journal
north
take toolkit
south
examine machine
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
enter rift
travel to blitz
north" "TEMPUS FUGIT"
run_test "Fire extinguish" "$BLITZ_SETUP
north
up
extinguish" "sputters and dies"
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
run_test "Blitz rift return" "$BLITZ_SETUP
enter rift" "back in the workshop"

# --- Cambridge ---
echo "[Cambridge 2009]"
CAMBRIDGE_SETUP="east
examine machine
enter rift
travel to blitz
enter rift
travel to cambridge"
run_test "Cambridge gates" "$CAMBRIDGE_SETUP" "Gonville"
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

HAWKING_SETUP="east
take journal
north
take toolkit
south
examine machine
enter rift
travel to blitz
enter rift
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
CONVINCE_SETUP="east
take journal
north
take toolkit
south
examine machine
west
take aureus
east
south
give aureus to felix
north
enter rift
travel to blitz
enter rift
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
FUTURE_SETUP="east
north
take toolkit
south
examine machine
enter rift
travel to blitz
enter rift
travel to cambridge
enter rift
travel to future"
run_test "Future flooded street" "$FUTURE_SETUP" "Thames won"
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
ENDGAME_CMD="east
take journal
north
take toolkit
south
examine machine
west
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
enter rift
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
enter rift
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
enter rift
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
enter rift
install
clean"
run_test "Install all components" "$ENDGAME_CMD" "Temporal Displacement Engine is repaired"
run_test "Game ends with win" "$ENDGAME_CMD" "ENDING"
run_test "Final score displayed" "$ENDGAME_CMD" "out of a possible 165"

# --- Copernicus ---
echo "[Copernicus]"
run_test "Cat follows player" "east
examine machine
south
look" "Copernicus"
run_test "Cat examine" "east
examine copernicus" "magnificently smug ginger tabby"
run_test "Can't take cat" "east
examine machine
take copernicus" "boneless"

# --- Help ---
echo "[Help System]"
run_test "Help command" "help" "TEMPORAL APPRENTICE"

# --- Kill Hitler Easter Egg ---
echo "[Easter Eggs]"
run_test "Kill Hitler response" "east
examine machine
enter rift
travel to blitz
kill hitler" "family-friendly"

# --- Travel-to scope outside workshop ---
echo "[Travel-to Scope]"
run_test "Travel to dest outside workshop shows error" "east
examine machine
travel to blitz" "temporal rift to return to the workshop"
run_test "Travel to dest before cat accident not in scope" "travel to roman" "can.t see any such thing"

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
