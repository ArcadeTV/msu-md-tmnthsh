### Sound map

| ID  | Track | Title                  | Loop |
| :-: | :---: | ---------------------- | :--: |
| 3A  | 02    | Game Over              | n    |
| 3B  | 03    | Stage Clear            | n    |
| 3C  | 04    | Stage Start            | n    |
| 3D  | 05    | Stage Introduction     | 155  |
| 3E  | 06    | Title Theme            | n    |
| 3F  | 07    | Stage 1: Let's Rock    | y    |
| 40  | 08    | Stage 2: Swimming Pool | 158  |
| 41  | 09    | Stage 3: Desert Drive  | y    |
| 42  | 10    | Stage 4: Dino Express  | 40   |
| 43  | 11    | Stage 5: Five Rock     | 547  |
| 44  | 12    | Stage 6: Hard Rock     | y    |
| 45  | 13    | Ending Theme           | y    |
| 46  | 14    | Unknown Track          | y    |
| 47  | 15    | Boss Theme             | y    |
| 68  | 16    | Invincibility          | 130  |
| 69  | 17    | Final Boss             | y    |
|     |       |                        |      |

#### Locations

| Where | What                      |
| ----- | ------------------------- |
| $B88  | PlaySound                 |
| $290E | soundIDs table            |
| $27DE | SoundTest calls PlaySound |
| $2082 | Intro calls PlaySound     |

#### Sound commands

01 - fadeOut
FF - Pause toggle (will trigger SoundID again on unpause)
4A - ?
39 - ?