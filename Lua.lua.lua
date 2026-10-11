-- Сервисы
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local coreGui = game:GetService("CoreGui")

local guiParent = pcall(function() return coreGui end) and coreGui or player:WaitForChild("PlayerGui")

-- Очистка старых версий
pcall(function()
    if guiParent:FindFirstChild("MusicUI") then guiParent.MusicUI:Destroy() end
    if guiParent:FindFirstChild("IntroScreen") then guiParent.IntroScreen:Destroy() end
end)
for _, name in ipairs({"Phone Tool", "VU Meter Tool"}) do
    if backpack:FindFirstChild(name) then backpack[name]:Destroy() end
    if player.Character and player.Character:FindFirstChild(name) then player.Character[name]:Destroy() end
end

-- Переменные загрузки
local isLoaded = false

-- === 1. ЭКРАН ЗАГРУЗКИ (60 СЕКУНД) ===
local introGui = Instance.new("ScreenGui")
introGui.Name = "IntroScreen"
introGui.IgnoreGuiInset = true
introGui.Parent = guiParent

local introBg = Instance.new("Frame")
introBg.Size = UDim2.new(1, 0, 1, 0)
introBg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
introBg.Parent = introGui

-- Ник игрока
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0, 300, 0, 30)
nameLabel.Position = UDim2.new(0.5, -150, 0.35, -40)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = player.Name
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextSize = 20
nameLabel.Font = Enum.Font.SourceSansBold
nameLabel.Parent = introBg

-- Иконка аватара
local avatarImg = Instance.new("ImageLabel")
avatarImg.Size = UDim2.new(0, 70, 0, 70)
avatarImg.Position = UDim2.new(0.5, -35, 0.35, -120)
avatarImg.BackgroundTransparency = 1
pcall(function()
    avatarImg.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
end)
avatarImg.Parent = introBg
local imgCorner = Instance.new("UICorner")
imgCorner.CornerRadius = UDim.new(1, 0)
imgCorner.Parent = avatarImg

-- Текст загрузки
local loadText = Instance.new("TextLabel")
loadText.Size = UDim2.new(0, 300, 0, 30)
loadText.Position = UDim2.new(0.5, -150, 0.5, 10)
loadText.BackgroundTransparency = 1
loadText.Text = "Загрузка скрипта... 0/60с"
loadText.TextColor3 = Color3.fromRGB(180, 180, 180)
loadText.TextSize = 14
loadText.Font = Enum.Font.SourceSans
loadText.Parent = introBg

-- Шкала загрузки
local loadBarBg = Instance.new("Frame")
loadBarBg.Size = UDim2.new(0, 260, 0, 8)
loadBarBg.Position = UDim2.new(0.5, -130, 0.5, 50)
loadBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
loadBarBg.Parent = introBg
Instance.new("UICorner", loadBarBg).CornerRadius = UDim.new(1, 0)

local loadBarFill = Instance.new("Frame")
loadBarFill.Size = UDim2.new(0, 0, 1, 0)
loadBarFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
loadBarFill.Parent = loadBarBg
Instance.new("UICorner", loadBarFill).CornerRadius = UDim.new(1, 0)

-- Падающие снежинки
for i = 1, 20 do
    local snow = Instance.new("Frame")
    snow.Size = UDim2.new(0, math.random(4, 7), 0, math.random(4, 7))
    snow.Position = UDim2.new(math.random(), 0, -0.1, 0)
    snow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    snow.BackgroundTransparency = 0.3
    snow.Parent = introBg
    Instance.new("UICorner", snow).CornerRadius = UDim.new(1, 0)
    
    task.spawn(function()
        local speed = math.random(10, 25) / 10
        while introGui.Parent do
            snow.Position = snow.Position + UDim2.new(0, 0, 0.01 * speed, 0)
            if snow.Position.Y.Scale > 1.1 then
                snow.Position = UDim2.new(math.random(), 0, -0.1, 0)
            end
            task.wait(0.04)
        end
    end)
end


-- === АУДИО И ЭФФЕКТЫ ===
local sharedSound = Instance.new("Sound")
sharedSound.Name = "GlobalMusicStream"
sharedSound.Volume = 1
sharedSound.Looped = true
sharedSound.Parent = workspace

