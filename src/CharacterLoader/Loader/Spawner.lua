local Players = game:GetService("Players")

local Spawner = {}

--- Takes a player id and creates a character model from it.
-- @param id The player id to load the character from.
-- @param is_r6 Whether the character being created should be R6, R15 otherwise.
-- @return success Whether the character creation succeeded.
-- @return result The character model if the creation succeeded, or an error message otherwise.
function Spawner.load_character(id: number, is_r6: boolean): (boolean, Model | string)
	-- why do we not use CreateHumanoidModelFromUserId? we offer our users the
	-- opportunity to specify the RigType, which is impossible to declare with
	-- CreateHumanoidModelFromUserId.
	local success, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, id)
	if not success then
		return false, "could not fetch character data. Error: "..desc
	end
	
	local rig_type = is_r6 and Enum.HumanoidRigType.R6 or Enum.HumanoidRigType.R15
	local asset_verification = Enum.AssetTypeVerification.Default
	
	local success, model = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, rig_type, asset_verification)
	if not success then
		return false, "could not create character model. Error: "..model
	end
	
	-- make sure the model has a PrimaryPart
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChild("Humanoid").RootPart
	end

	-- quickly go over all locked parts and unlock them
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Locked = false
		end
	end

	-- also delete any scripts so the plugin doesn't trigger any security checks
	for _, scr in ipairs(model:GetDescendants()) do
		if scr:IsA("BaseScript") then
			scr:Destroy()
		end
	end
	
	-- we do not have access to the player name, and default characters are named 'erik.cassel' or 'Player'
	model.Name = "Character"
	
	return true, model
end

--- Takes a model and positions it 5 studs in front of the camera or at the origin.
-- @param character The character model to be positioned.
-- @param at_origin Whether to place the character at the origin.
function Spawner.position_character(character: Model, at_origin: boolean) 
	if at_origin then
		character:SetPrimaryPartCFrame(CFrame.new())
	else
		local pos = (workspace.CurrentCamera.CFrame * CFrame.new(0,0,-5)).Position
		character:SetPrimaryPartCFrame(CFrame.new(pos))
	end
end

return Spawner