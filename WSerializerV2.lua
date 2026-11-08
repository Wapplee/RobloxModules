-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Wapplee/RobloxModules/refs/heads/main/WSerializerV2.lua?t="..tick()))()
local http = game:GetService("HttpService")
local hasHttpGet = pcall(function() return game.HttpGet end)

local Classes = (function()
	local http = game:GetService("HttpService")
	local hasHttpGet = pcall(function() return game.HttpGet end)
	local dumpUrl = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/API-Dump.txt"

	local dumpSource = if hasHttpGet then game:HttpGet(dumpUrl) else http:GetAsync(dumpUrl)
	local dumpLines = dumpSource:split("\n")

	local Classes = {}

	local function dictLength(dict)
		local count = 0
		for _ in dict do
			count += 1
		end
		return count
	end

	local function giveRootsOf(object,type)
		if not object.Root then return end
		for i,v in object.Root[type] do
			if object[type][i] then continue end
			object[type][i] = v
		end
	end

	for _,v in dumpLines do
		v = v:match("^[\t%s]*(.-)%s*$")
		if v == "" then continue end
		local type = v:match("^(%w+)")

		if type == "Class" then
			local lineSplit = v:split(" ")
			local tags = {v:match("%[(.-)%]")}
			local class = {
				Name = lineSplit[2],
				Tags = tags,

				Root = Classes[lineSplit[4]],
				Subclasses = {},

				Properties = {},
			}

			Classes[lineSplit[2]] = class
			if class.Root then
				class.Root.Subclasses[class.Name] = class
			elseif _ ~= 1 then
				warn("No root?", class)
			end

			giveRootsOf(class,"Properties")
		elseif type == "Property" then
			local lineSplit = v
			local tags = {v:match("%[(.-)%]")}

			local className,propName,value = (v.." "):match("^Property (.-)%.(.-):%s(.-)%s")
			local class = Classes[className]

			local property = {
				Name = propName,
				Tags = tags,

				Value = value,
				Origin = class.Name,  -- must be .Name to prevent print crashes.
			}
			class.Properties[propName] = property
		end
	end

	return Classes

	-- Class ExecutedRemoteCommand : Object [NotCreatable] [NotReplicated]
	-- Property Instance.Attributes: string [Hidden] [ReadOnly] [NotScriptable] {🔒RobloxEngine}
	-- Function EditableMesh:GetFacesWithNormal(normalId: number) -> { any } [CustomLuaState] {🚧DynamicGeneration}
	-- Event Instance.AncestryChanged(child: Instance, parent: Instance)
--[[
Types: {
    ["Callback"] = true,
    ["Class"] = true,
    ["Enum"] = true,
    ["EnumItem"] = true,
    ["Event"] = true,
    ["Function"] = true,
    ["Property"] = true
 }
 
]]	
end)()
local Values = (function()
	local BufferTypes = (function()
		local module = {}
		module.__index = module

		local constructed = {}

		function module.new(...)
			local type = {...}
			if typeof(type[1]) == "table" then type = type[1] end

			local concat = table.concat(type)
			if constructed[concat] then return constructed[concat] end

			local types = {}
			local bytes = 0
			for _,v in type do
				local num = tonumber(v:sub(2,-1))
				if not num or not buffer["write"..v] then return error(v.." is not a valid input!") end

				local type = {
					Type = v,
					Size = num/8,
					Offset = bytes,
				}
				table.insert(types,type)
				bytes += type.Size
			end

			local data = {
				Types = types,
				Bytes = bytes,
			}
			setmetatable(data,module)

			constructed[concat] = data
			return data
		end

		function module:Construct(...)
			local data = {...}
			if typeof(data[1]) == "table" then data = data[1] end

			local buf = buffer.create(self.Bytes)
			for i,v in self.Types do
				local type = v.Type
				local offset = v.Offset

				buffer["write"..type](buf,offset,data[i])
			end
			return buf
		end
		function module:Deconstruct(buf)
			local data = {}
			for i,v in self.Types do
				local type = v.Type
				local offset = v.Offset

				table.insert(data,
					buffer["read"..type](buf,offset)
				)
			end
			return unpack(data)
		end

		return module

	end)()

	local module = {}
	module._types = {
		["string"] = {
			function(value)
				return value
			end,
			function(value)
				return value
			end,
		},
		["number"] = {
			function(dbl)
				local buf = buffer.create(8)
				buffer.writef64(buf,0,dbl)
				return buffer.tostring(buf)
			end,
			function(dbl)
				local output = buffer.fromstring(dbl)
				return buffer.readf64(output,0)
			end,
		},
		["boolean"] = {
			function(bool)
				return if bool then "\1" else "\0"
			end,
			function(bool)
				return if bool == "\1" then true else false
			end,
		},
		["axes"] = {
			function(value)
				local mask = 0
				if value.X then mask +=1 end
				if value.Y then mask +=2 end
				if value.Z then mask +=4 end

				local bfr = buffer.create(1)
				buffer.writeu8(bfr,0,mask)
				return buffer.tostring(bfr)
			end,
			function(value)
				local bfr = buffer.fromstring(value)
				local byte = buffer.readu8(bfr,0)
				local enums = {}

				if bit32.btest(byte, 1) then table.insert(enums, Enum.Axis.X) end
				if bit32.btest(byte, 2) then table.insert(enums, Enum.Axis.Y) end
				if bit32.btest(byte, 4) then table.insert(enums, Enum.Axis.Z) end

				return Axes.new(
					unpack(enums)
				)
			end,
		},
		["brickcolor"] = {
			function(value)
				local bfr = buffer.create(2)
				buffer.writeu16(bfr, 0, value.Number)
				return buffer.tostring(bfr)
			end,
			function(value)
				local bfr = buffer.fromstring(value)
				return BrickColor.new(
					buffer.readu16(bfr, 0)
				)
			end,
		},
		["cframe"] = {
			function(cf: CFrame): string
				local bfrtype = BufferTypes.new("f64","f64","f64","f32","f32","f32","f32","f32","f32","f32","f32","f32")

				return buffer.tostring(
					bfrtype:Construct(
						cf:GetComponents()
					)
				)
			end,

			function(value: string): CFrame
				local bfr = buffer.fromstring(value)
				local bfrtype = BufferTypes.new("f64","f64","f64","f32","f32","f32","f32","f32","f32","f32","f32","f32")

				return CFrame.new(
					bfrtype:Deconstruct(bfr)
				)
			end,
		},
		["color3"] = {
			function(value)
				local bfrtype = BufferTypes.new("u8","u8","u8")
				return buffer.tostring(bfrtype:Construct(
					math.floor(value.R*255),
					math.floor(value.G*255),
					math.floor(value.B*255)
					))
			end,
			function(value)
				local bfrtype = BufferTypes.new("u8","u8","u8")
				return Color3.fromRGB(
					bfrtype:Deconstruct(
						buffer.fromstring(value)
					)
				)
			end,
		},
		["colorsequence"] = {
			function(value:ColorSequence)
				local kp = value.Keypoints
				local count = #kp

				local bfr = buffer.create(1 + count*4)

				buffer.writeu8(bfr,0,count)

				local offset = 1
				for _, kp in kp do
					buffer.writeu8(bfr, offset, math.round(kp.Time * 255))

					buffer.writeu8(bfr, offset + 1, math.round(kp.Value.R * 255))
					buffer.writeu8(bfr, offset + 2, math.round(kp.Value.G * 255))
					buffer.writeu8(bfr, offset + 3, math.round(kp.Value.B * 255))

					offset += 4
				end

				return buffer.tostring(bfr)
			end,
			function(value:string)
				local bfr = buffer.fromstring(value)
				local count = buffer.readu8(bfr, 0)
				local keypoints = table.create(count)

				local offset = 1
				for i = 1, count do
					local time = buffer.readu8(bfr, offset) / 255

					local color = Color3.fromRGB(
						buffer.readu8(bfr, offset + 1),
						buffer.readu8(bfr, offset + 2),
						buffer.readu8(bfr, offset + 3)
					)

					keypoints[i] = ColorSequenceKeypoint.new(time, color)
					offset += 4
				end

				return ColorSequence.new(keypoints)
			end,
		},
		["datetime"] = {
			function(dt: DateTime): string
				local bfr = buffer.create(8)
				buffer.writef64(bfr, 0, dt.UnixTimestampMillis)

				return buffer.tostring(bfr)
			end,

			function(value: string): DateTime
				local bfr = buffer.fromstring(value)
				local millis = buffer.readf64(bfr, 0)

				return DateTime.fromUnixTimestampMillis(millis)
			end,
		},
		["enumitem"] = {
			function(value:EnumItem)
				local value = tostring(value):sub(6)
				return value
			end,
			function(value)
				local enum = Enum
				for _,v in value:split(".") do
					enum = enum[v]
				end
				return enum
			end,
		},
		["faces"] = {
			function(value:Faces)
				local mask = 0
				if value.Front then mask +=1 end
				if value.Back then mask +=2 end
				if value.Left then mask +=4 end
				if value.Right then mask +=8 end
				if value.Top then mask +=16 end
				if value.Bottom then mask +=32 end

				local bfr = buffer.create(1)
				buffer.writeu8(bfr,0,mask)
				return buffer.tostring(bfr)
			end,
			function(value)
				local bfr = buffer.fromstring(value)
				local byte = buffer.readu8(bfr,0)
				local enums = {}

				if bit32.btest(byte, 1) then table.insert(enums, Enum.NormalId.Front) end
				if bit32.btest(byte, 2) then table.insert(enums, Enum.NormalId.Back) end
				if bit32.btest(byte, 4) then table.insert(enums, Enum.NormalId.Left) end
				if bit32.btest(byte, 8) then table.insert(enums, Enum.NormalId.Right) end
				if bit32.btest(byte, 16) then table.insert(enums, Enum.NormalId.Top) end
				if bit32.btest(byte, 32) then table.insert(enums, Enum.NormalId.Bottom) end

				return Faces.new(unpack(enums))
			end,
		},
		["font"] = {
			function(value: Font): string
				local family = value.Family
				local familyLen = #family

				local weightIndex = math.clamp(math.floor(value.Weight.Value / 100) - 1, 0, 8)
				local styleIndex = (value.Style == Enum.FontStyle.Italic) and 1 or 0
				local boldBit = value.Bold and 1 or 0

				local mask = weightIndex 
					+ bit32.lshift(styleIndex, 4) 
					+ bit32.lshift(boldBit, 5)

				local bfr = buffer.create(2 + familyLen)
				buffer.writeu8(bfr, 0, mask)
				buffer.writeu8(bfr, 1, familyLen)
				buffer.writestring(bfr, 2, family)

				return buffer.tostring(bfr)
			end,

			function(value: string): Font
				local bfr = buffer.fromstring(value)
				local mask = buffer.readu8(bfr, 0)
				local familyLen = buffer.readu8(bfr, 1)
				local family = buffer.readstring(bfr, 2, familyLen)

				local weightIndex = bit32.band(mask, 0x0F)
				local styleIndex = bit32.band(bit32.rshift(mask, 4), 0x01)
				local boldBit = bit32.band(bit32.rshift(mask, 5), 0x01) == 1

				local weightValue = (weightIndex + 1) * 100
				local weightEnum = Enum.FontWeight.Regular
				for _, item in Enum.FontWeight:GetEnumItems() do
					if item.Value == weightValue then
						weightEnum = item
						break
					end
				end

				local styleEnum = (styleIndex == 1) and Enum.FontStyle.Italic or Enum.FontStyle.Normal

				local font = Font.new(family, weightEnum, styleEnum)
				font.Bold = boldBit

				return font
			end,
		},
		["numberrange"] = {
			function(value : NumberRange)
				local buf = buffer.create(8)
				buffer.writef32(buf,0,value.Min)
				buffer.writef32(buf,4,value.Max)
				return buffer.tostring(buf)
			end,
			function(value)
				local buf = buffer.fromstring(value)
				local min = buffer.readf32(buf,0)
				local max = buffer.readf32(buf,4)
				return NumberRange.new(min,max)
			end,
		},
		["numbersequence"] = {
			function(value: NumberSequence)
				local kp = value.Keypoints
				local count = #kp
				local bfr = buffer.create(1 + count * 12)
				buffer.writeu8(bfr, 0, count)

				local offset = 1
				for _, k in kp do
					buffer.writef32(bfr, offset, k.Time)
					buffer.writef32(bfr, offset + 4, k.Value)
					buffer.writef32(bfr, offset + 8, k.Envelope)
					offset += 12
				end
				return buffer.tostring(bfr)
			end,
			function(value: string)
				local bfr = buffer.fromstring(value)
				local count = buffer.readu8(bfr, 0)
				local keypoints = table.create(count)

				local offset = 1
				for i = 1, count do
					local time = buffer.readf32(bfr, offset)
					local val = buffer.readf32(bfr, offset + 4)
					local env = buffer.readf32(bfr, offset + 8)
					keypoints[i] = NumberSequenceKeypoint.new(time, val, env)
					offset += 12
				end
				return NumberSequence.new(keypoints)
			end,
		},
		["path2dcontrolpoint"] = {
			function(value:Path2DControlPoint)
				local buftype = BufferTypes.new("f32","i32","f32","i32","f32","i32","f32","i32","f32","i32","f32","i32")
				local pos = value.Position
				local lT = value.LeftTangent
				local rT = value.RightTangent

				local buf = buftype:Construct(
					pos.X.Scale,
					pos.X.Offset,
					pos.Y.Scale,
					pos.Y.Offset,

					lT.X.Scale,
					lT.X.Offset,
					lT.Y.Scale,
					lT.Y.Offset,

					rT.X.Scale,
					rT.X.Offset,
					rT.Y.Scale,
					rT.Y.Offset
				)

				return buffer.tostring(buf)
			end,
			function(value)
				local buftype = BufferTypes.new("f32","i32","f32","i32","f32","i32","f32","i32","f32","i32","f32","i32")

				local posXScale,posXOffset,posYScale,posYOffset,lTXScale,lTXOffset,lTYScale,lTYOffset,rTXScale,rTXOffset,rTYScale,rTYOffset = buftype:Deconstruct(buffer.fromstring(value))
				local pos = UDim2.new(posXScale,posXOffset,posYScale,posYOffset)
				local lT = UDim2.new(lTXScale,lTXOffset,lTYScale,lTYOffset)
				local rT = UDim2.new(rTXScale,rTXOffset,rTYScale,rTYOffset)

				return Path2DControlPoint.new(pos,lT,rT)
			end,
		},
		["physicalproperties"] = {
			function(value : PhysicalProperties)
				local buftype = BufferTypes.new("f32","f32","f32","f32","f32")
				local buf = buftype:Construct(
					value.Density,
					value.Friction,
					value.Elasticity,
					value.FrictionWeight,
					value.ElasticityWeight
				)
				return buffer.tostring(buf)
			end,
			function(value)
				local buftype = BufferTypes.new("f32","f32","f32","f32","f32")
				return PhysicalProperties.new(
					buftype:Deconstruct(
						buffer.fromstring(value)
					)
				)
			end,
		},
		["ray"] = {
			function(value : Ray)
				local buftype = BufferTypes.new("f32","f32","f32","f32","f32","f32")

				return buffer.tostring(
					buftype:Construct(
						value.Origin.X,
						value.Origin.Y,
						value.Origin.Z,
						value.Direction.X,
						value.Direction.Y,
						value.Direction.Z
					)
				)
			end,
			function(value)
				local buftype = BufferTypes.new("f32","f32","f32","f32","f32","f32")
				local params = {buftype:Deconstruct(buffer.fromstring(value))}
				return Ray.new(
					Vector3.new(params[1],params[2],params[3]),
					Vector3.new(params[4],params[5],params[6])
				)
			end,
		},
		["rect"] = {
			function(value:Rect)
				local buftype = BufferTypes.new("f32","f32","f32","f32")

				return buffer.tostring(
					buftype:Construct(
						value.Min.X,
						value.Min.Y,

						value.Max.X,
						value.Max.Y
					)
				)
			end,
			function(value)
				local buftype = BufferTypes.new("f32","f32","f32","f32")

				return Rect.new(
					buftype:Deconstruct(
						buffer.fromstring(value)
					)
				)
			end,
		},
		["region3int16"] = {
			function(value:Region3int16)
				local buftype = BufferTypes.new("i16","i16","i16","i16","i16","i16")

				return buffer.tostring(
					buftype:Construct(
						value.Min.X,
						value.Min.Y,
						value.Min.Z,

						value.Max.X,
						value.Max.Y,
						value.Max.Z
					)
				)
			end,
			function(value)
				local buftype = BufferTypes.new("i16","i16","i16","i16","i16","i16")
				local params = {buftype:Deconstruct(buffer.fromstring(value))}
				return Region3int16.new(
					Vector3int16.new(
						params[1],params[2],params[3]
					),
					Vector3int16.new(
						params[4],params[5],params[6]
					)
				)
			end,
		},
		["vector3int16"] = {
			function(value:Vector3int16)
				local buftype = BufferTypes.new("i16","i16","i16")

				return buffer.tostring(
					buftype:Construct(
						value.X,
						value.Y,
						value.Z
					)
				)
			end,
			function(value)
				local buftype = BufferTypes.new("i16","i16","i16")
				return Vector3int16.new(
					buftype:Deconstruct(
						buffer.fromstring(value)
					)
				)
			end,
		},
		["tweeninfo"] = {
			function(info: TweenInfo): string
				local bftype = BufferTypes.new("f32", "u8", "u8", "i16", "u8", "f32")

				return buffer.tostring(bftype:Construct(
					info.Time,
					info.EasingStyle.Value,
					info.EasingDirection.Value,
					info.RepeatCount,
					info.Reverses and 1 or 0,
					info.DelayTime
					))
			end,

			function(value: string): TweenInfo
				local bfr = buffer.fromstring(value)
				local bftype = BufferTypes.new("f32", "u8", "u8", "i16", "u8", "f32")

				local time, easingStyle, easingDirection, repeatCount, reverses, delayTime = bftype:Deconstruct(bfr)

				return TweenInfo.new(
					time,
					easingStyle,
					easingDirection,
					repeatCount,
					reverses == 1,
					delayTime
				)
			end,
		},
		["udim"] = {
			function(value: UDim)
				-- Changed i8 -> i32 to prevent offset truncation/overflow errors
				local buftype = BufferTypes.new("f32", "i32")
				return buffer.tostring(
					buftype:Construct(value.Scale, value.Offset)
				)
			end,
			function(value: string): UDim
				local buftype = BufferTypes.new("f32", "i32")
				return UDim.new(
					buftype:Deconstruct(
						buffer.fromstring(value)
					)
				)
			end
		},
		["udim2"] = {
			function(value: UDim2)
				-- Changed i8 -> i32 to prevent offset truncation/overflow errors
				local buftype = BufferTypes.new("f32", "i32", "f32", "i32")
				return buffer.tostring(
					buftype:Construct(value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
				)
			end,
			function(value: string): UDim2
				local buftype = BufferTypes.new("f32", "i32", "f32", "i32")
				return UDim2.new(
					buftype:Deconstruct(
						buffer.fromstring(value)
					)
				)
			end
		},
		["vector2"] = {
			function(value: Vector2)
				local buftype = BufferTypes.new("f32", "f32")
				return buffer.tostring(
					buftype:Construct(value.X, value.Y)
				)
			end,
			function(value: string): Vector2
				local buftype = BufferTypes.new("f32", "f32")
				return Vector2.new(
					buftype:Deconstruct(
						buffer.fromstring(value)
					)
				)
			end
		},
		["vector3"] = {
			function(value: Vector3)
				local buftype = BufferTypes.new("f64", "f64", "f64")
				return buffer.tostring(
					buftype:Construct(value.X, value.Y, value.Z)
				)
			end,
			function(value: string): Vector3
				local buftype = BufferTypes.new("f64", "f64", "f64")
				return Vector3.new(
					buftype:Deconstruct(
						buffer.fromstring(value)
					)
				)
			end
		},
		["uint"] = {
			function(value: number)
				local buftype = BufferTypes.new("u32")
				return buffer.tostring(
					buftype:Construct(value)
				)
			end,
			function(value: string): number
				local buftype = BufferTypes.new("u32")
				return buftype:Deconstruct(
					buffer.fromstring(value)
				)
			end
		},
		["content"] = {
			function(value: Content)
				return value.Uri
			end,
			function(value)
				return Content.fromUri(value)
			end
		}
	}

	local TypeIDs = {
		["\30"] = "axes",
		["\31"] = "brickcolor",
		["\32"] = "cframe",
		["\33"] = "color3",
		["\34"] = "colorsequence",
		["\35"] = "string",
		["\36"] = "datetime",
		["\37"] = "enumitem",
		["\38"] = "faces",
		["\39"] = "font",
		["\40"] = "number",
		["\41"] = "numberrange",
		["\42"] = "numbersequence",
		["\43"] = "path2dcontrolpoint",
		["\44"] = "physicalproperties",
		["\45"] = "ray",
		["\46"] = "rect",
		["\47"] = "region3int16",
		["\48"] = "boolean",
		["\49"] = "vector3int16",
		["\50"] = "tweeninfo",
		["\51"] = "udim",
		["\52"] = "udim2",
		["\53"] = "vector2",
		["\54"] = "vector3",
		["\55"] = "uint",
		["\56"] = "content",
	}

	local ReverseTypeIds = {}
	for i,v in TypeIDs do ReverseTypeIds[v] = i end

	function module:Serialize(value,forceType)
		local valueType = (forceType or typeof(value)):lower()
		if not ReverseTypeIds[valueType] then return false end

		return ReverseTypeIds[valueType]..module._types[valueType][1](value)
	end

	function module:Deserialize(value : string)
		local type = value:sub(1,1)
		value = value:sub(2)

		if not TypeIDs[type] then error("Invalid type: "..string.byte(type)) end
		type = TypeIDs[type]

		return module._types[type][2](value)
	end

	return module
end)()

local DEBUG = false

local module = {}
local function debug(...)
	if not DEBUG then return end
	warn(...)
end 


local function cConcat(tab,customFunc)
	local concat = ""
	for i,v in tab do
		concat ..= customFunc(v,i)
	end
	return concat
end

local function dictLen(dict)
	local len = 0
	for _ in dict do
		len += 1
	end
	return len
end

function module:_compress(instances : {any}) : string
	local classes,classesNum = {},{}
	local properties,propertiesNum = {},{}
	local values,valuesNum = {},{}
	for _,v in instances do
		if not classesNum[v.ClassName] then
			table.insert(classes,v.ClassName)
			classesNum[v.ClassName] = #classes
		end
		for prop,value in v.Properties do
			if not propertiesNum[prop] then
				table.insert(properties,prop)
				propertiesNum[prop] = #properties
			end
			if not valuesNum[value] then
				table.insert(values,value)
				valuesNum[value] = #values
			end
		end
	end

	return Values:Serialize(#classes, "uint")
		.. cConcat(classes, function(v)
			return Values:Serialize(#v, "uint") .. v
		end)
		.. Values:Serialize(#properties, "uint")
		.. cConcat(properties, function(v)
			return Values:Serialize(#v, "uint") .. v
		end)
		.. Values:Serialize(#values, "uint")
		.. cConcat(values, function(v)
			return Values:Serialize(#v, "uint") .. v
		end)
		.. Values:Serialize(#instances, "uint")
		.. cConcat(instances, function(v)
			return Values:Serialize(classesNum[v.ClassName], "uint")
			.. Values:Serialize(dictLen(v.Properties), "uint")
			.. cConcat(v.Properties, function(val, propName)
				return Values:Serialize(propertiesNum[propName], "uint")
				.. Values:Serialize(valuesNum[val], "uint")
			end)

		end)
end

function module:_decompress(source : string) : {any}
	local classes,classesNum = {},{}
	local properties,propertiesNum = {},{}
	local values,valuesNum = {},{}

	local cursor = 1

	local function readLen(len : number)
		local sub = source:sub(cursor,cursor+len-1)
		cursor += len
		return sub
	end
	local function readBytes(bytes : number)
		return Values:Deserialize(
			readLen(bytes)
		)
	end
	local function readUint() : number
		return readBytes(5)
	end

	local classesAmt = readUint()
	for i = 1,classesAmt do
		local class = readLen(readUint())

		table.insert(classes,class)
		classesNum[class] = #classes
	end

	local propertiesAmt = readUint()
	for i = 1,propertiesAmt do
		local property = readLen(readUint())

		table.insert(properties,property)
		propertiesNum[property] = #properties
	end

	local valuesAmt = readUint()
	for i = 1,valuesAmt do
		local value = readLen(readUint())

		table.insert(values,value)
		valuesNum[value] = #values
	end


	local instances = {}
	local objectsAmt = readUint()
	for i = 1,objectsAmt do
		local class = classes[readUint()]
		local propertiesAmt = readUint()
		local objProps = {}

		for i = 1,propertiesAmt do
			local propName = properties[readUint()]
			local value = values[readUint()]

			objProps[propName] = value
		end
		table.insert(instances,{
			ClassName = class,
			Properties = objProps
		})
	end
	return instances
end

function module:_gatherProperties(obj : Instance,objNumbers)
	if obj:IsA("LuaSourceContainer") then return false end
	local class = Classes[obj.ClassName]
	local notCreatable = table.find(class.Tags,"NotCreatable")
	if notCreatable then return false end

	local compareInstance = Instance.new(obj.ClassName)
	local properties = {}
	for _,v in class.Properties do
		if table.find({},v.Name) then continue end
		local firstL = v.Name:sub(1,1)
		if firstL == firstL:lower() then continue end -- prevent unproper properties. e.g .p, .size, .shape, etc. and leaves .Parent, .Archivable, .Name, .ClassName, etc.

		if table.find(class.Tags,"NotScriptable") then continue end
		if table.find(class.Tags,"ReadOnly") then continue end
		if table.find(class.Tags,"WriteOnly") then continue end

		local success,value = pcall(function()obj[v.Name] = obj[v.Name]  return obj[v.Name] end) 
		if not success then continue end

		if compareInstance[v.Name] == value then continue end
		if typeof(value) == "Instance" then
			if not objNumbers[value] then continue end
			properties[v.Name] = objNumbers[value]
			continue
		end
		local serializedValue = Values:Serialize(value)
		if not serializedValue then continue end
		properties[v.Name] = serializedValue
	end
	compareInstance:Destroy()
	return properties
end

function module:_serialize(...) : {any}
	local objs = {...}
	if typeof(objs[1]) == "table" then objs = objs[1] end

	local objNumber = 0
	local objNumbers = {}
	local instances = {}
	local function doObject(obj : Instance)
		local props = module:_gatherProperties(obj,objNumbers)
		debug("Serializing: "..obj:GetFullName())
		if not props then return debug("Gathered property returned: "..tostring(props)) end

		objNumber += 1
		local objTable = {
			ClassName = obj.ClassName,
			Properties = props,
		}
		objNumbers[obj] = Values:Serialize(objNumber,"uint")
		instances[objNumber] = objTable
		for _,v in obj:GetChildren() do
			doObject(v)
		end
	end
	for _,v in objs do
		doObject(v)
	end
	return instances
end
function module:_deserialize(source, parent) : ...any
	local objs, returned, instanceProps = {}, {}, {}

	for _, v in source do
		local obj = Instance.new(v.ClassName)
		table.insert(objs, obj)
		if not v.Properties.Parent then table.insert(returned, obj) end

		for prop, val in v.Properties do
			local value = Classes[v.ClassName].Properties[prop].Value:gsub("%?", "")
			if Classes[value] then
				table.insert(instanceProps, {obj, prop, val})
			else
				obj[prop] = Values:Deserialize(val)
			end
		end
	end

	for _, v in instanceProps do v[1][v[2]] = objs[Values:Deserialize(v[3])] end
	for _, obj in returned do obj.Parent = parent end

	return unpack(returned)
end

function module:Serialize(...) : string
	local str = module:_compress(
		module:_serialize(...)
	)
	local encoded = game:GetService("EncodingService"):Base64Encode(
		buffer.fromstring(str)
	)
	return buffer.tostring(encoded)
end
function module:Deserialize(source,parent) : ...any
	local bfr = game:GetService("EncodingService"):Base64Decode(source)
	return module:_deserialize(
		module:_decompress(buffer.tostring(bfr),parent)
	)
end

function module:UploadOnline(title,name,content)
	local tab = http:JSONDecode(http:PostAsync("https://glot.io/api/snippets",http:JSONEncode{language="plaintext",title=title,public=true,files={{name = name,content=content}}}))
	return tab
end
function module:DownloadOnline(snippetUrl)
	local data = if hasHttpGet then game:HttpGet(snippetUrl) else http:GetAsync(snippetUrl)
	return data
end

return module

return module
