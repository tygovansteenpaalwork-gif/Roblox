-- MM2 coin farm: only moves your own character to coins. Starts on its own.
-- Override settings by setting getgenv().CoinFarmConfig = { TweenSpeed = 20, ... } before loading.
-- Stop it with: getgenv().CoinFarm.stop()

local Config = {
    -- Studs per second while tweening to a coin. Walking is 16; much higher gets flagged more easily.
    TweenSpeed = 25,
    -- Coins further than this are skipped so we never cross the whole map in one go.
    MaxCoinDistance = 300,
    -- Pause after reaching a coin so the touch registers.
    DelayAfterCoin = 0.15,
    -- A coin that still is not collected after this many visits gets skipped for the rest of the round.
    MaxAttemptsPerCoin = 2,
    -- How often to check for a new round while waiting.
    IdleCheckInterval = 1,
    -- Reset when the bag is full, so you are out of the round instead of standing around.
    ResetWhenBagFull = true,
    -- Skip coins near the Murderer and abort a tween when they get close.
    AvoidMurderer = true,
    MurdererSafeDistance = 40,
    ShowNotifications = true,
}

-- Only known settings with the right type are taken over, so a typo cannot break the farm.
local userConfig = getgenv().CoinFarmConfig
if type(userConfig) == "table" then
    for key, value in pairs(userConfig) do
        if Config[key] == nil then
            warn(string.format("[CoinFarm] Unknown setting ignored: %s", tostring(key)))
        elseif type(value) ~= type(Config[key]) then
            warn(string.format("[CoinFarm] Setting %s must be a %s, got %s", key, type(Config[key]), type(value)))
        elseif type(value) == "number" and (value < 0 or (key == "TweenSpeed" and value == 0)) then
            warn(string.format("[CoinFarm] Setting %s has an invalid value: %s", key, tostring(value)))
        else
            Config[key] = value
        end
    end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

if getgenv().CoinFarm then
    getgenv().CoinFarm.stop()
end

local running = true
local activeTween = nil
local connections = {}

-- Player name -> role ("Murderer", "Sheriff", "Innocent", or "Dead"), filled from the game's own role updates.
local rolesByName = {}
-- Coin -> number of times we reached it without it being collected.
local coinAttempts = setmetatable({}, { __mode = "k" })

local function notify(text)
    if not Config.ShowNotifications then
        return
    end
    pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
        Title = "Coin Farm",
        Text = text,
        Duration = 3,
    })
end

local function getHumanoid()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        return humanoid
    end
    return nil
end

local function getRootPart()
    local humanoid = getHumanoid()
    return humanoid and humanoid.Parent:FindFirstChild("HumanoidRootPart")
end

local function getCoinContainer()
    return workspace:FindFirstChild("CoinContainer", true)
end

-- The game sets Alive on the player while they are playing a round.
local function isInRound()
    return LocalPlayer:GetAttribute("Alive") == true and getCoinContainer() ~= nil
end

-- The game swaps which bag frame is visible depending on the event currency (Coin, Candy, ...).
local function isBagFull()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local bags = playerGui and playerGui:FindFirstChild("CoinBags", true)
    if not bags then
        return false
    end
    for _, label in ipairs(bags:GetDescendants()) do
        if label.Name == "Full" and label:IsA("TextLabel") and label.Visible and label.Parent.Visible then
            return true
        end
    end
    return false
end

local function hasTool(player, toolName)
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")
    return (character and character:FindFirstChild(toolName)) or (backpack and backpack:FindFirstChild(toolName))
end

-- Role updates only arrive when the game sends them, so a script started mid-round has no role data yet.
-- The Knife/Gun check covers that gap; other players' Backpacks replicate, so it works unequipped.
local function getRole(player)
    local role = rolesByName[player.Name]
    if role then
        return role
    end
    if hasTool(player, "Knife") then
        return "Murderer"
    end
    if hasTool(player, "Gun") then
        return "Sheriff"
    end
    return nil
end

local function getMurdererPosition()
    if not Config.AvoidMurderer then
        return nil
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getRole(player) == "Murderer" then
            local character = player.Character
            local murdererRoot = character and character:FindFirstChild("HumanoidRootPart")
            if murdererRoot then
                return murdererRoot.Position
            end
        end
    end
    return nil
end

local function isNearMurderer(position, murdererPosition)
    return murdererPosition ~= nil and (position - murdererPosition).Magnitude < Config.MurdererSafeDistance
end

-- A coin is unsafe if it is near the Murderer, or if we are already close and it lies towards them.
-- Coins that lead away from the Murderer stay allowed so we can escape.
local function isUnsafeTarget(coinPosition, ourPosition, murdererPosition)
    if not murdererPosition then
        return false
    end
    if isNearMurderer(coinPosition, murdererPosition) then
        return true
    end
    return isNearMurderer(ourPosition, murdererPosition)
        and (coinPosition - murdererPosition).Magnitude < (ourPosition - murdererPosition).Magnitude
end

