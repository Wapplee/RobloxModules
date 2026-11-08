-- local UIModule = loadstring(game:HttpGet('https://github.com/Wapplee/RobloxModules/blob/main/UI.lua?t='..tick()))()
local http = game:GetService("HttpService")
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local coreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")

local Player = game:GetService("Players").LocalPlayer
local mouse = Player:GetMouse()

local s = loadstring(game:HttpGet('https://glot.io/snippets/gnvhn0tvn3/raw/main.lua'))()
local templateui = s.Deserialize(s.GetSnippetData('hkw5kyt9hc'))[1]

-- [[ Functions ]] --
local function track(object,...)
	local tab = {...}
	local fix = function()
		for _,v in tab do
			pcall(v.Disconnect,v)
		end
	end
	object.Destroying:Once(fix)
	object.AncestryChanged:Once(function(f)
		if f then return end
		fix()
	end)
end
local function simplelerp(part, proprty, tweeninfo)
	tweeninfo = tweeninfo or TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0)
	local tween = ts:Create(part, tweeninfo, proprty)
	tween:Play()
	return tween
end
local fastTI = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local function map(val, min1, max1, min2, max2)
	return min2 + (max2 - min2) * ((val - min1) / (max1 - min1))
end

local function round(val, by)
	by = by or 1
	return math.round(val / by) * by
end

local function fixFP(val)
	local str = tostring(val)
	local cleaned = str:gsub("(.-%.%d-)00000000.+", "%1")
	if cleaned:find("%.") then
		cleaned = cleaned:gsub("0+$", ""):gsub("%.$", "")
	end
	return string.format("%.14g", val)
end

-- [[ UI HELPERS ]] --

local function makeMT(targetTable, proxyMode)
	local mt = {}
	local object = proxyMode and newproxy(true) or targetTable
	if proxyMode then mt = getmetatable(object) end
	mt.__index = targetTable
	if not proxyMode then setmetatable(targetTable, mt) end
	return mt, object
end

-- FIX: now returns c1, c2 so callers can track and disconnect
local function makeDraggable(topBar, target)
	local dragging, offset
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			offset = target.AbsolutePosition - uis:GetMouseLocation()
		end
	end)
	local c1 = uis.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = uis:GetMouseLocation()
			simplelerp(target, {Position = UDim2.new(0, mousePos.X + offset.X, 0, mousePos.Y + offset.Y)}, fastTI)
		end
	end)
	local c2 = uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	return c1, c2
end

local function makeSignalProxy(eleData, signal, onValue, ele)
	local mt, proxy = makeMT(eleData, true)
	mt.__index = function(_, i)
		if eleData[i] ~= nil then return eleData[i] end
		local m = signal[i]
		if typeof(m) == "function" then return function(_, ...) return m(signal, ...) end end
		return m
	end
	mt.__newindex = function(_, k, v)
		if k == "Value" then onValue(v)
		elseif k == "Name" then
			if ele then ele.Label.Text = v ele.Name = v end
			rawset(eleData, k, v)
		else rawset(eleData, k, v) end
	end
	eleData.Proxy = proxy
	eleData.Raw = eleData
	return proxy
end

-- [[ ELEMENT CREATORS ]] --
local function AddAction(catObj, actionName, Func)
	actionName = actionName or "Unnamed Action"
	local uimod = catObj.UI
	local ele = uimod.Templates.Action:Clone()
	ele.Parent = catObj.Instance

	local event = Instance.new("BindableEvent")
	local signal = event.Event
	local eleData = { Instance = ele, Event = signal }

	if Func then event.Event:Connect(Func) end

	local function updateVisuals(CLICKED)
		local on = eleData.Value
		if CLICKED then
			simplelerp(ele.Label, {TextColor3 = Color3.fromRGB(149,99,149),BackgroundColor3 = Color3.fromRGB(72, 60, 72)},fastTI)
				.Completed:Wait(function()
					simplelerp(ele.Label, {TextColor3 = Color3.fromRGB(85,68,85),BackgroundColor3 = Color3.fromRGB(56, 47, 56)})
				end)
		end
	end


	ele.MouseButton1Down:Connect(function()event:Fire()end)

	local proxy = makeSignalProxy(eleData, signal, tick, ele)
	proxy.Name = actionName
	updateVisuals()
	return proxy
