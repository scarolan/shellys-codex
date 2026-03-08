#!/usr/bin/env bash
# Test harness for The Temporal Apprentice
# Compiles the game and runs automated tests using dfrotz

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INF="temporal_apprentice.inf"
Z5="temporal_apprentice.z8"
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
"$INFORM6" -v8 "$LIB" "$INF" "$Z5"
echo ""

echo "=== Running tests ==="

# Buy paper, visit pub for pencil, circle ad, go to workshop, show ad
ENTER_WORKSHOP="buy newspaper
south
take pencil
circle ad
north
east
knock
knock
knock
east
show newspaper to dr thyme"

# Enter workshop, do Thyme sequence, auto-unlock and enter solarium
ENTER_SOLARIUM="buy newspaper
south
take pencil
circle ad
north
east
knock
knock
knock
east
show newspaper to dr thyme
take spanner
give spanner to dr thyme
talk to dr thyme
east"

# Common trigger: the multi-step cat accident sequence
# Primary path: clean in workshop -> cat bolts to solarium -> chase -> take cat
# This variant enters solarium first, then cleans there (solarium fallback path):
# 1) show newspaper to dr thyme (gets hired)
# 2) take spanner, give spanner to dr thyme (introduces you)
# 3) talk to dr thyme (gives rag + key, Thyme leaves)
# 4) east (auto-unlocks and enters solarium, cat follows)
# 5) clean (cat steals rag on the spot in solarium)
# 6) take cat (cat kicks lever, accident fires -> Drainage Tunnels)
# 7) take cloak, wear cloak, north (exit tunnels to Forum)

# Cat accident ONLY — stays in tunnels (for testing machine/tunnels directly)
CAT_TO_TUNNELS="take spanner
give spanner to dr thyme
talk to dr thyme
east
clean
take cat"

# Cat accident + tunnel exit — arrives in Forum
CAT_ACCIDENT="take spanner
give spanner to dr thyme
talk to dr thyme
east
clean
take cat
take cloak
wear cloak
north"

# --- Compilation ---
echo "[Compilation]"
run_test "Game compiles and runs" "look" "Praed Street"

# --- Knock Mechanic ---
echo "[Knock Mechanic]"
run_test "Open door before knock" "east
open door" "locked from the inside"
run_test "First knock" "east
knock" "No response"
run_test "Second knock" "east
knock
knock" "something move inside"
run_test "Third knock opens door" "east
knock
knock
knock" "beginning to rain"
run_test "East blocked before knock" "east
east" "should knock"
run_test "East open after knock" "$ENTER_WORKSHOP" "cathedral"
run_test "Enter works after knock" "east
knock
knock
knock
enter" "cathedral"
run_test "Close door from outside" "east
knock
knock
knock
close door" "solid, satisfying thunk"
run_test "Door open after round-trip" "east
knock
knock
knock
west
east
look" "stands open"
run_test "Close door reverts description" "east
knock
knock
knock
close door
look" "closed"

# --- Spanner Puzzle ---
echo "[Spanner Puzzle]"
run_test "Spanner on shelf" "$ENTER_WORKSHOP
look" "spanner"
run_test "Take spanner" "$ENTER_WORKSHOP
take spanner" "Taken"
run_test "Give spanner to Thyme" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme" "follow instructions"
run_test "Give wrench to Thyme" "$ENTER_WORKSHOP
take spanner
give wrench to dr thyme" "follow instructions"
run_test "Hand spanner to Thyme" "$ENTER_WORKSHOP
take spanner
hand spanner to dr thyme" "follow instructions"
run_test "Hand wrench to Thyme" "$ENTER_WORKSHOP
take spanner
hand wrench to dr thyme" "follow instructions"
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
run_test "Store room hint on first visit" "$ENTER_WORKSHOP
north" "hasn.t quite finished being occupied"
run_test "Take toolkit" "$ENTER_WORKSHOP
north
take toolkit" "Taken"
run_test "Dr. Thyme present" "$ENTER_WORKSHOP" "Dr. Thyme"
run_test "Cat shown as silver-grey" "$ENTER_WORKSHOP" "silver-grey cat"
run_test_absent "Cat not named Copernicus initially" "$ENTER_WORKSHOP
look" "You can also see.*Copernicus"
run_test "Workshop mentions corridor" "$ENTER_WORKSHOP
look" "corridor runs east"
run_test_absent "No time machine in workshop" "$ENTER_WORKSHOP" "magnificent contraption"
run_test_absent "No 'This would be the time machine' text" "$ENTER_WORKSHOP" "This would be the time machine"

# --- Solarium ---
echo "[Solarium]"
run_test "Corridor blocked before Thyme departs" "$ENTER_WORKSHOP
east" "Dr. Thyme seems to need your attention"
run_test "Solarium auto-unlock with key" "$ENTER_SOLARIUM" "master key"
run_test "First entry glimpse" "$ENTER_SOLARIUM" "Something extraordinary"
run_test "Machine in solarium" "$ENTER_SOLARIUM
look" "contraption"
run_test "Ferns in solarium" "$ENTER_SOLARIUM" "ferns"
run_test "Cat appears in solarium" "$ENTER_SOLARIUM" "already here"
run_test "Basket on machine" "$ENTER_SOLARIUM
examine machine" "wicker basket"
run_test "Examine basket" "$ENTER_SOLARIUM
examine basket" "silver fur"
run_test "Basket tag reveals test subject" "$ENTER_SOLARIUM
examine luggage tag" "14 successful"
run_test "Basket bolted down" "$ENTER_SOLARIUM
take basket" "bolted firmly"
run_test "On-board accumulator in machine description" "$ENTER_SOLARIUM
examine machine" "lead-acid accumulator"
run_test "Examine accumulator" "$ENTER_SOLARIUM
examine accumulator" "ELECTROBAT TYPE"
run_test "Charging station in solarium" "$ENTER_SOLARIUM
examine charging station" "ST. PANCRAS"
run_test "Charging station has invoice" "$ENTER_SOLARIUM
examine charging station" "EXCESSIVE"

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
talk to dr thyme" "into the solarium"
run_test "Thyme departs" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
talk to dr thyme" "front door slams"
run_test "Thyme gives toolkit on departure" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
talk to dr thyme
inventory" "toolkit"
run_test "Cat on machine with rag" "$ENTER_SOLARIUM
clean
look" "cleaning rag dangling"
run_test "Cat steals rag" "$ENTER_SOLARIUM
clean" "snatches the rag"
run_test "Take cat triggers accident" "$ENTER_WORKSHOP
$CAT_ACCIDENT" "TEMPORAL ACCELERATOR"
run_test "Sent to Roman forum" "$ENTER_WORKSHOP
$CAT_ACCIDENT" "Roman Londinium"
run_test "Lodestone depleted in cat accident" "$ENTER_WORKSHOP
$CAT_ACCIDENT" "lodestone"
run_test "Score for accident" "$ENTER_WORKSHOP
$CAT_ACCIDENT
score" "15 out of"
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

# Cat bolt mechanic: cleaning in workshop triggers cat stealing rag and bolting to solarium
THYME_DEPARTED="buy newspaper
south
take pencil
circle ad
north
east
knock
knock
knock
east
show newspaper to dr thyme
take spanner
give spanner to dr thyme
talk to dr thyme"
run_test "Cat steals rag and bolts to solarium" "$THYME_DEPARTED
clean" "bolted east down the corridor"
run_test "Cat bolt mentions locked door" "$THYME_DEPARTED
clean" "cat flap in the solarium window"
run_test_absent "Cat bolt not superficial clean" "$THYME_DEPARTED
clean" "marginally less chaotic"
run_test "Cat on machine after bolt" "$THYME_DEPARTED
clean
east
look" "cleaning rag"

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
examine machine" "TEMPORAL ACCELERATOR"

