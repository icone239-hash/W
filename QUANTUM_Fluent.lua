--[[
    QUANTUM - Fluent UI Library
    Website: QuantumRise.gg
]]

local player = game:GetService("Players").LocalPlayer or game.Players.LocalPlayer
local UIS    = game:GetService("UserInputService")
local rs     = game:GetService("RunService")

-- ══════════════════════════════════════════════
-- ANTICHEAT BYPASS
-- ══════════════════════════════════════════════
local function removeAnticheat()
    if player and player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("LocalScript") and string.lower(v.Name):find("anticheat") then
                v:Destroy()
            end
        end
    end
end
player.CharacterAdded:Connect(removeAnticheat)
removeAnticheat()

-- ══════════════════════════════════════════════
-- FLUENT UI
-- ══════════════════════════════════════════════
local Fluent         = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager    = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title      = "QUANTUM",
    SubTitle   = "QuantumRise.gg",
    TabWidth   = 160,
    Size       = UDim2.fromOffset(560, 420),
    Acrylic    = true,
    Theme      = "Darker",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Catching = Window:AddTab({ Title = "Catching",  Icon = "target"   }),
    Movement = Window:AddTab({ Title = "Movement",  Icon = "zap"      }),
    Settings = Window:AddTab({ Title = "Settings",  Icon = "settings" }),
}

-- ══════════════════════════════════════════════
-- SETTINGS
-- ══════════════════════════════════════════════
local Settings = {
    Magnet       = false,
    MagnetRange  = 2.2,
    VisualizeMags = false,
    VisualShape  = "Sphere",
    AutoTuck     = false,
    AutoTuckSpeed = "Instant",
}

local PlayerSettings = {
    SpeedEnabled = false,
    SpeedValue   = 16,
    JumpEnabled  = false,
    JumpValue    = 60.5,
    InfJump      = false,
}

-- ══════════════════════════════════════════════
-- JUMP HELPER
-- ══════════════════════════════════════════════
local function JumpPowerToJumpHeight(jp)
    jp = tonumber(jp) or 50
    return (jp * jp) / (2 * workspace.Gravity)
end

local function ApplyJump(hum, jp)
    if not hum then return end
    hum.UseJumpPower = false
    hum.JumpHeight   = JumpPowerToJumpHeight(jp)
end

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if PlayerSettings.InfJump then
        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ══════════════════════════════════════════════
-- MAGNET ENGINE
-- ══════════════════════════════════════════════
local activeBalls = {}
local hitboxes    = {}

local function isVisual(obj)
    return obj and (obj.Name == "QuantumMagnetVisual" or obj:GetAttribute("QuantumVisual") == true)
end

local function isBall(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    if isVisual(obj) then return false end
    if obj:FindFirstAncestorOfClass("Accessory") or obj:FindFirstAncestorOfClass("Accoutrement") then return false end

    local folder = workspace:FindFirstChild("Footballs")
    if folder and obj:IsDescendantOf(folder) then return true end

    local n = string.lower(obj.Name)
    if n == "football" or n == "ball" then return true end

    if obj.Parent and obj.Parent:IsA("Tool") then
        local pn = string.lower(obj.Parent.Name)
        if pn:find("football") or pn == "ball" then return true end
    end

    return false
end

workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if isBall(obj) then activeBalls[obj] = true end
    end)
end)

workspace.DescendantRemoving:Connect(function(obj)
    if activeBalls[obj] then
        activeBalls[obj] = nil
        if hitboxes[obj] then
            pcall(function() hitboxes[obj]:Destroy() end)
            hitboxes[obj] = nil
        end
    end
end)

for _, v in pairs(workspace:GetDescendants()) do
    if isBall(v) then activeBalls[v] = true end
end

local touching = {}

