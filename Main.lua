if not game:IsLoaded() then game.Loaded:Wait() end
if ClickAbleObjectExplorer_Loaded then return warn("[ClickObjExplorer] Already Loaded!") end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local ScrollingFrame = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local TextButtonTemplate = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local MinimizeButton = Instance.new("TextButton")
local TopBar = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local SearchBox = Instance.new("TextBox")
local ResizeHandle = Instance.new("Frame")

local isMinimized, isVisible, isPaused, resizing, dragging = false, true, false, false, false
local addedObjects, buttons = {}, {}
local dragInput, dragStart, startPos, resizeStart, resizeStartSize

ScreenGui.Parent = game.CoreGui

Frame.Size = UDim2.new(0.4, 0, 0.3, 0) 
Frame.Position = UDim2.new(0.3, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Frame.Parent = ScreenGui
Frame.BorderSizePixel = 0
UICorner.Parent = Frame

TopBar.Parent = Frame
TopBar.Size = UDim2.new(1, 0, 0.1, 0)
TopBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
TopBar.BorderSizePixel = 0

Title.Parent = TopBar
Title.Text = "Clickable Object Explorer (INS Toggle)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1

SearchBox.Parent = Frame
SearchBox.Size = UDim2.new(1, 0, 0.05, 0)
SearchBox.Position = UDim2.new(0, 0, 0.1, 0)
SearchBox.PlaceholderText = "Search Object Name..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextScaled = true
SearchBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
SearchBox.BorderSizePixel = 0
UICorner.Parent = SearchBox

ScrollingFrame.Parent = Frame
ScrollingFrame.Size = UDim2.new(1, 0, 0.85, 0)
ScrollingFrame.Position = UDim2.new(0, 0, 0.15, 0)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 5, 0)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 5
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200)
UIListLayout.Parent = ScrollingFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

TextButtonTemplate.Size = UDim2.new(1, 0, 0, 30)
TextButtonTemplate.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TextButtonTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButtonTemplate.Font = Enum.Font.Gotham
TextButtonTemplate.TextWrapped = true
TextButtonTemplate.TextScaled = true
TextButtonTemplate.ClipsDescendants = true
TextButtonTemplate.BorderSizePixel = 0
Instance.new("UICorner", TextButtonTemplate)

ResizeHandle.Size = UDim2.new(0, 15, 0, 15)
ResizeHandle.Position = UDim2.new(1, -10, 1, -10)
ResizeHandle.BackgroundColor3 = Color3.new(0.705882, 0.705882, 0.705882)
ResizeHandle.BorderSizePixel = 0
ResizeHandle.Parent = Frame

local function makeDraggable(frame, handle)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart, startPos = input.Position, frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(Frame, TopBar)

local function getFullPath(object)
    local pathParts = {}

    while object do
        local name = object.Name

        table.insert(pathParts, 1, '["' .. name .. '"]')
        object = object.Parent
    end

    local fullPath = "game:GetService(\"Workspace\")"
    for i, part in ipairs(pathParts) do
        if i > 2 then
            fullPath = fullPath .. part
        end
    end

    return fullPath
end
local function createTween(button, color1, color2)
    local tweenIn = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), color1)
    local tweenOut = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), color2)
    tweenIn:Play()
    tweenIn.Completed:Connect(function()
        task.wait(0.1)
        tweenOut:Play()
    end)
end

local function addClickableObject(object) --Added Optimization Thanks for microwave.xyz
    local fullPath = getFullPath(object)
    if buttons[fullPath] then return end -- We don't care already added Objects

    local newButton = TextButtonTemplate:Clone()
    newButton.Parent = ScrollingFrame
    newButton.Text, newButton.Name = fullPath, fullPath

    buttons[fullPath], addedObjects[fullPath] = newButton, true

    -- Table to store connections for this object
    local connections = {}

    newButton.MouseButton1Click:Connect(function() 
        setclipboard(fullPath) 
        createTween(newButton, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
    end)

    local function tweenSequence(color1, color2)
        createTween(newButton, color1, color2)
    end

    if object:IsA("ClickDetector") then
        -- Store the connection in the connections table
        connections[#connections + 1] = object.MouseClick:Connect(function(player)
            if player == LocalPlayer then
                tweenSequence({BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
            end
        end)
    elseif object:IsA("ProximityPrompt") then
        connections[#connections + 1] = object.Triggered:Connect(function(player)
            if player == LocalPlayer then
                tweenSequence({BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
            end
        end)
    elseif object:IsA("TouchTransmitter") then
        -- Ensure the parent is a BasePart
        if object.Parent:IsA("BasePart") then
            connections[#connections + 1] = object.Parent.Touched:Connect(function(hit)
                local player = Players:GetPlayerFromCharacter(hit.Parent)
                if player and player == LocalPlayer then
                    tweenSequence({BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
                end
            end)
        end
    end

    -- Detect when the object is removed from the game
    connections[#connections + 1] = object.AncestryChanged:Connect(function(child, parent)
        if not parent then
            -- Object was removed from the game
            -- Disconnect all associated connections
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            -- Clean up the GUI and tables
            newButton:Destroy()
            buttons[fullPath] = nil
            addedObjects[fullPath] = nil
        end
    end)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = SearchBox.Text:lower()
    for fullPath, button in pairs(buttons) do
        button.Visible = string.find(fullPath:lower(), searchText) ~= nil
    end
end)

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizeStart, resizeStartSize, resizing, isPaused = input.Position, Frame.Size, true, true
    end
end)

ResizeHandle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing, isPaused = false, false end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and resizing then
        local delta = input.Position - resizeStart
        local newWidth, newHeight = math.max(resizeStartSize.X.Offset + delta.X, 5), math.max(resizeStartSize.Y.Offset + delta.Y, 5)
        Frame.Size = UDim2.new(resizeStartSize.X.Scale, newWidth, resizeStartSize.Y.Scale, newHeight)
    end
end)

UserInputService.InputBegan:Connect(function(input) --UI Closer/Opener (Open the noor)
    if input.KeyCode == Enum.KeyCode.Insert then
        isVisible = not isVisible
        Frame.Visible = isVisible
    end
end)

for _, object in ipairs(Workspace:GetDescendants()) do --First loading all current objects
    if object:IsA("ClickDetector") or object:IsA("ProximityPrompt") or object:IsA("TouchTransmitter") then
        addClickableObject(object)
    end
end

Workspace.DescendantAdded:Connect(function(object) --Later added objects will adding on list
    if object:IsA("ClickDetector") or object:IsA("ProximityPrompt") or object:IsA("TouchTransmitter") then
        addClickableObject(object)
    end
end)

getgenv().ClickAbleObjectExplorer_Loaded = true
