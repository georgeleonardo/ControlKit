-- ControlKit: Controller Glyph Overlay for Action Bars
-- Vanilla WoW (1.12.x) Addon

-- Saved variables (persisted across sessions)
ControlKitDB = ControlKitDB or {}

-- Default settings
local DEFAULT_SCALE = 1.0
local DEFAULT_SIZE = 18
local DEFAULT_OFFSET_X = 2
local DEFAULT_OFFSET_Y = -2
local OUT_OF_RANGE_ALPHA = 0.5  -- Opacity when out of casting range
local IN_RANGE_ALPHA = 1.0     -- Opacity when in range

-- Action bar configurations
-- prefix: button name prefix, modifier: glyph file for modifier key (nil for main bar)
local ACTION_BARS = {
    { prefix = "ActionButton",              modifier = nil },          -- Main bar (no modifier)
    { prefix = "MultiBarBottomLeftButton",  modifier = "xbox_s_lb" },  -- LB (Shift) bar
    { prefix = "MultiBarBottomRightButton", modifier = "xbox_s_rb" },  -- RB (Alt) bar
}

-- Base glyph mapping: slot -> texture filename (without extension)
-- Reused across all bars, modifiers are added separately
local BASE_GLYPH_MAP = {
    [1]  = "xbox_s_lt",     -- LT (Left Trigger)
    [2]  = "xbox_s_rt",     -- RT (Right Trigger)
    [3]  = "all_l_stick",   -- P1 (Left Stick Click)
    [4]  = "all_r_stick",   -- P2 (Right Stick Click)
    [5]  = "xbox_r_a",      -- A
    [6]  = "xbox_r_x",      -- X
    [7]  = "xbox_r_y",      -- Y
    [8]  = "xbox_r_b",      -- B
    [9]  = "dpad_down",     -- D-Pad Down
    [10] = "dpad_left",     -- D-Pad Left
    [11] = "dpad_up",       -- D-Pad Up
    [12] = "dpad_right",    -- D-Pad Right
}

-- Addon media path
local MEDIA_PATH = "Interface\\AddOns\\ControlKit\\media\\"

-- Main frame for event handling
local ControlKit = CreateFrame("Frame", "ControlKitFrame", UIParent)

-- Initialize saved variables with defaults
local function InitDB()
    if ControlKitDB.scale == nil then
        ControlKitDB.scale = DEFAULT_SCALE
    end
end

-- Get the current glyph size based on scale
local function GetGlyphSize()
    return DEFAULT_SIZE * (ControlKitDB.scale or DEFAULT_SCALE)
end

-- Update glyph opacity based on action range
-- This mimics the default hotkey behavior of fading when out of range
local function UpdateGlyphRange(button)
    if not button then return end
    
    local dominated    -- Get the action ID for this button
    local action = nil
    if button.action then
        action = button.action
    elseif ActionButton_GetPagedID then
        action = ActionButton_GetPagedID(button)
    end
    
    if not action then return end
    
    -- Check if action is in range (returns 1=in range, 0=out of range, nil=no range check)
    local inRange = IsActionInRange(action)
    local alpha = IN_RANGE_ALPHA
    
    if inRange == 0 then
        -- Out of range - reduce opacity
        alpha = OUT_OF_RANGE_ALPHA
    end
    
    -- Apply alpha to main glyph
    if button.ControlKitGlyph then
        button.ControlKitGlyph:SetAlpha(alpha)
    end
    
    -- Apply alpha to modifier glyph if present
    if button.ControlKitModifier then
        button.ControlKitModifier:SetAlpha(alpha)
    end
end

-- OnUpdate handler for range checking
local function GlyphRangeOnUpdate(button, elapsed)
    -- Throttle updates to every 0.1 seconds for performance
    button.ControlKitRangeTimer = (button.ControlKitRangeTimer or 0) + elapsed
    if button.ControlKitRangeTimer >= 0.1 then
        button.ControlKitRangeTimer = 0
        UpdateGlyphRange(button)
    end
end