local function getArmsAndRoot(char)
    local l = char:FindFirstChild("Left Arm")   or char:FindFirstChild("LeftHand")  or char:FindFirstChild("LeftLowerArm")
    local r = char:FindFirstChild("Right Arm")  or char:FindFirstChild("RightHand") or char:FindFirstChild("RightLowerArm")
    local root = char:FindFirstChild("HumanoidRootPart")
    return l, r, root
end

local function magBall(ball)
    if touching[ball] then return end
    touching[ball] = true
    task.spawn(function()
        while Settings.Magnet and ball.Parent and player.Character do
            local l, r, root = getArmsAndRoot(player.Character)
            if not root or not l or not r then break end

            local dist = math.min(
                (l.Position    - ball.Position).Magnitude,
                (r.Position    - ball.Position).Magnitude,
                (root.Position - ball.Position).Magnitude
            )

            if dist > Settings.MagnetRange then task.wait() continue end

            for _ = 1, 8 do
                firetouchinterest(l,    ball, 0)
                firetouchinterest(r,    ball, 0)
                firetouchinterest(root, ball, 0)
                firetouchinterest(l,    ball, 1)
                firetouchinterest(r,    ball, 1)
                firetouchinterest(root, ball, 1)
            end
            task.wait()
        end
        touching[ball] = nil
    end)
end

local visualFolder = nil
local function getVisualFolder()
    if visualFolder and visualFolder.Parent then return visualFolder end
    visualFolder = workspace:FindFirstChild("QuantumMagVisuals")
    if not visualFolder then
        visualFolder = Instance.new("Folder")
        visualFolder.Name = "QuantumMagVisuals"
        visualFolder.Parent = workspace
    end
    return visualFolder
end

local function updateHitbox(ball)
    if not ball or not ball.Parent then return end
    local hb = hitboxes[ball]
    if not hb or not hb.Parent then
        hb = Instance.new("Part")
        hb.Name = "QuantumMagnetVisual"
        hb:SetAttribute("QuantumVisual", true)
        hb.Anchored       = true
        hb.CanCollide     = false
        hb.CanTouch       = false
        hb.CanQuery       = false
        hb.CastShadow     = false
        hb.Massless       = true
        hb.Material       = Enum.Material.ForceField
        hb.Color          = Color3.fromRGB(235, 35, 45)
        hb.Transparency   = 0.45
        hb.Parent         = getVisualFolder()
        hitboxes[ball]    = hb
    end
    local d = math.max(Settings.MagnetRange * 2, 1)
    local shape = Enum.PartType.Ball
    if Settings.VisualShape == "Box"      then shape = Enum.PartType.Block    end
    if Settings.VisualShape == "Cylinder" then shape = Enum.PartType.Cylinder end
    if hb.Shape ~= shape then hb.Shape = shape end
    hb.Size   = Vector3.new(d, d, d)
    hb.CFrame = ball.CFrame
end

local function clearHitboxes()
    for ball, hb in pairs(hitboxes) do
        pcall(function() hb:Destroy() end)
        hitboxes[ball] = nil
    end
end

-- Visual sync heartbeat
local visualConn = nil
local function startVisuals()
    if visualConn then return end
    visualConn = rs.Heartbeat:Connect(function()
        if not Settings.VisualizeMags then return end
        for ball in pairs(activeBalls) do
            if ball.Parent then updateHitbox(ball) end
        end
        for ball, hb in pairs(hitboxes) do
            if not activeBalls[ball] or not ball.Parent then
                pcall(function() hb:Destroy() end)
                hitboxes[ball] = nil
            end
        end
    end)
end
local function stopVisuals()
    if visualConn then visualConn:Disconnect(); visualConn = nil end
    clearHitboxes()
end

-- ══════════════════════════════════════════════
-- AUTO TUCK ENGINE
-- ══════════════════════════════════════════════
local tuckEvent = nil
pcall(function()
    tuckEvent = game:GetService("ReplicatedStorage")
        :WaitForChild("GamePackages", 5)
        :WaitForChild("Knit", 5)
        :WaitForChild("Services", 5)
        :WaitForChild("FootballService", 5)
        :WaitForChild("RE", 5)
        :WaitForChild("Event", 5)
end)

