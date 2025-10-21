--[[
    InovoProductions Script Hub Library
    Modern Roblox UI Library in Luau
    
    Features:
    - Window & Tab System
    - UI Elements (Button, Toggle, Slider, Dropdown, Textbox, etc.)
    - Theme System
    - Flags for persistent settings
    - Notification System
]]

local InovoLib = {}
InovoLib.Flags = {}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Theme System
InovoLib.Theme = {
    -- Background Colors
    Background = Color3.fromRGB(20, 20, 25),
    BackgroundLight = Color3.fromRGB(25, 25, 30),
    BackgroundDark = Color3.fromRGB(15, 15, 20),
    
    -- Accent Colors
    Accent = Color3.fromRGB(88, 101, 242),
    AccentHover = Color3.fromRGB(108, 121, 255),
    AccentActive = Color3.fromRGB(68, 81, 222),
    
    -- Text Colors
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 190),
    TextDisabled = Color3.fromRGB(100, 100, 110),
    
    -- UI Colors
    Border = Color3.fromRGB(40, 40, 50),
    Divider = Color3.fromRGB(35, 35, 45),
    
    -- Status Colors
    Success = Color3.fromRGB(67, 181, 129),
    Warning = Color3.fromRGB(250, 166, 26),
    Error = Color3.fromRGB(240, 71, 71),
    Info = Color3.fromRGB(52, 152, 219),
}

-- Utility Functions
local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput, mousePos, framePos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
end

local function Tween(object, properties, duration, style, direction)
    duration = duration or 0.3
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or InovoLib.Theme.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Notification System
InovoLib.Notifications = {}

