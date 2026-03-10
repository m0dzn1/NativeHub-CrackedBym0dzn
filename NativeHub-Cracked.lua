-- The base URL for fetching the actual script
local LUARMOR_API = "https://api.luarmor.net/files/v4/loaders/"

local SupportedGames = {
    [7750955984] = '9c7ff25555ddd4aa46b88d35361ceef7',
    [5166944221] = '2623c74821b882b1e5e529b9078bd30a',
    [5578556129] = 'be2f65b9bda9c9e9aaf37dbbe3d48070',
    [5750914919] = '3c7650df1287b147b62944e27ae8006a',
    [6756890519] = '3c7650df1287b147b62944e27ae8006a',
    [3808223175] = '1e9916162a8c65e9b12fb4fd43fdb2ab',
    [3183403065] = 'e35860641326143c12c12f00dbffade4',
    [7095682825] = 'b8966cedce625dac5d782b13ea5d7a3d',
    [7018190066] = '2d9f941db1fc0f126b147f7a827a1c14',
    [7436755782] = '7c50c2feaad52c53adf8e3a4641ec441',
    [7671049560] = '484102053ba652610bb4d7a1a3d97319',
    [7394964165] = '8e3b839f6051efb67ee848baf3a469c7',
    [9363735110] = '7572da20c48e659fc8d5a30f1121435d',
    [8144728961] = '3efe782ad0d787af1c4acda46447187a'
}

local HARDCODED_KEY = "m0dzn"

local function GetScriptId()
    return SupportedGames[game.GameId] or SupportedGames[game.PlaceId]
end

local function SetupTeleportQueue()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    LocalPlayer.OnTeleport:Connect(function()
        if queue_on_teleport then
            local payload = 'script_key="' .. HARDCODED_KEY .. '";(loadstring or load)(game:HttpGet("https://getnative.cc/script/loader"))()'
            queue_on_teleport(payload)
        end
    end)
end

local function LoadScript(scriptId)
    SetupTeleportQueue()
    getgenv().script_key = HARDCODED_KEY
    local scriptCode = game:HttpGet(LUARMOR_API .. scriptId .. ".lua")
    loadstring(scriptCode)()
end

local function PlayIntroThenLoad(scriptId)
    local CoreGui = cloneref(game:GetService("CoreGui"))
    local TweenService = game:GetService("TweenService")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "M0dznIntro"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = CoreGui

    -- Full screen blur background
    local BlurFrame = Instance.new("Frame")
    BlurFrame.Size = UDim2.new(1, 0, 1, 0)
    BlurFrame.Position = UDim2.new(0, 0, 0, 0)
    BlurFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BlurFrame.BackgroundTransparency = 1
    BlurFrame.BorderSizePixel = 0
    BlurFrame.ZIndex = 10
    BlurFrame.Parent = ScreenGui

    -- Blur effect
    local BlurEffect = Instance.new("BlurEffect")
    BlurEffect.Size = 0
    BlurEffect.Parent = game:GetService("Lighting")

    -- Colored "m0dzn" overlay just for the red part on KeyLabel
    -- We'll use RichText instead
    KeyLabel.RichText = true
    KeyLabel.Text = 'key: <font color="rgb(255,255,255)">m0dzn</font>'

    -- "Cracked By " + red "m0dzn"
    local CrackedLabel = Instance.new("TextLabel")
    CrackedLabel.Size = UDim2.new(1, 0, 0, 50)
    CrackedLabel.Position = UDim2.new(0, 0, 0.52, 0)
    CrackedLabel.BackgroundTransparency = 1
    CrackedLabel.RichText = true
    CrackedLabel.Text = 'Cracked By <font color="rgb(220,30,30)">m0dzn</font>'
    CrackedLabel.Font = Enum.Font.GothamBold
    CrackedLabel.TextSize = 28
    CrackedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    CrackedLabel.TextTransparency = 1
    CrackedLabel.ZIndex = 11
    CrackedLabel.Parent = ScreenGui

    local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenInfoSlow = TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- Fade IN
    TweenService:Create(BlurFrame, tweenInfo, {BackgroundTransparency = 0.3}):Play()
    TweenService:Create(BlurEffect, tweenInfo, {Size = 18}):Play()
    TweenService:Create(KeyLabel, tweenInfo, {TextTransparency = 0}):Play()

    task.wait(0.6)
    TweenService:Create(CrackedLabel, tweenInfo, {TextTransparency = 0}):Play()

    task.wait(2.2)

    -- Fade OUT
    TweenService:Create(BlurFrame, tweenInfoSlow, {BackgroundTransparency = 1}):Play()
    TweenService:Create(BlurEffect, tweenInfoSlow, {Size = 0}):Play()
    TweenService:Create(KeyLabel, tweenInfoSlow, {TextTransparency = 1}):Play()
    TweenService:Create(CrackedLabel, tweenInfoSlow, {TextTransparency = 1}):Play()

    task.wait(1.9)

    -- Cleanup
    ScreenGui:Destroy()
    BlurEffect:Destroy()

    -- Now run the actual script
    LoadScript(scriptId)
end

local function Initialize()
    local targetScriptId = GetScriptId()
    if not targetScriptId then return end

    -- If valid key already set globally, skip intro and load instantly
    if getgenv().script_key == HARDCODED_KEY then
        LoadScript(targetScriptId)
        return
    end

    getgenv().script_key = HARDCODED_KEY
    PlayIntroThenLoad(targetScriptId)
end

-- Prevent multiple executions
if getgenv().initialized then
    warn("NATIVE IS ALREADY INITIALIZED")
    return
end
getgenv().initialized = true

repeat task.wait() until game:IsLoaded()
Initialize()
