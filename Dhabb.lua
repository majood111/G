-- Dhabb GUI v3
-- رادار + صيد تلقائي للضبان + أداة فحص الأسماء

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== الإعدادات =====
local CONFIG = {
    -- كلمات البحث في اسم الضب (تقدر تضيف من الواجهة)
    -- اسم الضب في اللعبة: Dhab_xxxxxx (من نتيجة الفحص)
    keywords = { "dhab", "ضب" },
    shootRange = 40,        -- من أي مسافة يوجّه السلاح ويطلق
    bulletSpeed = 250,      -- سرعة الرصاصة التقريبية (للتقدّم على الضب المتحرك)
    dropFactor = 0.04,      -- رفع التصويب لكل متر مسافة (يعوّض نزول الرصاصة)
    aimHeight = 0,          -- رفع ثابت فوق الهدف (التصويب على الهيت بوكس مباشرة)
    minLeadSpeed = 2,       -- تحت هذي السرعة ما يتقدّم على الضب
    maxLead = 6,            -- أقصى تقدّم (متر) عشان ما يطيّح الرصاصة بعيد
    showTags = true,        -- سهم + مسافة فوق كل ضب
    flySpeed = 60,          -- سرعة الطيران
    promptRange = 10,       -- من أي مسافة يضغط E/F على الشي
    -- كلمات تدل على أزرار الجمع/التحميل (تعدّلها بعد ما تشوف نتيجة Prompts)
    promptKeywords = { "pick", "take", "collect", "load", "cargo", "bed", "trunk",
        "جمع", "شيل", "حمل", "الحمولة", "الحوض" },
    -- لو شغّلتها يلوّن أي حيوان (Model فيه Humanoid) مو لاعب
    detectAnimals = true,
    radarInterval = 1,
    huntInterval = 0.4,
    interactRange = 12,
    maxHuntRange = 500,
    scanRadius = 80,        -- نطاق أداة الفحص
}

-- ===== تنظيف النسخة القديمة =====
local oldGui = playerGui:FindFirstChild("DhabbGui")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "DhabbGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- ===== الواجهة =====
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 555)
frame.Position = UDim2.new(0.05, 0, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 0, 42)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "Dhabb GUI v3"
title.TextColor3 = Color3.fromRGB(255, 165, 0)
title.TextSize = 17
title.Font = Enum.Font.SourceSansBold
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(36, 42)
closeBtn.Position = UDim2.new(1, -36, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Text = "X"
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(36, 42)
minBtn.Position = UDim2.new(1, -76, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.TextSize = 20
minBtn.Font = Enum.Font.SourceSansBold
minBtn.Text = "–"
minBtn.Parent = frame
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 10)

-- زر صغير يظهر لما تخفي الواجهة
local mini = Instance.new("TextButton")
mini.Size = UDim2.fromOffset(70, 36)
mini.Position = frame.Position
mini.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
mini.TextColor3 = Color3.fromRGB(255, 165, 0)
mini.TextSize = 15
mini.Font = Enum.Font.SourceSansBold
mini.Text = "Dhabb"
mini.Active = true
mini.Draggable = true
mini.Visible = false
mini.Parent = gui
Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 8)

