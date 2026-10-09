--[[
    QUANTUM - Converted to Fluent UI Library
    Original: Mentality Library (Syde UI)
    Converted by: Antigravity
]]

local coregui = (gethui and gethui()) or game:GetService("CoreGui")
local player = game:GetService("Players").LocalPlayer or game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")

-- ══════════════════════════════════════════════
-- PRE-UI BYPASS STACK
-- Runs before UI loads
-- ══════════════════════════════════════════════

-- 1. Core Anti-Kick — patches core GC to nullify kick actions
pcall(function()
    for k, v in pairs(getgc(true)) do
        if pcall(function() return rawget(v, "indexInstance") end)
            and type(rawget(v, "indexInstance")) == "table"
            and (rawget(v, "indexInstance"))[1] == "kick" then
            setreadonly(v, false)
            v.tvk = {
                "kick",
                function()
                    return game.Workspace:WaitForChild("")
                end
            }
        end
    end
end)

-- 2. MEGGD Anti-Kick
pcall(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/SUUUUUS00000/MEGGD-Anti-kick/refs/heads/main/MEGGD%20Best%20Anti-kick.lua'))()
end)

-- 3. Light (AC script) removal
do
    local _lp = game:GetService("Players").LocalPlayer
    local function removeLight()
        local ac = _lp.PlayerScripts:FindFirstChild("Light")
        if ac then ac:Destroy() end
    end
    removeLight()
    _lp.CharacterAdded:Connect(function()
        task.wait()
        removeLight()
    end)
end

-- ==========================================
-- FLUENT UI LOAD
-- ==========================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "QUANTUM" .. "  " .. "<font size='11'>QuantumRise.gg</font>",
    SubTitle = "QuantumRise.gg",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- ==========================================
-- LOCAL SETTINGS
-- ==========================================
local Settings = {
    Magnet = false,
    MagnetRange = 25,
    VisualizeMags = false,
    VisualShape = "Sphere",
    AutoTuck = false,
    AutoTuckSpeed = "Instant",
    ResizeEnabled = false,
    BallSize = 1,
    PullEnabled = false,
    PullRadius = 10,
    PullStrength = 50,
    PullVisuals = false,

    AutoRush = false,
    AutoRushPredict = false,
    AutoRushDelay = 0,
    QuickTP = false,
    QuickTPDist = 2,
    BlockReach = false,
    BlockSize = 5,
    ShowBlockRange = false,
    FreezeEnabled = false,
    FreezeDuration = 0,
    AutoCatch = false,
    CatchRange = 4,
    AutoSwat = false,
    SwatRange = 4,
    BallTrail = false,
    BallTracer = false,
    EndzoneTPEnabled = false,
    KickerAimbot = false,
    KickerAimbotHeight = 5,
    PlayerESP = false,
    GoalpostESP = false
}

local PlayerSettings = {
    JumpEnabled = false,
    JumpValue = 50,
    SpeedEnabled = false,
    SpeedValue = 16,
    InfJump = false
}

