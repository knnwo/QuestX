# QuestX

One click, one abandoned quest. QuestX puts a small red X in the top-right corner of each quest in the objective tracker. Click it and the quest is gone, with no menus and no popup.

## Features

- **One-click abandon.** Every quest you can abandon gets a red X in the tracker, lined up in the same spot for each quest.
- **Only where it makes sense.** The X shows on Quests and Campaign entries the game lets you abandon, and nowhere else.
- **Optional safety.** Turn on Alt-click so a stray click can't throw a quest away.
- **Know what you dropped.** A chat message names the abandoned quest and any quest items that were removed with it.

## Using it

| Action | What it does |
| --- | --- |
| Click the X | Abandon that quest |
| Alt+click the X | Abandon that quest (when Alt-click is turned on) |
| Hover the X | Show which quest it abandons |

## Slash commands

| Command | What it does |
| --- | --- |
| `/questx` | Show the commands and what each setting is set to |
| `/questx toggle` | Show or hide the red X |
| `/questx alt` | Require Alt-click to abandon |
| `/questx tooltip` | Show or hide the tooltip on the X |
| `/questx chat` | Show or hide the chat message after abandoning |

## Notes

- Made for the current retail game (Midnight) and Blizzard's own objective tracker. Replacement quest trackers aren't supported.
- Abandoning a quest can't be undone. If you want a safety step, turn on Alt-click with `/questx alt`.
- QuestX only adds its own button next to the tracker. It doesn't change Blizzard's tracker code, so quest item buttons keep working in combat.