function InovoLib:Notify(options)
    options = options or {}
    local title = options.Title or "Notification"
    local message = options.Message or ""
    local duration = options.Duration or 3
    local type = options.Type or "Info" -- Info, Success, Warning, Error
    
    local notifContainer = self.NotificationContainer
    if not notifContainer then
        notifContainer = Instance.new("ScreenGui")
        notifContainer.Name = "InovoNotifications"
        notifContainer.ResetOnSpawn = false
        notifContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        notifContainer.Parent = CoreGui
        
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(0, 300, 1, 0)
        container.Position = UDim2.new(1, -320, 0, 20)
        container.BackgroundTransparency = 1
        container.Parent = notifContainer
        
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 10)
        layout.Parent = container
        
        self.NotificationContainer = container
    end
    
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 80)
    notif.BackgroundColor3 = InovoLib.Theme.BackgroundLight
    notif.BorderSizePixel = 0
    notif.ClipsDescendants = true
    notif.Parent = self.NotificationContainer
    
    CreateCorner(notif, 8)
    CreateStroke(notif, InovoLib.Theme.Border, 1)
    
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BorderSizePixel = 0
    accent.BackgroundColor3 = InovoLib.Theme[type] or InovoLib.Theme.Info
    accent.Parent = notif
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 15, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = InovoLib.Theme.TextPrimary
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notif
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -20, 0, 35)
    messageLabel.Position = UDim2.new(0, 15, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = InovoLib.Theme.TextSecondary
    messageLabel.TextSize = 12
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.Parent = notif
    
    -- Slide in animation
    notif.Position = UDim2.new(0, 320, 0, 0)
    Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
    
    -- Auto dismiss
    task.delay(duration, function()
        Tween(notif, {Position = UDim2.new(0, 320, 0, 0)}, 0.3)
        task.wait(0.3)
        notif:Destroy()
    end)
end

-- Main Window Creation
function InovoLib:CreateWindow(options)
    options = options or {}
    local windowTitle = options.Title or "InovoProductions"
    local windowSize = options.Size or UDim2.new(0, 600, 0, 400)
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InovoHub"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = CoreGui
    
    -- Main Container
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = windowSize
    mainFrame.Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
    mainFrame.BackgroundColor3 = InovoLib.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    CreateCorner(mainFrame, 10)
    CreateStroke(mainFrame, InovoLib.Theme.Border, 2)
    
    -- Shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ZIndex = 0
    shadow.Parent = mainFrame
    
    -- Top Bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = InovoLib.Theme.BackgroundDark
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = windowTitle
    title.TextColor3 = InovoLib.Theme.TextPrimary
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -40, 0, 0)
    closeBtn.BackgroundColor3 = InovoLib.Theme.BackgroundDark
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = InovoLib.Theme.TextPrimary
    closeBtn.TextSize = 24
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = topBar
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = InovoLib.Theme.Error})
    end)
    
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = InovoLib.Theme.BackgroundDark})
    end)
    
    -- Make draggable
    MakeDraggable(mainFrame, topBar)
    
    -- Tab Container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 150, 1, -40)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = InovoLib.Theme.BackgroundLight
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabContainer
    
    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingRight = UDim.new(0, 10)
    tabPadding.Parent = tabContainer
    
    -- Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -150, 1, -40)
    contentContainer.Position = UDim2.new(0, 150, 0, 40)
    contentContainer.BackgroundColor3 = InovoLib.Theme.Background
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainFrame
    
    -- Window Object
    local Window = {
        GUI = screenGui,
        Main = mainFrame,
        TabContainer = tabContainer,
        ContentContainer = contentContainer,
        Tabs = {},
        CurrentTab = nil
    }
    
    function Window:CreateTab(tabName)
        local Tab = {
            Name = tabName,
            Elements = {},
            Window = self
        }
        
        -- Tab Button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName
        tabButton.Size = UDim2.new(1, 0, 0, 35)
        tabButton.BackgroundColor3 = InovoLib.Theme.BackgroundLight
        tabButton.BorderSizePixel = 0
        tabButton.Text = tabName
        tabButton.TextColor3 = InovoLib.Theme.TextSecondary
        tabButton.TextSize = 13
        tabButton.Font = Enum.Font.GothamSemibold
        tabButton.Parent = tabContainer
        
        CreateCorner(tabButton, 6)
        
        -- Tab Content Frame
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tabName .. "Content"
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.Position = UDim2.new(0, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = InovoLib.Theme.Accent
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContent.Visible = false
        tabContent.Parent = contentContainer
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 8)
        contentLayout.Parent = tabContent
        
        local contentPadding = Instance.new("UIPadding")
        contentPadding.PaddingTop = UDim.new(0, 15)
        contentPadding.PaddingLeft = UDim.new(0, 15)
        contentPadding.PaddingRight = UDim.new(0, 15)
        contentPadding.PaddingBottom = UDim.new(0, 15)
        contentPadding.Parent = tabContent
        
        -- Auto-resize canvas
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 30)
        end)
        
        Tab.Button = tabButton
        Tab.Content = tabContent
        
        -- Tab switching
        tabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(self.Tabs) do
                tab.Content.Visible = false
                Tween(tab.Button, {
                    BackgroundColor3 = InovoLib.Theme.BackgroundLight,
                    TextColor3 = InovoLib.Theme.TextSecondary
                })
            end
            
            tabContent.Visible = true
            Tween(tabButton, {
                BackgroundColor3 = InovoLib.Theme.Accent,
                TextColor3 = InovoLib.Theme.TextPrimary
            })
            
            self.CurrentTab = Tab
        end)
        
        -- Hover effect
        tabButton.MouseEnter:Connect(function()
            if self.CurrentTab ~= Tab then
                Tween(tabButton, {BackgroundColor3 = InovoLib.Theme.BackgroundDark})
            end
        end)
        
        tabButton.MouseLeave:Connect(function()
            if self.CurrentTab ~= Tab then
                Tween(tabButton, {BackgroundColor3 = InovoLib.Theme.BackgroundLight})
            end
        end)
        
        -- Elements
        function Tab:AddButton(options)
            options = options or {}
            local buttonText = options.Text or "Button"
            local callback = options.Callback or function() end
            
            local buttonFrame = Instance.new("Frame")
            buttonFrame.Size = UDim2.new(1, 0, 0, 40)
            buttonFrame.BackgroundColor3 = InovoLib.Theme.BackgroundLight
            buttonFrame.BorderSizePixel = 0
            buttonFrame.Parent = self.Content
            
            CreateCorner(buttonFrame, 6)
            
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 1, 0)
            button.BackgroundTransparency = 1
            button.Text = buttonText
            button.TextColor3 = InovoLib.Theme.TextPrimary
            button.TextSize = 13
            button.Font = Enum.Font.GothamSemibold
            button.Parent = buttonFrame
            
            button.MouseButton1Click:Connect(function()
                Tween(buttonFrame, {BackgroundColor3 = InovoLib.Theme.AccentActive}, 0.1)
                task.wait(0.1)
                Tween(buttonFrame, {BackgroundColor3 = InovoLib.Theme.Accent}, 0.1)
                pcall(callback)
            end)
            
            button.MouseEnter:Connect(function()
                Tween(buttonFrame, {BackgroundColor3 = InovoLib.Theme.Accent})
            end)
            
            button.MouseLeave:Connect(function()
                Tween(buttonFrame, {BackgroundColor3 = InovoLib.Theme.BackgroundLight})
            end)
            
            return button
        end
        
        function Tab:AddToggle(options)
            options = options or {}
            local toggleText = options.Text or "Toggle"
            local default = options.Default or false
            local flag = options.Flag
            local callback = options.Callback or function() end
            
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(1, 0, 0, 40)
            toggleFrame.BackgroundColor3 = InovoLib.Theme.BackgroundLight
            toggleFrame.BorderSizePixel = 0
            toggleFrame.Parent = self.Content
            
            CreateCorner(toggleFrame, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = toggleText
            label.TextColor3 = InovoLib.Theme.TextPrimary
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = toggleFrame
            
            local toggleContainer = Instance.new("Frame")
            toggleContainer.Size = UDim2.new(0, 40, 0, 20)
            toggleContainer.Position = UDim2.new(1, -50, 0.5, -10)
            toggleContainer.BackgroundColor3 = InovoLib.Theme.BackgroundDark
            toggleContainer.BorderSizePixel = 0
            toggleContainer.Parent = toggleFrame
            
            CreateCorner(toggleContainer, 10)
            
            local toggleCircle = Instance.new("Frame")
            toggleCircle.Size = UDim2.new(0, 16, 0, 16)
            toggleCircle.Position = UDim2.new(0, 2, 0, 2)
            toggleCircle.BackgroundColor3 = InovoLib.Theme.TextSecondary
            toggleCircle.BorderSizePixel = 0
            toggleCircle.Parent = toggleContainer
            
            CreateCorner(toggleCircle, 8)
            
            local toggled = default
            
            local function UpdateToggle()
                if toggled then
                    Tween(toggleContainer, {BackgroundColor3 = InovoLib.Theme.Accent})
                    Tween(toggleCircle, {
                        Position = UDim2.new(0, 22, 0, 2),
                        BackgroundColor3 = InovoLib.Theme.TextPrimary
                    })
                else
                    Tween(toggleContainer, {BackgroundColor3 = InovoLib.Theme.BackgroundDark})
                    Tween(toggleCircle, {
                        Position = UDim2.new(0, 2, 0, 2),
                        BackgroundColor3 = InovoLib.Theme.TextSecondary
                    })
                end
                
                if flag then
                    InovoLib.Flags[flag] = toggled
                end
                
                pcall(callback, toggled)
            end
            
            local toggleButton = Instance.new("TextButton")
            toggleButton.Size = UDim2.new(1, 0, 1, 0)
            toggleButton.BackgroundTransparency = 1
            toggleButton.Text = ""
            toggleButton.Parent = toggleFrame
            
            toggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                UpdateToggle()
            end)
            
            UpdateToggle()
            
            return {
                Set = function(value)
                    toggled = value
                    UpdateToggle()
                end,
                Get = function()
                    return toggled
                end
            }
        end
        
        function Tab:AddSlider(options)
            options = options or {}
            local sliderText = options.Text or "Slider"
            local min = options.Min or 0
            local max = options.Max or 100
            local default = options.Default or min
            local increment = options.Increment or 1
            local flag = options.Flag
            local callback = options.Callback or function() end
            
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, 0, 0, 60)
            sliderFrame.BackgroundColor3 = InovoLib.Theme.BackgroundLight
            sliderFrame.BorderSizePixel = 0
            sliderFrame.Parent = self.Content
            
            CreateCorner(sliderFrame, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -30, 0, 20)
            label.Position = UDim2.new(0, 15, 0, 8)
            label.BackgroundTransparency = 1
            label.Text = sliderText
            label.TextColor3 = InovoLib.Theme.TextPrimary
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = sliderFrame
            
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0, 50, 0, 20)
            valueLabel.Position = UDim2.new(1, -65, 0, 8)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(default)
            valueLabel.TextColor3 = InovoLib.Theme.Accent
            valueLabel.TextSize = 13
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = sliderFrame
            
            local sliderBack = Instance.new("Frame")
            sliderBack.Size = UDim2.new(1, -30, 0, 4)
            sliderBack.Position = UDim2.new(0, 15, 0, 40)
            sliderBack.BackgroundColor3 = InovoLib.Theme.BackgroundDark
            sliderBack.BorderSizePixel = 0
            sliderBack.Parent = sliderFrame
            
            CreateCorner(sliderBack, 2)
            
            local sliderFill = Instance.new("Frame")
            sliderFill.Size = UDim2.new(0, 0, 1, 0)
            sliderFill.BackgroundColor3 = InovoLib.Theme.Accent
            sliderFill.BorderSizePixel = 0
            sliderFill.Parent = sliderBack
            
            CreateCorner(sliderFill, 2)
            
            local dragging = false
            local value = default
            
            local function UpdateSlider(newValue)
                value = math.clamp(math.floor(newValue / increment + 0.5) * increment, min, max)
                local percent = (value - min) / (max - min)
                
                Tween(sliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
                valueLabel.Text = tostring(value)
                
                if flag then
                    InovoLib.Flags[flag] = value
                end
                
                pcall(callback, value)
            end
            
            sliderBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    local pos = (input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X
                    UpdateSlider(min + (max - min) * pos)
                end
            end)
            
            sliderBack.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local pos = (input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X
                    pos = math.clamp(pos, 0, 1)
                    UpdateSlider(min + (max - min) * pos)
                end
            end)
            
            UpdateSlider(default)
            
            return {
                Set = function(newValue)
                    UpdateSlider(newValue)
                end,
                Get = function()
                    return value
                end
            }
        end
        
        function Tab:AddTextbox(options)
            options = options or {}
            local textboxText = options.Text or "Textbox"
            local default = options.Default or ""
            local placeholder = options.Placeholder or "Enter text..."
            local flag = options.Flag
            local callback = options.Callback or function() end
            
            local textboxFrame = Instance.new("Frame")
            textboxFrame.Size = UDim2.new(1, 0, 0, 70)
            textboxFrame.BackgroundColor3 = InovoLib.Theme.BackgroundLight
            textboxFrame.BorderSizePixel = 0
            textboxFrame.Parent = self.Content
            
            CreateCorner(textboxFrame, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -30, 0, 20)
            label.Position = UDim2.new(0, 15, 0, 8)
            label.BackgroundTransparency = 1
            label.Text = textboxText
            label.TextColor3 = InovoLib.Theme.TextPrimary
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = textboxFrame
            
            local textbox = Instance.new("TextBox")
            textbox.Size = UDim2.new(1, -30, 0, 30)
            textbox.Position = UDim2.new(0, 15, 0, 32)
            textbox.BackgroundColor3 = InovoLib.Theme.BackgroundDark
            textbox.BorderSizePixel = 0
            textbox.Text = default
            textbox.PlaceholderText = placeholder
            textbox.TextColor3 = InovoLib.Theme.TextPrimary
            textbox.PlaceholderColor3 = InovoLib.Theme.TextDisabled
            textbox.TextSize = 12
            textbox.Font = Enum.Font.Gotham
            textbox.ClearTextOnFocus = false
            textbox.Parent = textboxFrame
            
            CreateCorner(textbox, 4)
            
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 10)
            padding.PaddingRight = UDim.new(0, 10)
            padding.Parent = textbox
            
            textbox.FocusLost:Connect(function(enterPressed)
                if flag then
                    InovoLib.Flags[flag] = textbox.Text
                end
                pcall(callback, textbox.Text, enterPressed)
            end)
            
            return {
                Set = function(text)
                    textbox.Text = text
                end,
                Get = function()
                    return textbox.Text
                end
            }
        end
        
        function Tab:AddDropdown(options)
            options = options or {}
            local dropdownText = options.Text or "Dropdown"
            local items = options.Items or {}
            local default = options.Default or (items[1] or "None")
            local flag = options.Flag
            local callback = options.Callback or function() end
            
            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Size = UDim2.new(1, 0, 0, 70)
            dropdownFrame.BackgroundColor3 = InovoLib.Theme.BackgroundLight
            dropdownFrame.BorderSizePixel = 0
            dropdownFrame.ClipsDescendants = false
            dropdownFrame.Parent = self.Content
            
            CreateCorner(dropdownFrame, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -30, 0, 20)
            label.Position = UDim2.new(0, 15, 0, 8)
            label.BackgroundTransparency = 1
            label.Text = dropdownText
            label.TextColor3 = InovoLib.Theme.TextPrimary
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = dropdownFrame
            
            local selected = default
            local isOpen = false
            
            local selector = Instance.new("TextButton")
            selector.Size = UDim2.new(1, -30, 0, 30)
            selector.Position = UDim2.new(0, 15, 0, 32)
            selector.BackgroundColor3 = InovoLib.Theme.BackgroundDark
            selector.BorderSizePixel = 0
            selector.Text = selected
            selector.TextColor3 = InovoLib.Theme.TextPrimary
            selector.TextSize = 12
            selector.Font = Enum.Font.Gotham
            selector.TextXAlignment = Enum.TextXAlignment.Left
            selector.Parent = dropdownFrame
            
            CreateCorner(selector, 4)
            
            local selectorPadding = Instance.new("UIPadding")
            selectorPadding.PaddingLeft = UDim.new(0, 10)
            selectorPadding.PaddingRight = UDim.new(0, 30)
            selectorPadding.Parent = selector
            
            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -25, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.TextColor3 = InovoLib.Theme.TextSecondary
            arrow.TextSize = 10
            arrow.Font = Enum.Font.Gotham
            arrow.Parent = selector
            
            local itemContainer = Instance.new("Frame")
            itemContainer.Size = UDim2.new(1, -30, 0, 0)
            itemContainer.Position = UDim2.new(0, 15, 0, 67)
            itemContainer.BackgroundColor3 = InovoLib.Theme.BackgroundDark
            itemContainer.BorderSizePixel = 0
            itemContainer.Visible = false
            itemContainer.ZIndex = 10
            itemContainer.ClipsDescendants = true
            itemContainer.Parent = dropdownFrame
            
            CreateCorner(itemContainer, 4)
            CreateStroke(itemContainer, InovoLib.Theme.Border, 1)
            
            local itemLayout = Instance.new("UIListLayout")
            itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
            itemLayout.Parent = itemContainer
            
            for _, item in ipairs(items) do
                local itemButton = Instance.new("TextButton")
                itemButton.Size = UDim2.new(1, 0, 0, 30)
                itemButton.BackgroundColor3 = InovoLib.Theme.BackgroundDark
                itemButton.BorderSizePixel = 0
                itemButton.Text = item
                itemButton.TextColor3 = InovoLib.Theme.TextPrimary
                itemButton.TextSize = 12
                itemButton.Font = Enum.Font.Gotham
                itemButton.TextXAlignment = Enum.TextXAlignment.Left
                itemButton.Parent = itemContainer
                
                local itemPadding = Instance.new("UIPadding")
                itemPadding.PaddingLeft = UDim.new(0, 10)
                itemPadding.Parent = itemButton
                
                itemButton.MouseButton1Click:Connect(function()
                    selected = item
                    selector.Text = selected
                    isOpen = false
                    itemContainer.Visible = false
                    Tween(arrow, {Rotation = 0}, 0.2)
                    
                    if flag then
                        InovoLib.Flags[flag] = selected
                    end
                    
                    pcall(callback, selected)
                end)
                
                itemButton.MouseEnter:Connect(function()
                    Tween(itemButton, {BackgroundColor3 = InovoLib.Theme.Accent})
                end)
                
                itemButton.MouseLeave:Connect(function()
                    Tween(itemButton, {BackgroundColor3 = InovoLib.Theme.BackgroundDark})
                end)
            end
            
            selector.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                itemContainer.Visible = isOpen
                
                if isOpen then
                    Tween(arrow, {Rotation = 180}, 0.2)
                    Tween(itemContainer, {Size = UDim2.new(1, -30, 0, math.min(#items * 30, 120))}, 0.2)
                else
                    Tween(arrow, {Rotation = 0}, 0.2)
                    Tween(itemContainer, {Size = UDim2.new(1, -30, 0, 0)}, 0.2)
                end
            end)
            
            return {
                Set = function(item)
                    selected = item
                    selector.Text = selected
                end,
                Get = function()
                    return selected
                end,
                Refresh = function(newItems)
                    for _, child in ipairs(itemContainer:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    
                    items = newItems
                    for _, item in ipairs(items) do
                        local itemButton = Instance.new("TextButton")
                        itemButton.Size = UDim2.new(1, 0, 0, 30)
                        itemButton.BackgroundColor3 = InovoLib.Theme.BackgroundDark
                        itemButton.BorderSizePixel = 0
                        itemButton.Text = item
                        itemButton.TextColor3 = InovoLib.Theme.TextPrimary
                        itemButton.TextSize = 12
                        itemButton.Font = Enum.Font.Gotham
                        itemButton.TextXAlignment = Enum.TextXAlignment.Left
                        itemButton.Parent = itemContainer
                        
                        local itemPadding = Instance.new("UIPadding")
                        itemPadding.PaddingLeft = UDim.new(0, 10)
                        itemPadding.Parent = itemButton
                        
                        itemButton.MouseButton1Click:Connect(function()
                            selected = item
                            selector.Text = selected
                            isOpen = false
                            itemContainer.Visible = false
                            
                            if flag then
                                InovoLib.Flags[flag] = selected
                            end
                            
                            pcall(callback, selected)
                        end)
                    end
                end
            }
        end
        
        function Tab:AddLabel(text)
            local labelFrame = Instance.new("Frame")
            labelFrame.Size = UDim2.new(1, 0, 0, 30)
            labelFrame.BackgroundTransparency = 1
            labelFrame.Parent = self.Content
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -30, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = InovoLib.Theme.TextSecondary
            label.TextSize = 12
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextWrapped = true
            label.Parent = labelFrame
            
            return {
                Set = function(newText)
                    label.Text = newText
                end
            }
        end
        
        function Tab:AddDivider()
            local divider = Instance.new("Frame")
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.BackgroundColor3 = InovoLib.Theme.Divider
            divider.BorderSizePixel = 0
            divider.Parent = self.Content
            
            return divider
        end
        
        table.insert(self.Tabs, Tab)
        
        -- Auto-select first tab
        if #self.Tabs == 1 then
            task.spawn(function()
                task.wait(0.05)
                for _, tab in pairs(self.Tabs) do
                    tab.Content.Visible = false
                    tab.Button.BackgroundColor3 = InovoLib.Theme.BackgroundLight
                    tab.Button.TextColor3 = InovoLib.Theme.TextSecondary
                end
                
                tabContent.Visible = true
                tabButton.BackgroundColor3 = InovoLib.Theme.Accent
                tabButton.TextColor3 = InovoLib.Theme.TextPrimary
                self.CurrentTab = Tab
            end)
        end
        
        return Tab
    end
    
    return Window
end

return InovoLib

