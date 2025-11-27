-- ============================================================================
-- GYPSY MULTICHARACTER - CHARACTER MANAGER
-- ============================================================================
-- Manages character data, creation, deletion and database operations
-- ============================================================================

CharacterManager = {}
local PlayerCharacters = {} -- Cache for loaded characters

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local DEFAULT_METADATA = {
    hunger = 100,
    thirst = 100,
    stress = 0,
    isdead = false,
    inlaststand = false,
    armor = 0,
    health = 200
}

-- ============================================================================
-- PRIVATE HELPERS
-- ============================================================================

--- Decode and validate character data from database
---@param char table Raw character data from DB
---@return table Processed character data
local function processCharacterData(char)
    char.charinfo = json.decode(char.charinfo) or {}
    char.metadata = json.decode(char.metadata) or {}
    char.money = json.decode(char.money) or Config.DefaultMoney
    char.job = json.decode(char.job) or Config.DefaultJob
    char.position = json.decode(char.position) or Config.SpawnPoints[1].coords
    
    -- Ensure position has heading
    if char.position and not char.position.w then 
        char.position.w = Config.SpawnPoints[1].heading or 0.0 
    end
    
    return char
end

--- Generate unique citizen ID
---@return string 8-digit citizen ID
local function generateCitizenId()
    return tostring(math.random(10000000, 99999999))
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--- Get all characters for a license
---@param license string Player license identifier
---@return table Array of character data
function CharacterManager.GetCharacters(license)
    if PlayerCharacters[license] then 
        return PlayerCharacters[license] 
    end
    
    local result = MySQL.query.await(
        'SELECT * FROM players WHERE license = ? ORDER BY slot ASC', 
        {license}
    )
    
    if result then
        for _, char in ipairs(result) do
            processCharacterData(char)
        end
        PlayerCharacters[license] = result
        return result
    end
    
    PlayerCharacters[license] = {}
    return {}
end

--- Create a new character
---@param license string Player license identifier
---@param slot number Character slot (1-MaxCharacters)
---@param data table Character creation data
---@return boolean success
---@return string citizenid or error message
function CharacterManager.CreateCharacter(license, slot, data)
    local citizenid = generateCitizenId()
    data = data or {}
    
    -- Validate slot
    if slot < 1 or slot > Config.MaxCharacters then 
        return false, "Invalid slot" 
    end
    
    -- Check if slot is occupied
    local existing = MySQL.scalar.await(
        'SELECT citizenid FROM players WHERE license=? AND slot=?',
        {license, slot}
    )
    if existing then 
        return false, "Slot occupied" 
    end

    -- Prepare character info
    local charinfo = {
        firstname = data.firstname or "John",
        lastname = data.lastname or "Doe",
        birthdate = data.birthdate or "01/01/1990",
        gender = data.gender or 0,
        nationality = data.nationality or "USA",
        appearance = data.appearance or {}
    }
    
    -- Prepare spawn position
    local position = data.spawnPoint or Config.SpawnPoints[1].coords
    if not position.w then 
        position.w = Config.SpawnPoints[1].heading or 0.0 
    end

    -- Insert into database
    local success = MySQL.insert.await([[
        INSERT INTO players (citizenid, license, slot, name, charinfo, metadata, money, job, position)
        VALUES (?,?,?,?,?,?,?,?,?)
    ]], {
        citizenid,
        license,
        slot,
        charinfo.firstname .. " " .. charinfo.lastname,
        json.encode(charinfo),
        json.encode(DEFAULT_METADATA),
        json.encode(Config.DefaultMoney),
        json.encode(Config.DefaultJob),
        json.encode(position)
    })

    if success then 
        PlayerCharacters[license] = nil -- Clear cache
        return true, citizenid 
    end
    
    return false, "Database error"
end

--- Delete a character
---@param license string Player license identifier
---@param citizenid string Character citizen ID
---@return boolean success
function CharacterManager.DeleteCharacter(license, citizenid)
    local success = MySQL.query.await(
        'DELETE FROM players WHERE citizenid=? AND license=?',
        {citizenid, license}
    )
    
    if success then 
        PlayerCharacters[license] = nil -- Clear cache
        return true 
    end
    
    return false
end

--- Get single character by citizen ID
---@param citizenid string Character citizen ID
---@return table|nil Character data or nil
function CharacterManager.GetCharacter(citizenid)
    local result = MySQL.single.await(
        'SELECT * FROM players WHERE citizenid=?',
        {citizenid}
    )
    
    if result then
        return processCharacterData(result)
    end
    
    return nil
end

--- Update character position (async)
---@param citizenid string Character citizen ID
---@param coords table Position coordinates {x, y, z, w}
function CharacterManager.UpdatePosition(citizenid, coords)
    CreateThread(function()
        local affectedRows = MySQL.update.await(
            'UPDATE players SET position = ? WHERE citizenid = ?', 
            {json.encode(coords), citizenid}
        )
        
        if affectedRows and affectedRows > 0 then
            -- Update cache
            for license, chars in pairs(PlayerCharacters) do
                for _, char in ipairs(chars) do
                    if char.citizenid == citizenid then 
                        char.position = coords
                        break 
                    end
                end
            end
        end
    end)
end

--- Clear character cache for license
---@param license string Player license identifier
function CharacterManager.ClearCache(license)
    PlayerCharacters[license] = nil
end