local function makeButton(text, y, h)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.88, 0, 0, h or 38)
    b.Position = UDim2.new(0.06, 0, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 14
    b.Font = Enum.Font.SourceSansBold
    b.Text = text
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local radarBtn = makeButton("Radar: OFF", 52)
local huntBtn = makeButton("Auto Hunt: OFF", 96)
local scanBtn = makeButton("Scan: أسماء اللي حولي", 140)
local infoBtn = makeButton("Weapon Info: تفاصيل السلاح", 184)

local function makeHalf(text, x, y)
    y = y or 270
    local b = makeButton(text, y)
    b.Size = UDim2.new(0.43, 0, 0, 34)
    b.Position = UDim2.new(x, 0, 0, y)
    return b
end
local aimUpBtn = makeHalf("Aim ▲ ارفع", 0.06)
local aimDownBtn = makeHalf("Aim ▼ نزّل", 0.51)
local promptBtn = makeHalf("Prompts: E / F", 0.06, 312)
local loadBtn = makeHalf("Auto Load: OFF", 0.51, 312)
local flyBtn = makeButton("Fly: OFF", 354, 34)

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0.88, 0, 0, 34)
keyBox.Position = UDim2.new(0.06, 0, 0, 228)
keyBox.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
keyBox.TextColor3 = Color3.new(1, 1, 1)
keyBox.PlaceholderText = "اكتب اسم الضب واضغط Enter"
keyBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
keyBox.Text = ""
keyBox.ClearTextOnFocus = false
keyBox.TextSize = 14
keyBox.Font = Enum.Font.SourceSans
keyBox.Parent = frame
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.88, 0, 0, 150)
status.Position = UDim2.new(0.06, 0, 0, 396)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextSize = 13
status.Font = Enum.Font.SourceSans
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Text = "الحالة: جاهز"
status.Parent = frame

local function setToggle(btn, label, on)
    btn.Text = label .. (on and ": ON" or ": OFF")
    btn.BackgroundColor3 = on and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(60, 60, 60)
end

-- ===== أدوات مساعدة =====

-- هل الشي يخص لاعب (شخصيتي أو غيري) أو أداة/سلاح؟ نتجاهله
local function isPlayerStuff(object)
    if object:FindFirstAncestorOfClass("Tool") or object:IsA("Tool") then
        return true
    end
    for _, p in ipairs(Players:GetPlayers()) do
        local ch = p.Character
        if ch and (object == ch or object:IsDescendantOf(ch)) then
            return true
        end
    end
    return false
end

local function hasKeyword(object)
    local name = object.Name:lower()
    for _, k in ipairs(CONFIG.keywords) do
        if name:find(k:lower(), 1, true) then
            return true
        end
    end
    return false
end

local function isAnimal(object)
    return object:IsA("Model")
        and object:FindFirstChildOfClass("Humanoid") ~= nil
end

local function matches(object)
    if not (object:IsA("Model") or object:IsA("BasePart")) then
        return false
    end
    if object:IsA("Terrain") or isPlayerStuff(object) then
        return false
    end
    if hasKeyword(object) then
        return true
    end
    return CONFIG.detectAnimals and isAnimal(object)
end

local function getPart(object)
    if object:IsA("BasePart") then
        return object
    end
    -- نفضّل الهيت بوكس (وبعده الجسم) عشان التصويب يكون عليه بالضبط
    local hit = object:FindFirstChild("Hitbox", true)
    if hit and hit:IsA("BasePart") then
        return hit
    end
    local body = object:FindFirstChild("Body", true)
    if body and body:IsA("BasePart") then
        return body
    end
    return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
end

-- ===== الرادار =====
local radarOn = false
local markers = {}

local function clearMarkers()
    for object, marker in pairs(markers) do
        marker:Destroy()
        markers[object] = nil
    end
end

-- لو أبو الشي (Model) ملوّن أصلاً، ما نكرر له سهم
local function hasMarkedAncestor(object)
    local p = object.Parent
    while p and p ~= Workspace do
        if markers[p] then
            return true
        end
        p = p.Parent
    end
    return false
end