local tucked     = false
local missingSince = nil

local function checkFootball()
    local char = player.Character or workspace:FindFirstChild(player.Name)
    if not char then return end
    local football = char:FindFirstChild("Football", true)
    if football then
        missingSince = nil
        if not tucked then
            tucked = true
            local delayTime = 0
            if Settings.AutoTuckSpeed == "Smooth"  then delayTime = 0.1 end
            if Settings.AutoTuckSpeed == "Delayed" then delayTime = 0.3 end
            task.spawn(function()
                if delayTime > 0 then task.wait(delayTime) end
                if tuckEvent then
                    tuckEvent:FireServer("Tuck")
                else
                    pcall(function()
                        game:GetService("ReplicatedStorage").GamePackages.Knit.Services.FootballService.RE.Event:FireServer("Tuck")
                    end)
                end
            end)
        end
    else
        if not missingSince then missingSince = os.clock() end
        if os.clock() - missingSince >= 0.3 then tucked = false end
    end
end

task.spawn(function()
    while task.wait(0.03) do
        if Settings.AutoTuck then checkFootball()
        else tucked = false; missingSince = nil end
    end
end)

-- ══════════════════════════════════════════════
-- RMB MOUSE LOCK ENGINE
-- ══════════════════════════════════════════════
local rmbHeld    = false
local rmbEnabled = false

local function syncMouse()
    if not rmbEnabled then return end
    if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then return end
    local want = rmbHeld and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
    if UIS.MouseBehavior ~= want then UIS.MouseBehavior = want end
end

UIS.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then rmbHeld = true;  syncMouse() end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then rmbHeld = false; syncMouse() end
end)
UIS:GetPropertyChangedSignal("MouseBehavior"):Connect(function() task.defer(syncMouse) end)

-- ══════════════════════════════════════════════
-- HUMANOID DEFAULTS + PROPERTY LOCK
-- ══════════════════════════════════════════════
local defaultWS, defaultJH, defaultJP, defaultUseJP = nil, nil, nil, nil

local function lockHumanoid(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 4)
    if not hum then return end

    if not defaultWS   or defaultWS  == 0 then defaultWS   = hum.WalkSpeed   end
    if not defaultJP   or defaultJP  == 0 then defaultJP   = hum.JumpPower   end
    if defaultUseJP == nil                 then defaultUseJP = hum.UseJumpPower end
    if not defaultJH   or defaultJH  == 0 then defaultJH   = hum.JumpHeight  end

    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if PlayerSettings.SpeedEnabled and hum.WalkSpeed ~= PlayerSettings.SpeedValue then
            hum.WalkSpeed = PlayerSettings.SpeedValue
        end
    end)
    hum:GetPropertyChangedSignal("JumpHeight"):Connect(function()
        if PlayerSettings.JumpEnabled then
            local exp = JumpPowerToJumpHeight(PlayerSettings.JumpValue)
            if math.abs(hum.JumpHeight - exp) > 0.01 then
                ApplyJump(hum, PlayerSettings.JumpValue)
            end
        end
    end)
    hum:GetPropertyChangedSignal("UseJumpPower"):Connect(function()
        if PlayerSettings.JumpEnabled and hum.UseJumpPower then
            hum.UseJumpPower = false
        end
    end)
end

if player.Character then lockHumanoid(player.Character) end
player.CharacterAdded:Connect(lockHumanoid)

-- ══════════════════════════════════════════════
-- MAIN STEPPED LOOP
-- ══════════════════════════════════════════════
rs.Stepped:Connect(function()
    local char = player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if not char then return end

    -- Magnet
    if Settings.Magnet then
        for ball in pairs(activeBalls) do
            if ball.Parent then magBall(ball) end
        end
    end

    -- Speed / Jump
    if hum then
        if PlayerSettings.SpeedEnabled then hum.WalkSpeed = PlayerSettings.SpeedValue end
        if PlayerSettings.JumpEnabled  then ApplyJump(hum, PlayerSettings.JumpValue)  end
    end
end)

