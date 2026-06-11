# QServ - Quadra Game Server (Go Rewrite)

## Overview

Go rewrite of the original Perl `qserv.pl`, maintaining full behavioral compatibility.
Handles game registration, score submission, and leaderboard queries over HTTP.

## Project Structure

```
qserv/
  main.go          Entry point, flag parsing, server startup
  handler.go       HTTP request routing, all 5 command handlers
  data.go          Data directory init, game/scores cleanup
  dumper.go        Perl Data::Dumper serialization (read + write)
  log.go           Access logging (REQ/RES/ERR/DATA format, --logfile support)
  test_qserv.ps1   Integration test (auto-starts server, 10 tests)
  build_qserv.ps1 Portable build script (compiles + packages ZIP)
```

## Quick Start

```bash
# Dev
go run .

# Build portable exe
.\build_qserv.ps1

# Run tests (auto starts/stops server)
.\test_qserv.ps1
```

## API Specification

```
Method:  POST /
Param:   data=<command>\n<key> <value>\n<key> <value>...
Content: text/plain
```

### Commands

| Command        | Description                           | Sample Response     |
|---------------|---------------------------------------|---------------------|
| `postgame`    | Register / update a game              | `Game added` \| `Game updated` |
| `deletegame`  | Remove a game                         | `Game deleted` \| `Game not found` |
| `postdemo`    | Submit a score (auto-returns leaderboard) | `Ok\nhigh000/...` |
| `gethighscores`| Get top scores (default 5)           | `Ok\nhigh000/...` |
| `getgames`    | List current games (with dedup)       | `Current games\nIP:PORT ...` |
| *unknown*     | Returns welcome message               | `Hi, I'm the NEW Quadra game server.` |

### Parameter Format

- Flat: `port 27910`
- Nested: `info/players 2` → `{info: {players: "2"}}`

### Request Preprocessing (tweak)

Every request runs:
1. `info/remoteaddr` ← client IP (IPv6 brackets stripped)
2. `port` ← defaults to `3456`, strips non-digits, caps at `65535`

### Game De-duplication (getgames)

| Condition | Dedup Key |
|-----------|-----------|
| `quadra_version == "1.1.2"` | `IP:PORT` (but `players` removed) |
| No `quadra_version` AND no `qsnoop_version` | Host only (no port) |
| Otherwise | `IP:PORT` |

## Data Storage

```
<datadir>/
  games/
    <IP_PORT>          # Perl Data::Dumper format
  scores/
    <SCORE>            # Perl Data::Dumper format (filename = score value)
```

### Serialization Format (Perl Data::Dumper)

```
$VAR1 = {
  'info' => {
    'remoteaddr' => '127.0.0.1',
    'lastupdate' => 1234567890,
  },
  'port' => '27910',
  'players' => '2',
};
```

- `LoadPerlDumper()` converts to JSON internally for parsing
- `SaveAsPerlDumper()` writes atomic (temp file + rename)

### Cleanup Mechanism

| Rule | Trigger |
|------|---------|
| Games expire after 180 seconds | On `getgames` or post-request cleanup |
| Keep top 100 scores only | On `gethighscores`/`postdemo` or post-request cleanup |
| Cleanup runs synchronously | After command response |

## Configuration

### Command-Line Flags

```
--datadir <path>    Data directory (default: C:\quadra\data on Windows,
                    /home/groups/q/qu/quadra/data on Linux)
--port <port>       Listen port (default: 3456)
--debug <level>     Debug level (0=off, 1=on)
--logfile <path>    Access log file path (default: stderr only)
```

### Environment Variables

```
QUADRA_DATADIR    Override data directory (lower priority than --datadir)
DEBUG             Set to any value to enable debug logging (if --debug=0)
```

## Cross-Platform Notes

| Concern | Windows | Linux |
|---------|---------|-------|
| Default datadir | `C:\quadra\data` | `/home/groups/q/qu/quadra/data` |
| Filename `:` | Replaced with `_` (restored on output) | Kept as `:` |
| Line endings | `\n` used everywhere | `\n` |
| Temp files | `%TEMP%` | `/tmp/` |

## Build & Package

```powershell
.\build_qserv.ps1
```

Produces `output/qserv_portable.zip` containing:

```
qserv_portable/
  qserv_x64.exe        # Statically linked, no Go runtime needed
  start.bat            # Double-click to run
  data/                # Auto-created by server
    games/
    scores/
  README.txt
```

## Testing

```powershell
.\test_qserv.ps1
```
Covers 10 scenarios: unknown command, postgame (new + update), getgames,
postdemo (×2), gethighscores, deletegame (exists + missing),
quadra-format file with trailing ;\n. Uses port 34560 and temp data dir
to avoid conflicts.

## Known Limitations

1. `LoadPerlDumper` uses a simplified state-machine parser that does not handle
   single quotes embedded in string values (e.g., `O'Connor`). Production Perl
   data files with such values require a full parser.
2. Windows filename sanitization (`:` → `_`) is transparent to API consumers
   but creates incompatible filenames on disk vs. Linux.
3. No concurrency protection for game expiry during writes (acceptable since
   cleanups run synchronously after each request).

## References

- Original Perl script: `../qserv.pl`
- Specification: `qserv.md`