local function isCollectable(coin)
    return coin:IsA("BasePart")
        and coin:FindFirstChildOfClass("TouchTransmitter") ~= nil
        and (coinAttempts[coin] or 0) < Config.MaxAttemptsPerCoin
end

local function findNearestCoin(rootPart)
    local container = getCoinContainer()
    if not container then
        return nil
    end

    local murdererPosition = getMurdererPosition()
    local nearest, nearestDistance = nil, Config.MaxCoinDistance
    for _, coin in ipairs(container:GetChildren()) do
        if isCollectable(coin) and not isUnsafeTarget(coin.Position, rootPart.Position, murdererPosition) then
            local distance = (coin.Position - rootPart.Position).Magnitude
            if distance < nearestDistance then
                nearest, nearestDistance = coin, distance
            end
        end
    end
    return nearest, nearestDistance
end

-- Returns true only when the tween ran to the end.
local function tweenTo(rootPart, coin, distance)
    local tween = TweenService:Create(
        rootPart,
        TweenInfo.new(distance / Config.TweenSpeed, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(coin.Position) }
    )
    activeTween = tween
    tween:Play()

    local reached = false
    while true do
        if tween.PlaybackState == Enum.PlaybackState.Completed then
            reached = true
            break
        end
        if tween.PlaybackState ~= Enum.PlaybackState.Playing then
            break
        end
        -- Stop early if the coin gets taken, we die, the Murderer gets in the way, or the farm is stopped.
        if
            not running
            or not getHumanoid()
            or not coin:FindFirstChildOfClass("TouchTransmitter")
            or isUnsafeTarget(coin.Position, rootPart.Position, getMurdererPosition())
        then
            tween:Cancel()
            break
        end
        task.wait()
    end
    activeTween = nil
    return reached
end

local function collectCoin(rootPart, coin, distance)
    if not tweenTo(rootPart, coin, distance) then
        return
    end
    task.wait(Config.DelayAfterCoin)
    if coin.Parent and coin:FindFirstChildOfClass("TouchTransmitter") then
        coinAttempts[coin] = (coinAttempts[coin] or 0) + 1
    end
end

local function handleFullBag()
    local myRole = getRole(LocalPlayer)
    if not Config.ResetWhenBagFull then
        notify("Bag full. Waiting for next round.")
    elseif myRole == "Murderer" or myRole == "Sheriff" then
        -- Dying as Murderer ends the round and as Sheriff drops the gun: both affect everyone else.
        notify("Bag full. Not resetting: you are " .. myRole .. ".")
    else
        notify("Bag full. Resetting.")
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.Health = 0
        end
    end
end

local function onRoundEnded()
    table.clear(rolesByName)
    table.clear(coinAttempts)
end

local function farmLoop()
    -- The Full label stays visible until the next round, so only handle it once per full bag.
    local handledFullBag = false
    local wasInRound = false
    local hadMap = false

    while running do
        local inRound = isInRound()
        if inRound ~= wasInRound then
            wasInRound = inRound
            if inRound then
                notify("Round started. Farming.")
            else
                notify("Waiting for round...")
            end
        end
        -- Tracked separately from Alive: after a reset we are out of the round while it keeps going.
        local hasMap = getCoinContainer() ~= nil
        if hadMap and not hasMap then
            onRoundEnded()
        end
        hadMap = hasMap

        local rootPart = getRootPart()
        local bagFull = isBagFull()
        if not bagFull then
            handledFullBag = false
        elseif inRound and rootPart and not handledFullBag then
            handledFullBag = true
            handleFullBag()
        end

        local coin, distance
        if inRound and rootPart and not bagFull then
            coin, distance = findNearestCoin(rootPart)
        end

        if coin then
            collectCoin(rootPart, coin, distance)
        else
            task.wait(Config.IdleCheckInterval)
        end
    end
end

local function trackRoles()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local gameplay = remotes and remotes:FindFirstChild("Gameplay")
    local playerDataChanged = gameplay and gameplay:FindFirstChild("PlayerDataChanged")
    if not playerDataChanged then
        warn("[CoinFarm] PlayerDataChanged remote not found, using Knife/Gun detection only")
        return
    end

    table.insert(
        connections,
        playerDataChanged.OnClientEvent:Connect(function(data)
            if type(data) ~= "table" then
                return
            end
            for name, playerData in pairs(data) do
                if type(name) == "string" and type(playerData) == "table" and type(playerData.Role) == "string" then
                    -- A dead Murderer is no threat, so stop avoiding them.
                    rolesByName[name] = playerData.Dead == true and "Dead" or playerData.Role
                end
            end
        end)
    )
end

-- Without this, gravity pulls the character down while the tween moves it.
table.insert(
    connections,
    RunService.Heartbeat:Connect(function()
        if activeTween then
            local rootPart = getRootPart()
            if rootPart then
                rootPart.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
)

getgenv().CoinFarm = {
    Config = Config,
    stop = function()
        running = false
        if activeTween then
            activeTween:Cancel()
        end
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        notify("Stopped.")
    end,
}

trackRoles()
task.spawn(farmLoop)
notify("Loaded. Farming starts automatically.")