-- Infinite Jump Listener
game:GetService("UserInputService").JumpRequest:Connect(function()
    if PlayerSettings.InfJump then
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ==========================================
-- ⚡ COMPLETE QUANTUM RUNTIME ENGINE
-- ==========================================
local hitboxes = {}
local activeBalls = {}

local function isBall(obj)
    if not obj or not obj:IsA("BasePart") then return false end

    if obj:FindFirstAncestorOfClass("Accessory") or obj:FindFirstAncestorOfClass("Accoutrement") then
        return false
    end

    local charModel = obj:FindFirstAncestorOfClass("Model")
    if charModel and (charModel:FindFirstChildOfClass("Humanoid") or game:GetService("Players"):GetPlayerFromCharacter(charModel)) then
        local tool = obj:FindFirstAncestorOfClass("Tool")
        if not tool then return false end
        local tName = tool.Name:lower()
        if not (tName:find("football") or tName == "ball") then
            return false
        end
    end

    local n = obj.Name:lower()
    if n == "football" or n == "ball" then
        return true
    end

    if n == "handle" and obj.Parent and obj.Parent:IsA("Tool") then
        local pName = obj.Parent.Name:lower()
        return (pName:find("football") ~= nil or pName == "ball")
    end

    return false
end

workspace.DescendantAdded:Connect(function(obj)
    if isBall(obj) then activeBalls[obj] = true end
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

local function magBall(ball)
    if touching[ball] then return end
    touching[ball] = true

    task.spawn(function()
        while Settings.Magnet and ball.Parent and player.Character do
            local left, right = getArms(player.Character)
            local root = player.Character:FindFirstChild("HumanoidRootPart")

            if not root or not left or not right then
                break
            end

            local leftDist = (left.Position - ball.Position).Magnitude
            local rightDist = (right.Position - ball.Position).Magnitude
            local rootDist = (root.Position - ball.Position).Magnitude
            local closestDist = math.min(leftDist, rightDist, rootDist)

            if closestDist > Settings.MagnetRange then
                break
            end

            for _ = 1, 8 do
                firetouchinterest(left, ball, 0)
                firetouchinterest(right, ball, 0)
                firetouchinterest(root, ball, 0)

                firetouchinterest(left, ball, 1)
                firetouchinterest(right, ball, 1)
                firetouchinterest(root, ball, 1)
            end

            task.wait()
        end

        touching[ball] = nil
    end)
end

local function findPossessor()
    for _, p in pairs(game.Players:GetPlayers()) do
        local character = p.Character
        if not character then continue end
        if not character:FindFirstChildWhichIsA("Tool") then continue end
        return character
    end
end

local function createOrUpdateHitbox(ball)
    if not ball or not ball.Parent or not isBall(ball) then return end
    local hitbox = hitboxes[ball]
    if not hitbox or not hitbox.Parent then
        hitbox = Instance.new("Part")
        hitbox.Anchored = true
        hitbox.CanCollide = false
        hitbox.Name = "QuantumMagnetVisual"
        hitbox.Material = Enum.Material.ForceField
        hitbox.Color = Color3.fromRGB(235, 35, 45)
        hitbox.Transparency = 0.35
        hitbox.Parent = workspace
        hitboxes[ball] = hitbox
    end
    local radius = Settings.MagnetRange
    local diameter = radius * 2
    if Settings.VisualShape == "Sphere" then
        hitbox.Shape = Enum.PartType.Ball
        hitbox.Size = Vector3.new(diameter, diameter, diameter)
    elseif Settings.VisualShape == "Box" then
        hitbox.Shape = Enum.PartType.Block
        hitbox.Size = Vector3.new(diameter, diameter, diameter)
    elseif Settings.VisualShape == "Cylinder" then
        hitbox.Shape = Enum.PartType.Cylinder
        hitbox.Size = Vector3.new(diameter, diameter, diameter)
    end
    hitbox.CFrame = ball.CFrame
end

local function clearAllHitboxes()
    for ball, hb in pairs(hitboxes) do
        if hb then pcall(function() hb:Destroy() end) end
        hitboxes[ball] = nil
    end
end

-- AutoRush Loop
task.spawn(function()
    local log = {}
    while true do
        task.wait(1/30)
        if not Settings.AutoRush then log = {} continue end
        local possessor = findPossessor()
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp or not humanoid or not possessor or not possessor:FindFirstChild("HumanoidRootPart") then
            log = {} continue
        end
        log[#log + 1] = possessor.HumanoidRootPart.Position
        local delayedPosition = log[math.max(#log - math.round(Settings.AutoRushDelay / (1/30)), 1)]
        if delayedPosition then
            local timeToMoveTo = (hrp.Position - delayedPosition).Magnitude / 20
            local predictedPosition = delayedPosition + (possessor.Humanoid.MoveDirection * timeToMoveTo * 20)
            humanoid:MoveTo(Settings.AutoRushPredict and predictedPosition or delayedPosition)
        end
    end
end)

-- Main Stepped Loop
rs.Stepped:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChild("Humanoid")
    local head = char and char:FindFirstChild("Head")
    if not char or not root then return end

    local blockPart = char:FindFirstChild("BlockPart")
    if blockPart then
        if Settings.BlockReach then
            blockPart.Size = Vector3.new(Settings.BlockSize, Settings.BlockSize, Settings.BlockSize)
            blockPart.Transparency = Settings.ShowBlockRange and 0.5 or 1
        else
            blockPart.Size = Vector3.new(0.75, 5, 1.5)
            blockPart.Transparency = 1
        end
    end

    local seen = {}
    for ball in pairs(activeBalls) do
        if ball.Parent and isBall(ball) then
            seen[ball] = true
            if Settings.Magnet then
                magBall(ball)
            end
            if Settings.ResizeEnabled then
                ball.Size = Vector3.new(Settings.BallSize, Settings.BallSize, Settings.BallSize)
                ball.CanCollide = false
            end
            if Settings.VisualizeMags then
                createOrUpdateHitbox(ball)
            end
            local trail = ball:FindFirstChild("BallTrail")
            if Settings.BallTrail then
                if not trail then
                    local a0 = Instance.new("Attachment", ball); a0.Name = "Attachment0"
                    local a1 = Instance.new("Attachment", ball); a1.Name = "Attachment1"
                    a0.Position = Vector3.new(0, 0.5, 0); a1.Position = Vector3.new(0, -0.5, 0)
                    trail = Instance.new("Trail", ball); trail.Name = "BallTrail"
                    trail.Attachment0 = a0; trail.Attachment1 = a1
                    trail.Lifetime = 0.4; trail.MinLength = 0.1
                    trail.WidthScale = NumberSequence.new(1); trail.FaceCamera = true
                    trail.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255))
                    trail.Transparency = NumberSequence.new(0.2)
                end
            elseif trail then
                trail:Destroy()
                if ball:FindFirstChild("Attachment0") then ball.Attachment0:Destroy() end
                if ball:FindFirstChild("Attachment1") then ball.Attachment1:Destroy() end
            end
            local tracer = char:FindFirstChild("BallTracer")
            if Settings.BallTracer and head then
                if not tracer then
                    local pAtt = head:FindFirstChild("TracerAtt") or Instance.new("Attachment", head); pAtt.Name = "TracerAtt"
                    local bAtt = ball:FindFirstChild("TracerAtt") or Instance.new("Attachment", ball); bAtt.Name = "TracerAtt"
                    tracer = Instance.new("Beam", char); tracer.Name = "BallTracer"
                    tracer.Attachment0 = pAtt; tracer.Attachment1 = bAtt
                    tracer.Width0 = 0.1; tracer.Width1 = 0.1; tracer.FaceCamera = true
                    tracer.LightEmission = 1; tracer.LightInfluence = 0
                    tracer.Transparency = NumberSequence.new(0)
                    tracer.Color = ColorSequence.new(Color3.new(1,1,1))
                    tracer.Segments = 1; tracer.TextureMode = Enum.TextureMode.Stretch
                else
                    tracer.Attachment1 = ball:FindFirstChild("TracerAtt") or Instance.new("Attachment", ball)
                end
            elseif tracer then
                tracer:Destroy()
            end
        end
    end

    for ball, hb in pairs(hitboxes) do
        if not seen[ball] or not isBall(ball) then
            if hb then pcall(function() hb:Destroy() end) end
            hitboxes[ball] = nil
        end
    end

    if hum then
        if PlayerSettings.SpeedEnabled then
            hum.WalkSpeed = PlayerSettings.SpeedValue
        end
        if PlayerSettings.JumpEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = PlayerSettings.JumpValue
            pcall(function()
                hum.JumpHeight = (PlayerSettings.JumpValue ^ 2) / (2 * workspace.Gravity)
            end)
        end
    end
end)

-- Heartbeat Secondary Lock
rs.Heartbeat:Connect(function()
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        if PlayerSettings.SpeedEnabled and hum.WalkSpeed ~= PlayerSettings.SpeedValue then
            hum.WalkSpeed = PlayerSettings.SpeedValue
        end
        if PlayerSettings.JumpEnabled and hum.JumpPower ~= PlayerSettings.JumpValue then
            hum.UseJumpPower = true
            hum.JumpPower = PlayerSettings.JumpValue
            pcall(function()
                hum.JumpHeight = (PlayerSettings.JumpValue ^ 2) / (2 * workspace.Gravity)
            end)
        end
    end
end)

-- Auto Catch & Swat
local function checkAutomation()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, football in pairs(workspace:GetChildren()) do
        if (football.Name == "Football" or football.Name == "Ball") then
            local dist = (football.Position - char.HumanoidRootPart.Position).Magnitude
            if Settings.AutoCatch and dist <= Settings.CatchRange then
                local hit = char:FindFirstChild("Hitbox")
                if hit and hit:FindFirstChild("RemoteEvent") then hit.RemoteEvent:FireServer("catch") end
            end
            if Settings.AutoSwat and dist <= Settings.SwatRange then
                local hit = char:FindFirstChild("Hitbox")
                if hit and hit:FindFirstChild("RemoteEvent") then hit.RemoteEvent:FireServer({{"pbu", Vector3.new(1.8,1.3,4.6)}}) end
            end
        end
    end
end
rs.RenderStepped:Connect(checkAutomation)

-- ==========================================
-- KICKER AIMBOT ENGINE
-- ==========================================
local function getGoalposts()
    local posts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if obj:IsA("Model") and (n == "goal post1" or n == "goal post2" or n:find("goalpost") or n:find("goal_post")) then
            table.insert(posts, obj)
        end
    end
    return posts
end

local function getGoalpostCenter(model)
    local best = nil
    local bestY = -math.huge
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and p.Position.Y > bestY then
            bestY = p.Position.Y
            best = p
        end
    end
    if best then
        return Vector3.new(best.Position.X, best.Position.Y + Settings.KickerAimbotHeight, best.Position.Z)
    end
    return nil
end

local function getNearestGoalpost()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local posts = getGoalposts()
    local closest, closestDist = nil, math.huge
    for _, post in ipairs(posts) do
        local center = getGoalpostCenter(post)
        if center then
            local d = (hrp.Position - center).Magnitude
            if d < closestDist then
                closestDist = d
                closest = center
            end
        end
    end
    return closest
end

if not getgenv().QuantumKickHook then
    getgenv().QuantumKickHook = true
    local _mt = getrawmetatable(game)
    local _oldNC = _mt.__namecall
    setreadonly(_mt, false)
    _mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and Settings.KickerAimbot then
            local gameData = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
            local isKicking = gameData and gameData:FindFirstChild("Kicking") and gameData.Kicking.Value
            local isFG = gameData and gameData:FindFirstChild("Fieldgoal") and gameData.Fieldgoal.Value
            if isKicking and isFG then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local target = getNearestGoalpost()
                if hrp and target then
                    local dir = (target - hrp.Position).Unit
                    return _oldNC(self, dir)
                end
            end
        end
        return _oldNC(self, ...)
    end
    setreadonly(_mt, true)
end

-- ESP systems
local espHighlights = {}
local goalpostHighlights = {}

local function clearESP()
    for _, h in pairs(espHighlights) do pcall(function() h:Destroy() end) end
    espHighlights = {}
end

local function clearGoalpostESP()
    for _, h in pairs(goalpostHighlights) do pcall(function() h:Destroy() end) end
    goalpostHighlights = {}
end

local function updatePlayerESP()
    if not Settings.PlayerESP then clearESP() return end
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char = p.Character
            if not espHighlights[char] then
                local h = Instance.new("SelectionBox")
                h.Adornee = char
                h.Color3 = Color3.fromRGB(235, 35, 45)
                h.LineThickness = 0.04
                h.SurfaceTransparency = 0.85
                h.SurfaceColor3 = Color3.fromRGB(235, 35, 45)
                h.Parent = player.PlayerGui
                espHighlights[char] = h
            end
        end
    end
    for char, h in pairs(espHighlights) do
        if not char.Parent then
            pcall(function() h:Destroy() end)
            espHighlights[char] = nil
        end
    end
end

local function updateGoalpostESP()
    if not Settings.GoalpostESP then clearGoalpostESP() return end
    local posts = getGoalposts()
    for _, post in ipairs(posts) do
        if not goalpostHighlights[post] then
            local h = Instance.new("SelectionBox")
            h.Adornee = post
            h.Color3 = Color3.fromRGB(0, 255, 100)
            h.LineThickness = 0.06
            h.SurfaceTransparency = 1
            h.Parent = player.PlayerGui
            goalpostHighlights[post] = h
        end
    end
    for post, h in pairs(goalpostHighlights) do
        if not post.Parent then
            pcall(function() h:Destroy() end)
            goalpostHighlights[post] = nil
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        updatePlayerESP()
        updateGoalpostESP()
    end
end)

-- Auto Tuck Engine
local tuckEquipped = false
local function detectFootballEquipped()
    local char = player.Character
    if not char then tuckEquipped = false return end
    local football = char:FindFirstChild("Football")
    if football then
        if not tuckEquipped then
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Tuck", 3):FireServer()
            end)
            tuckEquipped = true
        end
    else
        tuckEquipped = false
    end