-- Create or update the glyph overlay on a button
-- modifier: optional modifier glyph filename (e.g., "xbox_s_lb" for LB)
local function SetupGlyphOverlay(button, slot, modifier)
    if not button then return end

    local glyphName = BASE_GLYPH_MAP[slot]
    if not glyphName then return end

    local size = GetGlyphSize()
    local modifierSize = size * 0.7  -- Modifier icon slightly smaller

    -- Create main glyph overlay texture if it doesn't exist
    if not button.ControlKitGlyph then
        local overlay = button:CreateTexture(button:GetName() .. "ControlKitGlyph", "OVERLAY")
        button.ControlKitGlyph = overlay
    end

    -- Create modifier glyph overlay texture if it doesn't exist
    if not button.ControlKitModifier then
        local modOverlay = button:CreateTexture(button:GetName() .. "ControlKitModifier", "OVERLAY")
        button.ControlKitModifier = modOverlay
    end

    local overlay = button.ControlKitGlyph
    local modOverlay = button.ControlKitModifier

    -- Set main glyph texture path (.blp extension for ConsolePort assets)
    overlay:SetTexture(MEDIA_PATH .. glyphName .. ".blp")

    if modifier then
        -- Composite display: modifier + base glyph side by side
        -- Position modifier icon on the left, main glyph on the right
        modOverlay:SetTexture(MEDIA_PATH .. modifier .. ".blp")
        modOverlay:SetWidth(modifierSize)
        modOverlay:SetHeight(modifierSize)
        modOverlay:ClearAllPoints()
        modOverlay:SetPoint("TOPLEFT", button, "TOPLEFT", DEFAULT_OFFSET_X, DEFAULT_OFFSET_Y)
        modOverlay:Show()

        -- Main glyph positioned to the right of modifier
        overlay:SetWidth(size)
        overlay:SetHeight(size)
        overlay:ClearAllPoints()
        overlay:SetPoint("LEFT", modOverlay, "RIGHT", 1, 0)
    else
        -- No modifier: single glyph display
        modOverlay:Hide()

        overlay:SetWidth(size)
        overlay:SetHeight(size)
        overlay:ClearAllPoints()
        overlay:SetPoint("TOPLEFT", button, "TOPLEFT", DEFAULT_OFFSET_X, DEFAULT_OFFSET_Y)
    end

    -- Show the main overlay
    overlay:Show()

    -- Hide the default hotkey text
    local hotkey = getglobal(button:GetName() .. "HotKey")
    if hotkey then
        hotkey:Hide()
        -- Also set text to empty to prevent it from showing on updates
        hotkey:SetText("")
    end
    
    -- Hook OnUpdate for range checking (only once per button)
    if not button.ControlKitRangeHooked then
        local oldOnUpdate = button:GetScript("OnUpdate")
        button:SetScript("OnUpdate", function()
            -- Call original OnUpdate if it exists
            if oldOnUpdate then
                oldOnUpdate()
            end
            -- Update glyph opacity based on range
            GlyphRangeOnUpdate(this, arg1 or 0.01)
        end)
        button.ControlKitRangeHooked = true
    end
end

-- Update all action button glyphs across all configured bars
local function UpdateAllGlyphs()
    for _, barConfig in ipairs(ACTION_BARS) do
        for slot = 1, 12 do
            local buttonName = barConfig.prefix .. slot
            local button = getglobal(buttonName)
            if button then
                SetupGlyphOverlay(button, slot, barConfig.modifier)
            end
        end
    end
end

-- Refresh glyphs (recalculate sizes) across all configured bars
local function RefreshGlyphs()
    local size = GetGlyphSize()
    local modifierSize = size * 0.7

    for _, barConfig in ipairs(ACTION_BARS) do
        for slot = 1, 12 do
            local buttonName = barConfig.prefix .. slot
            local button = getglobal(buttonName)
            if button then
                -- Update main glyph size
                if button.ControlKitGlyph then
                    button.ControlKitGlyph:SetWidth(size)
                    button.ControlKitGlyph:SetHeight(size)
                end
                -- Update modifier glyph size if present
                if button.ControlKitModifier and barConfig.modifier then
                    button.ControlKitModifier:SetWidth(modifierSize)
                    button.ControlKitModifier:SetHeight(modifierSize)
                end
            end
        end
    end
end

-- Print message to chat
local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ControlKit:|r " .. msg)
    end
end

-- Slash command handler
local function SlashHandler(msg)
    if not msg or msg == "" then
        Print("Commands:")
        Print("  /ck scale <number> - Set glyph scale (default: 1.0)")
        Print("  /ck reset - Reset to default settings")
        Print("  /ck status - Show current settings")
        return
    end

    -- Parse command and arguments
    local cmd, arg1 = string.match(msg, "^(%S+)%s*(.*)$")
    cmd = string.lower(cmd or "")

    if cmd == "scale" then
        local newScale = tonumber(arg1)
        if newScale and newScale > 0 and newScale <= 5 then
            ControlKitDB.scale = newScale
            RefreshGlyphs()
            Print("Glyph scale set to " .. newScale)
        else
            Print("Invalid scale. Use a number between 0.1 and 5.0")
            Print("Current scale: " .. (ControlKitDB.scale or DEFAULT_SCALE))
        end
    elseif cmd == "reset" then
        ControlKitDB.scale = DEFAULT_SCALE
        RefreshGlyphs()
        Print("Settings reset to defaults.")
    elseif cmd == "status" then
        Print("Current scale: " .. (ControlKitDB.scale or DEFAULT_SCALE))
        Print("Glyph size: " .. GetGlyphSize() .. "px")
    else
        Print("Unknown command: " .. cmd)
        Print("Type /ck for help.")
    end
end

-- Register slash commands
SLASH_CONTROLKIT1 = "/ck"
SLASH_CONTROLKIT2 = "/controlkit"
SlashCmdList["CONTROLKIT"] = SlashHandler

-- Event handler
ControlKit:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        InitDB()
        UpdateAllGlyphs()
        Print("Loaded. Type /ck for options.")
    elseif event == "ACTIONBAR_PAGE_CHANGED" then
        UpdateAllGlyphs()
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        UpdateAllGlyphs()
    elseif event == "UPDATE_BINDINGS" then
        -- Re-hide hotkey text after binding updates
        UpdateAllGlyphs()
    end
end)

-- Register events
ControlKit:RegisterEvent("PLAYER_ENTERING_WORLD")
ControlKit:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
ControlKit:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
ControlKit:RegisterEvent("UPDATE_BINDINGS")
