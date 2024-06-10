--[[
-- Made by Aweb. if you have any questions, feel free to dm me or mention me in developer channel. Username: awebgamedev
-- It's highly recommended to not edit this without my premission as it will result in unexpected bugs, if you have any suggestion please suggest them to me and I'll add them
-- I tried my best to make things clear as much as possible with comments, so if you don't get something read the comments
-- If you still can't get what's happening here I'm gonna have a documentation wroten you can check that out or simply ask me in discord


]]--


--// Setvices //--
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

--// Variables //--
local offsetMultiplier = script.OffsetMultiplier

local uiParts = replicatedStorage.UiParts
local uiBoards = replicatedStorage.UiBoards

--// TweenInfo //--
local transparencyTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0)

local GuiPopup = {}

--// Local Functions //--
--// Tweens //--
local function animateBillboard(billboard, openOrClose, sizeUDim2)
	local size = tweenService:Create(billboard, TweenInfo.new(0.1), {Size = sizeUDim2})
	size:Play()
end

local function fadeInOut(billboard, openOrClose)
	local transparencyValue = openOrClose and 0 or 1
	for _, child in ipairs(billboard:GetDescendants()) do
		if child:IsA("ImageLabel") then
			local tween = tweenService:Create(child, transparencyTweenInfo, {ImageTransparency = transparencyValue})
			tween:Play()
		elseif child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
			local tween = tweenService:Create(child, transparencyTweenInfo, {Transparency = transparencyValue})
			tween:Play()
		end
	end
end

--// Positioning Ui //--
local function positionUi(uiElement, humanoidRootPart, distance, offset)
	local targetPosition = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 10 + offset
	uiElement.Position = targetPosition

	local weld = Instance.new("WeldConstraint")
	weld.Parent = humanoidRootPart
	weld.Part0 = humanoidRootPart
	weld.Part1 = uiElement
end

--// Adornee Billboard //--
local function adornee(character:Model, billboard:BillboardGui, uiPart:BasePart)
	local billboardUi = billboard:Clone()

	billboardUi.Parent = character.GuiClient.BillBoards
	billboardUi.Adornee = uiPart
	billboardUi.Enabled = true
	
	return billboardUi
end

--// Module Functions //--
function GuiPopup:loadGui(player:Players, character:Model)
	for i, uiPart in pairs(uiParts:GetChildren()) do
		local uiPart = uiPart:Clone()
		uiPart.Parent = character
		positionUi(uiPart, character:WaitForChild("HumanoidRootPart"), uiPart.Distance.Value, uiPart.Offset.Value)

		local billboard = uiBoards:FindFirstChild(uiPart.Name)
		local billboardUi = adornee(character, billboard, uiPart)

		fadeInOut(billboardUi, false)
	end
end

--// Interaction Open/Close //--
function GuiPopup:interactUi(character , uiName:StringValue, open:boolean)
	local billboard = character:FindFirstChild("GuiClient").BillBoards:FindFirstChild(uiName)
	
	local targetSize
	
	if open then
		targetSize = billboard:GetAttribute("Size")
	else
		targetSize = UDim2.new(billboard.Size.X.Scale * offsetMultiplier.Value, 0, billboard.Size.Y.Scale * offsetMultiplier.Value, 0)
	end
	
	print(targetSize)
	
	animateBillboard(billboard, open, targetSize)
	fadeInOut(billboard, open)
end


return GuiPopup
