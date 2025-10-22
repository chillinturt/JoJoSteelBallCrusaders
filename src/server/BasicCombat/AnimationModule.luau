-- AnimationModule.lua
local AnimationModule = {}

-- Play an animation on a Humanoid or AnimationController
function AnimationModule.PlayAnimation(entity, animationId, looped, priority, speed)
	local humanoid = entity:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

	-- Fallback to AnimationController (for Stand or similar non-Humanoid models)
	if not animator then
		local controller = entity:FindFirstChildOfClass("AnimationController")
		if controller then
			animator = controller:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = controller
			end
		else
			return nil
		end
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. animationId

	local track = animator:LoadAnimation(animation)
	track.Looped = looped or false
	track.Priority = priority or Enum.AnimationPriority.Action
	track:AdjustSpeed(speed or 1) -- ✅ fallback to normal speed if not specified
	track:Play()
	track:AdjustSpeed(speed or 1) -- ✅ fallback to normal speed if not specified

	return track
end

-- ✅ Stop an animation by track reference
function AnimationModule.StopAnimation(track)
	if track and track.IsPlaying then
		track:Stop()
	end
end

-- ✅ Stop all animations for a given entity
function AnimationModule.StopAllAnimations(entity)
	local animationController = entity:FindFirstChildOfClass("AnimationController")
	local animator
	if not animationController then
		local humanoid = entity:FindFirstChildOfClass("Humanoid")
		if humanoid then
			animator = humanoid:FindFirstChildOfClass("Animator")
		end
	else
		animator = animationController:FindFirstChildOfClass("Animator")
	end
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop()
		end
	end
end

return AnimationModule

--[[
Back Roll: 71493580132157
80938111042689
Forward Roll: 116488788576301
96767618650505
104714640622145
121074387087243
Landing: 74308587429244
Left Roll: 119476538755231
127264779281230
Right Roll: 129728193718537
137936019211555
132491977508603
85261901059169
74432122888392
]]
