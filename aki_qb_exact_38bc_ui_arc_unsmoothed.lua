-- AKI QB adapter for Place 84324024961695.
-- Power comes from Football.BallData.Power; R/F requests game power changes.
-- Legacy AngleBased, DesiredPower, bounds and spawn-offset settings are unused.
getgenv().QBAimbotSettings = {
	Enabled = true,
	ToggleKeybind = 'Q',
	AngleBased = false,
	DesiredAngle = 30,
	YOffset = 1.25,
	XZOffset = 0,
	PowerBased = true,
	DesiredPower = 94,
	BoundsTolerance = 15,
	maxAirTime = 20,
	JumpPassKeybind = 'LeftControl',
	JumpPassHeight = 6.36+1.65,
	MaxYOffset = 12
}

getgenv().ballSpawnOffset = Vector3.new(0,3,0)

getgenv().ModeConfigs = {
	Dot = {
		['stationary']    = {YOffset=0,   XZOffset=0  },
		['streak']        = {YOffset=9,   XZOffset=1.5},
		['post/corner']   = {YOffset=5,   XZOffset=.5 },
		['slant']         = {YOffset=0,   XZOffset=.5 },
		['in/out']        = {YOffset=0,   XZOffset=.5 },
		['curl/comeback'] = {YOffset=0,   XZOffset=0  },
	},
	Dive = {
		['stationary']    = {YOffset=0,   XZOffset=0  },
		['streak']        = {YOffset=9.5, XZOffset=.5 },
		['post/corner']   = {YOffset=8.5, XZOffset=.5 },
		['slant']         = {YOffset=8.5, XZOffset=.5 },
		['in/out']        = {YOffset=0,   XZOffset=.5 },
		['curl/comeback'] = {YOffset=0,   XZOffset=0  },
	},
	Mag = {
		['stationary']    = {YOffset=0,   XZOffset=0  },
		['streak']        = {YOffset=10,  XZOffset=.5 },
		['post/corner']   = {YOffset=10,  XZOffset=.5 },
		['slant']         = {YOffset=0,   XZOffset=.5 },
		['in/out']        = {YOffset=0,   XZOffset=.5 },
		['curl/comeback'] = {YOffset=0,   XZOffset=0  },
	}
}


-- User-provided movement limits. Catch radius and reaction times remain estimates.
getgenv().SmartFitSettings = {
    MaxRunSpeed = 23, MaxJumpHeight = 10, AutoPower = true, Power100Only = false, PowerSettleSeconds = 0.25, AutoPowerChangeInterval = 1.25, AutoPowerThrowWindow = 0.75,
    AccelerationClamp = 40, -- noise filter, not a claimed game acceleration
    MaxTurnRate = 3, TurnHorizon = 0.25, ReceiverAccelerationHorizon = 0.25,
    ReceiverTurnHorizon = 0.12, ReceiverMaxTurnAngle = 0.2, PredictCatchShoulder = true,
    DeepTargetHeight = 9, InitialReleaseDelay = 0.04, MaxReleaseDelay = 0.2,
    SlantHeightBoost = 3.5, DeepHeightBoost = 1, FadeHeightExtra = 0.75,
    OutHeightExtra = 4.0, InHeightExtra = 3.5, OutForwardLead = 2.5, InForwardLead = 2.0,
    DiagonalHeightExtra = 0.75, DiagonalLeadExtra = 0.5,
    ReturningHeightExtra = 0.5,
    JointShoulderSearch = true,
    PhysicalCatchLimits = true, AllowStyleReach = true, CoveredShortLobs = true,
    AdaptiveExtraLead = true, BlendRouteHeight = true, ExtraHeightCandidate = true,
    ComebackHeightExtra = 0.75,
    StationaryHeightExtra = 1.5,
    JumpThrow = false,
    RefineMissingFit = true,
    OverTopShoulder = true,
    OpenReceiverNoExtraLead = true, OpenReceiverDistance = 24,
    TimedJumpReach = true,
    PredictDiveReach = true, DBAddedDiveReaction = 0.1,
    BackEndZoneEnabled = true, EndZoneInset = 4,
    DeepCatchHeightExtra = 3.25, DeepForwardLead = 4.0,
    StreakHeightExtra = 1.0, StreakLeadExtra = 1.75,
    DeepReceiverReachExtra = 1.25, -- aim-tuning allowance; not a measured catch hitbox
    PreferDeepArc = true, DeepArcAngle = 40, DeepMaxAngle = 50, DeepArcWeight = 0.5, DeepMinDescent = 8,
    CatchRadius = 3, ReachBelow = 3, VerticalCatchPadding = 0.75,
    ReachAccelerationAllowance = 6, -- estimated reserve for a DB starting pursuit
    WRReactionTime = 0.18, DBReactionTime = 0,
    MomentumReach = true, DBMomentumReaction = 0.06, DBPursuitAcceleration = 60,
    LatencyAllowance = 0.08, -- extra time for DB reach uncertainty
    ChestRange = 65, ChestLeadStuds = 1.5, ChestSideStuds = 1.5, ChestMaxAngle = 35,
    ShadeDistance = 18, ShadePlacement = true, ShadeLeadStuds = 1.5, StrictShoulder = true,
    LeadStuds = 4, SideStuds = 4, MaxAdjustment = 6,
    MaxFlightTime = 4.5, SafetyMargin = 0.75, SamplePadding = 0.75,
    FieldBoundaryChecks = true,
    ReelBoundary = true, ReelReach = 2, ReelLandingInset = 0.5,
    BoundsInset = 2, UpdateInterval = 0.075, PowerImprovement = 0.75,
    RequireClear = false, CancelUnsafe = false, PreferStyleWhenCovered = true,
    ExclusiveWindow = true, CatchWindowSeconds = 0.015, ExclusiveSafetyMargin = 0.15,
    DiveReachReserve = 0.5, VerticalReachReserve = 0.25,
    ContactGeometry = true, GeometryHorizon = 0.25, GeometryPadding = 0.25,
    DefenderChecks = true, AllDefenders = true, -- analyze every defender for placement; coverage does not cancel throws
}
local fit = getgenv().SmartFitSettings

local QBAimbotSettings = getgenv().QBAimbotSettings
local ModeConfigs = getgenv().ModeConfigs
local get = function(name) return game:GetService(name) end
local players, ws, rs = get('Players'), get('Workspace'), get('ReplicatedStorage')
local rus, uis = get('RunService'), get('UserInputService')
local plr = players.LocalPlayer
local v3, v2, keys = Vector3, Vector2, Enum.KeyCode
-- This place uses FootballService.RE.Event and a Direction table for passes.
local function child(parent, name)
    local result = parent:WaitForChild(name, 15)
    assert(result, '[AKI QB] Missing game object: ' .. name)
    return result
end
local shared = child(child(child(rs, 'GameLibraries'), 'Shared'), 'SharedLibraries')
local physics = require(child(shared, 'FootballPhysics'))
local event = child(child(child(child(child(rs, 'GamePackages'), 'Knit'), 'Services'), 'FootballService'), 'RE')
event = child(event, 'Event')
assert(type(hookmetamethod) == 'function' and type(getnamecallmethod) == 'function',
    '[AKI QB] This script requires hookmetamethod and getnamecallmethod support.')


local function create(class, parent, props)
	if not class then return end
	props = props or {}
	local obj = Instance.new(class, parent)
	for prop, val in pairs(props) do obj[prop] = val end
	return obj
end

-- //--------------------------------------------------
-- // GUI
-- //--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "QBAimbot"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Enabled = false
gui.Parent = gethui and gethui() or plr.PlayerGui

local Cards = Instance.new("Frame")
Cards.Name = "Cards"
Cards.Size = UDim2.new(0, 810, 0, 70)
Cards.Position = UDim2.new(0.5, -405, 0, 12)
Cards.BackgroundTransparency = 1
Cards.Parent = gui

local cardLayout = Instance.new("UIListLayout")
cardLayout.FillDirection = Enum.FillDirection.Horizontal
cardLayout.Padding = UDim.new(0, 6)
cardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
cardLayout.Parent = Cards

local function makeCard(name)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(0, 74, 0, 68)
	frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = Cards

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(0, 180, 255)
	stroke.Thickness = 1.2

	local titleLbl = Instance.new("TextLabel", frame)
	titleLbl.Size = UDim2.new(1, 0, 0.38, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = name:upper()
	titleLbl.TextColor3 = Color3.fromRGB(0, 180, 255)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextScaled = true

	local valueLbl = Instance.new("TextLabel", frame)
	valueLbl.Name = name
	valueLbl.Size = UDim2.new(1, 0, 0.62, 0)
	valueLbl.Position = UDim2.new(0, 0, 0.38, 0)
	valueLbl.BackgroundTransparency = 1
	valueLbl.Text = "—"
	valueLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueLbl.Font = Enum.Font.Gotham
	valueLbl.TextScaled = true

	return frame
end

makeCard("Power")
makeCard("Mode")
makeCard("Route")
makeCard("Target")
makeCard("Airtime")
makeCard("Angle")
makeCard("Fit")
makeCard("Suggest")
makeCard("Speed")
makeCard("Jump")

-- Buttons row
local Mobile = Instance.new("Frame")
Mobile.Size = UDim2.new(0, 260, 0, 36)
Mobile.Position = UDim2.new(0.5, -130, 0, 88)
Mobile.BackgroundTransparency = 1
Mobile.Parent = gui

local function makeBtn(name, txt, xPos, w)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, w or 70, 1, 0)
	btn.Position = UDim2.new(0, xPos, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
	btn.BorderSizePixel = 0
	btn.Text = txt
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Parent = Mobile
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local lockBtn    = makeBtn("Lock",    "🔓 Lock", 0,   76)
local modeBtn    = makeBtn("Switch",  "↔ Mode",  82,  76)
local powerUpBtn = makeBtn("PowerUp", "R ▲",     164, 44)
local powerDnBtn = makeBtn("PowerDn", "F ▼",     212, 44)

local tipLbl = Instance.new("TextLabel")
tipLbl.Size = UDim2.new(0, 260, 0, 18)
tipLbl.Position = UDim2.new(0.5, -130, 0, 130)
tipLbl.BackgroundTransparency = 1
tipLbl.Text = "R/F = Power  |  Q = Lock  |  T = Mode"
tipLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
tipLbl.Font = Enum.Font.Gotham
tipLbl.TextScaled = true
tipLbl.Parent = gui

-- //--------------------------------------------------
-- // BEAM SETUP
-- //--------------------------------------------------

local beamAttPart = create('Part', ws, {
	Anchored=true, CanCollide=false, CanQuery=false, CanTouch=false,
	Transparency=1, Size=v3.new(1,1,1), Position=v3.new(0,0,0)
})
local beamAtt0 = create('Attachment', beamAttPart)
local beamAtt1 = create('Attachment', beamAttPart)
local beam = create("Beam", nil, {
	Attachment0 = beamAtt0,
	Attachment1 = beamAtt1,
	Segments    = 50,
	Width0      = 0.4,
	Width1      = 0.4,
	FaceCamera  = true,
	LightEmission = 1,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0.1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1,   0.8),
	}),
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	}),
})

local highlight = Instance.new("Highlight")
highlight.FillColor    = Color3.fromRGB(82, 206, 255)
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)

local env = getgenv()
local previous = env.AKI_QB_84324024961695
if previous and previous.Cleanup then previous.Cleanup() end
local bridge = previous or {}
env.AKI_QB_84324024961695 = bridge
local connections = {}
local active = true
local selected, lockedTarget
local locked = false
local modes = {'Smart', 'Dot', 'Dive', 'Mag'}
local modeIndex = 1
local currentSolution
local blockedUntil = 0
local nearestDBLbl = create('TextLabel', gui, {
    Size = UDim2.new(0, 810, 0, 30), Position = UDim2.new(0.5, -405, 0, 246),
    BackgroundTransparency = 0.3, BackgroundColor3 = Color3.fromRGB(15, 20, 28),
    TextColor3 = Color3.fromRGB(240, 240, 240), Font = Enum.Font.Gotham,
    TextSize = 13, TextWrapped = true, Text = 'Nearest DB to WR: -',
})
local detailLbl = create('TextLabel', gui, {
    Size = UDim2.new(0, 720, 0, 22), Position = UDim2.new(0.5, -360, 0, 170),
    BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(240, 240, 240),
    Font = Enum.Font.Gotham, TextSize = 13, Text = 'Smart Fit v93',
})
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end
bridge.Cleanup = function()
    active = false
    bridge.Rewrite = nil
    for _, connection in ipairs(connections) do connection:Disconnect() end
    gui:Destroy()
    beam:Destroy()
    beamAttPart:Destroy()
    highlight:Destroy()
end
env.AKI_QB_Unload = bridge.Cleanup

local function getBall()
    local character = plr.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    local ball = character and character:FindFirstChild('Football')
    if not humanoid or humanoid.Health <= 0 or not ball or not ball:IsA('BasePart') then return end
    local data = ball:FindFirstChild('BallData')
    local throwable = data and data:FindFirstChild('Throwable')
    local power = data and data:FindFirstChild('Power')
    local punt = data and data:FindFirstChild('Punt')
    if not throwable or not throwable.Value or not power or (punt and punt.Value) then return end
    return ball, power.Value
end

-- ParkContext conventions verified in place 74386491549424.
local function isPark() return ws:GetAttribute('WorldMode')=='Park' or game.PlaceId==74386491549424 end
local function gameTeam(player)
    if isPark() then
        local team=player:GetAttribute('ParkFieldTeam')
        if team=='Home' or team=='Away' then return team end
        return nil
    end
    return not player.Neutral and player.Team or nil
end
local function sameGame(player)
    if not isPark() then return true end
    local field=plr:GetAttribute('ParkFieldName')
    return type(field)=='string' and field~='' and player:GetAttribute('ParkFieldName')==field
        and player:GetAttribute('ParkFieldMatchActive')==true
end
local cachedParkField,cachedParkBounds
local function gameBounds()
    if not isPark() then
        local field=ws:FindFirstChild('Field')
        local part=field and field:FindFirstChild('FieldSize')
        return part and part:IsA('BasePart') and part or nil
    end
    local fields=ws:FindFirstChild('Minigames')
    local fieldName=plr:GetAttribute('ParkFieldName')
    local field=fields and type(fieldName)=='string' and fields:FindFirstChild(fieldName)
    if not field then return nil end
    if field==cachedParkField and cachedParkBounds then return cachedParkBounds end
    local localModel=field:FindFirstChild('Local')
    local lines=localModel and localModel:FindFirstChild('Field Lines')
    local boundaries=lines and lines:FindFirstChild('Boundaries')
    local inner=boundaries and boundaries:FindFirstChild('Inner')
    if not inner then return nil end
    local ends={}
    for _,part in ipairs(inner:GetChildren()) do
        if part.Name=='End Line' and part:IsA('BasePart') then table.insert(ends,part) end
    end
    if #ends~=2 then return nil end
    local a,b=ends[1],ends[2]
    local center=(a.Position+b.Position)*.5
    local length=(a.Position-b.Position).Magnitude
    local width=math.min(math.max(a.Size.X,a.Size.Z),math.max(b.Size.X,b.Size.Z))
    if length<10 or width<10 then return nil end
    cachedParkField=field
    cachedParkBounds={CFrame=CFrame.lookAt(center,Vector3.new(b.Position.X,center.Y,b.Position.Z)),
        Size=Vector3.new(width,1,length)}
    return cachedParkBounds
end

local function targetRoot(player)
    if not player or player == plr or player.Parent ~= players or not sameGame(player) or not gameTeam(player) or gameTeam(player) ~= gameTeam(plr) then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    local root = character and character:FindFirstChild('HumanoidRootPart')
    if humanoid and humanoid.Health > 0 and root then return root end
end

local function findTarget()
    if locked and targetRoot(lockedTarget) then return lockedTarget end
    if locked then locked, lockedTarget = false, nil end
    local camera = ws.CurrentCamera
    if not camera then return end
    local mouse = uis:GetMouseLocation()
    local best, distance = nil, math.huge
    for _, player in ipairs(players:GetPlayers()) do
        local root = targetRoot(player)
        if root then
            local point, visible = camera:WorldToScreenPoint(root.Position)
            if visible and point.Z > 0 then
                local delta = (v2.new(point.X, point.Y) - mouse).Magnitude
                if delta < distance then best, distance = player, delta end
            end
        end
    end
    return best
end

local function routeFor(root, origin)
    local velocity = root.AssemblyLinearVelocity * v3.new(1, 0, 1)
    if velocity.Magnitude < 1 then return 'stationary', velocity end
    local away = (root.Position - origin) * v3.new(1, 0, 1)
    if away.Magnitude < 0.01 then return 'stationary', velocity end
    local dot = velocity.Unit:Dot(away.Unit)
    if dot >= 0.8 then return 'streak', velocity end
    if dot >= 0.45 then return 'post/corner', velocity end
    if dot >= 0.2 then return 'slant', velocity end
    if dot >= -0.2 then return 'in/out', velocity end
    return 'curl/comeback', velocity
end

-- Find the earliest ballistic intercept at the actual server-selected power.
-- Bracketing avoids NaN angles and unbounded recursive retries.
local function intercept(origin, target, movement, speed, gravity, lifetime)
    local delta = target - origin
    local function velocityAt(t)
        return delta / t + movement + v3.new(0, gravity * t / 2, 0)
    end
    local function errorAt(t) return velocityAt(t).Magnitude - speed end
    local low = 0.01
    local previousError = errorAt(low)
    for i = 1, 240 do
        local high = 0.01 + (lifetime - 0.01) * i / 240
        local nextError = errorAt(high)
        if previousError >= 0 and nextError <= 0 then
            for _ = 1, 24 do
                local middle = (low + high) / 2
                if errorAt(middle) > 0 then low = middle else high = middle end
            end
            local time = (low + high) / 2
            return velocityAt(time), time
        end
        low, previousError = high, nextError
    end
end

local ReceiverPhysics = {}
function ReceiverPhysics.catchDuration(rating,multiplier)
    rating=tonumber(rating) or 0;multiplier=tonumber(multiplier) or 1
    if rating~=rating then rating=0 end
    if multiplier~=multiplier then multiplier=1 end
    return math.clamp(math.max(-.25+1.35*math.clamp(rating,0,99)/99,.1)*math.clamp(multiplier,0,1.2),.1,1.32)
