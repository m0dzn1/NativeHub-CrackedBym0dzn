-- ╔══════════════════════════════════════════════════════════════╗
-- ║  FlarialRBX — Example Script                                 ║
-- ║  Place as a LocalScript under StarterPlayerScripts           ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 1. Require the library from ReplicatedStorage
local FlarialRBX = require(game.ReplicatedStorage:WaitForChild("FlarialRBX"))

-- ─────────────────────────────────────────────────────────────
--  CREATE WINDOW
--  ToggleKey = the key that shows/hides the entire menu
--  Blur = true  → BlurEffect in Lighting animates when menu opens
-- ─────────────────────────────────────────────────────────────
local Window = FlarialRBX:CreateWindow({
    Title      = "FlarialRBX",
    Subtitle   = "v1.0.0 • Open Source",
    ToggleKey  = Enum.KeyCode.RightShift,
    Blur       = true,
})

-- ─────────────────────────────────────────────────────────────
--  MODULE CARDS TAB  (the main grid — mirrors Flarial's Modules page)
--  IsModules = true  →  uses UIGridLayout instead of UIListLayout
-- ─────────────────────────────────────────────────────────────
local ModulesTab = Window:CreateTab({
    Name      = "Modules",
    Icon      = "⊞",
    IsModules = true,
})

-- Each CreateModCard call adds one card to the grid
local reachCard = ModulesTab:CreateModCard({
    Name     = "Reach",
    Icon     = "⚔",
    Default  = false,
    Callback = function(enabled)
        print("[Reach] enabled:", enabled)
    end,
    OnSettings = function()
        -- Switch to the Reach settings tab or open a sub-menu
        print("[Reach] settings clicked")
    end,
})

ModulesTab:CreateModCard({
    Name     = "CPS",
    Icon     = "🖱",
    Default  = true,
    Callback = function(enabled) print("[CPS]", enabled) end,
})

ModulesTab:CreateModCard({
    Name     = "ClickGUI",
    Icon     = "◈",
    Default  = true,
    Callback = function(enabled) print("[ClickGUI]", enabled) end,
})

ModulesTab:CreateModCard({
    Name     = "FPS",
    Icon     = "📊",
    Default  = true,
    Callback = function(enabled) print("[FPS]", enabled) end,
})

ModulesTab:CreateModCard({
    Name     = "IP Display",
    Icon     = "🌐",
    Default  = true,
    Callback = function(enabled) print("[IP Display]", enabled) end,
})

ModulesTab:CreateModCard({
    Name     = "Motion Blur",
    Icon     = "💨",
    Default  = false,
    Callback = function(enabled) print("[Motion Blur]", enabled) end,
})

ModulesTab:CreateModCard({
    Name     = "Zoom",
    Icon     = "🔍",
    Default  = false,
    Callback = function(enabled) print("[Zoom]", enabled) end,
})

ModulesTab:CreateModCard({
    Name     = "Deepfry",
    Icon     = "🍟",
    Default  = false,
    Callback = function(enabled) print("[Deepfry]", enabled) end,
})

ModulesTab:CreateModCard({
    Name     = "PatarHD",
    Icon     = "🎨",
    Default  = false,
    Callback = function(enabled) print("[PatarHD]", enabled) end,
})

-- ─────────────────────────────────────────────────────────────
--  COMBAT SETTINGS TAB
-- ─────────────────────────────────────────────────────────────
local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "⚔" })

local ReachSec = CombatTab:CreateSection("Reach")

ReachSec:CreateToggle({
    Name     = "Enable Reach",
    Default  = false,
    Callback = function(v)
        print("Reach enabled:", v)
    end,
})

ReachSec:CreateSlider({
    Name     = "Attack Distance",
    Min      = 1,
    Max      = 6,
    Default  = 3.5,
    Decimals = 1,
    Suffix   = " blocks",
    Callback = function(v)
        print("Reach distance:", v)
    end,
})

ReachSec:CreateSlider({
    Name     = "Defense Distance",
    Min      = 1,
    Max      = 6,
    Default  = 3.0,
    Decimals = 1,
    Suffix   = " blocks",
    Callback = function(v) end,
})