echo "[Progressive Damage]"
# After cat accident (Roman): only lodestone mentioned
run_test "Roman era: lodestone fading" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
examine machine" "lodestone is fading"
run_test_absent "Roman era: no Crookes tube damage yet" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
examine machine" "Crookes tube is webbed"
# After Blitz transit: Crookes tube also broken
run_test "Blitz transit: Crookes tube shattered" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
examine machine" "Crookes tube is webbed"
# Crystal cracking during Future transit

# --- Install-As-You-Go ---
echo "[Install-As-You-Go]"
# Roman: repair machine installs lodestone
run_test "Roman: repair installs lodestone" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine" "lodestone into the compass housing"

# Issue #86: 'use' and 'replace' as repair synonyms
run_test "Roman: use installs lodestone (issue #86)" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
use lodestone" "lodestone into the compass housing"

run_test "Roman: replace installs lodestone (issue #86)" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
replace lodestone" "lodestone into the compass housing"

# Roman: can't travel to Blitz without lodestone installed
run_test "Roman: blocked without lodestone installed" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
travel forward" "compass housing is dark"

# Blitz: repair machine installs tube (needs toolkit)
run_test "Blitz: repair installs tube" "$ENTER_WORKSHOP
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
travel forward" "Crookes tube is fractured"

# (Cambridge and Future install-as-you-go tests are below, after their setups are defined)

# --- Roman Londinium ---
echo "[Roman Londinium]"
run_test "Forum description" "$ENTER_WORKSHOP
$CAT_ACCIDENT
look" "Forum"
run_test "Marcus blocks north" "$ENTER_WORKSHOP
$CAT_ACCIDENT
north" "Cives et milites solum"
run_test "Livia blocks temple" "$ENTER_WORKSHOP
$CAT_ACCIDENT
east" "Initiati solum"
run_test "Bathhouse accessible" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west" "Steam billows"
run_test_absent "Drain grate no rattling in room desc" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west" "rattles"
run_test_absent "Drain grate no movement hint in room desc" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west" "Something is moving"
run_test "Drain grate mentioned in room desc" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west" "drain grate"
run_test "Examine drain grate reveals glint" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
examine drain" "glints"
run_test "Copernicus bathhouse description" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
look" "dry marble ledge"
run_test "Fish visible in bathhouse" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west" "small silvery fish"
run_test "Take fish from pool" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish" "undignified chase"
run_test "Catch fish from pool" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
catch fish" "undignified chase"
run_test "Cat ignores grate without bribe" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
ask copernicus about grate" "loses interest"
run_test "Give fish to cat retrieves aureus via grate" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus" "gold coin rolls"
run_test_absent "Gold aureus not visible before retrieval" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west" "gold aureus"
run_test "Ask about grate after retrieval says done" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate" "already done his bit"
run_test "Take aureus after retrieval" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus" "Taken"
run_test "Ask about grate outside bathhouse hints redirect" "$ENTER_WORKSHOP
$CAT_ACCIDENT
ask copernicus about grate" "recall seeing one in the bathhouse"
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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix" "lodestone"
run_test "Buy lodestone completes transaction" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
buy lodestone" "lodestone"
run_test "Lodestone pulls at iron hooks on purchase" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix" "iron hooks"
run_test "Lodestone reacts entering Forum" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north" "straining toward the soldiers"
run_test "Lodestone reacts entering bathhouse" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
west" "iron grate"
run_test "Show lodestone to Marcus" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus" "commands iron"
run_test "Temple accessible after offering watch" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east" "Temple of Mithras"
run_test "Carve inscription" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
carve" "TEMPUS FUGIT"

# --- Carve synonyms (issue #85) ---
echo "[Carve Synonyms]"
run_test "carve stone with toolkit" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
carve stone with toolkit" "TEMPUS FUGIT"
run_test "carve stone with chisel" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
carve stone with chisel" "TEMPUS FUGIT"
run_test "engrave stone with toolkit" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
engrave stone with toolkit" "TEMPUS FUGIT"
run_test "inscribe stone with toolkit" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
inscribe stone with toolkit" "TEMPUS FUGIT"
run_test "bare carve still works" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
carve" "TEMPUS FUGIT"

