-- ControlKit: Controller Glyph Overlay for Action Bars
-- Vanilla WoW (1.12.x) Addon

-- Saved variables (persisted across sessions)
ControlKitDB = ControlKitDB or {}

-- Default settings
local DEFAULT_SCALE = 1.0
local DEFAULT_STYLE = "xbox"
local DEFAULT_ENABLED = true
local DEFAULT_SIZE = 18
local DEFAULT_OFFSET_X = 2
local DEFAULT_OFFSET_Y = -2
local OUT_OF_RANGE_ALPHA = 0.5  -- Opacity when out of casting range
local IN_RANGE_ALPHA = 1.0     -- Opacity when in range

-- Controller style definitions
-- Each style has: glyphs (slot mappings), lb (left bumper), rb (right bumper)
local CONTROLLER_STYLES = {
    xbox = {
        name = "Xbox",
        glyphs = {
            [1]  = "xbox_s_lt",     -- LT (Left Trigger)
            [2]  = "xbox_s_rt",     -- RT (Right Trigger)
            [3]  = "all_g_left",    -- P1 (Left Paddle/Grip)
            [4]  = "all_g_right",   -- P2 (Right Paddle/Grip)
            [5]  = "xbox_r_a",      -- A
            [6]  = "xbox_r_x",      -- X
            [7]  = "xbox_r_y",      -- Y
            [8]  = "xbox_r_b",      -- B
            [9]  = "dpad_down",     -- D-Pad Down
            [10] = "dpad_left",     -- D-Pad Left
            [11] = "dpad_up",       -- D-Pad Up
            [12] = "dpad_right",    -- D-Pad Right
        },
        lb = "xbox_s_lb",  -- Left Bumper (Shift modifier)
        rb = "xbox_s_rb",  -- Right Bumper (Alt modifier)
    },
    steamdeck = {
        name = "Steam Deck",
        glyphs = {
            [1]  = "xbox_s_lt",     -- L2 (Left Trigger)
            [2]  = "xbox_s_rt",     -- R2 (Right Trigger)
            [3]  = "all_g_left",    -- L4 (Left Back Grip)
            [4]  = "all_g_right",   -- R4 (Right Back Grip)
            [5]  = "xbox_r_a",      -- A
            [6]  = "xbox_r_x",      -- X
            [7]  = "xbox_r_y",      -- Y
            [8]  = "xbox_r_b",      -- B
            [9]  = "dpad_down",     -- D-Pad Down
            [10] = "dpad_left",     -- D-Pad Left
            [11] = "dpad_up",       -- D-Pad Up
            [12] = "dpad_right",    -- D-Pad Right
        },
        lb = "xbox_s_lb",  -- L1 (Shift modifier)
        rb = "xbox_s_rb",  -- R1 (Alt modifier)
    },
    playstation = {
        name = "PlayStation",
        glyphs = {
            [1]  = "ps_s_l2",       -- L2 (Left Trigger)
            [2]  = "ps_s_r2",       -- R2 (Right Trigger)
            [3]  = "all_g_left",    -- P1 (Left Paddle/Grip)
            [4]  = "all_g_right",   -- P2 (Right Paddle/Grip)
            [5]  = "ps_r_cross",    -- Cross (X)
            [6]  = "ps_r_square",   -- Square
            [7]  = "ps_r_triangle", -- Triangle
            [8]  = "ps_r_circle",   -- Circle
            [9]  = "dpad_down",     -- D-Pad Down
            [10] = "dpad_left",     -- D-Pad Left
            [11] = "dpad_up",       -- D-Pad Up
            [12] = "dpad_right",    -- D-Pad Right
        },
        lb = "ps_s_l1",  -- L1 (Shift modifier)
        rb = "ps_s_r1",  -- R1 (Alt modifier)
    },
}

-- Available style names for iteration
local STYLE_LIST = { "xbox", "steamdeck", "playstation" }

