--// Services //--
local DataStore	= game:GetService("DataStoreService")
local PlayerDS = DataStore:GetDataStore("WFS_PLAYERS_DATA")
local ServerScript = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local CollectionService	= game:GetService("CollectionService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Lightning	= game:GetService("Lighting")
local ServerScriptService = game:GetService("ServerScriptService")

--// Modules //--
local dataManager = require(ServerScriptService.Modules.DataManager)
local RobuxHandle = require(ServerScriptService.Modules.RobuxHandle)
local roundModule = require(ServerScriptService.GameManager.RoundSystem)
local Remote = require(ReplicatedStorage.Modules.Framework.RemoteManger)

--// Variables
local gameText = workspace.Stat
local intermission = workspace.Intermission
local inGame = workspace.Ingame
local potato = ReplicatedStorage.Potato
local currentVotes = {}
local Map

local premium = ReplicatedStorage.PremiumBenefts
local speed = premium.Speed
local coins = premium.Coins

--// Functions //--

--// Main Function For Counting Children Of Any Folder //--
function CountPlayersInFolder(folder)
	local playerCount = 0
	for _, child in ipairs(folder:GetChildren()) do -- Loop inside the folder's children
		playerCount += 1
	end

	return playerCount
end

--// Count Afk Players //--
local function CountAfked()
	local afked = 0
	for _, plr in pairs(Players:GetChildren()) do -- Loop inside players
		if plr:WaitForChild("Data").Values.Afk.Value == true then -- Find afk players
			afked += 1 -- Add to the total amount
		end
	end
	
	return afked
end

--// Count Players In Lobby //--
local function CountPlayersInLobby()
	local afked = CountAfked() -- Count afk people
	plrCount = CountPlayersInFolder(Players) - afked -- Count inside Players folder
	
	if plrCount <= 1 then
		return false -- return false if there are not enough players
	else
		return true -- return true if there are enough players
	end
end

local ChoosingMapAndMod, CheckPlayerCount, InGame -- Variables of Functions

--// Teleport Players To Game Function //--
local function TeleportPlayers()
	for i, plr in pairs(Players:GetChildren()) do -- loop in players
		if plr.Data and plr.Data.Values.Afk.Value == false and plr.Character then 
			local num = math.random(1, 24)
			plr.Character.Head.CFrame = CFrame.new(workspace.Teleport["Part"..num].Position)
			plr.Character.Parent = inGame
			plr.PlayerGui.MainGui.Buttons.Visible = false
			ReplicatedStorage.HideTopBar:FireClient(plr, false)
		end
	end
	
	InGame()
end

--// Voting Map And Choosing Mod Function //--
function ChoosingMapAndMod()
	CountPlayersInLobby() -- check if there are enough players
	gameText.Value = "Voteing for map.."
	
	--// Readying up maps to select //-- 
	roundModule.ReadyUpMaps()
	roundModule.toggleVoting("Map")
	task.wait(8) -- wait for players to vote
	Map = roundModule.loadMap() -- load map
	
	if not Map then
		warn("THERE IS PROBLEM WITH THE MAP PICKING") -- warn if there is a problem
	end

	gameText.Value = "Map chosen, the map is " ..Map.Name -- display chosen map
	
	--// Choosing Mod //--
	task.wait(3)
	local modselect = ReplicatedStorage.Mods:GetChildren() -- Get all mods
	local choose = math.random(1, #modselect) -- select random mod
	
	--// Apply Mod Settings //--
	for i, plr in pairs(Players:GetChildren()) do
		if plr.Data and plr.Data.Values.Afk.Value == false and plr.Character then
			plr.Character:WaitForChild("Humanoid").WalkSpeed = modselect[choose].Speed.Value
			plr.Character:WaitForChild("Humanoid").JumpPower = modselect[choose].Jump.Value
			if plr.MembershipType == Enum.MembershipType.Premium then -- if player has a membership then buff his speed 10%
				plr.Character:WaitForChild("Humanoid").WalkSpeed = modselect[choose].Speed.Value + modselect[choose].Speed.Value / speed.Value
			end
		end
	end

	gameText.Value = "Mod chosen, the mod is " ..modselect[choose].Name ..". Get ready!"
	task.wait(3)
	
	CountPlayersInLobby() -- check if there are enough players last time
	TeleportPlayers() -- teleport players
end

--// Intermission Function //--
local function Intermission()
	local t = intermission.Value
	while t > 0 do
		t -= 1
		gameText.Value = "Intermission.. "..t
		task.wait(1)
	end
	
	ChoosingMapAndMod()
end

--// Wait For More Players Function //--
local function WaitForMorePlayers()
	while true do
		task.wait(1)
		local matchable = CountPlayersInLobby()
		if matchable then -- if there are enough players then call intermission
			Intermission()
		end
		gameText.Value = "Waiting for more players"
		task.wait(1)
	end
end

--// Awarding Winner //--
local function AwardWinner(player:Player)
	gameText.Value = ""
	player.PlayerGui.MainGui.Buttons.Visible = true -- Display UI that was hiden in game
	ReplicatedStorage.HideTopBar:FireClient(player, true) -- Display UI that was hiden in game
	task.wait(0.2)
	player:LoadCharacter() -- Teleport winner to lobby
	task.wait(0.2)

	--// Display Winner //--
	for i, plr in pairs(game:GetService("Players"):GetChildren()) do
		local newef = plr.PlayerGui.Effect.Frame.Win -- Get frame
		local play = plr.PlayerGui.Effect.Win -- Get sfx
		play:Play() -- Play sfx
		newef.Text = player.Name .." Won!" -- Display text
		newef.Visible = true -- Frame visible
	end

	--// Award Player //--
	local profile = dataManager.GetProfile(player) -- Get profile
	if profile and profile.Data then
		profile.Data.Leaderstats.Wins += 1 -- Give Wins
		profile.Data.Leaderstats.Coins += (100 + tonumber(player.Data.Values.WinBonus.Value)) * profile.Data.Values.Multi -- Award Coins * 2 if double coins gamepass owned else 1
		--// Award 50% More For Premium Membership //--
		if player.MembershipType == Enum.MembershipType.Premium then 
			profile.Data.Leaderstats.Coins += ((100 + tonumber(player.Data.Values.WinBonus.Value)) / coins.Value) * profile.Data.Values.Multi
		end
	end
	
	WaitForMorePlayers() -- call fuction to start another round
end

--// Game Ender Function //--
local function EndGame()
	for i, plr in pairs(Players:GetChildren()) do
		plr.PlayerGui.Revenge.Frame.Visible = false -- unvisiblethe revenge product ui
	end
	
	for i, char in pairs(inGame:GetChildren()) do
		local plr = Players:GetPlayerFromCharacter(char)
		if plr then
			AwardWinner(plr) -- award remaining player
		end
	end
	
	--// End round and destroy map //--
	roundModule.EndTheRound()
	Map:Destroy()
	task.wait(3)
	CheckPlayerCount()
end

--// Count Players In Game Function //--
local function CountPlayesInGame()
	plrCount = CountPlayersInFolder(inGame)

	if plrCount <= 1 then
		EndGame() -- there are not enough players ingame end round
	else
		return
	end
end

--// Player Count Checker Function //--
function CheckPlayerCount()
	local matchable = CountPlayesInGame()
	if matchable then
		return -- if there are enough players return
	end

	--// If there aren't enough players //--
	if Map then -- if map found destroy it and end round
		roundModule.EndTheRound()
		Map:Destroy()
	end

	WaitForMorePlayers()
end

--// Award Killer Function //--
local function AwardKiller(curPotato)
	if curPotato.Killer.Value == "" then
		return -- if there is no killer then return
	end
	
	local killer = Players:FindFirstChild(curPotato.Killer.Value)
	if not inGame:FindFirstChild(killer.Name) or not curPotato.Parent  then
		return -- if killer is not in round then return
	end
	
	local killerProfile = dataManager.GetProfile(killer)
	if not killerProfile or not killerProfile.Data then
		return --if killer profile is not found then return
	end
	
	--// Award Killer //--
	killerProfile.Data.Leaderstats.Kills += 1
	killerProfile.Data.Leaderstats.Coins += (10 + tonumber(killer.Data.Values.KillBonus.Value)) * killerProfile.Data.Values.Multi
	if killer.MembershipType == Enum.MembershipType.Premium then -- if killer has premium membership then give %50 more
		killerProfile.Data.Leaderstats.Coins += ((10 + tonumber(killer.Data.Values.KillBonus.Value)) / coins.Value) * killerProfile.Data.Values.Multi
	end
	
	--// Play Sfx and Display victim //--
	local newef = killer.PlayerGui.Effect.Frame.Kill
	local play = killer.PlayerGui.Effect.Kill
	play:Play()
	newef.Visible = true
	newef.Text = "YOU KILLED "  ..curPotato.Parent.Name
	
	-- save killer to give player ability to take revenge
	if Players:FindFirstChild(curPotato.Parent.Name):FindFirstChild("Data") then
		Players:FindFirstChild(curPotato.Parent.Name).Data.Values.Killed.Value = killer.Name
	end
end

--// Blow Potato Holder Function //--
local function BlowPotato(curPotato)
	if curPotato and curPotato.Parent then
		AwardKiller(curPotato) -- award killer
		
		--// Kill Potato Holder //--
		local expo = Instance.new("Explosion", curPotato.Parent)
		expo.Position = curPotato.Parent:FindFirstChild("HumanoidRootPart").Position
		expo.BlastRadius = 0.8
		curPotato:Destroy() -- Destroy potato
	end
end

--// In Game Function //--
function InGame()
	while true do
		CountPlayesInGame() -- count if there are enough players
		
		--// select random player to have the potato //--
		local random = math.random(1, plrCount)
		local ingame = inGame:GetChildren()
		local curPotato = potato:Clone()
		
		--// Give potato //--
		curPotato.Parent = ingame[random]
		curPotato.Parent:WaitForChild("HumanoidRootPart").Feedback.Potato.Visible = true -- display icon on the character
		curPotato.Parent:WaitForChild("Humanoid").WalkSpeed += curPotato.Parent:WaitForChild("Humanoid").WalkSpeed / 20 --give speed buff for fairness
		local highlight = ReplicatedStorage.Highlight:Clone() -- Highlight player
		highlight.Parent = curPotato.Parent
		
		local plrCountLast = CountPlayersInFolder(inGame) -- player count before the potato start to heat
		local t = 15
		while t > 0 do
			plrCount = CountPlayersInFolder(inGame)
			if not curPotato or not curPotato.Parent then -- if no potato then return (to avoid unexpected behavior)
				break
			end
			if plrCount < plrCountLast and curPotato.Parent and not inGame:FindFirstChild(curPotato.Parent.Name) then -- if potato holder died before potato exploded then return
				break
			end
			
			CountPlayesInGame() -- if there are enough players
			
			--// display timer and play clock  sfx //--
			gameText.Value = ""..t
			ReplicatedStorage.SfxEvents.Clock:FireAllClients(t)
			task.wait(1)
			t -= 1
		end
		CountPlayesInGame() -- count if there are enough players
		BlowPotato(curPotato) -- blow the potato
		task.wait(1)
	end
end

WaitForMorePlayers() -- start server by waiting for more players