end

player.CharacterAdded:Connect(function() tuckEquipped = false end)
task.spawn(function()
    while true do
        if Settings.AutoTuck then detectFootballEquipped() end
        task.wait(0.1)
    end
end)

----------------------------------------------------------------------
-- HELPER FUNCTIONS & DEFAULTS TRACKING
local defaultWS = nil
local defaultJP = nil
local defaultUseJP = nil
local defaultJH = nil

local function lockHumanoidProperties(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 4)
    if not hum then return end

    if defaultWS == nil or defaultWS == 0 then defaultWS = hum.WalkSpeed end
    if defaultJP == nil or defaultJP == 0 then defaultJP = hum.JumpPower end
    if defaultUseJP == nil then defaultUseJP = hum.UseJumpPower end
    if defaultJH == nil or defaultJH == 0 then defaultJH = hum.JumpHeight end

    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if PlayerSettings.SpeedEnabled and hum.WalkSpeed ~= PlayerSettings.SpeedValue then
            hum.WalkSpeed = PlayerSettings.SpeedValue
        end
    end)

    hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if PlayerSettings.JumpEnabled and hum.JumpPower ~= PlayerSettings.JumpValue then
            hum.UseJumpPower = true
            hum.JumpPower = PlayerSettings.JumpValue
        end
    end)

    hum:GetPropertyChangedSignal("JumpHeight"):Connect(function()
        if PlayerSettings.JumpEnabled then
            local expected = (PlayerSettings.JumpValue ^ 2) / (2 * workspace.Gravity)
            if math.abs(hum.JumpHeight - expected) > 0.1 then
                pcall(function() hum.JumpHeight = expected end)
            end
        end
    end)
end

if player.Character then lockHumanoidProperties(player.Character) end
player.CharacterAdded:Connect(lockHumanoidProperties)

-- ══════════════════════════════════════════════
-- RMB MOUSE LOCK ENGINE
-- ══════════════════════════════════════════════
local rmbHeld = false
local rmbEnabled = false

local function syncMouseBehavior()
    if not rmbEnabled then return end
    if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then return end
    local desired = rmbHeld
        and Enum.MouseBehavior.LockCurrentPosition
        or Enum.MouseBehavior.Default
    if UIS.MouseBehavior ~= desired then
        UIS.MouseBehavior = desired
    end
end

UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rmbHeld = true
        syncMouseBehavior()
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rmbHeld = false
        syncMouseBehavior()
    end
end)

UIS:GetPropertyChangedSignal("MouseBehavior"):Connect(function()
    task.defer(syncMouseBehavior)
end)

local function GetTeamsFromFrame(category, frameName)
    local teams = {}
    local pg = player:FindFirstChild("PlayerGui")
    local sideMenu = pg and pg:FindFirstChild("SideMenu")
    local catFrame = sideMenu and sideMenu:FindFirstChild("Container") and sideMenu.Container:FindFirstChild(category)
    local innerContainer = catFrame and catFrame:FindFirstChild("Container")
    local targetFrame = innerContainer and innerContainer:FindFirstChild(frameName)

    if targetFrame then
        for _, v in ipairs(targetFrame:GetChildren()) do
            if v:IsA("TextButton") then
                table.insert(teams, v.Name)
            end
        end
    end

    if #teams == 0 then
        if category == "Accessories" then
            return { "Black", "White", "Red", "Blue", "Purple", "Yellow", "Pink", "Navy", "Maroon", "Orange" }
        end
        table.insert(teams, "Default")
    end
    return teams
