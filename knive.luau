local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tool = script.Parent :: Tool
local KTH = require(ReplicatedStorage.Access.Value:WaitForChild("KniveToolHandler").Value)

local Player: Player? = nil
local object: any = nil

local function GetPlayer(): Player?
	if RunService:IsClient() then
		return Players.LocalPlayer
	end

	local Character = Tool.Parent

	if Character:IsA("Model") then
		return Players:GetPlayerFromCharacter(Character)
	end

	return nil
end

local config = {
	swing_reach = 10,
	swing_area = 10,
	swing_damage = 10,
	swing_area_animation_stall = 0,
	swing_complete = 0.1,

	animations = {
		swing_animation = "rbxassetid://138042218482923" -- Replace with a valid animation ID.
	}
}

local function Setup()
	Player = GetPlayer()

	if not Player then
		return
	end

	object = KTH.new(Player)
	object:Set(config)
end

Tool.Equipped:Connect(function()
	if not object then
		Setup()
	end

	if object then
		object:Equip()
	end
end)

Tool.Unequipped:Connect(function()
	if object then
		object:Unequip()
	end
end)

Tool.Activated:Connect(function()
	if object then
		object:Swing()
	end
end)

Setup()