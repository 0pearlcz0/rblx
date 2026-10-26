-- ══════════════════════════════════════════════════════════════
--  MM2 SHORT — PHASE 1E (player picker + bayblade + aimbot + venyx features)
--  INSERT = menu · DELETE = panic · END = watermark
-- ══════════════════════════════════════════════════════════════
local BUILD = "PHASE-1E"

pcall(function() if _G.__MM2Short_Destroy then _G.__MM2Short_Destroy() end end)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local Camera           = Workspace.CurrentCamera
local LP               = Players.LocalPlayer

local T = {
    BG      = Color3.fromRGB(10,10,13),
    Surface = Color3.fromRGB(18,18,22),
    Accent  = Color3.fromRGB(214,40,56),
    AccentDrk=Color3.fromRGB(140,20,35),
    Text    = Color3.fromRGB(240,240,245),
    Dim     = Color3.fromRGB(140,140,150),
    Faint   = Color3.fromRGB(80,80,90),
    Good    = Color3.fromRGB(72,199,116),
    Warn    = Color3.fromRGB(232,172,62),
    Bad     = Color3.fromRGB(226,72,72),
    Border  = Color3.fromRGB(35,35,42),
    Murd    = Color3.fromRGB(255,60,60),
    Sher    = Color3.fromRGB(255,200,50),
    Inno    = Color3.fromRGB(80,160,255),
    Gun     = Color3.fromRGB(0,120,255),
    Knife   = Color3.fromRGB(255,30,30),
    None    = Color3.fromRGB(0,220,80),
}

-- HELPERS
local function tw(i,p,t,s,d)
    local tween = TweenService:Create(i, TweenInfo.new(t or 0.25, s or Enum.EasingStyle.Quint, d or Enum.EasingDirection.Out), p)
    tween:Play() return tween
end
local function corner(i,r)
    local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=i return c
end
local function stroke(i,c,t,tr)
    local s=Instance.new("UIStroke") s.Color=c or T.Border s.Thickness=t or 1 s.Transparency=tr or 0
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=i return s
end
local function lbl(p,txt,sz,col,fnt,xa,pos,s2)
    local l=Instance.new("TextLabel") l.Parent=p l.BackgroundTransparency=1 l.Text=txt or ""
    l.TextSize=sz or 13 l.TextColor3=col or T.Text l.Font=fnt or Enum.Font.Gotham
    l.TextXAlignment=xa or Enum.TextXAlignment.Left l.Position=pos or UDim2.new(0,0,0,0)
    l.Size=s2 or UDim2.new(1,0,1,0) l.TextTruncate=Enum.TextTruncate.AtEnd return l
end
local function mount(g)
    local ok=pcall(function()
        if typeof(gethui)=="function" then g.Parent=gethui()
        else g.Parent=game:GetService("CoreGui") end
    end)
    if not ok or not g.Parent then g.Parent=LP:WaitForChild("PlayerGui") end
    return g
end
local function clearOld(n)
    for _,p in ipairs({LP:FindFirstChild("PlayerGui"),game:FindFirstChild("CoreGui")}) do
        if p then pcall(function() local o=p:FindFirstChild(n) if o then o:Destroy() end end) end
    end
    pcall(function() if typeof(gethui)=="function" then local o=gethui():FindFirstChild(n) if o then o:Destroy() end end end)
end
for _,n in ipairs({"MM2Short","MM2ShortVis","MM2ShortWM"}) do clearOld(n) end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 3})
    end)
    print("[" .. title .. "] " .. text)
end

-- WATERMARK
local WM=mount(Instance.new("ScreenGui"))
WM.Name="MM2ShortWM" WM.ResetOnSpawn=false WM.DisplayOrder=996
local wmFrame=Instance.new("Frame") wmFrame.Size=UDim2.new(0,220,0,30) wmFrame.Position=UDim2.new(0,10,0,10)
wmFrame.BackgroundColor3=T.Surface wmFrame.BackgroundTransparency=0.1 wmFrame.BorderSizePixel=0 wmFrame.Parent=WM
corner(wmFrame,6) stroke(wmFrame,T.Accent,1,0.3)
lbl(wmFrame,"🔪 MM2 Short",12,T.Text,Enum.Font.GothamBold,Enum.TextXAlignment.Left,UDim2.new(0,10,0,0),UDim2.new(0.6,0,1,0))
local wmInfo=lbl(wmFrame,"",10,T.Sher,Enum.Font.GothamBold,Enum.TextXAlignment.Right,UDim2.new(0.6,0,0,0),UDim2.new(0.4,-10,1,0))

