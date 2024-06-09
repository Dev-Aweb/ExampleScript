--if not game:IsLoaded() then game.Loaded:Wait() end
--// Services //--

local DataStore			 = game:GetService("DataStoreService")

local PlayerDS			 = DataStore:GetDataStore("WFS_PLAYERS_DATA")

local ServerScript		 = game:GetService("ServerScriptService")

local MarketplaceService	 = game:GetService("MarketplaceService")

local HttpService		 = game:GetService("HttpService")

local CollectionService	 = game:GetService("CollectionService")

local ReplicatedStorage	 = game:GetService("ReplicatedStorage")

local Lightning			 = game:GetService("Lighting")

local ServerScriptService = game:GetService("ServerScriptService")

local dataManager = require(ServerScriptService.Modules.DataManager)

local RobuxHandle = require(ServerScriptService.Modules.RobuxHandle)

local roundModule 		= require(ServerScriptService.GameManager.RoundSystem)

local Remote 		 = require(ReplicatedStorage.Modules.Framework.RemoteManger)

local GameText = game.Workspace.Stat

local potato = ReplicatedStorage.Potato

local currentVotes	 = {}

local Map

local function awardPointsAndWins(player:Player)
	GameText.Value = ""
	player.PlayerGui.MainGui.Buttons.Visible = true
	game.ReplicatedStorage.HideTopBar:FireClient(player, true)
	task.wait(0.2)
	player:LoadCharacter()
	task.wait(0.2)
	for i, plr in pairs(game:GetService("Players"):GetChildren()) do
		local newef = plr.PlayerGui.Effect.Frame.Win
		local play = plr.PlayerGui.Effect.Win
		play:Play()
		newef.Text = player.Name .." Won!"
		newef.Visible = true
	end
	
	local newef = player.PlayerGui.Effect.Frame.Win
	local play = player.PlayerGui.Effect.Win
	play:Play()
	newef.Text = player.Name .." Win!"
	newef.Visible = true

	local profile = dataManager.GetProfile(player)
	if profile and profile.Data then
		profile.Data.Leaderstats.Wins += 1
		profile.Data.Leaderstats.Coins += (100 + tonumber(player.Data.Values.WinBonus.Value)) * profile.Data.Values.Multi
		if player.MembershipType == Enum.MembershipType.Premium then
			profile.Data.Leaderstats.Coins += ((100 + tonumber(player.Data.Values.WinBonus.Value)) / 2) * profile.Data.Values.Multi
		end
	end
end

function countPlayersInFolder(folder)
	local playerCount = 0

	local children = folder:GetChildren()

	for _, child in ipairs(children) do
		--if child:IsA("Player") then
			playerCount += 1
		--end
	end

	return playerCount
end

local ts = game:GetService("TweenService")
local function emit(part) -- part is the parent of all your vfx
	for i, v in part:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
			task.spawn(function()
				if v:GetAttribute("EmitDelay") then
					task.wait(v:GetAttribute("EmitDelay"))
				end
				if v:GetAttribute("EmitCount") then
					v:Emit(v:GetAttribute("EmitCount"))
				end
			end)

		elseif v:IsA("Beam") then
			v.Enabled = true
			if v:GetAttribute("Width0") and v:GetAttribute("Width1") and v:GetAttribute("Duration") then
				task.spawn(function()
					if v:GetAttribute("EmitDelay") then
						task.wait(v:GetAttribute("EmitDelay"))
					end

					v.Width0 = 0
					v.Width1 = 0

					ts:Create(v, TweenInfo.new(v:GetAttribute("Duration"), Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0, true), {Width0 = v:GetAttribute("Width0"), Width1 = v:GetAttribute("Width1")}):Play()

				end)
			end 
		end
	end
end

