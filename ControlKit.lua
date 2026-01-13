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

-- All available glyphs for the picker (organized by category)
local AVAILABLE_GLYPHS = {
    face = {
        { id = "xbox_r_a", label = "A" },
        { id = "xbox_r_b", label = "B" },
        { id = "xbox_r_x", label = "X" },
        { id = "xbox_r_y", label = "Y" },
    },
    triggers = {
        { id = "xbox_s_lt", label = "LT" },
        { id = "xbox_s_rt", label = "RT" },
        { id = "xbox_s_lb", label = "LB" },
        { id = "xbox_s_rb", label = "RB" },
    },
    dpad = {
        { id = "dpad_up", label = "Up" },
        { id = "dpad_down", label = "Down" },
        { id = "dpad_left", label = "Left" },
        { id = "dpad_right", label = "Right" },
    },
    other = {
        { id = "all_g_left", label = "P1" },
        { id = "all_g_right", label = "P2" },
        { id = "xbox_s_lsb", label = "L3" },
        { id = "xbox_s_rsb", label = "R3" },
    },
    playstation = {
        { id = "ps_r_cross", label = "Cross" },
        { id = "ps_r_circle", label = "Circle" },
        { id = "ps_r_square", label = "Square" },
        { id = "ps_r_triangle", label = "Triangle" },
        { id = "ps_s_l1", label = "L1" },
        { id = "ps_s_r1", label = "R1" },
        { id = "ps_s_l2", label = "L2" },
        { id = "ps_s_r2", label = "R2" },
    },
}

-- Flat list of all glyph IDs for easy lookup
local ALL_GLYPH_IDS = {}
for _, category in pairs(AVAILABLE_GLYPHS) do
    for _, glyph in ipairs(category) do
        table.insert(ALL_GLYPH_IDS, glyph.id)
    end
end

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
    if ControlKitDB.customGlyphs == nil then
        ControlKitDB.customGlyphs = {}
    end
end

-- Check if glyphs are enabled
local function IsEnabled()
    return ControlKitDB.enabled ~= false
end

-- Get the glyph for a specific bar and slot (custom or default)
local function GetGlyphForSlot(barPrefix, slot)
    -- Check for custom glyph first
    if ControlKitDB.customGlyphs and ControlKitDB.customGlyphs[barPrefix] then
        local customGlyph = ControlKitDB.customGlyphs[barPrefix][slot]
        if customGlyph then
            return customGlyph
        end
    end
    -- Fall back to style default
    local style = GetCurrentStyle()
    return style.glyphs[slot]
end

-- Set a custom glyph for a specific bar and slot
local function SetCustomGlyph(barPrefix, slot, glyphId)
    if not ControlKitDB.customGlyphs then
        ControlKitDB.customGlyphs = {}
    end
    if not ControlKitDB.customGlyphs[barPrefix] then
        ControlKitDB.customGlyphs[barPrefix] = {}
    end
    ControlKitDB.customGlyphs[barPrefix][slot] = glyphId
end

-- Clear a custom glyph (revert to default)
local function ClearCustomGlyph(barPrefix, slot)
    if ControlKitDB.customGlyphs and ControlKitDB.customGlyphs[barPrefix] then
        ControlKitDB.customGlyphs[barPrefix][slot] = nil
    end
end

-- Clear all custom glyphs
local function ClearAllCustomGlyphs()
    ControlKitDB.customGlyphs = {}
end

-- Check if a slot has a custom glyph
local function HasCustomGlyph(barPrefix, slot)
    return ControlKitDB.customGlyphs 
        and ControlKitDB.customGlyphs[barPrefix] 
        and ControlKitDB.customGlyphs[barPrefix][slot] ~= nil
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
-- barPrefix: the bar prefix for custom glyph lookup
local function SetupGlyphOverlay(button, slot, modifier, barPrefix)
    if not button then return end

    -- Use custom glyph if set, otherwise fall back to style default
    local glyphName = GetGlyphForSlot(barPrefix or "ActionButton", slot)
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
                SetupGlyphOverlay(button, slot, barConfig.modifier, barConfig.prefix)
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
    frame:SetHeight(260)
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
    
    -- Customize Button (opens bar editor)
    local customizeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    customizeBtn:SetWidth(120)
    customizeBtn:SetHeight(22)
    customizeBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 50)
    customizeBtn:SetText("Customize Glyphs")
    customizeBtn:SetScript("OnClick", function()
        ShowBarEditor()
    end)
    
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
-- Glyph Picker Popup
--------------------------------------------------------------------------------

local GlyphPicker = nil
local GlyphPickerTarget = { barPrefix = nil, slot = nil, callback = nil }

