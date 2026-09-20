--[[
    Ryken UI Library
    Library/Ryken.lua
]]

local Ryken = {}
Ryken.__index = Ryken

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// External Modules
local Icons = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/getryken/Ryken/main/Library/Icons.lua"
))()

local Config = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/getryken/Ryken/refs/heads/main/Library/Config.lua"
))()

local ConfigManager = Config.new()

--// Configuration
Ryken.Config = ConfigManager
Ryken.Flags = ConfigManager.Flags

Ryken.Version = "1.0.0"

--// Colors
local COLORS = {
    Background = Color3.fromRGB(12, 12, 14),
    Secondary = Color3.fromRGB(17, 17, 20),
    Tertiary = Color3.fromRGB(22, 22, 25),

    Border = Color3.fromRGB(38, 38, 43),

    Text = Color3.fromRGB(245, 245, 247),
    SubText = Color3.fromRGB(150, 150, 157),
    Muted = Color3.fromRGB(105, 105, 112),

    Accent = Color3.fromRGB(255, 255, 255),
    AccentDark = Color3.fromRGB(205, 205, 210),

    ToggleOff = Color3.fromRGB(50, 50, 55),
    ToggleOn = Color3.fromRGB(235, 235, 238),
}

--// Helpers
local function Create(class, properties)
    local object = Instance.new(class)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    return object
end

local function Corner(parent, radius)
    return Create("UICorner", {
        Parent = parent,
        CornerRadius = UDim.new(0, radius or 8)
    })
end

local function Stroke(parent, color, thickness)
    return Create("UIStroke", {
        Parent = parent,
        Color = color or COLORS.Border,
        Thickness = thickness or 1
    })
end

local function Padding(parent, top, right, bottom, left)
    return Create("UIPadding", {
        Parent = parent,
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0)
    })
end

local function Tween(object, time, properties, style, direction)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            time or 0.2,
            style or Enum.EasingStyle.Quart,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()
    return tween
end

local function SafeCallback(callback, ...)
    if typeof(callback) ~= "function" then
        return
    end

    task.spawn(function()
        pcall(callback, ...)
    end)
end

local function GetIcon(icon)
    if not icon then
        return nil
    end

    if typeof(Icons) ~= "table" then
        return nil
    end

    local data = Icons[icon]

    if typeof(data) == "string" then
        return data
    end

    if typeof(data) == "table" then
        return data.Image or data.ImageId or data.Asset
    end

    return nil
end

local function SetIcon(image, icon)
    if not image then
        return
    end

    local asset = GetIcon(icon)

    if asset then
        image.Image = asset
        image.Visible = true
    else
        image.Visible = false
    end
end

--// ScreenGui
local ScreenGui

local function GetParent()
    local success, result = pcall(function()
        if gethui then
            return gethui()
        end
    end)

    if success and result then
        return result
    end

    return CoreGui
end

local function CreateScreenGui()
    local existing = GetParent():FindFirstChild("Ryken")

    if existing then
        existing:Destroy()
    end

    ScreenGui = Create("ScreenGui", {
        Name = "Ryken",
        Parent = GetParent(),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })

    return ScreenGui
end

--// Dragging
local function MakeDraggable(object, handle)
    handle = handle or object

    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = object.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        object.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