end
function ReceiverPhysics.stadiumYards(studs) return studs/3.65 end
-- Exact launch expression from MovementController.Dive. The selected profile
-- and live ATH/badge values must be supplied; do not assume a receiver dives.
function ReceiverPhysics.diveLaunch(direction, walkSpeed, athleticism, badgeMultiplier, profile)
    local multiplier = (profile.LINEAR_POWER - 0.25 + athleticism / 99 * 0.25)
        * math.clamp(badgeMultiplier or 1, 1, 1.2)
    return Vector3.new(direction.X * walkSpeed * multiplier,
        math.max(profile.VERTICAL_POWER, 0), direction.Z * walkSpeed * multiplier)
end
function ReceiverPhysics.jumpLaunch(height, gravity)
    return math.sqrt(2 * math.max(gravity, 0) * math.max(height, 0))
end
function ReceiverPhysics.landingTime(height, verticalSpeed, gravity)
    if gravity <= 0 then return 0 end
    return math.max(0, (verticalSpeed + math.sqrt(verticalSpeed^2 + 2*gravity*math.max(height,0))) / gravity)
end

-- Reproduce the saved MovementController's next-jump badge conditions.
function ReceiverPhysics.badgeJump(state, nearOpponent, nearReceiver)
    local function finite(value, fallback)
        return type(value)=='number' and value==value and math.abs(value)<math.huge and value or fallback
    end
    local base=finite(state.BaseJump,0)
    if base<=0 then return math.max(0,finite(state.LiveJump,0)),false,0 end
    local top=finite(state.TopSpeed,23)
    if top<=0 then top=23 end
    local bonus=0
    if state.Speed>=top*.95 and state.WalkSpeed>=top*.95 then
        bonus=finite(state.VerticalFlyer,0)
    end
    if not state.HasFootball then
        if nearOpponent then bonus=bonus+finite(state.Ladder,0) end
        if nearReceiver then bonus=bonus+math.max(0,finite(state.BallHawk,0)) end
    end
    return math.max(0,base+bonus),true,bonus
end
-- Relative to a standard R6 torso (2x2) and two-stud arms.
-- This is a reach estimate, not a server catch-hitbox measurement.
function ReceiverPhysics.bodyReach(width,height,leftLength,rightLength)
    for _,n in ipairs({width,height,leftLength,rightLength}) do
        if type(n)~='number' or n~=n or n<=0 or n>10 then return 0,0,false end
    end
    if not width or not height or not leftLength or not rightLength then return 0,0,false end
    local arm=math.min(leftLength,rightLength)
    return math.clamp(width*.5+arm-3,-1,1),math.clamp(height*.5+arm-3,-1,1),true
end

-- Pure prediction math. Reach values are tuning estimates, not verified hitboxes.
local Smart = {}
local ContactGeometry
function Smart.topSpeed(value,fallback)
    if type(value)=='number' and value==value and value>0 and value<math.huge then return value end
    return fallback or 23
end
function Smart.speedLimit(sample,cfg)
    return Smart.topSpeed(sample.TopSpeed,cfg.MaxRunSpeed)
end
function Smart.arcPenalty(angle, descendingSpeed, chestPass, cfg)
    if chestPass or not cfg.PreferDeepArc then return 0 end
    -- Keep catch location separate from the flight shape. Prefer a moderate
    -- descending deep pass, not a flat bullet or a very long sky ball.
    local angleCost = math.abs(angle - cfg.DeepArcAngle) * cfg.DeepArcWeight
    local risingCost = math.max(0, cfg.DeepMinDescent - descendingSpeed) * 0.15
    return angleCost + risingCost
end
function Smart.cap(velocity, maximum)
    local flat = Vector3.new(velocity.X, 0, velocity.Z)
    return flat.Magnitude > maximum and flat.Unit * maximum or flat
end

function Smart.runDistance(sample, time, cfg)
    local maximum=Smart.speedLimit(sample,cfg)
    if sample.Airborne then
        local flying = math.min(time, sample.LandingTime or 0)
        local afterSpeed = sample.Diving and 0 or math.min(sample.Velocity.Magnitude, maximum)
        return sample.Velocity.Magnitude * flying + afterSpeed * math.max(0,time-flying)
    end
    local speed = math.min(sample.Velocity.Magnitude, maximum)
    local acceleration = sample.Acceleration or 0
    if math.abs(acceleration) < 0.01 then return speed * time end
    local limit = acceleration > 0 and maximum or 0
    -- Recent acceleration is reliable only briefly for the intended receiver.
    -- After that window, continue at the resulting speed instead of inventing
    -- a full-flight stop or acceleration. DB pursuit keeps its existing model.
    local window=math.min(time,math.max(0,sample.AccelerationHorizon or time))
    local rampTime = math.min(window, math.max(0, (limit - speed) / acceleration))
    local finalSpeed=math.clamp(speed+acceleration*rampTime,0,maximum)
    return speed * rampTime + 0.5 * acceleration * rampTime * rampTime
        + limit * (window - rampTime) + finalSpeed * (time-window)
end
function Smart.travel(sample, time, cfg)
    if sample.Airborne then
        local airTime = math.min(time, sample.LandingTime or 0)
        local vertical = (sample.VerticalSpeed or 0)*airTime - 0.5*(sample.CharacterGravity or 196.2)*airTime*airTime
        local horizontal = sample.Velocity.Magnitude > .01 and sample.Velocity.Unit * Smart.runDistance(sample,time,cfg) or Vector3.new(0,0,0)
        return horizontal + Vector3.new(0,vertical,0)
    end
    if sample.Velocity.Magnitude < 0.01 then return Vector3.new(0, 0, 0) end
    local turn = sample.TurnRate or 0
    if math.abs(turn) < 0.01 then return sample.Velocity.Unit * Smart.runDistance(sample, time, cfg) end
    -- Extrapolate a recent cut briefly, then continue along the resulting
    -- heading. Do not curve around forever during a long throw.
    local maxHorizon = sample.TurnHorizon or cfg.TurnHorizon or 0.25
    if sample.MaxTurnAngle then maxHorizon=math.min(maxHorizon,sample.MaxTurnAngle/math.abs(turn)) end
    local cached = sample.TurnMotionCache
    if time >= maxHorizon and cached and cached.Velocity == sample.Velocity
        and cached.Acceleration == sample.Acceleration and cached.AccelerationHorizon == sample.AccelerationHorizon and cached.Turn == turn
        and cached.Horizon == maxHorizon and cached.MaxSpeed == Smart.speedLimit(sample,cfg) then
        return cached.Prefix + cached.Heading * (Smart.runDistance(sample,time,cfg)-cached.Distance)
    end
    local horizon = math.min(time, maxHorizon)
    local result = Vector3.new(0, 0, 0)
    local direction = sample.Velocity.Unit
    local function heading(t)
        local angle = turn * t
        return Vector3.new(direction.X * math.cos(angle) - direction.Z * math.sin(angle), 0,
            direction.X * math.sin(angle) + direction.Z * math.cos(angle))
    end
    for i = 1, 6 do
        local a, b = horizon * (i - 1) / 6, horizon * i / 6
        result = result + heading((a + b) / 2) * (Smart.runDistance(sample, b, cfg) - Smart.runDistance(sample, a, cfg))
    end
    local finalHeading, distance = heading(horizon), Smart.runDistance(sample,horizon,cfg)
    if time >= maxHorizon then
        sample.TurnMotionCache = {Velocity=sample.Velocity,Acceleration=sample.Acceleration,AccelerationHorizon=sample.AccelerationHorizon,Turn=turn,
            Horizon=maxHorizon,MaxSpeed=Smart.speedLimit(sample,cfg),Prefix=result,Heading=finalHeading,Distance=distance}
    end
    return result + finalHeading * (Smart.runDistance(sample, time, cfg) - distance)
end
function Smart.jumpCapacity(sample,cfg)
    local predicted=sample.PredictedJumpHeight
    if type(predicted)=='number' and predicted==predicted and predicted>=0 and predicted<math.huge then return predicted end
    return math.clamp(sample.JumpHeight or cfg.MaxJumpHeight,0,cfg.MaxJumpHeight)
end
function Smart.jump(sample, time, cfg)
    -- The active jump is already represented in travel(); don't add another
    -- full jump on top of the predicted airborne root position.
    if sample.Airborne then return 0 end
    -- Use the latest live jump setting; no invented speed/jump conversion.
    return Smart.jumpCapacity(sample,cfg)
end
function Smart.timedJump(sample,time,reaction,cfg)
    local earliest=math.max(0,reaction or 0,sample.JumpCooldownRemaining or 0)
    if sample.Airborne then
        if sample.Diving or type(sample.LandingTime)~='number' or sample.LandingTime<0 then return 0 end
        earliest=math.max(earliest,sample.LandingTime+math.max(0,reaction or 0))
    end
    local height=Smart.jumpCapacity(sample,cfg)
    local gravity=math.max(.01,sample.CharacterGravity or 196.2)
    local launch=math.sqrt(2*gravity*height)
    local riseTime=math.min(math.max(0,time-earliest),launch/gravity)
    return math.max(0,launch*riseTime-.5*gravity*riseTime*riseTime)
end
function Smart.arcs(origin, target, movement, speed, gravity, lifetime, cfg, travelCache)
    local dx,dy,dz=target.X-origin.X,target.Y-origin.Y,target.Z-origin.Z
    local speedSquared=speed*speed
    local function components(t,index)
        local x,y,z
        if cfg then
            local displacement=index and travelCache and travelCache[index]
            if not displacement then
                displacement=Smart.travel(movement,t+(movement.ReleaseDelay or 0),cfg)
                if index and travelCache then travelCache[index]=displacement end
            end
            x,y,z=displacement.X,displacement.Y,displacement.Z
        else x,y,z=movement.X*t,movement.Y*t,movement.Z*t end
        return (dx+x)/t,(dy+y)/t+gravity*t/2,(dz+z)/t
    end
    local function errorAt(t,index)
        local x,y,z=components(t,index)
        return x*x+y*y+z*z-speedSquared
    end
    local results={}
    local low,oldError=.01,errorAt(.01,0)
    local minimumError,minimumTime=oldError,low
    local step=(lifetime-.01)/120
    for i=1,120 do
        local high=.01+(lifetime-.01)*i/120
        local nextError=errorAt(high,i)
        if nextError<minimumError then minimumError,minimumTime=nextError,high end
        if (oldError>0 and nextError<=0) or (oldError<0 and nextError>=0) then
            local a,b,sign=low,high,oldError>0
            for _=1,22 do
                local middle=(a+b)/2
                if (errorAt(middle)>0)==sign then a=middle else b=middle end
            end
            local t=(a+b)/2
            local x,y,z=components(t)
            table.insert(results,{Velocity=Vector3.new(x,y,z),Time=t})
        end
        low,oldError=high,nextError
    end
    -- Refine narrow root intervals near maximum range that the coarse scan misses.
    if #results==0 and minimumTime>.01 and minimumTime<lifetime then
        local left,right=math.max(.01,minimumTime-step),math.min(lifetime,minimumTime+step)
        local a,b=left,right
        for _=1,28 do
            local m1,m2=a+(b-a)/3,b-(b-a)/3
            if errorAt(m1)<errorAt(m2) then b=m2 else a=m1 end
        end
        local mid=(a+b)/2
        local value=errorAt(mid)
        local function add(t)
            local x,y,z=components(t)
            table.insert(results,{Velocity=Vector3.new(x,y,z),Time=t})
        end
        if value<=0 then
            for _,edge in ipairs({left,right}) do
                if errorAt(edge)>0 then
                    local inner,outer=mid,edge
                    for _=1,24 do
                        local t=(inner+outer)/2
                        if errorAt(t)<=0 then inner=t else outer=t end
                    end
                    add((inner+outer)/2)
                end
            end
        elseif value<=speedSquared*1e-10 then add(mid) end
        table.sort(results,function(a,b) return a.Time<b.Time end)
    end
    return results
end

-- Shared across all candidate arcs/powers in one live snapshot, never across frames.
function Smart.diveWindows(sample,time,reaction,extraDelay,cfg)
    local windows={}
    if not cfg.PredictDiveReach or not sample.CanDive or sample.Diving
        or not sample.DiveLaunchSpeed or not sample.DiveVerticalSpeed then return windows end
    local earliest=math.max(0,reaction or 0)+math.max(0,extraDelay or 0)
    local gravity=math.max(.01,sample.CharacterGravity or 196.2)
    -- A small fixed set of dive ages, reused across all arcs in this snapshot.
    for _,age in ipairs({.02,.05,.1,.2}) do
        local start=time-age
        if start>=earliest then
            local center=sample.Position+Smart.travel(sample,start,cfg)
            local rise=sample.DiveVerticalSpeed*age-.5*gravity*age*age
            local airborneHeight=sample.Airborne and center.Y-sample.Position.Y or 0
            -- Stop at modeled ground contact; no sliding distance is invented.
            if airborneHeight+rise>=0 and (not sample.Airborne or start<(sample.LandingTime or 0)) then
                windows[#windows+1]={Center=center+Vector3.new(0,rise,0),
                    Reach=sample.DiveLaunchSpeed*age+math.max(0,cfg.CatchRadius+(sample.BodyHorizontal or 0)),
                    Height=(sample.ChestOffset or 0)+(cfg.VerticalCatchPadding or 0)+(sample.BodyVertical or 0),Below=cfg.ReachBelow}
            end
        end
    end
    return windows
end
function Smart.envelopes(defenders, time, cfg)
    defenders.ReachCache = defenders.ReachCache or {}
    if defenders.ReachCache[time] then return defenders.ReachCache[time] end
    local result = {}
    local guard = cfg.ExclusiveWindow and (cfg.CatchWindowSeconds or .15) or 0
    for _, defender in ipairs(defenders) do
        local center, reach
        if defender.Airborne then
            local physicalTime=math.max(0,time-(cfg.LatencyAllowance or 0))
            center = defender.Position + Smart.travel(defender, physicalTime, cfg)
            local afterLanding = math.max(0, physicalTime - (defender.LandingTime or 0))
            -- Current airborne motion is measured; future steering is uncertain.
            reach = math.max(0,cfg.CatchRadius+(defender.BodyHorizontal or 0)) + math.max(Smart.speedLimit(defender,cfg),defender.Velocity.Magnitude) * (afterLanding+(cfg.LatencyAllowance or 0)+guard)
                + math.min(time, defender.LandingTime or 0) * (cfg.AirSteerAllowance or 3)
        else
            local reaction = math.min(time+guard, cfg.MomentumReach and (cfg.DBMomentumReaction or .06) or cfg.DBReactionTime)
            center = defender.Position + Smart.travel(defender, reaction, cfg)
            local observed = math.max(0, Smart.runDistance(defender,time+guard,cfg)-Smart.runDistance(defender,reaction,cfg))
            local pursuit = {Velocity=defender.Velocity,TopSpeed=defender.TopSpeed,
                Acceleration=math.max(0,defender.Acceleration or 0)+(cfg.ReachAccelerationAllowance or 0)}
            local possible = math.max(0, Smart.runDistance(pursuit,time+guard,cfg)-Smart.runDistance(pursuit,reaction,cfg))
            reach = math.max(0,cfg.CatchRadius+(defender.BodyHorizontal or 0)) + math.max(observed,possible)
        end
        local jump = cfg.TimedJumpReach and Smart.timedJump(defender,time+guard,cfg.DBReactionTime,cfg)
            or Smart.jump(defender,time,cfg)
        if defender.Airborne and not cfg.TimedJumpReach and time > (defender.LandingTime or 0) then
            jump = Smart.jumpCapacity(defender,cfg)
        end
        -- Reserves are conservative tuning estimates, not measured catch/dive hitboxes.
        local diveReserve = cfg.ExclusiveWindow and (cfg.DiveReachReserve or 2) or 0
        local verticalReserve = cfg.ExclusiveWindow and (cfg.VerticalReachReserve or 1) or 0
        if defender.Airborne and guard>0 then
            verticalReserve = verticalReserve + math.abs((defender.VerticalSpeed or 0)
                -(defender.CharacterGravity or 196.2)*math.min(time,defender.LandingTime or 0))*guard
                +(defender.CharacterGravity or 196.2)*guard*guard/2
        end
        table.insert(result,{Center=center,Reach=reach+(defender.Uncertainty or 0)+cfg.SamplePadding+diveReserve,
            Height=jump+(defender.ChestOffset or 0)+(cfg.VerticalCatchPadding or 0)+verticalReserve+(defender.BodyVertical or 0),
            Below=cfg.ReachBelow+verticalReserve,Defender=defender,
            PursuitTime=math.max(0,time+guard-(cfg.MomentumReach and (cfg.DBMomentumReaction or .06) or cfg.DBReactionTime)),
            Padding=math.max(0,cfg.CatchRadius+(defender.BodyHorizontal or 0))+(defender.Uncertainty or 0)+cfg.SamplePadding+diveReserve,
            DiveWindows=Smart.diveWindows(defender,time,cfg.DBReactionTime,cfg.DBAddedDiveReaction,cfg)})
    end
    defenders.ReachCache[time]=result
    return result
end

-- Necessary reach bound along the line to the ball. A player moving away
-- must brake before reversing; use a generous estimated acceleration so this
-- does not assume slow turning or require the defender to keep their route.
function Smart.directionalMargin(envelope,dx,dz,cfg)
    local defender=envelope.Defender
    if not cfg.MomentumReach or defender.Airborne then return -math.huge end
    local distance=math.sqrt(dx*dx+dz*dz)
    if distance<.001 then return -envelope.Padding end
    local maximum=Smart.speedLimit(defender,cfg)
    local velocity=Smart.cap(defender.Velocity,maximum)
    local initial=(velocity.X*dx+velocity.Z*dz)/distance
    local acceleration=math.max(1,cfg.DBPursuitAcceleration or 60,math.abs(defender.Acceleration or 0))
    local time=envelope.PursuitTime
    local ramp=math.min(time,math.max(0,(maximum-initial)/acceleration))
    local travel=initial*ramp+.5*acceleration*ramp*ramp+maximum*(time-ramp)
    return distance-(math.max(0,travel)+envelope.Padding)
end

