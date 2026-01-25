local addonName = ...

-- Keybind localization
BINDING_HEADER_DAWNLEADERS = "DawnLeaders"
BINDING_NAME_DAWNLEADERS_TOGGLE = "Toggle Attendance Window"

local StdUi = LibStub and LibStub("StdUi", true)
if not StdUi then
    error(addonName .. ": Required library StdUi not found!")
    return
end

-- State: group filters and window reference
local groupFilters = {true, true, true, true, true, true, true, true}

local attendanceWindow
local UpdateRaidList

-- Build comma-separated list of raid members from selected groups
local function BuildRaidList()
    if not IsInRaid() then
        return "You are not in a raid group."
    end

    local text = ""
    local sep = ""

    for i = 1, 40 do
        local unit = "raid" .. i
        if UnitExists(unit) then
            local name, realm = UnitName(unit)
            local subgroup = select(3, GetRaidRosterInfo(i))

            if groupFilters[subgroup] then
                if not realm or realm == "" then
                    realm = GetRealmName():gsub("%s+", "")
                end

                text = text .. sep .. name .. "-" .. realm
                sep = ","
            end
        end
    end

    return text ~= "" and text or "No players found in selected groups."
end

local function CreateWindow()
    local window = StdUi:Window(UIParent, 400, 230, "Dawn Attendance")
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 200)

    local editBox = StdUi:MultiLineBox(window, 380, 90, nil)
    StdUi:GlueTop(editBox, window, 0, -30, "CENTER")

    -- Close window on Ctrl+C or Escape
    if editBox.editBox then
        editBox.editBox:SetScript("OnKeyDown", function(_, key)
            if (key == "C" and IsControlKeyDown()) or key == "ESCAPE" then
                window:Hide()
            end
        end)
    end

    local label = StdUi:Label(window, "Select groups to include:")
    StdUi:GlueBelow(label, editBox, 0, -8, "LEFT")

    -- Create checkboxes in 2 rows of 4 (groups 1-4 top, 5-8 bottom)
    local groupCheckboxes = {}
    for i = 1, 8 do
        local checkbox = StdUi:Checkbox(window, tostring(i))

        local row = (i <= 4) and 0 or 1
        local col = (i - 1) % 4
        local xOffset = 70 + col * 60
        local yOffset = -10 - row * 30

        StdUi:GlueBelow(checkbox, label, xOffset - 10, yOffset, "LEFT")

        checkbox:SetChecked(true)

        checkbox.OnValueChanged = function(_, state)
            groupFilters[i] = state
            UpdateRaidList(editBox)
            -- Restore focus to editbox after checkbox click
            if editBox.editBox then
                editBox.editBox:SetFocus()
            end
        end

        groupCheckboxes[i] = checkbox
    end

    local logoFrame = StdUi:Frame(window, 32, 32)
    local logoTexture = StdUi:Texture(logoFrame, 32, 32, [[Interface\AddOns\DawnLeaders\media\dawnLogo]])
    StdUi:GlueTop(logoTexture, logoFrame, 0, 0, "CENTER")
    StdUi:GlueBottom(logoFrame, window, -10, 10, "RIGHT")

    window.editBox = editBox
    window.groupCheckboxes = groupCheckboxes

    return window
end

function UpdateRaidList(editBox)
    local text = BuildRaidList()
    editBox:SetValue(text)
    if editBox.editBox then
        editBox.editBox:HighlightText()
    end
end

local function ShowWindow()
    if not attendanceWindow then
        attendanceWindow = CreateWindow()
    end

    -- Reset all group filters
    for i = 1, 8 do
        groupFilters[i] = true
        attendanceWindow.groupCheckboxes[i]:SetChecked(true)
    end

    UpdateRaidList(attendanceWindow.editBox)
    attendanceWindow:Show()

    -- Set focus after showing (needs to run on next frame for keybind invocations)
    C_Timer.After(0, function()
        if attendanceWindow.editBox.editBox then
            attendanceWindow.editBox.editBox:SetFocus()
        end
    end)
end

-- Global function for keybind support
function DawnLeaders_ToggleWindow()
    if attendanceWindow and attendanceWindow:IsShown() then
        attendanceWindow:Hide()
    else
        ShowWindow()
    end
end

SLASH_DAWNLEADERS1 = "/dawnatd"
SLASH_DAWNLEADERS2 = "/gws"
SLASH_DAWNLEADERS3 = "/atd"

SlashCmdList["DAWNLEADERS"] = function()
    ShowWindow()
end