local function CreateGlyphPicker()
    if GlyphPicker then return GlyphPicker end
    
    local frame = CreateFrame("Frame", "ControlKitGlyphPicker", UIParent)
    frame:SetWidth(220)
    frame:SetHeight(280)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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
    frame:SetFrameStrata("TOOLTIP")
    frame:Hide()
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Select Glyph")
    frame.title = title
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    
    -- Glyph buttons container
    local ICON_SIZE = 28
    local ICON_SPACING = 4
    local ICONS_PER_ROW = 4
    local startY = -40
    local startX = 20
    
    frame.glyphButtons = {}
    
    -- Helper to create a section of glyph buttons
    local function CreateGlyphSection(categoryName, glyphs, yOffset)
        -- Category label
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", frame, "TOPLEFT", startX, yOffset)
        label:SetText(categoryName)
        
        yOffset = yOffset - 15
        
        for i, glyph in ipairs(glyphs) do
            local btn = CreateFrame("Button", nil, frame)
            btn:SetWidth(ICON_SIZE)
            btn:SetHeight(ICON_SIZE)
            
            local col = ((i - 1) % ICONS_PER_ROW)
            local row = math.floor((i - 1) / ICONS_PER_ROW)
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 
                startX + col * (ICON_SIZE + ICON_SPACING), 
                yOffset - row * (ICON_SIZE + ICON_SPACING))
            
            -- Icon texture
            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints()
            icon:SetTexture(MEDIA_PATH .. glyph.id .. ".blp")
            btn.icon = icon
            
            -- Highlight texture
            local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
            highlight:SetBlendMode("ADD")
            
            -- Store glyph info
            btn.glyphId = glyph.id
            btn.glyphLabel = glyph.label
            
            -- Click handler
            btn:SetScript("OnClick", function()
                if GlyphPickerTarget.barPrefix and GlyphPickerTarget.slot then
                    SetCustomGlyph(GlyphPickerTarget.barPrefix, GlyphPickerTarget.slot, this.glyphId)
                    UpdateAllGlyphs()
                    if GlyphPickerTarget.callback then
                        GlyphPickerTarget.callback()
                    end
                end
                frame:Hide()
            end)
            
            -- Tooltip
            btn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(this.glyphLabel)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            table.insert(frame.glyphButtons, btn)
        end
        
        local numRows = math.ceil(table.getn(glyphs) / ICONS_PER_ROW)
        return yOffset - numRows * (ICON_SIZE + ICON_SPACING) - 10
    end
    
    -- Create sections for each category
    local yPos = startY
    yPos = CreateGlyphSection("Face Buttons:", AVAILABLE_GLYPHS.face, yPos)
    yPos = CreateGlyphSection("Triggers/Bumpers:", AVAILABLE_GLYPHS.triggers, yPos)
    yPos = CreateGlyphSection("D-Pad:", AVAILABLE_GLYPHS.dpad, yPos)
    yPos = CreateGlyphSection("Other:", AVAILABLE_GLYPHS.other, yPos)
    
    -- Use Default button
    local defaultBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    defaultBtn:SetWidth(80)
    defaultBtn:SetHeight(20)
    defaultBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
    defaultBtn:SetText("Default")
    defaultBtn:SetScript("OnClick", function()
        if GlyphPickerTarget.barPrefix and GlyphPickerTarget.slot then
            ClearCustomGlyph(GlyphPickerTarget.barPrefix, GlyphPickerTarget.slot)
            UpdateAllGlyphs()
            if GlyphPickerTarget.callback then
                GlyphPickerTarget.callback()
            end
        end
        frame:Hide()
    end)
    
    -- Clear button
    local clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearBtn:SetWidth(80)
    clearBtn:SetHeight(20)
    clearBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        if GlyphPickerTarget.barPrefix and GlyphPickerTarget.slot then
            ClearCustomGlyph(GlyphPickerTarget.barPrefix, GlyphPickerTarget.slot)
            UpdateAllGlyphs()
            if GlyphPickerTarget.callback then
                GlyphPickerTarget.callback()
            end
        end
        frame:Hide()
    end)
    
    -- ESC closes the picker
    tinsert(UISpecialFrames, "ControlKitGlyphPicker")
    
    GlyphPicker = frame
    return frame
end

-- Show the glyph picker for a specific bar and slot
local function ShowGlyphPicker(barPrefix, slot, anchorFrame, callback)
    local picker = CreateGlyphPicker()
    
    GlyphPickerTarget.barPrefix = barPrefix
    GlyphPickerTarget.slot = slot
    GlyphPickerTarget.callback = callback
    
    -- Update title
    local barName = "Main"
    if barPrefix == "MultiBarBottomLeftButton" then
        barName = "LB"
    elseif barPrefix == "MultiBarBottomRightButton" then
        barName = "RB"
    end
    picker.title:SetText("Select Glyph (Slot " .. slot .. " - " .. barName .. ")")
    
    -- Position near anchor if provided
    picker:ClearAllPoints()
    if anchorFrame then
        picker:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 10, 0)
    else
        picker:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    picker:Show()