local eqEffect = Instance.new("EqualizerSoundEffect")
eqEffect.Name = "BassBoost"
eqEffect.HighGain = 0
eqEffect.MidGain = 0
eqEffect.LowGain = 0
eqEffect.Parent = sharedSound

local isRainbowActive = false
local shakeScreenActive = false
local particlesActive = false

-- Частицы из VU-метра
local emitterAttachment = Instance.new("Attachment")
local particleEmitter = Instance.new("ParticleEmitter")
particleEmitter.Name = "MusicParticles"
particleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 50, 255), Color3.fromRGB(50, 200, 255))
particleEmitter.Size = NumberSequence.new(0.2, 0.5)
particleEmitter.Texture = "rbxassetid://258129463"
particleEmitter.Rate = 0
particleEmitter.Speed = NumberRange.new(3, 6)
particleEmitter.Parent = emitterAttachment

-- Функция создания ОДНОЙ полоски на корпусе VU-метра
local function createSingleBar(part)
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.CanvasSize = Vector2.new(100, 200)
    surfaceGui.Parent = part

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.6, 0, 0.85, 0)
    container.Position = UDim2.new(0.2, 0, 0.075, 0)
    container.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    container.Parent = surfaceGui

    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.Name = "SingleFill"
    fill.Size = UDim2.new(1, 0, 0, 0)
    fill.Position = UDim2.new(0, 0, 1, 0)
    fill.AnchorPoint = Vector2.new(0, 1)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.Parent = container

    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
    emitterAttachment.Parent = part

    return fill
end

-- === ИНСТРУМЕНТЫ ===
local phoneTool = Instance.new("Tool")
phoneTool.Name = "Phone Tool"
phoneTool.RequiresHandle = true
local phoneHandle = Instance.new("Part")
phoneHandle.Name = "Handle"
phoneHandle.Size = Vector3.new(0.6, 1, 0.15)
phoneHandle.BrickColor = BrickColor.new("Dark stone grey")
phoneHandle.Material = Enum.Material.SmoothPlastic
phoneHandle.Parent = phoneTool
phoneTool.Parent = backpack

local vuTool = Instance.new("Tool")
vuTool.Name = "VU Meter Tool"
vuTool.RequiresHandle = true
local vuHandle = Instance.new("Part")
vuHandle.Name = "Handle"
vuHandle.Size = Vector3.new(0.4, 0.9, 0.3)
vuHandle.BrickColor = BrickColor.new("Black")
vuHandle.Material = Enum.Material.Metal
vuHandle.Parent = vuTool
local vuFill = createSingleBar(vuHandle)
vuTool.Parent = backpack


-- === ГЛАВНЫЙ ЭКРАННЫЙ UI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MusicUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = guiParent

-- --- ЧЕРНЫЙ ЗАКРУГЛЕННЫЙ ТЕЛЕФОН ---
local phoneFrame = Instance.new("Frame")
phoneFrame.Name = "PhoneFrame"
phoneFrame.Size = UDim2.new(0, 270, 0, 340)
phoneFrame.Position = UDim2.new(0.5, -135, 0.4, -170)
phoneFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
phoneFrame.Visible = false
phoneFrame.Parent = screenGui
Instance.new("UICorner", phoneFrame).CornerRadius = UDim.new(0, 18)

local phoneHeader = Instance.new("TextButton")
phoneHeader.Size = UDim2.new(1, 0, 0, 35)
phoneHeader.BackgroundTransparency = 1
phoneHeader.Text = "📱 Музыкальный Телефон (Тяни тут)"
phoneHeader.TextColor3 = Color3.fromRGB(150, 150, 150)
phoneHeader.TextSize = 12
phoneHeader.Font = Enum.Font.SourceSansBold
phoneHeader.Parent = phoneFrame

-- Переключатель вкладок
local tabMain = Instance.new("TextButton")
tabMain.Size = UDim2.new(0.45, 0, 0, 26)
tabMain.Position = UDim2.new(0.05, 0, 0, 40)
tabMain.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
tabMain.TextColor3 = Color3.fromRGB(255, 255, 255)
tabMain.Text = "Плеер"
tabMain.TextSize, tabMain.Font = 12, Enum.Font.SourceSansBold
tabMain.Parent = phoneFrame
Instance.new("UICorner", tabMain).CornerRadius = UDim.new(0, 6)

