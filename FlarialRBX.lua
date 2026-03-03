-- ╔══════════════════════════════════════════════════════════════════╗
-- ║            FlarialRBX UI Library  —  v1.0.0                     ║
-- ║  Pixel-accurate port of Flarial Client V2 ClickGUI aesthetic    ║
-- ║  Colors extracted directly from dll-oss-main source code        ║
-- ║  Place in: ReplicatedStorage > FlarialRBX (ModuleScript)        ║
-- ╚══════════════════════════════════════════════════════════════════╝

--[[
  QUICK START:
    local FlarialRBX = require(game.ReplicatedStorage.FlarialRBX)

    local Win = FlarialRBX:CreateWindow({
        Title      = "FlarialRBX",
        Subtitle   = "v1.0.0",
        ToggleKey  = Enum.KeyCode.RightShift,
        Blur       = true,
    })

    -- Module grid tab (like the main Modules page in Flarial)
    local ModulesTab = Win:CreateTab({
        Name      = "Modules",
        Icon      = "⊞",
        IsModules = true,
    })
    ModulesTab:CreateModCard({
        Name     = "Reach",
        Icon     = "⚔",
        Default  = false,
        Callback = function(enabled) print("Reach:", enabled) end,
        OnSettings = function() print("Open Reach settings") end,
    })

    -- Settings tab (toggle, slider, dropdown, keybind, button)
    local CombatTab = Win:CreateTab({ Name = "Combat", Icon = "⚔" })
    local ReachSec  = CombatTab:CreateSection("Reach")
    ReachSec:CreateToggle({
        Name     = "Reach",
        Default  = false,
        Callback = function(v) end,
    })
    ReachSec:CreateSlider({
        Name     = "Distance",
        Min      = 1, Max = 6, Default = 3.5,
        Suffix   = " blocks", Decimals = 1,
        Callback = function(v) end,
    })
    ReachSec:CreateDropdown({
        Name     = "Mode",
        Options  = { "Normal", "Packet", "Bypass" },
        Default  = "Normal",
        Callback = function(v) end,
    })
    ReachSec:CreateKeybind({
        Name     = "Toggle Key",
        Default  = Enum.KeyCode.V,
        Callback = function(k) end,
    })

  BLUR IMPLEMENTATION:
    FlarialRBX automatically inserts a BlurEffect into Lighting and tweens its
    Size between 0 (hidden) and 14 (open). This is the closest Roblox equivalent
    to Flarial's Gaussian blur that runs behind the GUI rectangle.

    If you need stronger isolation (e.g., don't want the blur to affect other GUIs):
      • Create a Part in Workspace with Material = Glass + Transparency ~0.05
      • Attach a SurfaceGui to it and render your UI inside
      • This is "Method 2" but has drawbacks (needs 3D anchor, Z-fighting)
    The default BlurEffect approach (Method 1) is recommended.
]]

-- ─────────────────────────────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local Lighting         = game:GetService("Lighting")
local CoreGui          = game:GetService("CoreGui")

-- ─────────────────────────────────────────────────────────────
--  FLARIAL CLIENT V2 — EXACT COLOR PALETTE
--  Source file: dll-oss-main/src/Client/Module/Modules/ClickGUI/ClickGUI.hpp
--  All hex values are verbatim from setDef() calls in defaultConfig()
-- ─────────────────────────────────────────────────────────────
local function HEX(h)
    local r = tonumber(h:sub(1,2), 16) or 0
    local g = tonumber(h:sub(3,4), 16) or 0
    local b = tonumber(h:sub(5,6), 16) or 0
    return Color3.fromRGB(r, g, b)
end

local C = {
    -- ── Text ──────────────────────────────────────────────────────────
    globalText      = HEX("ffffff"),  -- All body text
    headerText      = HEX("ffffff"),  -- Nav / window header text
    settingsText    = HEX("ffffff"),  -- Settings panel text
    settingsSubtext = HEX("473b3d"),  -- Muted / sub-labels / section headers
    modNameText     = HEX("8b767a"),  -- Module card name

    -- ── Module badge colors ───────────────────────────────────────────
    modCardEnabled  = HEX("188830"),  -- "Enabled"  badge (green)
    modCardDisabled = HEX("7d1820"),  -- "Disabled" badge (dark red)

    -- ── Primary palette ───────────────────────────────────────────────
    primary1 = HEX("ff233a"),  -- Accent / active / enabled toggle track / slider fill
    primary2 = HEX("ffffff"),  -- Toggle knob / slider thumb
    primary3 = HEX("9a6b72"),  -- Inactive / disabled toggle track
    primary4 = HEX("704b52"),  -- Hover on dropdown items / color picker base

    -- ── Secondary palette (backgrounds / surfaces) ────────────────────
    secondary1 = HEX("3f2a2d"),  -- Settings panel BG / hover fill
    secondary2 = HEX("201a1b"),  -- Nav bar, tooltips, button BG
    secondary3 = HEX("120e0f"),  -- Base window BG (darkest)
    secondary4 = HEX("1c1616"),  -- Active search bar BG
    secondary5 = HEX("8b1b25"),  -- Nav logo icon BG
    secondary6 = HEX("ff2438"),  -- Active nav tab BG (bright red)
    secondary7 = HEX("943c3c"),  -- Tooltip / dropdown outline
    secondary8 = HEX("302728"),  -- Inactive nav tab BG / gear box BG

    -- ── Module card surfaces ──────────────────────────────────────────
    modcard1 = HEX("201a1b"),  -- Card main surface
    modcard2 = HEX("2f2022"),  -- Card bottom strip
    modcard3 = HEX("3f2a2d"),  -- Icon container background
    modcard4 = HEX("705d60"),  -- Settings gear inner tint
    modicon  = HEX("1A1313"),  -- Module icon tint

    -- ── Misc ──────────────────────────────────────────────────────────
    flariallogo = HEX("FE4443"),  -- Logo color
    modsettings = HEX("FFFFFF"),  -- Settings gear icon color
}

-- ─────────────────────────────────────────────────────────────
--  TWEEN PRESETS  (mirrors FlarialGUI::lerp frame-factor style)
-- ─────────────────────────────────────────────────────────────
local TW = {
    INSTANT = TweenInfo.new(0.05, Enum.EasingStyle.Linear),
    FAST    = TweenInfo.new(0.14, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out),
    MEDIUM  = TweenInfo.new(0.22, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out),
    SLOW    = TweenInfo.new(0.38, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out),
    OPEN    = TweenInfo.new(0.30, Enum.EasingStyle.Quint,  Enum.EasingDirection.Out),
    SPRING  = TweenInfo.new(0.45, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
}

-- ─────────────────────────────────────────────────────────────
--  LAYOUT CONSTANTS
--  Derived from Constraints::RelativeConstraint calls in ClickGUI.cpp:
--    baseWidth  = RelativeConstraint(0.81)  → ~640 at 790px screen
--    baseHeight = RelativeConstraint(0.64)  → ~390 at 610px screen
--    navBar height = RelativeConstraint(0.124) * baseWidth ≈ 48px
--    ModCard  = RelativeConstraint(0.178,h) × RelativeConstraint(0.141,h) ≈ 145×100
-- ─────────────────────────────────────────────────────────────
local L = {
    WIN_W      = 640,
    WIN_H      = 400,
    NAV_H      = 50,
    NAV_ROUND  = 12,
    CARD_W     = 148,
    CARD_H     = 108,
    CARD_ROUND = 14,
    CARD_GAP   = 12,
    CARD_PAD   = 10,
    ROW_H      = 44,          -- Standard setting row height
    CORNER     = UDim.new(0, 12),
    CORNER_SM  = UDim.new(0, 9),
    CORNER_PILL= UDim.new(1, 0),
    STROKE_T   = 0.82,
}

-- ─────────────────────────────────────────────────────────────
--  PRIMITIVE HELPERS
-- ─────────────────────────────────────────────────────────────
local function tw(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or L.CORNER
    c.Parent = parent
    return c
end

local function stroke(parent, color, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color           = color or C.primary3
    s.Thickness       = thick or 1
    s.Transparency    = trans or L.STROKE_T
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function pad(parent, t, r, b, l)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 6)
    p.PaddingRight  = UDim.new(0, r or 6)
    p.PaddingBottom = UDim.new(0, b or 6)
    p.PaddingLeft   = UDim.new(0, l or 6)
    p.Parent = parent
    return p
end

local function vList(parent, spacing)
    local ll = Instance.new("UIListLayout")
    ll.FillDirection       = Enum.FillDirection.Vertical
    ll.SortOrder           = Enum.SortOrder.LayoutOrder
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ll.Padding             = UDim.new(0, spacing or 5)
    ll.Parent = parent
    return ll
end

local function hList(parent, spacing, valign)
    local ll = Instance.new("UIListLayout")
    ll.FillDirection      = Enum.FillDirection.Horizontal
    ll.SortOrder          = Enum.SortOrder.LayoutOrder
    ll.VerticalAlignment  = valign or Enum.VerticalAlignment.Center
    ll.Padding            = UDim.new(0, spacing or 4)
    ll.Parent = parent
    return ll
end

local function Frame(parent, size, pos, bg, alpha)
    local f = Instance.new("Frame")
    f.Size                  = size  or UDim2.new(1,0,0,40)
    f.Position              = pos   or UDim2.new(0,0,0,0)
    f.BackgroundColor3      = bg    or C.secondary3
    f.BackgroundTransparency= alpha or 0
    f.BorderSizePixel       = 0
    f.Parent = parent
    return f
end

local function Label(parent, text, size, pos, color, font, xAlign, textSize)
    local l = Instance.new("TextLabel")
    l.Text              = text   or ""
    l.Size              = size   or UDim2.new(1,0,0,18)
    l.Position          = pos    or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1
    l.TextColor3        = color  or C.globalText
    l.Font              = font   or Enum.Font.GothamBold
    l.TextSize          = textSize or 13
    l.TextXAlignment    = xAlign or Enum.TextXAlignment.Left
    l.TextYAlignment    = Enum.TextYAlignment.Center
    l.TextTruncate      = Enum.TextTruncate.AtEnd
    l.Parent = parent
    return l
end

local function Btn(parent, zindex)
    local b = Instance.new("TextButton")
    b.Size                  = UDim2.new(1,0,1,0)
    b.BackgroundTransparency= 1
    b.Text                  = ""
    b.ZIndex                = zindex or 8
    b.Parent = parent
    return b
end

local function Scroll(parent, size, pos)
    local sf = Instance.new("ScrollingFrame")
    sf.Size                  = size or UDim2.new(1,0,1,0)
    sf.Position              = pos  or UDim2.new(0,0,0,0)
    sf.BackgroundTransparency= 1
    sf.BorderSizePixel       = 0
    sf.ScrollBarThickness    = 3
    sf.ScrollBarImageColor3  = C.primary1
    sf.CanvasSize            = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    sf.ScrollingDirection    = Enum.ScrollingDirection.Y
    sf.ElasticBehavior       = Enum.ElasticBehavior.Always
    sf.Parent = parent
    return sf
end

-- Hover-glow card helper: adds a semi-transparent overlay for hover
local function addHover(frame, r)
    local h = Frame(frame, UDim2.new(1,0,1,0), nil, C.secondary1, 1)
    if r then corner(h, r) else corner(h, L.CORNER_SM) end
    frame.MouseEnter:Connect(function()  tw(h, TW.FAST, {BackgroundTransparency=0.85}) end)
    frame.MouseLeave:Connect(function()  tw(h, TW.FAST, {BackgroundTransparency=1}) end)
    return h
end

-- ════════════════════════════════════════════════════════════
--  BLUR SYSTEM
-- ════════════════════════════════════════════════════════════
local _blur = nil
local function initBlur()
    _blur = Lighting:FindFirstChild("FlarialBlur")
    if not _blur then
        _blur = Instance.new("BlurEffect")
        _blur.Name   = "FlarialBlur"
        _blur.Size   = 0
        _blur.Parent = Lighting
    end
end
local function setBlur(on) if _blur then tw(_blur, TW.MEDIUM, {Size = on and 14 or 0}) end end

-- ════════════════════════════════════════════════════════════
--  COMPONENT — TOGGLE
--  Mirrors: FlarialGUI::Toggle()
--  • Pill track (primary1 ON / primary3 OFF)
--  • White knob (primary2) that lerps left/right
--  • Color lerps at 0.10f * frameFactor per frame → TweenService MEDIUM
-- ════════════════════════════════════════════════════════════
local function Toggle(listParent, cfg)
    cfg = cfg or {}
    local state = cfg.Default ~= nil and cfg.Default or false
    local cb    = cfg.Callback or function() end

    -- Row
    local row = Frame(listParent, UDim2.new(1,0,0,L.ROW_H), nil, Color3.new(), 1)
    addHover(row)
    local divider = Frame(row, UDim2.new(1,-28,0,1), UDim2.new(0,14,1,-1), HEX("2a2020"), 0)

    -- Name
    local nameLbl = Label(row, cfg.Name or "Toggle",
        UDim2.new(1,-120,0,16), UDim2.new(0,14,0,7),
        C.globalText, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 13)

    -- Sub-state label
    local stateLbl = Label(row, "",
        UDim2.new(0,70,0,12), UDim2.new(0,14,0,26),
        C.modCardEnabled, Enum.Font.Gotham, Enum.TextXAlignment.Left, 10)

    -- Track  (mirrors: rectWidth = RelativeConstraint(0.058,"height",true))
    local track = Frame(row, UDim2.new(0,44,0,24), UDim2.new(1,-58,0.5,-12),
        state and C.primary1 or C.primary3, 0)
    corner(track, L.CORNER_PILL)

    -- Knob  (mirrors: circleWidth = SpacingConstraint(0.7, rectHeight))
    local knob = Frame(track, UDim2.new(0,17,0,17),
        UDim2.new(0, state and 23 or 3, 0.5, -8),
        C.primary2, 0)
    corner(knob, L.CORNER_PILL)

    local function apply(s, animate)
        local info = animate ~= false and TW.MEDIUM or TW.INSTANT
        tw(track, info, {BackgroundColor3 = s and C.primary1 or C.primary3})
        tw(knob,  info, {Position = UDim2.new(0, s and 23 or 3, 0.5, -8)})
        stateLbl.Text       = s and "Enabled" or "Disabled"
        stateLbl.TextColor3 = s and C.modCardEnabled or C.modCardDisabled
    end

    local btn = Btn(row)
    btn.MouseButton1Click:Connect(function()
        state = not state
        apply(state)
        -- Knob squish (visual feedback)
        tw(knob, TW.FAST, {Size = UDim2.new(0,21,0,17)})
        task.delay(0.12, function() tw(knob, TW.FAST, {Size = UDim2.new(0,17,0,17)}) end)
        task.spawn(cb, state)
    end)

    apply(state, false)

    return {
        Frame  = row,
        Set    = function(v) state = v; apply(v) end,
        Get    = function() return state end,
        Toggle = function() state = not state; apply(state); task.spawn(cb, state) end,
    }
end

-- ════════════════════════════════════════════════════════════
--  COMPONENT — SLIDER
--  Mirrors: FlarialGUI::Slider()
--  • Pill track (primary3) + fill (primary1) + white knob (primary2)
--  • Value display box top-left (primary3 bg → primary1 active)
--  • Drag with mouse, value rounds to Decimals places
-- ════════════════════════════════════════════════════════════
local function Slider(listParent, cfg)
    cfg = cfg or {}
    local minV     = cfg.Min      or 0
    local maxV     = cfg.Max      or 100
    local dec      = cfg.Decimals or 1
    local suffix   = cfg.Suffix   or ""
    local value    = math.clamp(cfg.Default or 50, minV, maxV)
    local dragging = false
    local cb       = cfg.Callback or function() end

    local row = Frame(listParent, UDim2.new(1,0,0,60), nil, Color3.new(), 1)
    addHover(row)
    Frame(row, UDim2.new(1,-28,0,1), UDim2.new(0,14,1,-1), HEX("2a2020"), 0)

    -- Name label
    Label(row, cfg.Name or "Slider",
        UDim2.new(1,-100,0,16), UDim2.new(0,14,0,7),
        C.globalText, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 13)

    -- Value display box  (mirrors: percWidth box in top-left of slider row)
    local fmt = "%." .. dec .. "f%s"
    local valBox = Frame(row, UDim2.new(0,54,0,20), UDim2.new(1,-68,0,7),
        C.primary3, 0)
    corner(valBox, UDim.new(0, 6))
    local valLbl = Label(valBox, string.format(fmt, value, suffix),
        UDim2.new(1,0,1,0), nil,
        C.primary2, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 11)

    -- Track BG
    local trackBG = Frame(row, UDim2.new(1,-28,0,5), UDim2.new(0,14,0,42),
        C.primary3, 0)
    corner(trackBG, L.CORNER_PILL)

    -- Filled portion
    local pct  = (value - minV) / (maxV - minV)
    local fill = Frame(trackBG, UDim2.new(pct,0,1,0), nil, C.primary1, 0)
    corner(fill, L.CORNER_PILL)

    -- Knob
    local knob = Frame(trackBG, UDim2.new(0,13,0,13), UDim2.new(pct,-6,0.5,-6),
        C.primary2, 0)
    corner(knob, L.CORNER_PILL)
    stroke(knob, C.primary1, 2, 0)

    local function setVal(newV)
        local mult = 10^dec
        newV = math.floor(math.clamp(newV, minV, maxV) * mult + 0.5) / mult
        value = newV
        local p = (value - minV) / (maxV - minV)
        tw(fill,  TW.FAST, {Size     = UDim2.new(p, 0, 1, 0)})
        tw(knob,  TW.FAST, {Position = UDim2.new(p, -6, 0.5, -6)})
        valLbl.Text = string.format(fmt, value, suffix)
        task.spawn(cb, value)
    end

    -- Wide invisible hit area for dragging
    local ib = Instance.new("TextButton")
    ib.Size = UDim2.new(1,0,6,0); ib.Position = UDim2.new(0,0,-2,0)
    ib.BackgroundTransparency = 1; ib.Text = ""; ib.ZIndex = 9
    ib.Parent = trackBG

    ib.MouseButton1Down:Connect(function()
        dragging = true
        tw(knob, TW.FAST, {Size = UDim2.new(0,17,0,17)})
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and
           inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local p = math.clamp(
            (inp.Position.X - trackBG.AbsolutePosition.X) / trackBG.AbsoluteSize.X, 0, 1)
        setVal(minV + p * (maxV - minV))
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging then
                dragging = false
                tw(knob, TW.FAST, {Size = UDim2.new(0,13,0,13)})
            end
        end
    end)

    return { Frame = row, Set = setVal, Get = function() return value end }
end

-- ════════════════════════════════════════════════════════════
--  COMPONENT — DROPDOWN
--  Expands in-place, pushing elements below downward
--  (AutomaticSize.Y on wrapper achieves the "push" effect)
-- ════════════════════════════════════════════════════════════
local function Dropdown(listParent, cfg)
    cfg = cfg or {}
    local options  = cfg.Options  or {}
    local selected = cfg.Default  or options[1] or ""
    local open     = false
    local cb       = cfg.Callback or function() end
    local ITEM_H   = 30

    -- Wrapper auto-sizes vertically
    local wrap = Frame(listParent, UDim2.new(1,0,0,0), nil, Color3.new(), 1)
    wrap.AutomaticSize = Enum.AutomaticSize.Y

    -- Header
    local header = Frame(wrap, UDim2.new(1,0,0,52), nil, C.modcard1, 0)
    corner(header, L.CORNER_SM)
    stroke(header, C.primary4, 1, 0.7)
    addHover(header, L.CORNER_SM)

    Label(header, cfg.Name or "Dropdown",
        UDim2.new(1,-40,0,12), UDim2.new(0,14,0,8),
        C.settingsSubtext, Enum.Font.Gotham, Enum.TextXAlignment.Left, 10)

    local selLbl = Label(header, selected,
        UDim2.new(1,-44,0,18), UDim2.new(0,14,0,26),
        C.globalText, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 13)

    local arrow = Label(header, "▾",
        UDim2.new(0,22,0,22), UDim2.new(1,-32,0.5,-11),
        C.primary1, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 16)

    -- Panel  (secondary3 bg, secondary7 outline — from Flarial tooltip colors)
    local panel = Frame(wrap, UDim2.new(1,0,0,0), UDim2.new(0,0,0,54),
        C.secondary3, 0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.Visible = false; panel.ZIndex = 20
    corner(panel, L.CORNER_SM)
    stroke(panel, C.secondary7, 1, 0.5)
    pad(panel, 4, 0, 4, 0)

    local pList = Instance.new("UIListLayout")
    pList.SortOrder = Enum.SortOrder.LayoutOrder
    pList.Padding   = UDim.new(0, 0)
    pList.Parent    = panel

    -- Track option state for visual update
    local optMeta = {}

    for i, opt in ipairs(options) do
        local item = Frame(panel, UDim2.new(1,0,0,ITEM_H), nil, Color3.new(), 1)
        item.LayoutOrder = i

        local ih = Frame(item, UDim2.new(1,0,1,0), nil, C.primary4, 1)
        item.MouseEnter:Connect(function() tw(ih, TW.FAST, {BackgroundTransparency=0.82}) end)
        item.MouseLeave:Connect(function() tw(ih, TW.FAST, {BackgroundTransparency=1}) end)

        local dot = Frame(item, UDim2.new(0,5,0,5), UDim2.new(1,-18,0.5,-2),
            C.primary1, opt == selected and 0 or 1)
        corner(dot, L.CORNER_PILL)

        local optLbl = Label(item, opt,
            UDim2.new(1,-30,1,0), UDim2.new(0,12,0,0),
            opt == selected and C.primary1 or C.globalText,
            Enum.Font.Gotham, Enum.TextXAlignment.Left, 12)

        optMeta[i] = {dot = dot, lbl = optLbl}

        local ib = Btn(item, 22)
        ib.MouseButton1Click:Connect(function()
            -- Reset all
            for _, m in ipairs(optMeta) do
                m.dot.BackgroundTransparency = 1
                m.lbl.TextColor3 = C.globalText
            end
            -- Select this
            dot.BackgroundTransparency = 0
            optLbl.TextColor3 = C.primary1
            selected = opt; selLbl.Text = opt
            task.spawn(cb, selected)
            -- Close
            open = false; panel.Visible = false
            tw(arrow, TW.MEDIUM, {Rotation = 0})
            tw(header, TW.MEDIUM, {BackgroundColor3 = C.modcard1})
        end)
    end

    local hBtn = Btn(header, 10)
    hBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            panel.Visible = true
            tw(arrow, TW.MEDIUM, {Rotation = 180})
            tw(header, TW.MEDIUM, {BackgroundColor3 = C.secondary1})
        else
            panel.Visible = false
            tw(arrow, TW.MEDIUM, {Rotation = 0})
            tw(header, TW.MEDIUM, {BackgroundColor3 = C.modcard1})
        end
    end)

    return {
        Frame  = wrap,
        Get    = function() return selected end,
        Set    = function(v) selected = v; selLbl.Text = v; task.spawn(cb, v) end,
    }
end

-- ════════════════════════════════════════════════════════════
--  COMPONENT — KEYBIND SELECTOR
--  Mirrors: ClickGUIElements::KeybindSelector
--  Click badge → enters listening mode ("...") → capture next key
-- ════════════════════════════════════════════════════════════
local function Keybind(listParent, cfg)
    cfg = cfg or {}
    local key       = cfg.Default or Enum.KeyCode.RightShift
    local listening = false
    local conn      = nil
    local cb        = cfg.Callback or function() end

    local row = Frame(listParent, UDim2.new(1,0,0,L.ROW_H), nil, Color3.new(), 1)
    addHover(row)
    Frame(row, UDim2.new(1,-28,0,1), UDim2.new(0,14,1,-1), HEX("2a2020"), 0)

    Label(row, cfg.Name or "Keybind",
        UDim2.new(1,-120,0,16), UDim2.new(0,14,0.5,-8),
        C.globalText, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 13)

    -- Badge box  (secondary2 bg = nav bar color)
    local badge = Frame(row, UDim2.new(0,88,0,26), UDim2.new(1,-100,0.5,-13),
        C.secondary2, 0)
    corner(badge, UDim.new(0,8))
    local badgeStroke = stroke(badge, C.primary1, 1, 0.45)

    local keyLbl = Label(badge, key.Name,
        UDim2.new(1,0,1,0), nil,
        C.primary1, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 11)

    local function setListen(v)
        listening = v
        if v then
            tw(badge, TW.FAST, {BackgroundColor3 = C.secondary4})
            badgeStroke.Transparency = 0
            keyLbl.Text = "..."; keyLbl.TextColor3 = C.settingsSubtext
            if conn then conn:Disconnect() end
            conn = UserInputService.InputBegan:Connect(function(inp, gpe)
                if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                key = inp.KeyCode
                conn:Disconnect(); conn = nil
                setListen(false); task.spawn(cb, key)
            end)
        else
            tw(badge, TW.FAST, {BackgroundColor3 = C.secondary2})
            badgeStroke.Transparency = 0.45
            keyLbl.Text = key.Name; keyLbl.TextColor3 = C.primary1
        end
    end

    local bb = Btn(badge, 10)
    bb.MouseButton1Click:Connect(function() setListen(not listening) end)

    return {
        Frame = row,
        Get   = function() return key end,
        Set   = function(k) key = k; keyLbl.Text = k.Name end,
    }
end

-- ════════════════════════════════════════════════════════════
--  COMPONENT — BUTTON
-- ════════════════════════════════════════════════════════════
local function Button(listParent, cfg)
    cfg = cfg or {}
    local cb = cfg.Callback or function() end

    local row = Frame(listParent, UDim2.new(1,-16,0,36), nil, C.secondary2, 0)
    row.Position = UDim2.new(0,8,0,0)
    corner(row, L.CORNER_SM)
    stroke(row, C.primary1, 1, 0.55)

    local lbl = Label(row, cfg.Name or "Button",
        UDim2.new(1,0,1,0), nil,
        C.globalText, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 13)

    local btn = Btn(row)
    btn.MouseButton1Click:Connect(function()
        tw(row, TW.FAST,   {BackgroundColor3 = C.primary1})
        task.delay(0.14, function()
            tw(row, TW.MEDIUM, {BackgroundColor3 = C.secondary2})
        end)
        task.spawn(cb)
    end)
    btn.MouseEnter:Connect(function() tw(row, TW.FAST, {BackgroundColor3 = C.secondary1}) end)
    btn.MouseLeave:Connect(function() tw(row, TW.FAST, {BackgroundColor3 = C.secondary2}) end)

    return {Frame = row}
end

-- ════════════════════════════════════════════════════════════
--  COMPONENT — COLOR PICKER  (swatch + hex display)
-- ════════════════════════════════════════════════════════════
local function ColorPicker(listParent, cfg)
    cfg = cfg or {}
    local color = cfg.Default or C.primary1
    local cb    = cfg.Callback or function() end

    local row = Frame(listParent, UDim2.new(1,0,0,L.ROW_H), nil, Color3.new(), 1)
    addHover(row)

    Label(row, cfg.Name or "Color",
        UDim2.new(1,-100,0,16), UDim2.new(0,14,0.5,-8),
        C.globalText, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 13)

    local swatch = Frame(row, UDim2.new(0,32,0,22), UDim2.new(1,-46,0.5,-11), color, 0)
    corner(swatch, UDim.new(0,7))
    stroke(swatch, C.primary3, 1, 0.4)

    return {
        Frame = row,
        Get   = function() return color end,
        Set   = function(c3) color = c3; swatch.BackgroundColor3 = c3; task.spawn(cb, c3) end,
    }
end

-- ════════════════════════════════════════════════════════════
--  SECTION  —  labeled group of components
-- ════════════════════════════════════════════════════════════
local Section = {}
Section.__index = Section

function Section.new(parent, title)
    local self  = setmetatable({}, Section)

    -- Auto-sizing wrapper
    local wrap = Frame(parent, UDim2.new(1,-16,0,0), nil, Color3.new(), 1)
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.Position = UDim2.new(0,8,0,0)
    self._wrap = wrap

    -- Section label row
    if title and title ~= "" then
        local hdr = Frame(wrap, UDim2.new(1,0,0,22), nil, Color3.new(), 1)
        Label(hdr, title:upper(),
            UDim2.new(1,-20,1,0), UDim2.new(0,0,0,0),
            C.settingsSubtext, Enum.Font.GothamBold,
            Enum.TextXAlignment.Left, 9)
        Frame(hdr, UDim2.new(1,-14,0,1), UDim2.new(0,0,1,-1), HEX("2a2020"), 0)
    end

    -- Items container
    local list = Frame(wrap, UDim2.new(1,0,0,0), nil, Color3.new(), 1)
    list.AutomaticSize = Enum.AutomaticSize.Y
    vList(list, 5)
    pad(list, 2, 0, 8, 0)
    self._list = list

    -- Stack wrap children vertically
    local outer = Instance.new("UIListLayout")
    outer.SortOrder = Enum.SortOrder.LayoutOrder
    outer.Padding   = UDim.new(0,0)
    outer.Parent = wrap

    return self
end

function Section:CreateToggle(c)      return Toggle(self._list, c)      end
function Section:CreateSlider(c)      return Slider(self._list, c)      end
function Section:CreateDropdown(c)    return Dropdown(self._list, c)    end
function Section:CreateKeybind(c)     return Keybind(self._list, c)     end
function Section:CreateButton(c)      return Button(self._list, c)      end
function Section:CreateColorPicker(c) return ColorPicker(self._list, c) end

-- ════════════════════════════════════════════════════════════
--  MODULE CARD
--  Mirrors ClickGUIElements::ModCard layout exactly:
--    • modcard1 surface  (top, full card)
--    • modcard2 bottom strip
--    • modcard3 icon box  (centered top half)
--    • modNameText color label
--    • Enabled/Disabled colored badge  (modCardEnabled / modCardDisabled)
--    • secondary8 gear button  (bottom-left)
--    • Hover: lerp card size up slightly
-- ════════════════════════════════════════════════════════════
local function ModCard(gridParent, cfg, idx)
    cfg     = cfg or {}
    local enabled  = cfg.Default  or false
    local name     = cfg.Name     or "Module"
    local icon     = cfg.Icon     or "◈"
    local cb       = cfg.Callback   or function() end
    local onGear   = cfg.OnSettings or function() end

    local card = Frame(gridParent, UDim2.new(0,L.CARD_W,0,L.CARD_H), nil, C.modcard1, 0)
    card.LayoutOrder = idx or 1
    corner(card, UDim.new(0,L.CARD_ROUND))

    -- Bottom strip (modcard2)
    local strip = Frame(card, UDim2.new(1,0,0,32), UDim2.new(0,0,1,-32), C.modcard2, 0)
    corner(strip, UDim.new(0,L.CARD_ROUND))

    -- Icon box (modcard3)
    local iconBox = Frame(card, UDim2.new(0,38,0,38), UDim2.new(0.5,-19,0,8), C.modcard3, 0)
    corner(iconBox, UDim.new(0,8))
    local iconLbl = Label(iconBox, icon,
        UDim2.new(1,0,1,0), nil,
        C.modsettings, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 19)
    iconLbl.TextYAlignment = Enum.TextYAlignment.Center

    -- Name label  (modNameText = #8b767a)
    local nameLbl = Label(card, name,
        UDim2.new(1,-8,0,15), UDim2.new(0,4,0,50),
        C.modNameText, Enum.Font.Gotham, Enum.TextXAlignment.Center, 11)

    -- Enabled/Disabled badge
    local badge = Frame(card, UDim2.new(0.68,0,0,22), UDim2.new(0.5,-0.34,1,-28),
        enabled and C.modCardEnabled or C.modCardDisabled, 0)
    corner(badge, UDim.new(0,10))
    local badgeLbl = Label(badge, enabled and "Enabled" or "Disabled",
        UDim2.new(1,0,1,0), nil,
        C.globalText, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 10)
    badgeLbl.TextYAlignment = Enum.TextYAlignment.Center

    -- Gear button (secondary8 bg)
    local gearBox = Frame(card, UDim2.new(0,22,0,22), UDim2.new(0,6,1,-27), C.secondary8, 0)
    corner(gearBox, UDim.new(0,8))
    local gearLbl = Label(gearBox, "⚙",
        UDim2.new(1,0,1,0), nil,
        C.modsettings, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 12)
    gearLbl.TextYAlignment = Enum.TextYAlignment.Center

    -- Hover overlay
    local hover = Frame(card, UDim2.new(1,0,1,0), nil, C.secondary1, 1)
    corner(hover, UDim.new(0,L.CARD_ROUND))

    -- Main click
    local btn = Btn(card)
    btn.MouseEnter:Connect(function()
        tw(card, TW.FAST, {Size = UDim2.new(0,L.CARD_W+5,0,L.CARD_H+5)})
        tw(hover, TW.FAST, {BackgroundTransparency = 0.87})
    end)
    btn.MouseLeave:Connect(function()
        tw(card, TW.FAST, {Size = UDim2.new(0,L.CARD_W,0,L.CARD_H)})
        tw(hover, TW.FAST, {BackgroundTransparency = 1})
    end)
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        tw(badge, TW.MEDIUM, {BackgroundColor3 = enabled and C.modCardEnabled or C.modCardDisabled})
        badgeLbl.Text = enabled and "Enabled" or "Disabled"
        task.spawn(cb, enabled)
    end)

    -- Gear click
    local gBtn = Btn(gearBox, 12)
    gBtn.MouseButton1Click:Connect(function() task.spawn(onGear) end)
    gBtn.MouseEnter:Connect(function() tw(gearBox, TW.FAST, {BackgroundColor3 = C.secondary1}) end)
    gBtn.MouseLeave:Connect(function() tw(gearBox, TW.FAST, {BackgroundColor3 = C.secondary8}) end)

    return {
        Frame    = card,
        SetState = function(v) enabled = v
            badge.BackgroundColor3 = v and C.modCardEnabled or C.modCardDisabled
            badgeLbl.Text = v and "Enabled" or "Disabled"
        end,
        GetState = function() return enabled end,
    }
end

-- ════════════════════════════════════════════════════════════
--  TAB
-- ════════════════════════════════════════════════════════════
local Tab = {}
Tab.__index = Tab

function Tab.new(contentArea, cfg)
    local self = setmetatable({}, Tab)
    cfg = cfg or {}
    self._name      = cfg.Name      or "Tab"
    self._icon      = cfg.Icon      or "◈"
    self._isModules = cfg.IsModules or false
    self._cardIdx   = 0

    self._frame = Frame(contentArea, UDim2.new(1,0,1,0), nil, Color3.new(), 1)
    self._frame.Visible = false

    if self._isModules then
        self._scroll = Scroll(self._frame)
        local gl = Instance.new("UIGridLayout")
        gl.CellSize              = UDim2.new(0,L.CARD_W,0,L.CARD_H)
        gl.CellPaddingrl         = UDim2.new(0,L.CARD_GAP,0,L.CARD_GAP)
        gl.HorizontalAlignment   = Enum.HorizontalAlignment.Center
        gl.SortOrder             = Enum.SortOrder.LayoutOrder
        gl.Parent = self._scroll
        pad(self._scroll, L.CARD_PAD, L.CARD_PAD, L.CARD_PAD, L.CARD_PAD)
    else
        self._scroll = Scroll(self._frame)
        vList(self._scroll, 10)
        pad(self._scroll, 8, 4, 8, 4)
    end
    return self
end

function Tab:CreateSection(title)
    assert(not self._isModules, "Use CreateModCard on module tabs")
    return Section.new(self._scroll, title)
end

function Tab:CreateModCard(cfg)
    assert(self._isModules, "Use CreateSection on settings tabs")
    self._cardIdx += 1
    return ModCard(self._scroll, cfg, self._cardIdx)
end

function Tab:Show()
    self._frame.Visible = true
    self._frame.BackgroundTransparency = 1
    tw(self._frame, TW.FAST, {BackgroundTransparency = 0})
end

function Tab:Hide()
    self._frame.Visible = false
end

-- ════════════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════════════
local Window = {}
Window.__index = Window

function Window.new(cfg)
    local self   = setmetatable({}, Window)
    cfg          = cfg or {}
    self._tabs   = {}
    self._btns   = {}
    self._active = nil
    self._open   = false
    self._blur   = cfg.Blur ~= false

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name           = "FlarialRBX"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder   = 999
    gui.IgnoreGuiInset = true
    local ok = pcall(function()
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
    if not ok then gui.Parent = CoreGui end

    -- Fullscreen tinted overlay (optional)
    self._overlay = Frame(gui, UDim2.new(1,0,1,0), nil, C.secondary3, 0.7)
    self._overlay.Visible = false; self._overlay.ZIndex = 2

    -- ── Main Window ──
    local win = Frame(gui,
        UDim2.new(0,L.WIN_W,0,1),      -- height starts at 1 for open animation
        UDim2.new(0.5,-L.WIN_W/2,0.5,-L.WIN_H/2),
        C.secondary3, 0)
    win.ZIndex = 5; win.ClipsDescendants = true
    corner(win, L.CORNER)
    stroke(win, HEX("3c2a2c"), 1, 0)
    self._win = win

    -- ── Nav Bar (secondary2 = #201a1b) ──
    local nav = Frame(win, UDim2.new(1,-20,0,L.NAV_H), UDim2.new(0,10,0,8),
        C.secondary2, 0)
    corner(nav, UDim.new(0,L.NAV_ROUND))
    self._nav = nav

    -- Logo box (secondary5 bg, flariallogo "F" text)
    local logoBox = Frame(nav, UDim2.new(0,34,0,34), UDim2.new(0,8,0.5,-17), C.secondary5, 0)
    corner(logoBox, UDim.new(0,9))
    local logoTxt = Label(logoBox, "F", UDim2.new(1,0,1,0), nil,
        C.flariallogo, Enum.Font.GothamBlack, Enum.TextXAlignment.Center, 20)
    logoTxt.TextYAlignment = Enum.TextYAlignment.Center

    -- Title
    local titleLbl = Label(nav, cfg.Title or "FlarialRBX",
        UDim2.new(0,110,0,18), UDim2.new(0,48,0,6),
        C.headerText, Enum.Font.GothamBlack, Enum.TextXAlignment.Left, 14)
    Label(nav, cfg.Subtitle or "",
        UDim2.new(0,110,0,13), UDim2.new(0,48,0,26),
        C.settingsSubtext, Enum.Font.Gotham, Enum.TextXAlignment.Left, 10)

    -- Close button
    local xBox = Frame(nav, UDim2.new(0,26,0,26), UDim2.new(1,-34,0.5,-13), C.secondary1, 0)
    corner(xBox, UDim.new(0,7))
    local xLbl = Label(xBox, "✕", UDim2.new(1,0,1,0), nil,
        C.settingsSubtext, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 11)
    xLbl.TextYAlignment = Enum.TextYAlignment.Center
    local xBtn = Btn(xBox)
    xBtn.MouseButton1Click:Connect(function() self:Toggle() end)
    xBtn.MouseEnter:Connect(function()
        tw(xBox, TW.FAST, {BackgroundColor3 = C.primary1})
        tw(xLbl, TW.FAST, {TextColor3 = C.globalText})
    end)
    xBtn.MouseLeave:Connect(function()
        tw(xBox, TW.FAST, {BackgroundColor3 = C.secondary1})
        tw(xLbl, TW.FAST, {TextColor3 = C.settingsSubtext})
    end)

    -- Nav tab buttons container
    local navTabs = Frame(nav, UDim2.new(1,-180,1,-10), UDim2.new(0,172,0,5), Color3.new(), 1)
    hList(navTabs, 5, Enum.VerticalAlignment.Center)
    self._navTabs = navTabs

    -- Content area
    local content = Frame(win, UDim2.new(1,0,1,-(L.NAV_H+22)),
        UDim2.new(0,0,0,L.NAV_H+14), Color3.new(), 1)
    self._content = content

    -- Dragging
    local dragging, dStart, dPos = false, nil, nil
    local dragBtn = Btn(nav, 6)
    dragBtn.MouseButton1Down:Connect(function()
        dragging = true
        dStart = UserInputService:GetMouseLocation()
        dPos   = win.Position
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = UserInputService:GetMouseLocation() - dStart
        win.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X,
                                  dPos.Y.Scale, dPos.Y.Offset+d.Y)
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- Toggle keybind
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == (cfg.ToggleKey or Enum.KeyCode.RightShift) then self:Toggle() end
    end)

    if self._blur then initBlur() end
    return self
end

function Window:_navBtn(tab)
    local active = false
    local btn = Frame(self._navTabs, UDim2.new(0,0,1,-2), nil, C.secondary8, 0)
    btn.AutomaticSize = Enum.AutomaticSize.X
    corner(btn, UDim.new(0,8))

    local inner = Frame(btn, UDim2.new(0,0,1,0), nil, Color3.new(), 1)
    inner.AutomaticSize = Enum.AutomaticSize.X
    hList(inner, 5, Enum.VerticalAlignment.Center)
    pad(inner, 0, 10, 0, 10)

    local ico = Label(inner, tab._icon,
        UDim2.new(0,16,0,16), nil,
        C.globalText, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 13)
    ico.TextYAlignment = Enum.TextYAlignment.Center
    ico.LayoutOrder = 1

    local nl = Label(inner, tab._name,
        UDim2.new(0,0,0,14), nil,
        C.globalText, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 11)
    nl.AutomaticSize = Enum.AutomaticSize.X
    nl.TextYAlignment = Enum.TextYAlignment.Center
    nl.LayoutOrder = 2

    local bb = Btn(btn, 10)
    bb.MouseButton1Click:Connect(function() self:_select(tab) end)
    bb.MouseEnter:Connect(function()
        if not active then tw(btn, TW.FAST, {BackgroundColor3 = C.secondary1}) end
    end)
    bb.MouseLeave:Connect(function()
        if not active then tw(btn, TW.FAST, {BackgroundColor3 = C.secondary8}) end
    end)

    return {
        SetActive = function(v)
            active = v
            tw(btn, TW.MEDIUM, {BackgroundColor3 = v and C.secondary6 or C.secondary8})
        end
    }
end

function Window:_select(tab)
    for t, info in pairs(self._btns) do
        info.SetActive(false); t:Hide()
    end
    tab:Show(); self._active = tab
    local info = self._btns[tab]; if info then info.SetActive(true) end
end

function Window:CreateTab(cfg)
    local tab  = Tab.new(self._content, cfg)
    local nbtn = self:_navBtn(tab)
    self._btns[tab] = nbtn
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then self._active = tab end
    return tab
end

function Window:Toggle()
    self._open = not self._open
    if self._open then
        self._win.Visible = true
        self._overlay.Visible = self._blur
        self._win.Size = UDim2.new(0,L.WIN_W,0,1)
        self._win.BackgroundTransparency = 1
        tw(self._win, TW.OPEN, {
            Size = UDim2.new(0,L.WIN_W,0,L.WIN_H),
            BackgroundTransparency = 0
        })
        if self._blur then setBlur(true) end
        task.delay(0.12, function()
            if self._active then self:_select(self._active) end
        end)
    else
        tw(self._win, TW.OPEN, {
            Size = UDim2.new(0,L.WIN_W,0,1),
            BackgroundTransparency = 1
        })
        if self._blur then setBlur(false) end
        task.delay(0.32, function()
            self._win.Visible  = false
            self._overlay.Visible = false
        end)
    end
end

function Window:Destroy()
    if self._win and self._win.Parent then
        self._win.Parent:Destroy()
    end
    setBlur(false)
end

-- ════════════════════════════════════════════════════════════
--  LIBRARY  —  entry point returned to callers
-- ════════════════════════════════════════════════════════════
local Library = {}
Library.__index = Library
Library._windows = {}
Library.Colors   = C       -- expose for external theming
Library.TweenPresets = TW  -- expose for custom animations

function Library:CreateWindow(cfg)
    local win = Window.new(cfg)
    table.insert(self._windows, win)
    return win
end

function Library:Unload()
    for _, w in ipairs(self._windows) do w:Destroy() end
    self._windows = {}
end

return Library