-- Get current controller style config
local function GetCurrentStyle()
    local styleName = ControlKitDB.style or DEFAULT_STYLE
    return CONTROLLER_STYLES[styleName] or CONTROLLER_STYLES[DEFAULT_STYLE]
end

-- Action bar configurations (dynamically uses current style's modifiers)
local function GetActionBars()
    local style = GetCurrentStyle()
    return {
        { prefix = "ActionButton",              modifier = nil },       -- Main bar (no modifier)
        { prefix = "MultiBarBottomLeftButton",  modifier = style.lb },  -- LB/L1 (Shift) bar
        { prefix = "MultiBarBottomRightButton", modifier = style.rb },  -- RB/R1 (Alt) bar
    }
end

-- Addon media path
local MEDIA_PATH = "Interface\\AddOns\\ControlKit\\media\\"

-- Main frame for event handling
local ControlKit = CreateFrame("Frame", "ControlKitFrame", UIParent)

-- Initialize saved variables with defaults
local function InitDB()
    if ControlKitDB.scale == nil then
        ControlKitDB.scale = DEFAULT_SCALE
    end
    if ControlKitDB.style == nil then
        ControlKitDB.style = DEFAULT_STYLE
    end
    if ControlKitDB.enabled == nil then
        ControlKitDB.enabled = DEFAULT_ENABLED
    end
end

-- Check if glyphs are enabled
local function IsEnabled()
    return ControlKitDB.enabled ~= false
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

    local style = GetCurrentStyle()
    local glyphName = style.glyphs[slot]
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

-- Hide all glyphs and restore default hotkey text
local function HideAllGlyphs()
    local actionBars = GetActionBars()
    for _, barConfig in ipairs(actionBars) do
        for slot = 1, 12 do
            local buttonName = barConfig.prefix .. slot
            local button = getglobal(buttonName)
            if button then
                -- Hide glyph overlays
                if button.ControlKitGlyph then
                    button.ControlKitGlyph:Hide()
                end
                if button.ControlKitModifier then
                    button.ControlKitModifier:Hide()
                end
                -- Restore default hotkey text
                local hotkey = getglobal(button:GetName() .. "HotKey")
                if hotkey then
                    hotkey:Show()
                end
            end
        end
    end
end

-- Update all action button glyphs across all configured bars
local function UpdateAllGlyphs()
    -- If disabled, hide glyphs and return
    if not IsEnabled() then
        HideAllGlyphs()
        return
    end
    
    local actionBars = GetActionBars()
    for _, barConfig in ipairs(actionBars) do
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
    local actionBars = GetActionBars()

    for _, barConfig in ipairs(actionBars) do
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

--------------------------------------------------------------------------------
-- Settings UI Panel
--------------------------------------------------------------------------------

local ControlKitOptions = nil  -- Will hold the options frame

local function CreateOptionsPanel()
    if ControlKitOptions then return ControlKitOptions end
    
    -- Main options frame
    local frame = CreateFrame("Frame", "ControlKitOptionsFrame", UIParent)
    frame:SetWidth(280)
    frame:SetHeight(230)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("ControlKit Options")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    
    -- Enable Checkbox
    local enableCheck = CreateFrame("CheckButton", "ControlKitEnableCheck", frame, "OptionsCheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -50)
    enableCheck:SetChecked(ControlKitDB.enabled ~= false)
    getglobal(enableCheck:GetName() .. "Text"):SetText("Enable Controller Glyphs")
    enableCheck:SetScript("OnClick", function()
        ControlKitDB.enabled = this:GetChecked() == 1
        UpdateAllGlyphs()
        if ControlKitDB.enabled then
            Print("Glyphs enabled.")
        else
            Print("Glyphs disabled.")
        end
    end)
    frame.enableCheck = enableCheck
    
    -- Controller Style Label
    local styleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    styleLabel:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 5, -10)
    styleLabel:SetText("Controller Style:")
    
    -- Controller Style Dropdown
    local styleDropdown = CreateFrame("Frame", "ControlKitStyleDropdown", frame, "UIDropDownMenuTemplate")
    styleDropdown:SetPoint("TOPLEFT", styleLabel, "BOTTOMLEFT", -15, -5)
    
    local function StyleDropdown_OnClick()
        ControlKitDB.style = this.value
        UIDropDownMenu_SetSelectedValue(styleDropdown, this.value)
        UIDropDownMenu_SetText(CONTROLLER_STYLES[this.value].name, styleDropdown)
        UpdateAllGlyphs()
    end
    
    local function StyleDropdown_Initialize()
        local info = {}
        for _, styleName in ipairs(STYLE_LIST) do
            info.text = CONTROLLER_STYLES[styleName].name
            info.value = styleName
            info.func = StyleDropdown_OnClick
            info.checked = (ControlKitDB.style == styleName)
            UIDropDownMenu_AddButton(info)
        end
    end
    
    UIDropDownMenu_Initialize(styleDropdown, StyleDropdown_Initialize)
    UIDropDownMenu_SetWidth(150, styleDropdown)
    UIDropDownMenu_SetSelectedValue(styleDropdown, ControlKitDB.style or DEFAULT_STYLE)
    UIDropDownMenu_SetText(GetCurrentStyle().name, styleDropdown)
    frame.styleDropdown = styleDropdown
    
    -- Scale Label
    local scaleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", styleDropdown, "BOTTOMLEFT", 15, -15)
    scaleLabel:SetText("Glyph Scale:")
    
    -- Scale Slider
    local scaleSlider = CreateFrame("Slider", "ControlKitScaleSlider", frame, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -15)
    scaleSlider:SetWidth(180)
    scaleSlider:SetHeight(17)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetValue(ControlKitDB.scale or DEFAULT_SCALE)
    
    getglobal(scaleSlider:GetName() .. "Low"):SetText("0.5")
    getglobal(scaleSlider:GetName() .. "High"):SetText("2.0")
    getglobal(scaleSlider:GetName() .. "Text"):SetText(string.format("%.1f", ControlKitDB.scale or DEFAULT_SCALE))
    
    scaleSlider:SetScript("OnValueChanged", function()
        local value = math.floor(this:GetValue() * 10 + 0.5) / 10  -- Round to 1 decimal
        ControlKitDB.scale = value
        getglobal(this:GetName() .. "Text"):SetText(string.format("%.1f", value))
        UpdateAllGlyphs()
    end)
    frame.scaleSlider = scaleSlider
    
    -- Reset Button
    local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetBtn:SetWidth(100)
    resetBtn:SetHeight(22)
    resetBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        ControlKitDB.scale = DEFAULT_SCALE
        ControlKitDB.style = DEFAULT_STYLE
        -- Update UI elements
        UIDropDownMenu_SetSelectedValue(styleDropdown, DEFAULT_STYLE)
        UIDropDownMenu_SetText(CONTROLLER_STYLES[DEFAULT_STYLE].name, styleDropdown)
        scaleSlider:SetValue(DEFAULT_SCALE)
        getglobal(scaleSlider:GetName() .. "Text"):SetText(string.format("%.1f", DEFAULT_SCALE))
        UpdateAllGlyphs()
        Print("Settings reset to defaults.")
    end)
    
    -- ESC key closes the frame
    tinsert(UISpecialFrames, "ControlKitOptionsFrame")
    
    ControlKitOptions = frame
    return frame