local tabFX = Instance.new("TextButton")
tabFX.Size = UDim2.new(0.45, 0, 0, 26)
tabFX.Position = UDim2.new(0.5, 0, 0, 40)
tabFX.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
tabFX.TextColor3 = Color3.fromRGB(255, 255, 255)
tabFX.Text = "Эффекты"
tabFX.TextSize, tabFX.Font = 12, Enum.Font.SourceSansBold
tabFX.Parent = phoneFrame
Instance.new("UICorner", tabFX).CornerRadius = UDim.new(0, 6)

-- Плеер контейнер
local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(1, 0, 0, 260)
mainContainer.Position = UDim2.new(0, 0, 0, 75)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = phoneFrame

local idInput = Instance.new("TextBox")
idInput.Size = UDim2.new(0.85, 0, 0, 32)
idInput.Position = UDim2.new(0.075, 0, 0, 5)
idInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
idInput.TextColor3 = Color3.fromRGB(255, 255, 255)
idInput.PlaceholderText = "Введите Sound ID..."
idInput.Text = ""
idInput.TextSize = 13
idInput.Parent = mainContainer
Instance.new("UICorner", idInput).CornerRadius = UDim.new(0, 6)

local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0.4, 0, 0, 28)
playBtn.Position = UDim2.new(0.075, 0, 0, 45)
playBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playBtn.Text = "Играть"
playBtn.TextSize, playBtn.Font = 12, Enum.Font.SourceSansBold
playBtn.Parent = mainContainer
Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 5)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.4, 0, 0, 28)
stopBtn.Position = UDim2.new(0.525, 0, 0, 45)
stopBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Text = "Стоп"
stopBtn.TextSize, stopBtn.Font = 12, Enum.Font.SourceSansBold
stopBtn.Parent = mainContainer
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 5)

-- Табло времени трека (12 - 12)
local timeDisplay = Instance.new("TextLabel")
timeDisplay.Size = UDim2.new(0.85, 0, 0, 18)
timeDisplay.Position = UDim2.new(0.075, 0, 0, 78)
timeDisplay.BackgroundTransparency = 1
timeDisplay.Text = "0 - 0"
timeDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
timeDisplay.TextSize = 12
timeDisplay.Font = Enum.Font.Code
timeDisplay.Parent = mainContainer

-- Строка громкости
local volLabel = Instance.new("TextLabel")
volLabel.Size = UDim2.new(0.85, 0, 0, 16)
volLabel.Position = UDim2.new(0.075, 0, 0, 100)
volLabel.BackgroundTransparency = 1
volLabel.Text = "Громкость:"
volLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
volLabel.TextSize = 11
volLabel.Parent = mainContainer

local volInput = Instance.new("TextBox")
volInput.Size = UDim2.new(0.85, 0, 0, 26)
volInput.Position = UDim2.new(0.075, 0, 0, 118)
volInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
volInput.TextColor3 = Color3.fromRGB(255, 255, 255)
volInput.Text = "1.0"
volInput.TextSize = 12
volInput.Parent = mainContainer
Instance.new("UICorner", volInput).CornerRadius = UDim.new(0, 5)

-- Строка баса
local bassLabel = Instance.new("TextLabel")
bassLabel.Size = UDim2.new(0.85, 0, 0, 16)
bassLabel.Position = UDim2.new(0.075, 0, 0, 150)
bassLabel.BackgroundTransparency = 1
bassLabel.Text = "Бас (Low Gain dB):"
bassLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
bassLabel.TextSize = 11
bassLabel.Parent = mainContainer

local bassInput = Instance.new("TextBox")
bassInput.Size = UDim2.new(0.85, 0, 0, 26)
bassInput.Position = UDim2.new(0.075, 0, 0, 168)
bassInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
bassInput.TextColor3 = Color3.fromRGB(255, 255, 255)
bassInput.Text = "0"
bassInput.TextSize = 12
bassInput.Parent = mainContainer
Instance.new("UICorner", bassInput).CornerRadius = UDim.new(0, 5)