-- ROLE DETECTION
local roleMemory = {}
local function clearRoleMemory() roleMemory = {} end
local function checkToolName(tn)
    if not tn then return nil end
    tn = tn:lower()
    if tn:find("knife") or tn:find("blade") or tn:find("machete") or tn:find("dagger") then return "murderer" end
    if tn:find("gun") or tn:find("revolver") or tn:find("pistol") then return "sheriff" end
    return nil
end
local function scanForTools(container)
    if not container then return nil end
    local ok, result = pcall(function()
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("Tool") then
                local r = checkToolName(obj.Name)
                if r then return r end
            end
        end
        return nil
    end)
    return ok and result or nil
end
local function getPlayerRole(player)
    if not player then return "innocent" end
    local pname = player.Name
    if roleMemory[pname] then return roleMemory[pname] end
    local found = scanForTools(player.Character) or scanForTools(player:FindFirstChild("Backpack"))
    if found then roleMemory[pname] = found; return found end
    return "innocent"
end
local watchedChars = {}
local function watchPlayer(p)
    if p == LP then return end
    local function hookCharacter(charObj)
        if not charObj then return end
        if watchedChars[charObj] then return end
        watchedChars[charObj] = true
        charObj.ChildAdded:Connect(function(child)
            if not child:IsA("Tool") then return end
            local r = checkToolName(child.Name)
            if r then roleMemory[p.Name] = r end
        end)
    end
    if p.Character then hookCharacter(p.Character) end
    p.CharacterAdded:Connect(hookCharacter)
end
for _,p in pairs(Players:GetPlayers()) do pcall(watchPlayer, p) end
Players.PlayerAdded:Connect(function(p) pcall(watchPlayer, p) end)

local function roleColor(role, isDead)
    if isDead then return T.Faint end
    return role=="murderer" and T.Murd or role=="sheriff" and T.Sher or T.Inno
end
local function roleText(role, isDead)
    if isDead then return "DEAD" end
    return role=="murderer" and "MURDERER" or role=="sheriff" and "SHERIFF" or "INNOCENT"
end

-- WEAPON DETECTION (z Venyx: Gun/Knife/None)
local function getWeaponType(p)
    if not p or p == LP then return "None" end
    local function scan(container)
        if not container then return nil end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("gun") or n:find("revolver") or n:find("pistol") then return "Gun" end
                if n:find("knife") or n:find("blade") then return "Knife" end
            end
        end
        return nil
    end
    return scan(p.Character) or scan(p:FindFirstChild("Backpack")) or "None"
end

-- SKIDFLING + BAYBLADE
local FlingActive = false
local FlingOldPos = nil
local FlingFPDH = Workspace.FallenPartsDestroyHeight
local BaybladeActive = false
local BaybladeTarget = nil

local function SkidFling(TargetPlayer, offset)
    local Character = LP.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    if not (Character and Humanoid and RootPart) then return end
    if RootPart.Velocity.Magnitude < 50 then FlingOldPos = RootPart.CFrame end
    if THumanoid and THumanoid.Sit then return end
    if THead then Workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then Workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid and TRootPart then Workspace.CurrentCamera.CameraSubject = THumanoid end
    if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

    offset = offset or 0

    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * CFrame.new(0, 0, -offset) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * CFrame.new(0, 0, -offset) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0
        repeat
            if RootPart and THumanoid then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                end
            end
        until Time + TimeToWait < tick() or not FlingActive
    end

    Workspace.FallenPartsDestroyHeight = 0/0
    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(0, 0, 0)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TRootPart then SFBasePart(TRootPart)
    elseif THead then SFBasePart(THead)
    elseif Handle then SFBasePart(Handle) end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    Workspace.CurrentCamera.CameraSubject = Humanoid
    if FlingOldPos then
        repeat
            RootPart.CFrame = FlingOldPos * CFrame.new(0, .5, 0)
            Character:SetPrimaryPartCFrame(FlingOldPos * CFrame.new(0, .5, 0))
            Humanoid:ChangeState("GettingUp")
            for _, part in pairs(Character:GetChildren()) do
                if part:IsA("BasePart") then part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new() end
            end
            task.wait()
        until (RootPart.Position - FlingOldPos.p).Magnitude < 25
        Workspace.FallenPartsDestroyHeight = FlingFPDH
    end
end