end

-- Toggle options panel
local function ToggleOptionsPanel()
    local panel = CreateOptionsPanel()
    if panel:IsShown() then
        panel:Hide()
    else
        -- Refresh UI values before showing
        if panel.enableCheck then
            panel.enableCheck:SetChecked(ControlKitDB.enabled ~= false)
        end
        if panel.styleDropdown then
            UIDropDownMenu_SetSelectedValue(panel.styleDropdown, ControlKitDB.style or DEFAULT_STYLE)
            UIDropDownMenu_SetText(GetCurrentStyle().name, panel.styleDropdown)
        end
        if panel.scaleSlider then
            panel.scaleSlider:SetValue(ControlKitDB.scale or DEFAULT_SCALE)
        end
        panel:Show()
    end
end

-- Toggle glyphs on/off
local function ToggleEnabled()
    ControlKitDB.enabled = not IsEnabled()
    UpdateAllGlyphs()
    if ControlKitDB.enabled then
        Print("Glyphs enabled.")
    else
        Print("Glyphs disabled.")
    end
end

--------------------------------------------------------------------------------
-- Game Menu (ESC) Button
--------------------------------------------------------------------------------

local function CreateGameMenuButton()
    -- Create ControlKit button for the game menu
    local menuButton = CreateFrame("Button", "GameMenuButtonControlKit", GameMenuFrame, "GameMenuButtonTemplate")
    menuButton:SetText("ControlKit")
    menuButton:SetScript("OnClick", function()
        PlaySound("igMainMenuOption")
        HideUIPanel(GameMenuFrame)
        ToggleOptionsPanel()
    end)
    
    -- Position the button above the Options button
    -- We need to move some buttons down to make room
    local buttonHeight = GameMenuButtonOptions:GetHeight() + 1
    
    -- Move buttons down to make room for ControlKit
    GameMenuButtonOptions:ClearAllPoints()
    GameMenuButtonOptions:SetPoint("TOP", menuButton, "BOTTOM", 0, -1)
    
    -- Position ControlKit button where Options was (below UIOptions/Video)
    menuButton:SetPoint("TOP", GameMenuButtonUIOptions, "BOTTOM", 0, -1)
    
    -- Expand the game menu frame to fit the new button
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + buttonHeight)
end

