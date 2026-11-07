-- Copyright (c) 2026 NeticSoul. Licensed under the MIT License; see LICENSE.

local addon = select(2, ...)

-- micromenu.lua captures MICRO_BUTTONS in a file-scope local, so a button that does not exist by
-- the time it loads can never join the strip -- hence at load, before it, not at PLAYER_LOGIN.
if _G.CollectionsMicroButton then return end

local ICON = addon._dir .. "Micromenu\\uimicromenu2x"

local btn = CreateFrame("Button", "CollectionsMicroButton", UIParent)
btn:SetSize(32, 40)
btn:SetPoint("CENTER")
btn:Hide()

-- layoutMicroButtons re-points all four; they only have to exist for its getters to return one.
btn:SetNormalTexture(ICON)
btn:SetPushedTexture(ICON)
btn:SetDisabledTexture(ICON)
btn:SetHighlightTexture(ICON)
btn:GetHighlightTexture():SetBlendMode("ADD")

local BINDING = "DRAGONUI_TOGGLE_COLLECTIONS"

-- The Key Bindings window reads BINDING_NAME_* globals, and 3.3.5's tooltip helper reads the button
-- fields -- so all three hold plain strings. None of them may be read at file scope: modules load
-- before ADDON_LOADED, which is the first moment the stored language override can be read
-- (core.lua:46 calls addon.RefreshLocale there), so an eager read freezes the client's own locale
-- into the tooltip for the whole session -- Chinese UI with an English "Pets & Mounts" tooltip.
local function RefreshText()
    local name = addon.L["Pets & Mounts"]
    _G["BINDING_NAME_" .. BINDING] = name
    btn.tooltipText = name
    btn.newbieText = addon.L["The mounts and pets you have collected."]
end
RefreshText()

local localeWatch = CreateFrame("Frame")
localeWatch:RegisterEvent("ADDON_LOADED")
localeWatch:SetScript("OnEvent", function(self, event, name)
    if name ~= "DragonUI" then return end
    self:UnregisterEvent("ADDON_LOADED")
    -- core.lua registered its OnInitialize earlier, so the locale is already re-pointed here.
    RefreshText()
end)

btn:RegisterForClicks("LeftButtonUp")
btn:SetScript("OnClick", function()
    if addon.ToggleCollections then addon.ToggleCollections() end
end)
-- What MainMenuBarMicroButton's own OnEnter does: it is what puts every other micro menu tooltip at
-- the default anchor and prints the second line in NORMAL_FONT_COLOR.
btn:SetScript("OnEnter", function(self)
    -- Rebuilt per hover rather than cached: a rebind would otherwise show the old key until reload.
    local text = self.tooltipText
    if MicroButtonTooltipText then text = MicroButtonTooltipText(text, BINDING) end
    GameTooltip_AddNewbieTip(self, text, 1.0, 1.0, 1.0, self.newbieText)
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