end

local MarketplaceService = game:GetService("MarketplaceService")
local VIP_PASS = 1899769178
local BALL_TRAIL_PASS = 1898828399
local FREE_PASSES = { [VIP_PASS] = true, [BALL_TRAIL_PASS] = true }

if not getgenv().QuantumGamePassHook then
    getgenv().QuantumGamePassHook = true
    pcall(function()
        local oldOwns
        oldOwns = hookfunction(MarketplaceService.UserOwnsGamePassAsync, newcclosure(function(self, userId, passId)
            if FREE_PASSES[passId] then return true end
            return oldOwns(self, userId, passId)
        end))
    end)
end

local TOWEL_SLOTS = { "FrontMid", "FrontRight", "Right", "BackRight", "BackMid", "BackLeft", "Left", "FrontLeft" }
local HANDWARMER_SLOTS = { "FrontMid", "BackMid" }
local BALL_TRAIL_IDS = { "None", "Ice", "Blue", "Crimson", "Gold", "Rainbow" }
local VIP_EMOTES = {
    "archer", "clap", "flex", "frontflip", "folks", "hotfeet", "lebron", "inc", "superman",
    "pose1", "pose2", "pose3", "sturdy", "shake that", "baby", "seatbelt", "griddy", "headtap"
}
local CUSTOM_COLOR_FRAMES = {
    "MaskFrame", "MouthpieceFrame",
    "RevolutionVisorFrame", "SchuttF7FullbarVisorFrame",
    "SchuttF7RobotVisorFrame", "Speedflex2BarVisorFrame"
}

local function getHelmetEvent()
    local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
    return events and events:FindFirstChild("Helmet")
end

local function FireHelmet(args)
    local event = getHelmetEvent()
    if event then event:FireServer(args) end
end

local function getSideMenuOptionFrame(category, frameName)
    local pg = player:FindFirstChild("PlayerGui")
    local sideMenu = pg and pg:FindFirstChild("SideMenu")
    local catFrame = sideMenu and sideMenu:FindFirstChild("Container") and sideMenu.Container:FindFirstChild(category)
    local innerContainer = catFrame and catFrame:FindFirstChild("Container")
    return innerContainer and innerContainer:FindFirstChild(frameName)
end

local function clickSideMenuOption(category, frameName, optionName)
    local optionFrame = getSideMenuOptionFrame(category, frameName)
    local btn = optionFrame and optionFrame:FindFirstChild(optionName)
    if not btn or not btn:IsA("GuiButton") then return false end

    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(btn.MouseButton1Down)) do
                conn:Fire()
            end
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                conn:Fire()
            end
        end
    end)
    return true
end

local function EquipHelmetFrame(frameName, teamButton)
    if teamButton == "Default" then return end
    clickSideMenuOption("Helmets", frameName, teamButton)
    FireHelmet({ frameName, teamButton })
end

local function EquipAccessoryFrame(frameName, optionName)
    if optionName == "Default" then return end
    clickSideMenuOption("Accessories", frameName, optionName)
    FireHelmet({ frameName, optionName })
end

local function EquipTowel(slot, towelId)
    if clickSideMenuOption("Accessories", "TowelFrame", towelId) then return end
    FireHelmet({ "Towel", slot, towelId })
end

local function EquipHandwarmer(slot, id)
    if clickSideMenuOption("Accessories", "HandwarmersFrame", id) then return end
    FireHelmet({ "Handwarmer", slot, id })
end

local function getAutoTowelSlot()
    local char = player.Character
    if not char then return "FrontMid" end
    local chain = {
        { "FrontMid", "FrontRight" },
        { "FrontRight", "Right" },
        { "Right", "BackRight" },
        { "BackRight", "BackMid" },
        { "BackMid", "BackLeft" },
        { "BackLeft", "Left" },
        { "Left", "FrontLeft" },
        { "FrontLeft", "FrontMid" },
    }
    for _, pair in ipairs(chain) do
        if char:FindFirstChild(pair[1]) then return pair[2] end
    end
    return "FrontMid"
end

local function getAutoHandwarmerSlot()
    local char = player.Character
    if char and char:FindFirstChild("FrontMid") then return "BackMid" end
    if char and char:FindFirstChild("BackMid") then return "FrontMid" end
    return "FrontMid"
end

local function EquipCustomAccessory(frameName, r, g, b, transparency, reflectance)
    FireHelmet({
        frameName,
        "Custom",
        Color3.fromRGB(r, g, b),
        tostring(transparency or 0),
        tostring(reflectance or 0)
    })
end

local function playVipEmote(name)
    local cmd = "/e " .. name
    local sent = false
    pcall(function()
        local ch = game:GetService("TextChatService"):FindFirstChild("TextChannels")
        ch = ch and ch:FindFirstChild("RBXGeneral")
        if ch then ch:SendAsync(cmd); sent = true end
    end)
    if not sent then pcall(function() player:Chat(cmd) end) end
end

local function getBallTrailRemote()
    local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
    return events and events:FindFirstChild("BallTrail")
end

local function syncBallTrail()
    local rf = getBallTrailRemote()
    if not rf then return BALL_TRAIL_IDS, "None" end
    local ok, result = pcall(function() return rf:InvokeServer("Get") end)
    if ok and type(result) == "table" then
        return BALL_TRAIL_IDS, tostring(result.equipped or "None")
    end
    return BALL_TRAIL_IDS, "None"
end

local function equipServerBallTrail(trailId)
    local rf = getBallTrailRemote()
    if not rf then return false end
    local ok, result = pcall(function() return rf:InvokeServer("Equip", trailId) end)
    return ok and type(result) == "table" and result.ok == true
end

----------------------------------------------------------------------
-- QUICK TP MOBILE UI
----------------------------------------------------------------------
local tpButton

local function teleportForward()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = hrp.CFrame + (hrp.CFrame.LookVector * Settings.QuickTPDist)
    end
end

local function toggleMobileTP(v)
    if v and UIS.TouchEnabled then
        if tpButton then tpButton:Destroy() end
        local screenGui = Instance.new("ScreenGui", player.PlayerGui)
        screenGui.Name = "QuickTPUI"

        tpButton = Instance.new("TextButton", screenGui)
        tpButton.Size = UDim2.new(0, 60, 0, 60)
        tpButton.Position = UDim2.new(0.5, -30, 0.8, 0)
        tpButton.BackgroundColor3 = Color3.fromRGB(28, 24, 18)
        tpButton.TextColor3 = Color3.fromRGB(212, 175, 55)
        tpButton.Text = "TP"
        tpButton.Font = Enum.Font.GothamBold
        tpButton.TextSize = 20

        local corner = Instance.new("UICorner", tpButton)
        corner.CornerRadius = UDim.new(0.5, 0)

        local stroke = Instance.new("UIStroke", tpButton)
        stroke.Color = Color3.fromRGB(212, 175, 55)
        stroke.Thickness = 2

        tpButton.MouseButton1Click:Connect(teleportForward)
    elseif tpButton then
        tpButton.Parent:Destroy()
        tpButton = nil
    end
