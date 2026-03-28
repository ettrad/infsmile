-- Infectious Smile | Rayfield UI Script
-- Standalone | Loadstring Compatible

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ==============================
--         CONFIG
-- ==============================
local Config = {
    AutoFarm = false,
    AutoWin = false,
    ESP = false,
    InfectedESP = false,
    SpeedHack = false,
    SpeedValue = 25,
    Noclip = false,
    InfiniteJump = false,
    AutoHide = false,
    FlyEnabled = false,
    FlySpeed = 50,
}

-- ==============================
--         HELPERS
-- ==============================
local function Notify(title, content, duration)
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3,
        Image = 4483362458,
    })
end

local function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ==============================
--         ESP MODULE
-- ==============================
local ESPObjects = {}

local function CreateESP(player, color)
    if ESPObjects[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color or Color3.fromRGB(255, 80, 80)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    ESPObjects[player] = highlight
    if player.Character then
        highlight.Adornee = player.Character
        highlight.Parent = player.Character
    end
    player.CharacterAdded:Connect(function(char)
        highlight.Adornee = char
        highlight.Parent = char
    end)
end

local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

local function ClearAllESP()
    for player, _ in pairs(ESPObjects) do
        RemoveESP(player)
    end
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Config.ESP then
                -- Determine if infected (basic check via team or tag)
                local isInfected = false
                if player.Team then
                    isInfected = tostring(player.Team.Name):lower():find("infect") ~= nil
                end
                if Config.InfectedESP and isInfected then
                    CreateESP(player, Color3.fromRGB(255, 50, 50))
                elseif Config.ESP and not Config.InfectedESP then
                    CreateESP(player, Color3.fromRGB(80, 200, 255))
                elseif not Config.ESP then
                    RemoveESP(player)
                end
            else
                RemoveESP(player)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    if Config.ESP then UpdateESP() end
end)
Players.PlayerRemoving:Connect(function(p)
    RemoveESP(p)
end)

-- ==============================
--         NOCLIP
-- ==============================
RunService.Stepped:Connect(function()
    if Config.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ==============================
--         INFINITE JUMP
-- ==============================
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ==============================
--         SPEED HACK
-- ==============================
RunService.Heartbeat:Connect(function()
    if Config.SpeedHack then
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = Config.SpeedValue end
    end
end)

-- ==============================
--         FLY
-- ==============================
local flyBody = nil

local function EnableFly()
    local hrp = GetHRP()
    if not hrp then return end
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 9e4
    bg.Parent = hrp
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = hrp
    flyBody = {bg = bg, bv = bv}
end

local function DisableFly()
    if flyBody then
        flyBody.bg:Destroy()
        flyBody.bv:Destroy()
        flyBody = nil
    end
end

RunService.Heartbeat:Connect(function()
    if Config.FlyEnabled and flyBody then
        local hrp = GetHRP()
        if not hrp then return end
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        flyBody.bv.Velocity = dir.Magnitude > 0 and dir.Unit * Config.FlySpeed or Vector3.zero
        flyBody.bg.CFrame = cam.CFrame
    end
end)

-- ==============================
--         AUTO HIDE (Survivor)
-- ==============================
local function TryHide()
    if not Config.AutoHide then return end
    -- Attempts to move player into a hidden spot (under map objects)
    local hrp = GetHRP()
    if not hrp then return end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    -- Simple hide attempt: move under nearest part
    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -50, 0), params)
    if result then
        hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 0.5, 0))
    end
end

-- ==============================
--       TELEPORT TO LOBBY
-- ==============================
local function TeleportToSpawn()
    local spawn = workspace:FindFirstChild("Spawn") or workspace:FindFirstChildOfClass("SpawnLocation")
    local hrp = GetHRP()
    if hrp and spawn then
        hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
        Notify("Teleport", "Teleported to spawn!", 3)
    else
        Notify("Teleport", "Could not find spawn location.", 3)
    end
end

local function TeleportToSafeZone()
    -- Looks for parts named SafeZone or similar
    local safe = workspace:FindFirstChild("SafeZone") 
        or workspace:FindFirstChild("Safe") 
        or workspace:FindFirstChild("Lobby")
    local hrp = GetHRP()
    if hrp and safe then
        local pos = safe:IsA("BasePart") and safe.Position or safe:FindFirstChildOfClass("BasePart") and safe:FindFirstChildOfClass("BasePart").Position
        if pos then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
            Notify("Teleport", "Teleported to Safe Zone!", 3)
            return
        end
    end
    Notify("Teleport", "Safe Zone not found. Try manual TP.", 3)
end

-- ==============================
--       INFECT TOOL
-- ==============================
local SelectedVictim = nil

local function FindWhiteParts()
    local results = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local c = obj.Color
            -- Match parts that are white or near-white and not a player character
            if c.R > 0.85 and c.G > 0.85 and c.B > 0.85 and obj.Size.Magnitude > 2 then
                local isPlayerPart = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and obj:IsDescendantOf(p.Character) then
                        isPlayerPart = true
                        break
                    end
                end
                if not isPlayerPart then
                    table.insert(results, obj)
                end
            end
        end
    end
    return results
