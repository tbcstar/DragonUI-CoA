-- Copyright (c) 2026 NeticSoul. Licensed under the MIT License; see LICENSE.

local addon = select(2, ...)
local CP = addon.CharacterPanel

local MODEL_W, MODEL_H = 231, 320
local VANILLA_W, VANILLA_H = 233, 215
local VANILLA_X, VANILLA_Y = 65, -78

-- Blizzard's own DressUpTexturePath applies this same fallback: the 3.3.5a client ships no
-- Gnome or Troll backdrop art.
local RACE_FALLBACK = { GNOME = "DWARF", TROLL = "ORC" }

<<<<<<< HEAD
-- `unit` lets the Conquest of Azeroth skin build the same backdrop for the Inspect viewport, which shows the
-- *target* rather than the player; the character model defaults to "player" like Blizzard's own.
local function raceKey(unit)
    unit = unit or "player"
    local _, fileName = UnitRace(unit)
=======
-- Lifted far enough to run past the art's last row, so their bottom pair ships rebuilt to row 127.
local FLOOR = { BLOODELF = true, DRAENEI = true, NIGHTELF = true, SCOURGE = true, TAUREN = true }
local FLOOR_ART = addon._dir .. "CharacterPanel\\RaceBackground\\"

local function artRace(fileName)
>>>>>>> ecd4c6fb (feat(inspect): retail-style inspect window with race backdrops that fit every race)
    if not fileName then return "ORC" end
    local upper = strupper(fileName)
    return RACE_FALLBACK[upper] or upper
end

<<<<<<< HEAD
local function racePath(unit)
    unit = unit or "player"
    local _, fileName = UnitRace(unit)
    if not fileName then return "Interface\\DressUpFrame\\DressUpBackground-Orc" end
    local upper = strupper(fileName)
    fileName = RACE_FALLBACK[upper] or fileName
    return "Interface\\DressUpFrame\\DressUpBackground-" .. fileName
=======
local function artPath(fileName, suffix)
    local race = artRace(fileName)
    if suffix >= 3 and FLOOR[race] then return FLOOR_ART .. strlower(race) .. "-floor" .. suffix end
    return "Interface\\DressUpFrame\\DressUpBackground-" .. race .. suffix
>>>>>>> ecd4c6fb (feat(inspect): retail-style inspect window with race backdrops that fit every race)
end

-- Retail's own per-race dimming: the backdrops differ in brightness, so one flat value washes out
-- the pale ones. Keyed off the RESOLVED race, so a Gnome drawn on Dwarf art gets Dwarf's value.
local RACE_OVERLAY_ALPHA = {
    BLOODELF = 0.8, NIGHTELF = 0.6, SCOURGE = 0.3,
    TROLL = 0.6, ORC = 0.6, WORGEN = 0.5, GOBLIN = 0.6,
}
local OVERLAY_ALPHA_DEFAULT = 0.7

local function resizeModel()
    local model = _G.CharacterModelFrame
    local cf = _G.CharacterFrame
    if not model or not cf or not cf.Inset or model._duiResized then return end
    model._duiResized = true

    model:SetSize(MODEL_W, MODEL_H)
    model:ClearAllPoints()
    -- Retail puts it at (52,-66) of the frame; the Inset starts at (4,-60), so that is (48,-6) here.
    model:SetPoint("TOPLEFT", cf.Inset, "TOPLEFT", 48, -6)
end