local function updateRadar()
    if not radarOn then
        clearMarkers()
        return
    end

    local count = 0
    for _, object in ipairs(Workspace:GetDescendants()) do
        if matches(object) then
            count += 1
            -- نتجنب تكرار: لو أبوه Model ملوّن، ما نلوّن الجزء
            if not markers[object] and not hasMarkedAncestor(object) then
                local marker = Instance.new("Highlight")
                marker.Name = "DhabbESP"
                marker.Adornee = object
                marker.FillColor = Color3.fromRGB(255, 140, 0)
                marker.OutlineColor = Color3.fromRGB(255, 255, 0)
                marker.FillTransparency = 0.4
                marker.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                marker.Parent = gui
                markers[object] = marker

                -- سهم + مسافة فوق الضب، يلحقه وين ما راح
                local part = getPart(object)
                if CONFIG.showTags and part then
                    local tag = Instance.new("BillboardGui")
                    tag.Name = "DhabbTag"
                    tag.Adornee = part
                    tag.AlwaysOnTop = true
                    tag.Size = UDim2.fromOffset(90, 44)
                    tag.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
                    tag.Parent = marker

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "Dist"
                    lbl.Size = UDim2.fromScale(1, 1)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.fromRGB(255, 255, 0)
                    lbl.TextStrokeTransparency = 0
                    lbl.TextSize = 16
                    lbl.Font = Enum.Font.SourceSansBold
                    lbl.Text = "▼"
                    lbl.Parent = tag
                end
            end
        end
    end

    for object, marker in pairs(markers) do
        if not object:IsDescendantOf(Workspace) or isPlayerStuff(object) then
            marker:Destroy()
            markers[object] = nil
        end
    end

    status.Text = "الرادار: لقيت " .. count .. " هدف"
end

-- ===== أداة الفحص: تعرض أسماء الأشياء اللي حولك =====
local function scanNearby()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        status.Text = "الفحص: الشخصية مو جاهزة"
        return
    end

    local found, seen = {}, {}
    for _, object in ipairs(Workspace:GetDescendants()) do
        if (object:IsA("Model") or object:IsA("BasePart"))
            and not object:IsA("Terrain")
            and not isPlayerStuff(object) then
            local part = getPart(object)
            if part then
                local d = (part.Position - root.Position).Magnitude
                -- نتجاهل الأجزاء الكبيرة (أرض/جدران) والأسماء العامة
                local big = part.Size.Magnitude > 40
                if d <= CONFIG.scanRadius and not big and not seen[object.Name] then
                    seen[object.Name] = true
                    table.insert(found, { name = object.Name, class = object.ClassName, d = d })
                end
            end
        end
    end

    table.sort(found, function(a, b) return a.d < b.d end)

    local lines = {}
    for i = 1, math.min(#found, 8) do
        local f = found[i]
        lines[#lines + 1] = string.format("%s (%s) %dm", f.name, f.class, f.d)
        print("[DhabbScan]", f.name, f.class, math.floor(f.d))
    end

    status.Text = #lines > 0
        and ("أقرب الأسماء:\n" .. table.concat(lines, "\n") .. "\nوقف جنب الضب واضغط Scan، وانسخ اسمه في الخانة.")
        or "الفحص: ما لقيت شي قريب"
end

-- ===== الصيد التلقائي =====
local huntOn = false

local function findNearest(root)
    local best, bestDist = nil, CONFIG.maxHuntRange
    for _, object in ipairs(Workspace:GetDescendants()) do
        if matches(object) then
            local part = getPart(object)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if d < bestDist then
                    best, bestDist = object, d
                end
            end
        end
    end
    return best, bestDist
end

local function interact(object)
    local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and fireproximityprompt then
        fireproximityprompt(prompt)
        return true
    end
    local click = object:FindFirstChildWhichIsA("ClickDetector", true)
    if click and fireclickdetector then
        fireclickdetector(click)
        return true
    end
    return false
end

-- يجهّز السلاح: يمسكه لو كان في الشنطة
local function getTool(char, humanoid)
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        return tool
    end
    local backpack = player:FindFirstChildOfClass("Backpack")
    tool = backpack and backpack:FindFirstChildOfClass("Tool")
    if tool then
        humanoid:EquipTool(tool)
    end
    return tool
end

-- يوجّه الشخصية والكاميرا للضب
-- نقطة التصويب: مكان الضب + تقدّم لو يتحرك + رفع يعوّض نزول الرصاصة
local aimPart = nil

local aimTrackPart, aimLastPos, aimVel = nil, nil, Vector3.zero

local function computeAimPoint(part, dt)
    local cam = Workspace.CurrentCamera
    local origin = cam and cam.CFrame.Position or part.Position
    local dist = (part.Position - origin).Magnitude

    -- نحسب سرعة الضب من حركته الفعلية ونمرّرها بنعومة، فإذا وقف فجأة يوقف التقدّم بسرعة
    if aimTrackPart ~= part then
        aimTrackPart, aimLastPos, aimVel = part, part.Position, Vector3.zero
    end
    if dt and dt > 0 then
        local newVel = (part.Position - aimLastPos) / dt
        aimVel = aimVel:Lerp(newVel, math.clamp(dt * 8, 0, 1))
    end
    aimLastPos = part.Position

    local lead = Vector3.zero
    if aimVel.Magnitude > CONFIG.minLeadSpeed then
        lead = aimVel * (dist / CONFIG.bulletSpeed)
        if lead.Magnitude > CONFIG.maxLead then
            lead = lead.Unit * CONFIG.maxLead
        end
    end
    local lift = Vector3.new(0, dist * CONFIG.dropFactor + CONFIG.aimHeight, 0)
    return part.Position + lead + lift
end

-- نثبّت الكاميرا على الضب كل فريم، لأن سكربت الكاميرا يرجّعها فيصير التصويب عشوائي
pcall(function() RunService:UnbindFromRenderStep("DhabbAim") end)
RunService:BindToRenderStep("DhabbAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local part = aimPart
    if not part or not part:IsDescendantOf(Workspace) then
        return
    end
    local cam = Workspace.CurrentCamera
    if cam then
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, computeAimPoint(part, dt))
    end
end)

local function aimAt(root, part)
    aimPart = part
    local flat = Vector3.new(part.Position.X, root.Position.Y, part.Position.Z)
    root.CFrame = CFrame.lookAt(root.Position, flat)
end

-- يطلق بكل الطرق المتاحة: Activate ثم كبسة ماوس وهمية في وسط الشاشة
-- (الكاميرا موجّهة للضب أصلاً فالمنتصف عليه)
local function fireTool(tool)
    pcall(function() tool:Activate() end)

    local cam = Workspace.CurrentCamera
    local cx, cy = 0, 0
    if cam then
        cx, cy = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2
    end

    if mouse1click then
        pcall(mouse1click)
    else
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            task.wait(0.05)
            vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
        end)
    end
