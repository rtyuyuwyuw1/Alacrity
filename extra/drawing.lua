local DrawingCache = {}
local DrawingObjects = {}

local Fonts = {
    [0] = Enum.Font.Arial,
    [1] = Enum.Font.BuilderSans,
    [2] = Enum.Font.Gotham,
    [3] = Enum.Font.RobotoMono
}

local UI = Instance.new("ScreenGui")
UI.Name = "DrawingLib"
UI.DisplayOrder = 999999
UI.IgnoreGuiInset = true
UI.ResetOnSpawn = false
UI.Parent = gethui()

local TextService = game:GetService("TextService")

local Drawing = {
    Fonts = {
        UI = 0,
        System = 1,
        Plex = 2,
        Monospace = 3
    }
}

local function createBaseFrame(parent)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.fromOffset(0, 0)
    frame.Position = UDim2.fromOffset(0, 0)
    frame.Parent = parent
    return frame
end

local function createLineFrame(parent)
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = Color3.new(1, 1, 1)
    line.BorderSizePixel = 0
    line.Parent = parent
    return line
end

local function updateLineFrame(frame, p1, p2, thickness, color, transparency, offsetX, offsetY)
    local dx = p2.X - p1.X
    local dy = p2.Y - p1.Y
    local length = math.sqrt(dx * dx + dy * dy)

    frame.Size = UDim2.fromOffset(length, thickness)
    frame.Position = UDim2.fromOffset(
        (p1.X + p2.X) / 2 - (offsetX or 0),
        (p1.Y + p2.Y) / 2 - (offsetY or 0)
    )
    frame.Rotation = math.deg(math.atan2(dy, dx))
    frame.BackgroundColor3 = color
    frame.BackgroundTransparency = 1 - transparency
end