function Smart.clearance(origin, velocity, time, defenders, gravity, cfg, delay)
    local margin = math.huge
    local limiting
    local steps = math.max(1,math.ceil(time/.06))
    local previousTime,previousPoint=0,origin
    for i=0,steps do
        local t=math.min(time,i*.06)
        local px,py,pz=origin.X+velocity.X*t,origin.Y+velocity.Y*t-gravity*t*t/2,origin.Z+velocity.Z*t
        local sweep = cfg.AllDefenders and (math.abs(velocity.Y-gravity*t)*.03+gravity*.03*.03/2) or 0
        if cfg.ContactGeometry and ContactGeometry and t+(delay or 0)<=(cfg.GeometryHorizon or .25) then
            local point=Vector3.new(px,py,pz)
            for _,defender in ipairs(defenders) do
                if ContactGeometry.intercepts(previousPoint,point,defender,previousTime+(delay or 0),t+(delay or 0),cfg,defenders.BallRadius) then
                    if -1<margin then
                        margin=-1;limiting={name=defender.Name,seconds=t,kind='hand contact',margin=-1}
                    end
                end
            end
            previousPoint=point
        end
        previousTime=t
        local horizon=t+(delay or 0)+(cfg.LatencyAllowance or 0)
        for _, envelope in ipairs(Smart.envelopes(defenders,horizon,cfg)) do
            for _,window in ipairs(envelope.DiveWindows or {}) do
                local dy=py-window.Center.Y
                if dy>=-window.Below-sweep and dy<=window.Height+sweep then
                    local dx,dz=px-window.Center.X,pz-window.Center.Z
                    local candidate=math.sqrt(dx*dx+dz*dz)-window.Reach-cfg.SamplePadding
                    if candidate<margin then
                        margin=candidate;limiting={name=envelope.Defender.Name,seconds=t,kind='possible dive',margin=candidate}
                    end
                end
            end
            local height=py-envelope.Center.Y
            -- Cover vertical motion between samples, especially steep descending passes.
            if height>=-envelope.Below-.01-sweep and height<=envelope.Height+.01+sweep then
                local dx,dz=px-envelope.Center.X,pz-envelope.Center.Z
                local radial=math.sqrt(dx*dx+dz*dz)-envelope.Reach
                local directional=Smart.directionalMargin(envelope,dx,dz,cfg)
                local candidate=math.max(radial,directional)
                if candidate<margin then
                    margin=candidate
                    limiting={name=envelope.Defender.Name,seconds=t,kind=directional>radial and 'momentum reach' or 'reach',margin=candidate}
                end
            end
        end
    end
    if limiting then
        limiting.stage=limiting.seconds<=.25 and 'release' or
            (limiting.seconds>=math.max(.25,time-.35) and 'catch' or 'flight')
        limiting.estimated=true
    end
    return margin,limiting
end

-- Coverage dominates style when comparing the whole defense. Beyond 15 studs,
-- prefer the requested flight shape rather than adding unnecessary hang time.
function Smart.better(option, best, cfg, improvement)
    if not best then return true end
    if option.Clear ~= best.Clear then return option.Clear end
    -- When coverage cancellation is off, preserve placement/arc preferences
    -- among contested options instead of chasing a slightly less negative margin.
    if cfg.PreferStyleWhenCovered and not cfg.CancelUnsafe and not option.Clear then
        local optionStyle = option.Score - math.min(option.Margin, 15)
        local bestStyle = best.Score - math.min(best.Margin, 15)
        return optionStyle > bestStyle + (improvement or 0)
    end
    if cfg.AllDefenders then
        local difference=math.min(option.Margin,15)-math.min(best.Margin,15)
        if math.abs(difference)>.1 then return difference>0 end
    end
    return option.Score>best.Score+(improvement or 0)
end

function Smart.offsets(receiver, defenders, forward, side, flightEstimate, cfg)
    local chest = receiver.ChestPass == true
    local leadStep = chest and (cfg.ChestLeadStuds or 1.5) or cfg.LeadStuds
    local sideStep = chest and (cfg.ChestSideStuds or 1.5) or cfg.SideStuds
    local candidates = {}
    local nearest, nearestDistance
    local receiverPoint = receiver.Position + Smart.travel(receiver, flightEstimate, cfg)
    for _, defender in ipairs(defenders) do
        local relative = Smart.cap(defender.Position + Smart.travel(defender, flightEstimate, cfg) - receiverPoint, math.huge)
        if not nearestDistance or relative.Magnitude < nearestDistance then
            nearest, nearestDistance = relative, relative.Magnitude
        end
    end
    local covered = nearest and nearestDistance <= (cfg.ShadeDistance or 18)
    local shade = covered and nearest:Dot(side) or 0
    local onTop = covered and nearest:Dot(forward) >= -1
    local leads = cfg.RefinedFitPass and {-leadStep,-.5,0,.5,leadStep} or {-leadStep,0,leadStep}
    local sides = cfg.RefinedFitPass and {-sideStep,-.5,0,.5,sideStep} or {-sideStep,0,sideStep}
    for _, lead in ipairs(leads) do
        for _, lateral in ipairs(sides) do
            -- Do not lead into the nearest DB's lateral leverage.
            if cfg.AllDefenders or not covered or math.abs(shade) < 1 or lateral * shade <= 0 then
                table.insert(candidates, {Offset = forward * lead + side * lateral,
                    Kind = chest and 'Chest' or 'Lead', Bonus = 0})
            end
        end
    end
    if not chest and covered then
        local away = shade >= 0 and -1 or 1
        if math.abs(shade) < 1 and receiver.Outside then
            away = receiver.Outside:Dot(side) >= 0 and 1 or -1
        end
        for _, drop in ipairs({2, 3.5}) do
            table.insert(candidates, {Offset = forward * -drop + side * (away * 3),
                Kind = 'Back shoulder', Bonus = 2})
        end
    end
    -- A trailing DB calls for a forward over-shoulder option, not a forced
    -- back shoulder. Keep lead within the WR's modeled catch radius.
    if not chest and covered and nearest:Dot(forward) < -1 then
        local away = shade >= 0 and -1 or 1
        for _, lead in ipairs({1.5, 2.5}) do
            for _, lateral in ipairs({0, away * 1.5}) do
                table.insert(candidates, {Offset = forward * lead + side * lateral,
                    Kind = 'Over shoulder', Bonus = 2})
            end
        end
    end
    return candidates
end

function Smart.shoulder(receiver, time, cfg)
    if not cfg.ShadePlacement or not receiver.Outside then return end
    local outside = Smart.cap(receiver.Outside, math.huge)
    if outside.Magnitude < .01 then return end
    outside = outside.Unit
    local nearest, distance, nearestDefender
    local overtop, overtopDistance, overtopDefender
    local running = Smart.cap(receiver.Velocity,math.huge)
    local forward = running.Magnitude>1 and running.Unit or nil
    local projected = receiver.Position + Smart.travel(receiver, time, cfg)
    for _, defender in ipairs(receiver.ShadeDefenders or {}) do
        local relative = Smart.cap(defender.Position + Smart.travel(defender, time, cfg) - projected, math.huge)
        if relative.Magnitude <= (cfg.ShadeDistance or 18) and (not distance or relative.Magnitude < distance) then
            nearest, distance, nearestDefender = relative, relative.Magnitude, defender
        end
        if cfg.OverTopShoulder and forward and relative.Magnitude <= (cfg.ShadeDistance or 18)
            and relative:Dot(forward)>=1 and math.abs(relative:Dot(outside))>=1
            and (not overtopDistance or relative.Magnitude<overtopDistance) then
            overtop,overtopDistance,overtopDefender=relative,relative.Magnitude,defender
        end
    end
    if overtop then nearest,distance,nearestDefender=overtop,overtopDistance,overtopDefender end
    if not nearest or math.abs(nearest:Dot(outside)) < 1 then return end
    local sign = nearest:Dot(outside) > 0 and -1 or 1
    return outside * sign, sign > 0 and 'Outside shoulder' or 'Inside shoulder',
        {name=nearestDefender.Name,distance=distance,dbLateral=nearest:Dot(outside),overtop=overtop~=nil,
         requiredSide=sign>0 and 'Outside' or 'Inside'}
end

function Smart.reelBounds(point,receiver,time,height,cfg,inBounds)
    if inBounds(point) then return true end
    if not cfg.ReelBoundary or receiver.Diving then return false end
    local landingBounds=receiver.ReelBounds or inBounds
    local root=receiver.Position+Smart.travel(receiver,time,cfg)
    local reach=math.min(cfg.ReelReach or 2,math.max(0,cfg.CatchRadius+(receiver.BodyHorizontal or 0)))
    if not landingBounds(root) or Smart.cap(point-root,math.huge).Magnitude>reach then return false end
    local rise=math.max(0,height-(receiver.ChestOffset or 0)-(receiver.BodyVertical or 0)-(cfg.VerticalCatchPadding or 0))
    if rise>Smart.jumpCapacity(receiver,cfg) then return false end
    -- Conservative estimated landing: current momentum continues. Never assume
    -- that a catch stops the receiver or teleports them back into the field.
    local fall=math.sqrt(2*rise/math.max(.01,receiver.CharacterGravity or 196.2))
    if receiver.Airborne then fall=math.max(fall,math.max(0,(receiver.LandingTime or time)-time)) end
    local landing=receiver.Position+Smart.travel(receiver,time+fall,cfg)
    if not landingBounds(landing) then return false end
    return true,{estimated=true,reachStuds=Smart.cap(point-root,math.huge).Magnitude,
        landingDelay=fall,landingX=landing.X,landingZ=landing.Z}
