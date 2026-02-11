# Shelly's Codex

**Interactive fiction stories — playable in your browser.**

Shelly's Codex is a collection of interactive fiction (text adventure) games written in Inform 6 and served via [Parchment](https://github.com/curiousdannii/parchment) on GitHub Pages. No downloads, no installs — just click and play.

**Play now:** https://scarolan.github.io/shellys-codex/

## Stories

| Title | Genre | Play |
|-------|-------|------|
| Neon Shadows | Cyberpunk Detective Noir | [Play in browser](https://scarolan.github.io/shellys-codex/neon-shadows/) |

## Playing locally

If you prefer a terminal experience, install a Z-machine interpreter:

```bash
# Ubuntu/Debian
sudo apt install frotz

# Then play
frotz neon-shadows/neon_shadows.z5
```

## Project structure

```
shellys-codex/
  index.html                # Landing page / story picker
  neon-shadows/
    index.html              # Parchment interpreter (browser player)
    neon_shadows.inf         # Inform 6 source code
    neon_shadows.z5          # Compiled Z-machine story
    test_neon_shadows.sh     # Test harness (dfrotz + grep)
    CLAUDE.md                # Game-specific docs
```

## Building from source

Each story's `.inf` file compiles to a `.z5` Z-machine story file:

```bash
cd neon-shadows
inform6 +/usr/local/share/inform6/lib/ neon_shadows.inf neon_shadows.z5
```

## Running tests

```bash
cd neon-shadows && bash test_neon_shadows.sh
```

## Adding a new story

1. Create a new directory (e.g., `my-story/`)
2. Add your Inform 6 source (`.inf`), compiled story (`.z5`), and test harness
3. Copy `parchment.html` as `index.html` into the directory and set `default_story`
4. Add a card to the root `index.html` landing page

## About Shelly

This repo is maintained with help from **Shelly**, an autonomous AI task dispatcher. Issues labeled `shelly` are automatically picked up, implemented, tested, and committed. See the [Shelly repo](https://github.com/scarolan/shelly) for details.