-- Кнопка радуги
local rainbowBtn = Instance.new("TextButton")
rainbowBtn.Size = UDim2.new(0.85, 0, 0, 30)
rainbowBtn.Position = UDim2.new(0.075, 0, 0, 204)
rainbowBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
rainbowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rainbowBtn.Text = "🌈 Радуга: ВЫКЛ"
rainbowBtn.TextSize, rainbowBtn.Font = 12, Enum.Font.SourceSansBold
rainbowBtn.Parent = mainContainer
Instance.new("UICorner", rainbowBtn).CornerRadius = UDim.new(0, 6)

-- Эффекты контейнер
local fxContainer = Instance.new("Frame")
fxContainer.Size = UDim2.new(1, 0, 0, 260)
fxContainer.Position = UDim2.new(0, 0, 0, 75)
fxContainer.BackgroundTransparency = 1
fxContainer.Visible = false
fxContainer.Parent = phoneFrame

local shakeBtn = Instance.new("TextButton")
shakeBtn.Size = UDim2.new(0.85, 0, 0, 35)
shakeBtn.Position = UDim2.new(0.075, 0, 0, 20)
shakeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
shakeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shakeBtn.Text = "📳 Shake Screen: ВЫКЛ"
shakeBtn.TextSize, shakeBtn.Font = 12, Enum.Font.SourceSansBold
shakeBtn.Parent = fxContainer
Instance.new("UICorner", shakeBtn).CornerRadius = UDim.new(0, 6)

local particlesBtn = Instance.new("TextButton")
particlesBtn.Size = UDim2.new(0.85, 0, 0, 35)
particlesBtn.Position = UDim2.new(0.075, 0, 0, 70)
particlesBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
particlesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
particlesBtn.Text = "✨ Частицы из VU: ВЫКЛ"
particlesBtn.TextSize, particlesBtn.Font = 12, Enum.Font.SourceSansBold
particlesBtn.Parent = fxContainer
Instance.new("UICorner", particlesBtn).CornerRadius = UDim.new(0, 6)

tabMain.MouseButton1Click:Connect(function()
    mainContainer.Visible = true
    fxContainer.Visible = false
end)
tabFX.MouseButton1Click:Connect(function()
    mainContainer.Visible = false
    fxContainer.Visible = true
end)

-- --- DVD ВАТЕРМАРК ---
local waterMark = Instance.new("TextLabel")
waterMark.Name = "DVDWatermark"
waterMark.Size = UDim2.new(0, 160, 0, 40)
waterMark.Position = UDim2.new(0.1, 0, 0.1, 0)
waterMark.BackgroundTransparency = 1
waterMark.Text = "Kupa Scripts"
waterMark.TextColor3 = Color3.fromRGB(255, 50, 50)
waterMark.TextSize = 18
waterMark.Font = Enum.Font.FredokaOne
waterMark.Visible = false -- Скрыт на время загрузки
waterMark.Parent = screenGui
local textStroke = Instance.new("UIStroke")
textStroke.Color = Color3.fromRGB(0, 0, 0)
textStroke.Thickness = 2
textStroke.Parent = waterMark

-- Таймер загрузки на 60 секунд (Показывает ватермарк только после конца)
task.spawn(function()
    for i = 1, 60 do
        if not introGui.Parent then break end
        loadText.Text = "Загрузка скрипта... " .. i .. "/60с"
        loadBarFill.Size = UDim2.new(i / 60, 0, 1, 0)
        task.wait(1)
    end
    introGui:Destroy()
    isLoaded = true
    waterMark.Visible = true -- Показываем ватермарк
end)


-- === ЛОГИКА ===
local posX, posY = 100, 100
local velX, velY = 2.5, 2.0
local currentRainbowHue = 0