end

--------------------------------------------------------------------------------
-- Bar Editor Panel (Customize Tab)
--------------------------------------------------------------------------------

local BarEditorPanel = nil

local function CreateBarEditorPanel()
    if BarEditorPanel then return BarEditorPanel end
    
    local frame = CreateFrame("Frame", "ControlKitBarEditorFrame", UIParent)
    frame:SetWidth(380)
    frame:SetHeight(320)
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
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Customize Glyphs")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    
    -- Instructions
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("TOP", frame, "TOP", 0, -35)
    instructions:SetText("Click any slot to change its glyph")
    instructions:SetTextColor(0.7, 0.7, 0.7)
    
    -- Bar slot button creation helper
    local SLOT_SIZE = 26
    local SLOT_SPACING = 2
    frame.barSlots = {}
    
    local function CreateBarSlotGrid(barPrefix, barLabel, yOffset)
        -- Bar label
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
        label:SetText(barLabel)
        
        local slots = {}
        for slot = 1, 12 do
            local btn = CreateFrame("Button", nil, frame)
            btn:SetWidth(SLOT_SIZE)
            btn:SetHeight(SLOT_SIZE)
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 
                20 + (slot - 1) * (SLOT_SIZE + SLOT_SPACING), 
                yOffset - 18)
            
            -- Background
            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(0.1, 0.1, 0.1, 0.8)
            btn.bg = bg
            
            -- Icon texture
            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
            icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
            btn.icon = icon
            
            -- Custom indicator (border when custom)
            local customBorder = btn:CreateTexture(nil, "OVERLAY")
            customBorder:SetAllPoints()
            customBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            customBorder:SetBlendMode("ADD")
            customBorder:SetVertexColor(0, 1, 0, 0.5)
            customBorder:Hide()
            btn.customBorder = customBorder
            
            -- Highlight
            local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
            highlight:SetBlendMode("ADD")
            
            -- Store info
            btn.barPrefix = barPrefix
            btn.slot = slot
            
            -- Click handler
            btn:SetScript("OnClick", function()
                ShowGlyphPicker(this.barPrefix, this.slot, this, function()
                    -- Refresh this slot's display
                    local glyphId = GetGlyphForSlot(this.barPrefix, this.slot)
                    if glyphId then
                        this.icon:SetTexture(MEDIA_PATH .. glyphId .. ".blp")
                    end
                    -- Update custom indicator
                    if HasCustomGlyph(this.barPrefix, this.slot) then
                        this.customBorder:Show()
                    else
                        this.customBorder:Hide()
                    end
                end)
            end)
            
            -- Tooltip
            btn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                local glyphId = GetGlyphForSlot(this.barPrefix, this.slot)
                local isCustom = HasCustomGlyph(this.barPrefix, this.slot)
                GameTooltip:SetText("Slot " .. this.slot)
                if isCustom then
                    GameTooltip:AddLine("Custom: " .. (glyphId or "none"), 0, 1, 0)
                else
                    GameTooltip:AddLine("Default: " .. (glyphId or "none"), 0.7, 0.7, 0.7)
                end
                GameTooltip:AddLine("Click to change", 0.5, 0.5, 0.5)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            slots[slot] = btn
        end
        
        frame.barSlots[barPrefix] = slots
        return yOffset - 55
    end
    
    -- Create grids for each bar
    local yPos = -55
    yPos = CreateBarSlotGrid("ActionButton", "Main Action Bar:", yPos)
    yPos = CreateBarSlotGrid("MultiBarBottomLeftButton", "LB (Shift) Bar:", yPos)
    yPos = CreateBarSlotGrid("MultiBarBottomRightButton", "RB (Alt) Bar:", yPos)
    
    -- Reset All button
    local resetAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetAllBtn:SetWidth(150)
    resetAllBtn:SetHeight(22)
    resetAllBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    resetAllBtn:SetText("Reset All to Defaults")
    resetAllBtn:SetScript("OnClick", function()
        ClearAllCustomGlyphs()
        UpdateAllGlyphs()
        -- Refresh all slot displays
        RefreshBarEditorSlots()
        Print("All custom glyphs cleared.")
    end)
    
    -- ESC closes
    tinsert(UISpecialFrames, "ControlKitBarEditorFrame")
    
    BarEditorPanel = frame
    return frame
end

-- Refresh the bar editor slot displays
local function RefreshBarEditorSlots()
    if not BarEditorPanel then return end
    
    for barPrefix, slots in pairs(BarEditorPanel.barSlots) do
        for slot, btn in pairs(slots) do
            local glyphId = GetGlyphForSlot(barPrefix, slot)
            if glyphId then
                btn.icon:SetTexture(MEDIA_PATH .. glyphId .. ".blp")
            end
            -- Update custom indicator
            if HasCustomGlyph(barPrefix, slot) then
                btn.customBorder:Show()
            else
                btn.customBorder:Hide()
            end
        end
    end