end

local function AddSelection(catObj, selectionName, Values, defaultValue)
	defaultValue = defaultValue or Values[1]

	selectionName = selectionName or "Unnamed Selection"
	local uimod = catObj.UI
	local ele = uimod.Templates.Selection:Clone()
	ele.Parent = catObj.Instance

	local optionsList = ele.OptionsList
	local optionFrame = ele.CurrentOptionFrame
	optionFrame.Parent = nil
	optionsList.Parent = nil
	optionsList.Visible = false

	local event = Instance.new("BindableEvent")
	local signal = event.Event
	local eleData = { Instance = ele, DefaultValue = defaultValue, Value = defaultValue, Event = signal }

	local function toggleList(forceClose)
		if optionsList.Visible == true or forceClose then
			optionsList.Parent = nil
			optionsList.Visible = false
		else
			optionsList.Parent = uimod.ScreenGui
			optionsList.Visible = true
			repeat game:GetService("RunService").RenderStepped:Wait()
				local currentoption = ele:FindFirstChild("CurrentOptionFrame")
				if not currentoption then continue end
				local abspos,abssize = currentoption.AbsolutePosition,currentoption.AbsoluteSize

				optionsList.Position = UDim2.new(0,abspos.X,0,abspos.Y+abssize.Y+5)
				optionsList.Size = UDim2.new(0,abssize.X,0,math.min(300,optionFrame.Size.Y.Offset*(#Values-1))+5)
			until optionsList.Visible == false
				or optionsList.AbsolutePosition.Y > uimod.ScreenGui.AbsolutePosition.Y+uimod.ScreenGui.AbsoluteSize.Y-optionsList.AbsoluteSize.Y
				or uimod.SelectedTab ~= catObj.Tab.Raw
			toggleList(true)
		end
	end

	local setValue
	local function updateVisuals()-- local UI = loadstring(game:HttpGet('https://glot.io/snippets/hhhuunsw0j/raw/UI.lua'))()
		local on = eleData.Value

		local currentoption = ele:FindFirstChild("CurrentOptionFrame")
		if currentoption then
			currentoption:Destroy()
		end
		for _,v in optionsList:GetChildren() do
			if v:IsA("Frame") then
				v:Destroy()
			end
		end
		
		for _,v in Values do
			local option = optionFrame:Clone()
			option.Option.Text = v
			if v ~= eleData.Value then
				option.Parent = optionsList
				option.Option.MouseButton1Down:Connect(function()
					setValue(v)
					toggleList()
				end)
				option.BackgroundColor3 = Color3.fromRGB(22, 18, 22)
				option.PlusSymbol:Destroy()
			else
				option.Parent = ele
				option.Option.MouseButton1Down:Connect(function()
					toggleList()
				end)
			end
		end

		--simplelerp(ele.Button.ButtonChecked, { BackgroundColor3 = on and Color3.fromRGB(149,99,149) or Color3.fromRGB(30,25,30) })
		--simplelerp(ele.Label, { TextColor3 = on and Color3.fromRGB(149,99,149) or Color3.fromRGB(85,68,85) })
	end

	function setValue(newVal) eleData.Value = newVal event:Fire(newVal) updateVisuals() end

	local proxy = makeSignalProxy(eleData, signal, setValue, ele)
	proxy.Name = selectionName
	updateVisuals()
	return proxy
end

local function AddBind(catObj, bindName, defaultValue, funcDown, funcUp)
	defaultValue = defaultValue or Enum.KeyCode.M

	bindName = bindName or "Unnamed Bind"
	local ele = catObj.UI.Templates.Bind:Clone()
	ele.Parent = catObj.Instance
	local keyLabel = ele.Key.Label
	local event = Instance.new("BindableEvent")
	local eleData = {
		Instance = ele, Event = event.Event,
		DefaultValue = defaultValue,
		Value = defaultValue,
		FuncDown = funcDown or function() end,
		FuncUp = funcUp or function() end,
	}
	local binding = false
	local function updateVisuals()
		keyLabel.Text = eleData.Value and tostring(eleData.Value):match("(%a*)$") or "None"
		simplelerp(ele.Label, { TextColor3 = binding and Color3.fromRGB(149,99,149) or Color3.fromRGB(85,68,85) })
	end
	local function setValue(v) eleData.Value = v event:Fire(v) updateVisuals() end

	track(ele,
		uis.InputBegan:Connect(function(inp, proc) if not proc and inp.KeyCode == eleData.Value and not binding then eleData.FuncDown() end end),
		uis.InputEnded:Connect(function(inp, proc) if not proc and inp.KeyCode == eleData.Value and not binding then eleData.FuncUp() end end)
	)

	ele.MouseButton1Down:Connect(function()
		if binding then return end
		binding = true updateVisuals() keyLabel.Text = "..."
		local conn conn = uis.InputBegan:Connect(function(inp)
			if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
			setValue(if inp.KeyCode ~= Enum.KeyCode.Escape then inp.KeyCode else nil)
			conn:Disconnect()
			task.defer(function() binding = false updateVisuals()  end)
		end)
	end)

	local proxy = makeSignalProxy(eleData, event.Event, setValue, ele)
	proxy.Name = bindName updateVisuals()
	return proxy
end

local function AddColor(catObj, colorName, defaultValue)
	defaultValue = defaultValue or Color3.new(1,1,1)

	colorName = colorName or "Unnamed Color"
	local uimod = catObj.UI
	local ele = uimod.Templates.Color:Clone()
	ele.Parent = catObj.Instance
	local colorpreview = ele.Picker.Color

	local event = Instance.new("BindableEvent")
	local signal = event.Event
	local eleData = { Instance = ele, DefaultValue = defaultValue, Value = defaultValue, Event = signal }
	local H, S, V = eleData.Value:ToHSV()

	local function updateVisuals() simplelerp(colorpreview, { BackgroundColor3 = eleData.Value }, fastTI) end
	local function setValue(v) eleData.Value = v event:Fire(v) updateVisuals() end

	local function onDrag(target, cb)
		local dragging = false
		local c1 = target.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true cb() end
		end)
		local c2 = uis.InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then cb() end
		end)
		local c3 = uis.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
		return c1, c2, c3
	end

	local openColorPicker = nil

	ele.MouseButton1Down:Connect(function()
		if openColorPicker then return end
		openColorPicker = uimod.Templates.ColorPickerUI:Clone()
		openColorPicker.Parent = uimod.ScreenGui
		openColorPicker.Name = "Color Picker - " .. ele.Name
		openColorPicker.Visible = true

		local pos = colorpreview.AbsolutePosition
		openColorPicker.Position = UDim2.new(1.5, 0, -1.5, 0)
		simplelerp(openColorPicker, { Position = UDim2.new(0, 30+pos.X, 0, pos.Y) }, fastTI)

		local cpFrame = openColorPicker.Frame
		local cpTitle = cpFrame.Title
		cpTitle.Label.Text = openColorPicker.Name

		-- FIX: track makeDraggable connections so they disconnect on picker close
		track(openColorPicker,makeDraggable(cpTitle.Label, openColorPicker))

		cpTitle.Exit.MouseButton1Down:Connect(function()
			local ocp = openColorPicker openColorPicker = nil
			simplelerp(ocp, { Position = UDim2.new(1.5, 0, -1.5, 0) },
			TweenInfo.new(.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)).Completed:Wait()
			ocp:Destroy()
		end)

		local wheel = cpFrame.Frame.WheelOutline.Wheel
		local preview = cpFrame.Frame.Preview

		local sliders = {
			H = { cpFrame.Frame.Hue,        360, function(a) H = a end },
			S = { cpFrame.Frame.Saturation, 100, function(a) S = a end },
			V = { cpFrame.Frame.Value,      100, function(a) V = a wheel.ImageColor3 = Color3.new(V,V,V) end },
		}

		local function applyHSV()
			setValue(Color3.fromHSV(H, S, V))
			simplelerp(preview, { BackgroundColor3 = eleData.Value }, fastTI)
			for key, def in pairs(sliders) do
				if key == "H" then continue end
				for _, color in def[1].Colors:GetChildren() do
					if not color:IsA("Frame") then continue end
					local t = tonumber(color.Name) / 100
					color.BackgroundColor3 = key == "S" and Color3.fromHSV(H, t, V) or Color3.fromHSV(H, S, t)
				end
			end
			updateVisuals()
		end
		applyHSV()

		local function updateCursor()
			local angle = (H * 2 * math.pi) - (math.pi / 2)
			wheel.Cursor.Position = UDim2.new(math.cos(angle)*S/2*.98+.5, 0, math.sin(angle)*S/2*.98+.5, 0)
		end

		for key, def in pairs(sliders) do
			local frame, hi, setter = def[1], def[2], def[3]
			local sliderEl, valBox = frame.Slider, frame.Value

			local function changePos(alpha)
				if not alpha then
					local y1 = frame.AbsolutePosition.Y
					alpha = map(math.clamp(mouse.Y, y1, y1 + frame.AbsoluteSize.Y), y1, y1 + frame.AbsoluteSize.Y, 0, 1)
				end
				simplelerp(sliderEl, { Position = UDim2.new(.5, 0, alpha, 0) }, fastTI)
				setter(alpha)
				valBox.Text = tostring(math.floor(alpha * hi))
				if key ~= "V" then updateCursor() end
				applyHSV()
			end
			def.changePos = changePos

			track(openColorPicker,valBox.FocusLost:Connect(function()
				local n = tonumber(valBox.Text)
				if n then changePos(math.clamp(n, 0, hi) / hi) end
			end))
			track(openColorPicker,onDrag(frame, changePos))
			changePos((key == "H" and H or (key == "S" and S or V)))
		end

		track(openColorPicker,onDrag(wheel.Parent, function()
			local m = uis:GetMouseLocation() - GuiService:GetGuiInset()
			local center = wheel.AbsolutePosition + wheel.AbsoluteSize/2
			local radius = wheel.AbsoluteSize.X/2 * .98
			local offset = m - center
			local dist = math.min(offset.Magnitude, radius)
			offset = offset.Unit * dist
			wheel.Cursor.Position = UDim2.new(.5, offset.X, .5, offset.Y)
			local angle = math.atan2(offset.Y, offset.X)
			sliders.H.changePos(((angle + math.pi) / (2*math.pi) + 3/4) % 1)
			sliders.S.changePos(map(dist, 0, radius, 0, 1))
		end))
	end)

	local line = Drawing.new("Line") line.Visible = false line.Thickness = 1
	track(ele,game:GetService("RunService").RenderStepped:Connect(function()
		if not openColorPicker or catObj.UI.SelectedTab ~= catObj.Tab.Raw then line.Visible = false return end
		line.Visible = true
		local title = openColorPicker.Frame.Title
		local p1 = colorpreview.AbsolutePosition + GuiService:GetGuiInset()
		local p2 = title.AbsolutePosition + GuiService:GetGuiInset()
		line.From = p1 + colorpreview.AbsoluteSize/2
		line.To = p2 + title.AbsoluteSize * Vector2.new(p1.X > p2.X and 1 or 0, .5)
		line.Color = eleData.Value
	end))
	task.delay(40, function() line:Destroy() end)

	local proxy = makeSignalProxy(eleData, signal, function(v) setValue(v) H,S,V = v:ToHSV() end, ele)
	proxy.Name = colorName
	updateVisuals()
	return proxy
end

local function AddSlider(catObj, sliderName, defaultValue, min, max, roundTo)
	defaultValue = defaultValue or (min+max)/2

	sliderName = sliderName or "Unnamed Slider"
	local uimod = catObj.UI
	local ele = uimod.Templates.Slider:Clone()
	ele.Parent = catObj.Instance
	local sliderFrame = ele.SliderFrame
	local slider = sliderFrame.ProgressSlider

	local event = Instance.new("BindableEvent")
	local signal = event.Event
	local eleData = { Instance = ele, DefaultValue = defaultValue, Value = defaultValue, Event = signal }

	local function updateVisuals()
		if not sliderFrame:IsDescendantOf(game) then return end
		sliderFrame.Progress.Text = `{fixFP(round(eleData.Value or defaultValue, roundTo or .01))}/{fixFP(round(max, roundTo or .01))}`
		simplelerp(slider, { Size = UDim2.new(map(math.clamp(eleData.Value or defaultValue,min,max), min, max, 0, 1), 0, 1, 0) })
	end

	local function setValue(newVal) eleData.Value = newVal event:Fire(newVal) updateVisuals() end

	local function changePos()
		local x1 = sliderFrame.AbsolutePosition.X
		local alpha = map(math.clamp(mouse.X, x1, x1 + sliderFrame.AbsoluteSize.X), x1, x1 + sliderFrame.AbsoluteSize.X, min, max)
		setValue(roundTo and round(alpha, roundTo) or alpha)
	end

	local dragging = false
	ele.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			changePos()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			local prog = sliderFrame.Progress
			local manual = prog.Manual
			dragging = false
			prog.TextTransparency = 1
			manual.Visible = true
			manual.Text = tostring(eleData.Value)
			manual:CaptureFocus()
			local conn = manual.Changed:Connect(function(t)
				if t == "Text" then setValue(tonumber(manual.Text)) end
			end)
			manual.FocusLost:Wait()
			conn:Disconnect()
			manual.Visible = false
			prog.TextTransparency = 0
			updateVisuals()
		end
	end)

	track(ele,
		uis.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then changePos() end
		end),
		uis.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
	)

	local proxy = makeSignalProxy(eleData, signal, setValue, ele)
	proxy.Name = sliderName
	updateVisuals()
	return proxy
