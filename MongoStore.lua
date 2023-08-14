--[[

	MongoStore is an alternative to DataStoreService
	which uses the Rongo module as an interface to
	MongoDB.
	
	MongoStore includes quite a few of the functions
	which DataStoreService has and it aims to make the
	transition from DataStoreService as smooth as possible
	
	You will need a MongoDB account to use MongoStore
	
	Version: 1.0.0
	License: MIT License
	Contributors:
		- Starnamics (Creator)
	Documentation: N/A

--]]

local function rngo()
	--[[

	Rongo - MongoDB API Wrapper for Roblox
	
	Rongo gives developers easy access to MongoDBs web APIs
	so they're able to use MongoDB directly in their games
	
	Rongo is a bare-bones module, meaning it contains only
	the essentials, which can be used standalone or to
	develop modules which use Rongo at its core. 
	
	Some modules which use Rongo can be found on the Rongo
	DevForum post!
	
	Rongo uses MongoDB's Data API, which is disabled by
	default so you must enable it in your Atlas settings
	
	Version: 1.1.0
	License: MIT License
	Contributors:
		- Starnamics (Creator)
	Documentation: N/A	

--]]

	local HttpService = game:GetService("HttpService")

	local APIVersion = "v1"
	local URI = "https://data.mongodb-api.com/app/%s/endpoint/data/"..APIVersion

	local ENDPOINTS = {
		POST = {
			["FindOne"] = "/action/findOne",
			["FindMany"] = "/action/find",
			["InsertOne"] = "/action/insertOne",
			["InsertMany"] = "/action/insertMany",
			["UpdateOne"] = "/action/updateOne",
			["UpdateMany"] = "/action/updateMany",
			["ReplaceOne"] = "/action/replaceOne",
			["DeleteOne"] = "/action/deleteOne",
			["DeleteMany"] = "/action/deleteMany",
		}
	}

	local Rongo = {}

	local RongoClient = {}
	RongoClient.__index = RongoClient

	local RongoCluster = {}
	RongoCluster.__index = RongoCluster

	local RongoDatabase = {}
	RongoDatabase.__index = RongoDatabase

	local RongoCollection = {}
	RongoCollection.__index = RongoCollection

	local RongoDocument = {}
	RongoDocument.__index = RongoDocument

	function Rongo.new(AppId: string,Key: string)
		local Client = {}
		setmetatable(Client,RongoClient)

		Client["AppId"] = AppId
		Client["Key"] = Key

		return Client
	end

	function RongoClient:SetVersion(Version: "v1" | "beta")
		URI = "https://data.mongodb-api.com/app/%s/endpoint/data/"..Version
	end

	function RongoClient:GetCluster(Name: string)
		local Cluster = {}
		setmetatable(Cluster,RongoCluster)

		Cluster["Client"] = self
		Cluster["Name"] = Name

		return Cluster
	end

	function RongoCluster:GetDatabase(Name: string)
		local Database = {}
		setmetatable(Database,RongoDatabase)

		Database["Client"] = self["Client"]
		Database["Cluster"] = self
		Database["Name"] = Name

		return Database
	end

	function RongoDatabase:GetCollection(Name: string)
		local Collection = {}
		setmetatable(Collection,RongoCollection)

		Collection["Client"] = self["Client"]
		Collection["Cluster"] = self["Cluster"]
		Collection["Database"] = self
		Collection["Name"] = Name

		return Collection
	end

	function RongoCollection:FindOne(Filter: {[string]: string | {[string]: string}}?): {[string]: any?}?
		local RequestData = {
			["dataSource"] = self["Cluster"]["Name"],
			["database"] = self["Database"]["Name"],
			["collection"] = self["Name"],
			["filter"] = Filter or nil,
		}
		local RequestHeaders = {
			["Access-Control-Request-Headers"] = "*",
			["api-key"] = self["Client"]["Key"]
		}
		RequestData = HttpService:JSONEncode(RequestData)
		local Success,Response = pcall(function() return HttpService:PostAsync(string.format(URI,self["Client"]["AppId"])..ENDPOINTS.POST.FindOne,RequestData,Enum.HttpContentType.ApplicationJson,false,RequestHeaders) end)
		if not Success then warn("[RONGO] Request Failed:",Response) return end
		Response = HttpService:JSONDecode(Response)
		if not Response["document"] then return nil end
		return Response["document"]
	end

	function RongoCollection:FindMany(Filter: {[string]: string | {[string]: string}}?,Limit: number?,Sort: {any?}?,Skip: number?): {[number]: {[string]: any?}}?
		local RequestData = {
			["dataSource"] = self["Cluster"]["Name"],
			["database"] = self["Database"]["Name"],
			["collection"] = self["Name"],
			["filter"] = Filter or nil,
			["limit"] = Limit or nil,
			["sort"] = Sort or nil,
			["skip"] = Skip or nil,
		}
		local RequestHeaders = {
			["Access-Control-Request-Headers"] = "*",
			["api-key"] = self["Client"]["Key"]
		}
		RequestData = HttpService:JSONEncode(RequestData)
		local Success,Response = pcall(function() return HttpService:PostAsync(string.format(URI,self["Client"]["AppId"])..ENDPOINTS.POST.FindMany,RequestData,Enum.HttpContentType.ApplicationJson,false,RequestHeaders) end)
		if not Success then warn("[RONGO] Request Failed:",Response) return end
		Response = HttpService:JSONDecode(Response)
		if not Response["documents"] then return nil end
		return Response["documents"]
	end

	function RongoCollection:InsertOne(Document: {[string]: any?}): string?
		if not Document then warn("[RONGO] Document argument cannot be empty") return nil end
		local RequestData = {
			["dataSource"] = self["Cluster"]["Name"],
			["database"] = self["Database"]["Name"],
			["collection"] = self["Name"],
			["document"] = Document,
		}
		local RequestHeaders = {
			["Access-Control-Request-Headers"] = "*",
			["api-key"] = self["Client"]["Key"]
		}
		RequestData = HttpService:JSONEncode(RequestData)
		local Success,Response = pcall(function() return HttpService:PostAsync(string.format(URI,self["Client"]["AppId"])..ENDPOINTS.POST.InsertOne,RequestData,Enum.HttpContentType.ApplicationJson,false,RequestHeaders) end)
		if not Success then warn("[RONGO] Request Failed:",Response) return end
		Response = HttpService:JSONDecode(Response)
		if not Response["insertedId"] then return nil end
		return Response["insertedId"]
	end

	function RongoCollection:InsertMany(Documents: {[number]: {[string]: any?}}): {[number]: string}?
		if not Documents then warn("[RONGO] Documents argument cannot be empty") return nil end
		local RequestData = {
			["dataSource"] = self["Cluster"]["Name"],
			["database"] = self["Database"]["Name"],
			["collection"] = self["Name"],
			["documents"] = Documents,
		}
		local RequestHeaders = {
			["Access-Control-Request-Headers"] = "*",
			["api-key"] = self["Client"]["Key"]
		}
		RequestData = HttpService:JSONEncode(RequestData)
		local Success,Response = pcall(function() return HttpService:PostAsync(string.format(URI,self["Client"]["AppId"])..ENDPOINTS.POST.InsertMany,RequestData,Enum.HttpContentType.ApplicationJson,false,RequestHeaders) end)
		if not Success then warn("[RONGO] Request Failed:",Response) return end
		Response = HttpService:JSONDecode(Response)
		if not Response["insertedIds"] then return nil end
		return Response["insertedIds"]
	end

	function RongoCollection:UpdateOne(Filter: string,Update: {[string]: any?},Upsert: boolean?): {["matchedCount"]: number,["modifiedCount"]: number,["upsertedId"]: string?}?
		if not Filter then warn("[RONGO] Filter argument cannot be empty") return nil end
		if not Update then warn("[RONGO] Update argument cannot be empty") return nil end
		local RequestData = {
			["dataSource"] = self["Cluster"]["Name"],
			["database"] = self["Database"]["Name"],
			["collection"] = self["Name"],
			["filter"] = Filter or nil,
			["update"] = Update or nil,
			["upsert"] = Upsert or nil,
		}
		local RequestHeaders = {
			["Access-Control-Request-Headers"] = "*",
			["api-key"] = self["Client"]["Key"]
		}
		RequestData = HttpService:JSONEncode(RequestData)
		local Success,Response = pcall(function() return HttpService:PostAsync(string.format(URI,self["Client"]["AppId"])..ENDPOINTS.POST.UpdateOne,RequestData,Enum.HttpContentType.ApplicationJson,false,RequestHeaders) end)
		if not Success then warn("[RONGO] Request Failed:",Response) return end
		Response = HttpService:JSONDecode(Response)
		return Response
	end

	function RongoCollection:UpdateMany(Filter: string,Update: {[string]: any?},Upsert: boolean?): {["matchedCount"]: number,["modifiedCount"]: number,["upsertedId"]: string?}?
		if not Filter then warn("[RONGO] Filter argument cannot be empty") return nil end
		if not Update then warn("[RONGO] Update argument cannot be empty") return nil end
		local RequestData = {
			["dataSource"] = self["Cluster"]["Name"],
			["database"] = self["Database"]["Name"],
			["collection"] = self["Name"],
			["filter"] = Filter or nil,
			["update"] = Update or nil,
			["upsert"] = Upsert or nil,
		}
		local RequestHeaders = {
			["Access-Control-Request-Headers"] = "*",
			["api-key"] = self["Client"]["Key"]
		}
		RequestData = HttpService:JSONEncode(RequestData)
		local Success,Response = pcall(function() return HttpService:PostAsync(string.format(URI,self["Client"]["AppId"])..ENDPOINTS.POST.UpdateMany,RequestData,Enum.HttpContentType.ApplicationJson,false,RequestHeaders) end)
		if not Success then warn("[RONGO] Request Failed:",Response) return end
		Response = HttpService:JSONDecode(Response)
		return Response
	end

	function RongoCollection:ReplaceOne(Filter: string,Replacement: {[string]: any?},Upsert: boolean?): {["matchedCount"]: number,["modifiedCount"]: number,["upsertedId"]: string?}?
		if not Filter then warn("[RONGO] Filter argument cannot be empty") return nil end
		if not Replacement then warn("[RONGO] Update argument cannot be empty") return nil end
		local RequestData = {
			["dataSource"] = self["Cluster"]["Name"],
			["database"] = self["Database"]["Name"],
			["collection"] = self["Name"],
			["filter"] = Filter or nil,
			["replacement"] = Replacement,
			["upsert"] = Upsert
		}
		local RequestHeaders = {
			["Access-Control-Request-Headers"] = "*",
			["api-key"] = self["Client"]["Key"]
		}
		RequestData = HttpService:JSONEncode(RequestData)
		local Success,Response = pcall(function() return HttpService:PostAsync(string.format(URI,self["Client"]["AppId"])..ENDPOINTS.POST.ReplaceOne,RequestData,Enum.HttpContentType.ApplicationJson,false,RequestHeaders) end)
		if not Success then warn("[RONGO] Request Failed:",Response) return end
		Response = HttpService:JSONDecode(Response)
		return Response
	end

	function RongoCollection:DeleteOne(Filter: string): number?
		if not Filter then warn("[RONGO] Filter argument cannot be empty") return nil end
		local RequestData = {
			["dataSource"] = self["Cluster"]["Name"],
			["database"] = self["Database"]["Name"],
			["collection"] = self["Name"],
			["filter"] = Filter or nil,
		}
		local RequestHeaders = {
			["Access-Control-Request-Headers"] = "*",
			["api-key"] = self["Client"]["Key"]
		}
		RequestData = HttpService:JSONEncode(RequestData)
		local Success,Response = pcall(function() return HttpService:PostAsync(string.format(URI,self["Client"]["AppId"])..ENDPOINTS.POST.DeleteOne,RequestData,Enum.HttpContentType.ApplicationJson,false,RequestHeaders) end)
		if not Success then warn("[RONGO] Request Failed:",Response) return end
		Response = HttpService:JSONDecode(Response)
		if not Response["deletedCount"] then return 0 end
		return Response["deletedCount"]
	end

	function RongoCollection:DeleteMany(Filter: string): number?
		if not Filter then warn("[RONGO] Filter argument cannot be empty") return nil end
		local RequestData = {
			["dataSource"] = self["Cluster"]["Name"],
			["database"] = self["Database"]["Name"],
			["collection"] = self["Name"],
			["filter"] = Filter or nil,
		}
		local RequestHeaders = {
			["Access-Control-Request-Headers"] = "*",
			["api-key"] = self["Client"]["Key"]
		}
		RequestData = HttpService:JSONEncode(RequestData)
		local Success,Response = pcall(function() return HttpService:PostAsync(string.format(URI,self["Client"]["AppId"])..ENDPOINTS.POST.DeleteMany,RequestData,Enum.HttpContentType.ApplicationJson,false,RequestHeaders) end)
		if not Success then warn("[RONGO] Request Failed:",Response) return end
		Response = HttpService:JSONDecode(Response)
		if not Response["deletedCount"] then return 0 end
		return Response["deletedCount"]
	end

	return Rongo