end

local QuickTPKey = Enum.KeyCode.E

UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and Settings.QuickTP and QuickTPKey and input.KeyCode == QuickTPKey then
        teleportForward()
    end
end)

----------------------------------------------------------------------
-- FREEZE TECH LOGIC
----------------------------------------------------------------------
local freezeActive = false

local function unfreezeCharacter()
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and root then
        hum.PlatformStand = false
        root.Anchored = false
    end
    freezeActive = false
end

local function freezeCharacter()
    local char = game.Players.LocalPlayer.Character
    if not char or freezeActive then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if root and hum then
        freezeActive = true
        hum.PlatformStand = true
        root.Anchored = true
        task.delay(Settings.FreezeDuration, function()
            unfreezeCharacter()
        end)
    end
end

game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if Settings.FreezeEnabled and child:IsA("Tool") and child.Name:lower():find("football") then
            freezeCharacter()
        end
    end)
end)

if game.Players.LocalPlayer.Character then
    game.Players.LocalPlayer.Character.ChildAdded:Connect(function(child)
        if Settings.FreezeEnabled and child:IsA("Tool") and child.Name:lower():find("football") then
            freezeCharacter()
        end
    end)
end

----------------------------------------------------------------------
-- PULL VECTOR LOGIC
----------------------------------------------------------------------
local function pull_move(ball)
    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not Settings.PullEnabled or not ball or not hrp then return end
    char:SetPrimaryPartCFrame(CFrame.new(ball.Position + Vector3.new(0, 2, 0)))
end

workspace.ChildAdded:Connect(function(v)
    if v:IsA("BasePart") and (v.Name:lower():find("football") or v.Name == "Ball") then
        while v.Parent == workspace and Settings.PullEnabled do
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (v.Position - hrp.Position).Magnitude
                if d <= Settings.PullRadius then
                    pull_move(v)
                end
            end
            task.wait(0.1)
        end
    end
end)

-- ==========================================
-- NOTIFICATION HELPER
-- ==========================================
local function Notify(title, content, dur)
    Fluent:Notify({
        Title = title or "QUANTUM",
        Content = content or "",
        Duration = dur or 2
    })
end

-- ==========================================
-- TABS
-- ==========================================
local Tabs = {
    Catching   = Window:AddTab({ Title = "Catching",   Icon = "crosshair" }),
    Movement   = Window:AddTab({ Title = "Movement",   Icon = "footprints" }),
    Physics    = Window:AddTab({ Title = "Physics",    Icon = "atom" }),
    Equipment  = Window:AddTab({ Title = "Equipment",  Icon = "shirt" }),
    Visuals    = Window:AddTab({ Title = "Visuals",    Icon = "eye" }),
    Automatics = Window:AddTab({ Title = "Automatics", Icon = "cpu" }),
    Extras     = Window:AddTab({ Title = "Extras",     Icon = "star" }),
}