end

local function AddToggle(catObj, toggleName, defaultValue)
	defaultValue = defaultValue or false

	toggleName = toggleName or "Unnamed Toggle"
	local uimod = catObj.UI
	local ele = uimod.Templates.Toggle:Clone()
	ele.Parent = catObj.Instance

	local event = Instance.new("BindableEvent")
	local signal = event.Event
	local eleData = { Instance = ele, DefaultValue = defaultValue, Value = defaultValue, Event = signal }

	local function updateVisuals()
		local on = eleData.Value
		simplelerp(ele.Button.ButtonChecked, { BackgroundColor3 = on and Color3.fromRGB(149,99,149) or Color3.fromRGB(30,25,30) })
		simplelerp(ele.Label, { TextColor3 = on and Color3.fromRGB(149,99,149) or Color3.fromRGB(85,68,85) })
	end

	local function setValue(newVal) eleData.Value = newVal event:Fire(newVal) updateVisuals() end

	ele.MouseButton1Down:Connect(function() setValue(not eleData.Value) end)

	local proxy = makeSignalProxy(eleData, signal, setValue, ele)
	proxy.Name = toggleName
	updateVisuals()
	return proxy
end

local function AddCategory(tabObj, catName)
	catName = catName or "Unnamed Category"
	local targetList = (tabObj.List1.AbsoluteSize.Y <= tabObj.List2.AbsoluteSize.Y) and tabObj.List1 or tabObj.List2
	local cat = tabObj.UI.Templates.Category:Clone()
	cat.Parent = targetList

	local catObj = {
		UI = tabObj.UI,
		Tab = tabObj,
		Instance = cat,
		AddToggle = AddToggle,
		AddSlider = AddSlider,
		AddColor = AddColor,

		AddBind = AddBind,
		AddAction = AddAction,
		AddSelection = AddSelection,
	}

	local mt, proxy = makeMT(catObj, true)
	mt.__newindex = function(_, k, v)
		rawset(catObj, k, v)
		if k == "Name" then cat.Title.Text = v cat.Name = v end
	end
	proxy.Name = catName
	catObj.Proxy = proxy
	catObj.Raw = catObj
	return proxy