end

-- Show the bar editor
local function ShowBarEditor()
    local editor = CreateBarEditorPanel()
    RefreshBarEditorSlots()
    editor:Show()
end

-- Toggle bar editor
local function ToggleBarEditor()
    local editor = CreateBarEditorPanel()
    if editor:IsShown() then
        editor:Hide()
    else
        RefreshBarEditorSlots()
        editor:Show()
    end
end

--------------------------------------------------------------------------------
-- Alt+Click Hook for Action Buttons
--------------------------------------------------------------------------------

local function HookActionButtonClicks()
    local actionBars = GetActionBars()
    
    for _, barConfig in ipairs(actionBars) do
        for slot = 1, 12 do
            local buttonName = barConfig.prefix .. slot
            local button = getglobal(buttonName)
            
            if button and not button.ControlKitClickHooked then
                local originalOnClick = button:GetScript("OnClick")
                
                button:SetScript("OnClick", function()
                    -- Check for Alt+Click to open glyph picker
                    if IsAltKeyDown() and arg1 == "LeftButton" then
                        -- Get the bar prefix from the button name
                        local prefix = string.gsub(this:GetName(), "%d+$", "")
                        local slotNum = tonumber(string.match(this:GetName(), "(%d+)$"))
                        
                        ShowGlyphPicker(prefix, slotNum, this, function()
                            UpdateAllGlyphs()
                        end)
                        return  -- Don't execute original click
                    end
                    
                    -- Call original click handler
                    if originalOnClick then
                        originalOnClick()
                    end
                end)
                
                button.ControlKitClickHooked = true
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Game Menu (ESC) Button
--------------------------------------------------------------------------------

local function CreateGameMenuButton()
    -- Safety check - make sure GameMenuFrame exists
    if not GameMenuFrame then return end
    
    -- Don't create if already exists
    if GameMenuButtonControlKit then return end
    
    -- Create ControlKit button for the game menu
    local menuButton = CreateFrame("Button", "GameMenuButtonControlKit", GameMenuFrame, "GameMenuButtonTemplate")
    menuButton:SetText("ControlKit")
    menuButton:SetScript("OnClick", function()
        PlaySound("igMainMenuOption")
        HideUIPanel(GameMenuFrame)
        ToggleOptionsPanel()
    end)
    
    -- Find a valid anchor button (try different buttons that might exist)
    local anchorButton = nil
    local buttonsToTry = {
        "GameMenuButtonOptions",
        "GameMenuButtonSoundOptions",
        "GameMenuButtonUIOptions",
        "GameMenuButtonKeybindings",
    }
    
    for _, btnName in ipairs(buttonsToTry) do
        local btn = getglobal(btnName)
        if btn then
            anchorButton = btn
            break
        end
    end
    
    if not anchorButton then
        -- Fallback: position at top of menu frame
        menuButton:SetPoint("TOP", GameMenuFrame, "TOP", 0, -10)
        return
    end
    
    -- Get button height for spacing
    local buttonHeight = anchorButton:GetHeight() + 1
    
    -- Position ControlKit button at the anchor's current position
    local point, relativeTo, relativePoint, xOfs, yOfs = anchorButton:GetPoint(1)
    if point and relativeTo then
        menuButton:SetPoint(point, relativeTo, relativePoint, xOfs or 0, yOfs or 0)
        
        -- Move the anchor button down below ControlKit
        anchorButton:ClearAllPoints()
        anchorButton:SetPoint("TOP", menuButton, "BOTTOM", 0, -1)
        
        -- Expand the game menu frame to fit the new button
        GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + buttonHeight)
    else
        -- Simple fallback positioning
        menuButton:SetPoint("TOP", anchorButton, "TOP", 0, buttonHeight)
    end
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
        Print("  /ck customize - Open glyph customization panel")
        Print("  /ck toggle - Toggle glyphs on/off")
        Print("  /ck enable - Enable glyphs")
        Print("  /ck disable - Disable glyphs")
        Print("  /ck style <xbox|steamdeck|playstation> - Change controller style")
        Print("  /ck scale <number> - Set glyph scale (default: 1.0)")
        Print("  /ck reset - Reset to default settings")
        Print("  /ck status - Show current settings")
        Print("  Alt+Click action buttons to customize individual glyphs")
        return
    end
    
    if cmd == "customize" or cmd == "custom" or cmd == "edit" then
        ShowBarEditor()
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
        HookActionButtonClicks()
        Print("Loaded. Type /ck to open options. Alt+Click action buttons to customize.")
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
