--!strict
--!nolint LocalShadow

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

local Client = RunService:IsClient()
local Server = RunService:IsServer()

local KNIVETOOLTIPS = require("./KniveToolTips")
type config = KNIVETOOLTIPS.config

local Instance = Instance

local KTH = {}
KTH.__index = KTH

function KTH.new(Player:Player)
	local self = {}
	setmetatable(self, KTH)
	self.config = nil :: config?

	self.Equipped = false
	self.swinging = false
	
	self.loadedAnimations = {} :: {[string]:Animation}
	self.Player = Player
	
	return self
end

type KTH = typeof(KTH.new(nil::any))

function KTH:Set(CONFIG: config)
	local self = self :: KTH
	self.config = CONFIG :: config
	
	for id:string, str: string in pairs(CONFIG.animations) do
		local animation = Instance.new("Animation")
		animation.AnimationId = str
		ContentProvider:PreloadAsync({animation})
		self.loadedAnimations[id] = animation
	end
end

function KTH:Equip()
	local self = self :: KTH
	if self.config == nil then return end
	self.Equipped = true
end

function KTH:Unequip()
	local self = self :: KTH
	if self.config == nil then return end
	self.Equipped = false
end

function KTH:CreateHitbox()
	local self = self :: KTH
	local config = self.config :: config
	local SWING_DAMAGE = config.swing_damage

	if not Server or config == nil then
		return
	end

	local Character = self.Player.Character
	if not Character then
		return
	end

	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
	local Root = Character:FindFirstChild("HumanoidRootPart")

	if not Humanoid or Humanoid.Health <= 0 then
		return
	end

	if not Root or not Root:IsA("BasePart") then
		return
	end

	-- Box extends forward from the character.
	local Reach = math.max(config.swing_reach, 0)
	local Area = math.max(config.swing_area, 0)

	if Reach <= 0 or Area <= 0 then
		return
	end

	local HitboxSize = Vector3.new(Area, Area, Reach)
	local HitboxCFrame = Root.CFrame * CFrame.new(0, 0, -Reach / 2)

	local OverlapParams = OverlapParams.new()
	OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
	OverlapParams.FilterDescendantsInstances = {Character}

	local Parts = workspace:GetPartBoundsInBox(
		HitboxCFrame,
		HitboxSize,
		OverlapParams
	)

	local HitHumanoids: {[Humanoid]: boolean} = {}

	for _, Part in Parts do
		local Target = Part:FindFirstAncestorOfClass("Model")

		if not Target or Target == Character then
			continue
		end

		local TargetHumanoid =
			Target:FindFirstChildWhichIsA("Humanoid")

		if not TargetHumanoid or TargetHumanoid.Health <= 0 then
			continue
		end

		if HitHumanoids[TargetHumanoid] then
			continue
		end

		HitHumanoids[TargetHumanoid] = true

		-- Don't damage the attacker's own character.
		if Players:GetPlayerFromCharacter(Target) == self.Player then
			continue
		end

		TargetHumanoid:TakeDamage(SWING_DAMAGE)
	end
end

function KTH:Swing()
	local self = self :: KTH
	
	if self.config == nil then return end
	if self.Equipped == false then return end
	if self.swinging then return end
	
	
	self.swinging = true
	task.delay(self.config.swing_complete, function()
		self.swinging = false
	end)
	
	if Client then
		local animation = self.loadedAnimations["swing_animation"]
		if not animation then
			return
		end
		local Character = self.Player.Character
		if not Character then
			return
		end
		
		local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
		if not Humanoid then
			return
		end
		
		local Animator = Humanoid:FindFirstChildWhichIsA("Animator")
		if not Animator then
			return
		end
		
		local anim = Animator:LoadAnimation(animation)
		if anim then
			anim:Play(0.2, 0.2, 1)
		end
		
	elseif Server then
		task.delay(self.config.swing_area_animation_stall, function()
			if not self.Equipped or self.Player.Character == nil then
				return
			end

			self:CreateHitbox()
		end)	
	end
end

return KTH