end

local function huntStep()
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (humanoid and root) or humanoid.Health <= 0 then
        status.Text = "الصيد: الشخصية مو جاهزة"
        return
    end

    local target, dist = findNearest(root)
    if not target then
        aimPart = nil
        status.Text = "الصيد: ما فيه ضب قريب"
        return
    end

    local part = getPart(target)
    local tool = getTool(char, humanoid)

    if dist > CONFIG.shootRange then
        aimPart = nil
        humanoid:MoveTo(part.Position)
        status.Text = string.format("الصيد: ألحق %s (%d م)", target.Name, dist)
        return
    end

    -- داخل المدى: وجّه وأطلق (والضب يهرب فنتبعه بنفس الوقت)
    aimAt(root, part)
    humanoid:MoveTo(part.Position)

    if tool then
        fireTool(tool)
        status.Text = string.format("الصيد: أطلق على %s (%d م)", target.Name, dist)
    elseif dist <= CONFIG.interactRange and interact(target) then
        status.Text = "الصيد: تفاعلت مع " .. target.Name
    else
        status.Text = "الصيد: ما معي سلاح في الشنطة"
    end
end

-- ===== الجمع والتحميل: أزرار E / F (ProximityPrompt) =====
-- fireproximityprompt يضغط الزر مباشرة، فما يفرق E ولا F
local loadOn = false

local function promptMatches(prompt)
    local text = (prompt.ActionText .. " " .. prompt.ObjectText .. " "
        .. (prompt.Parent and prompt.Parent.Name or "")):lower()
    for _, k in ipairs(CONFIG.promptKeywords) do
        if text:find(k:lower(), 1, true) then
            return true
        end
    end
    return false
end

local function promptPosition(prompt)
    local p = prompt.Parent
    if not p then
        return nil
    end
    if p:IsA("BasePart") then
        return p.Position
    elseif p:IsA("Attachment") then
        return p.WorldPosition
    elseif p:IsA("Model") then
        return p:GetPivot().Position
    end
    local part = p:FindFirstAncestorWhichIsA("BasePart")
    return part and part.Position