local function PickingMapSystemV2()
	local MapTable = ReplicatedStorage.Maps:GetChildren()
	local mapObject = MapTable[math.random(1, #MapTable)]
	local roundMap = mapObject:Clone()
	roundMap.Parent = workspace.RoundKeeper.MapChosen
	game.ReplicatedStorage.RoundValues.Status:SetAttribute("MapSelected",roundMap.Name)
	return roundMap
end

while true do
	task.wait(1)
	local afked = 0
	for _, plr in pairs(game.Players:GetChildren()) do
		if plr:WaitForChild("Data").Values.Afk.Value == true then
			afked += 1
		end
	end
	plrCount = countPlayersInFolder(game.Players) - afked
	print(plrCount, afked)
	if plrCount <= 1 then
		GameText.Value = "Waiting for more players"
		task.wait(1)
	else
		t = 15
		while t > 0 do
			t -= 1
			GameText.Value = "Intermission.. "..t
			task.wait(1)
		end
		
		local afked = 0
		for _, plr in pairs(game.Players:GetChildren()) do
			if plr:WaitForChild("Data").Values.Afk.Value == true then
				afked += 1
			end
		end
		
		plrCount = countPlayersInFolder(game.Players) - afked
		if plrCount > 1 then
			GameText.Value = "Voteing for map.."
			
			roundModule.ReadyUpMaps()
			roundModule.toggleVoting("Map")
			task.wait(8)
			Map = roundModule.loadMap()

			if not Map then
				Map = PickingMapSystemV2()
				warn("THERE IS PROBLEM WITH THE MAP PICKING")
			end
			
			GameText.Value = "Map chosen, the map is " ..Map.Name
			
			task.wait(3)
			local modselect = game.ReplicatedStorage.Mods:GetChildren()
			local choose = math.random(1, #modselect)
			local plrs = game.Players:GetChildren()
			
			for i = 1, #plrs do
				if plrs[i].Data and plrs[i].Data.Values.Afk.Value == false and plrs[i].Character then
					plrs[i].Character:WaitForChild("Humanoid").WalkSpeed = modselect[choose].Speed.Value
					plrs[i].Character:WaitForChild("Humanoid").JumpPower = modselect[choose].Jump.Value
					if plrs[i].MembershipType == Enum.MembershipType.Premium then
						plrs[i].Character:WaitForChild("Humanoid").WalkSpeed = modselect[choose].Speed.Value + modselect[choose].Speed.Value / 10
					end
				end
			end
			
			GameText.Value = "Mod chosen, the mod is " ..modselect[choose].Name ..". Get ready!"
			task.wait(3)
			local afked = 0
			for _, plr in pairs(game.Players:GetChildren()) do
				if plr:WaitForChild("Data").Values.Afk.Value == true then
					afked += 1
				end
			end
			plrCount = countPlayersInFolder(game.Players) - afked
			local plrs = game.Players:GetChildren()
			if plrCount > 1 then
				for i = 1, #plrs do
					if plrs[i].Data and plrs[i].Data.Values.Afk.Value == false and plrs[i].Character then
						local num = math.random(1, 24)
						plrs[i].Character.Head.CFrame = CFrame.new(workspace.Teleport["Part"..num].Position)
						plrs[i].Character.Parent = workspace.Ingame
						plrs[i].PlayerGui.MainGui.Buttons.Visible = false
						game.ReplicatedStorage.HideTopBar:FireClient(plrs[i], false)
					end
				end
				while true do
					plrCount = countPlayersInFolder(game.Workspace.Ingame)
					if plrCount <= 1 then
						break
					end
					random = math.random(1, plrCount)
					local ingame = workspace.Ingame:GetChildren()
					curPotato = potato:Clone()
					curPotato.Parent = ingame[random]
					curPotato.Parent:WaitForChild("HumanoidRootPart").Feedback.Potato.Visible = true
					curPotato.Parent:WaitForChild("Humanoid").WalkSpeed += curPotato.Parent:WaitForChild("Humanoid").WalkSpeed / 20
					local highlight = game.ReplicatedStorage.Highlight:Clone()
					highlight.Parent = curPotato.Parent
					plrCountLast = countPlayersInFolder(game.Workspace.Ingame)
					t = 15
					while t > 0 do
						plrCount = countPlayersInFolder(game.Workspace.Ingame)
						if not curPotato or not curPotato.Parent then
							break
						end
						if plrCount <= 1 then
							break
						end
						if plrCount < plrCountLast and curPotato.Parent and not workspace.Ingame:FindFirstChild(curPotato.Parent.Name) then
							break
						end
						GameText.Value = ""..t
						game.ReplicatedStorage.SfxEvents.Clock:FireAllClients(t)
						task.wait(1)
						t -= 1
					end
					plrCount = countPlayersInFolder(game.Workspace.Ingame)
					if plrCount <= 1 then
						break
					end
					plrCount = countPlayersInFolder(game.Workspace.Ingame)
					print(plrCount)
					if curPotato and curPotato.Parent and plrCount > 1 then
						if curPotato.Killer.Value ~= "" then
							local killer = game.Players:FindFirstChild(curPotato.Killer.Value)
							if workspace.Ingame:FindFirstChild(killer.Name) and curPotato.Parent then
								killerProfile = dataManager.GetProfile(killer)
								if killerProfile and killerProfile.Data then
									killerProfile.Data.Leaderstats.Kills += 1
									killerProfile.Data.Leaderstats.Coins += 1
									killerProfile.Data.Leaderstats.Coins += (10 + tonumber(killer.Data.Values.KillBonus.Value)) * killerProfile.Data.Values.Multi
									if killer.MembershipType == Enum.MembershipType.Premium then
										killerProfile.Data.Leaderstats.Coins += ((10 + tonumber(killer.Data.Values.KillBonus.Value)) / 2) * killerProfile.Data.Values.Multi
									end
									local newef = killer.PlayerGui.Effect.Frame.Kill
									local play = killer.PlayerGui.Effect.Kill
									play:Play()
									newef.Visible = true
									newef.Text = "YOU KILLED "  ..curPotato.Parent.Name
									if game.Players:FindFirstChild(curPotato.Parent.Name):FindFirstChild("Data") then
										game.Players:FindFirstChild(curPotato.Parent.Name).Data.Values.Killed.Value = killer.Name
									end
								end
							end
						end
						local expo = Instance.new("Explosion", curPotato.Parent)
						expo.Position = curPotato.Parent:FindFirstChild("HumanoidRootPart").Position
						expo.BlastRadius = 0.8
						curPotato:Destroy()
					end
					plrCount = countPlayersInFolder(game.Workspace.Ingame)
					if plrCount <= 1 then
						break
					end
					task.wait(1)
				end
				local plrs = game.Players:GetChildren()
				local ingame = workspace.Ingame:GetChildren()
				for i, plr in pairs(plrs) do
					plr.PlayerGui.Revenge.Frame.Visible = false
				end
				for i = 1, #ingame do
					local plr = game.Players:GetPlayerFromCharacter(ingame[i])
					if plr then
						awardPointsAndWins(plr)
					end
				end
				roundModule.EndTheRound()
				Map:Destroy()
				task.wait(3)
			else
				roundModule.EndTheRound()
				Map:Destroy()
			end
		end 
	end
end