end

local function switchTab(tabObj)
	local uimod = tabObj.UI
	local Settings = uimod.Settings
	local currentSave = Settings:FindFirstChildOfClass("Folder")
	if currentSave then currentSave.Parent = uimod.SavedFolder end

	for _, v in uimod.Tabs do
		local active = v == tabObj
		--v.TabLabel.BackgroundTransparency = active and .98 or 1
		v.TabLabel.FontFace = Font.new(v.TabLabel.FontFace.Family, active and Enum.FontWeight.Bold or Enum.FontWeight.Regular)
	end

	simplelerp(uimod.TabHighlighter,{Position = UDim2.new((1/#uimod.Tabs)*(table.find(uimod.Tabs,tabObj)-1),0,0,0)})

	uimod.SelectedTab = tabObj
	tabObj.Save.Parent = Settings
end

-- [[ MAIN MODULE ]] --

local module = {}

function module.new(name)
	local ui = templateui:Clone()
	local uiframe = ui.Base.Frame
	local Settings = uiframe.SettingsFrame.Main.Settings
	local savedFolder = Settings.Saved

	makeDraggable(uiframe.Titlebar, ui.Base) -- main titlebar, lives forever, no need to track
	uiframe.Titlebar.Title.Text = name or "Unnamed UI"

	local templates = {}
	templates.TabLabel = uiframe.TabSelection.Tabs.ListObject
	templates.Save = savedFolder.SaveTemplate
	templates.Category = savedFolder.SaveTemplate.List1.Category
	templates.ColorPickerUI = ui.ColorPickerUI
	templates.Toggle = savedFolder.SaveTemplate.List1.Category.Toggle
	templates.Color = savedFolder.SaveTemplate.List1.Category.Color
	templates.Action = savedFolder.SaveTemplate.List1.Category.Action
	templates.Bind = savedFolder.SaveTemplate.List1.Category.Bind
	templates.Slider = savedFolder.SaveTemplate.List1.Category.Slider
	templates.Selection = savedFolder.SaveTemplate.List1.Category.Selection
	for _, v in templates do v.Parent = nil end

	local uimod = {
		ScreenGui = ui,
		UIFrame = uiframe,
		Settings = Settings,
		Templates = templates,
		SavedFolder = savedFolder,
		Tabs = {},

		SelectedTab = nil,
		TabHighlighter = uiframe.TabSelection.Highlighter
	}

	do
		local target = ui.Base
		local scaleButton = ui.Base.Scale

		local dragging, offset
		scaleButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				offset = target.AbsoluteSize - uis:GetMouseLocation()
			end
		end)
		local c1 = uis.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local mousePos = uis:GetMouseLocation()
				simplelerp(target, {Size = UDim2.new(0, math.clamp(mousePos.X + offset.X,500,1500), 0,  math.clamp(mousePos.Y + offset.Y,100,1500))}, fastTI)
			end
		end)
		local c2 = uis.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
		track(target,c1,c2)
	end

	function uimod:AddTab(name, isDefault)
		name = name or "Unnamed Tab"
		local newSave = templates.Save:Clone()
		newSave.Name = name
		newSave.Parent = savedFolder

		local tabObj = {
			UI = uimod,
			Save = newSave,
			TabLabel = templates.TabLabel:Clone(),
			List1 = newSave.List1,
			List2 = newSave.List2,
			AddCategory = AddCategory,
		}

		tabObj.TabLabel.Parent = uiframe.TabSelection.Tabs
		tabObj.TabLabel.MouseButton1Down:Connect(function()
			if uimod.SelectedTab ~= tabObj then switchTab(tabObj) end
		end)

		local mt, proxy = makeMT(tabObj, true)
		mt.__newindex = function(_, k, v)
			rawset(tabObj, k, v)
			if k == "Name" then tabObj.TabLabel.Text = v end
		end
		proxy.Name = name
		tabObj.Proxy = proxy
		tabObj.Raw = tabObj

		table.insert(uimod.Tabs, tabObj)

		uimod.TabHighlighter.Size = UDim2.new(1/#uimod.Tabs, 0, 1, 0)
		if isDefault or #uimod.Tabs == 1 then task.defer(switchTab,tabObj) end
		return proxy
	end

	return uimod
end

-- [[ USAGE ]] --
--[[local lib = module.new("Test Name for Main")
lib.ScreenGui.Parent = coreGui

local home = lib:AddTab("Home")
local testtab = lib:AddTab("Tab2")

local cat = home:AddCategory("Combat")
local toggle = cat:AddToggle("Kill Aura")
toggle:Connect(print)
local slider = cat:AddSlider("Reach", _, 1, 50, .1)
slider:Connect(print)

local esp = home:AddCategory("ESP")
local color = esp:AddColor("Tracers Color", Color3.new(1, .3, .3))
color:Connect(print)

local speed = home:AddCategory("Movement")

local slider = speed:AddSlider("Walk Speed", _, .1, 300, .1)
slider:Connect(function(s)
	Character:SetAttribute("WalkSpeed", s)
end)

local slider = speed:AddSlider("Run Speed", _, .1, 300, .1)
slider:Connect(function(s)
	Character:SetAttribute("RunSpeed", s)
end)

local bind = speed:AddBind("Test Print", nil, function() print("Hello") end)
bind:Connect(function(s)
	print(s)
end)

local action = speed:AddAction("Test Action Print", function()print("Yay! Action!")end)
action:Connect(function()
	warn("Action 2!")
end)
task.delay(40, function() lib.ScreenGui:Destroy() end)

local action = speed:AddSelection("Test Warn", {1,2,3,4})
action:Connect(warn)
task.delay(40, function() lib.ScreenGui:Destroy() end)
--]]
--[=[

module.new(name : string) -> uimod
- .ScreenGui : ScreenGui    -- The main ScreenGui object in PlayerGui/CoreGui
- .SelectedTab : table     -- The currently active tab object
- .Tabs : table            -- An array containing all created tab objects

- uimod:AddTab(name : string, isDefault : bool?) -> tab
- - tab:AddCategory(name : string) -> category
- - - category:AddToggle(name : string, defaultValue : bool?) -> toggle
- - - category:AddSlider(name : string, defaultValue : number?, min : number, max : number, roundTo : number?) -> slider
- - - category:AddSelection(name : string, Values : table, defaultValue : any?) -> selection
- - - category:AddColor(name : string, defaultValue : Color3?) -> color
- - - category:AddBind(name : string, defaultKeyCode : Enum.KeyCode?, funcDown : function?, funcUp : function?) -> bind
- - - category:AddAction(name : string, Func : function?) -> action

-- [[ Object Properties & Methods ]] --
All UI Elements share:
.Name : string             -- The display text/label of the element
.Value : any               -- The current state/data (bool, number, Color3, etc.)
.DefaultValue : any        -- The default value it was already on.
.Instance : Instance       -- The physical UI object clone
.Event : RBXScriptSignal   -- Fired when Value or Name is updated
.Raw : table               -- The underlying data table
:Connect(function)         -- Shorthand for .Event:Connect()

--]=]
return module