local function flingPlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then notify("Fling", "Player not found"); return false end
    if FlingActive then notify("Fling", "Already flinging"); return false end
    FlingActive = true
    notify("Fling", "Flinging " .. target.Name .. "...")
    task.spawn(function()
        pcall(SkidFling, target, 0)
        FlingActive = false
        notify("Fling", "Done")
    end)
    return true
end

-- BAYBLADE: teleport 1 stud za oběť, roztočit, čekat než odletí
local function baybladePlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then notify("Bayblade", "Player not found"); return false end
    if BaybladeActive then notify("Bayblade", "Already active"); return false end
    BaybladeActive = true
    BaybladeTarget = target
    notify("Bayblade", "Started on " .. target.Name)

    task.spawn(function()
        local Timeout = tick() + 10
        while BaybladeActive and tick() < Timeout do
            if not target.Character then break end
            local trp = target.Character:FindFirstChild("HumanoidRootPart")
            local myChar = LP.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if trp and myRoot then
                -- 1 stud za obětí
                local behind = trp.CFrame * CFrame.new(0, 0, -1)
                pcall(function()
                    myRoot.CFrame = behind
                    myRoot.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
                    myRoot.AssemblyLinearVelocity = Vector3.new(9e7, 9e7, 9e7)
                end)
                -- Pokud oběť už letí (rychlost > 200), skončit
                local tv = trp.AssemblyLinearVelocity
                if tv.Magnitude > 200 then
                    break
                end
            else
                break
            end
            task.wait()
        end
        BaybladeActive = false
        BaybladeTarget = nil
        -- návrat
        pcall(function()
            local myChar = LP.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot and FlingOldPos then
                myRoot.CFrame = FlingOldPos
            end
            Workspace.FallenPartsDestroyHeight = FlingFPDH
        end)
        notify("Bayblade", "Done")
    end)
    return true
end

-- UI
local GUI = mount(Instance.new("ScreenGui"))
GUI.Name = "MM2Short" GUI.ResetOnSpawn = false GUI.DisplayOrder = 999

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 340, 0, 480)
Main.Position = UDim2.new(0.5, -170, 0.5, -240)
Main.BackgroundColor3 = T.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.Parent = GUI
corner(Main, 10) stroke(Main, T.Border, 1)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = T.Surface
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
corner(TitleBar, 10)
lbl(TitleBar, "🔪  MM2 Short", 15, T.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Left, UDim2.new(0,14,0,0), UDim2.new(1,-100,1,0))
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -32, 0.5, -13)
closeBtn.BackgroundColor3 = T.Bad
closeBtn.BackgroundTransparency = 0.4
closeBtn.Text = "✕"
closeBtn.TextColor3 = T.Text
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.BorderSizePixel = 0
closeBtn.Parent = TitleBar
corner(closeBtn, 6)
closeBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

do
    local dragging=false local dragStart=nil local startPos=nil
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true dragStart=input.Position startPos=Main.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            local delta=input.Position-dragStart
            local vs=Camera.ViewportSize
            local ax=math.clamp(startPos.X.Offset+delta.X, 0, vs.X-Main.AbsoluteSize.X)
            local ay=math.clamp(startPos.Y.Offset+delta.Y, 0, vs.Y-Main.AbsoluteSize.Y)
            Main.Position=UDim2.new(0,ax,0,ay)
        end
    end)
end

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 36)
TabBar.Position = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(14,14,17)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, 0, 1, -76)
ContentArea.Position = UDim2.new(0, 0, 0, 76)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.Parent = Main

local tabs = {}
local activeTab = nil
local function switchTab(tab)
    if activeTab then
        activeTab.scroll.Visible = false
        activeTab.btn.TextColor3 = T.Faint
        activeTab.btn.BackgroundTransparency = 1
    end
    activeTab = tab
    tab.scroll.Visible = true
    tab.btn.TextColor3 = T.Text
    tab.btn.BackgroundTransparency = 0.6
end

local function makeTab(name, sizeFrac)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(sizeFrac or (1/4), -2, 1, 0)
    btn.BackgroundColor3 = T.Surface
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = T.Faint
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = TabBar
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new()
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = T.Accent
    scroll.Visible = false
    scroll.Parent = ContentArea
    local sl = Instance.new("UIListLayout") sl.Padding = UDim.new(0,6) sl.Parent = scroll
    local sp = Instance.new("UIPadding") sp.PaddingLeft = UDim.new(0,10) sp.PaddingRight = UDim.new(0,10) sp.PaddingTop = UDim.new(0,10) sp.PaddingBottom = UDim.new(0,10) sp.Parent = scroll
    local tab = {btn=btn, scroll=scroll}
    btn.MouseButton1Click:Connect(function() switchTab(tab) end)
    tabs[name]=tab
    if not activeTab then switchTab(tab) end
    return tab