end

local function GetPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

local function TeleportToPlayer(name)
    local target = Players:FindFirstChild(name)
    if not target or not target.Character then
        Notify("Error", "Player not found or has no character.", 3)
        return false
    end
    local hrp = GetHRP()
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if hrp and targetHRP then
        hrp.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        return true
    end
    return false
end

local function GrabAndInfect(name)
    local target = Players:FindFirstChild(name)
    if not target or not target.Character then
        Notify("Infect", "Target not found.", 3)
        return
    end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local hrp = GetHRP()
    if not hrp or not targetHRP then
        Notify("Infect", "Missing HumanoidRootPart.", 3)
        return
    end

    -- Step 1: TP to victim
    hrp.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
    Notify("Infect Step 1", "Teleported to " .. name, 2)
    task.wait(0.3)

    -- Step 2: Find white infect parts
    local parts = FindWhiteParts()
    if #parts == 0 then
        Notify("Infect", "No white infect parts found in workspace!", 4)
        return
    end

    -- Step 3: Pick a random white part
    local chosen = parts[math.random(1, #parts)]
    local infectPos = chosen.Position

    -- Step 4: Move victim to white part position by teleporting us both there
    -- We anchor victim near the part, then teleport ourselves on top
    targetHRP.CFrame = CFrame.new(infectPos + Vector3.new(0, 3, 0))
    task.wait(0.1)
    hrp.CFrame = CFrame.new(infectPos + Vector3.new(0, 5, 0))

    Notify("Infect Step 2", name .. " moved to infect part!", 3)
end

-- ==============================
--       RAYFIELD UI SETUP
-- ==============================
local Window = Rayfield:CreateWindow({
    Name = "Infectious Smile | Hub",
    Icon = 0,
    LoadingTitle = "Infectious Smile Hub",
    LoadingSubtitle = "by gandr57",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "InfectiousSmileHub",
        FileName = "Config",
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = true,
    KeySettings = {
        Title = "Infectious Smile Hub",
        Subtitle = "Key System",
        Note = "The key is provided by gandr57.",
        FileName = "ISHubKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"6790god"},
    },
})

-- ==============================
--         TAB: PLAYER
-- ==============================
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(val)
        Config.SpeedHack = val
        if not val then
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
        Notify("Speed Hack", val and "Enabled" or "Disabled", 2)
    end,
})

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = 25,
    Flag = "SpeedSlider",
    Callback = function(val)
        Config.SpeedValue = val
        if Config.SpeedHack then
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = val end
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(val)
        Config.InfiniteJump = val
        Notify("Infinite Jump", val and "Enabled" or "Disabled", 2)
    end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(val)
        Config.Noclip = val
        Notify("Noclip", val and "Enabled" or "Disabled", 2)
    end,
})

PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(val)
        Config.FlyEnabled = val
        if val then EnableFly() else DisableFly() end
        Notify("Fly", val and "Enabled — WASD + Space/Ctrl" or "Disabled", 3)
    end,
})

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(val)
        Config.FlySpeed = val
    end,
})

PlayerTab:CreateSection("Teleport")

PlayerTab:CreateButton({
    Name = "Teleport to Spawn",
    Callback = function()
        TeleportToSpawn()
    end,
})

PlayerTab:CreateButton({
    Name = "Teleport to Safe Zone",
    Callback = function()
        TeleportToSafeZone()
    end,
})

-- ==============================
--       TAB: SURVIVOR
-- ==============================
local SurvivorTab = Window:CreateTab("Survivor", 4483362458)

SurvivorTab:CreateSection("Survival Assist")

SurvivorTab:CreateToggle({
    Name = "Auto Hide (Experimental)",
    CurrentValue = false,
    Flag = "AutoHide",
    Callback = function(val)
        Config.AutoHide = val
        Notify("Auto Hide", val and "Active — moves you under objects" or "Disabled", 3)
        if val then TryHide() end
    end,
})

SurvivorTab:CreateButton({
    Name = "Manual Hide (Trigger Once)",
    Callback = function()
        TryHide()
        Notify("Hide", "Attempted to hide under nearest surface.", 3)
    end,
})

SurvivorTab:CreateSection("Anti-Infected")

SurvivorTab:CreateToggle({
    Name = "ESP — All Players",
    CurrentValue = false,
    Flag = "ESPAll",
    Callback = function(val)
        Config.ESP = val
        UpdateESP()
        if not val then ClearAllESP() end
        Notify("ESP", val and "All Players highlighted" or "Disabled", 2)
    end,
})

