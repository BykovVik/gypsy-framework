CharacterManager = {}
local PlayerCharacters = {}

-- Get all characters for license
function CharacterManager.GetCharacters(license)
    if PlayerCharacters[license] then return PlayerCharacters[license] end
    local result = MySQL.query.await('SELECT * FROM players WHERE license = ? ORDER BY slot ASC', {license})
    if result then
        for _, char in ipairs(result) do
            char.charinfo = json.decode(char.charinfo) or {}
            char.metadata = json.decode(char.metadata) or {}
            char.money = json.decode(char.money) or Config.DefaultMoney
            char.job = json.decode(char.job) or Config.DefaultJob
            char.position = json.decode(char.position) or Config.SpawnPoints[1].coords
            if char.position and not char.position.w then 
                char.position.w = Config.SpawnPoints[1].heading or 0.0 
            end
        end
        PlayerCharacters[license] = result
        return result
    end
    PlayerCharacters[license] = {}
    return {}
end

-- Create character
function CharacterManager.CreateCharacter(license, slot, data)
    local citizenid = tostring(math.random(10000000,99999999))
    if not data then data = {} end
    if slot < 1 or slot > Config.MaxCharacters then return false,"Invalid slot" end
    local existing = MySQL.scalar.await('SELECT citizenid FROM players WHERE license=? AND slot=?',{license,slot})
    if existing then return false,"Slot occupied" end

    local charinfo = {
        firstname = data.firstname or "John",
        lastname = data.lastname or "Doe",
        birthdate = data.birthdate or "01/01/1990",
        gender = data.gender or 0,
        nationality = data.nationality or "USA",
        appearance = data.appearance or {}
    }
    local metadata = { hunger=100, thirst=100, stress=0, isdead=false, inlaststand=false, armor=0, health=200 }
    local money = Config.DefaultMoney
    local job = Config.DefaultJob

    local position = data.spawnPoint or Config.SpawnPoints[1].coords
    if not position.w then position.w = Config.SpawnPoints[1].heading or 0.0 end

    local success = MySQL.insert.await([[
        INSERT INTO players (citizenid, license, slot, name, charinfo, metadata, money, job, position)
        VALUES (?,?,?,?,?,?,?,?,?)
    ]], {
        citizenid, license, slot, charinfo.firstname.." "..charinfo.lastname,
        json.encode(charinfo), json.encode(metadata), json.encode(money), json.encode(job),
        json.encode(position)
    })

    if success then PlayerCharacters[license]=nil; return true,citizenid end
    return false,"Database error"
end

-- Delete character
function CharacterManager.DeleteCharacter(license,citizenid)
    local success = MySQL.query.await('DELETE FROM players WHERE citizenid=? AND license=?',{citizenid,license})
    if success then PlayerCharacters[license]=nil; return true end
    return false
end

-- Get character by citizenid
function CharacterManager.GetCharacter(citizenid)
    local result = MySQL.single.await('SELECT * FROM players WHERE citizenid=?',{citizenid})
    if result then
        result.charinfo = json.decode(result.charinfo) or {}
        result.metadata = json.decode(result.metadata) or {}
        result.money = json.decode(result.money) or Config.DefaultMoney
        result.job = json.decode(result.job) or Config.DefaultJob
        result.position = json.decode(result.position) or Config.SpawnPoints[1].coords
        if result.position and not result.position.w then 
            result.position.w = Config.SpawnPoints[1].heading or 0.0 
        end
        return result
    end
    return nil
end

-- Update position (async with callback for reliability)
function CharacterManager.UpdatePosition(citizenid, coords)
    CreateThread(function()
        local affectedRows = MySQL.update.await('UPDATE players SET position = ? WHERE citizenid = ?', {
            json.encode(coords),
            citizenid
        })
        
        if affectedRows and affectedRows > 0 then
            print('^2[CharacterManager] Position saved for '..citizenid..' (affected: '..affectedRows..')^0')
            -- Update cache
            for license, chars in pairs(PlayerCharacters) do
                for _, char in ipairs(chars) do
                    if char.citizenid == citizenid then 
                        char.position = coords
                        break 
                    end
                end
            end
        else
            print('^1[CharacterManager] Failed to save position for '..citizenid..' (affected: '..(affectedRows or 'nil')..')^0')
        end
    end)
end

-- Clear cache
function CharacterManager.ClearCache(license)
    PlayerCharacters[license]=nil
end