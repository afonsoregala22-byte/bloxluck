local LocalPlayer = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local function sendMessage(msg)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        pcall(function()
            TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
        end)
    end
end

if not LocalPlayer.PlayerGui:FindFirstChild("TradeManagerUI") then
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TradeManagerUI"
    ScreenGui.Parent = LocalPlayer.PlayerGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 9999
    ScreenGui.Enabled = true

    local uiFrame = Instance.new("Frame")
    uiFrame.Size = UDim2.new(0, 350, 0, 100)
    uiFrame.Position = UDim2.new(0.5, -175, 0.5, -50)
    uiFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    uiFrame.BackgroundTransparency = 0.70
    uiFrame.BorderSizePixel = 0
    uiFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    uiFrame.Active = true
    uiFrame.Draggable = true
    uiFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = uiFrame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 300, 0, 60)
    button.Position = UDim2.new(0.5, -150, 0.5, -30)
    button.Text = "TRADEBOT: OFF"
    button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Parent = uiFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 12)
    buttonCorner.Parent = button

    local isTradeProcessActive = false
    local tradeThread = nil

    button.MouseButton1Click:Connect(function()
        if isTradeProcessActive then
            isTradeProcessActive = false
            button.Text = "TRADEBOT: OFF"
            button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            if tradeThread then
                tradeThread = nil
            end
        else
            isTradeProcessActive = true
            button.Text = "TRADEBOT: ON"
            button.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            if not tradeThread then
                tradeThread = coroutine.create(tradeProcess)
                coroutine.resume(tradeThread)
            end
        end
    end)

    local UserInputService = game:GetService("UserInputService")
    local elapsed = 0
    local connection = nil

    UserInputService.InputBegan:Connect(function()
        if connection then
            connection:Disconnect()
            connection = nil
            elapsed = 0
        end
    end)

    UserInputService.InputEnded:Connect(function()
        connection = game.RunService.Heartbeat:Connect(function(delta)
            elapsed += delta
            if elapsed >= 1199 then
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                elapsed -= 1199
            end
        end)
    end)

    local function getplayertag()
        local tradeRequestLabel = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.HUD.TradeRequest:FindFirstChild("Label")
        if tradeRequestLabel then
            local labelText = tradeRequestLabel.Text
            local playerName = labelText:match("<font.->(.-)</font>")
            if playerName then
                local player = game:GetService("Players"):FindFirstChild(playerName)
                if player then
                    return player
                end
            end
        end
        return nil
    end

    local victim = nil

    local function handleTradeRequest()
        local acceptCooldown = false
        while true do
            if button.Text == "TRADEBOT: ON" then
                local tradeRequest = LocalPlayer.PlayerGui.ScreenGui.HUD:WaitForChild("TradeRequest")
                if tradeRequest.Visible == true and not acceptCooldown then
                    task.wait(0.3)
                    victim = getplayertag()
                    if victim then
                        ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("TradeAcceptRequest", victim)
                        local depomessage = "trade with " .. victim.Name .. " started, deposit"
                        sendMessage(depomessage)

                        acceptCooldown = true
                        task.wait(6.5)
                        acceptCooldown = false
                    end
                end
            end
            task.wait(0.01)
        end
    end

    local function handleTradeConfirmation()
        while true do
            if victim and LocalPlayer.PlayerGui.ScreenGui.Trading.Frame.Inner.Them.Cover.Visible == true and LocalPlayer.PlayerGui.ScreenGui.Trading.Visible == true then
                task.wait(0.5)
                local remote = ReplicatedStorage.Shared.Framework.Network.Remote.Event
                remote:FireServer("TradeAccept")
                task.wait(3)

                while LocalPlayer.PlayerGui.ScreenGui.Trading.Visible == true do
                    local status = LocalPlayer.PlayerGui.ScreenGui.Trading.Frame.Inner.Offers.Status.Text
                    if status == victim.Name .. " has confirmed!" then
                        remote:FireServer("TradeConfirm")
                    end
                    task.wait(0.3)
                end

                victim = nil
            end
            task.wait(0.01)
        end
    end

    function tradeProcess()
        coroutine.wrap(handleTradeRequest)()
        coroutine.wrap(handleTradeConfirmation)()
    end
end