end

MONGOSTORE_CLUSTER = "Cluster0"

local warn = function(...) return warn("[MongoStore]",...) end
local print = function(...) return print("[MongoStore]",...) end

local Rongo = rngo()
local Client = nil	

local MongoStore = {}

local MongoDataStore = {}
MongoDataStore.__index = MongoDataStore

function MongoStore:Authorize(API_ID:string,API_KEY:string,Cluster: string?): boolean?
	if Cluster then MONGOSTORE_CLUSTER = Cluster end
	Client = Rongo.new(API_ID,API_KEY)
	return true
end

function MongoStore:GetDataStore(Name: string,Scope: string)
	if not Client then repeat task.wait() until Client end
	local DataStore = {}
	setmetatable(DataStore,MongoDataStore)
	DataStore.Name = Name
	DataStore.Scope = Scope
	return DataStore
end

function MongoDataStore:GetAsync(Key: string): {[string]: any?}?
	local Collection = Client:GetCluster(MONGOSTORE_CLUSTER):GetDatabase(self.Name):GetCollection(self.Scope)
	local Document = Collection:FindOne({["key"] = Key})
	if Document then return Document["data"] else return nil end
end

function MongoDataStore:RemoveAsync(Key: string): boolean
	local Collection = Client:GetCluster(MONGOSTORE_CLUSTER):GetDatabase(self.Name):GetCollection(self.Scope)
	local Result = Collection:DeleteOne({["key"] = Key})
	if not Result or Result == 0 then return false end
	return true
end

function MongoDataStore:SetAsync(Key: string,Value: any): boolean
	local Collection = Client:GetCluster(MONGOSTORE_CLUSTER):GetDatabase(self.Name):GetCollection(self.Scope)
	local Result = Collection:ReplaceOne({["key"] = Key},{["key"] = Key,["data"] = Value},true)
	if not Result or Result.modifiedCount == 0 then return false end
	return true
end

function MongoDataStore:UpdateAsync(Key: string,Value: any): boolean
	local Collection = Client:GetCluster(MONGOSTORE_CLUSTER):GetDatabase(self.Name):GetCollection(self.Scope)
	local Result = Collection:UpdateOne({["key"] = Key},{["key"] = Key,["data"] = Value},true)
	if not Result or Result.modifiedCount == 0 then return false end
	return true
end

return MongoStore