end

-- يعرض الأزرار القريبة: الحرف، النص، اسم الشي، المسافة
local function scanPrompts()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        status.Text = "Prompts: الشخصية مو جاهزة"
        return
    end

    local found = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and not isPlayerStuff(d) then
            local pos = promptPosition(d)
            if pos then
                local dist = (pos - root.Position).Magnitude
                if dist <= CONFIG.scanRadius then
                    table.insert(found, { p = d, dist = dist })
                end
            end
        end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)

    local lines = {}
    for i = 1, math.min(#found, 8) do
        local p = found[i].p
        local line = string.format("[%s] %s | %s | %s | %dm", p.KeyboardKeyCode.Name,
            p.ActionText, p.ObjectText, p.Parent and p.Parent.Name or "?", found[i].dist)
        lines[#lines + 1] = line
        print("[DhabbPrompt]", line)
    end
    status.Text = #lines > 0 and ("الأزرار القريبة:\n" .. table.concat(lines, "\n"))
        or "Prompts: ما فيه أزرار قريبة"
end

local function loadStep()
    if huntOn then
        return -- الصيد أول، بعدين التحميل
    end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (humanoid and root) or humanoid.Health <= 0 then
        status.Text = "التحميل: الشخصية مو جاهزة"
        return
    end

    local best, bestPos, bestDist = nil, nil, CONFIG.maxHuntRange
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled and promptMatches(d) and not isPlayerStuff(d) then
            local pos = promptPosition(d)
            if pos then
                local dist = (pos - root.Position).Magnitude
                if dist < bestDist then
                    best, bestPos, bestDist = d, pos, dist
                end
            end
        end
    end

    if not best then
        status.Text = "التحميل: ما لقيت زر مطابق قريب"
    elseif bestDist > CONFIG.promptRange then
        humanoid:MoveTo(bestPos)
        status.Text = string.format("التحميل: أمشي لـ %s (%d م)", best.ActionText, bestDist)
    elseif fireproximityprompt then
        fireproximityprompt(best)
        status.Text = "التحميل: ضغطت [" .. best.KeyboardKeyCode.Name .. "] " .. best.ActionText
    else
        status.Text = "التحميل: المنفذ ما يدعم fireproximityprompt"
    end
end

task.spawn(function()
    while gui.Parent do
        task.wait(0.5)
        if loadOn then
            local ok, err = pcall(loadStep)
            if not ok then
                status.Text = "خطأ: " .. tostring(err)
            end
        end
    end
end)

-- ===== الطيران =====
-- تحرّك بالعصا/WASD والكاميرا تحدد الاتجاه: ارفع الكاميرا وامشي للأمام تطلع، نزّلها تنزل
local flyOn = false
local flyConn, flyBV

local function setFly(on)
    flyOn = on
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
    if flyBV then
        flyBV:Destroy()
        flyBV = nil
    end

    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not on or not (hum and root) then
        flyOn = false
        setToggle(flyBtn, "Fly", false)
        return
    end

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root

    flyConn = RunService.Heartbeat:Connect(function()
        local cam = Workspace.CurrentCamera
        if not (flyBV and cam and hum.Parent) then
            return
        end
        local md = hum.MoveDirection
        local vel = Vector3.zero
        if md.Magnitude > 0.05 then
            local look = cam.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            local fwd = flat.Magnitude > 0.01 and md:Dot(flat.Unit) or 0
            vel = md.Unit * CONFIG.flySpeed + Vector3.new(0, look.Y * fwd * CONFIG.flySpeed, 0)
        end
        flyBV.Velocity = vel
    end)
end

flyBtn.Activated:Connect(function()
    setFly(not flyOn)
    setToggle(flyBtn, "Fly", flyOn)
end)

-- لو متّ وطلعت من جديد يوقف الطيران
player.CharacterAdded:Connect(function()
    setFly(false)
end)

-- ===== الأزرار =====
radarBtn.Activated:Connect(function()
    radarOn = not radarOn
    setToggle(radarBtn, "Radar", radarOn)
    updateRadar()
    if not radarOn then
        status.Text = "الرادار: متوقف"
    end
end)

huntBtn.Activated:Connect(function()
    huntOn = not huntOn
    setToggle(huntBtn, "Auto Hunt", huntOn)
    if not huntOn then
        aimPart = nil
        status.Text = "الصيد: متوقف"
    end
end)

scanBtn.Activated:Connect(scanNearby)
promptBtn.Activated:Connect(scanPrompts)
loadBtn.Activated:Connect(function()
    loadOn = not loadOn
    setToggle(loadBtn, "Auto Load", loadOn)
    if not loadOn then
        status.Text = "التحميل: متوقف"
    end
end)

-- يعرض محتويات السلاح (Remotes / سكربتات) عشان نعرف كيف يطلق
local function weaponInfo()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then
        status.Text = "السلاح: الشخصية مو جاهزة"
        return
    end
    local tool = getTool(char, hum)
    if not tool then
        status.Text = "السلاح: ما لقيت أداة في الشنطة"
        return
    end

    local lines = { "السلاح: " .. tool.Name }
    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("LocalScript")
            or d:IsA("Script") or d:IsA("ValueBase") then
            lines[#lines + 1] = d.ClassName .. ": " .. d.Name
            print("[DhabbWeapon]", d:GetFullName(), d.ClassName)
        end
    end
    for k, v in pairs(tool:GetAttributes()) do
        lines[#lines + 1] = "attr " .. k .. " = " .. tostring(v)
    end
    status.Text = table.concat(lines, "\n", 1, math.min(#lines, 9))
end

infoBtn.Activated:Connect(weaponInfo)

keyBox.FocusLost:Connect(function(enterPressed)
    local text = keyBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if enterPressed and text ~= "" then
        table.insert(CONFIG.keywords, text)
        keyBox.Text = ""
        status.Text = "أضفت الاسم: " .. text
        if radarOn then
            updateRadar()
        end
    end
end)

-- تعديل رفع التصويب من الواجهة
local function showAim()
    status.Text = string.format("رفع التصويب: %.2f لكل متر", CONFIG.dropFactor)
end
aimUpBtn.Activated:Connect(function()
    CONFIG.dropFactor += 0.01
    showAim()
end)
aimDownBtn.Activated:Connect(function()
    CONFIG.dropFactor = math.max(0, CONFIG.dropFactor - 0.01)
    showAim()
end)

-- إخفاء / إظهار الواجهة (الرادار والصيد يكملون شغل)
minBtn.Activated:Connect(function()
    mini.Position = frame.Position
    frame.Visible = false
    mini.Visible = true
end)
mini.Activated:Connect(function()
    frame.Position = mini.Position
    mini.Visible = false
    frame.Visible = true
end)

closeBtn.Activated:Connect(function()
    radarOn, huntOn = false, false
    aimPart = nil
    gui:Destroy()
end)

-- ===== الحلقات =====
task.spawn(function()
    while gui.Parent do
        task.wait(CONFIG.radarInterval)
        if radarOn then
            pcall(updateRadar)
        end
    end
end)

-- تحديث المسافة فوق كل ضب
task.spawn(function()
    while gui.Parent do
        task.wait(0.2)
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if radarOn and root then
            for object, marker in pairs(markers) do
                local part = object.Parent and getPart(object)
                local lbl = marker:FindFirstChild("DhabbTag")
                    and marker.DhabbTag:FindFirstChild("Dist")
                if part and lbl then
                    lbl.Text = string.format("▼\n%d م", (part.Position - root.Position).Magnitude)
                end
            end
        end
    end
end)

task.spawn(function()
    while gui.Parent do
        task.wait(CONFIG.huntInterval)
        if huntOn then
            local ok, err = pcall(huntStep)
            if not ok then
                status.Text = "خطأ: " .. tostring(err)
            end
        end
    end
end)

gui.Destroying:Connect(function()
    aimPart = nil
    setFly(false)
    pcall(function() RunService:UnbindFromRenderStep("DhabbAim") end)
    clearMarkers()
end)
