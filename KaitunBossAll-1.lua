-- ============================================================
--            KAITUN BOSS (ALL) - Auto Farm All Boss
--            By: Kaitun | Blox Fruits Script
-- ============================================================

local Players        = game:GetService("Players")
local TeleportService= game:GetService("TeleportService")
local HttpService    = game:GetService("HttpService")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Plr  = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId   = game.JobId

-- ─── World detect ────────────────────────────────────────────
local World1, World2, World3 = false, false, false
if PlaceId == 2753915549 or PlaceId == 85211729168715 then
    World1 = true
elseif PlaceId == 4442272183 or PlaceId == 79091703265657 then
    World2 = true
elseif PlaceId == 7449423635 or PlaceId == 100117331123089 then
    World3 = true
end

-- ─── TweenSpeed ──────────────────────────────────────────────
local TweenSpeed = 350

-- ─── Boss list per sea (loại trừ Ice Admiral [lv.700]) ───────
local BossLists = {
    World1 = {
        "The Gorilla King",
        "Bobby",
        "Yeti",
        "Mob Leader",
        "Vice Admiral",
        "Warden",
        "Chief Warden",
        "Swan",
        "Magma Admiral",
        "Fishman Lord",
        "Wysper",
        "Thunder God",
        "Cyborg",
        "Saber Expert",
    },
    World2 = {
        "Diamond",
        "Jeremy",
        "Fajita",
        "Don Swan",
        "Smoke Admiral",
        "Cursed Captain",
        "Darkbeard",
        "Order",
        "Awakened Ice Admiral",
        "Tide Keeper",
    },
    World3 = {
        "Tyrant of the Skies",
        "Stone",
        "Island Empress",
        "Kilo Admiral",
        "Captain Elephant",
        "Beautiful Pirate",
        "rip_indra True Form",
        "Longma",
        "Soul Reaper",
        "Cake Queen",
    },
}

-- ─── Lấy đúng boss list theo sea hiện tại ───────────────────
local function GetCurrentBossList()
    if World1 then return BossLists.World1
    elseif World2 then return BossLists.World2
    elseif World3 then return BossLists.World3
    end
    return {}
end

-- ─── Trạng thái ──────────────────────────────────────────────
_G.KaitunAllBoss     = false
local killedBosses   = {}
local currentBossName = ""
local currentDistance = 0

-- ─── AutoHaki / Buso ────────────────────────────────────────
local function AutoHaki()
    pcall(function()
        local char = Plr.Character
        if char and not char:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end
    end)
end

-- Bật Buso ngay khi script chạy
task.spawn(function()
    while task.wait(3) do
        AutoHaki()
    end
end)

-- ─── Tween bay đến vị trí ────────────────────────────────────
local function TweenTo(targetCF)
    pcall(function()
        local char = Plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- NoClip
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end

        local dist = (targetCF.Position - hrp.Position).Magnitude
        local t = math.max(dist / TweenSpeed, 0.05)
        local tw = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = targetCF})
        tw:Play()
        tw.Completed:Wait()
    end)
end

-- ─── Server Hop ──────────────────────────────────────────────
local function Hop()
    pcall(function()
        local cursor = ""
        local tried  = {}
        local function fetchServers()
            local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url.."&cursor="..cursor end
            local data = HttpService:JSONDecode(game:HttpGet(url))
            if data.nextPageCursor then cursor = data.nextPageCursor end
            for _, s in pairs(data.data) do
                if s.id ~= JobId and s.playing < s.maxPlayers and not tried[s.id] then
                    tried[s.id] = true
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(PlaceId, s.id, Plr)
                    end)
                    return
                end
            end
        end
        for _ = 1, 5 do
            fetchServers()
            task.wait(0.5)
        end
        TeleportService:Teleport(PlaceId, Plr)
    end)
end

-- ─── Rejoin khi bị văng ──────────────────────────────────────
Plr.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        TeleportService:Teleport(PlaceId, Plr)
    end
end)

-- ─── Anti AFK ────────────────────────────────────────────────
local VirtualUser = game:GetService("VirtualUser")
Plr.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ─── Tìm boss trong Workspace.Enemies hoặc ReplicatedStorage ─
local function FindBoss(name)
    local ws = workspace.Enemies:FindFirstChild(name)
    if ws then return ws end
    local rs = ReplicatedStorage:FindFirstChild(name)
    if rs then return rs end
    return nil
end

-- ─── Kill 1 boss ─────────────────────────────────────────────
local function KillBoss(bossName)
    currentBossName = bossName
    local timeout = 60 -- tối đa 60s chờ boss
    local t0 = tick()

    -- Chờ boss spawn hoặc bỏ qua
    while tick() - t0 < timeout do
        if not _G.KaitunAllBoss then return false end
        local boss = FindBoss(bossName)
        if boss then break end
        task.wait(1)
    end

    local boss = FindBoss(bossName)
    if not boss then
        currentBossName = "Skipped (not spawned): "..bossName
        return false -- chưa spawn → bỏ qua
    end

    -- Bay đến boss và tấn công
    while _G.KaitunAllBoss do
        pcall(function()
            boss = FindBoss(bossName)
            if not boss then return end

            local hrpBoss = boss:FindFirstChild("HumanoidRootPart")
            local hum     = boss:FindFirstChild("Humanoid")
            if not hrpBoss or not hum then return end
            if hum.Health <= 0 then return end

            currentDistance = math.floor((hrpBoss.Position - Plr.Character.HumanoidRootPart.Position).Magnitude)

            AutoHaki()
            hrpBoss.CanCollide = false
            hum.WalkSpeed = 0
            TweenTo(hrpBoss.CFrame * CFrame.new(0, 20, 5))
            sethiddenproperty(Plr, "SimulationRadius", math.huge)
        end)

        -- Kiểm tra boss đã chết chưa
        local b2 = FindBoss(bossName)
        if not b2 then break end
        local h = b2:FindFirstChild("Humanoid")
        if not h or h.Health <= 0 then break end
        task.wait()
    end

    currentBossName = "Killed: "..bossName
    return true