-- Heartbeat secondary lock
rs.Heartbeat:Connect(function()
    local char = player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if not hum then return end
    if PlayerSettings.SpeedEnabled and hum.WalkSpeed ~= PlayerSettings.SpeedValue then
        hum.WalkSpeed = PlayerSettings.SpeedValue
    end
    if PlayerSettings.JumpEnabled then
        local exp = JumpPowerToJumpHeight(PlayerSettings.JumpValue)
        if hum.UseJumpPower or math.abs(hum.JumpHeight - exp) > 0.01 then
            ApplyJump(hum, PlayerSettings.JumpValue)
        end
    end
end)

-- ══════════════════════════════════════════════
-- 1. CATCHING TAB
-- ══════════════════════════════════════════════
Tabs.Catching:AddSection("Magnet")

local MagToggle = Tabs.Catching:AddToggle("MagnetEnabled", {
    Title   = "Magnet Enabled",
    Default = false,
    Callback = function(v)
        Settings.Magnet = v
        Fluent:Notify({ Title = "QUANTUM", Content = "Magnet: " .. (v and "On" or "Off"), Duration = 2 })
    end
})

Tabs.Catching:AddKeybind("MagnetKeybind", {
    Title    = "Magnet Keybind",
    Mode     = "Toggle",
    Default  = "None",
    Callback = function(v) MagToggle:SetValue(v) end
})

Tabs.Catching:AddSlider("MagnetRange", {
    Title       = "Magnet Range",
    Description = "Range in studs",
    Default     = 2.2,
    Min         = 1,
    Max         = 100,
    Rounding    = 1,
    Callback    = function(v) Settings.MagnetRange = v end
})

Tabs.Catching:AddSection("Visuals")

local VisToggle = Tabs.Catching:AddToggle("VisualizeMags", {
    Title   = "Visuals (On Ball)",
    Default = false,
    Callback = function(v)
        Settings.VisualizeMags = v
        if v then startVisuals() else stopVisuals() end
        Fluent:Notify({ Title = "QUANTUM", Content = "Mag Visuals: " .. (v and "On" or "Off"), Duration = 2 })
    end
})

Tabs.Catching:AddDropdown("VisualShape", {
    Title    = "Visual Shape",
    Values   = { "Sphere", "Box", "Cylinder" },
    Multi    = false,
    Default  = "Sphere",
    Callback = function(v) Settings.VisualShape = v end
})

Tabs.Catching:AddSection("Auto Tuck")

local TuckToggle = Tabs.Catching:AddToggle("AutoTuck", {
    Title   = "Auto Tuck",
    Default = false,
    Callback = function(v)
        Settings.AutoTuck = v
        Fluent:Notify({ Title = "QUANTUM", Content = "Auto Tuck: " .. (v and "On" or "Off"), Duration = 2 })
    end
})

Tabs.Catching:AddKeybind("AutoTuckKeybind", {
    Title    = "Auto Tuck Keybind",
    Mode     = "Toggle",
    Default  = "None",
    Callback = function(v) TuckToggle:SetValue(v) end
})

Tabs.Catching:AddDropdown("AutoTuckSpeed", {
    Title    = "Tuck Speed",
    Values   = { "Instant", "Smooth", "Delayed" },
    Multi    = false,
    Default  = "Instant",
    Callback = function(v) Settings.AutoTuckSpeed = v end
})

-- ══════════════════════════════════════════════
-- 2. MOVEMENT TAB
-- ══════════════════════════════════════════════
Tabs.Movement:AddSection("WalkSpeed")