end

local function makeSection(tab, title)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = T.Surface
    card.BorderSizePixel = 0
    card.Parent = tab.scroll
    corner(card, 8) stroke(card, T.Border, 1, 0.3)
    local cl = Instance.new("UIListLayout") cl.Padding = UDim.new(0,5) cl.Parent = card
    local cp = Instance.new("UIPadding") cp.PaddingLeft = UDim.new(0,10) cp.PaddingRight = UDim.new(0,10) cp.PaddingTop = UDim.new(0,8) cp.PaddingBottom = UDim.new(0,8) cp.Parent = card
    lbl(card, title:upper(), 11, T.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Left, UDim2.new(0,0,0,0), UDim2.new(1,0,0,18))
    return card
end

local function makeToggle(parent, name, desc, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, desc and 46 or 36)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)
    lbl(row, name, 12, T.Text, Enum.Font.GothamMedium, Enum.TextXAlignment.Left, UDim2.new(0,10,0,desc and 5 or 0), UDim2.new(0.7,0,0,desc and 18 or 36))
    if desc then lbl(row, desc, 10, T.Faint, Enum.Font.Gotham, Enum.TextXAlignment.Left, UDim2.new(0,10,0,23), UDim2.new(0.7,0,0,14)) end
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 40, 0, 20)
    track.Position = UDim2.new(1, -50, 0.5, -10)
    track.BackgroundColor3 = Color3.fromRGB(45,45,52)
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 10)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = T.Dim
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 7)
    local on = false
    local h = {}
    function h:get() return on end
    function h:set(v, fire)
        on = v
        tw(track,{BackgroundColor3=on and T.Accent or Color3.fromRGB(45,45,52)})
        tw(knob,{Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),BackgroundColor3=on and T.Text or T.Dim},0.2,Enum.EasingStyle.Back)
        if fire~=false then pcall(callback,on) end
    end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function() h:set(not on) end)
    return h
end

local function makeButton(parent, name, col, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,32)
    btn.BackgroundColor3 = col or T.AccentDrk
    btn.Text = name
    btn.TextColor3 = T.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = parent
    corner(btn, 6) stroke(btn, col or T.Accent, 1, 0.5)
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=T.Accent}) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=col or T.AccentDrk}) end)
    btn.MouseButton1Click:Connect(function() pcall(cb) end)
    return btn
end

local function makeSlider(parent, name, min, max, default, suffix, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,46)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)
    lbl(row, name, 11, T.Text, Enum.Font.GothamMedium, Enum.TextXAlignment.Left, UDim2.new(0,10,0,4), UDim2.new(0.6,0,0,16))
    local vl = lbl(row, tostring(default)..(suffix or ""), 11, T.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right, UDim2.new(0.6,0,0,4), UDim2.new(0.4,-10,0,16))
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-20,0,6)
    track.Position = UDim2.new(0,10,0,30)
    track.BackgroundColor3 = Color3.fromRGB(35,35,42)
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 3)
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = T.Accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.Parent = track
    corner(fill, 3)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,12,0,12)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((default-min)/(max-min),0,0.5,0)
    knob.BackgroundColor3 = T.Text
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = track
    corner(knob, 6)
    local value = default
    local grabbing = false
    local function setFromX(x)
        local alpha = math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
        value = math.floor(min+(max-min)*alpha+0.5)
        vl.Text = tostring(value)..(suffix or "")
        tw(fill,{Size=UDim2.new(alpha,0,1,0)},0.08)
        tw(knob,{Position=UDim2.new(alpha,0,0.5,0)},0.08)
        pcall(cb, value)
    end
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1,0,0,24)
    hit.Position = UDim2.new(0,0,0,22)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = row
    hit.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then grabbing=true setFromX(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i) if grabbing and i.UserInputType==Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 and grabbing then grabbing=false end end)
    return {get=function() return value end}
end

local function makeLive(parent, text, initial, color)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,26)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)
    lbl(row, text, 11, T.Dim, Enum.Font.Gotham, Enum.TextXAlignment.Left, UDim2.new(0,10,0,0), UDim2.new(0.5,0,1,0))
    local val = lbl(row, initial or "—", 11, color or T.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Right, UDim2.new(0.5,0,0,0), UDim2.new(0.5,-10,1,0))
    return {set=function(txt,col) val.Text=tostring(txt) if col then val.TextColor3=col end end}