run_test "Give watch to Livia grants temple access" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia" "Enter freely"
run_test "Livia demands offering after Marcus" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia" "demand.*offering"
run_test "Livia still blocks temple without offering" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
talk to livia
east" "Initiati solum"
run_test "Livia rejects non-watch gifts" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give coins to livia" "no need of material things"
run_test "Give aureus to Marcus gets rejection not parser error (issue #140)" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
give aureus to marcus" "Non corrumpor"
run_test "Give fish to Marcus gets rejection (issue #140)" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
east
give fish to marcus" "Non corrumpor"
run_test "Give journal to Marcus gets rejection (issue #140)" "$ENTER_WORKSHOP
take journal
$CAT_ACCIDENT
give journal to marcus" "Non corrumpor"
run_test "Give toolkit to Livia gets rejection (issue #140)" "$ENTER_WORKSHOP
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give toolkit to livia" "no need of material things"
run_test "Give journal to Livia gets rejection (issue #140)" "$ENTER_WORKSHOP
take journal
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give journal to livia" "no need of material things"
# --- Drainage Tunnels ---
echo "[Drainage Tunnels]"
run_test "Cat accident sends to tunnels" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
look" "vaulted tunnel of Roman brick"
run_test "Machine in tunnels after accident" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
look" "brass toad"
run_test "Skeleton visible in tunnels" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
examine skeleton" "slumped against the tunnel wall"
run_test "Take cloak from skeleton" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
take cloak" "Taken"
run_test "Wear cloak" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
take cloak
wear cloak" "pull the cloak"
run_test "Wear cloak implicit take" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
wear cloak" "pull the cloak"
run_test "Talk to skeleton" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
talk to skeleton" "dignified silence"
run_test "Ask skeleton about tunnels" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
ask skeleton about tunnels" "dignified silence"
run_test "Tell skeleton about tunnels" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
tell skeleton about tunnels" "dignified silence"
run_test "Can't go up without cloak" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
north" "arrested on sight"
run_test "Up with cloak reaches Forum" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
take cloak
wear cloak
north
look" "Forum"
run_test "Climb stairs without cloak gives disguise gate" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
climb stairs" "arrested on sight"
run_test "Enter stairway without cloak gives disguise gate" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
enter stairway" "arrested on sight"
run_test "Climb stairs with cloak reaches Forum" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
take cloak
wear cloak
climb stairs
look" "Forum"
run_test "Enter stairway with cloak reaches Forum" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
take cloak
wear cloak
enter stairway
look" "Forum"
run_test "Down from Forum returns to tunnels" "$ENTER_WORKSHOP
$CAT_ACCIDENT
down
look" "vaulted tunnel of Roman brick"
run_test "Machine gate: quest blocks travel" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
travel forward" "haven.t found what you need"
run_test "Machine gate: quest blocks repair" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
fix machine" "compass needle is dead"
run_test "Travel to workshop from Roman" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
travel to workshop" "back in the solarium"
run_test "Solarium has machine after travel home" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
travel to workshop
look" "worse for wear"
run_test "Already home guard" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
travel to workshop
travel to workshop" "already home"
TOTAL=$((TOTAL + 1))
_home_output=$(echo "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward" "1941"
run_test "Crookes tube shatters in Blitz transit" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward" "champagne flute"
run_test "Eras must be sequential" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
travel forward" "half-buried under rubble"

# --- WWII London ---
echo "[WWII London]"
# Get lodestone, impress Marcus, install lodestone, then travel to Blitz
BLITZ_SETUP="$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward"
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
ask tommy about rubble" "I'll help you dig"
run_test "Ask tommy for help (issue #87)" "$BLITZ_SETUP
down
ask tommy for help" "Fix my radio"
run_test "Ask tommy about help after radio fixed (issue #110)" "$BLITZ_SETUP
west
take valve
east
down
give valve to tommy
ask tommy about help" "help you dig"
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
run_test "Open crate synonym (issue #91)" "$BLITZ_SETUP
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
dig
open crate
take tube" "temporal resonance"
run_test "Church inscription visible" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
carve
west
down
repair machine
travel forward
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

# --- Fire Timer ---
echo "[Blitz Fire Timer]"
run_test "Fire starts on arrival" "$BLITZ_SETUP" "incendiaries come"
run_test "Peggy shouts on arrival" "$BLITZ_SETUP" "Shelter! NOW"
run_test "Church fire visible from street" "$BLITZ_SETUP
look" "Smoke and flame"
run_test "Fire active in church" "$BLITZ_SETUP
north" "Heat radiates from above"
run_test "Fire urgent on rooftop" "$BLITZ_SETUP
north
up" "this is what they.re for"
run_test "Save church in time" "$BLITZ_SETUP
north
up
extinguish" "sputters and dies"
run_test "Save church: rooftop after" "$BLITZ_SETUP
north
up
extinguish
look" "St. Margaret.s still stands"
run_test "Peggy approves after saving" "$BLITZ_SETUP
north
up
extinguish
down
south
talk to peggy" "Saved that church"
run_test "Church burns if you wait" "$BLITZ_SETUP
z
z
z
z
z
z
z
z
z
z
z
z" "roof of St. Margaret.s collapses"
run_test "Church burned: street description" "$BLITZ_SETUP
z
z
z
z
z
z
z
z
z
z
z
z
look" "gutted shell"
run_test "Church burned: rooftop blocked" "$BLITZ_SETUP
z
z
z
z
z
z
z
z
z
z
z
z
north
up" "choked with fallen timbers"
run_test "Peggy mourns burned church" "$BLITZ_SETUP
z
z
z
z
z
z
z
z
z
z
z
z
talk to peggy" "grandmother was married"
run_test "Fire escalation warning" "$BLITZ_SETUP
z
z
z
z
z
z
z" "Smoke pours from the church"
run_test "Fire countdown in shelter" "$BLITZ_SETUP
down
z
z
z
z
z
z
z
z" "Dust trickles from the ceiling"
run_test "Church collapse heard in shelter" "$BLITZ_SETUP
down
z
z
z
z
z
z
z
z
z
z
z
z" "That was St. Margaret"
run_test "Church collapse heard in pub" "$BLITZ_SETUP
east
z
z
z
z
z
z
z
z
z
z
z" "That was the church"

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

# --- Issue #126: QA bug fixes ---
echo "[Issue #126 QA Fixes]"
# Bug 1: "remove lodestone" should give a sensible message, not library default
run_test_absent "Remove lodestone: no library default (issue #126)" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
remove lodestone" "isn.t in or on anything"
run_test "Remove lodestone: sensible message (issue #126)" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
remove lodestone" "mounted in the compass housing"
# Bug 2: installing lodestone should not say "One component down"
run_test_absent "No 'component down' on lodestone install (issue #126)" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine" "One component down"
# Bug 3: Tommy visible at rubble site when helping
run_test "Tommy at rubble site when helping (issue #126)" "$BLITZ_SETUP
west
take valve
east
down
give valve to tommy
ask tommy about rubble
up
west
look" "Tommy"

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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
travel forward"
run_test "Cambridge gates" "$CAMBRIDGE_SETUP" "Gonville"
run_test "Return to Cambridge after travel home (issue #126)" "$CAMBRIDGE_SETUP
travel home
travel forward" "Gonville"
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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
travel forward
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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
travel forward
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

echo "[Hawking Item Dismissals]"
# Newspaper, watch, and key are in inventory at this point
run_test "Hawking dismisses newspaper" "$HAWKING_SETUP
give newspaper to hawking" "obtain one of these myself"
run_test "Hawking dismisses pocket watch" "$HAWKING_SETUP
give watch to hawking" "mechanical approximations"
run_test "Hawking dismisses front door key" "$HAWKING_SETUP
give key to hawking" "rather less mundane"
# Tin soldier: pick it up in Blitz pub (east from street) and keep it
HAWKING_WITH_SOLDIER="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
east
take soldier
west
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
travel forward
north
east
take invitation
west
give invitation to porter
north"
run_test "Hawking dismisses tin soldier" "$HAWKING_WITH_SOLDIER
give soldier to hawking" "nostalgia is not proof"

# --- Cambridge Party Timer ---
echo "[Cambridge Party Timer]"
# Timer is 40 turns. After arrival daemon fires: 39 effective turns.
# Warnings at: 30, 20, 12, 6, 3, 1. Party ends at 0.
# Generate wait sequences using printf
PARTY_WAIT_9=$(printf 'z\n%.0s' {1..9})     # reach turn 30
PARTY_WAIT_19=$(printf 'z\n%.0s' {1..19})   # reach turn 20
PARTY_WAIT_38=$(printf 'z\n%.0s' {1..38})   # reach turn 1
PARTY_WAIT_39=$(printf 'z\n%.0s' {1..39})   # reach turn 0
PARTY_WAIT_33=$(printf 'z\n%.0s' {1..33})   # reach turn 0 from hall (6 extra moves to get invitation + enter)
run_test "Party sound on arrival" "$CAMBRIDGE_SETUP" "champagne glasses"
run_test "Party hourglass hint" "$CAMBRIDGE_SETUP" "hourglass"
run_test "Party wind-down warning" "$CAMBRIDGE_SETUP
$PARTY_WAIT_19" "student passes"
run_test "Convince Hawking stops timer" "$CONVINCE_SETUP
$PARTY_WAIT_39" "temporal harmonics"
run_test "Party ends if too slow" "$CAMBRIDGE_SETUP
$PARTY_WAIT_38" "Destroy it"
run_test "Party over: game ends" "$CAMBRIDGE_SETUP
$PARTY_WAIT_39" "stranded in 2009"
run_test "Stranded epilogue: Whipple Museum" "$CAMBRIDGE_SETUP
$PARTY_WAIT_39" "Whipple Museum"
run_test "Stranded epilogue: cat has followers" "$CAMBRIDGE_SETUP
$PARTY_WAIT_39" "four thousand followers"
run_test "Party over: hall empty" "$CAMBRIDGE_SETUP
north
east
take invitation
west
give invitation to porter
north
$PARTY_WAIT_33
look" "no one came"
run_test "Destroy it warning from gates" "$CAMBRIDGE_SETUP
$PARTY_WAIT_38" "Destroy it"

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
travel forward" "can.t aim this far"

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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
travel forward
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
travel forward"
# --- Museum Invitation Display ---
echo "[Museum Invitation Display]"
run_test "Hawking invitation in museum" "$FUTURE_SETUP
north" "one guest is known to have attended"
run_test "Examine invitation display" "$FUTURE_SETUP
north
examine invitation" "Identity unknown"
run_test "Curator knows about Hawking party" "$FUTURE_SETUP
north
ask curator about hawking" "one person turned up"

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

# --- Future High Tide ---
echo "[Future High Tide]"
# Timer is 40 turns. After arrival daemon fires: 39 effective turns.
# Warnings at: 30, 20, 10, 4, 1. Tide hits at 0.
TIDE_WAIT_9=$(printf 'z\n%.0s' {1..9})      # reach turn 30
TIDE_WAIT_29=$(printf 'z\n%.0s' {1..29})    # reach turn 10
TIDE_WAIT_35=$(printf 'z\n%.0s' {1..35})    # reach turn 4
TIDE_WAIT_38=$(printf 'z\n%.0s' {1..38})    # reach turn 1
TIDE_WAIT_39=$(printf 'z\n%.0s' {1..39})    # reach turn 0

# Tide warning on arrival
run_test "Tide warning on arrival" "$FUTURE_SETUP" "RISING FAST TODAY"

# Tide water rising warning (turn 30: 9 waits)
run_test "Tide rising warning" "$FUTURE_SETUP
$TIDE_WAIT_9" "cat that wants feeding"

# Kai tide marker warning (turn 20: 2 waits + east + 16 waits)
TIDE_KAI=$(printf 'z\n%.0s' {1..16})
run_test "Kai tide marker warning" "$FUTURE_SETUP
z
z
east
$TIDE_KAI" "water.s not waiting"

# Torres tide warning (turn 20: 2 waits + west + 16 waits)
run_test "Torres tide warning" "$FUTURE_SETUP
z
z
west
$TIDE_KAI" "wouldn.t dawdle"

# Tide surging warning (turn 10: 29 waits)
run_test "Tide surging warning" "$FUTURE_SETUP
$TIDE_WAIT_29" "current is vicious"

# Tide last chance warning (turn 4: 35 waits)
run_test "Tide last chance warning" "$FUTURE_SETUP
$TIDE_WAIT_35" "last chance"

# Tide desperate warning (turn 1: 38 waits)
run_test "Tide desperate warning" "$FUTURE_SETUP
$TIDE_WAIT_38" "One more surge"

# Tide death: game over without processor (39 waits)
run_test "Tide death without processor" "$FUTURE_SETUP
$TIDE_WAIT_39" "stranded in 2045"

# Swept from lab when tide hits (5 turns to get gear + 33 waits + down to lab)
TIDE_WAIT_33=$(printf 'z\n%.0s' {1..33})
run_test "Swept from lab by tide" "$FUTURE_SETUP
north
up
open panel
down
south
$TIDE_WAIT_33
down" "sweeps you upward"

# Processor stops tide timer (get processor, then wait many turns — game continues)
TIDE_WAIT_40=$(printf 'z\n%.0s' {1..40})
run_test "Processor stops tide timer" "$FUTURE_SETUP
north
up
open panel
down
south
down
open cabinet
take processor
$TIDE_WAIT_40
inventory" "quantum processor"

# Tide-aware street description (rising)
run_test "Street shows rising tide" "$FUTURE_SETUP
z
z
z
z
z
z
look" "water has risen since you arrived"

# Ask Kai about tide
run_test "Ask Kai about tide" "$FUTURE_SETUP
east
ask kai about tide" "off-limits"

# Ask Torres about tide
run_test "Ask Torres about tide" "$FUTURE_SETUP
west
ask torres about tide" "tide turns twice a day"

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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
travel forward
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
travel forward
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
west
west
open door
east
north"
run_test "Install all components" "$ENDGAME_CMD" "tear a hole in the fabric of time"
run_test "Game ends with win" "$ENDGAME_CMD" "ENDING"
run_test "Final score displayed" "$ENDGAME_CMD" "out of a possible 209"

# --- Bootstrap Paradox Endgame ---
echo "[Bootstrap Paradox]"
run_test "Knocks at the door" "$ENDGAME_CMD" "KNOCK. KNOCK. KNOCK"
run_test "Player recognises own knocks" "$ENDGAME_CMD" "The exact time you arrived"
run_test "Bootstrap loop closes" "$ENDGAME_CMD" "loop is closed"
run_test "Dr Thyme returns after bootstrap" "$ENDGAME_CMD" "Dr. Thyme has returned from tea"

# Interactive endgame: door opens, player navigates to store room
# ENDGAME_DOOR ends after opening the front door (phase 1)
ENDGAME_DOOR="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
travel forward
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
travel forward
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
west
west
open door"
run_test "Phase 1: behind the door" "$ENDGAME_DOOR" "alone behind the front door"
run_test "Phase 1: east hint" "$ENDGAME_DOOR" "workshop is east"
run_test "Phase 1: can't leave" "$ENDGAME_DOOR
west" "loop breaks"
run_test "Phase 2: cross workshop" "$ENDGAME_DOOR
east" "four quick steps"
run_test "Phase 2: north hint" "$ENDGAME_DOOR
east" "store room"
run_test "Phase 2: wrong way east" "$ENDGAME_DOOR
east
east" "not the solarium"
run_test "Phase 2: talk to past self triggers paradox" "$ENDGAME_DOOR
east
talk to past self" "PARADOX COLLAPSE"
run_test "Phase 2: past self confrontation text" "$ENDGAME_DOOR
east
talk to past self" "That.s MY COAT"
run_test "Phase 1: past self not visible from entrance" "$ENDGAME_DOOR
talk to past self" "can.t see any such thing"

# Auto-trigger bootstrap after 2 turns
ENDGAME_AUTO="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
travel forward
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
travel forward
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
west
west
look
look
look
look
look
look"
run_test "Paradox collapse if door not opened" "$ENDGAME_AUTO" "PARADOX COLLAPSE"

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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
travel forward
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
travel forward
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
west
west
open door
east
north"
run_test "Rough ending (critical path + Eleanor gift)" "$ROUGH_ENDGAME" "ROUGH ENDING"

# Good ending: critical path + Eleanor (+25) + inscription (+20) + offering (+20) = 150
GOOD_ENDGAME="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
carve
west
down
repair machine
travel forward
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
travel forward
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
travel forward
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
west
west
open door
east
north"
run_test "Good ending (critical path + 3 side quests)" "$GOOD_ENDGAME" "GOOD ENDING"

# Perfect ending: all events (score = 209)
PERFECT_ENDGAME="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north
take amphora
south
south
south
bury newspaper
north
north
give watch to livia
east
carve
west
down
repair machine
travel forward
north
up
extinguish
down
south
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
travel forward
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
travel forward
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
clean workshop
west
west
open door
east
north"
run_test "Perfect ending (all side quests)" "$PERFECT_ENDGAME" "PERFECT ENDING"

# --- Copernicus ---
echo "[Copernicus]"
run_test "Cat follows player" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
look" "Copernicus"
run_test "Cat examine" "$ENTER_WORKSHOP
examine cat" "British Shorthair"
run_test "Can't take cat before accident" "$ENTER_WORKSHOP
take cat" "boneless"

# --- Help ---
echo "[Help System]"
run_test "Help command" "help" "TEMPORAL APPRENTICE"

# --- Kill Hitler Easter Egg ---
echo "[Easter Eggs]"
run_test "Kill Hitler response" "$BLITZ_SETUP
kill hitler" "family-friendly"

echo "[Magic Words]"
run_test "xyzzy easter egg" "xyzzy" "colossal cave"
run_test "plugh easter egg" "plugh" "Plugh yourself"
run_test "frotz easter egg" "frotz" "Frobozzian light spell"
run_test "nitfol easter egg" "nitfol" "animal communication"
run_test "blorb easter egg" "blorb" "archive format"

echo "[Profanity Handler]"
run_test_absent "Swear word not unrecognised" "fuck" "not a verb I recognise"
run_test_absent "British swear not unrecognised" "bollocks" "not a verb I recognise"

# --- Buffer overflow on long input ---
echo "[Buffer Overflow]"
run_test_absent "No programming error on long input" "east
knock on door
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
travel forward" "time machine isn.t here"
run_test "Travel to named dest before cat accident denied" "travel to roman" "don.t have a time machine"
run_test "Travel to roman denied after cat accident" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel to roman" "destination dial is damaged"
run_test_absent "Machine desc no named destinations" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
examine machine" "Roman Londinium"
run_test "Machine desc shows FORWARD and HOME" "$ENTER_WORKSHOP
$CAT_TO_TUNNELS
examine machine" "FORWARD and HOME"

# --- Travel synonym tests ---
echo "[Travel Synonyms]"

# Setup for travel synonym tests (in tunnels after cat accident with machine)
TRAVEL_GATE_SETUP="$ENTER_WORKSHOP
$CAT_TO_TUNNELS"

# Setup for travel home tests (in tunnels with lodestone installed)
TRAVEL_HOME_SETUP="$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine"

run_test "pull lever triggers forward travel" "$TRAVEL_GATE_SETUP
pull lever" "lodestone"
run_test "yank lever triggers forward travel" "$TRAVEL_GATE_SETUP
yank lever" "lodestone"
run_test "time travel triggers forward travel" "$TRAVEL_GATE_SETUP
time travel" "lodestone"
run_test "activate machine triggers forward travel" "$TRAVEL_GATE_SETUP
activate machine" "lodestone"
run_test "travel to blitz london triggers forward travel" "$TRAVEL_GATE_SETUP
travel to blitz london" "lodestone"
run_test "travel forward in time triggers forward travel" "$TRAVEL_GATE_SETUP
travel forward in time" "lodestone"
run_test "travel home returns to workshop" "$TRAVEL_HOME_SETUP
travel home" "solarium"
run_test "travel back returns to workshop" "$TRAVEL_HOME_SETUP
travel back" "solarium"

# --- Scenery objects ---
echo "[Scenery Objects]"
run_test "Examine door in Workshop Entrance" "east
examine door" "heavy oak door"
run_test "Examine brass plate in Workshop Entrance" "east
examine brass plate" "TEMPORAL ENGINEERING"
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

# --- Timepieces ---
echo "[Timepieces]"
run_test "Examine water clock in Bathhouse" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
examine water clock" "clepsydra"
run_test "Examine clepsydra in Bathhouse" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
examine clepsydra" "HOROLOGIUM AQUAE"
run_test "Examine pub clock" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
talk to dr thyme
west
west
south
examine clock" "twenty-three minutes past four"
run_test "Examine sundial in Forum" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine sundial" "bronze gnomon"
run_test "Examine workshop clock" "$ENTER_WORKSHOP
examine clock" "Adjusted for Temporal Drift"
run_test "HG Wells magazine in workshop" "$ENTER_WORKSHOP
examine magazine" "The Time Machine"
run_test "Wells margin notes: NICKEL BARS" "$ENTER_WORKSHOP
examine magazine" "NICKEL BARS"
run_test "Ask Thyme about Wells" "$ENTER_WORKSHOP
take spanner
give spanner to dr thyme
ask dr thyme about wells" "Nickel bars"
run_test "Examine study clock in Cambridge" "$CONVINCE_SETUP
east
examine clock" "three minutes fast"
run_test "Examine tide clock in Future" "$FUTURE_SETUP
west
examine tide clock" "WHEN THE HAND POINTS UP"

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

# --- Crookes tube scenery (issue #90) ---
echo "[Scenery: Crookes Tube]"
# Before accident: intact tube
run_test "Examine crookes tube pre-accident" "$ENTER_SOLARIUM
examine crookes tube" "hand-blown glass envelope"
# After Blitz transit but before replacement: fractured
run_test "Examine crookes tube post-blitz" "$BLITZ_SETUP
examine crookes tube" "webbed with fractures"
# After vacuum tube installation: replaced
TUBE_INSTALLED_SETUP="$ENTER_WORKSHOP
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
repair machine"
run_test "Examine crookes tube after replacement" "$TUBE_INSTALLED_SETUP
examine crookes tube" "military-grade vacuum tube"
# Ensure 'examine vacuum tube' still works for the portable object
run_test "Examine vacuum tube still works" "$BLITZ_SETUP
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
examine vacuum tube" "military-grade vacuum tube"
# Ensure 'examine machine' output is unchanged
run_test "Examine machine unchanged post-blitz" "$BLITZ_SETUP
examine machine" "Crookes tube is webbed"

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
take fish
give fish to copernicus
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
take fish
give fish to copernicus
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
take fish
give fish to copernicus
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
take fish
give fish to copernicus
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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
examine torches" "iron brackets"
run_test "Examine altar in Temple" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
examine altar" "clay figurines"
run_test "Examine carvings in Temple" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
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
run_test "Examine roof in church (fire active)" "$BLITZ_SETUP
north
examine roof" "timbers are ablaze"
run_test "Examine inscription on church walls" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
carve
west
south
repair machine
travel forward
north
examine inscription" "TEMPUS FUGIT"
run_test "Examine stone in church (inscription carved)" "$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
carve
west
south
repair machine
travel forward
north
examine stone" "TEMPUS FUGIT"

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

# --- Timepieces ---
echo "[Timepieces]"
# Roman: sundial in forum
run_test "Examine sundial in forum" "$ENTER_WORKSHOP
$CAT_ACCIDENT
examine sundial" "bronze gnomon"
# Roman: hourglass in temple (need lodestone chain + Marcus + Livia to enter)
run_test "Examine hourglass in temple" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
examine hourglass" "colour of dried blood"
# Roman: astrolabe at merchants
run_test "Examine astrolabe at merchants" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
examine astrolabe" "star maps"
# Blitz: distant clock tower
run_test "Examine clock tower in Blitz" "$BLITZ_SETUP
examine clock" "clock tower still chimes"
# Blitz: Tommy's wristwatch
run_test "Examine Tommy's wristwatch" "$BLITZ_SETUP
down
examine wristwatch" "luminous dial"
# Cambridge: Corpus Clock at gates
run_test "Examine Corpus Clock" "$CAMBRIDGE_SETUP
examine corpus" "Chronophage"
# Cambridge: mantel clock in study
run_test "Examine mantel clock in study" "$CONVINCE_SETUP
east
examine mantel clock" "three minutes fast"
# Future: memorial clock in museum
run_test "Examine memorial clock in museum" "$FUTURE_SETUP
north
examine memorial clock" "03:17 AM"
# Future: tide clock in refuge
run_test "Examine tide clock in refuge" "$FUTURE_SETUP
west
examine tide clock" "WHEN THE HAND POINTS UP"

# --- Timepiece NPC Dialogue ---
echo "[Timepiece NPC Dialogue]"
# Livia about hourglass
run_test "Ask Livia about hourglass" "$ENTER_WORKSHOP
$CAT_ACCIDENT
show lodestone to marcus
east
ask livia about hourglass" "measures the mysteries"
# Livia about sundial
run_test "Ask Livia about sundial" "$ENTER_WORKSHOP
$CAT_ACCIDENT
show lodestone to marcus
east
ask livia about sundial" "when to argue"
# Tommy about his wristwatch
run_test "Ask Tommy about wristwatch" "$BLITZ_SETUP
down
ask tommy about watch" "Standard issue"
# Hawking about Chronophage
run_test "Ask Hawking about Chronophage" "$CONVINCE_SETUP
ask hawking about chronophage" "eats time"
# Hawking about mantel clock
run_test "Ask Hawking about mantel clock" "$CONVINCE_SETUP
ask hawking about mantel" "someone I have not yet met"
# Torres about tide clock
run_test "Ask Torres about tide clock" "$FUTURE_SETUP
west
ask torres about clock" "yacht club"
# Curator about memorial clock
run_test "Ask curator about memorial clock" "$FUTURE_SETUP
north
ask curator about memorial" "3:17 AM"
# Tell curator (issue #118)
run_test "Tell curator produces character response" "$FUTURE_SETUP
north
tell curator about time" "scholarly patience"
run_test_absent "Tell curator no generic reaction" "$FUTURE_SETUP
north
tell curator about flood" "provokes no reaction"
# Ask curator about newspaper and time (issue #150)
run_test "Ask curator about newspaper" "$FUTURE_SETUP
north
ask curator about newspaper" "Fleet Street"
run_test "Ask curator about paper synonym" "$FUTURE_SETUP
north
ask curator about paper" "Fleet Street"
run_test "Ask curator about times synonym" "$FUTURE_SETUP
north
ask curator about times" "Fleet Street"
run_test "Ask curator about time" "$FUTURE_SETUP
north
ask curator about time" "machine for travelling"
run_test "Ask curator about travel synonym" "$FUTURE_SETUP
north
ask curator about travel" "machine for travelling"

# --- Issue #45: Missing scenery ---
echo "[Issue #45: Missing Scenery]"
run_test_absent "Newspaper not in inventory at start" "inventory" "carrying.*newspaper"
run_test "Examine newspaper pre-accident" "buy newspaper
examine newspaper" "fresh off the press"
run_test "Examine advert in newspaper" "buy newspaper
examine advert" "TEMPORAL ENGINEERING"
run_test "Examine clock in Main Workshop" "$ENTER_WORKSHOP
examine clock" "brass clock"
run_test "Examine overcoat in Workshop Entrance" "east
examine overcoat" "overcoat"
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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
east
carve
examine newspaper" "MYSTERIOUS INSCRIPTION"

# Headline shift: watch_offered
run_test "Headline shifts after watch_offered" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
examine newspaper" "POCKET WATCH FOUND ON ROMAN PRIESTESS"

# Headline shift: eleanor_gift
run_test "Headline shifts after eleanor_gift" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
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
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down
repair machine
travel forward
north
up
extinguish
down
south
examine newspaper" "600TH ANNIVERSARY"

# Newspaper lost during Future transit (destroyed, not deposited)
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

# Transit rip no longer deposits newspaper in museum
run_test_absent "Museum omits newspaper if not buried" "$FUTURE_SETUP
north" "SEALED AMPHORA"

# --- Via Principalis: soldiers & notice board ---
echo "[Via Principalis Enrichment]"
# Need lodestone + Marcus impressed to reach Via
VIA_SETUP="$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north"
run_test "Via soldiers respond to Ask about Boudica" "$VIA_SETUP
ask soldiers about boudica" "fifty thousand"
run_test "Via notice board" "$VIA_SETUP
examine board" "UNFOUNDED and UNHELPFUL"
run_test "Via soldiers respond to Ask about Marcus" "$VIA_SETUP
ask soldiers about marcus" "Twenty years on the frontier"
run_test "Via soldiers respond to Ask about docks" "$VIA_SETUP
ask soldiers about docks" "stow it in the mud"
run_test_absent "Via soldiers default response (not generic)" "$VIA_SETUP
ask soldiers about weather" "no reply"
run_test "Take amphora from Via" "$VIA_SETUP
take amphora" "Taken"

# --- Thames Dockside: Burial Mechanic ---
echo "[Newspaper Burial]"
# Bury newspaper without amphora at docks
run_test "Bury newspaper without amphora" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
south
south
bury newspaper" "some kind of container"
# Bury newspaper with pencil at docks
run_test "Bury newspaper with pencil" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north
take amphora
south
south
south
bury newspaper" "MY NAME DOESN'T MATTER"
run_test "Bury newspaper with pencil: amphora" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north
take amphora
south
south
south
bury newspaper" "amphora"
# Bury newspaper without pencil at docks
run_test "Bury newspaper without pencil" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north
take amphora
south
south
south
drop pencil
bury newspaper" "wish you had something to write"
run_test "Bury newspaper without pencil: amphora" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north
take amphora
south
south
south
drop pencil
bury newspaper" "amphora"
# Bury at wrong location
run_test "Bury wrong location" "$ENTER_WORKSHOP
$CAT_ACCIDENT
bury newspaper" "doesn't seem like a good place"
# Bury without newspaper at docks (bare bury)
run_test "Bury without newspaper at docks" "$ENTER_WORKSHOP
$CAT_ACCIDENT
south
south
drop newspaper
bury" "choose carefully"

# --- Museum: Pocket Watch Centrepiece ---
echo "[Museum Pocket Watch Centrepiece]"
# Need watch_offered=true (give watch to livia) for the exhibit to appear
WATCH_FUTURE_SETUP="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
give watch to livia
down
repair machine
travel forward
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
travel forward
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
travel forward"
run_test "Museum shows watch as centrepiece" "$WATCH_FUTURE_SETUP
north" "Priestess of Mithras"
run_test "Museum watch: archaeological anachronism" "$WATCH_FUTURE_SETUP
north" "archaeological anachronism"

# --- Museum: Newspaper Display After Burial ---
echo "[Museum Newspaper After Burial]"
# Build a FUTURE_SETUP that buries the newspaper first (with pencil)
BURY_FUTURE_SETUP="$ENTER_WORKSHOP
take journal
north
take toolkit
south
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
north
take amphora
south
south
south
bury newspaper
north
north
down
repair machine
travel forward
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
travel forward
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
travel forward"
run_test "Museum shows newspaper if buried" "$BURY_FUTURE_SETUP
north" "SEALED AMPHORA"
run_test "Museum inscribed message" "$BURY_FUTURE_SETUP
north" "shaky but deliberate"
run_test "Museum newspaper examine after burial" "$BURY_FUTURE_SETUP
north
examine newspaper" "pencil circle"

# --- Issue #75: insert/enter/board machine ---
echo "[Issue #75: Machine Insert/Enter/Board]"
# Setup: get to Roman forum with lodestone in inventory, machine present
MACHINE_CMD_SETUP="$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
ask copernicus about grate
take aureus
east
south
give aureus to felix
north
show lodestone to marcus
down"
run_test "Insert lodestone in machine hints repair" "$MACHINE_CMD_SETUP
insert lodestone in machine" "REPAIR MACHINE"
run_test_absent "Insert lodestone no generic refusal" "$MACHINE_CMD_SETUP
insert lodestone in machine" "can.t contain things"
run_test "Enter machine hints travel" "$MACHINE_CMD_SETUP
enter machine" "TRAVEL FORWARD"
run_test_absent "Enter machine no generic refusal" "$MACHINE_CMD_SETUP
enter machine" "not something you can enter"
run_test "Board machine hints travel" "$MACHINE_CMD_SETUP
board machine" "TRAVEL FORWARD"
run_test_absent "Board machine no unrecognised verb" "$MACHINE_CMD_SETUP
board machine" "not a verb I recognise"

# --- Issue #72: climb onto machine ---
echo "[Issue #72: Climb Machine]"
run_test "Climb machine hints travel" "$MACHINE_CMD_SETUP
climb machine" "TRAVEL FORWARD"
run_test_absent "Climb machine no generic refusal" "$MACHINE_CMD_SETUP
climb machine" "can.t see any such thing"
run_test "Get on machine hints travel" "$ENTER_SOLARIUM
get on machine" "TRAVEL FORWARD"

# --- Issue #77: Praed Street & Brass Tap ---
echo "[Issue #77: Praed Street & Brass Tap]"

# Praed Street is the start location; REACH_PRAED just stays there
REACH_PRAED="look"

# Workshop entrance west always returns to Praed Street
run_test "West from workshop entrance returns to Praed Street" "east
west" "Praed Street stretches"

# Praed Street is the starting room
run_test "Praed Street accessible from start" "look" "Praed Street"

# Praed Street room description
run_test "Praed Street description: frost" "$REACH_PRAED" "Great Frost"
run_test "Praed Street description: Brass Tap sign" "$REACH_PRAED" "BRASS TAP"

# Workshop entrance always mentions Praed Street west
run_test "Workshop entrance mentions Praed Street" "east
look" "Praed Street"

# Praed Street scenery
run_test "Examine street gas lamps" "$REACH_PRAED
examine lamps" "disapproving aunts"
run_test "Examine street fog" "$REACH_PRAED
examine fog" "Great Frost"
run_test "Examine hansom cabs" "$REACH_PRAED
examine cabs" "ghosts with hooves"
run_test "Examine hanging sign" "$REACH_PRAED
examine sign" "wrought-iron bracket"
run_test "Examine street cobblestones" "$REACH_PRAED
examine cobblestones" "black ice"

# Praed Street directional blocks
run_test "Praed Street north blocked" "$REACH_PRAED
north" "hansom cab"
run_test "Praed Street west leads to Paddington" "$REACH_PRAED
west" "Paddington Station"

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
examine bar" "dark as sin"

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

# --- Expanded Opening ---
echo ""
echo "[Expanded Opening]"
run_test "Starting location is Praed Street" "look" "Praed Street"
run_test "Newsboy visible on Praed Street" "look" "newsboy"
run_test "Buy newspaper from newsboy" "buy newspaper" "Tuppence"
run_test "Coins survive newspaper purchase" "buy newspaper
inventory" "coins"
run_test "Can't buy twice" "buy newspaper
buy newspaper" "already got a newspaper"
run_test "Examine newspaper shows ad" "buy newspaper
examine newspaper" "TEMPORAL ENGINEERING"
run_test "Circle ad with pencil" "buy newspaper
south
take pencil
circle ad" "circle the advert"
run_test "Circle ad needs pencil" "buy newspaper
circle ad" "something to write with"
run_test "Pencil found in pub" "south
look" "pencil"
run_test "Take pencil from pub" "south
take pencil
inventory" "pencil"
run_test "Coins in inventory at start" "inventory" "coins"
run_test "Newsboy description" "examine newsboy" "sharp-faced lad"
run_test "Give coins to newsboy works as buy" "give coins to newsboy" "Tuppence"
run_test "Buy pint in pub" "south
buy pint" "pint of dark ale"
run_test "Order pint synonym" "south
order ale" "pint of dark ale"
run_test "Give coins to barkeep buys pint" "south
give coins to barkeep" "pint of dark ale"
run_test "Coins gone after pint" "south
buy pint
inventory" "pocket watch"
run_test_absent "Coins removed by pint" "south
buy pint
inventory" "carrying.*coins"
run_test "Enter brass tap works" "enter brass tap" "mahogany bar"

# --- Paddington Station ---
echo ""
echo "[Paddington Station]"
run_test "Paddington Station accessible west" "west" "iron-and-glass canopy"
run_test "Paddington Station description" "west" "Paddington Station"
run_test "East from Paddington returns to Praed" "west
east" "Praed Street"
run_test "Examine station canopy" "west
examine canopy" "Brunel"
run_test "Examine station locomotives" "west
examine locomotives" "Brunswick green"
run_test "Examine station clock" "west
examine clock" "four-faced"
run_test "Examine station porters" "west
examine porters" "luggage management"

# --- Thyme hiring gate ---
echo ""
echo "[Thyme Hiring Gate]"
run_test "Thyme rejects without newspaper" "east
knock
knock
knock
east
talk to dr thyme" "No salesmen"
run_test "Show uncircled newspaper to Thyme" "buy newspaper
east
knock
knock
knock
east
show newspaper to dr thyme" "forty-seven adverts"
run_test "Show circled newspaper to Thyme" "$ENTER_WORKSHOP
look" "cathedral"
run_test "Can't give spanner before hired" "east
knock
knock
knock
east
take spanner
give spanner to dr thyme" "No salesmen"
run_test "Full opening flow" "buy newspaper
south
take pencil
circle ad
north
east
knock
knock
knock
east
show newspaper to dr thyme
take spanner
give spanner to dr thyme
talk to dr thyme
east" "Something extraordinary"

# --- Thyme auto-departure timer ---
echo "[Thyme Auto-Departure]"
SPANNER_GIVEN="buy newspaper
south
take pencil
circle ad
north
east
knock
knock
knock
east
show newspaper to dr thyme
take spanner
give spanner to dr thyme"
run_test "Thyme still present 4 turns after spanner" "$SPANNER_GIVEN
look
look
look
look" "Dr. Thyme"
run_test "Thyme auto-departs after 5 turns" "$SPANNER_GIVEN
look
look
look
look
look" "Mrs. Pemberton"
run_test "Rag received after auto-departure" "$SPANNER_GIVEN
look
look
look
look
look
inventory" "cleaning rag"
run_test "Immediate departure via talk still works" "$SPANNER_GIVEN
talk to dr thyme" "Mrs. Pemberton"
run_test "Note visible after standard talk departure" "$SPANNER_GIVEN
talk to dr thyme
look" "hastily scrawled note"
run_test "Read note after standard talk departure" "$SPANNER_GIVEN
talk to dr thyme
read note" "SCONES"
run_test "Off-screen departure from store room" "$SPANNER_GIVEN
north
look
look
look
look
look" "commotion"
run_test "Note left after off-screen departure" "$SPANNER_GIVEN
north
look
look
look
look
look
south
look" "hastily scrawled note"
run_test "Read Thyme's note" "$SPANNER_GIVEN
north
look
look
look
look
look
south
read note" "SCONES"
run_test "Door closed after Thyme departs" "$SPANNER_GIVEN
talk to dr thyme
west
look" "door is closed"
run_test "Key and rag left in workshop after off-screen departure" "$SPANNER_GIVEN
north
look
look
look
look
look
south
look" "front door key"

# --- Clock and time loop ---
echo "[Clock and Time Loop]"
run_test "Watch check at third knock" "east
knock
knock
knock" "pocket watch"
run_test "Endgame return: smooth transit home" "$ENDGAME_CMD" "silk through water"
run_test "Endgame knocks match arrival time" "$ENDGAME_CMD" "exact time you arrived"
run_test "Bootstrap: past self checks watch" "$ENDGAME_CMD" "watch your past self fish out a pocket watch"
run_test "Door didn't open by itself" "$ENDGAME_CMD" "didn.t open by itself"

# --- Opening deadline ---
echo "[Opening Deadline]"
# 27 turns of 'z' (wait) = 2:48 + 27 = 3:15 PM, triggers deadline
WASTE_TIME="south
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z"
run_test "Thyme leaves at quarter past three" "$WASTE_TIME" "enormous overcoat"
run_test "Missed appointment ends game" "$WASTE_TIME" "Somewhere in London there was a job"
run_test "Deadline with newspaper shows ad" "buy newspaper
$WASTE_TIME" "quarter past three"
run_test "Deadline without newspaper" "$WASTE_TIME" "didn.t even buy a newspaper"
run_test "Ad mentions quarter past three" "buy newspaper
examine newspaper" "quarter past three"
run_test "Hired before deadline is safe" "$ENTER_WORKSHOP
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z" "cathedral"

# --- Great Frost ---
echo "[Great Frost]"
FROST_WAIT=$(printf 'z\n%.0s' {1..4})
run_test "Frost warning at turn 4" "$FROST_WAIT" "Great Frost has London"
FROST_DEATH=$(printf 'z\n%.0s' {1..12})
run_test "Frost kills at turn 12" "$FROST_DEATH" "dusted with rime"
run_test "Pub resets frost" "z
z
z
south
z
z
z
z
z
z
z
z
z
z
z" "coal fire"
run_test_absent "No frost death indoors" "south
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z" "frozen to death"

echo "[Post-Rag-Theft Weather]"
# After cat steals rag: exit solarium -> workshop -> entrance -> praed street
RAG_TO_PRAED="$ENTER_SOLARIUM
clean
west
west
west"
run_test "Brass Tap closed after rag theft" "$RAG_TO_PRAED
south" "CLOSED ON ACCOUNT"
run_test "Paddington blocked after rag theft" "$RAG_TO_PRAED
west" "die out there"
run_test "Praed Street worsened after rag theft" "$RAG_TO_PRAED" "gone from cold to murderous"
run_test "Door closes behind player" "$ENTER_SOLARIUM
clean
west
west
west
east
east" "brass key"
run_test "No re-knock after first visit" "$ENTER_SOLARIUM
clean
west
west
west
east
east" "closes behind you"
run_test "Knock with key skips sequence" "$ENTER_SOLARIUM
clean
west
west
west
east
knock" "you have the key"

# --- Clock tower chimes ---
echo "[Clock Tower Chimes]"
# Wait in the pub for 12 turns to hear the 3:00 PM muffled chime
run_test "Clock chime at 3:00 PM from Brass Tap" "south
z
z
z
z
z
z
z
z
z
z
z
z" "clock tower strikes"

# After cat accident, chimes should NOT fire (daemon stops)
TOTAL=$((TOTAL + 1))
_clock_output=$(echo "$ENTER_WORKSHOP
$CAT_ACCIDENT
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z
z" | "$DFROTZ" -h 999 -w 200 "$Z5" 2>&1)
# Extract only text after the Roman tunnel (post cat-accident)
_drain_line=$(echo "$_clock_output" | grep -n "vaulted tunnel" | head -1 | cut -d: -f1)
if [ -n "$_drain_line" ]; then
    _post_accident=$(echo "$_clock_output" | tail -n +"$_drain_line")
    if echo "$_post_accident" | grep -qi "clock tower strikes"; then
        FAIL=$((FAIL + 1))
        echo "  FAIL: No clock chime after cat accident (should NOT contain: clock tower strikes)"
    else
        PASS=$((PASS + 1))
        echo "  PASS: No clock chime after cat accident"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  FAIL: No clock chime after cat accident (could not find tunnel marker)"
fi

# --- Watch Calibration ---
echo "[Watch Calibration]"
run_test "Set watch at Paddington" "west
set watch" "right time"
run_test "Calibrate synonym" "west
calibrate watch" "right time"
run_test "Already calibrated" "west
set watch
set watch" "already keeping perfect time"
run_test "Wrong location" "set watch" "nothing accurate enough"
run_test "Clock hints discrepancy" "west
examine clock" "three minutes ahead"
run_test "Clock after calibration" "west
set watch
examine clock" "matches the north face"

CALIBRATE_PREFIX="west
set watch
east"
run_test "Bootstrap with calibrated watch" "$CALIBRATE_PREFIX
$ENDGAME_CMD" "Paddington.s clock"

# --- Ring Bell (issue #142) ---
echo "[Ring Bell]"
run_test "Ring bell in solarium" "$ENTER_SOLARIUM
ring bell" "Ding"
run_test "Ring controls in solarium" "$ENTER_SOLARIUM
ring controls" "Ding"
run_test_absent "Ring bell is not a parser error" "$ENTER_SOLARIUM
ring bell" "not a verb I recognise"
run_test "Ring bell outside solarium" "ring bell" "Ringing that would accomplish nothing"

# --- Detail Polish ---
echo "[Detail Polish]"

# Pigeon names on solarium ceiling
run_test "Pigeon names on ceiling" "$ENTER_SOLARIUM
examine ceiling" "Newton"

# Listen/Smell in workshop
run_test "Listen in workshop" "$ENTER_WORKSHOP
listen" "ticks and hums"
run_test "Smell in workshop" "$ENTER_WORKSHOP
smell" "marmalade"

# Listen/Smell in solarium
run_test "Listen in solarium" "$ENTER_SOLARIUM
listen" "machine hums"
run_test "Smell in solarium" "$ENTER_SOLARIUM
smell" "overheated copper"

# Listen/Smell in Roman Forum
run_test "Listen in Roman forum" "$ENTER_WORKSHOP
$CAT_ACCIDENT
listen" "merchants hawking"
run_test "Smell in Roman forum" "$ENTER_WORKSHOP
$CAT_ACCIDENT
smell" "garum"

# Listen/Smell in Blitz street (reuse BLITZ_SETUP defined earlier)
run_test "Listen in Blitz" "$BLITZ_SETUP
listen" "bombers"
run_test "Smell in Blitz" "$BLITZ_SETUP
smell" "Cordite"

# Listen to cat (Listen takes a noun in Inform 6)
run_test "Listen to cat" "$ENTER_WORKSHOP
$CAT_ACCIDENT
listen to copernicus" "Purrrrrrrrr"

# Show watch to cat (after accident, cat is named Copernicus)
run_test "Show watch to cat" "$ENTER_WORKSHOP
$CAT_ACCIDENT
show watch to copernicus" "pendulum"

# Show lodestone to cat (need to buy lodestone first)
run_test "Show lodestone to cat" "$ENTER_WORKSHOP
$CAT_ACCIDENT
west
take fish
give fish to copernicus
take aureus
east
south
give aureus to felix
show lodestone to copernicus" "fur stands on end"

# Marzipan TARDIS and Cambridge Listen (reuse HAWKING_SETUP defined earlier)
run_test "Examine marzipan TARDIS" "$HAWKING_SETUP
examine marzipan" "Tom Baker"

run_test "Listen in Cambridge hall" "$HAWKING_SETUP
listen" "champagne fizzes"

# --- Full Score ---
echo "[Full Score]"

run_test "Full score shows task breakdown" "$ENTER_WORKSHOP
full score" "buying the newspaper"

run_test "Full score shows multiple tasks" "$ENTER_WORKSHOP
full score" "circling the advertisement"

run_test "Full score shows hired task" "$ENTER_WORKSHOP
full score" "getting hired"

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