-- ==========================================
-- 1. CATCHING TAB
-- ==========================================
do
    local Tab = Tabs.Catching

    Tab:AddSection("Magnet")

    Tab:AddToggle("MagnetEnabled", {
        Title = "Magnet Enabled",
        Default = false,
        Callback = function(v)
            Settings.Magnet = v
            Notify("QUANTUM", "Magnet: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("MagnetRange", {
        Title = "Magnet Range",
        Description = "Detection radius in studs",
        Default = 25,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Callback = function(v)
            Settings.MagnetRange = v
        end
    })

    Tab:AddToggle("VisualizeMags", {
        Title = "Visuals (On Ball)",
        Default = false,
        Callback = function(v)
            Settings.VisualizeMags = v
            Notify("QUANTUM", "Mag Visuals: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddDropdown("VisualShape", {
        Title = "Visual Shape",
        Values = { "Sphere", "Box", "Cylinder" },
        Default = 1,
        Callback = function(v) Settings.VisualShape = v end
    })

    Tab:AddSection("Pull Vector")

    Tab:AddToggle("PullEnabled", {
        Title = "Pull Vector Enabled",
        Default = false,
        Callback = function(v)
            Settings.PullEnabled = v
            Notify("QUANTUM", "Pull Vector: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("PullRadius", {
        Title = "Pull Radius",
        Default = 10,
        Min = 1,
        Max = 50,
        Rounding = 0,
        Callback = function(v) Settings.PullRadius = v end
    })

    Tab:AddSlider("PullStrength", {
        Title = "Pull Strength",
        Default = 50,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Callback = function(v) Settings.PullStrength = v end
    })

    Tab:AddSection("Pull Visuals")

    Tab:AddToggle("PullVisuals", {
        Title = "Pull Visuals",
        Default = false,
        Callback = function(v)
            Settings.PullVisuals = v
            Notify("QUANTUM", "Pull Visuals: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSection("Auto Tuck")

    Tab:AddToggle("AutoTuck", {
        Title = "Auto Tuck",
        Default = false,
        Callback = function(v)
            Settings.AutoTuck = v
            Notify("QUANTUM", "Auto Tuck: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddDropdown("AutoTuckSpeed", {
        Title = "Auto Tuck Speed",
        Values = { "Instant", "Smooth", "Delayed" },
        Default = 1,
        Callback = function(v) Settings.AutoTuckSpeed = v end
    })

    Tab:AddSection("Catch Effects")

    Tab:AddToggle("CatchEffect", {
        Title = "Catch Effect",
        Default = false,
        Callback = function(v)
            getgenv().catchEffects = v
            Notify("QUANTUM", "Catch Effect: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSection("Freeze After Catch")

    Tab:AddToggle("FreezeEnabled", {
        Title = "Freeze After Catch",
        Default = false,
        Callback = function(v)
            Settings.FreezeEnabled = v
            if not v then unfreezeCharacter() end
            Notify("QUANTUM", "Freeze After Catch: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("FreezeDuration", {
        Title = "Freeze Time (seconds)",
        Default = 0,
        Min = 0,
        Max = 5,
        Rounding = 1,
        Callback = function(v) Settings.FreezeDuration = v end
    })
end

-- ==========================================
-- 2. MOVEMENT TAB
-- ==========================================
do
    local Tab = Tabs.Movement

    Tab:AddSection("WalkSpeed")

    Tab:AddToggle("SpeedEnabled", {
        Title = "Enable WalkSpeed",
        Default = false,
        Callback = function(v)
            PlayerSettings.SpeedEnabled = v
            local hum = player.Character and player.Character:FindFirstChild("Humanoid")
            if hum then
                if v then
                    hum.WalkSpeed = PlayerSettings.SpeedValue
                else
                    hum.WalkSpeed = (defaultWS and defaultWS > 0) and defaultWS or 16
                end
            end
            Notify("QUANTUM", "WalkSpeed: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("SpeedValue", {
        Title = "WalkSpeed",
        Default = 16,
        Min = 16,
        Max = 250,
        Rounding = 0,
        Callback = function(v)
            PlayerSettings.SpeedValue = v
            if PlayerSettings.SpeedEnabled then
                local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = v end
            end
        end
    })

    Tab:AddSection("JumpPower")

    Tab:AddToggle("JumpEnabled", {
        Title = "Enable JumpPower",
        Default = false,
        Callback = function(v)
            PlayerSettings.JumpEnabled = v
            local hum = player.Character and player.Character:FindFirstChild("Humanoid")
            if hum then
                if v then
                    hum.UseJumpPower = true
                    hum.JumpPower = PlayerSettings.JumpValue
                    pcall(function()
                        hum.JumpHeight = (PlayerSettings.JumpValue ^ 2) / (2 * workspace.Gravity)
                    end)
                else
                    if defaultJP and defaultJP > 0 then hum.JumpPower = defaultJP else hum.JumpPower = 50 end
                    if defaultUseJP ~= nil then hum.UseJumpPower = defaultUseJP end
                    if defaultJH and defaultJH > 0 then
                        hum.JumpHeight = defaultJH
                    else
                        pcall(function()
                            hum.JumpHeight = ((defaultJP or 50) ^ 2) / (2 * workspace.Gravity)
                        end)
                    end
                end
            end
            Notify("QUANTUM", "JumpPower: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("JumpValue", {
        Title = "JumpPower",
        Default = 50,
        Min = 50,
        Max = 500,
        Rounding = 0,
        Callback = function(v)
            PlayerSettings.JumpValue = v
            if PlayerSettings.JumpEnabled then
                local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                if hum then
                    hum.UseJumpPower = true
                    hum.JumpPower = v
                end
            end
        end
    })

    Tab:AddSection("Infinite Jump")

    Tab:AddToggle("InfJump", {
        Title = "Infinite Jump",
        Default = false,
        Callback = function(v)
            PlayerSettings.InfJump = v
            Notify("QUANTUM", "Infinite Jump: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSection("Mouse")

    local RMBToggle = Tab:AddToggle("RMBMouseLock", {
        Title = "RMB Mouse Lock",
        Default = false,
        Callback = function(v)
            rmbEnabled = v
            if not v then
                if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                    UIS.MouseBehavior = Enum.MouseBehavior.Default
                end
            end
            Notify("QUANTUM", "RMB Mouse Lock: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddKeybind("RMBMouseLockKeybind", {
        Title = "RMB Lock Keybind",
        Mode = "Toggle",
        Default = "None",
        Callback = function(v)
            RMBToggle:SetValue(v)
        end
    })

    Tab:AddSection("Quick Teleport")

    Tab:AddToggle("QuickTP", {
        Title = "Enabled",
        Default = false,
        Callback = function(v)
            Settings.QuickTP = v
            toggleMobileTP(v)
            Notify("QUANTUM", "Quick TP: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("QuickTPDist", {
        Title = "TP Distance (studs)",
        Default = 2,
        Min = 1,
        Max = 10,
        Rounding = 0,
        Callback = function(v) Settings.QuickTPDist = v end
    })

    Tab:AddKeybind("QuickTPKey", {
        Title = "Quick TP Key",
        Mode = "Toggle",
        Default = "E",
        Callback = function(v) end,
        ChangedCallback = function(new)
            QuickTPKey = new
        end
    })

    Tab:AddSection("Endzone Teleports")

    Tab:AddToggle("EndzoneTPEnabled", {
        Title = "Enable Endzone TP",
        Default = false,
        Callback = function(v)
            Settings.EndzoneTPEnabled = v
            Notify("QUANTUM", "Endzone TP: " .. (v and "On" or "Off"))
        end
    })

    local function findFieldTarget(keywords)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                for _, kw in ipairs(keywords) do
                    if n:find(kw) then
                        return obj.Position + Vector3.new(0, 3, 0)
                    end
                end
            end
        end
        return nil
    end

    local function teleportToPosition(pos)
        if not Settings.EndzoneTPEnabled then
            Notify("QUANTUM", "Enable Endzone TP toggle first!")
            return
        end
        local char = player.Character or game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and pos then
            hrp.CFrame = CFrame.new(pos)
            Notify("QUANTUM", "Teleported!")
        else
            Notify("QUANTUM", "Position not found")
        end
    end

    Tab:AddButton({
        Title = "Teleport Home Endzone",
        Callback = function()
            if not Settings.EndzoneTPEnabled then
                Notify("QUANTUM", "Turn Endzone TP ON first!")
                return
            end
            local pos = findFieldTarget({ "homeendzone", "home_endzone", "endzone1", "homeez", "home" })
            if not pos then pos = Vector3.new(0, 5, 160) end
            teleportToPosition(pos)
        end
    })

    Tab:AddButton({
        Title = "Teleport Away Endzone",
        Callback = function()
            if not Settings.EndzoneTPEnabled then
                Notify("QUANTUM", "Turn Endzone TP ON first!")
                return
            end
            local pos = findFieldTarget({ "awayendzone", "away_endzone", "endzone2", "awayez", "away" })
            if not pos then pos = Vector3.new(0, 5, -160) end
            teleportToPosition(pos)
        end
    })

    Tab:AddButton({
        Title = "Teleport 50-Yard Line (Midfield)",
        Callback = function()
            if not Settings.EndzoneTPEnabled then
                Notify("QUANTUM", "Turn Endzone TP ON first!")
                return
            end
            local pos = findFieldTarget({ "midfield", "50yard", "50_yard", "centerfield", "fifty" })
            if not pos then pos = Vector3.new(0, 5, 0) end
            teleportToPosition(pos)
        end
    })
end

-- ==========================================
-- 3. PHYSICS TAB
-- ==========================================
do
    local Tab = Tabs.Physics

    Tab:AddSection("Block Reach")

    Tab:AddToggle("BlockReach", {
        Title = "Block Reach",
        Default = false,
        Callback = function(v)
            Settings.BlockReach = v
            Notify("QUANTUM", "Block Reach: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("BlockSize", {
        Title = "Block Distance (studs)",
        Default = 5,
        Min = 5,
        Max = 25,
        Rounding = 0,
        Callback = function(v) Settings.BlockSize = v end
    })

    Tab:AddSection("Ball Resize")

    Tab:AddToggle("ResizeEnabled", {
        Title = "Ball Resize",
        Default = false,
        Callback = function(v)
            Settings.ResizeEnabled = v
            Notify("QUANTUM", "Ball Resize: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("BallSize", {
        Title = "Ball Size",
        Default = 1,
        Min = 1,
        Max = 10,
        Rounding = 0,
        Callback = function(v) Settings.BallSize = v end
    })
end

-- ==========================================
-- 4. EQUIPMENT TAB
-- ==========================================
do
    local Tab = Tabs.Equipment

    Tab:AddSection("Helmets")

    local helmetFrames = {
        { title = "Revolution",     frame = "RevolutionFrame"    },
        { title = "Speed Flex",     frame = "SpeedflexFrame"     },
        { title = "Schutt F7",      frame = "SchuttF7Frame"      },
        { title = "Vengeance Edge", frame = "VengeanceEdgeFrame" },
        { title = "ROPO Gold",      frame = "ROPOGoldFrame"      },
        { title = "ROPO Speed",     frame = "ROPOSpeedFrame"     },
    }

    for _, h in ipairs(helmetFrames) do
        Tab:AddDropdown("Helmet_" .. h.frame, {
            Title = h.title,
            Values = GetTeamsFromFrame("Helmets", h.frame),
            Default = 1,
            Callback = function(team) EquipHelmetFrame(h.frame, team) end
        })
    end

    Tab:AddButton({
        Title = "Refresh Helmet Options",
        Callback = function()
            Notify("QUANTUM", "Open in-game menu first, then rerun helmet dropdowns", 3)
        end
    })

    Tab:AddSection("Visors")

    local visorFrames = {
        { title = "Revolution Visor",    frame = "RevolutionVisorFrame"      },
        { title = "F7 Fullbar Visor",    frame = "SchuttF7FullbarVisorFrame" },
        { title = "F7 Robot Visor",      frame = "SchuttF7RobotVisorFrame"   },
        { title = "Speedflex 2-Bar Visor", frame = "Speedflex2BarVisorFrame" },
    }

    for _, v in ipairs(visorFrames) do
        Tab:AddDropdown("Visor_" .. v.frame, {
            Title = v.title,
            Values = GetTeamsFromFrame("Accessories", v.frame),
            Default = 1,
            Callback = function(team) EquipAccessoryFrame(v.frame, team) end
        })
    end

    Tab:AddSection("Masks & Mouthpieces")

    Tab:AddDropdown("Mask", {
        Title = "Mask",
        Values = GetTeamsFromFrame("Accessories", "MaskFrame"),
        Default = 1,
        Callback = function(v) EquipAccessoryFrame("MaskFrame", v) end
    })

    Tab:AddDropdown("Mouthpiece", {
        Title = "Mouthpiece",
        Values = GetTeamsFromFrame("Accessories", "MouthpieceFrame"),
        Default = 1,
        Callback = function(v) EquipAccessoryFrame("MouthpieceFrame", v) end
    })

    Tab:AddSection("Towels & Handwarmers")

    local towelSlot = "Auto"

    Tab:AddDropdown("TowelSlot", {
        Title = "Towel Slot",
        Values = { "Auto", table.unpack(TOWEL_SLOTS) },
        Default = 1,
        Callback = function(v) towelSlot = v end
    })

    Tab:AddDropdown("TowelType", {
        Title = "Towel Type",
        Values = GetTeamsFromFrame("Accessories", "TowelFrame"),
        Default = 1,
        Callback = function(v)
            local slot = towelSlot == "Auto" and getAutoTowelSlot() or towelSlot
            EquipTowel(slot, v)
        end
    })

    local handwarmerSlot = "Auto"

    Tab:AddDropdown("HandwarmerSlot", {
        Title = "Handwarmer Slot",
        Values = { "Auto", table.unpack(HANDWARMER_SLOTS) },
        Default = 1,
        Callback = function(v) handwarmerSlot = v end
    })

    Tab:AddDropdown("HandwarmerType", {
        Title = "Handwarmer Type",
        Values = GetTeamsFromFrame("Accessories", "HandwarmersFrame"),
        Default = 1,
        Callback = function(v)
            local slot = handwarmerSlot == "Auto" and getAutoHandwarmerSlot() or handwarmerSlot
            EquipHandwarmer(slot, v)
        end
    })

    Tab:AddSection("Custom Colors")

    local customColor = { frame = "RevolutionVisorFrame", r = 255, g = 0, b = 0, t = 0, ref = 0 }

    Tab:AddDropdown("ColorTargetFrame", {
        Title = "Color Target Frame",
        Values = CUSTOM_COLOR_FRAMES,
        Default = 1,
        Callback = function(v) customColor.frame = v end
    })

    Tab:AddSlider("CustomRed", {
        Title = "Red",
        Default = 255,
        Min = 0,
        Max = 255,
        Rounding = 0,
        Callback = function(v) customColor.r = v end
    })

    Tab:AddSlider("CustomGreen", {
        Title = "Green",
        Default = 0,
        Min = 0,
        Max = 255,
        Rounding = 0,
        Callback = function(v) customColor.g = v end
    })

    Tab:AddSlider("CustomBlue", {
        Title = "Blue",
        Default = 0,
        Min = 0,
        Max = 255,
        Rounding = 0,
        Callback = function(v) customColor.b = v end
    })

    Tab:AddSlider("CustomTransparency", {
        Title = "Transparency",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) customColor.t = v end
    })

    Tab:AddSlider("CustomReflectance", {
        Title = "Reflectance",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) customColor.ref = v end
    })

    Tab:AddButton({
        Title = "Apply Custom Color",
        Callback = function()
            EquipCustomAccessory(customColor.frame, customColor.r, customColor.g, customColor.b, customColor.t, customColor.ref)
        end
    })
end

-- ==========================================
-- 5. VISUALS TAB
-- ==========================================
do
    local Tab = Tabs.Visuals

    Tab:AddSection("Player ESP")

    Tab:AddToggle("PlayerESP", {
        Title = "Player ESP (Selection Box)",
        Default = false,
        Callback = function(v)
            Settings.PlayerESP = v
            if not v then clearESP() end
            Notify("QUANTUM", "Player ESP: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSection("Goalpost ESP")

    Tab:AddToggle("GoalpostESP", {
        Title = "Highlight Goalposts",
        Default = false,
        Callback = function(v)
            Settings.GoalpostESP = v
            if not v then clearGoalpostESP() end
            Notify("QUANTUM", "Goalpost ESP: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSection("Ball Trail")

    local _, equippedTrail = syncBallTrail()

    Tab:AddDropdown("ServerBallTrail", {
        Title = "Equip Ball Trail (Server)",
        Values = BALL_TRAIL_IDS,
        Default = 1,
        Callback = function(v)
            if equipServerBallTrail(v) then
                Notify("QUANTUM", "Equipped trail: " .. v)
            end
        end
    })

    Tab:AddButton({
        Title = "Refresh Trail State",
        Callback = function()
            local _, eq = syncBallTrail()
            Notify("QUANTUM", "Equipped: " .. eq)
        end
    })

    Tab:AddToggle("BallTrailClient", {
        Title = "Enable Ball Trail (Client)",
        Default = false,
        Callback = function(v)
            Settings.BallTrail = v
            Notify("QUANTUM", "Ball Trail: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSection("Ball Tracer")

    Tab:AddToggle("BallTracer", {
        Title = "Enable Ball Tracer",
        Default = false,
        Callback = function(v)
            Settings.BallTracer = v
            Notify("QUANTUM", "Ball Tracer: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSection("Block Range Visual")

    Tab:AddToggle("ShowBlockRange", {
        Title = "Show Block Range",
        Default = false,
        Callback = function(v)
            Settings.ShowBlockRange = v
            Notify("QUANTUM", "Show Block Range: " .. (v and "On" or "Off"))
        end
    })
end

-- ==========================================
-- 6. AUTOMATICS TAB
-- ==========================================
do
    local Tab = Tabs.Automatics

    Tab:AddSection("Kicker Aimbot")

    Tab:AddToggle("KickerAimbot", {
        Title = "Kicker Aimbot",
        Default = false,
        Callback = function(v)
            Settings.KickerAimbot = v
            Notify("QUANTUM", "Kicker Aimbot: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("KickerAimbotHeight", {
        Title = "Target Height Offset",
        Default = 5,
        Min = 0,
        Max = 20,
        Rounding = 0,
        Callback = function(v) Settings.KickerAimbotHeight = v end
    })

    Tab:AddButton({
        Title = "Aim At Goalpost Now",
        Callback = function()
            local target = getNearestGoalpost()
            if target then
                local cam = workspace.CurrentCamera
                local lookDir = (target - cam.CFrame.Position).Unit
                cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + lookDir)
                Notify("QUANTUM", "Aimed at goalpost!")
            else
                Notify("QUANTUM", "No goalpost found")
            end
        end
    })

    Tab:AddSection("Auto Catch")

    Tab:AddToggle("AutoCatch", {
        Title = "Enable Auto Catch",
        Default = false,
        Callback = function(v)
            Settings.AutoCatch = v
            Notify("QUANTUM", "Auto Catch: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("CatchRange", {
        Title = "Catch Range (studs)",
        Default = 4,
        Min = 1,
        Max = 10,
        Rounding = 0,
        Callback = function(v) Settings.CatchRange = v end
    })

    Tab:AddSection("Auto Swat")

    Tab:AddToggle("AutoSwat", {
        Title = "Enable Auto Swat",
        Default = false,
        Callback = function(v)
            Settings.AutoSwat = v
            Notify("QUANTUM", "Auto Swat: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("SwatRange", {
        Title = "Swat Range (studs)",
        Default = 4,
        Min = 1,
        Max = 10,
        Rounding = 0,
        Callback = function(v) Settings.SwatRange = v end
    })

    Tab:AddSection("Auto Rush")

    Tab:AddToggle("AutoRush", {
        Title = "Auto Rush",
        Default = false,
        Callback = function(v)
            Settings.AutoRush = v
            Notify("QUANTUM", "Auto Rush: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddToggle("AutoRushPredict", {
        Title = "Auto Rush Predictions",
        Default = false,
        Callback = function(v)
            Settings.AutoRushPredict = v
            Notify("QUANTUM", "Auto Rush Predictions: " .. (v and "On" or "Off"))
        end
    })

    Tab:AddSlider("AutoRushDelay", {
        Title = "Auto Rush Delay (seconds)",
        Default = 0,
        Min = 0,
        Max = 15,
        Rounding = 1,
        Callback = function(v) Settings.AutoRushDelay = v end
    })
end

-- ==========================================
-- 7. EXTRAS TAB
-- ==========================================
do
    local Tab = Tabs.Extras

    Tab:AddSection("VIP Animations")

    for _, emote in ipairs(VIP_EMOTES) do
        Tab:AddButton({
            Title = emote:sub(1,1):upper() .. emote:sub(2),
            Callback = function() playVipEmote(emote) end
        })
    end

    Tab:AddSection("Weather & Wind")

    Tab:AddSlider("WindSpeed", {
        Title = "Wind Speed (MPH)",
        Default = 0,
        Min = 0,
        Max = 30,
        Rounding = 0,
        Callback = function(v)
            pcall(function()
                game:GetService("ReplicatedStorage").Events.Weather:FireServer('Wind', v)
            end)
            Notify("QUANTUM", "Wind Speed: " .. tostring(v) .. " MPH")
        end
    })

    Tab:AddSection("Scoreboard")

    Tab:AddToggle("ShowScoreboard", {
        Title = "Show / Hide Scoreboard",
        Default = true,
        Callback = function(v)
            local pg = player:FindFirstChild("PlayerGui")
            if not pg then return end
            for _, gui in pairs(pg:GetChildren()) do
                if gui.Name:lower():find("scoreboard") or gui.Name:lower():find("hud") or gui.Name:lower():find("score") then
                    gui.Enabled = v
                end
            end
            Notify("QUANTUM", "Scoreboard: " .. (v and "Shown" or "Hidden"))
        end
    })

    Tab:AddSection("Score Manipulation")

    local scoreButtons = {
        { "+1 Home Score",  "+1",  true  },
        { "+7 Home Score",  "+7",  true  },
        { "+3 Home Score",  "+3",  true  },
        { "+1 Away Score",  "+1",  false },
        { "+7 Away Score",  "+7",  false },
        { "+3 Away Score",  "+3",  false },
    }

    for _, data in ipairs(scoreButtons) do
        local label, amount, isHome = data[1], data[2], data[3]
        Tab:AddButton({
            Title = label,
            Callback = function()
                pcall(function()
                    local remote = game.ReplicatedStorage.Remotes.GameManager["Events/Functions"].Event
                    remote:FireServer(amount, isHome)
                end)
                Notify("QUANTUM", label)
            end
        })
    end
end

-- ==========================================
-- SAVE MANAGER & INTERFACE MANAGER SETUP
-- ==========================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreList({ "QuickTPKey" })

InterfaceManager:SetFolder("QUANTUM")
SaveManager:SetFolder("QUANTUM/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Extras)
SaveManager:BuildConfigSection(Tabs.Extras)

SaveManager:LoadAutoloadConfig()

-- ==========================================
-- LOADED NOTIFICATION
-- ==========================================
Fluent:Notify({
    Title = "QUANTUM",
    Content = "Script loaded! QuantumRise.gg",
    SubContent = "v1.0 — Fluent UI",
    Duration = 5
})