end

-- TABS
local tInfo = makeTab("Info", 1/5)
local tESP  = makeTab("ESP", 1/5)
local tAim  = makeTab("Aim", 1/5)
local tMove = makeTab("Move", 1/5)
local tFun  = makeTab("Fun", 1/5)

-- INFO
local secRoles = makeSection(tInfo, "Role Info")
local lblMurd = makeLive(secRoles, "🔪 Murderer", "Detecting...", T.Murd)
local lblSher = makeLive(secRoles, "🔫 Sheriff", "Detecting...", T.Sher)
local lblMyRole = makeLive(secRoles, "👤 Your Role", "?", T.Text)

local secStats = makeSection(tInfo, "Stats")
local lblPlayers = makeLive(secStats, "Players", "0")
local lblAlive = makeLive(secStats, "Alive", "0", T.Good)
local lblDead = makeLive(secStats, "Dead", "0", T.Bad)
local lblFPS = makeLive(secStats, "FPS", "?")

-- ESP
local secESP = makeSection(tESP, "Role ESP")
local espMurd = makeToggle(secESP, "Murderer ESP", "Red highlight")
local espSher = makeToggle(secESP, "Sheriff ESP", "Yellow highlight")
local espInno = makeToggle(secESP, "Innocent ESP", "Blue highlight")
local espDead = makeToggle(secESP, "Dead ESP", "Show ghosts")
local espBox = makeToggle(secESP, "Box", "Draw box around players")
local espName = makeToggle(secESP, "Name", "Show player name")
local espRole = makeToggle(secESP, "Role Text", "Show role under name")

local secWeaponESP = makeSection(tESP, "Weapon ESP")
local espGun = makeToggle(secWeaponESP, "Show Gun", "Blue")
local espKnife = makeToggle(secWeaponESP, "Show Knife", "Red")
local espNone = makeToggle(secWeaponESP, "Show No Weapon", "Green")

local secGunDrop = makeSection(tESP, "GunDrop ESP")
local gunDropEnabled = makeToggle(secGunDrop, "Enable GunDrop ESP", "Highlight dropped gun")
local gunDropColor = T.Gun
local gunDropObjects = {}
local gunDropGui = nil

-- AIM
local secAim = makeSection(tAim, "Aimbot")
local aimEnabled = makeToggle(secAim, "Enable Aimbot", "Press E to toggle")
local aimSmooth = makeSlider(secAim, "Smoothness", 1, 20, 8, "x", function() end)
local aimFOV = makeSlider(secAim, "FOV", 20, 400, 120, "px", function() end)
local aimTargetMode = "murderer"
makeButton(secAim, "🎯 Target: MURDERER", Color3.fromRGB(100,20,20), function()
    aimTargetMode = "murderer"
    notify("Aim", "Target: Murderer")
end)
makeButton(secAim, "🎯 Target: SHERIFF", Color3.fromRGB(100,70,0), function()
    aimTargetMode = "sheriff"
    notify("Aim", "Target: Sheriff")
end)

-- MOVE
local secMove = makeSection(tMove, "Movement")
local gravityVal = makeSlider(secMove, "Gravity", 0, 500, 196, "", function(v) Workspace.Gravity = v end)
local speedVal = makeSlider(secMove, "Walk Speed", 0, 200, 16, " sp", function(v)
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = v end
end)
local jumpVal = makeSlider(secMove, "Jump Power", 0, 300, 50, "", function(v)
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.UseJumpPower = true h.JumpPower = v end
end)
local boostOnJump = makeToggle(secMove, "Boost on Jump", "75 speed when jumping")

-- FUN
local secPicker = makeSection(tFun, "Select Player")
local pickerScroll = Instance.new("ScrollingFrame")
pickerScroll.Size = UDim2.new(1,0,0,140)
pickerScroll.BackgroundColor3 = T.BG
pickerScroll.BorderSizePixel = 0
pickerScroll.ScrollBarThickness = 3
pickerScroll.ScrollBarImageColor3 = T.Accent
pickerScroll.CanvasSize = UDim2.new()
pickerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
pickerScroll.Parent = secPicker
corner(pickerScroll, 6)
local pickerLayout = Instance.new("UIListLayout")
pickerLayout.Padding = UDim.new(0,2)
pickerLayout.Parent = pickerScroll
local selectedTarget = nil
local pickerRows = {}