end
function Smart.best(origin, receiver, defenders, power, multiplier, gravity, cfg, inBounds, clampToField)
    local speed = math.clamp(power * multiplier, 1, 250)
    local movement = Smart.cap(receiver.Velocity, Smart.speedLimit(receiver,cfg))
    local forward = movement.Magnitude > 1 and movement.Unit or Smart.cap(receiver.Position - origin, math.huge)
    if forward.Magnitude < 0.01 then forward = Vector3.new(0, 0, -1) else forward = forward.Unit end
    local side = Vector3.new(-forward.Z, 0, forward.X)
    local best
    local search={candidates=0,trajectories=0,noArc=0,reach=0,angle=0,shoulder=0,bounds=0,coverageRisk=0}
    local hasArc,hasReach,hasAngle,hasPlacement=false,false,false,false
    local travelCache = {} -- valid only for this immutable receiver snapshot
    local chest = receiver.ChestOffset or 0
    local deepRoute = receiver.RouteLabel == 'Streak' or receiver.RouteLabel == 'Post' or receiver.RouteLabel == 'Corner'
    local stopped = not receiver.Airborne and movement.Magnitude<2
    local chestPass = stopped or (receiver.ChestPass == true and not deepRoute)
    local estimate = math.clamp((receiver.Position - origin).Magnitude / speed, 0.1, cfg.MaxFlightTime)
    local catchAfterLanding=receiver.Airborne and cfg.TimedJumpReach
        and Smart.timedJump(receiver,estimate,cfg.WRReactionTime,cfg)>0
    local groundedCatch=not receiver.Airborne or catchAfterLanding
    local candidates = Smart.offsets(receiver, defenders, forward, side, estimate, cfg)
    local streak = receiver.RouteLabel == 'Streak'
    local streakLead = streak and (cfg.StreakLeadExtra or 0) or 0
    local extraDeepHeight = groundedCatch and not chestPass and ((cfg.DeepCatchHeightExtra or 0)
        + (streak and (cfg.StreakHeightExtra or 0) or 0)) or 0
    local receiverCatchRadius = math.max(0,cfg.CatchRadius+(receiver.BodyHorizontal or 0)) + (not chestPass and not receiver.Airborne
        and ((cfg.DeepReceiverReachExtra or 0) + streakLead) or 0)
    local strictCatchReach=cfg.PhysicalCatchLimits and not cfg.AllowStyleReach
    if strictCatchReach then receiverCatchRadius=math.max(0,cfg.CatchRadius+(receiver.BodyHorizontal or 0)) end
    local preferredLead = not chestPass and movement.Magnitude > 1 and ((cfg.DeepForwardLead or 0) + streakLead) or 0
    if chestPass and (receiver.RouteLabel == 'Out' or receiver.RouteLabel == 'In') and movement.Magnitude > 1 then
        preferredLead = receiver.RouteLabel == 'In' and (cfg.InForwardLead or cfg.OutForwardLead or 0)
            or (cfg.OutForwardLead or 0)
    end
    if receiver.RouteLabel == 'Diagonal' and movement.Magnitude > 1 then
        preferredLead = preferredLead + (cfg.DiagonalLeadExtra or 0)
    end
    local uncovered=cfg.OpenReceiverNoExtraLead==true
    if uncovered then
        local time=estimate+(receiver.ReleaseDelay or 0)
        local projected=receiver.Position+Smart.travel(receiver,time,cfg)
        for _,db in ipairs(receiver.ShadeDefenders or defenders) do
            local currentDistance=Smart.cap(db.Position-receiver.Position,math.huge).Magnitude
            local futureDistance=Smart.cap(db.Position+Smart.travel(db,time,cfg)-projected,math.huge).Magnitude
            if math.min(currentDistance,futureDistance)<=(cfg.OpenReceiverDistance or 24) then
                uncovered=false;break
            end
        end
    end
    if uncovered then
        preferredLead=0
        candidates={{Offset=Vector3.new(0,0,0),Kind='Open receiver',Bonus=0}}
    end
    if preferredLead > 0 then
        table.insert(candidates, {Offset = forward * preferredLead, Kind = chestPass and 'In/Out lead' or 'Deep lead', Bonus = 0})
    end
    if receiver.EndZone and not uncovered then
        local zone = receiver.EndZone
        local projected = receiver.Position + Smart.travel(receiver, estimate, cfg)
        local across = math.clamp((projected - zone.Center):Dot(zone.Right), -zone.HalfWidth, zone.HalfWidth)
        for _, lateral in ipairs({-2, 0, 2}) do
            local position = zone.Center + zone.Right * math.clamp(across + lateral, -zone.HalfWidth, zone.HalfWidth)
            table.insert(candidates, {Offset = Vector3.new(0, 0, 0), FixedTarget = position,
                Kind = 'Back end zone', Bonus = 3})
        end
    end
    -- Strict placement follows the nearby DB at estimated release, not a
    -- speculative side change at the catch point.
    local shadeTime = cfg.StrictShoulder and (receiver.ReleaseDelay or 0) or estimate + (receiver.ReleaseDelay or 0)
    local shoulder, placement, shadeDetails = Smart.shoulder(receiver, shadeTime, cfg)
    if not shoulder and cfg.PredictCatchShoulder then
        shoulder,placement,shadeDetails=Smart.shoulder(receiver,estimate+(receiver.ReleaseDelay or 0),cfg)
        if shadeDetails then shadeDetails.basis='projected catch';shadeDetails.seconds=estimate+(receiver.ReleaseDelay or 0) end
    elseif shadeDetails then shadeDetails.basis='release';shadeDetails.seconds=shadeTime end
    if shoulder and cfg.JointShoulderSearch and #defenders>0 then
        local count=#candidates
        for i=1,count do
            local c=candidates[i]
            c.Shoulder=shoulder
            table.insert(candidates,{Offset=c.Offset,FixedTarget=c.FixedTarget,Kind=c.Kind,
                Bonus=c.Bonus,Shoulder=shoulder*-1})
        end
        search.shoulders={Inside={valid=0},Outside={valid=0}}
    elseif shoulder and cfg.AllDefenders and not cfg.StrictShoulder then
        -- Preserve alternatives: a safety can cover the nominal open shoulder.
        local count=#candidates
        for i=1,count do
            local c=candidates[i]
            table.insert(candidates,{Offset=c.Offset,FixedTarget=c.FixedTarget,Kind=c.Kind,Bonus=c.Bonus,Unshifted=true})
        end
    end
    if cfg.RefinedFitPass and clampToField then
        local count=#candidates
        local seen={}
        for i=1,count do
            local c=candidates[i]
            local predicted=receiver.Position+Smart.travel(receiver,estimate+(receiver.ReleaseDelay or 0),cfg)+c.Offset
            if not c.FixedTarget and not inBounds(predicted) then
                local bounded=clampToField(predicted)
                local key=string.format('%.2f:%.2f',bounded.X,bounded.Z)
                if not seen[key] then
                    seen[key]=true
                    table.insert(candidates,{Offset=Vector3.new(0,0,0),FixedTarget=bounded,
                        Kind='Sideline fit',Bonus=0,Unshifted=true})
                end
            end
        end
    end
    -- Scale only extra placement lead; normal movement prediction is unchanged.
    local leadScale=1
    if cfg.AdaptiveExtraLead then
        leadScale=math.clamp(movement.Magnitude/math.max(1,Smart.speedLimit(receiver,cfg)),.4,1)
            /(1+math.abs(receiver.TurnRate or 0)*.25+math.max(0,-(receiver.Acceleration or 0))*.03)
        preferredLead=preferredLead*leadScale
        for _,c in ipairs(candidates) do
            local ahead=c.Offset:Dot(forward)
            if ahead>0 then
                c.Offset=c.Offset-forward*(ahead*(1-leadScale))
                local predicted=receiver.Position+Smart.travel(receiver,estimate+(receiver.ReleaseDelay or 0),cfg)
                if inBounds(predicted) and not inBounds(predicted+c.Offset) then
                    c.Offset=c.Offset-forward*c.Offset:Dot(forward)
                end
            end
        end
    end
    for _, candidate in ipairs(candidates) do
            local shoulder=candidate.Shoulder or shoulder
            search.candidates=search.candidates+1
            -- Field-relative inside/outside also works on crossing and out routes.
            -- Apply to every candidate, including deep lead and back-end-zone targets.
            if shoulder and not candidate.Unshifted then
                local projected = receiver.Position + Smart.travel(receiver, estimate + (receiver.ReleaseDelay or 0), cfg)
                local offset = candidate.FixedTarget and candidate.FixedTarget - projected or candidate.Offset
                local shift = shoulder * math.max(0, (cfg.ShadeLeadStuds or 1.5) - offset:Dot(shoulder))
                if candidate.FixedTarget then candidate.FixedTarget = candidate.FixedTarget + shift
                else candidate.Offset = candidate.Offset + shift end
            end
            local jumpHeight = Smart.jump(receiver, 0, cfg)
            if catchAfterLanding then jumpHeight=Smart.timedJump(receiver,estimate,cfg.WRReactionTime,cfg) end
            -- Extra catch height is a small aim-tuning allowance, not a change
            -- to the live jump height or a verified catch-box measurement.
            local fade = not chestPass and (receiver.RouteLabel == 'Fade' or receiver.RouteLabel == 'Corner'
                or candidate.Kind == 'Back shoulder'
                or ((receiver.RouteLabel == 'Streak' or receiver.RouteLabel == 'Post') and shoulder and receiver.Outside and shoulder:Dot(receiver.Outside) > 0))
            -- Small placement allowance for fade-style throws, not measured jump height.
            local fadeLift = fade and groundedCatch and (cfg.FadeHeightExtra or 0) or 0
            local maximumHeight = chest + jumpHeight + extraDeepHeight + fadeLift + (receiver.BodyVertical or 0)
            local reachPadding=cfg.VerticalCatchPadding or 0
            if strictCatchReach then maximumHeight=chest+jumpHeight+(receiver.BodyVertical or 0)+reachPadding end
            local oldDeepHeight = math.max(chest, math.min(cfg.DeepTargetHeight or 9, chest + jumpHeight * 0.9))
            local routeLift = receiver.RouteLabel == 'Out' and (cfg.OutHeightExtra or 0)
                or receiver.RouteLabel == 'In' and (cfg.InHeightExtra or cfg.OutHeightExtra or 0) or 0
            if receiver.RouteLabel == 'Returning' then routeLift = cfg.ReturningHeightExtra or 0 end
            if receiver.RouteLabel == 'Comeback' then routeLift = cfg.ComebackHeightExtra or 0 end
            local preferredHeight = chestPass and math.min(maximumHeight, chest + (cfg.SlantHeightBoost or 1.25) + routeLift)
                or math.min(maximumHeight, oldDeepHeight + (cfg.DeepHeightBoost or 1) + extraDeepHeight + fadeLift)
            if cfg.BlendRouteHeight and receiver.RouteDeepWeight and not stopped then
                local low=math.min(maximumHeight,chest+(cfg.SlantHeightBoost or 1.25)+routeLift)
                local high=math.min(maximumHeight,oldDeepHeight+(cfg.DeepHeightBoost or 1)+extraDeepHeight+fadeLift)
                preferredHeight=low+(high-low)*receiver.RouteDeepWeight
            end
            if receiver.RouteLabel == 'Diagonal' and not stopped then
                preferredHeight=math.min(maximumHeight,preferredHeight+(cfg.DiagonalHeightExtra or 0))
            end
            if stopped then preferredHeight=math.min(maximumHeight,chest+(cfg.StationaryHeightExtra or .75)) end
            local heights = (chestPass or math.abs(preferredHeight-maximumHeight)<.001) and {preferredHeight} or {preferredHeight, maximumHeight}
            if cfg.ExtraHeightCandidate and not chestPass and maximumHeight-preferredHeight>1
                and (candidate.Kind=='Back shoulder' or candidate.Kind=='Over shoulder' or candidate.Kind=='Deep lead') then
                table.insert(heights,(preferredHeight+maximumHeight)*.5)
            end
            if cfg.CoveredShortLobs and chestPass and not uncovered and #defenders>0
                and (stopped or receiver.RouteLabel=='In' or receiver.RouteLabel=='Out') and maximumHeight-preferredHeight>.5 then
                table.insert(heights,(preferredHeight+maximumHeight)*.5)
                table.insert(heights,maximumHeight)
            end

            for _, height in ipairs(heights) do
                local offset = candidate.Offset
                local base = receiver.Position + offset + Vector3.new(0, height, 0)
                local trajectoryMotion = receiver
                if candidate.FixedTarget then
                    base = Vector3.new(candidate.FixedTarget.X, receiver.Position.Y + height, candidate.FixedTarget.Z)
                    trajectoryMotion = {Velocity = Vector3.new(0, 0, 0)}
                end
                local arcs = Smart.arcs(origin, base, trajectoryMotion, speed, gravity, cfg.MaxFlightTime, cfg, not candidate.FixedTarget and travelCache or nil)
                if #arcs==0 then search.noArc=search.noArc+1 end
                for _, arc in ipairs(arcs) do
                    search.trajectories=search.trajectories+1
                    hasArc=true
                    local totalTime = arc.Time + (receiver.ReleaseDelay or 0)
                    local point = candidate.FixedTarget and base or base + Smart.travel(receiver, totalTime, cfg)
                    local requiredAdjustment = candidate.FixedTarget and Smart.cap(point - receiver.Position - Smart.travel(receiver, totalTime, cfg), math.huge).Magnitude or offset.Magnitude
                    local needed = Smart.cap(point - receiver.Position, math.huge).Magnitude
                    local distanceBudget = Smart.runDistance(receiver, totalTime, cfg)
                    local adjust = receiverCatchRadius + math.max(0, distanceBudget - Smart.runDistance(receiver, math.min(arc.Time, cfg.WRReactionTime), cfg))
                    local availableJump=cfg.TimedJumpReach and Smart.timedJump(receiver,arc.Time,cfg.WRReactionTime,cfg)
                        or Smart.jump(receiver,arc.Time,cfg)
                    if cfg.PhysicalCatchLimits and cfg.TimedJumpReach then
                        availableJump=Smart.timedJump(receiver,totalTime,(receiver.ReleaseDelay or 0)+cfg.WRReactionTime,cfg)
                    end
                    local catchCeiling=chest+availableJump+(receiver.BodyVertical or 0)
                        +(strictCatchReach and reachPadding or extraDeepHeight+fadeLift)
                    local reachable = needed <= distanceBudget + receiverCatchRadius
                        and (not catchAfterLanding or availableJump>0)
                        and (not receiver.Diving or totalTime <= (receiver.LandingTime or 0))
                        and height <= catchCeiling + 0.01
                        and requiredAdjustment + (receiver.Uncertainty or 0) <= math.min(cfg.MaxAdjustment, adjust)
                    -- Slants use the low, fast chest pass rather than a hanging lob.
                    local angle = math.deg(math.atan2(arc.Velocity.Y, Smart.cap(arc.Velocity, math.huge).Magnitude))
                    local actualShoulder = candidate.Shoulder or (cfg.StrictShoulder and shoulder or shoulder and Smart.shoulder(receiver, totalTime, cfg))
                    local placementValid = not actualShoulder or (point - receiver.Position - Smart.travel(receiver, totalTime, cfg)):Dot(actualShoulder) >= .5
                    local highShort=chestPass and cfg.CoveredShortLobs and height>preferredHeight+.1
                    local angleValid = angle <= (chestPass and not highShort and (cfg.ChestMaxAngle or 35) or (cfg.DeepMaxAngle or 90))
                    local sideValid = (cfg.AllDefenders and not cfg.StrictShoulder) or placementValid
                    local boundsValid,reel=Smart.reelBounds(point,receiver,totalTime,height,cfg,inBounds)
                    if not reachable then search.reach=search.reach+1
                    elseif not angleValid then search.angle=search.angle+1
                    elseif not sideValid then search.shoulder=search.shoulder+1
                    elseif not boundsValid then search.bounds=search.bounds+1 end
                    if reachable then hasReach=true end
                    if reachable and angleValid then hasAngle=true end
                    if reachable and angleValid and sideValid then hasPlacement=true end
                    if reachable and sideValid and angleValid and boundsValid then
                        local margin, limiting = Smart.clearance(origin, arc.Velocity, arc.Time, defenders, gravity, cfg, receiver.ReleaseDelay)
                        -- Positive margin means outside the estimated DB reach envelope.
                        local clear = margin >= (cfg.ExclusiveWindow and (cfg.ExclusiveSafetyMargin or 2) or cfg.SafetyMargin)
                        if not clear then search.coverageRisk=search.coverageRisk+1 end
                        if search.shoulders and shoulder then
                            local sideName=shoulder:Dot(receiver.Outside)>0 and 'Outside' or 'Inside'
                            local stats=search.shoulders[sideName]
                            stats.valid=stats.valid+1
                            local finiteMargin=math.clamp(margin,-1000000,1000000)
                            stats.bestMargin=math.max(stats.bestMargin or -1000000,finiteMargin)
                        end
                        local leadPenalty = not candidate.FixedTarget and preferredLead > 0 and (offset - forward * preferredLead).Magnitude * 2 or 0
                        local score = math.min(margin, 15) - requiredAdjustment * 0.35 - leadPenalty
                            - math.abs(height - preferredHeight) * 2.5 - arc.Time * (chestPass and 3 or 2) - (receiver.Uncertainty or 0) + candidate.Bonus
                        score = score - Smart.arcPenalty(angle, gravity * arc.Time - arc.Velocity.Y, chestPass, cfg)
                        if Smart.better({Clear=clear,Margin=margin,Score=score},best,cfg) then
                            local lateral = receiver.Outside and (point-receiver.Position-Smart.travel(receiver,totalTime,cfg)):Dot(receiver.Outside) or 0
                            local selectedPlacement = shoulder and (lateral >= .5 and 'Outside shoulder' or lateral <= -.5 and 'Inside shoulder' or 'Center') or nil
                            local selectedShade=shadeDetails
                            if candidate.Shoulder and shadeDetails then
                                selectedShade={}
                                for k,v in pairs(shadeDetails) do selectedShade[k]=v end
                                selectedShade.preferredSide=shadeDetails.requiredSide
                                selectedShade.requiredSide=lateral>=0 and 'Outside' or 'Inside'
                                selectedShade.basis='both shoulders compared against all defenders'
                            end
                            best = {Velocity = arc.Velocity, Direction = arc.Velocity.Unit, Time = arc.Time,
                                Point = point, Power = power, Margin = margin, Clear = clear, LimitingDefender=limiting,
                                ReelEstimate=reel,
                                CatchHeight={targetAboveRoot=height,availableJump=availableJump,
                                    estimatedCeiling=catchCeiling,verticalMargin=catchCeiling-height,
                                    horizontalReach=receiverCatchRadius,catchSeconds=totalTime,
                                    physicalLimits=strictCatchReach==true,styleReachAllowed=cfg.AllowStyleReach==true,highShort=highShort==true,
                                    bodyAdjustment=receiver.BodyVertical or 0,styleAllowance=extraDeepHeight+fadeLift,
                                    afterLanding=catchAfterLanding==true,landingTime=receiver.LandingTime,
                                    jumpCooldown=receiver.JumpCooldownRemaining or 0},
                                CatchWindowSeconds=cfg.ExclusiveWindow and cfg.CatchWindowSeconds or nil, Score = score, Kind = candidate.Kind,
                                Placement = selectedPlacement, ShadeDetails=selectedShade, TargetLateral=lateral, Angle = angle, ApexHeight = math.max(0, arc.Velocity.Y)^2 / (2 * gravity)}
                        end
                    end
                end
            end
    end
    if not best and cfg.RefineMissingFit and not cfg.RefinedFitPass then
        local refined={}
        for key,value in pairs(cfg) do refined[key]=value end
        refined.RefinedFitPass=true
        -- Preserve the required side and target height; try smaller adjustments.
        refined.ShadeLeadStuds=math.min(cfg.ShadeLeadStuds or 1.5,.5)
        local refinedBest,refinedReason=Smart.best(origin,receiver,defenders,power,multiplier,gravity,refined,inBounds,clampToField)
        if refinedBest then return refinedBest end
        -- A narrower search must not erase an arc found by the first search.
        if not hasArc then return nil,refinedReason end
    end
    local reason = not hasArc and 'Out of range' or not hasReach and 'WR reach limit'
        or not hasAngle and 'Angle limit' or not hasPlacement and 'Shoulder blocked' or 'Field boundary'
    if best then
        best.SearchDiagnostics=search;best.ExtraLeadScale=leadScale;best.RouteDeepWeight=receiver.RouteDeepWeight
        local t=best.Time+(receiver.ReleaseDelay or 0)
        local comparison={snapshotSeconds=t,estimated=true,defenders={}}
        for _,e in ipairs(Smart.envelopes(defenders,t,cfg)) do
            local relative=best.Point-e.Center
            comparison.defenders[#comparison.defenders+1]={name=e.Defender.Name,
                horizontalMargin=Smart.cap(relative,math.huge).Magnitude-e.Reach,
                aboveReach=relative.Y-e.Height,belowReach=-relative.Y-e.Below}
        end
        best.CatchComparison=comparison
    end
    return best,not best and reason or nil
end

ContactGeometry = {}
-- Same segment/slab calculation as CatchMotion.Contact.Intersects.
function ContactGeometry.box(ball0,ball1,frame0,frame1,size,padding)
    local start=frame0:PointToObjectSpace(ball0)
    local delta=frame1:PointToObjectSpace(ball1)-start
    local enter,leave=0,1
    for _,axis in ipairs({'X','Y','Z'}) do
        local extent=size[axis]*.5+padding
        if math.abs(delta[axis])<1e-6 then
            if math.abs(start[axis])>extent then return false end
        else
            local a,b=(-extent-start[axis])/delta[axis],(extent-start[axis])/delta[axis]
            if a>b then a,b=b,a end
            enter,leave=math.max(enter,a),math.min(leave,b)
            if leave<enter then return false end
        end
    end
    return true
end
-- Same relative-segment distance calculation as PBUMotion.Contact.
function ContactGeometry.swat(ball0,ball1,hand0,hand1,radius)
    local start=ball0-hand0
    local delta=ball1-hand1-start
    local length=delta:Dot(delta)
    local time=length>1e-6 and math.clamp(-start:Dot(delta)/length,0,1) or 0
    return (start+delta*time).Magnitude<=radius
end
function ContactGeometry.intercepts(ball0,ball1,defender,t0,t1,cfg,ballRadius)
    if not defender.HandGeometry then return false end
    if defender.CatchState and not defender.CatchState.catching and not defender.CatchState.pbuing then return false end
    local move0,move1=Smart.travel(defender,t0,cfg),Smart.travel(defender,t1,cfg)
    local padding=(ballRadius or .75)+(cfg.GeometryPadding or .25)
    for _,hand in ipairs(defender.HandGeometry) do
        local frame0,frame1=hand.Frame+move0,hand.Frame+move1
        -- Cheap conservative broad-phase test before oriented-box math.
        if ContactGeometry.swat(ball0,ball1,frame0.Position,frame1.Position,hand.Size.Magnitude*.5+math.max(hand.Size.X,hand.Size.Z)*.5+padding) then
            if ContactGeometry.box(ball0,ball1,frame0,frame1,hand.Size,padding) then return true end
            local tip0=frame0:PointToWorldSpace(Vector3.new(0,-hand.Size.Y*.5,0))
            local tip1=frame1:PointToWorldSpace(Vector3.new(0,-hand.Size.Y*.5,0))
            -- Estimated swat radius; server's caller-supplied radius is unknown.
            local radius=math.max(hand.Size.X,hand.Size.Z)*.5+padding
            if ContactGeometry.swat(ball0,ball1,tip0,tip1,radius) then return true end
        end
    end
    return false
end

-- Movement classification, not knowledge of the playbook. Field direction is
-- inferred from QB/WR alignment; uncertain alignment remains Unknown.
local Routes = {}
function Routes.update(state, now, x, z, vx, vz, attackSign)
    if not attackSign then return nil, 'Unknown', 'waiting for direction' end
    if not state or now - state.Last > 0.6 or state.Sign ~= attackSign then
        state = {StartX=x,StartZ=z,Side=x < -2 and -1 or (x > 2 and 1 or 0),
            Last=now,Started=now,Peak=0,Stem=0,LastZ=z,Sign=attackSign,Label='Reading'}
    end
    state.Last = now
    local depth = (z-state.StartZ)*attackSign
    state.Peak = math.max(state.Peak,depth)
    local speed = math.sqrt(vx*vx+vz*vz)
    local up = speed > 0.01 and vz*attackSign/speed or 0
    local lateral = speed > 0.01 and math.abs(vx)/speed or 0
    local inside = state.Side ~= 0 and vx*state.Side < 0
    local outside = state.Side ~= 0 and vx*state.Side > 0
    -- Shallow posts/corners can remain below the ordinary diagonal threshold.
    -- Require an observed stem and sustained lateral displacement, not jitter.
    if speed>=2 and state.Stem>=10 and up>.5 and lateral>.22 and state.Side~=0 then
        if state.ShallowSide~=inside or not state.ShallowAt then
            state.ShallowAt,state.ShallowX,state.ShallowSide=now,x,inside
        end
    else state.ShallowAt=nil;state.ShallowX=nil;state.ShallowSide=nil end
    local shallowCut=state.ShallowAt and now-state.ShallowAt>=.3
        and math.abs(x-state.ShallowX)>=1.5
    -- An early Out label is provisional if the runner subsequently carries
    -- the route diagonally downfield. Require both time and measured depth.
    if speed>=2 and outside and up>=.5 and lateral>.35
        and (state.Label=='Out' or state.DiagonalRoute=='Out') then
        if not state.OutDiagonalAt then state.OutDiagonalAt=now;state.OutDiagonalZ=z end
    else
        state.OutDiagonalAt=nil;state.OutDiagonalZ=nil
    end
    local upgradeOut=state.OutDiagonalAt and now-state.OutDiagonalAt>=.4
        and (z-state.OutDiagonalZ)*attackSign>=6
    -- Remember the straight stem before a cut. Diagonal travel alone must not
    -- promote a long-running slant into a post.
    if speed < 2 and state.Peak < 2 then state.SawStart=true end
    if up>=.9 and lateral<.3 then
        state.Stem=state.Stem+math.max(0,(z-state.LastZ)*attackSign)
    end
    state.LastZ=z
    local route, reason
    if speed < 2 then
        route,reason=state.Peak>=5 and 'Curl' or 'Stationary','stopped movement'
    elseif now-state.Started < .2 then
        route,reason='Reading','building movement history'
    elseif up < -.3 and state.Peak>=4 then
        route,reason=outside and 'Comeback' or 'Curl','returning after a downfield stem'
    elseif up < -.3 then
        route,reason='Returning','moving back; no observed stem'
    elseif lateral>.86 and math.abs(up)<.5 then
        if outside and state.DiagonalRoute=='Corner' and up>=-.1 then
            route,reason='Corner','confirmed corner bending toward the sideline'
        else
            route,reason=inside and 'In' or (outside and 'Out' or 'Crossing'),'crossing the field'
        end
    elseif up>.2 and (lateral>.35 or shallowCut) then
        if state.Side==0 then route='Diagonal'
        elseif upgradeOut then route='Corner'
        elseif state.DiagonalSide==inside and state.DiagonalRoute then route=state.DiagonalRoute
        elseif state.Stem>=10 then route=inside and 'Post' or 'Corner'
        elseif state.SawStart or state.Stem>=2 then route=inside and 'Slant' or 'Out'
        else route='Diagonal' end
        reason=route=='Diagonal' and 'inward/outward cut; missing pre-cut history' or 'observed stem and confirmed cut'
        if upgradeOut then reason='out developed into sustained downfield/outward run' end
    elseif up>=.8 then
        route,reason='Streak','running downfield'
    else route,reason='Developing','movement does not yet match a stable route' end
    -- A brief confirmation interval prevents flicker during a cut.
    if state.Pending~=route then state.Pending,state.PendingAt=route,now end
    if route=='Reading' or speed<2 or now-state.PendingAt>=.15 then
        state.Label=route
        state.Reason=reason
        if route=='Post' or route=='Corner' or route=='Slant' or (route=='Out' and up>.2) then
            state.DiagonalRoute,state.DiagonalSide=route,inside
        elseif route=='Streak' or route=='Curl' or route=='Comeback' or route=='Returning'
            or route=='In' or route=='Crossing' or route=='Stationary' or route=='Out' then
            state.DiagonalRoute=nil
        end
    end
    return state,state.Label,state.Reason or reason