SurvivorTab:CreateToggle({
    Name = "ESP — Infected Only",
    CurrentValue = false,
    Flag = "ESPInfected",
    Callback = function(val)
        Config.InfectedESP = val
        Config.ESP = val
        UpdateESP()
        if not val then ClearAllESP() end
        Notify("Infected ESP", val and "Infected players highlighted red" or "Disabled", 2)
    end,
})

-- ==============================
--       TAB: INFECT
-- ==============================
local InfectTab = Window:CreateTab("Infect", 4483362458)

InfectTab:CreateSection("Target Selection")

local playerNames = GetPlayerNames()
if #playerNames == 0 then playerNames = {"No players found"} end

InfectTab:CreateDropdown({
    Name = "Select Victim",
    Options = playerNames,
    CurrentOption = {playerNames[1]},
    Flag = "VictimDropdown",
    Callback = function(val)
        local ok, err = pcall(function()
            if val and val[1] and val[1] ~= "No players found" then
                SelectedVictim = val[1]
                Notify("Target", "Selected: " .. tostring(SelectedVictim), 2)
            else
                Notify("Error", "Invalid selection. Refresh list.", 3)
            end
        end)
        if not ok then
            Notify("Error", "Dropdown error: " .. tostring(err), 3)
        end
    end,
})

InfectTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        local ok, err = pcall(function()
            local names = GetPlayerNames()
            local list = table.concat(names, ", ")
            Notify("Players Online", list ~= "" and list or "No other players found", 4)
        end)
        if not ok then Notify("Error", tostring(err), 3) end
    end,
})

InfectTab:CreateSection("Infect Actions")

InfectTab:CreateButton({
    Name = "TP to Victim",
    Callback = function()
        if not SelectedVictim or SelectedVictim == "" then
            Notify("Error", "Select a victim first!", 3)
            return
        end
        local ok = TeleportToPlayer(SelectedVictim)
        if ok then
            Notify("Teleport", "Teleported to " .. SelectedVictim, 3)
        end
    end,
})

InfectTab:CreateButton({
    Name = "Grab & Send to White Part",
    Callback = function()
        if not SelectedVictim or SelectedVictim == "" then
            Notify("Error", "Select a victim first!", 3)
            return
        end
        GrabAndInfect(SelectedVictim)
    end,
})

InfectTab:CreateButton({
    Name = "Auto Infect (TP + Grab + Send)",
    Callback = function()
        if not SelectedVictim or SelectedVictim == "" then
            Notify("Error", "Select a victim in the dropdown first!", 3)
            return
        end
        Notify("Auto Infect", "Starting on " .. SelectedVictim .. "...", 3)
        task.spawn(function()
            GrabAndInfect(SelectedVictim)
        end)
    end,
})

InfectTab:CreateSection("Info")
InfectTab:CreateLabel("White parts are auto-detected by color.")
InfectTab:CreateLabel("Victim is moved directly onto the part.")

-- ==============================
--       TAB: VISUAL
-- ==============================
local VisualTab = Window:CreateTab("Visual", 4483362458)

VisualTab:CreateSection("Camera")

VisualTab:CreateSlider({
    Name = "Field of View",
    Range = {70, 120},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 70,
    Flag = "FOV",
    Callback = function(val)
        workspace.CurrentCamera.FieldOfView = val
    end,
})

VisualTab:CreateSection("Lighting")

VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(val)
        local lighting = game:GetService("Lighting")
        if val then
            lighting.Brightness = 2
            lighting.ClockTime = 14
            lighting.FogEnd = 100000
            lighting.GlobalShadows = false
            lighting.Ambient = Color3.fromRGB(255, 255, 255)
        else
            lighting.Brightness = 1
            lighting.ClockTime = 14
            lighting.FogEnd = 100000
            lighting.GlobalShadows = true
            lighting.Ambient = Color3.fromRGB(127, 127, 127)
        end
        Notify("Fullbright", val and "Enabled" or "Disabled", 2)
    end,
})

-- ==============================
--       TAB: MISC
-- ==============================
local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateSection("Game")

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscTab:CreateButton({
    Name = "Leave Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscTab:CreateSection("UI")

MiscTab:CreateKeybind({
    Name = "Toggle UI Visibility",
    CurrentKeybind = "RightShift",
    HoldToInteract = false,
    Flag = "UIKeybind",
    Callback = function()
        Rayfield:ToggleVisibility()
    end,
})

MiscTab:CreateSection("Credits")

MiscTab:CreateLabel("Infectious Smile Hub | Rayfield UI")
MiscTab:CreateLabel("Script by: gandr57")
MiscTab:CreateLabel("Toggle UI: Right Shift")

-- ==============================
--       INIT
-- ==============================
Rayfield:LoadConfiguration()

Notify(
    "Infectious Smile Hub",
    "Script by gandr57 loaded! Toggle UI with RightShift.",
    5
)

-- Periodic ESP refresh
task.spawn(function()
    while true do
        task.wait(2)
        if Config.ESP or Config.InfectedESP then
            UpdateESP()
        end
    end
end)