local function refreshPlayerPicker()
    for _, row in pairs(pickerRows) do pcall(function() row:Destroy() end) end
    pickerRows = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1,-4,0,26)
            row.BackgroundColor3 = (selectedTarget == p.Name) and T.Accent or T.Surface
            row.BorderSizePixel = 0
            row.Text = "  " .. p.Name
            row.TextColor3 = T.Text
            row.Font = Enum.Font.GothamMedium
            row.TextSize = 11
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.AutoButtonColor = false
            row.Parent = pickerScroll
            corner(row, 4)
            row.MouseButton1Click:Connect(function()
                selectedTarget = p.Name
                refreshPlayerPicker()
            end)
            table.insert(pickerRows, row)
        end
    end
end

local secFun = makeSection(tFun, "Actions")
makeButton(secFun, "💥 Fling Selected", T.AccentDrk, function()
    if not selectedTarget then notify("Fling", "Select a player first"); return end
    flingPlayer(selectedTarget)
end)
makeButton(secFun, "🌀 Bayblade Selected", Color3.fromRGB(80,20,120), function()
    if not selectedTarget then notify("Bayblade", "Select a player first"); return end
    baybladePlayer(selectedTarget)
end)
makeButton(secFun, "📍 Teleport to Selected", Color3.fromRGB(30,60,100), function()
    if not selectedTarget then notify("TP", "Select a player first"); return end
    local t = Players:FindFirstChild(selectedTarget)
    if t and t.Character then
        local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local tr = t.Character:FindFirstChild("HumanoidRootPart")
        if r and tr then r.CFrame = tr.CFrame + Vector3.new(0,3,0); notify("TP", "To "..t.Name) end
    end
end)

-- ESP UPDATE
local espHighlights = {}
local espBillboards = {}
local weaponHighlights = {}

local function removeESP(name)
    if espHighlights[name] then pcall(function() espHighlights[name]:Destroy() end) espHighlights[name]=nil end
    if espBillboards[name] then pcall(function() espBillboards[name].bb:Destroy() end) espBillboards[name]=nil end
end
local function removeWeaponESP(name)
    if weaponHighlights[name] then pcall(function() weaponHighlights[name]:Destroy() end) weaponHighlights[name]=nil end
end