-- Slash command handler
local function SlashHandler(msg)
    if not msg or msg == "" then
        -- No argument: open the options panel
        ToggleOptionsPanel()
        return
    end

    -- Parse command and arguments
    local cmd, arg1 = string.match(msg, "^(%S+)%s*(.*)$")
    cmd = string.lower(cmd or "")
    
    if cmd == "config" or cmd == "options" or cmd == "opt" then
        ToggleOptionsPanel()
        return
    end
    
    if cmd == "help" then
        Print("Commands:")
        Print("  /ck - Open options panel")
        Print("  /ck toggle - Toggle glyphs on/off")
        Print("  /ck enable - Enable glyphs")
        Print("  /ck disable - Disable glyphs")
        Print("  /ck style <xbox|steamdeck|playstation> - Change controller style")
        Print("  /ck scale <number> - Set glyph scale (default: 1.0)")
        Print("  /ck reset - Reset to default settings")
        Print("  /ck status - Show current settings")
        return
    end
    
    if cmd == "toggle" then
        ToggleEnabled()
        return
    end
    
    if cmd == "enable" or cmd == "on" then
        ControlKitDB.enabled = true
        UpdateAllGlyphs()
        Print("Glyphs enabled.")
        return
    end
    
    if cmd == "disable" or cmd == "off" then
        ControlKitDB.enabled = false
        UpdateAllGlyphs()
        Print("Glyphs disabled.")
        return
    end

    if cmd == "style" then
        local styleName = string.lower(arg1 or "")
        if CONTROLLER_STYLES[styleName] then
            ControlKitDB.style = styleName
            UpdateAllGlyphs()
            Print("Controller style set to: " .. CONTROLLER_STYLES[styleName].name)
        else
            Print("Available styles: xbox, steamdeck, playstation")
            Print("Current style: " .. GetCurrentStyle().name)
        end
    elseif cmd == "scale" then
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
        ControlKitDB.style = DEFAULT_STYLE
        ControlKitDB.enabled = DEFAULT_ENABLED
        UpdateAllGlyphs()
        Print("Settings reset to defaults.")
    elseif cmd == "status" then
        local enabledText = IsEnabled() and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"
        Print("Glyphs: " .. enabledText)
        Print("Controller style: " .. GetCurrentStyle().name)
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
        CreateGameMenuButton()
        UpdateAllGlyphs()
        Print("Loaded. Type /ck to open options.")
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