runService.RenderStepped:Connect(function(dt)
    if not isLoaded then return end

    -- Движение ватермарки
    local screenSize = screenGui.AbsoluteSize
    if screenSize.X > 160 and screenSize.Y > 40 then
        posX = posX + velX
        posY = posY + velY
        local bounced = false
        if posX <= 0 or posX >= screenSize.X - 160 then velX = -velX bounced = true end
        if posY <= 0 or posY >= screenSize.Y - 40 then velY = -velY bounced = true end
        if bounced then
            currentRainbowHue = (currentRainbowHue + 0.15) % 1
            waterMark.TextColor3 = Color3.fromHSV(currentRainbowHue, 1, 1)
        end
        waterMark.Position = UDim2.new(0, posX, 0, posY)
    end
    
    -- Тряска экрана
    if shakeScreenActive and sharedSound.IsPlaying then
        local loudness = sharedSound.PlaybackLoudness
        if loudness > 120 then
            local camera = workspace.CurrentCamera
            local shakeOffset = Vector3.new(math.random(-5,5), math.random(-5,5), math.random(-5,5)) * (loudness / 2000)
            camera.CFrame = camera.CFrame * CFrame.new(shakeOffset)
        end
    end
    
    -- Обновление времени трека (текущее - осталось)
    if sharedSound.IsPlaying and sharedSound.TimeLength > 0 then
        local currentSec = math.floor(sharedSound.TimePosition)
        local remainingSec = math.floor(sharedSound.TimeLength - sharedSound.TimePosition)
        timeDisplay.Text = currentSec .. " - " .. remainingSec
    else
        timeDisplay.Text = "0 - 0"
    end
    
    -- Полоска VU и частицы
    if sharedSound.IsPlaying then
        local loudness = sharedSound.PlaybackLoudness
        local targetScale = math.clamp(loudness / 280, 0.05, 1)
        vuFill.Size = UDim2.new(1, 0, vuFill.Size.Y.Scale + (targetScale - vuFill.Size.Y.Scale) * 0.4, 0)
        
        particleEmitter.Rate = particlesActive and math.clamp(loudness / 5, 5, 30) or 0
        
        if isRainbowActive then
            local hue = (tick() * 0.3) % 1
            vuFill.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        else
            vuFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    else
        vuFill.Size = UDim2.new(1, 0, vuFill.Size.Y.Scale * 0.8, 0)
        particleEmitter.Rate = 0
        if not isRainbowActive then
            vuFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end)

volInput.FocusLost:Connect(function()
    local val = tonumber(volInput.Text)
    if val then sharedSound.Volume = val else volInput.Text = tostring(sharedSound.Volume) end
end)

bassInput.FocusLost:Connect(function()
    local val = tonumber(bassInput.Text)
    if val then eqEffect.LowGain = val else bassInput.Text = tostring(eqEffect.LowGain) end
end)

rainbowBtn.MouseButton1Click:Connect(function()
    isRainbowActive = not isRainbowActive
    rainbowBtn.Text = isRainbowActive and "🌈 Радуга: ВКЛ" or "🌈 Радуга: ВЫКЛ"
    rainbowBtn.BackgroundColor3 = isRainbowActive and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(150, 50, 200)
end)

shakeBtn.MouseButton1Click:Connect(function()
    shakeScreenActive = not shakeScreenActive
    shakeBtn.Text = shakeScreenActive and "📳 Shake Screen: ВКЛ" or "📳 Shake Screen: ВЫКЛ"
    shakeBtn.BackgroundColor3 = shakeScreenActive and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(70, 70, 80)
end)

particlesBtn.MouseButton1Click:Connect(function()
    particlesActive = not particlesActive
    particlesBtn.Text = particlesActive and "✨ Частицы из VU: ВКЛ" or "✨ Частицы из VU: ВЫКЛ"
    particlesBtn.BackgroundColor3 = particlesActive and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(70, 70, 80)
end)

local dragging, dragStart, startPos = false, nil, nil
phoneHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = phoneFrame.Position
    end
end)
userInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        phoneFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
userInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

phoneTool.Equipped:Connect(function() phoneFrame.Visible = true end)
phoneTool.Unequipped:Connect(function() phoneFrame.Visible = false end)

playBtn.MouseButton1Click:Connect(function()
    local numberId = idInput.Text:match("%d+")
    if numberId then
        sharedSound.SoundId = "rbxassetid://" .. numberId
        sharedSound:Play()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    sharedSound:Stop()
end)
