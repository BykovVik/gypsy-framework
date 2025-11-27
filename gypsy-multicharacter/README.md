# Gypsy Multicharacter

Multi-character system for Gypsy Framework with appearance customization and spawn selection.

## Features

- ✅ **Multiple Characters** - Up to 3 characters per player
- ✅ **Character Creation** - Integrated with `gypsy-appearance` for full customization
- ✅ **Spawn Selection** - Choose from 6 spawn locations across Los Santos
- ✅ **Position Tracking** - Automatic position saving (client: 30s, server: 60s)
- ✅ **Session Persistence** - Spawn at last logout position

## Dependencies

- **Required:**
  - `oxmysql` - Database operations
  - `gypsy-core` - Core framework
  
- **Optional:**
  - `gypsy-appearance` - Character appearance customization
  - `spawnmanager` - Auto-spawn prevention

## Installation

1. Ensure dependencies are started before this resource
2. Database schema is handled by `gypsy-core/setup_database.sql`
3. Add to `server.cfg`:
```cfg
ensure gypsy-core
ensure gypsy-multicharacter
```

## Configuration

Edit `config.lua` to customize:

- **Spawn Points** - Add/modify spawn locations
- **Max Characters** - Change character limit per player
- **Default Money** - Starting cash and bank balance
- **Camera Position** - Character selection camera coordinates

## Events

### Client Events

| Event | Parameters | Description |
|-------|-----------|-------------|
| `gypsy-multicharacter:client:showSelection` | `data` | Show character selection UI |
| `gypsy-multicharacter:client:spawnPlayer` | `data` | Spawn player with character data |
| `gypsy-multicharacter:client:refreshCharacters` | `characters` | Refresh character list |
| `gypsy-multicharacter:client:showError` | `message` | Display error message |

### Server Events

| Event | Parameters | Description |
|-------|-----------|-------------|
| `gypsy-multicharacter:server:requestCharacters` | - | Request character list |
| `gypsy-multicharacter:server:createCharacter` | `data` | Create new character |
| `gypsy-multicharacter:server:selectCharacter` | `citizenid` | Select existing character |
| `gypsy-multicharacter:server:deleteCharacter` | `citizenid` | Delete character |
| `gypsy-multicharacter:server:updatePosition` | `position` | Update player position |

## API

### CharacterManager

```lua
-- Get all characters for license
CharacterManager.GetCharacters(license)

-- Create new character
CharacterManager.CreateCharacter(license, slot, data)

-- Delete character
CharacterManager.DeleteCharacter(license, citizenid)

-- Get single character
CharacterManager.GetCharacter(citizenid)

-- Update position
CharacterManager.UpdatePosition(citizenid, coords)

-- Clear cache
CharacterManager.ClearCache(license)
```

### SpawnManager

```lua
-- Spawn player
SpawnManager.SpawnPlayer(src, citizenid)
```

## Position Tracking

Position is saved automatically:
- **Client-side**: Every 30 seconds
- **Server-side**: Every 60 seconds (backup)
- **On disconnect**: Final position save

## License

Part of Gypsy Framework