end

local motion = {}
local jumpHistory={}
local jumpCooldown=2
local catchMotion
pcall(function() catchMotion=require(rs.GameLibraries.Shared.SharedLibraries.CatchMotion) end)
local routeStates = {}
local routeBall
local routeField
local releaseCalibration = {Count = 0, Delay = 0}
local diveProfiles = {Regular={LINEAR_POWER=1.45,VERTICAL_POWER=2.5},Jumping={LINEAR_POWER=1.7,VERTICAL_POWER=8}}
-- Prefer the live configuration; saved Classic constants are the fallback.
pcall(function()
    local controller = get('StarterPlayer').StarterPlayerScripts.Client.Controllers.Player.MovementController
    local config = require(controller.Configuration)
    if config.DIVE_TYPES then diveProfiles = config.DIVE_TYPES end
    if type(config.JUMP_COOLDOWN)=='number' then jumpCooldown=math.max(0,config.JUMP_COOLDOWN) end
end)
local jumpSampleAt=0
connect(rus.Heartbeat,function()
    local now=os.clock()
    if now-jumpSampleAt<.1 then return end
    jumpSampleAt=now
    for _,player in ipairs(players:GetPlayers()) do
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass('Humanoid')
        if humanoid and sameGame(player) then
            local jumping=humanoid:GetState()==Enum.HumanoidStateType.Jumping
            local old=jumpHistory[player]
            if not old or old.Character~=character then old={Character=character,Until=0};jumpHistory[player]=old end
            if jumping and not old.Jumping then old.Until=now+jumpCooldown end
            old.Jumping=jumping
        else jumpHistory[player]=nil end
    end
end)
local function snapshot(player, now, roster)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    local root = character and character:FindFirstChild('HumanoidRootPart')
    if not root or not humanoid or humanoid.Health <= 0 then motion[player] = nil return end
    local handGeometry={}
    local bodyHorizontal,bodyVertical,bodyKnown=0,0,false
    local bodyTorso=character:FindFirstChild('Torso')
    local leftArm=character:FindFirstChild('Left Arm')
    local rightArm=character:FindFirstChild('Right Arm')
    if bodyTorso and leftArm and rightArm and bodyTorso:IsA('BasePart')
        and leftArm:IsA('BasePart') and rightArm:IsA('BasePart') then
        bodyHorizontal,bodyVertical,bodyKnown=ReceiverPhysics.bodyReach(bodyTorso.Size.X,bodyTorso.Size.Y,leftArm.Size.Y,rightArm.Size.Y)
    end
    if fit.ContactGeometry then
        for _,names in ipairs({{'LeftHand','Left Arm'},{'RightHand','Right Arm'}}) do
            local hand=character:FindFirstChild(names[1]) or character:FindFirstChild(names[2])
            if hand and hand:IsA('BasePart') then table.insert(handGeometry,{Frame=hand.CFrame,Size=hand.Size}) end
        end
    end
    local topSpeed=Smart.topSpeed(character:GetAttribute('BadgeTopSpeed'),fit.MaxRunSpeed)
    local rawVelocity = root.AssemblyLinearVelocity
    local storage = rs:FindFirstChild('PlayerDataStorage')
    local data = storage and storage:FindFirstChild(tostring(player.UserId))
    local session = data and data:FindFirstChild('SessionData')
    local catching=session and session:FindFirstChild('Catching')
    local pbu=session and session:FindFirstChild('PBUing')
    local targetValue=session and session:FindFirstChild('CatchTarget')
    local hitbox=character:FindFirstChild('Hitbox')
    local catchAction=hitbox and hitbox:GetAttribute('Action')
    local target=targetValue and targetValue.Value
    local targetPosition=typeof(target)=='Vector3' and target or nil
    if typeof(target)=='Instance' and target:IsA('BasePart') then targetPosition=target.Position end
    local isCatching=catching and catching.Value==true or false
    local isPbu=pbu and pbu.Value==true or false
    local torso=character:FindFirstChild('Torso') or character:FindFirstChild('UpperTorso')
    if (isCatching or isPbu) and targetPosition and torso and catchMotion then
        local posed={}
        local oneHand=catchAction=='One Hand Catch' or isPbu
        local side=root.CFrame.RightVector:Dot(targetPosition-root.Position)>=0 and 'Right' or 'Left'
        for _,name in ipairs({'Left Arm','Right Arm'}) do
            local arm=character:FindFirstChild(name)
            if arm and (not oneHand or string.find(name,side,1,true)) then
                local ok,pose=pcall(catchMotion.Pose,torso,arm,targetPosition)
                if ok and typeof(pose)=='CFrame' then posed[#posed+1]={Frame=torso.CFrame*pose,Size=arm.Size} end
            end
        end
        if #posed>0 then handGeometry=posed end
    end
    local divingValue = session and session:FindFirstChild('Diving')
    local diving = divingValue and divingValue.Value == true or false
    local state = humanoid:GetState()
    local airborne = humanoid.FloorMaterial == Enum.Material.Air
        or state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
    local velocity = Smart.cap(rawVelocity, airborne and math.huge or topSpeed)
    local old = motion[player]
    local uncertainty = 0
    local acceleration, turnRate = 0, 0
    local jumpHeight = humanoid.UseJumpPower and humanoid.JumpPower ^ 2 / (2 * math.max(ws.Gravity, 0.01)) or humanoid.JumpHeight
    local liveJumpHeight = jumpHeight
    local nearOpponent,nearReceiver=false,false
    local receiverPositions={WR=true,TE=true,RB=true,FB=true}
    for _, other in ipairs(roster or {}) do
        if other.Player~=player and other.Team~=gameTeam(player) and (other.Position-root.Position).Magnitude<=5 then
            nearOpponent=true
            if gameTeam(player) and other.Team and other.Alive and receiverPositions[other.Role] then nearReceiver=true end
        end
    end
    local predictedJumpHeight,badgeKnown,jumpBonus=ReceiverPhysics.badgeJump({
        BaseJump=character:GetAttribute('BadgeBaseJumpHeight'),TopSpeed=topSpeed,
        LiveJump=liveJumpHeight,Speed=Smart.cap(rawVelocity,math.huge).Magnitude,WalkSpeed=humanoid.WalkSpeed,
        HasFootball=character:GetAttribute('HasFootball')==true,
        VerticalFlyer=player:GetAttribute('BadgeJumpVerticalFlyer'),Ladder=player:GetAttribute('BadgeJumpLadder'),
        BallHawk=player:GetAttribute('BadgeJumpBallHawk')},nearOpponent,nearReceiver)
    jumpHeight = math.clamp(jumpHeight, 0, fit.MaxJumpHeight)
    local chestPart = character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso')
    local chestOffset = chestPart and math.clamp(chestPart.Position.Y - root.Position.Y + chestPart.Size.Y * 0.15, 0, 2) or 0.75
    if not airborne and old and not old.Airborne and old.Root == root and now - old.At < 0.5 then
        local change = (velocity - old.Raw).Magnitude
        uncertainty = math.min(3, change * 0.15)
        local elapsed = math.max(0.01, now - old.At)
        if velocity.Magnitude > 3 and old.Raw.Magnitude > 3 then
            local a, b = old.Raw.Unit, velocity.Unit
            local angle = math.atan2(a.X * b.Z - a.Z * b.X, a:Dot(b))
            turnRate = math.clamp(angle / elapsed, -fit.MaxTurnRate, fit.MaxTurnRate)
        end
        local speedChange = velocity.Magnitude - old.Raw.Magnitude
        -- This is an observed ramp, not an assumption that everyone runs at 23.
        acceleration = math.clamp(speedChange / elapsed, -fit.AccelerationClamp, fit.AccelerationClamp)
        acceleration = (old.Acceleration or 0) * 0.4 + acceleration * 0.6
        -- React immediately to sharp cuts; smooth small replication fluctuations.
        if change < 7 then
            local alpha = 1 - math.exp(-math.max(0.001, now - old.At) / 0.08)
            velocity = Smart.cap(old.Velocity:Lerp(velocity, alpha), topSpeed)
        end
    end
    local groundY = root.Position.Y
    if airborne then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local characters = {}
        for _, p in ipairs(players:GetPlayers()) do if p.Character then table.insert(characters,p.Character) end end
        params.FilterDescendantsInstances = characters
        local hit = ws:Raycast(root.Position, v3.new(0,-100,0),params)
        local clearance = root.Size.Y/2 + (humanoid.RigType == Enum.HumanoidRigType.R6 and 2 or humanoid.HipHeight)
        groundY = hit and hit.Position.Y + clearance or (old and old.GroundY or root.Position.Y)
    end
    local landingTime = airborne and ReceiverPhysics.landingTime(root.Position.Y-groundY,rawVelocity.Y,ws.Gravity) or 0
    local bodyState = diving and 'Diving' or (airborne and (rawVelocity.Y>0 and 'Jumping' or 'Falling') or 'Running')
    motion[player] = {Root = root, At = now, Raw = velocity, Airborne=airborne,GroundY=groundY,
        Velocity = velocity, Acceleration = acceleration, JumpHeight = jumpHeight}
    local diveRange, diveVertical
    local canDiveValue=session and session:FindFirstChild('CanDive')
    local canDive=canDiveValue and canDiveValue.Value==true and not diving and not humanoid.PlatformStand
    for _,name in ipairs({'Tackle','MidTackle','HitSticking','Trucking'}) do
        local flag=session and session:FindFirstChild(name)
        if flag and flag.Value then canDive=false end
    end
    local ath = data and data:FindFirstChild('ATH',true)
    if ath and ath:IsA('ValueBase') and type(ath.Value)=='number' then
        local profile = airborne and diveProfiles.Jumping or diveProfiles.Regular
        if profile then
            local launch = ReceiverPhysics.diveLaunch(humanoid.MoveDirection,humanoid.WalkSpeed,ath.Value,
                player:GetAttribute('BadgeDiveMultiplier') or 1,profile)
            diveRange = Smart.cap(launch,math.huge).Magnitude
            diveVertical=launch.Y
        end
    end
    local jumpRecord=jumpHistory[player]
    local jumpWait=jumpRecord and jumpRecord.Character==character and math.max(0,jumpRecord.Until-now) or 0
    return {HandGeometry=handGeometry, CatchState={catching=isCatching,pbuing=isPbu,action=catchAction,pose=character:GetAttribute('CatchPose'),hasTarget=targetPosition~=nil},
        BodyHorizontal=bodyHorizontal,BodyVertical=bodyVertical,BodyReachKnown=bodyKnown,
        JumpCooldownRemaining=jumpWait, Name=player.Name, Position = root.Position, Velocity = velocity, Uncertainty = uncertainty,
        TopSpeed=topSpeed, WalkSpeed=humanoid.WalkSpeed, LiveJumpHeight=liveJumpHeight, UsesJumpPower=humanoid.UseJumpPower,
        PredictedJumpHeight=predictedJumpHeight, BadgeJumpKnown=badgeKnown, JumpBonus=jumpBonus,
        Acceleration = acceleration, JumpHeight = jumpHeight, ChestOffset = chestOffset, TurnRate = turnRate,
        Airborne=airborne,Diving=diving,VerticalSpeed=rawVelocity.Y,CharacterGravity=ws.Gravity,
        LandingTime=landingTime,BodyState=bodyState,DiveLaunchSpeed=diveRange,DiveVerticalSpeed=diveVertical,CanDive=canDive==true}
end
connect(players.PlayerRemoving, function(player) motion[player] = nil; routeStates[player] = nil;jumpHistory[player]=nil end)
-- Track every eligible teammate even before the QB selects a target. This is
-- only position/velocity sampling, not another trajectory or defender solve.
local routeSampleAt=0
connect(rus.Heartbeat,function()
    local now=os.clock()
    if now-routeSampleAt<.1 then return end
    routeSampleAt=now
    local ball=getBall()
    local fieldKey=plr:GetAttribute('ParkFieldName')
    if routeBall~=ball or routeField~=fieldKey then
        routeStates={};routeBall=ball;routeField=fieldKey
    end
    local bounds=ball and gameBounds()
    local team=gameTeam(plr)
    if not bounds or not team then return end
    local qb=bounds.CFrame:PointToObjectSpace(ball.Position)
    for _,other in ipairs(players:GetPlayers()) do
        if other~=plr and sameGame(other) and gameTeam(other)==team then
            local character=other.Character
            local root=character and character:FindFirstChild('HumanoidRootPart')
            local humanoid=character and character:FindFirstChildOfClass('Humanoid')
            if root and humanoid and humanoid.Health>0 then
                local p=bounds.CFrame:PointToObjectSpace(root.Position)
                local v=bounds.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)
                local record=routeStates[other]
                local state=record and record.Character==character and record.State or nil
                if record and record.Root~=root then state=nil end
                if record and record.Position and (root.Position-record.Position).Magnitude>30 then state=nil end
                local sign=state and state.Sign
                if not sign and math.abs(p.Z-qb.Z)>5 then sign=p.Z>qb.Z and 1 or -1 end
                local label,reason
                state,label,reason=Routes.update(state,now,p.X,p.Z,v.X,v.Z,sign)
                routeStates[other]={State=state,Character=character,Root=root,Position=root.Position,Label=label,Reason=reason}
            else routeStates[other]=nil end
        else routeStates[other]=nil end
    end
end)
local powerScanIndex = 0
local recommendedPower
local fitStatus = 'Waiting'
local lastRejectedFit
local coverageText = 'Smart Fit v93 | Waiting for receiver'
local lastPowerRequest = -math.huge
local powerWindupUntil = 0
local pendingPower, pendingPowerAt
local powerHoldUntil = 0
local powerBall
local function refreshPowerState(ball,power,now)
    if ball~=powerBall then
        powerBall=ball
        pendingPower,pendingPowerAt=nil,nil
        lastPowerRequest=-math.huge
        powerHoldUntil=now+.75
        powerWindupUntil=0
    end
    if pendingPower then
        local acknowledged=power~=pendingPower
        if acknowledged or now-(pendingPowerAt or now)>=.8 then
            pendingPower,pendingPowerAt=nil,nil
            powerHoldUntil=math.max(powerHoldUntil,now+(acknowledged and math.max(.75,fit.AutoPowerThrowWindow or .75) or 3))
        end
    end
end
local function nextPowerCandidate(choices, maximum, power, actual, reason)
    powerScanIndex=powerScanIndex % #choices+1
    if not actual and reason=='Out of range' and power<maximum then
        return maximum
    end
    return choices[powerScanIndex]
end
local function fieldCheck(point)
    if fit.FieldBoundaryChecks==false then return true end
    local size = gameBounds()
    if not size then return false end
    local relative = size.CFrame:PointToObjectSpace(point)
    return math.abs(relative.X) <= size.Size.X / 2 - fit.BoundsInset
        and math.abs(relative.Z) <= size.Size.Z / 2 - fit.BoundsInset