-- The backdrop grid is retail's 212x245 / 231x320 split; keeping the ratios lets the same art
-- scale to any model viewport (Conquest of Azeroth's) while staying continuous across the seams.
local X_SPLIT, Y_SPLIT = 212 / 231, 245 / 320

-- Cropped to the viewport: 245 + 75 = 320, the model's exact height. Retail runs the bottom pair
-- their full 128, which made the strip under the model depend on that overhang drawing.
local BOTTOM_CROP = 75 / 128
local QUARTERS = {
    { key = "TopLeft", suffix = 1, tc = { 0.171875, 1, 0.0392156862745098, 1 },
      point = "TOPLEFT", rel = "TOPLEFT" },
    { key = "TopRight", suffix = 2, tc = { 0, 0.296875, 0.0392156862745098, 1 },
      point = "TOPLEFT", rel = "TOPRIGHT" },
    { key = "BotLeft", suffix = 3, tc = { 0.171875, 1, 0, BOTTOM_CROP },
      point = "TOPLEFT", rel = "BOTTOMLEFT" },
    { key = "BotRight", suffix = 4, tc = { 0, 0.296875, 0, BOTTOM_CROP },
      point = "TOPLEFT", rel = "BOTTOMRIGHT" },
}
CP.MODEL_W, CP.MODEL_H = MODEL_W, MODEL_H

<<<<<<< HEAD
-- The race backdrops are strongly coloured and the model reads as a cutout pasted on them. Retail
-- desaturates then dims under black, so the character is the only colour in the viewport.
local function overlayAlpha(unit)
    return RACE_OVERLAY_ALPHA[raceKey(unit)] or OVERLAY_ALPHA_DEFAULT
=======
-- Down uses the top pair's 10 cropped rows; up past 0 needs a FLOOR race's rebuilt rows.
local LIFT_MIN, LIFT_MAX = -10, 53

local RACE_LIFT = {
    BLOODELFF = 25, BLOODELFM = 34, DRAENEIF = 7, DRAENEIM = 7, DWARFF = -10, DWARFM = -10,
    GNOMEF = -10, GNOMEM = -10, HUMANF = 1, HUMANM = 1, NIGHTELFF = 29, NIGHTELFM = 30,
    ORCM = 1, SCOURGEF = 13, SCOURGEM = 13, TAURENF = 21, TAURENM = 21,
}

local function shadeFor(fileName)
    return SHADE_BY_RACE[artRace(fileName)] or SHADE_DEFAULT
end

function CP.RaceLiftKey(fileName, sex)
    return strupper(fileName or "ORC") .. (sex == 3 and "F" or "M")
end

function CP.RaceBackdropLift(key)
    return math.max(LIFT_MIN, math.min(LIFT_MAX, RACE_LIFT[key] or 0))
end

-- Slides the art up `lift` px and keeps the 320 total by trading top rows for bottom ones.
local function layoutQuarters(bySuffix, lift)
    for _, q in ipairs(QUARTERS) do
        local piece = bySuffix[q.suffix]
        if piece then
            if q.suffix <= 2 then
                piece:SetHeight(q.h - lift)
                piece:SetTexCoord(q.tc[1], q.tc[2], q.tc[3] + lift / 256, 1)
            else
                piece:SetHeight(q.h + lift)
                piece:SetTexCoord(q.tc[1], q.tc[2], 0, (q.h + lift) / 128)
            end
        end
    end
end

-- Shared with the inspect window, which paints other units' races.
function CP.PaintRaceBackdrop(bySuffix, shade, fileName, sex)
    -- Plain truth test: the pre-database config is {}, and a missing key must read as colour.
    local desaturate = CP:Config().grey_model_backdrop and true or false
    for suffix, piece in pairs(bySuffix) do
        piece:SetTexture(artPath(fileName, suffix))
        piece:SetDesaturated(desaturate)
        piece:Show()
    end
    if shade then
        shade:SetAlpha(desaturate and shadeFor(fileName) or 0)
        shade:Show()
    end
    layoutQuarters(bySuffix, CP.RaceBackdropLift(CP.RaceLiftKey(fileName, sex)))
>>>>>>> ecd4c6fb (feat(inspect): retail-style inspect window with race backdrops that fit every race)
end

local function buildRaceBackdrop(model)
    if not model or model._duiRaceBg then return end
    model._duiRaceBg = {}

<<<<<<< HEAD
    local w, h = model:GetWidth() or 0, model:GetHeight() or 0
    if w == 0 then w = MODEL_W end
    if h == 0 then h = MODEL_H end
    local qw, qh = math.floor(w * X_SPLIT + 0.5), math.floor(h * Y_SPLIT + 0.5)

    local topLeft
    for _, q in ipairs(QUARTERS) do
        local tex = model:CreateTexture(nil, "BACKGROUND")
        tex:SetTexCoord(unpack(q.tc))
        local pw, ph = qw, qh
        if q.key == "TopRight" then
            pw = w - qw
        elseif q.key == "BotLeft" then
            ph = h - qh
        elseif q.key == "BotRight" then
            pw, ph = w - qw, h - qh
=======
-- Returns the quarters by file suffix and the shade, for any 231x320 viewport.
function CP.CreateRaceBackdrop(viewport)
    -- Every other quarter anchors to the top-left one, so it is made before the rest.
    local anchorEntry
    for _, entry in ipairs(QUARTERS) do
        if entry.key == "TopLeft" then anchorEntry = entry break end
    end
    if not anchorEntry then return end

    local bySuffix = {}
    local anchorPiece = addQuarter(viewport, anchorEntry, viewport)
    bySuffix[anchorEntry.suffix] = anchorPiece
    for _, entry in ipairs(QUARTERS) do
        if entry ~= anchorEntry then
            bySuffix[entry.suffix] = addQuarter(viewport, entry, anchorPiece)
>>>>>>> ecd4c6fb (feat(inspect): retail-style inspect window with race backdrops that fit every race)
        end
        tex:SetSize(pw, ph)
        if q.key == "TopLeft" then
            tex:SetPoint(q.point, model, q.rel, 0, 0)
            topLeft = tex
        else
            tex:SetPoint(q.point, topLeft, q.rel, 0, 0)
        end
        model._duiRaceBg[q.suffix] = tex
    end

<<<<<<< HEAD
    -- Bounded by the MODEL, not the backdrop grid: the grid runs 53px past the viewport, and
    -- measuring up from its floor left the two edges a pixel apart. BORDER is retail's layer.
    local overlay = model:CreateTexture(nil, "BORDER")
    overlay:SetTexture(0, 0, 0)
    overlay:SetPoint("TOPLEFT", model._duiRaceBg[1], "TOPLEFT", 0, 0)
    overlay:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", 0, 0)
    model._duiRaceBgOverlay = overlay
end

local function applyRaceBackground(model, unit)
    model = model or _G.CharacterModelFrame
    if not model or not model._duiRaceBg then return end

    -- Read plainly, never as `~= false`: Config() falls back to an empty table before the database
    -- is up, and under that idiom a missing value would read as ENABLED.
    local grey = CP:Config().grey_model_backdrop and true or false
    local base = racePath(unit)
    for suffix, tex in pairs(model._duiRaceBg) do
        tex:SetTexture(base .. suffix)
        tex:SetDesaturated(grey)
        tex:Show()
    end
    if model._duiRaceBgOverlay then
        model._duiRaceBgOverlay:SetAlpha(grey and overlayAlpha(unit) or 0)
        model._duiRaceBgOverlay:Show()
    end
=======
    -- Held to the viewport's corner, not the art's, so the shade ends exactly where the model does.
    local shade = viewport:CreateTexture(nil, "BORDER")
    shade:SetPoint("BOTTOMRIGHT", viewport)
    shade:SetPoint("TOPLEFT", anchorPiece)
    shade:SetTexture(0, 0, 0)
    shade:SetAlpha(0)
    return bySuffix, shade
end

local function createBackdrop()
    local viewport = _G.CharacterModelFrame
    if viewport == nil or viewport._duiRaceBg then return end
    viewport._duiRaceBg, viewport._duiRaceBgOverlay = CP.CreateRaceBackdrop(viewport)
end

local function paintBackdrop()
    local viewport = _G.CharacterModelFrame
    if not (viewport and viewport._duiRaceBg) then return end
    local _, fileName = UnitRace("player")
    CP.PaintRaceBackdrop(viewport._duiRaceBg, viewport._duiRaceBgOverlay, fileName, UnitSex("player"))
>>>>>>> ecd4c6fb (feat(inspect): retail-style inspect window with race backdrops that fit every race)
end

CP.ApplyModelBackdrop = applyRaceBackground

-- Shared with the Conquest of Azeroth skin, which builds the same backdrop on its own model viewport; the
-- Inspect passes its unit ("target") so the backdrop reads that target's race, not the player's.
function CP.BuildModelBackdrop(model, unit)
    buildRaceBackdrop(model)
    applyRaceBackground(model, unit)
end

-- Blizzard anchors the viewport in XML only; nothing else undoes our placement without a reload.
function CP.RestoreModel()
    local model = _G.CharacterModelFrame
    if not model then return end
    model._duiResized = nil

    model:SetSize(VANILLA_W, VANILLA_H)
    model:ClearAllPoints()
    model:SetPoint("TOPLEFT", model:GetParent(), "TOPLEFT", VANILLA_X, VANILLA_Y)

    if model._duiRaceBg then
        for _, tex in pairs(model._duiRaceBg) do tex:Hide() end
    end
    if model._duiRaceBgOverlay then model._duiRaceBgOverlay:Hide() end
end

local function build()
    resizeModel()
    CP.BuildModelBackdrop(_G.CharacterModelFrame)
end

CP.RefreshRaceBackground = applyRaceBackground

CP:RegisterBuilder("model", build)
