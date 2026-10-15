# Core Loop

```text
Enter a room
↓
Move, dodge, aim, and attack
↓
Defeat enemies and receive a clear room-complete signal
↓
Choose one randomized item that changes the run's build
↓
Advance to the next room and face a stronger or different threat
↓
Reach the boss, win or lose, then restart
```

- What makes the next decision meaningful? The item choice should alter attack behavior or a combat trade-off enough to affect the next room.
- How does a run/session/attempt end or change state? The prototype run ends on player defeat or boss defeat and offers a quick restart.
- What is still an assumption? Exact weapon/aim model, dodge rules, room count, item effects, boss design, difficulty curve, and target run length.
- Smallest playable version: One arena, player movement and attack, one enemy, one reward choice, a second encounter, a win/loss state, and restart.
- Expanded prototype target: Three combat rooms, two enemy types, one basic weapon, one boss, and approximately eight items.