end
local function solveFit(player, ball, power)
    recommendedPower = nil
    if not gameTeam(plr) or not sameGame(plr) then fitStatus = 'Join a team' return end
    local now = os.clock()
    refreshPowerState(ball,power,now)
    local snapshotServerTime = ws:GetServerTimeNow()
    -- One lightweight roster shared by all badge checks in this update.
    local roster={}
    local allPlayers=players:GetPlayers()
    for _, other in ipairs(allPlayers) do
        local character=other.Character
        local root=character and character:FindFirstChild('HumanoidRootPart')
        if root and sameGame(other) then
            local humanoid=character:FindFirstChildOfClass('Humanoid')
            local hitbox=character:FindFirstChild('Hitbox')
            table.insert(roster,{Player=other,Team=gameTeam(other),Position=root.Position,
                Alive=humanoid and humanoid.Health>0,Role=hitbox and hitbox:GetAttribute('Position')})
        end
    end
    local receiver = snapshot(player, now, roster)
    if not receiver then fitStatus = 'No receiver' return end
    receiver.AccelerationHorizon=fit.ReceiverAccelerationHorizon
    receiver.TurnHorizon=fit.ReceiverTurnHorizon
    receiver.MaxTurnAngle=fit.ReceiverMaxTurnAngle
    gui.Cards.Speed.Speed.Text = string.format('%.1f',receiver.Velocity.Magnitude)
    -- This snapshot is made near release; do not add the animation windup again.
    receiver.ReleaseDelay = math.clamp(releaseCalibration.Count >= 3 and releaseCalibration.Delay
        or fit.InitialReleaseDelay, 0, fit.MaxReleaseDelay)
    local flatDelta = Smart.cap(receiver.Position - ball.Position, math.huge)
    local dot = receiver.Velocity.Magnitude > 1 and flatDelta.Magnitude > 0.01
        and receiver.Velocity.Unit:Dot(flatDelta.Unit) or 1
    receiver.ChestPass = flatDelta.Magnitude <= fit.ChestRange or dot < 0.65
    local fieldSize = gameBounds()
    if not fieldSize then fitStatus = 'No field bounds' return end
    receiver.ReelBounds=function(point)
        local p=fieldSize.CFrame:PointToObjectSpace(point)
        local inset=fit.ReelLandingInset or .75
        return math.abs(p.X)<=fieldSize.Size.X/2-inset and math.abs(p.Z)<=fieldSize.Size.Z/2-inset
    end
    local localPosition = fieldSize.CFrame:PointToObjectSpace(receiver.Position)
    local fieldKey=plr:GetAttribute('ParkFieldName')
    if routeBall ~= ball or routeField~=fieldKey then routeStates = {}; routeBall = ball; routeField=fieldKey end
    local localQB = fieldSize.CFrame:PointToObjectSpace(ball.Position)
    local localVelocity = fieldSize.CFrame:VectorToObjectSpace(receiver.Velocity)
    local record = routeStates[player]
    local character = player.Character
    if record and record.Character ~= character then record = nil end
    local state = record and record.State
    local attackSign = state and state.Sign
    if not attackSign and math.abs(localPosition.Z-localQB.Z)>5 then
        attackSign = localPosition.Z>localQB.Z and 1 or -1
    end
    local label, reason
    if record and state and now-state.Last<=.6 then
        label,reason=record.Label,record.Reason
    else
        state,label,reason = Routes.update(state,now,localPosition.X,localPosition.Z,
            localVelocity.X,localVelocity.Z,attackSign)
        routeStates[player] = {State=state,Character=character,Root=character:FindFirstChild('HumanoidRootPart'),Position=receiver.Position,Label=label,Reason=reason}
    end
    if not receiver.Airborne and receiver.Velocity.Magnitude<2 then
        label=state and state.Peak>=5 and 'Curl' or 'Stationary'
        reason='stopped receiver; stationary catch target'
    end
    receiver.RouteLabel = label
    local chestRoutes = {Slant=true,In=true,Out=true,Curl=true,Comeback=true,Stationary=true,Crossing=true,Returning=true}
    local deepRoutes = {Streak=true,Post=true,Corner=true}
    if chestRoutes[label] then receiver.ChestPass=true
    elseif deepRoutes[label] then receiver.ChestPass=false
    elseif label=='Diagonal' then receiver.ChestPass=flatDelta.Magnitude<=fit.ChestRange end
    if state then
        local goal=deepRoutes[label] and 1 or chestRoutes[label] and 0 or (receiver.ChestPass and .25 or .75)
        local previous=state.DeepWeight
        local dt=math.max(0,now-(state.BlendAt or now))
        state.DeepWeight=previous and previous+math.clamp(goal-previous,-dt/.4,dt/.4) or goal
        state.BlendAt=now
        receiver.RouteDeepWeight=state.DeepWeight
    end
    if (label=='Curl' or label=='Stationary') and not receiver.Airborne and receiver.Velocity.Magnitude<2 then
        receiver.Velocity,receiver.Acceleration,receiver.TurnRate=v3.zero,0,0
    end
    receiver.Outside = fieldSize.CFrame.RightVector * (localPosition.X >= 0 and 1 or -1)
    if fit.FieldBoundaryChecks~=false and fit.BackEndZoneEnabled and not receiver.ChestPass and not isPark() then
        local sign = localPosition.Z >= 0 and 1 or -1
        local outward = fieldSize.CFrame:VectorToWorldSpace(v3.new(0, 0, sign))
        -- Goal-line position is from this place's FieldDimensions (182.5).
        if math.abs(localPosition.Z) >= 162.5 and receiver.Velocity:Dot(outward) > 1 then
            local inset = math.max(fit.BoundsInset, fit.EndZoneInset)
            receiver.EndZone = {
                Center = fieldSize.CFrame:PointToWorldSpace(v3.new(0, 0, sign * (fieldSize.Size.Z / 2 - inset))),
                Right = fieldSize.CFrame.RightVector, HalfWidth = fieldSize.Size.X / 2 - inset,
            }
        end
    end
    if uis:IsKeyDown(keys.C) then receiver.Velocity, receiver.Acceleration = v3.zero, 0 end
    local defenders = {BallRadius=ball.Size.Magnitude*.5}
    receiver.ShadeDefenders = {}
    local unknownTeams, nearestDB = 0, math.huge
    local nearestSample, nearestPlayer
    for _, opponent in ipairs(allPlayers) do
        if (fit.DefenderChecks or fit.ShadePlacement) and opponent ~= plr and opponent ~= player and sameGame(opponent) and (gameTeam(opponent) ~= gameTeam(plr) or not gameTeam(opponent)) then
            local sample = snapshot(opponent, now, roster)
            if sample then
                local distance = (sample.Position - receiver.Position).Magnitude
                if gameTeam(opponent) then
                    if fit.DefenderChecks then table.insert(defenders, sample) end
                    if fit.ShadePlacement then table.insert(receiver.ShadeDefenders, sample) end
                    if distance < nearestDB then
                        nearestDB, nearestSample, nearestPlayer = distance, sample, opponent
                    end
                elseif fit.DefenderChecks and (fit.ExclusiveWindow or distance < 100) then unknownTeams = unknownTeams + 1 end
            elseif fit.ExclusiveWindow then
                local character=opponent.Character
                local humanoid=character and character:FindFirstChildOfClass('Humanoid')
                if humanoid and humanoid.Health>0 then unknownTeams=unknownTeams+1 end
            end
        end
    end
    if nearestSample then
        nearestDBLbl.Text = string.format('Nearest DB to WR: %s | %.1f studs | WalkSpeed %.1f / top %.1f | Jump %.1f / next %.1f%s',
            nearestPlayer.Name, nearestDB, nearestSample.WalkSpeed, nearestSample.TopSpeed, nearestSample.LiveJumpHeight, nearestSample.PredictedJumpHeight,
            nearestSample.UsesJumpPower and ' (from JumpPower)' or '')
    else nearestDBLbl.Text = 'Nearest DB to WR: none available' end
    coverageText = string.format('Smart Fit v93 | DBs: %d | Nearest: %s | Unknown teams: %d',
        #defenders, nearestDB == math.huge and 'none' or string.format('%.1f studs', nearestDB), unknownTeams)
    if not fit.DefenderChecks then coverageText = 'Smart Fit v93 | Defender checks OFF' end
    if fit.Power100Only then
        recommendedPower=100
        local data=ball:FindFirstChild('BallData')
        local minimum=data and data:FindFirstChild('MinPower')
        local maximum=data and data:FindFirstChild('MaxPower')
        if not minimum or not maximum or minimum.Value>100 or maximum.Value<100 then
            fitStatus='100 unavailable';return
        end
        if power~=100 and not pendingPower and now>=powerHoldUntil and now>=powerWindupUntil and now-lastPowerRequest>=.25 then
            lastPowerRequest,pendingPowerAt,pendingPower=now,now,power
            event:FireServer(power<100 and 'Power Up' or 'Power Down')
        end
        if power~=100 or pendingPower then
            fitStatus='Setting 100';coverageText=coverageText .. ' | Waiting for 100 power';return
        end
        coverageText=coverageText .. ' | 100 only'
    end
    local gravity = math.abs(physics.PassGravity)
    local function clampToField(point)
        local localPoint=fieldSize.CFrame:PointToObjectSpace(point)
        local halfX=math.max(0,fieldSize.Size.X/2-fit.BoundsInset-.05)
        local halfZ=math.max(0,fieldSize.Size.Z/2-fit.BoundsInset-.05)
        return fieldSize.CFrame:PointToWorldSpace(v3.new(math.clamp(localPoint.X,-halfX,halfX),localPoint.Y,math.clamp(localPoint.Z,-halfZ,halfZ)))
    end
    local actual, noFitReason = Smart.best(ball.Position, receiver, defenders, power, physics.PassSpeedMultiplier, gravity, fit, fieldCheck,clampToField)
    local best = actual
    local data = ball:FindFirstChild('BallData')
    local minimum = data and data:FindFirstChild('MinPower')
    local maximum = data and data:FindFirstChild('MaxPower')
    -- One alternative per update instead of up to eight full-field searches.
    -- Every comparison uses this update's fresh snapshot; never reuse old coverage.
    if not fit.Power100Only and fit.AutoPower and minimum and maximum and minimum.Value <= maximum.Value then
        local seen = {[power]=true}
        local choices = {}
        for _, candidate in ipairs({minimum.Value,maximum.Value,power-20,power-10,power-5,power+5,power+10,power+20}) do
            candidate=math.clamp(candidate,minimum.Value,maximum.Value)
            if not seen[candidate] then seen[candidate]=true; table.insert(choices,candidate) end
        end
        if #choices>0 then
            local candidate=nextPowerCandidate(choices,maximum.Value,power,actual,noFitReason)
            local option=Smart.best(ball.Position,receiver,defenders,candidate,physics.PassSpeedMultiplier,gravity,fit,fieldCheck,clampToField)
            if option and Smart.better(option,best,fit,fit.PowerImprovement) then best=option end
        end
    end
    recommendedPower = best and best.Power or nil
    if not fit.Power100Only and fit.AutoPower and best and (best.Clear or not fit.RequireClear) and math.abs(best.Power - power) >= 1
        and now >= powerHoldUntil and now >= powerWindupUntil and not pendingPower
        and now - lastPowerRequest >= (fit.AutoPowerChangeInterval or 1.25) then
        lastPowerRequest, pendingPowerAt, pendingPower = now, now, power
        event:FireServer(best.Power > power and 'Power Up' or 'Power Down')
    end
    -- Confirmed power can be used immediately; pending requests block stale aim.
    if pendingPower then
        fitStatus='Power settling'
        coverageText=coverageText .. ' | Waiting for power to settle'
        return
    end
    if not actual then
        -- Keep the latest rejected solve, even though no ball was released.
        local function point(v) return {x=v.X,y=v.Y,z=v.Z} end
        lastRejectedFit={reason=noFitReason,power=power,maximumPower=maximum and maximum.Value,
            serverTime=snapshotServerTime,target=player.Name,origin=point(ball.Position),
            receiver=point(receiver.Position),velocity=point(receiver.Velocity),
            distanceStuds=(receiver.Position-ball.Position).Magnitude,
            launchSpeed=power*physics.PassSpeedMultiplier,gravity=gravity,
            route=receiver.RouteLabel,routeDeepWeight=receiver.RouteDeepWeight,
            acceleration=receiver.Acceleration,turnRate=receiver.TurnRate,
            topSpeed=receiver.TopSpeed,releaseDelay=receiver.ReleaseDelay,
            accelerationHorizon=receiver.AccelerationHorizon,turnHorizon=receiver.TurnHorizon,
            maxTurnAngle=receiver.MaxTurnAngle,airborne=receiver.Airborne,
            landingTime=receiver.LandingTime,verticalSpeed=receiver.VerticalSpeed,
            jump=receiver.PredictedJumpHeight,chestOffset=receiver.ChestOffset,
            bodyVertical=receiver.BodyVertical,bodyHorizontal=receiver.BodyHorizontal,
            settings={maxFlightTime=fit.MaxFlightTime,deepMaxAngle=fit.DeepMaxAngle,
                deepHeight=fit.DeepTargetHeight,deepBoost=fit.DeepHeightBoost,
                deepExtra=fit.DeepCatchHeightExtra,deepLead=fit.DeepForwardLead,
                streakHeight=fit.StreakHeightExtra,streakLead=fit.StreakLeadExtra}}
        fitStatus = noFitReason or 'No fit'
        coverageText=coverageText .. ' | ' .. fitStatus .. ' at current power'
        return
    end
    if unknownTeams > 0 then actual.Clear = false end
    coverageText = coverageText .. ' | ' .. (actual.Kind or 'Lead')
    if actual.Placement then coverageText = coverageText .. ' | ' .. actual.Placement end
    if not actual.Clear and actual.LimitingDefender then
        local limit=actual.LimitingDefender
        coverageText=coverageText .. string.format(' | Risk: %s at %.2fs (%s)',limit.name or 'DB',limit.seconds,limit.kind)
    end
    actual.Origin, actual.Player, actual.Ball, actual.UpdatedAt = ball.Position, player, ball, now
    actual.SnapshotServerTime = snapshotServerTime
    actual.ReleaseDelay = receiver.ReleaseDelay
    coverageText = coverageText .. string.format(' | Delay %.0fms (%s)', receiver.ReleaseDelay * 1000,
        releaseCalibration.Count >= 3 and 'measured' or 'estimate')
    actual.Route = receiver.RouteLabel
    actual.RouteBasis = reason
    actual.ReceiverMotion = {acceleration=receiver.Acceleration,turnRate=receiver.TurnRate,
        bodyHorizontal=receiver.BodyHorizontal,bodyVertical=receiver.BodyVertical,bodyReachKnown=receiver.BodyReachKnown,
        jumpCooldownRemaining=receiver.JumpCooldownRemaining,catchState=receiver.CatchState,
        turnHorizon=receiver.TurnHorizon,maxTurnAngle=receiver.MaxTurnAngle,
        accelerationHorizon=receiver.AccelerationHorizon,state=receiver.BodyState,topSpeed=receiver.TopSpeed,horizontalSpeed=receiver.Velocity.Magnitude,
        verticalSpeed=receiver.VerticalSpeed,gravity=receiver.CharacterGravity,landingTime=receiver.LandingTime,
        configuredDiveLaunchSpeed=receiver.DiveLaunchSpeed,liveJumpHeight=receiver.LiveJumpHeight,
        predictedJumpHeight=receiver.PredictedJumpHeight,badgeJumpKnown=receiver.BadgeJumpKnown,jumpBonus=receiver.JumpBonus}
    coverageText = coverageText .. ' | ' .. receiver.BodyState
    coverageText = coverageText .. string.format(' | Speed %.1f / top %.1f Jump %.1f / next %.1f | Route estimated',receiver.Velocity.Magnitude,receiver.TopSpeed,receiver.LiveJumpHeight,receiver.PredictedJumpHeight)
    actual.SolveMilliseconds = (os.clock()-now)*1000
    actual.NearestDB = nearestSample and {name=nearestPlayer.Name,distance=nearestDB,
        bodyHorizontal=nearestSample.BodyHorizontal,bodyVertical=nearestSample.BodyVertical,bodyReachKnown=nearestSample.BodyReachKnown,
        distanceYards=not isPark() and ReceiverPhysics.stadiumYards(nearestDB) or nil,
        jumpCooldownRemaining=nearestSample.JumpCooldownRemaining,catchState=nearestSample.CatchState,
        walkSpeed=nearestSample.WalkSpeed,topSpeed=nearestSample.TopSpeed,jumpHeight=nearestSample.LiveJumpHeight,
        predictedJumpHeight=nearestSample.PredictedJumpHeight,badgeJumpKnown=nearestSample.BadgeJumpKnown,jumpBonus=nearestSample.JumpBonus,
        usesJumpPower=nearestSample.UsesJumpPower,measuredSpeed=nearestSample.Velocity.Magnitude} or nil
    actual.DefenderCount = #defenders
    actual.SmartFit = true
    if pendingPower then fitStatus = 'Power adjusting'
    elseif not fit.DefenderChecks then fitStatus = 'Checks off'
    elseif unknownTeams > 0 then fitStatus = 'Unknown DBs'
    elseif #defenders == 0 then fitStatus = 'No DBs'
    elseif actual.Clear then fitStatus = fit.ExclusiveWindow and 'Window' or (actual.Margin == math.huge and 'Above reach' or string.format('+%.1f studs', actual.Margin))
    else
        local stage=actual.LimitingDefender and actual.LimitingDefender.stage
        fitStatus=stage=='release' and 'Release risk' or stage=='catch' and 'Catch risk' or 'Path risk'
    end
    return actual
end

local function solve(player, ball, power)
    local root = targetRoot(player)
    if not root then return end
    local route, movement = routeFor(root, ball.Position)
    if uis:IsKeyDown(keys.C) then movement = v3.zero end
    movement = Smart.cap(movement, Smart.topSpeed(player.Character:GetAttribute('BadgeTopSpeed'),fit.MaxRunSpeed))
    local config = ModeConfigs[modes[modeIndex]][route]
    local jumpKey = keys[QBAimbotSettings.JumpPassKeybind]
    local jump = jumpKey and uis:IsKeyDown(jumpKey) and QBAimbotSettings.JumpPassHeight or 0
    local lead = movement.Magnitude > 0.01 and movement.Unit * config.XZOffset or v3.zero
    local target = root.Position + lead + v3.new(0, config.YOffset + jump, 0)
    local speed = math.clamp(power * physics.PassSpeedMultiplier, 1, 250)
    local velocity, time = intercept(ball.Position, target, movement, speed,
        math.abs(physics.PassGravity), math.min(QBAimbotSettings.maxAirTime, physics.MaxLifetime))
    if not velocity or not physics.IsFiniteVector(velocity) then return end
    return {Direction = velocity.Unit, Velocity = velocity, Time = time, Power = power,
        Origin = ball.Position, Player = player, Route = route, Ball = ball, UpdatedAt = os.clock()}
end

local function lockTarget()
    if locked then locked, lockedTarget = false, nil
    else
        lockedTarget = findTarget()
        locked = lockedTarget ~= nil
    end
end
local function cycleMode() modeIndex = modeIndex % #modes + 1; currentSolution = nil end
local function changePower(up)
    if fit.Power100Only and modes[modeIndex] == 'Smart' then return end
    fit.AutoPower = false
    powerHoldUntil = os.clock() + 1
    if getBall() then event:FireServer(up and 'Power Up' or 'Power Down') end
end
connect(lockBtn.MouseButton1Click, lockTarget)
connect(modeBtn.MouseButton1Click, cycleMode)
connect(powerUpBtn.MouseButton1Click, function() changePower(true) end)
connect(powerDnBtn.MouseButton1Click, function() changePower(false) end)
connect(uis.InputBegan, function(input, processed)
    if processed or uis:GetFocusedTextBox() then return end
    if input.KeyCode == keys[QBAimbotSettings.ToggleKeybind] then lockTarget()
    elseif input.KeyCode == keys.T then cycleMode()
    elseif input.KeyCode == keys.R then changePower(true)
    elseif input.KeyCode == keys.F then changePower(false)
    elseif input.KeyCode == keys.G then fit.Power100Only = not fit.Power100Only; currentSolution = nil; powerHoldUntil = 0; if fit.Power100Only then modeIndex = 1 end
    elseif input.KeyCode == keys.P then fit.Power100Only = false; fit.AutoPower = not fit.AutoPower
    elseif input.KeyCode == keys.End then
        QBAimbotSettings.Enabled = not QBAimbotSettings.Enabled
    end
end)
tipLbl.Size = UDim2.new(0, 620, 0, 36)
tipLbl.Position = UDim2.new(0.5, -310, 0, 130)
tipLbl.Text = 'R/F Power | Q Lock | T Mode | P Auto power | G 100 only | End Manual\nTolerance cancellation OFF. Coverage is advisory. Missing/stale aim cancels; no mouse fallback.'

-- Launch/visual diagnostics. Only validated server-clock delay samples are
-- used after three matches; origin, speed and gravity corrections stay manual.
local calibrationGui = create('ScreenGui', gui.Parent, {Name = 'AKIThrowCalibration', ResetOnSpawn = false})
local calibrationLabel = create('TextLabel', calibrationGui, {
    Size = UDim2.new(0, 740, 0, 46), Position = UDim2.new(0.5, -370, 0, 196),
    BackgroundColor3 = Color3.fromRGB(15, 20, 28), BackgroundTransparency = 0.2,
    TextColor3 = Color3.fromRGB(225, 240, 250), Font = Enum.Font.Gotham,
    TextSize = 13, TextWrapped = true,
    Text = 'Calibration ON | Make a few throws. K copies the measurements.',
})
local calibrationRecords = {}
env.AKI_QB_Calibration = calibrationRecords
local calibrationQueue = {}
local pendingCalibration, flightCalibration
local outcomeWatch
local function possessionRelation(owner,target,thrower,ownerTeam,throwTeam)
    if owner==thrower then return 'thrower' end
    if owner==target then return 'target' end
    if ownerTeam~=nil and throwTeam~=nil then
        return ownerTeam==throwTeam and 'teammate' or 'opponent'
    end
    return 'unknown team'
end
local function observeOutcome()
    local watch=outcomeWatch
    if not watch then return end
    local now=os.clock()
    if now>watch.Until then outcomeWatch=nil;return end
    if now-(watch.Last or 0)<.05 then return end
    watch.Last=now
    local owner=watch.Ball.Parent and players:GetPlayerFromCharacter(watch.Ball.Parent)
    if not owner or owner==plr or not sameGame(owner) then watch.Owner=nil;return end
    if watch.Owner~=owner then watch.Owner=owner;watch.Since=now;return end
    if now-watch.Since<.1 then return end
    watch.Record.outcome={status='possession observed',player=owner.Name,userId=owner.UserId,
        relation=possessionRelation(owner,watch.Target,plr,gameTeam(owner),watch.ThrowTeam),
        seconds=ws:GetServerTimeNow()-watch.Start,evidence='exact thrown ball parent; stable for 0.1s',
        serverCatchConfirmed=false}
    outcomeWatch=nil
end
local http = get('HttpService')
-- Index only newly visible football clones; never walk the stadium on a throw.
local visualByBall = setmetatable({}, {__mode='kv'})
local function indexVisual(object)
    local reference
    if object.Name == 'ReplaySourceBall' and object:IsA('ObjectValue') then
        reference=object
    elseif object.Name == 'ClientFootballVisual' and object:IsA('BasePart') then
        reference=object:FindFirstChild('ReplaySourceBall')
    end
    if reference and reference:IsA('ObjectValue') and reference.Value
        and reference.Parent and reference.Parent:IsA('BasePart') then
        visualByBall[reference.Value]=reference.Parent
    end
end
connect(ws.DescendantAdded,indexVisual)
-- The saved game's clones are created unparented, so their next activation is
-- observed above. Direct children cover a clone already active when loading.
for _,object in ipairs(ws:GetChildren()) do
    if object.Name=='ClientFootballVisual' then indexVisual(object) end
end
local function xyz(value) return {x = value.X, y = value.Y, z = value.Z} end
local function remember(record)
    table.insert(calibrationRecords, record)
    if #calibrationRecords > 50 then table.remove(calibrationRecords, 1) end
end
local function finishCalibration(reason)
    local flight = flightCalibration
    if not flight then return end
    flight.Record.stopReason = reason
    flight.Record.visualSamples = #flight.Record.samples
    if flight.Count > 0 then
        flight.Record.visualRmsStuds = math.sqrt(flight.SumSquared / flight.Count)
    end
    calibrationLabel.Text = string.format('Calibration: %d throws | launch error %.2f studs | speed error %+.2f studs/s\nVisual samples %d | K copies report | Delay adapts after 3 matches; physics stays unchanged',
        #calibrationRecords, flight.Record.originErrorStuds, flight.Record.speedError, flight.Count)
    flightCalibration = nil
end
-- Called by the hook using only plain Lua data. All instance work happens later.
local function queueCalibration(solution)
    if #calibrationQueue >= 4 then table.remove(calibrationQueue, 1) end
    table.insert(calibrationQueue, {Solution = solution, SentAt = os.clock()})
end
local function beginCalibration(action, launch)
    if action == 'Deterministic Throw Stop' then
        if outcomeWatch and launch==outcomeWatch.Id then outcomeWatch.Until=math.min(outcomeWatch.Until,os.clock()+.5) end
        if flightCalibration and launch == flightCalibration.Id then finishCalibration('game stop') end
        return
    end
    if action ~= 'Deterministic Throw Start' or type(launch) ~= 'table' then return end
    -- Match the exact ball, not the nearest ball or another player's throw.
    local pending = calibrationQueue[#calibrationQueue] or pendingCalibration
    if not pending or os.clock() - pending.SentAt > 2 then return end
    local solution = pending.Solution
    if launch.ball ~= solution.Ball or launch.throwType ~= 'Pass' then return end
    if not physics.IsFiniteVector(launch.origin) or not physics.IsFiniteVector(launch.velocity)
        or not physics.IsFiniteVector(launch.gravity) or type(launch.serverStartTime) ~= 'number' then return end
    finishCalibration('next launch')
    calibrationQueue = {}
    pendingCalibration = nil
    local direction = solution.Direction
    local forward = Smart.cap(direction, math.huge)
    forward = forward.Magnitude > 0.001 and forward.Unit or v3.new(0, 0, -1)
    local side = v3.new(-forward.Z, 0, forward.X)
    local predictedVelocity = solution.Velocity
    local time = solution.Time
    local predictedEnd = solution.Origin + predictedVelocity * time + v3.new(0, physics.PassGravity * time * time / 2, 0)
    local actualEnd = launch.origin + launch.velocity * time + launch.gravity * (time * time / 2)
    local difference = actualEnd - predictedEnd
    local measuredDelay
    if solution.SnapshotServerTime and solution.UpdatedAt then
        local sentServerTime = solution.SnapshotServerTime + (pending.SentAt - solution.UpdatedAt)
        local delta = launch.serverStartTime - sentServerTime
        if delta >= 0 and delta <= fit.MaxReleaseDelay then
            measuredDelay = delta
            releaseCalibration.Delay = releaseCalibration.Count == 0 and delta or releaseCalibration.Delay * 0.75 + delta * 0.25
            releaseCalibration.Count = releaseCalibration.Count + 1
        end
    end
    local record = {
        version = 93, index = #calibrationRecords + 1, mode = modes[modeIndex], route = solution.Route,
        fieldBoundaryChecks=fit.FieldBoundaryChecks~=false,
        reelEstimate=solution.ReelEstimate,
        outcome={status='unknown',serverCatchConfirmed=false},
        search=solution.SearchDiagnostics,extraLeadScale=solution.ExtraLeadScale,routeDeepWeight=solution.RouteDeepWeight,
        catchHeight=solution.CatchHeight,
        catchComparison=solution.CatchComparison,
        unitScale={studsPerYard=not isPark() and 3.65 or nil,physicsUnits='studs'},
        catchTimingReference={minimum=ReceiverPhysics.catchDuration(0,1),maximum=ReceiverPhysics.catchDuration(99,1.2),
            verifiedServerWindow=false},
        solveMilliseconds = solution.SolveMilliseconds, defenderCount = solution.DefenderCount, coverageClear = solution.Clear, limitingDefender = solution.LimitingDefender, catchWindowSeconds = solution.CatchWindowSeconds,
        coverageMargin = solution.Margin and solution.Margin < math.huge and solution.Margin or nil,
        nearestDB = solution.NearestDB, receiverMotion = solution.ReceiverMotion, placement = solution.Placement, shade = solution.ShadeDetails, targetLateral = solution.TargetLateral,
        selectedAngle = solution.Angle, apexAboveRelease = solution.ApexHeight,
        routeBasis = solution.RouteBasis,
        estimatedReleaseDelay = solution.ReleaseDelay, measuredReleaseDelay = measuredDelay,
        power = solution.Power, predictedFlightSeconds = time,
        originErrorStuds = (launch.origin - solution.Origin).Magnitude,
        speedError = launch.velocity.Magnitude - predictedVelocity.Magnitude,
        gravityError = launch.gravity.Y - physics.PassGravity,
        directionErrorDegrees = math.deg(math.acos(math.clamp(direction:Dot(launch.velocity.Unit), -1, 1))),
        sendToLaunchEventSeconds = os.clock() - pending.SentAt,
        eventAgeSeconds = ws:GetServerTimeNow() - launch.serverStartTime,
        predicted = {origin = xyz(solution.Origin), velocity = xyz(predictedVelocity), gravityY = physics.PassGravity},
        server = {origin = xyz(launch.origin), velocity = xyz(launch.velocity), gravity = xyz(launch.gravity)},
        projectedDifferenceAtCatchTime = {forward = difference:Dot(forward), lateral = difference:Dot(side), vertical = difference.Y},
        samples = {},
    }
    -- Projected difference is an extrapolation, not a measured catch/miss.
    remember(record)
    local teamOK,throwTeam=pcall(function() return gameTeam(plr) end)
    outcomeWatch={Id=launch.id,Ball=launch.ball,Target=solution.Player,ThrowTeam=teamOK and throwTeam or nil,
        Start=launch.serverStartTime,Record=record,Until=os.clock()+math.min(physics.MaxLifetime or 5,time+1)}
    flightCalibration = {Id = launch.id, Ball = launch.ball, Origin = launch.origin,
        Velocity = launch.velocity, Gravity = launch.gravity, Start = launch.serverStartTime,
        Record = record, SumSquared = 0, Count = 0, LastSample = 0, LastSearch = 0,
        Receiver = solution.Player, ExpectedEnd = predictedEnd, FlightTime = time}
    calibrationLabel.Text = 'Calibration: matched your ball; sampling its visible flight...'
end
connect(event.OnClientEvent, function(...)
    local ok, err = pcall(beginCalibration, ...)
    if not ok then calibrationLabel.Text = 'Calibration unavailable: ' .. tostring(err) end
end)
connect(rus.Heartbeat, function()
    local outcomeOK=pcall(observeOutcome)
    if not outcomeOK then outcomeWatch=nil end
    if #calibrationQueue > 0 then
        pendingCalibration = calibrationQueue[#calibrationQueue]
        calibrationQueue = {}
    end
    if pendingCalibration and os.clock() - pendingCalibration.SentAt > 2 then
        pendingCalibration = nil
        calibrationLabel.Text = 'Calibration: no matching launch record. No correction applied. K copies prior records.'
    end
    local flight = flightCalibration
    if not flight then return end
    local now = os.clock()
    local age = ws:GetServerTimeNow() - flight.Start
    if age < 0 then return end
    if age > math.min(physics.MaxLifetime, flight.FlightTime + 1) then finishCalibration('sampling complete') return end
    if not flight.Visual or not flight.Visual.Parent then
        if now - flight.LastSearch < 0.2 then return end
        flight.LastSearch = now
        local visual=visualByBall[flight.Ball]
        local reference=visual and visual.Parent and visual:FindFirstChild('ReplaySourceBall')
        if reference and reference.Value==flight.Ball then flight.Visual=visual end
        if not flight.Visual then return end
    end
    if now - flight.LastSample < 0.05 then return end
    flight.LastSample = now
    local actual = flight.Visual.Position
    local expected = flight.Origin + flight.Velocity * age + flight.Gravity * (0.5 * age * age)
    local errorStuds = (actual - expected).Magnitude
    if not physics.IsFiniteVector(actual) then return end
    flight.Count = flight.Count + 1
    flight.SumSquared = flight.SumSquared + errorStuds * errorStuds
    local sample = {seconds = age, observed = xyz(actual), serverCurve = xyz(expected), errorStuds = errorStuds}
    local receiverRoot = targetRoot(flight.Receiver)
    if receiverRoot then sample.receiver = xyz(receiverRoot.Position) end
    local character=flight.Receiver and flight.Receiver.Character
    if character and receiverRoot then
        local humanoid=character:FindFirstChildOfClass('Humanoid')
        sample.receiverVerticalSpeed=receiverRoot.AssemblyLinearVelocity.Y
        sample.receiverState=humanoid and humanoid:GetState().Name or nil
        if sample.receiverState=='Jumping' and not flight.Record.firstObservedJumpSeconds then
            flight.Record.firstObservedJumpSeconds=age
        end
        local closest
        for _,name in ipairs({'LeftHand','RightHand','Left Arm','Right Arm'}) do
            local hand=character:FindFirstChild(name)
            if hand and hand:IsA('BasePart') then
                local p=hand.CFrame:PointToObjectSpace(actual)
                local d=v3.new(math.max(0,math.abs(p.X)-hand.Size.X/2),
                    math.max(0,math.abs(p.Y)-hand.Size.Y/2),math.max(0,math.abs(p.Z)-hand.Size.Z/2)).Magnitude
                closest=math.min(closest or math.huge,d)
            end
        end
        sample.ballCenterToArmBoxStuds=closest
        if closest and math.abs(age-flight.FlightTime)<=.5 then
            local prior=flight.Record.closestArmApproach
            if not prior or closest<prior.studs then
                flight.Record.closestArmApproach={studs=closest,seconds=age,visualOnly=true,
                    receiverState=sample.receiverState,verticalSpeed=sample.receiverVerticalSpeed}
            end
        end
    end
    table.insert(flight.Record.samples, sample)
end)
connect(uis.InputBegan, function(input, processed)
    if processed or input.KeyCode ~= keys.K or uis:GetFocusedTextBox() then return end
    local report = http:JSONEncode({schema = 2, place = game.PlaceId,
        notes = 'Launch comparisons are server-reported; visual errors include rendering delay. Send-to-event time is not one-way latency. Outcomes record exact-ball possession only, not confirmed catches; unknown is not incomplete.',
        records = calibrationRecords, lastRejectedFit = lastRejectedFit})
    if type(setclipboard) == 'function' then
        local ok = pcall(setclipboard, report)
        calibrationLabel.Text = ok and 'Calibration report copied. Paste it into this chat for tuning.' or 'Clipboard failed; records are in getgenv().AKI_QB_Calibration.'
    else
        warn('[AKI Calibration] ' .. report)
        calibrationLabel.Text = 'Clipboard unavailable; report printed in the console.'
    end
end)
local cleanupBeforeCalibration = bridge.Cleanup
bridge.Cleanup = function()
    outcomeWatch=nil
    finishCalibration('unloaded')
    calibrationGui:Destroy()
    cleanupBeforeCalibration()
end
env.AKI_QB_Unload = bridge.Cleanup

bridge.Rewrite = function(remote, args)
    if not active or not QBAimbotSettings.Enabled or remote ~= event then return end
    -- Freeze automatic requests during the game's throwing windup. Plain data
    -- only: calling instance methods here would break the namecall hook.
    if args[1]=='Begin Throw' then powerWindupUntil=os.clock()+5; return end
    if args[1]=='Cancel Throw Pose' then powerWindupUntil=0; return end
    if args[1]~='Throw' then return end
    powerWindupUntil=0
    powerHoldUntil=os.clock()+.75
    -- Leave non-QB actions and the game's receiver-button passes untouched.
    if type(args[2]) ~= 'table' or args[2].PassStyle or not args[2].Direction then return end
    -- No instance methods here: nested namecalls caused the old release bug.
    local solution = currentSolution
    local valid = solution and os.clock() - solution.UpdatedAt <= (fit.ExclusiveWindow and 0.12 or 0.18)
        and solution.Ball.Parent == plr.Character
        and (not solution.PowerValue or solution.PowerValue.Value == solution.Power)
    local smartMode = modes[modeIndex] == 'Smart'
    if smartMode and (not valid or (fit.Power100Only and solution.Power ~= 100)
        or ((fit.CancelUnsafe or fit.RequireClear) and not solution.Clear)) then
        -- Use the game's existing cancel action; do not silently throw manually.
        args[1] = 'Cancel Throw Pose'
        for i = 2, args.n do args[i] = nil end
        args.n = 1
        blockedUntil = os.clock() + 1.5
        return
    end
    if not valid then return end
    if solution.SmartFit and fit.RequireClear and not solution.Clear then return end
    args[2] = {Direction = solution.Direction}
    queueCalibration(solution)
end

if not bridge.Hooked then
    local original
    original = hookmetamethod(game, '__namecall', function(self, ...)
        if getnamecallmethod() == 'FireServer' and bridge.Rewrite then
            local args = table.pack(...)
            local ok = pcall(bridge.Rewrite, self, args)
            if ok then return original(self, table.unpack(args, 1, args.n)) end
        end
        return original(self, ...)
    end)
    bridge.Hooked = true
end

local lastWarning = 0
local lastFitUpdate = 0
connect(rus.RenderStepped, function()
    if os.clock() - lastFitUpdate < fit.UpdateInterval then return end
    lastFitUpdate = os.clock()
    local ok, message = pcall(function()
        currentSolution = nil
        nearestDBLbl.Text = 'Nearest DB to WR: -'
        beam.Enabled = false
        highlight.Adornee = nil
        local ball, power = getBall()
        gui.Enabled = active and QBAimbotSettings.Enabled and ball ~= nil
        if not gui.Enabled then return end
        selected = findTarget()
        lockBtn.Text = locked and 'Locked' or 'Lock'
        lockBtn.BackgroundColor3 = locked and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(0, 150, 220)
        gui.Cards.Power.Power.Text = tostring(power)
        gui.Cards.Mode.Mode.Text = modes[modeIndex]
        gui.Cards.Target.Target.Text = selected and selected.Name or 'No target'
        gui.Cards.Route.TextLabel.Text = modes[modeIndex] == 'Smart' and 'ROUTE' or 'ROUTE'
        gui.Cards.Speed.Speed.Text = '—'
        gui.Cards.Jump.Jump.Text = '—'
        gui.Cards.Route.Route.Text = '—'
        gui.Cards.Airtime.Airtime.Text = '—'
        gui.Cards.Angle.Angle.Text = '—'
        gui.Cards.Fit.Fit.Text = '—'
        gui.Cards.Suggest.Suggest.Text = fit.AutoPower and 'Auto' or 'Manual'
        if not selected then return end
        local displayRoot = targetRoot(selected)
        local displayHumanoid = selected.Character and selected.Character:FindFirstChildOfClass('Humanoid')
        if displayRoot and displayHumanoid then
            gui.Cards.Speed.Speed.Text = string.format('%.1f', Smart.cap(displayRoot.AssemblyLinearVelocity, math.huge).Magnitude)
            local liveJump = displayHumanoid.UseJumpPower and displayHumanoid.JumpPower^2 / (2 * math.max(ws.Gravity, 0.01)) or displayHumanoid.JumpHeight
            gui.Cards.Jump.Jump.Text = string.format('%.1f', math.max(0,liveJump))
        end
        highlight.Parent = gui
        highlight.Adornee = selected.Character
        if modes[modeIndex] == 'Smart' then
            currentSolution = solveFit(selected, ball, power)
            detailLbl.Text = coverageText
            gui.Cards.Fit.Fit.Text = os.clock() < blockedUntil and 'CANCELED' or fitStatus
            gui.Cards.Suggest.Suggest.Text = (recommendedPower and tostring(recommendedPower) or '—') .. (fit.Power100Only and ' ONLY' or fit.AutoPower and ' AUTO' or '')
        else
            currentSolution = solve(selected, ball, power)
            detailLbl.Text = 'Smart Fit v93 | Legacy mode: coverage protection is off'
        end
        if not currentSolution then
            gui.Cards.Fit.Fit.TextColor3 = Color3.fromRGB(255, 100, 80)
            gui.Cards.Route.Route.Text = 'No fit'
            return
        end
        local solution = currentSolution
        local ballData = ball:FindFirstChild('BallData')
        solution.PowerValue = ballData and ballData:FindFirstChild('Power')
        local color = solution.SmartFit and not solution.Clear and Color3.fromRGB(255, 100, 80) or Color3.fromRGB(0, 230, 200)
        beam.Color = ColorSequence.new(color)
        gui.Cards.Fit.Fit.TextColor3 = color
        gui.Cards.Route.Route.Text = solution.Route
        gui.Cards.Airtime.Airtime.Text = string.format('%.2fs', solution.Time)
        local horizontal = (solution.Velocity * v3.new(1, 0, 1)).Magnitude
        gui.Cards.Angle.Angle.Text = string.format('%.1f°', math.deg(math.atan2(solution.Velocity.Y, horizontal)))
        local c0, c1, cf0, cf1 = physics.BeamDirection(solution.Origin, solution.Velocity,
            v3.new(0, physics.PassGravity, 0), solution.Time)
        beam.CurveSize0, beam.CurveSize1 = c0, c1
        beamAtt0.WorldCFrame, beamAtt1.WorldCFrame = cf0, cf1
        beam.Parent = beamAttPart
        beam.Enabled = true
    end)
    if not ok and os.clock() - lastWarning > 5 then
        lastWarning = os.clock()
        warn('[AKI QB] ' .. tostring(message))
    end
end)
warn('[AKI QB Smart Fit] Q lock, T mode, R/F power, P auto power, End toggle. Tolerance cancellation OFF; coverage is advisory. End toggles manual throwing.')

if not fit.DefenderChecks then tipLbl.Text = 'R/F Power | Q Lock | T Mode | P Auto power | G 100 only | End Manual\nCoverage checks OFF. Inside/outside shoulder placement ON in Smart mode.' end

-- One calculated pass per observed jump; no mouse-direction fallback.
local jumpPending
local jumpHumanoid
local jumpConnection
local jumpStatus = create('TextLabel', gui, {
    Size=UDim2.new(0,360,0,22),Position=UDim2.new(0.5,-180,0,280),
    BackgroundTransparency=1,TextColor3=Color3.fromRGB(240,240,240),
    Font=Enum.Font.Gotham,TextSize=13,Text='J: Jump throw OFF',
})
local function cancelJumpThrow()
    local pending=jumpPending
    jumpPending=nil
    if pending and pending.Begun then event:FireServer('Cancel Throw Pose') end
end
connect(uis.InputBegan,function(input,processed)
    if processed or uis:GetFocusedTextBox() or input.KeyCode~=keys.J then return end
    fit.JumpThrow=not fit.JumpThrow
    cancelJumpThrow()
    if fit.JumpThrow then modeIndex=1;currentSolution=nil end
    jumpStatus.Text=fit.JumpThrow and 'J: Jump throw ON | Jump to pass to selected WR' or 'J: Jump throw OFF'
end)
connect(rus.Heartbeat,function()
    local character=plr.Character
    local humanoid=character and character:FindFirstChildOfClass('Humanoid')
    if humanoid~=jumpHumanoid then
        cancelJumpThrow()
        if jumpConnection then jumpConnection:Disconnect() end
        jumpHumanoid=humanoid
        if humanoid then
            jumpConnection=connect(humanoid.StateChanged,function(_,state)
                if state~=Enum.HumanoidStateType.Jumping or jumpPending then return end
                if not active or not fit.JumpThrow or not QBAimbotSettings.Enabled or modes[modeIndex]~='Smart' then return end
                if uis:GetFocusedTextBox() or powerWindupUntil>os.clock() then return end
                local ball=getBall()
                local target=locked and lockedTarget or selected
                if not ball or not target or not targetRoot(target) then return end
                jumpPending={Ball=ball,Target=target,Character=character,At=os.clock()}
            end)
        end
    end
    local pending=jumpPending
    if not pending then return end
    local ball,power=getBall()
    local now=os.clock()
    if not active or not fit.JumpThrow or not QBAimbotSettings.Enabled or modes[modeIndex]~='Smart'
        or character~=pending.Character or ball~=pending.Ball or not targetRoot(pending.Target)
        or not humanoid or humanoid.Health<=0 or now-pending.At>.4 then
        cancelJumpThrow();return
    end
    -- Wait briefly for takeoff, then calculate from the airborne ball position.
    if now-pending.At<.1 then return end
    if humanoid:GetState()~=Enum.HumanoidStateType.Jumping
        and humanoid:GetState()~=Enum.HumanoidStateType.Freefall then cancelJumpThrow();return end
    if not pending.Begun then
        if pendingPower then return end
        pending.Begun=true
        pending.ReleaseAt=now+.05
        event:FireServer('Begin Throw')
        return
    end
    if now<pending.ReleaseAt then return end
    local ok,solution=pcall(solveFit,pending.Target,ball,power)
    if not ok or not solution or (fit.Power100Only and solution.Power~=100)
        or ((fit.CancelUnsafe or fit.RequireClear) and not solution.Clear) then
        cancelJumpThrow();return
    end
    local data=ball:FindFirstChild('BallData')
    solution.PowerValue=data and data:FindFirstChild('Power')
    if not solution.PowerValue or solution.PowerValue.Value~=solution.Power then cancelJumpThrow();return end
    currentSolution=solution
    jumpPending=nil
    event:FireServer('Throw',{Direction=solution.Direction},true,false,false)
end)

-- Reference-video presentation. No prediction or throw settings are changed.
do
    local lavender=Color3.fromRGB(255,168,168)
    local cyan=Color3.fromRGB(241,55,55)
    local panel=create('Frame',gui,{Name='ReferenceHUD',AnchorPoint=Vector2.new(.5,1),
        Position=UDim2.new(.5,0,1,-105),Size=UDim2.fromOffset(680,110),
        BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=.04,BorderSizePixel=0})
    create('UICorner',panel,{CornerRadius=UDim.new(0,55)})
    create('UIStroke',panel,{Color=cyan,Thickness=1.3,Transparency=.25})
    create('UIGradient',panel,{Rotation=90,Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(141,55,55)),
        ColorSequenceKeypoint.new(.22,Color3.fromRGB(32,22,22)),
        ColorSequenceKeypoint.new(.7,Color3.fromRGB(25,18,18)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(196,86,86))})})
    -- Soft perimeter bloom, made from static strokes rather than extra world beams.
    for _,layer in ipairs({{8,.94},{5,.91},{3,.83}}) do
        local glow=create('Frame',panel,{Name='EdgeGlow',Size=UDim2.fromScale(1,1),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=0})
        create('UICorner',glow,{CornerRadius=UDim.new(0,55)})
        local stroke=create('UIStroke',glow,{Thickness=layer[1],Transparency=layer[2],Color=Color3.fromRGB(255,103,103)})
        create('UIGradient',stroke,{Rotation=90,Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(243,68,68)),
            ColorSequenceKeypoint.new(.5,Color3.fromRGB(116,35,35)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(255,112,112))})})
    end
    local scale=create('UIScale',panel,{Scale=1.14})
    local avatar=create('ImageLabel',panel,{Name='Avatar',Size=UDim2.fromOffset(78,78),
        Position=UDim2.fromOffset(18,16),BackgroundColor3=Color3.fromRGB(59,29,29),
        BackgroundTransparency=.2,BorderSizePixel=0,Image='',ScaleType=Enum.ScaleType.Crop})
    create('UICorner',avatar,{CornerRadius=UDim.new(1,0)})
    create('UIStroke',avatar,{Color=cyan,Thickness=1.5,Transparency=.2})
    local function label(name,text,x,y,w,h,size,color)
        return create('TextLabel',panel,{Name=name,Text=text,Position=UDim2.fromOffset(x,y),
            Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,TextColor3=color or lavender,
            Font=Enum.Font.GothamMedium,TextSize=size,TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd})
    end
    local display=label('DisplayName','Select a receiver',116,28,210,27,19)
    display.Font=Enum.Font.GothamBold
    local username=label('Username','',116,58,210,20,13,Color3.fromRGB(179,154,154))
    for _,x in ipairs({338,442,535}) do
        create('Frame',panel,{Size=UDim2.fromOffset(1,45),Position=UDim2.fromOffset(x,33),
            BackgroundColor3=Color3.fromRGB(145,104,104),BackgroundTransparency=.55,BorderSizePixel=0})
    end
    local powerTitle=label('PowerTitle','Power',353,27,76,20,12,Color3.fromRGB(248,232,232))
    powerTitle.TextXAlignment=Enum.TextXAlignment.Center
    local powerText=label('PowerValue','—',353,48,76,33,27)
    powerText.TextXAlignment=Enum.TextXAlignment.Center
    powerText.Font=Enum.Font.GothamBold
    local lock=create('TextButton',panel,{Name='TargetLock',Text='',Position=UDim2.fromOffset(454,22),
        Size=UDim2.fromOffset(68,70),BackgroundTransparency=1,AutoButtonColor=false})
    -- Draw a padlock from UI shapes, so no external icon asset is needed.
    local shackle=create('Frame',lock,{Size=UDim2.fromOffset(17,19),Position=UDim2.fromOffset(25,11),
        BackgroundTransparency=1,BorderSizePixel=0})
    create('UICorner',shackle,{CornerRadius=UDim.new(0,9)})
    local shackleStroke=create('UIStroke',shackle,{Color=lavender,Thickness=2})
    local lockBody=create('Frame',lock,{Size=UDim2.fromOffset(26,22),Position=UDim2.fromOffset(21,25),
        BackgroundColor3=Color3.fromRGB(35,23,23),BorderSizePixel=0})
    create('UICorner',lockBody,{CornerRadius=UDim.new(0,3)})
    local bodyStroke=create('UIStroke',lockBody,{Color=lavender,Thickness=2})
    local keyhole=create('Frame',lockBody,{Size=UDim2.fromOffset(4,7),Position=UDim2.fromOffset(11,7),
        BackgroundColor3=lavender,BorderSizePixel=0})
    create('UICorner',keyhole,{CornerRadius=UDim.new(1,0)})
    local lockCaption=create('TextLabel',lock,{Size=UDim2.new(1,0,0,16),Position=UDim2.fromOffset(0,52),
        Text='Q · LOCK',Font=Enum.Font.GothamMedium,TextSize=10,TextColor3=lavender,BackgroundTransparency=1})
    connect(lock.Activated,lockTarget)
    local logo=label('Brand','<font color="#FFFFFF">A</font><font color="#FF404C">K</font><font color="#FFFFFF">I</font>',558,24,106,48,40)
    logo.Visible=false
    local brandA=label('BrandA','A',557,25,42,48,44,Color3.fromRGB(255,246,246))
    brandA.Font=Enum.Font.GothamBlack
    local brandI=label('BrandI','I',626,25,24,48,44,Color3.fromRGB(255,246,246))
    brandI.Font=Enum.Font.GothamBlack
    -- Angular cyan mark in the reference logo.
    for _,arm in ipairs({{599,42,-35},{599,56,35}}) do
        create('Frame',panel,{Position=UDim2.fromOffset(arm[1],arm[2]),Size=UDim2.fromOffset(27,10),
            Rotation=arm[3],BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(250,27,27)})
    end
    lockCaption.Visible=false
    local details=create('TextButton',panel,{Text='',Position=UDim2.fromOffset(548,17),
        Size=UDim2.fromOffset(112,77),BackgroundTransparency=1,TextSize=10,
        Font=Enum.Font.GothamMedium,TextColor3=Color3.fromRGB(204,175,175)})
    local routeText=label('RouteType','ROUTE · —',116,81,215,17,11,Color3.fromRGB(244,103,103))
    local status=label('Status','',347,84,185,16,10,Color3.fromRGB(225,181,181))
    local expanded=false
    local panelTweens={}
    local tweenService=game:GetService('TweenService')
    local function tweenColor(object,property,color)
        local running=panelTweens[object]
        if running then running:Cancel() end
        local tween=tweenService:Create(object,TweenInfo.new(.14,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{[property]=color})
        panelTweens[object]=tween
        tween:Play()
    end
    local previousLock

    -- Keep the old data labels for existing logic, but never display their panels.
    details.Visible=false
    details.Active=false
    for _,oldPanel in ipairs({Cards,Mobile,tipLbl,detailLbl,nearestDBLbl,calibrationLabel,jumpStatus}) do
        oldPanel.Visible=false
        connect(oldPanel:GetPropertyChangedSignal('Visible'),function()
            if oldPanel.Visible then oldPanel.Visible=false end
        end)
    end
    local avatarPlayer
    local lastUpdate=0
    local thumbnails={}
    connect(rus.Heartbeat,function()
        if not active or not gui.Enabled or os.clock()-lastUpdate<.1 then return end
        lastUpdate=os.clock()
        local camera=ws.CurrentCamera
        if camera then scale.Scale=math.clamp(camera.ViewportSize.X/1680,.35,1.55) end
        local target=selected
        display.Text=target and target.DisplayName or 'Select a receiver'
        username.Text=target and target.Name or 'Aim near a teammate'
        local route=currentSolution and currentSolution.Player==target and currentSolution.Route
        local tracked=target and routeStates[target]
        if not route and tracked and tracked.Character==target.Character then route=tracked.Label end
        routeText.Text='ROUTE · '..(route or '—')
        powerText.Text=gui.Cards.Power.Power.Text
        local lockColor=locked and cyan or lavender
        if previousLock~=locked then
            previousLock=locked
            tweenColor(shackleStroke,'Color',lockColor)
            tweenColor(bodyStroke,'Color',lockColor)
            tweenColor(keyhole,'BackgroundColor3',lockColor)
        end
        shackle.Rotation=locked and 0 or -22
        lockCaption.Text=locked and 'Q · LOCKED' or 'Q · LOCK'
        status.Text=currentSolution and '' or (target and gui.Cards.Fit.Fit.Text or '')
        if avatarPlayer~=target then
            avatarPlayer=target
            avatar.Image=target and thumbnails[target.UserId] or ''
            if target and not thumbnails[target.UserId] then
                task.spawn(function()
                    local ok,url=pcall(function()
                        return players:GetUserThumbnailAsync(target.UserId,Enum.ThumbnailType.AvatarBust,Enum.ThumbnailSize.Size150x150)
                    end)
                    if ok and active then
                        thumbnails[target.UserId]=url
                        if avatarPlayer==target then avatar.Image=url end
                    end
                end)
            end
        end
    end)
end


-- Presentation-only glow: share the solver's exact attachments and curve sizes.
do
    local arcColor=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,86,86)),
        ColorSequenceKeypoint.new(.48,Color3.fromRGB(255,126,126)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,175,175))})
    local coreColor=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,206,206)),
        ColorSequenceKeypoint.new(.55,Color3.fromRGB(255,206,206)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,225,225))})
    local layers={}
    for i,style in ipairs({{1.5,1.05,.91},{.8,.5,.65},{.28,.17,.06}}) do
        layers[i]=create('Beam',beamAttPart,{Name='AKIGlowArc'..i,
            Attachment0=beamAtt0,Attachment1=beamAtt1,
            CurveSize0=beam.CurveSize0,CurveSize1=beam.CurveSize1,
            Width0=style[1],Width1=style[2],Segments=64,FaceCamera=true,
            LightEmission=1,LightInfluence=0,Enabled=false,
            Color=i==3 and coreColor or arcColor,
            Transparency=NumberSequence.new({
                NumberSequenceKeypoint.new(0,math.min(.98,style[3]+.04)),
                NumberSequenceKeypoint.new(.25,style[3]),
                NumberSequenceKeypoint.new(.8,style[3]),
                NumberSequenceKeypoint.new(1,math.min(.98,style[3]+.13))})})
    end
    -- Keep the original beam as the presentation controller used by the solver.
    beam.Transparency=NumberSequence.new(1)
    local function syncArc()
        local visible=active and gui.Enabled and beam.Parent~=nil and beam.Enabled
        for _,layer in ipairs(layers) do
            layer.CurveSize0,layer.CurveSize1=beam.CurveSize0,beam.CurveSize1
            layer.Enabled=visible
        end
    end
    for _,property in ipairs({'CurveSize0','CurveSize1','Enabled','Parent'}) do
        connect(beam:GetPropertyChangedSignal(property),syncArc)
    end
    connect(gui:GetPropertyChangedSignal('Enabled'),syncArc)
    syncArc()
    -- Existing cleanup destroys beamAttPart and all glow layers, and disconnects signals.