--// Window
function Ryken:CreateWindow(options)
    options = options or {}

    local windowObject = setmetatable({}, {
        __index = function(_, key)
            return Ryken[key]
        end
    })

    windowObject.Title = options.Title or "Ryken"
    windowObject.Subtitle = options.Subtitle or ""
    windowObject.Size = options.Size or UDim2.fromOffset(620, 430)

    CreateScreenGui()

    --// Main Window
    local Window = Create("Frame", {
        Parent = ScreenGui,
        Name = "Window",
        Size = windowObject.Size,
        Position = UDim2.new(0.5, -windowObject.Size.X.Offset / 2, 0.5, -windowObject.Size.Y.Offset / 2),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0
    })

    Corner(Window, 12)
    Stroke(Window)

    windowObject.Instance = Window
    windowObject.Tabs = {}
    windowObject.CurrentTab = nil

    --// Scale
    local UIScale = Create("UIScale", {
        Parent = Window,
        Scale = 1
    })

    windowObject.UIScale = UIScale

    --// Header
    local Header = Create("Frame", {
        Parent = Window,
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundTransparency = 1
    })

    MakeDraggable(Window, Header)

    local Title = Create("TextLabel", {
        Parent = Header,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(20, 13),
        Size = UDim2.new(1, -130, 0, 24),
        Font = Enum.Font.GothamSemibold,
        Text = windowObject.Title,
        TextColor3 = COLORS.Text,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local Subtitle = Create("TextLabel", {
        Parent = Header,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(21, 36),
        Size = UDim2.new(1, -130, 0, 16),
        Font = Enum.Font.Gotham,
        Text = windowObject.Subtitle,
        TextColor3 = COLORS.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    --// Minimize
    local Minimize = Create("TextButton", {
        Parent = Header,
        Name = "Minimize",
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -72, 0, 18),
        Size = UDim2.fromOffset(26, 26),
        AutoButtonColor = false,
        Text = ""
    })

    Corner(Minimize, 7)
    Stroke(Minimize)

    local MinimizeIcon = Create("ImageLabel", {
        Parent = Minimize,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(15, 15),
        ImageColor3 = COLORS.Text
    })

    SetIcon(MinimizeIcon, "minus")

    --// Close
    local Close = Create("TextButton", {
        Parent = Header,
        Name = "Close",
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -38, 0, 18),
        Size = UDim2.fromOffset(26, 26),
        AutoButtonColor = false,
        Text = ""
    })

    Corner(Close, 7)
    Stroke(Close)

    local CloseIcon = Create("ImageLabel", {
        Parent = Close,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(15, 15),
        ImageColor3 = COLORS.Text
    })

    SetIcon(CloseIcon, "x")

    --// Body
    local Body = Create("Frame", {
        Parent = Window,
        Position = UDim2.fromOffset(12, 64),
        Size = UDim2.new(1, -24, 1, -76),
        BackgroundTransparency = 1
    })

    --// Sidebar
    local Sidebar = Create("Frame", {
        Parent = Body,
        Name = "Sidebar",
        Size = UDim2.fromOffset(150, 1),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0
    })

    Corner(Sidebar, 9)
    Stroke(Sidebar)

    local TabList = Create("ScrollingFrame", {
        Parent = Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 8),
        Size = UDim2.new(1, -12, 1, -16),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    Padding(TabList, 2, 2, 2, 2)

    Create("UIListLayout", {
        Parent = TabList,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    --// Content
    local Content = Create("Frame", {
        Parent = Body,
        Name = "Content",
        Position = UDim2.fromOffset(162, 0),
        Size = UDim2.new(1, -162, 1, 0),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0
    })

    Corner(Content, 9)
    Stroke(Content)

    windowObject.Sidebar = Sidebar
    windowObject.Content = Content

    --// Bubble
    local Bubble = Create("ImageButton", {
        Parent = ScreenGui,
        Name = "MinimizeBubble",
        Size = UDim2.fromOffset(58, 58),
        Position = UDim2.new(1, -78, 1, -88),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Image = "rbxassetid://84328669110423",
        ScaleType = Enum.ScaleType.Fit,
        Visible = false
    })

    Corner(Bubble, 29)
    Stroke(Bubble)

    windowObject.Bubble = Bubble

    MakeDraggable(Bubble)

    local function Restore()
        Bubble.Visible = false
        Window.Visible = true

        Window.Size = UDim2.fromOffset(0, 0)

        Tween(Window, 0.25, {
            Size = windowObject.Size
        })
    end

    local function MinimizeWindow()
        Tween(Window, 0.2, {
            Size = UDim2.fromOffset(0, 0)
        }).Completed:Connect(function()
            Window.Visible = false
            Bubble.Visible = true
        end)
    end

    Minimize.MouseButton1Click:Connect(MinimizeWindow)
    Bubble.MouseButton1Click:Connect(Restore)

    Close.MouseButton1Click:Connect(function()
        Window.Visible = false
        Bubble.Visible = false
    end)

    Minimize.MouseEnter:Connect(function()
        Tween(Minimize, 0.15, {
            BackgroundColor3 = COLORS.Tertiary
        })
    end)

    Minimize.MouseLeave:Connect(function()
        Tween(Minimize, 0.15, {
            BackgroundColor3 = COLORS.Secondary
        })
    end)

    Close.MouseEnter:Connect(function()
        Tween(Close, 0.15, {
            BackgroundColor3 = COLORS.Tertiary
        })
    end)

    Close.MouseLeave:Connect(function()
        Tween(Close, 0.15, {
            BackgroundColor3 = COLORS.Secondary
        })
    end)

    --// Tab Creation
    function windowObject:CreateTab(tabOptions)
        tabOptions = tabOptions or {}

        local Tab = {}
        Tab.Name = tabOptions.Name or "Tab"
        Tab.Icon = tabOptions.Icon
        Tab.Elements = {}

        local TabButton = Create("TextButton", {
            Parent = TabList,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = COLORS.Secondary,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = ""
        })

        Corner(TabButton, 7)

        local TabIcon = Create("ImageLabel", {
            Parent = TabButton,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 10),
            Size = UDim2.fromOffset(16, 16),
            ImageColor3 = COLORS.SubText
        })

        SetIcon(TabIcon, Tab.Icon)

        local TabText = Create("TextLabel", {
            Parent = TabButton,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(34, 0),
            Size = UDim2.new(1, -42, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = Tab.Name,
            TextColor3 = COLORS.SubText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local Page = Create("ScrollingFrame", {
            Parent = Content,
            Name = Tab.Name,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.new(1, -16, 1, -16),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = COLORS.Border,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false
        })

        Padding(Page, 4, 5, 8, 5)

        Create("UIListLayout", {
            Parent = Page,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        Tab.Button = TabButton
        Tab.Page = Page
        Tab.IconObject = TabIcon
        Tab.TextObject = TabText

        table.insert(windowObject.Tabs, Tab)

        local function Select()
            for _, other in ipairs(windowObject.Tabs) do
                other.Page.Visible = false

                Tween(other.Button, 0.15, {
                    BackgroundTransparency = 1
                })

                Tween(other.TextObject, 0.15, {
                    TextColor3 = COLORS.SubText
                })

                Tween(other.IconObject, 0.15, {
                    ImageColor3 = COLORS.SubText
                })
            end

            Page.Visible = true

            Tween(TabButton, 0.15, {
                BackgroundTransparency = 0
            })

            Tween(TabText, 0.15, {
                TextColor3 = COLORS.Text
            })

            Tween(TabIcon, 0.15, {
                ImageColor3 = COLORS.Text
            })

            windowObject.CurrentTab = Tab
        end

        TabButton.MouseButton1Click:Connect(Select)

        TabButton.MouseEnter:Connect(function()
            if windowObject.CurrentTab ~= Tab then
                Tween(TabButton, 0.15, {
                    BackgroundColor3 = COLORS.Tertiary,
                    BackgroundTransparency = 0.5
                })
            end
        end)

        TabButton.MouseLeave:Connect(function()
            if windowObject.CurrentTab ~= Tab then
                Tween(TabButton, 0.15, {
                    BackgroundTransparency = 1
                })
            end
        end)

        --// Section
        function Tab:CreateSection(name)
            local Section = {}

            local Container = Create("Frame", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = COLORS.Tertiary,
                BorderSizePixel = 0
            })

            Corner(Container, 8)
            Stroke(Container)

            Padding(Container, 10, 10, 10, 10)

            local SectionTitle = Create("TextLabel", {
                Parent = Container,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = name or "Section",
                TextColor3 = COLORS.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Elements = Create("Frame", {
                Parent = Container,
                Position = UDim2.fromOffset(0, 29),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1
            })

            Create("UIListLayout", {
                Parent = Elements,
                Padding = UDim.new(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Section.Container = Container
            Section.Elements = Elements

            --// Button
            function Section:CreateButton(elementOptions)
                elementOptions = elementOptions or {}

                local Button = Create("TextButton", {
                    Parent = Elements,
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = COLORS.Secondary,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = ""
                })

                Corner(Button, 7)

                local Icon = Create("ImageLabel", {
                    Parent = Button,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(11, 11),
                    Size = UDim2.fromOffset(16, 16),
                    ImageColor3 = COLORS.SubText
                })

                SetIcon(Icon, elementOptions.Icon)

                local Text = Create("TextLabel", {
                    Parent = Button,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(
                        elementOptions.Icon and 36 or 12,
                        0
                    ),
                    Size = UDim2.new(1, -48, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = elementOptions.Name or "Button",
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                Button.MouseButton1Click:Connect(function()
                    SafeCallback(elementOptions.Callback)
                end)

                Button.MouseEnter:Connect(function()
                    Tween(Button, 0.12, {
                        BackgroundColor3 = COLORS.Border
                    })
                end)

                Button.MouseLeave:Connect(function()
                    Tween(Button, 0.12, {
                        BackgroundColor3 = COLORS.Secondary
                    })
                end)

                return Button
            end

            --// Toggle
            function Section:CreateToggle(elementOptions)
                elementOptions = elementOptions or {}

                local flag = elementOptions.Flag or elementOptions.Name or "Toggle"
                local value = elementOptions.Default == true

                ConfigManager:RegisterFlag(flag, value)

                value = ConfigManager:GetFlag(flag, value)

                local Toggle = Create("TextButton", {
                    Parent = Elements,
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundColor3 = COLORS.Secondary,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = ""
                })

                Corner(Toggle, 7)

                local Text = Create("TextLabel", {
                    Parent = Toggle,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(12, 0),
                    Size = UDim2.new(1, -70, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = elementOptions.Name or "Toggle",
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local Switch = Create("Frame", {
                    Parent = Toggle,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(38, 20),
                    BackgroundColor3 = COLORS.ToggleOff,
                    BorderSizePixel = 0
                })

                Corner(Switch, 10)

                local Knob = Create("Frame", {
                    Parent = Switch,
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.fromOffset(3, 3),
                    BackgroundColor3 = COLORS.SubText,
                    BorderSizePixel = 0
                })

                Corner(Knob, 7)

                local function Update(state, callback)
                    value = state

                    ConfigManager:SetFlag(flag, value)

                    Tween(Switch, 0.15, {
                        BackgroundColor3 = value
                            and COLORS.ToggleOn
                            or COLORS.ToggleOff
                    })

                    Tween(Knob, 0.15, {
                        Position = value
                            and UDim2.new(1, -17, 0, 3)
                            or UDim2.fromOffset(3, 3),
                        BackgroundColor3 = value
                            and COLORS.Background
                            or COLORS.SubText
                    })

                    if callback then
                        SafeCallback(callback, value)
                    end
                end

                Toggle.MouseButton1Click:Connect(function()
                    Update(not value, elementOptions.Callback)
                end)

                Update(value)

                return {
                    Set = function(_, state)
                        Update(state, elementOptions.Callback)
                    end,

                    Get = function()
                        return value
                    end
                }
            end

            --// Slider
            function Section:CreateSlider(elementOptions)
                elementOptions = elementOptions or {}

                local flag = elementOptions.Flag or elementOptions.Name or "Slider"

                local minimum = elementOptions.Min or 0
                local maximum = elementOptions.Max or 100
                local default = elementOptions.Default or minimum

                ConfigManager:RegisterFlag(flag, default)

                local value = ConfigManager:GetFlag(flag, default)

                local Container = Create("Frame", {
                    Parent = Elements,
                    Size = UDim2.new(1, 0, 0, 58),
                    BackgroundColor3 = COLORS.Secondary,
                    BorderSizePixel = 0
                })

                Corner(Container, 7)

                local Label = Create("TextLabel", {
                    Parent = Container,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(12, 7),
                    Size = UDim2.new(1, -70, 0, 20),
                    Font = Enum.Font.GothamMedium,
                    Text = elementOptions.Name or "Slider",
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local ValueLabel = Create("TextLabel", {
                    Parent = Container,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -12, 0, 7),
                    Size = UDim2.fromOffset(50, 20),
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(value),
                    TextColor3 = COLORS.SubText,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right
                })

                local Bar = Create("Frame", {
                    Parent = Container,
                    Position = UDim2.fromOffset(12, 37),
                    Size = UDim2.new(1, -24, 0, 5),
                    BackgroundColor3 = COLORS.Border,
                    BorderSizePixel = 0
                })

                Corner(Bar, 3)

                local Fill = Create("Frame", {
                    Parent = Bar,
                    Size = UDim2.new(
                        math.clamp((value - minimum) / (maximum - minimum), 0, 1),
                        0,
                        1,
                        0
                    ),
                    BackgroundColor3 = COLORS.Accent,
                    BorderSizePixel = 0
                })

                Corner(Fill, 3)

                local Dragging = false

                local function SetValue(newValue, callback)
                    value = math.clamp(newValue, minimum, maximum)

                    local percent = (value - minimum) / (maximum - minimum)

                    ValueLabel.Text = tostring(value)

                    Tween(Fill, 0.08, {
                        Size = UDim2.new(percent, 0, 1, 0)
                    })

                    ConfigManager:SetFlag(flag, value)

                    if callback then
                        SafeCallback(callback, value)
                    end
                end

                local function UpdateFromInput(input)
                    local percent = math.clamp(
                        (input.Position.X - Bar.AbsolutePosition.X)
                        / Bar.AbsoluteSize.X,
                        0,
                        1
                    )

                    local newValue = minimum + ((maximum - minimum) * percent)
                    newValue = math.floor(newValue + 0.5)

                    SetValue(newValue, elementOptions.Callback)
                end

                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then

                        Dragging = true
                        UpdateFromInput(input)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if not Dragging then
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then

                        UpdateFromInput(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then

                        Dragging = false
                    end
                end)

                return {
                    Set = function(_, newValue)
                        SetValue(newValue, elementOptions.Callback)
                    end,

                    Get = function()
                        return value
                    end
                }
            end

            --// Dropdown
            function Section:CreateDropdown(elementOptions)
                elementOptions = elementOptions or {}

                local flag = elementOptions.Flag or elementOptions.Name or "Dropdown"
                local values = elementOptions.Values or {}
                local current = elementOptions.Default or values[1]

                ConfigManager:RegisterFlag(flag, current)
                current = ConfigManager:GetFlag(flag, current)

                local Open = false

                local Container = Create("Frame", {
                    Parent = Elements,
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundColor3 = COLORS.Secondary,
                    BorderSizePixel = 0,
                    ClipsDescendants = true
                })

                Corner(Container, 7)

                local MainButton = Create("TextButton", {
                    Parent = Container,
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundTransparency = 1,
                    AutoButtonColor = false,
                    Text = ""
                })

                local Label = Create("TextLabel", {
                    Parent = MainButton,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(12, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = elementOptions.Name or "Dropdown",
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local Selected = Create("TextLabel", {
                    Parent = MainButton,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(0.5, -38, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = tostring(current or ""),
                    TextColor3 = COLORS.SubText,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right
                })

                local Arrow = Create("ImageLabel", {
                    Parent = MainButton,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    ImageColor3 = COLORS.SubText
                })

                SetIcon(Arrow, "chevron-down")

                local List = Create("Frame", {
                    Parent = Container,
                    Position = UDim2.fromOffset(8, 46),
                    Size = UDim2.new(1, -16, 0, math.min(#values * 32, 160)),
                    BackgroundTransparency = 1
                })

                Create("UIListLayout", {
                    Parent = List,
                    Padding = UDim.new(0, 4)
                })

                for _, item in ipairs(values) do
                    local Item = Create("TextButton", {
                        Parent = List,
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundColor3 = COLORS.Tertiary,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = tostring(item),
                        Font = Enum.Font.Gotham,
                        TextSize = 11,
                        TextColor3 = COLORS.Text
                    })

                    Corner(Item, 6)

                    Item.MouseButton1Click:Connect(function()
                        current = item
                        Selected.Text = tostring(item)

                        ConfigManager:SetFlag(flag, current)

                        SafeCallback(elementOptions.Callback, current)

                        Open = false

                        Tween(Container, 0.2, {
                            Size = UDim2.new(1, 0, 0, 42)
                        })

                        Tween(Arrow, 0.2, {
                            Rotation = 0
                        })
                    end)
                end

                MainButton.MouseButton1Click:Connect(function()
                    Open = not Open

                    local height = 42

                    if Open then
                        height = 54 + math.min(#values * 32, 160)
                    end

                    Tween(Container, 0.2, {
                        Size = UDim2.new(1, 0, 0, height)
                    })

                    Tween(Arrow, 0.2, {
                        Rotation = Open and 180 or 0
                    })
                end)

                return {
                    Set = function(_, item)
                        current = item
                        Selected.Text = tostring(item)
                        ConfigManager:SetFlag(flag, item)
                        SafeCallback(elementOptions.Callback, item)
                    end,

                    Get = function()
                        return current
                    end
                }
            end

            --// Textbox
            function Section:CreateTextbox(elementOptions)
                elementOptions = elementOptions or {}

                local flag = elementOptions.Flag or elementOptions.Name or "Textbox"

                ConfigManager:RegisterFlag(
                    flag,
                    elementOptions.Default or ""
                )

                local value = ConfigManager:GetFlag(
                    flag,
                    elementOptions.Default or ""
                )

                local Container = Create("Frame", {
                    Parent = Elements,
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundColor3 = COLORS.Secondary,
                    BorderSizePixel = 0
                })

                Corner(Container, 7)

                local Label = Create("TextLabel", {
                    Parent = Container,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(12, 0),
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = elementOptions.Name or "Textbox",
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local Input = Create("TextBox", {
                    Parent = Container,
                    Position = UDim2.new(0.45, 0, 0, 7),
                    Size = UDim2.new(0.55, -12, 0, 28),
                    BackgroundColor3 = COLORS.Tertiary,
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                    Font = Enum.Font.Gotham,
                    PlaceholderText = elementOptions.Placeholder or "",
                    PlaceholderColor3 = COLORS.Muted,
                    Text = tostring(value),
                    TextColor3 = COLORS.Text,
                    TextSize = 11
                })

                Corner(Input, 6)

                Padding(Input, 8, 8, 8, 8)

                Input.FocusLost:Connect(function()
                    value = Input.Text

                    ConfigManager:SetFlag(flag, value)

                    SafeCallback(elementOptions.Callback, value)
                end)

                return {
                    Set = function(_, text)
                        value = tostring(text)
                        Input.Text = value
                        ConfigManager:SetFlag(flag, value)
                        SafeCallback(elementOptions.Callback, value)
                    end,

                    Get = function()
                        return value
                    end
                }
            end

            --// Keybind
            function Section:CreateKeybind(elementOptions)
                elementOptions = elementOptions or {}

                local flag = elementOptions.Flag or elementOptions.Name or "Keybind"
                local default = elementOptions.Default or Enum.KeyCode.RightShift

                ConfigManager:RegisterFlag(flag, default.Name)

                local current = default
                local Listening = false

                local Container = Create("TextButton", {
                    Parent = Elements,
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundColor3 = COLORS.Secondary,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = ""
                })

                Corner(Container, 7)

                local Label = Create("TextLabel", {
                    Parent = Container,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(12, 0),
                    Size = UDim2.new(1, -100, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = elementOptions.Name or "Keybind",
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local Key = Create("TextLabel", {
                    Parent = Container,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(70, 24),
                    BackgroundColor3 = COLORS.Tertiary,
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamMedium,
                    Text = current.Name,
                    TextColor3 = COLORS.SubText,
                    TextSize = 10
                })

                Corner(Key, 6)

                Container.MouseButton1Click:Connect(function()
                    if Listening then
                        return
                    end

                    Listening = true
                    Key.Text = "..."

                    local connection

                    connection = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType ~= Enum.UserInputType.Keyboard then
                            return
                        end

                        current = input.KeyCode
                        Key.Text = current.Name
                        Listening = false

                        ConfigManager:SetFlag(flag, current.Name)

                        SafeCallback(
                            elementOptions.Callback,
                            current
                        )

                        connection:Disconnect()
                    end)
                end)

                return {
                    Set = function(_, key)
                        if typeof(key) == "EnumItem" then
                            current = key
                        elseif typeof(key) == "string" then
                            current = Enum.KeyCode[key] or current
                        end

                        Key.Text = current.Name
                        ConfigManager:SetFlag(flag, current.Name)
                    end,

                    Get = function()
                        return current
                    end
                }
            end

            return Section
        end

        if not windowObject.CurrentTab then
            task.defer(Select)
        end

        return Tab
    end

    --// Notification System
    function windowObject:Notify(notificationOptions)
        notificationOptions = notificationOptions or {}

        local Holder = ScreenGui:FindFirstChild("Notifications")

        if not Holder then
            Holder = Create("Frame", {
                Parent = ScreenGui,
                Name = "Notifications",
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -18, 1, -18),
                Size = UDim2.fromOffset(300, 400),
                BackgroundTransparency = 1
            })

            Create("UIListLayout", {
                Parent = Holder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 8)
            })
        end

        local Notification = Create("Frame", {
            Parent = Holder,
            Size = UDim2.fromOffset(280, 64),
            BackgroundColor3 = COLORS.Secondary,
            BorderSizePixel = 0
        })

        Corner(Notification, 8)
        Stroke(Notification)

        local Title = Create("TextLabel", {
            Parent = Notification,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 8),
            Size = UDim2.new(1, -24, 0, 18),
            Font = Enum.Font.GothamSemibold,
            Text = notificationOptions.Title or "Ryken",
            TextColor3 = COLORS.Text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local Message = Create("TextLabel", {
            Parent = Notification,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 28),
            Size = UDim2.new(1, -24, 0, 26),
            Font = Enum.Font.Gotham,
            Text = notificationOptions.Content or notificationOptions.Text or "",
            TextColor3 = COLORS.SubText,
            TextSize = 10,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })

        Notification.BackgroundTransparency = 1
        Title.TextTransparency = 1
        Message.TextTransparency = 1

        Tween(Notification, 0.2, {
            BackgroundTransparency = 0
        })

        Tween(Title, 0.2, {
            TextTransparency = 0
        })

        Tween(Message, 0.2, {
            TextTransparency = 0
        })

        task.delay(notificationOptions.Duration or 3, function()
            Tween(Notification, 0.2, {
                BackgroundTransparency = 1
            })

            Tween(Title, 0.2, {
                TextTransparency = 1
            })

            Tween(Message, 0.2, {
                TextTransparency = 1
            })

            task.wait(0.25)

            if Notification then
                Notification:Destroy()
            end
        end)

        return Notification
    end

    --// Config shortcuts
    function windowObject:SaveConfig(name)
        return ConfigManager:Save(name)
    end

    function windowObject:LoadConfig(name)
        return ConfigManager:Load(name)
    end

    function windowObject:DeleteConfig(name)
        return ConfigManager:Delete(name)
    end

    function windowObject:GetConfigs()
        return ConfigManager:List()
    end

    function windowObject:SetAutoLoad(name)
        return ConfigManager:SetAutoLoad(name)
    end

    --// Window controls
    function windowObject:Open()
        Window.Visible = true
        Bubble.Visible = false
    end

    function windowObject:Close()
        Window.Visible = false
        Bubble.Visible = false
    end

    function windowObject:Minimize()
        MinimizeWindow()
    end

    function windowObject:Restore()
        Restore()
    end

    --// Initial animation
    Window.Size = UDim2.fromOffset(0, 0)

    task.defer(function()
        Tween(Window, 0.3, {
            Size = windowObject.Size
        })
    end)

    return windowObject
end

--// Library-level config shortcuts
function Ryken:SaveConfig(name)
    return ConfigManager:Save(name)
end

function Ryken:LoadConfig(name)
    return ConfigManager:Load(name)
end

function Ryken:DeleteConfig(name)
    return ConfigManager:Delete(name)
end

function Ryken:GetConfigs()
    return ConfigManager:List()
end

function Ryken:SetAutoLoad(name)
    return ConfigManager:SetAutoLoad(name)
end

function Ryken:Notify(options)
    if self.Window and self.Window.Notify then
        return self.Window:Notify(options)
    end
end

return Ryken
