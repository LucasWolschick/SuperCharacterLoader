local UI = require(script.UI)
local Spawner = require(script.Spawner)
local Selection = game:GetService("Selection")

local button = plugin:CreateToolbar("Super Character Loader"):CreateButton(
	"SuperCharacterLoaderLoad",
	"Load a Roblox player character into your game",
	"rbxassetid://6217910997",
	"Super Character Loader"
)

local ui_state

function spawn_character(id: number, is_r6: boolean, at_origin: boolean)
	local success, result = Spawner.load_character(id, is_r6)
	
	if not success then
		warn("[ERROR] Super Character Loader: "..result)
		return
	end
	
	Spawner.position_character(result, at_origin)
	result.Parent = workspace
	Selection:Set({result})
end

ui_state = UI.init(spawn_character)
UI.hook(ui_state)

plugin.Unloading:Connect(function()
	UI.toggle(ui_state, false)
	UI.clear(ui_state)
	ui_state = nil
end)

plugin.Deactivation:Connect(function()
	UI.toggle(ui_state, false)
	button:SetActive(false)
end)

button.Click:Connect(function()
	local active = UI.toggle(ui_state)
	button:SetActive(active)
end)