end

-- ─── Main loop: farm tất cả boss trong sea hiện tại ──────────
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.KaitunAllBoss then
            local bossList = GetCurrentBossList()
            local allDone  = true

            for _, bossName in ipairs(bossList) do
                if not _G.KaitunAllBoss then break end

                if not killedBosses[bossName] then
                    currentBossName = "Hunting: "..bossName
                    local killed = KillBoss(bossName)
                    if killed then
                        killedBosses[bossName] = true
                    end
                    allDone = false
                end
            end

            -- Nếu đã farm hết tất cả boss → đổi server ngay (tối đa 1s)
            if allDone then
                currentBossName = "All Bosses Done! Hopping..."
                killedBosses    = {}
                task.wait(1)
                Hop()
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--                          UI
-- ═══════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "KaitunBossUI"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = Plr:WaitForChild("PlayerGui")

-- ─── Dim overlay (làm mờ 50%) ────────────────────────────────
local dimFrame = Instance.new("Frame")
dimFrame.Name            = "DimOverlay"
dimFrame.Size            = UDim2.new(1, 0, 1, 0)
dimFrame.BackgroundColor3= Color3.fromRGB(0, 0, 0)
dimFrame.BackgroundTransparency = 0.5
dimFrame.BorderSizePixel = 0
dimFrame.ZIndex          = 1
dimFrame.Parent          = screenGui

-- ─── Main label frame (giữa màn hình) ────────────────────────
local mainFrame = Instance.new("Frame")
mainFrame.Name                  = "KaitunFrame"
mainFrame.AnchorPoint           = Vector2.new(0.5, 0.5)
mainFrame.Position              = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size                  = UDim2.new(0, 320, 0, 100)
mainFrame.BackgroundTransparency= 1
mainFrame.ZIndex                = 2
mainFrame.Parent                = screenGui

-- Title "Kaitun Boss ( All )"
local titleLabel = Instance.new("TextLabel")
titleLabel.Name              = "TitleLabel"
titleLabel.Size              = UDim2.new(1, 0, 0, 40)
titleLabel.Position          = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text              = "Kaitun Boss ( All )"
titleLabel.TextColor3        = Color3.fromRGB(100, 180, 255)  -- Xanh dương nhạt
titleLabel.TextScaled        = false
titleLabel.TextSize          = 26
titleLabel.Font              = Enum.Font.GothamBold
titleLabel.ZIndex            = 2
titleLabel.Parent            = mainFrame

-- Boss: ...
local bossLabel = Instance.new("TextLabel")
bossLabel.Name              = "BossLabel"
bossLabel.Size              = UDim2.new(1, 0, 0, 26)
bossLabel.Position          = UDim2.new(0, 0, 0, 42)
bossLabel.BackgroundTransparency = 1
bossLabel.Text              = "Boss: Waiting..."
bossLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
bossLabel.TextScaled        = false
bossLabel.TextSize          = 15
bossLabel.Font              = Enum.Font.Gotham
bossLabel.ZIndex            = 2
bossLabel.Parent            = mainFrame

-- Distance: ...
local distLabel = Instance.new("TextLabel")
distLabel.Name              = "DistLabel"
distLabel.Size              = UDim2.new(1, 0, 0, 26)
distLabel.Position          = UDim2.new(0, 0, 0, 68)
distLabel.BackgroundTransparency = 1
distLabel.Text              = "Distance: 0"
distLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
distLabel.TextScaled        = false
distLabel.TextSize          = 15
distLabel.Font              = Enum.Font.Gotham
distLabel.ZIndex            = 2
distLabel.Parent            = mainFrame

-- ─── Nút toggle UI (góc trái dưới nút avatar Roblox) ─────────
local toggleBtn = Instance.new("ImageButton")
toggleBtn.Name              = "ToggleUIBtn"
toggleBtn.Size              = UDim2.new(0, 40, 0, 40)
toggleBtn.Position          = UDim2.new(0, 10, 0, 100) -- dưới avatar Roblox ~y=100
toggleBtn.BackgroundTransparency = 1
toggleBtn.Image             = "rbxassetid://16060333448"
toggleBtn.ZIndex            = 10
toggleBtn.Parent            = screenGui

local uiVisible = true
toggleBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    mainFrame.Visible = uiVisible
    dimFrame.Visible  = uiVisible
end)

-- ─── Update label mỗi frame ──────────────────────────────────
RunService.Heartbeat:Connect(function()
    pcall(function()
        if _G.KaitunAllBoss then
            bossLabel.Text  = "Boss: " .. currentBossName
            distLabel.Text  = "Distance: " .. tostring(currentDistance)
        else
            bossLabel.Text  = "Boss: OFF"
            distLabel.Text  = "Distance: -"
        end

        -- Cập nhật distance thực
        if _G.KaitunAllBoss and currentBossName ~= "" then
            local boss = workspace.Enemies:FindFirstChild(
                currentBossName:gsub("Hunting: ",""):gsub("Killed: ",""):gsub("Skipped.*","")
            )
            if boss and boss:FindFirstChild("HumanoidRootPart") and Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
                currentDistance = math.floor((boss.HumanoidRootPart.Position - Plr.Character.HumanoidRootPart.Position).Magnitude)
            end
        end
    end)
end)

-- ─── Bật ngay khi chạy script ────────────────────────────────
_G.KaitunAllBoss = true
killedBosses     = {}
print("[Kaitun] Boss All Farm - STARTED")