local SpeedToggle = Tabs.Movement:AddToggle("EnableWalkSpeed", {
    Title   = "Enable WalkSpeed",
    Default = false,
    Callback = function(v)
        PlayerSettings.SpeedEnabled = v
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = v and PlayerSettings.SpeedValue or ((defaultWS and defaultWS > 0) and defaultWS or 16)
        end
        Fluent:Notify({ Title = "QUANTUM", Content = "WalkSpeed: " .. (v and "On" or "Off"), Duration = 2 })
    end
})

Tabs.Movement:AddKeybind("WalkSpeedKeybind", {
    Title    = "WalkSpeed Keybind",
    Mode     = "Toggle",
    Default  = "None",
    Callback = function(v) SpeedToggle:SetValue(v) end
})

Tabs.Movement:AddSlider("WalkSpeedVal", {
    Title    = "WalkSpeed",
    Default  = 16,
    Min      = 16,
    Max      = 250,
    Rounding = 1,
    Callback = function(v)
        PlayerSettings.SpeedValue = v
        if PlayerSettings.SpeedEnabled then
            local hum = player.Character and player.Character:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

Tabs.Movement:AddSection("JumpPower")

local JumpToggle = Tabs.Movement:AddToggle("EnableJumpPower", {
    Title   = "Enable JumpPower",
    Default = false,
    Callback = function(v)
        PlayerSettings.JumpEnabled = v
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then
            if v then
                ApplyJump(hum, PlayerSettings.JumpValue)
            else
                if defaultUseJP ~= nil then hum.UseJumpPower = defaultUseJP else hum.UseJumpPower = false end
                hum.JumpHeight = (defaultJH and defaultJH > 0) and defaultJH or JumpPowerToJumpHeight(defaultJP or 50)
                if defaultJP and defaultJP > 0 then hum.JumpPower = defaultJP end
            end
        end
        Fluent:Notify({ Title = "QUANTUM", Content = "JumpPower: " .. (v and "On" or "Off"), Duration = 2 })
    end
})

Tabs.Movement:AddKeybind("JumpPowerKeybind", {
    Title    = "JumpPower Keybind",
    Mode     = "Toggle",
    Default  = "None",
    Callback = function(v) JumpToggle:SetValue(v) end
})

Tabs.Movement:AddSlider("JumpPowerVal", {
    Title    = "JumpPower",
    Default  = 60.5,
    Min      = 50,
    Max      = 500,
    Rounding = 1,
    Callback = function(v)
        PlayerSettings.JumpValue = v
        if PlayerSettings.JumpEnabled then
            local hum = player.Character and player.Character:FindFirstChild("Humanoid")
            if hum then ApplyJump(hum, v) end
        end
    end
})

Tabs.Movement:AddSection("Infinite Jump")

Tabs.Movement:AddToggle("InfJump", {
    Title   = "Infinite Jump",
    Default = false,
    Callback = function(v)
        PlayerSettings.InfJump = v
        Fluent:Notify({ Title = "QUANTUM", Content = "Infinite Jump: " .. (v and "On" or "Off"), Duration = 2 })
    end
})

Tabs.Movement:AddSection("Mouse")

local RMBToggle = Tabs.Movement:AddToggle("RMBMouseLock", {
    Title   = "RMB Mouse Lock",
    Default = false,
    Callback = function(v)
        rmbEnabled = v
        if not v and UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
        Fluent:Notify({ Title = "QUANTUM", Content = "RMB Mouse Lock: " .. (v and "On" or "Off"), Duration = 2 })
    end
})

Tabs.Movement:AddKeybind("RMBKeybind", {
    Title    = "RMB Lock Keybind",
    Mode     = "Toggle",
    Default  = "None",
    Callback = function(v) RMBToggle:SetValue(v) end
})

-- ══════════════════════════════════════════════
-- SETTINGS & CONFIG
-- ══════════════════════════════════════════════
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("QUANTUM")
SaveManager:SetFolder("QUANTUM/config")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

Fluent:Notify({
    Title   = "QUANTUM",
    Content = "Loaded! QuantumRise.gg",
    Duration = 5
})