end


-- Presentation-only endpoint ball. Uses the existing arc endpoint, never the solver.
do
    local ball=create('Part',beamAttPart,{
        Name='AKIArcEndpointBall',Shape=Enum.PartType.Ball,
        Size=Vector3.new(1.7,1.7,1.7),Anchored=true,
        CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,
        Material=Enum.Material.Neon,Color=Color3.fromRGB(255,205,205),Transparency=1})
    local glow=create('BillboardGui',ball,{
        Name='AKIArcEndpointGlow',Adornee=ball,Size=UDim2.fromOffset(48,48),
        AlwaysOnTop=false,LightInfluence=0,Enabled=false})
    for _,style in ipairs({{1,.94},{.75,.88},{.5,.66},{.22,.12}}) do
        local ring=create('Frame',glow,{
            AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
            Size=UDim2.fromScale(style[1],style[1]),BorderSizePixel=0,
            BackgroundColor3=Color3.fromRGB(255,65,75),BackgroundTransparency=style[2]})
        create('UICorner',ring,{CornerRadius=UDim.new(1,0)})
    end
    local function syncEndpoint()
        local visible=active and gui.Enabled and beam.Parent~=nil and beam.Enabled
        if visible then ball.Position=beamAtt1.WorldPosition end
        ball.Transparency=visible and 0 or 1
        glow.Enabled=visible
    end
    connect(beamAtt1:GetPropertyChangedSignal('WorldCFrame'),syncEndpoint)
    connect(beam:GetPropertyChangedSignal('Enabled'),syncEndpoint)
    connect(beam:GetPropertyChangedSignal('Parent'),syncEndpoint)
    connect(gui:GetPropertyChangedSignal('Enabled'),syncEndpoint)
    syncEndpoint()
    -- The existing unload destroys beamAttPart and disconnects these connections.
end