local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local role = getPlayerRole(p)
            local pHum = p.Character:FindFirstChildOfClass("Humanoid")
            local isDead = pHum and pHum.Health <= 0
            local showRole = (role=="murderer" and espMurd:get()) or (role=="sheriff" and espSher:get()) or (role=="innocent" and espInno:get()) or (isDead and espDead:get())
            local color = roleColor(role, isDead)
            if showRole then
                if espBox:get() then
                    if not espHighlights[p.Name] or not espHighlights[p.Name].Parent then
                        local hl = Instance.new("Highlight")
                        hl.Name = "_mm2hl"
                        hl.FillColor = color
                        hl.FillTransparency = 0.6
                        hl.OutlineColor = color
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = p.Character
                        espHighlights[p.Name] = hl
                    else
                        espHighlights[p.Name].FillColor = color
                        espHighlights[p.Name].OutlineColor = color
                    end
                else
                    if espHighlights[p.Name] then pcall(function() espHighlights[p.Name]:Destroy() end) espHighlights[p.Name]=nil end
                end
                if espName:get() or espRole:get() then
                    local head = p.Character:FindFirstChild("Head")
                    if head then
                        if not espBillboards[p.Name] or not espBillboards[p.Name].bb.Parent then
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "_mm2bb"
                            bb.Size = UDim2.new(0, 120, 0, 32)
                            bb.StudsOffset = Vector3.new(0, 2, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = head
                            local txt = Instance.new("TextLabel")
                            txt.Size = UDim2.new(1, 0, 0, 16)
                            txt.BackgroundTransparency = 1
                            txt.Font = Enum.Font.GothamBold
                            txt.TextSize = 11
                            txt.TextStrokeTransparency = 0
                            txt.TextXAlignment = Enum.TextXAlignment.Center
                            txt.Parent = bb
                            local rtxt = Instance.new("TextLabel")
                            rtxt.Size = UDim2.new(1, 0, 0, 14)
                            rtxt.Position = UDim2.new(0, 0, 0, 16)
                            rtxt.BackgroundTransparency = 1
                            rtxt.Font = Enum.Font.GothamMedium
                            rtxt.TextSize = 10
                            rtxt.TextStrokeTransparency = 0
                            rtxt.TextXAlignment = Enum.TextXAlignment.Center
                            rtxt.Parent = bb
                            espBillboards[p.Name] = {bb=bb, txt=txt, rtxt=rtxt}
                        end
                        local data = espBillboards[p.Name]
                        data.txt.Text = espName:get() and p.Name or ""
                        data.txt.TextColor3 = color
                        data.rtxt.Text = espRole:get() and roleText(role, isDead) or ""
                        data.rtxt.TextColor3 = color
                    end
                else
                    if espBillboards[p.Name] then pcall(function() espBillboards[p.Name].bb:Destroy() end) espBillboards[p.Name]=nil end
                end
            else
                removeESP(p.Name)
            end

            -- Weapon ESP
            local wType = getWeaponType(p)
            local wShow = (wType=="Gun" and espGun:get()) or (wType=="Knife" and espKnife:get()) or (wType=="None" and espNone:get())
            local wColor = wType=="Gun" and T.Gun or wType=="Knife" and T.Knife or T.None
            if wShow then
                if not weaponHighlights[p.Name] or not weaponHighlights[p.Name].Parent then
                    local hl = Instance.new("Highlight")
                    hl.Name = "_mm2whl"
                    hl.FillColor = wColor
                    hl.FillTransparency = 0.6
                    hl.OutlineColor = wColor
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = p.Character
                    weaponHighlights[p.Name] = hl
                else
                    weaponHighlights[p.Name].FillColor = wColor
                    weaponHighlights[p.Name].OutlineColor = wColor
                end
            else
                removeWeaponESP(p.Name)
            end
        end
    end
end

-- GunDrop ESP
local function isGunDrop(obj)
    if not obj then return false end
    local n = obj.Name:lower()
    return n:find("gundrop") or n:find("drop") or n:find("gun")
end
local function getGunDropPos(obj)
    local primary = obj:FindFirstChild("PrimaryPart")
    if primary then return primary.Position end
    local part = obj:FindFirstChildOfClass("BasePart")
    if part then return part.Position end
    if obj:IsA("BasePart") then return obj.Position end
    return nil
end
local function createGunDropESP(obj)
    if gunDropObjects[obj] then return end
    local pos = getGunDropPos(obj)
    if not pos then return end
    if not gunDropGui then
        gunDropGui = mount(Instance.new("ScreenGui"))
        gunDropGui.Name = "MM2GunDrop" gunDropGui.ResetOnSpawn = false gunDropGui.DisplayOrder = 994
    end
    local hl = Instance.new("Highlight")
    hl.Parent = obj
    hl.FillColor = gunDropColor
    hl.FillTransparency = 0.4
    hl.OutlineColor = gunDropColor
    hl.OutlineTransparency = 0.2
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,120,0,20)
    frame.BackgroundTransparency = 1
    frame.Parent = gunDropGui
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.Text = "GunDrop"
    txt.TextColor3 = gunDropColor
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 12
    txt.TextStrokeTransparency = 0
    txt.Parent = frame
    gunDropObjects[obj] = {hl=hl, frame=frame}
end
local function clearGunDropESP()
    for obj, data in pairs(gunDropObjects) do
        pcall(function() data.hl:Destroy() end)
        pcall(function() data.frame:Destroy() end)
    end
    gunDropObjects = {}
    if gunDropGui then pcall(function() gunDropGui:Destroy() end) gunDropGui=nil end
end
local function scanGunDrops()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isGunDrop(obj) then createGunDropESP(obj) end
    end
end
local function updateGunDropPositions()
    for obj, data in pairs(gunDropObjects) do
        local pos = getGunDropPos(obj)
        if pos then
            local sp, onScreen = Camera:WorldToScreenPoint(pos)
            if onScreen then
                data.frame.Position = UDim2.new(0, sp.X - 60, 0, sp.Y - 10)
                data.frame.Visible = true
            else
                data.frame.Visible = false
            end
        end
    end
end
Workspace.DescendantAdded:Connect(function(obj)
    if gunDropEnabled:get() and isGunDrop(obj) then createGunDropESP(obj) end
end)

-- AIMBOT
local aimEnabledState = false
local aimConn = nil
local function startAimbot()
    if aimConn then return end
    aimConn = RunService.Heartbeat:Connect(function(dt)
        if not aimEnabled:get() then return end
        local want = aimTargetMode
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local closest = nil
        local closestDist = math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and getPlayerRole(p) == want then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and h and h.Health > 0 then
                    local sp, onScreen = Camera:WorldToScreenPoint(hrp.Position)
                    if onScreen and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < aimFOV.get() and d < closestDist then
                            closestDist = d
                            closest = hrp.Position
                        end
                    end
                end
            end
        end
        if closest then
            local camPos = Camera.CFrame.Position
            local goal = CFrame.lookAt(camPos, closest)
            Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(dt * (aimSmooth.get()/10), 0, 1))
        end
    end)