ReachSec:CreateDropdown({
    Name     = "Mode",
    Options  = { "Normal", "Packet", "Bypass", "Silent" },
    Default  = "Normal",
    Callback = function(v)
        print("Reach mode:", v)
    end,
})

ReachSec:CreateKeybind({
    Name     = "Toggle Reach",
    Default  = Enum.KeyCode.V,
    Callback = function(key)
        print("Reach keybind set to:", key.Name)
    end,
})

local CPSSec = CombatTab:CreateSection("CPS Limiter")

CPSSec:CreateToggle({
    Name    = "Enable CPS Limit",
    Default = false,
    Callback = function(v) end,
})

CPSSec:CreateSlider({
    Name     = "Min CPS",
    Min      = 1,
    Max      = 20,
    Default  = 8,
    Decimals = 0,
    Callback = function(v) print("Min CPS:", v) end,
})

CPSSec:CreateSlider({
    Name     = "Max CPS",
    Min      = 1,
    Max      = 20,
    Default  = 14,
    Decimals = 0,
    Callback = function(v) print("Max CPS:", v) end,
})

-- ─────────────────────────────────────────────────────────────
--  VISUALS TAB
-- ─────────────────────────────────────────────────────────────
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "🎨" })

local FpsSec = VisualsTab:CreateSection("FPS Counter")

FpsSec:CreateToggle({
    Name    = "Show FPS",
    Default = true,
    Callback = function(v) end,
})

FpsSec:CreateColorPicker({
    Name    = "FPS Color",
    Default = Color3.fromRGB(255, 35, 58),  -- primary1
    Callback = function(c) print("FPS color changed") end,
})

FpsSec:CreateDropdown({
    Name    = "Position",
    Options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" },
    Default = "Top Right",
    Callback = function(v) end,
})

local MotionBlurSec = VisualsTab:CreateSection("Motion Blur")

MotionBlurSec:CreateToggle({
    Name    = "Enable Motion Blur",
    Default = false,
    Callback = function(v) end,
})

MotionBlurSec:CreateSlider({
    Name     = "Blur Intensity",
    Min      = 0,
    Max      = 100,
    Default  = 50,
    Decimals = 0,
    Suffix   = "%",
    Callback = function(v) end,
})

-- ─────────────────────────────────────────────────────────────
--  SETTINGS TAB  (mirrors Flarial's ClickGUI settings page)
-- ─────────────────────────────────────────────────────────────
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "⚙" })

local GuiSec = SettingsTab:CreateSection("GUI")

GuiSec:CreateToggle({
    Name    = "Blur Background",
    Default = true,
    Callback = function(v) end,
})

GuiSec:CreateSlider({
    Name     = "Blur Intensity",
    Min      = 0,
    Max      = 30,
    Default  = 14,
    Decimals = 0,
    Callback = function(v) end,
})

GuiSec:CreateDropdown({
    Name    = "Theme",
    Options = { "Flarial Red", "Custom" },
    Default = "Flarial Red",
    Callback = function(v) end,
})

GuiSec:CreateKeybind({
    Name    = "Open Menu",
    Default = Enum.KeyCode.RightShift,
    Callback = function(k) end,
})

local MiscSec = SettingsTab:CreateSection("Misc")

MiscSec:CreateButton({
    Name     = "Reset All Settings",
    Callback = function()
        print("Resetting all settings...")
    end,
})

MiscSec:CreateButton({
    Name     = "Save Config",
    Callback = function()
        print("Config saved!")
    end,
})

-- ─────────────────────────────────────────────────────────────
--  OPEN THE MENU ON LOAD  (remove if you want key-only)
-- ─────────────────────────────────────────────────────────────
task.delay(0.5, function()
    Window:Toggle()
end)

--[[
  NOTES:
    • To programmatically toggle a module card state:
        reachCard.SetState(true)   -- enable
        reachCard.SetState(false)  -- disable
        print(reachCard.GetState()) -- read current state

    • To change a toggle from code:
        local myToggle = ReachSec:CreateToggle({ Name="Test", Default=false })
        myToggle.Set(true)
        print(myToggle.Get())

    • To unload the entire library (e.g., on script end):
        FlarialRBX:Unload()

    • The color palette is accessible via:
        FlarialRBX.Colors.primary1  -- returns Color3
]]