Drawing.new = function(drawingType)
    if type(drawingType) ~= "string" then
        error("Drawing.new: argument must be a string, got " .. type(drawingType), 2)
    end

    local validTypes = {
        Line = true,
        Square = true,
        Rectangle = true,
        Circle = true,
        Text = true,
        Image = true,
        Triangle = true,
        Quad = true
    }

    if not validTypes[drawingType] then
        error("Drawing.new: invalid drawing type '" .. drawingType .. "'", 2)
    end

    local root = createBaseFrame(UI)
    local removed = false
    local properties = {
        Visible = true,
        Color = Color3.new(1, 1, 1),
        Transparency = 1,
        ZIndex = 1
    }

    local self = newproxy(true)
    local mt = getmetatable(self)

    local function markRemoved()
        if removed then return end
        removed = true
        if root and root.Parent then
            root:Destroy()
        end
        for i, obj in ipairs(DrawingCache) do
            if obj.proxy == self then
                table.remove(DrawingCache, i)
                break
            end
        end
        DrawingObjects[self] = nil
    end

    mt.__index = function(_, key)
        if key == "__OBJECT_EXISTS" then
            return not removed
        end
        if key == "Remove" or key == "Destroy" then
            return markRemoved
        end
        return properties[key]
    end

    mt.__newindex = function(_, key, value)
        if removed then return end
        if key == "__OBJECT_EXISTS" then return end
        properties[key] = value

        if key == "Visible" then
            root.Visible = value
        elseif key == "ZIndex" then
            root.ZIndex = value
        end
    end

    mt.__tostring = function()
        return "Drawing"
    end

    mt.__metatable = "The metatable is locked"

    table.insert(DrawingCache, {proxy = self, instance = root})
    DrawingObjects[self] = true

    if drawingType == "Line" then
        local line = createLineFrame(root)
        properties.From = Vector2.zero
        properties.To = Vector2.zero
        properties.Thickness = 1

        local function update()
            if removed then return end
            updateLineFrame(
                line,
                properties.From,
                properties.To,
                properties.Thickness,
                properties.Color,
                properties.Transparency,
                0,
                0
            )
        end

        local oldNewindex = mt.__newindex
        mt.__newindex = function(t, k, v)
            oldNewindex(t, k, v)
            if k == "From" or k == "To" or k == "Thickness" or k == "Color" or k == "Transparency" then
                update()
            end
        end

        update()

    elseif drawingType == "Square" or drawingType == "Rectangle" then
        local lineTop = createLineFrame(root)
        local lineBottom = createLineFrame(root)
        local lineLeft = createLineFrame(root)
        local lineRight = createLineFrame(root)
        local fill = createBaseFrame(root)
        fill.BackgroundColor3 = properties.Color
        fill.BackgroundTransparency = 1
        fill.ZIndex = root.ZIndex

        properties.Size = Vector2.zero
        properties.Position = Vector2.zero
        properties.Filled = false
        properties.Thickness = 1

        local function update()
            if removed then return end
            local pos = properties.Position
            local size = properties.Size
            local thickness = properties.Thickness
            local color = properties.Color
            local transparency = properties.Transparency

            root.Position = UDim2.fromOffset(pos.X, pos.Y)
            root.Size = UDim2.fromOffset(size.X, size.Y)

            if properties.Filled then
                fill.Visible = true
                fill.Position = UDim2.fromOffset(0, 0)
                fill.Size = UDim2.fromOffset(size.X, size.Y)
                fill.BackgroundColor3 = color
                fill.BackgroundTransparency = 1 - transparency
                lineTop.Visible = false
                lineBottom.Visible = false
                lineLeft.Visible = false
                lineRight.Visible = false
            else
                fill.Visible = false
                lineTop.Visible = true
                lineBottom.Visible = true
                lineLeft.Visible = true
                lineRight.Visible = true

                local p1 = Vector2.new(0, 0)
                local p2 = Vector2.new(size.X, 0)
                local p3 = Vector2.new(size.X, size.Y)
                local p4 = Vector2.new(0, size.Y)

                updateLineFrame(lineTop, p1, p2, thickness, color, transparency, 0, 0)
                updateLineFrame(lineBottom, p4, p3, thickness, color, transparency, 0, 0)
                updateLineFrame(lineLeft, p1, p4, thickness, color, transparency, 0, 0)
                updateLineFrame(lineRight, p2, p3, thickness, color, transparency, 0, 0)
            end
        end

        local oldNewindex = mt.__newindex
        mt.__newindex = function(t, k, v)
            oldNewindex(t, k, v)
            if k == "Size" or k == "Position" or k == "Filled" or k == "Thickness" or k == "Color" or k == "Transparency" then
                update()
            end
        end

        update()

    elseif drawingType == "Circle" then
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = properties.Color
        fill.BackgroundTransparency = 1
        fill.BorderSizePixel = 0
        fill.Parent = root

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = fill

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Color = properties.Color
        stroke.Transparency = 1
        stroke.Parent = fill

        properties.Radius = 50
        properties.Position = Vector2.zero
        properties.Filled = false
        properties.Thickness = 1
        properties.NumSides = 64

        local function update()
            if removed then return end
            local diameter = properties.Radius * 2
            root.Size = UDim2.fromOffset(diameter, diameter)
            root.Position = UDim2.fromOffset(
                properties.Position.X - properties.Radius,
                properties.Position.Y - properties.Radius
            )

            fill.Size = UDim2.fromOffset(diameter, diameter)
            fill.Position = UDim2.fromOffset(0, 0)

            if properties.Filled then
                fill.BackgroundColor3 = properties.Color
                fill.BackgroundTransparency = 1 - properties.Transparency
                stroke.Enabled = false
            else
                fill.BackgroundTransparency = 1
                stroke.Enabled = true
                stroke.Color = properties.Color
                stroke.Thickness = properties.Thickness
                stroke.Transparency = 1 - properties.Transparency
            end
        end

        local oldNewindex = mt.__newindex
        mt.__newindex = function(t, k, v)
            oldNewindex(t, k, v)
            if k == "Radius" or k == "Position" or k == "Filled" or k == "Thickness" or k == "Color" or k == "Transparency" then
                update()
            end
        end

        update()

    elseif drawingType == "Triangle" then
        local line1 = createLineFrame(root)
        local line2 = createLineFrame(root)
        local line3 = createLineFrame(root)

        properties.PointA = Vector2.zero
        properties.PointB = Vector2.new(50, 100)
        properties.PointC = Vector2.new(100, 0)
        properties.Filled = false
        properties.Thickness = 1

        local function update()
            if removed then return end
            local pA, pB, pC = properties.PointA, properties.PointB, properties.PointC
            local minX = math.min(pA.X, pB.X, pC.X)
            local minY = math.min(pA.Y, pB.Y, pC.Y)
            local maxX = math.max(pA.X, pB.X, pC.X)
            local maxY = math.max(pA.Y, pB.Y, pC.Y)

            root.Position = UDim2.fromOffset(minX, minY)
            root.Size = UDim2.fromOffset(maxX - minX, maxY - minY)

            if properties.Filled then
                line1.Visible = false
                line2.Visible = false
                line3.Visible = false
                root.BackgroundColor3 = properties.Color
                root.BackgroundTransparency = 1 - properties.Transparency
            else
                line1.Visible = true
                line2.Visible = true
                line3.Visible = true
                root.BackgroundTransparency = 1

                updateLineFrame(line1, pA, pB, properties.Thickness, properties.Color, properties.Transparency, minX, minY)
                updateLineFrame(line2, pB, pC, properties.Thickness, properties.Color, properties.Transparency, minX, minY)
                updateLineFrame(line3, pC, pA, properties.Thickness, properties.Color, properties.Transparency, minX, minY)
            end
        end

        local oldNewindex = mt.__newindex
        mt.__newindex = function(t, k, v)
            oldNewindex(t, k, v)
            if k == "PointA" or k == "PointB" or k == "PointC" or k == "Filled" or k == "Thickness" or k == "Color" or k == "Transparency" then
                update()
            end
        end

        update()

    elseif drawingType == "Quad" then
        local line1 = createLineFrame(root)
        local line2 = createLineFrame(root)
        local line3 = createLineFrame(root)
        local line4 = createLineFrame(root)

        properties.PointA = Vector2.zero
        properties.PointB = Vector2.new(100, 0)
        properties.PointC = Vector2.new(100, 100)
        properties.PointD = Vector2.new(0, 100)
        properties.Filled = false
        properties.Thickness = 1

        local function update()
            if removed then return end
            local pA, pB, pC, pD = properties.PointA, properties.PointB, properties.PointC, properties.PointD
            local minX = math.min(pA.X, pB.X, pC.X, pD.X)
            local minY = math.min(pA.Y, pB.Y, pC.Y, pD.Y)
            local maxX = math.max(pA.X, pB.X, pC.X, pD.X)
            local maxY = math.max(pA.Y, pB.Y, pC.Y, pD.Y)

            root.Position = UDim2.fromOffset(minX, minY)
            root.Size = UDim2.fromOffset(maxX - minX, maxY - minY)

            if properties.Filled then
                line1.Visible = false
                line2.Visible = false
                line3.Visible = false
                line4.Visible = false
                root.BackgroundColor3 = properties.Color
                root.BackgroundTransparency = 1 - properties.Transparency
            else
                line1.Visible = true
                line2.Visible = true
                line3.Visible = true
                line4.Visible = true
                root.BackgroundTransparency = 1

                updateLineFrame(line1, pA, pB, properties.Thickness, properties.Color, properties.Transparency, minX, minY)
                updateLineFrame(line2, pB, pC, properties.Thickness, properties.Color, properties.Transparency, minX, minY)
                updateLineFrame(line3, pC, pD, properties.Thickness, properties.Color, properties.Transparency, minX, minY)
                updateLineFrame(line4, pD, pA, properties.Thickness, properties.Color, properties.Transparency, minX, minY)
            end
        end

        local oldNewindex = mt.__newindex
        mt.__newindex = function(t, k, v)
            oldNewindex(t, k, v)
            if k == "PointA" or k == "PointB" or k == "PointC" or k == "PointD" or k == "Filled" or k == "Thickness" or k == "Color" or k == "Transparency" then
                update()
            end
        end

        update()

    elseif drawingType == "Text" then
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.TextColor3 = properties.Color
        label.TextSize = 13
        label.Font = Enum.Font.Code
        label.Text = ""
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.TextScaled = false
        label.RichText = false
        label.AutomaticSize = Enum.AutomaticSize.None
        label.Size = UDim2.fromOffset(0, 0)
        label.Position = UDim2.fromOffset(0, 0)
        label.Parent = root

        properties.Text = ""
        properties.Size = 13
        properties.Center = false
        properties.Outline = false
        properties.OutlineColor = Color3.new(0, 0, 0)
        properties.Position = Vector2.zero
        properties.Font = 2
        properties.TextBounds = Vector2.zero

        local function updateText()
            if removed then return end
            local text = tostring(properties.Text)
            local fontSize = properties.Size
            local font = Fonts[properties.Font] or Enum.Font.Code

            label.Text = text
            label.TextSize = fontSize
            label.Font = font
            label.TextColor3 = properties.Color
            label.TextTransparency = 1 - properties.Transparency
            label.Position = UDim2.fromOffset(properties.Position.X, properties.Position.Y)

            if properties.Center then
                label.TextXAlignment = Enum.TextXAlignment.Center
                label.TextYAlignment = Enum.TextYAlignment.Center
            else
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextYAlignment = Enum.TextYAlignment.Top
            end

            if properties.Outline then
                label.TextStrokeTransparency = 0
                label.TextStrokeColor3 = properties.OutlineColor
            else
                label.TextStrokeTransparency = 1
            end

            local bounds = TextService:GetTextSize(
                text,
                fontSize,
                font,
                Vector2.new(100000, 100000)
            )
            properties.TextBounds = bounds
            label.Size = UDim2.fromOffset(bounds.X, bounds.Y)
        end

        local oldNewindex = mt.__newindex
        mt.__newindex = function(t, k, v)
            oldNewindex(t, k, v)
            if k ~= "TextBounds" then
                updateText()
            end
        end

        updateText()

    elseif drawingType == "Image" then
        local image = Instance.new("ImageLabel")
        image.BackgroundTransparency = 1
        image.BorderSizePixel = 0
        image.Parent = root

        properties.Data = ""
        properties.Size = Vector2.zero
        properties.Position = Vector2.zero
        properties.Rounding = 0

        local function updateImage()
            if removed then return end
            image.Image = properties.Data
            root.Size = UDim2.fromOffset(properties.Size.X, properties.Size.Y)
            root.Position = UDim2.fromOffset(properties.Position.X, properties.Position.Y)
            image.Size = UDim2.fromOffset(properties.Size.X, properties.Size.Y)
            image.Position = UDim2.fromOffset(0, 0)
            image.ImageTransparency = 1 - properties.Transparency
            image.ImageColor3 = properties.Color
        end

        local oldNewindex = mt.__newindex
        mt.__newindex = function(t, k, v)
            oldNewindex(t, k, v)
            if k == "Data" or k == "Size" or k == "Position" or k == "Transparency" or k == "Color" then
                updateImage()
            end
        end

        updateImage()
    end

    return self
end

getgenv().Drawing = Drawing
if getgenv ~= nil then
    getgenv().Drawing = Drawing
end

pcall(function()
    _G.Drawing = Drawing
end)

if setglobal then
    pcall(setglobal, "Drawing", Drawing)
end

getgenv().isrenderobj = function(obj)
    if type(obj) ~= "userdata" then
        return false
    end

    local success, exists = pcall(function()
        return obj.__OBJECT_EXISTS
    end)

    return success and exists == true
end

getgenv().cleardrawcache = function()
    for i = #DrawingCache, 1, -1 do
        local data = DrawingCache[i]
        if data and data.proxy then
            pcall(function()
                data.proxy:Remove()
            end)
        end
    end

    DrawingCache = {}
    DrawingObjects = {}
end

getgenv().getrenderproperty = function(obj, prop)
    if not getgenv().isrenderobj(obj) then
        return nil
    end
    return obj[prop]
end

getgenv().setrenderproperty = function(obj, prop, value)
    if not getgenv().isrenderobj(obj) then
        return
    end
    obj[prop] = value
end