end
startAimbot()

-- BOOST ON JUMP
local boostActive = false
local boostConn = nil
local function setupBoost()
    if boostConn then boostConn:Disconnect() end
    boostConn = RunService.Heartbeat:Connect(function()
        if not boostOnJump:get() then return end
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then
            if h.FloorMaterial == Enum.Material.Air then
                h.WalkSpeed = 75
            else
                h.WalkSpeed = speedVal.get()
            end
        end
    end)
end
setupBoost()

-- CLEANUP
Players.PlayerRemoving:Connect(function(p)
    removeESP(p.Name)
    removeWeaponESP(p.Name)
    roleMemory[p.Name]=nil
    refreshPlayerPicker()
end)
Players.PlayerAdded:Connect(function() task.wait(0.5) refreshPlayerPicker() end)
LP.CharacterAdded:Connect(function()
    task.wait(1)
    clearRoleMemory()
    for n in pairs(espHighlights) do removeESP(n) end
    for n in pairs(weaponHighlights) do removeWeaponESP(n) end
end)

-- KEYS
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        Main.Visible = not Main.Visible
        if Main.Visible then refreshPlayerPicker() end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        for _, t in ipairs({espMurd,espSher,espInno,espDead,espBox,espName,espRole,espGun,espKnife,espNone,gunDropEnabled,aimEnabled,boostOnJump}) do t:set(false) end
        FlingActive = false
        BaybladeActive = false
        clearGunDropESP()
        pcall(function() Workspace.FallenPartsDestroyHeight = FlingFPDH end)
        pcall(function() Lighting.Brightness = 1 end)
        notify("Panic", "All features disabled")
    elseif input.KeyCode == Enum.KeyCode.End then
        wmFrame.Visible = not wmFrame.Visible
    elseif input.KeyCode == Enum.KeyCode.E then
        aimEnabled:set(not aimEnabled:get())
    end
end)

-- MAIN LOOP
local fpsCount, fpsAccum = 0, 0
local heavyTimer = 0
local HEAVY = 0.1
RunService.Heartbeat:Connect(function(dt)
    fpsCount = fpsCount + 1
    fpsAccum = fpsAccum + dt
    heavyTimer = heavyTimer + dt
    pcall(updateESP)
    if gunDropEnabled:get() then pcall(updateGunDropPositions) end
    if fpsAccum >= 1 then
        local fps = math.floor(fpsCount/fpsAccum)
        pcall(function() lblFPS.set(fps.." FPS") wmInfo.Text=fps.." FPS" end)
        fpsCount=0 fpsAccum=0
    end
    if heavyTimer < HEAVY then return end
    heavyTimer = 0
    local char = LP.Character
    if not char then return end
    local murderer, sheriff = nil, nil
    local alive, dead = 0, 0
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h then
                if h.Health > 0 then alive = alive + 1 else dead = dead + 1 end
            end
            if p ~= LP then
                local r = getPlayerRole(p)
                if r=="murderer" then murderer=p.Name end
                if r=="sheriff" then sheriff=p.Name end
            end
        end
    end
    pcall(function()
        lblMurd.set(murderer or "Unknown", murderer and T.Murd or T.Faint)
        lblSher.set(sheriff or "Unknown", sheriff and T.Sher or T.Faint)
        lblMyRole.set(roleText(getPlayerRole(LP),false), roleColor(getPlayerRole(LP),false))
        lblPlayers.set(#Players:GetPlayers())
        lblAlive.set(alive, T.Good)
        lblDead.set(dead, T.Bad)
    end)
end)

refreshPlayerPicker()

_G.__MM2Short_Destroy = function()
    FlingActive = false
    BaybladeActive = false
    pcall(function() Workspace.FallenPartsDestroyHeight = FlingFPDH end)
    pcall(function() GUI:Destroy() end)
    pcall(function() WM:Destroy() end)
    clearGunDropESP()
    for n in pairs(espHighlights) do removeESP(n) end
    for n in pairs(weaponHighlights) do removeWeaponESP(n) end
end

print("[MM2 Short] " .. BUILD .. " loaded")
