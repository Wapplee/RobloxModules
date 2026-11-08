-- local quicksaveinstance = loadstring(game:HttpGet('https://glot.io/snippets/hhhuunsw0j/raw/quicksaveinstance.lua'))()
-- https://luau.github.io/UniversalSynSaveInstance/api/SynSaveInstance
local Params = {
	RepoURL = "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/",
	SSI = "saveinstance",
}
getgenv().saveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()

getgenv().quicksaveinstance = function(object,settings)
    object = object or game
	local sett = {
		Object = object, -- Replace with your instance reference
		SafeMode = false,                       -- SET TO FALSE: SafeMode kicks you by design to prevent detection
		KillAllScripts = false,                 -- SET TO FALSE: Prevents your local scripts from being disabled
		ShutdownWhenDone = false,               -- SET TO FALSE: Keeps the game open after saving
		FilePath = object:GetFullName(),            -- Name of the file (saved to your executor's workspace folder)
        RemovePlayerCharacters = false,
        IsolateLocalPlayer = true,
        ReadMe = false,
    }
	for i,v in settings or {} do
		sett[i] = v
	end
	saveinstance(sett)
end

return quicksaveinstance
