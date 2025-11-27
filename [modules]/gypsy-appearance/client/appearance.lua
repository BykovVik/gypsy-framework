-- Gypsy Appearance - Appearance Logic
-- Functions to apply and get appearance data

-- ============================================================================
-- APPLY APPEARANCE TO PED
-- ============================================================================

-- Helper to safely set component variation
local function SetPedComponent(ped, componentId, drawableId, textureId)
    if not DoesEntityExist(ped) then return end
    
    -- Validate drawable
    local maxDrawables = GetNumberOfPedDrawableVariations(ped, componentId)
    if drawableId < 0 or drawableId >= maxDrawables then
        drawableId = 0
    end
    
    -- Validate texture
    local maxTextures = GetNumberOfPedTextureVariations(ped, componentId, drawableId)
    if textureId < 0 or textureId >= maxTextures then
        textureId = 0
    end
    
    SetPedComponentVariation(ped, componentId, drawableId, textureId, 0)
end

function ApplyAppearanceToPed(ped, data)
    if not ped or not DoesEntityExist(ped) then return end
    if not data then return end
    
    -- Set ped as freemode model
    SetPedDefaultComponentVariation(ped)
    
    -- Heritage (parents)
    if data.heritage then
        SetPedHeadBlendData(
            ped,
            data.heritage.mother or 0,
            data.heritage.father or 0,
            0, -- third parent (not used)
            data.heritage.mother or 0,
            data.heritage.father or 0,
            0, -- third parent skin (not used)
            data.heritage.mix or 0.5, -- shape mix
            data.heritage.skinMix or 0.5, -- skin mix
            0.0, -- third mix (not used)
            false -- is parent
        )
    end
    
    -- Skin tone
    if data.skinTone then
        SetPedHeadBlendData(
            ped,
            data.heritage and data.heritage.mother or 0,
            data.heritage and data.heritage.father or 0,
            0,
            data.heritage and data.heritage.mother or 0,
            data.heritage and data.heritage.father or 0,
            0,
            data.heritage and data.heritage.mix or 0.5,
            data.skinTone,
            0.0,
            false
        )
    end
    
    -- Hair
    if data.hair then
        SetPedComponent(ped, 2, data.hair.style or 0, 0) -- Hair style (texture handled by color)
        SetPedHairColor(ped, data.hair.color or 0, data.hair.highlight or 0) -- Hair color
    end
    
    -- Eyes
    if data.eyeColor then
        SetPedEyeColor(ped, data.eyeColor)
    end
    
    -- Eyebrows
    if data.eyebrows then
        SetPedHeadOverlay(ped, 2, data.eyebrows.style or 0, 1.0) -- Eyebrow style
        SetPedHeadOverlayColor(ped, 2, 1, data.eyebrows.color or 0, 0) -- Eyebrow color
    end
    
    -- Clothing
    if data.clothing then
        -- Torso (upper body)
        if data.clothing.torso then
            SetPedComponent(ped, 11, data.clothing.torso.drawable or 0, data.clothing.torso.texture or 0)
        end
        
        -- Legs
        if data.clothing.legs then
            SetPedComponent(ped, 4, data.clothing.legs.drawable or 0, data.clothing.legs.texture or 0)
        end
        
        -- Shoes
        if data.clothing.shoes then
            SetPedComponent(ped, 6, data.clothing.shoes.drawable or 0, data.clothing.shoes.texture or 0)
        end
        
        -- Arms
        if data.clothing.arms then
            SetPedComponent(ped, 3, data.clothing.arms.drawable or 0, data.clothing.arms.texture or 0)
        end
    else
        -- Apply default clothing if none provided
        local gender = GetEntityModel(ped) == `mp_f_freemode_01` and 'female' or 'male'
        local defaultClothing = Config.DefaultClothing[gender]
        
        SetPedComponent(ped, 11, defaultClothing.torso.drawable, defaultClothing.torso.texture)
        SetPedComponent(ped, 4, defaultClothing.legs.drawable, defaultClothing.legs.texture)
        SetPedComponent(ped, 6, defaultClothing.shoes.drawable, defaultClothing.shoes.texture)
        SetPedComponent(ped, 3, defaultClothing.arms.drawable, defaultClothing.arms.texture)
    end
end

-- ============================================================================
-- GET APPEARANCE FROM PED
-- ============================================================================

function GetPedAppearance(ped)
    if not ped or not DoesEntityExist(ped) then return nil end
    
    local appearance = {}
    
    -- Get heritage data
    local shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix = GetPedHeadBlendData(ped)
    appearance.heritage = {
        mother = shapeFirst,
        father = shapeSecond,
        mix = shapeMix,
        skinMix = skinMix
    }
    
    -- Get hair
    local hairStyle = GetPedDrawableVariation(ped, 2)
    local hairColor, hairHighlight = GetPedHairColor(ped)
    appearance.hair = {
        style = hairStyle,
        color = hairColor,
        highlight = hairHighlight
    }
    
    -- Get eye color
    appearance.eyeColor = GetPedEyeColor(ped)
    
    -- Get eyebrows
    local eyebrowStyle = GetPedHeadOverlayValue(ped, 2)
    local eyebrowColor = GetPedHeadOverlayColor(ped, 2)
    appearance.eyebrows = {
        style = eyebrowStyle,
        color = eyebrowColor
    }
    
    -- Get clothing
    appearance.clothing = {
        torso = {
            drawable = GetPedDrawableVariation(ped, 11),
            texture = GetPedTextureVariation(ped, 11)
        },
        legs = {
            drawable = GetPedDrawableVariation(ped, 4),
            texture = GetPedTextureVariation(ped, 4)
        },
        shoes = {
            drawable = GetPedDrawableVariation(ped, 6),
            texture = GetPedTextureVariation(ped, 6)
        },
        arms = {
            drawable = GetPedDrawableVariation(ped, 3),
            texture = GetPedTextureVariation(ped, 3)
        }
    }
    
    return appearance
end
