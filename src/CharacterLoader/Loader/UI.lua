local plugin = script:FindFirstAncestorWhichIsA("Plugin")
local UI = {}

--- Creates a new UI state for the plugin.
-- @param request_spawn A function that when called spawns a character.
-- @return state The UI state. It should be passed to other UI functions.
function UI.init(request_spawn)
	-- create and configure our widget
	local widget = plugin:CreateDockWidgetPluginGui("SuperCharacterLoader",
		DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Left, -- initial state
			false, -- whether visible on start
			true, -- whether it overrides previous visible state
			150, -- init width when float
			210, -- init height when float
			100, -- min width 
			100 -- min height
		)
	)
	widget.Title = "Super Character Loader"
	
	-- instantiate our UI (currently template-based)
	local ui = plugin.CharacterLoader.Frame:Clone()
	ui.Parent = widget
	
	-- create our state object
	local state = {
		active = false,
		current_id = nil,
		first_load = false,
		spawn_at_origin = false,
		input_valid = false,
		
		widget = widget,
		ui = ui,
		
		request_spawn = request_spawn
	}
	
	-- voila
	return state
end

--- Destroys and clears an UI state, making it invalid.
-- @param state The UI state to be cleared.
function UI.clear(state)
	UI.toggle(state, false)
	
	state.ui:Destroy()
	state.ui = nil
	state.widget:Destroy()
	state.widget = nil
end

--- Connects any necessary events to an UI state.
-- @param state The UI state to be connected.
function UI.hook(state)
	local contents = state.ui.Contents
	
	-- UI element events
	contents.Buttons.LoadR6.Activated:Connect(function()
		if not (state.current_id and state.input_valid and state.active) then
			if not (state.current_id and state.input_valid) then
				warn("[ERROR] Super Character Loader: please input a valid player name or ID.")
			end
			return
		end
		state.request_spawn(state.current_id, true, state.spawn_at_origin)
	end)
	contents.Buttons.LoadR15.Activated:Connect(function()
		if not (state.current_id and state.input_valid and state.active) then
			if not (state.current_id and state.input_valid) then
				warn("[ERROR] Super Character Loader: please input a valid player name or ID.")
			end
			return
		end
		state.request_spawn(state.current_id, false, state.spawn_at_origin)
	end)
	contents.AtOrigin.Check.Checkmark.Activated:Connect(function() UI._toggle_at_origin(state) end)
	contents.PlrName.Field.FocusLost:Connect(function() UI._on_input_focus_lost(state) end)
	contents.PlrName.Field:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		-- keeps the input text under a fixed proportion (TextScaled makes it shrink when it gets long)
		local plr_field = contents.PlrName.Field
		plr_field.TextSize = 17/22 * plr_field.AbsoluteSize.Y
	end)
	
	-- widget events
	state.widget:BindToClose(function() UI.toggle(state, false) end)
	
	-- initial state
	UI._sync_theme(state)
	UI._update_origin_check(state)
	settings().Studio.ThemeChanged:Connect(function() UI._sync_theme(state) end)
end

--- Toggles visibility of a state or sets it to a supplied argument.
-- @param state The UI state to toggle visibility.
-- @param force_visible If supplied, sets the UI state's visibility to it.
-- @return visible The new visible state.
function UI.toggle(state, force_visible: boolean?): boolean
	if force_visible ~= nil then
		state.active = state.force
	else
		state.active = not state.active
	end

	if state.active and not state.first_load then
		-- we do this for the courtesy of not doing web requests at boot
		state.first_load = true
		UI._on_input_focus_lost(state)
	end

	state.widget.Enabled = state.active
	return state.active
end

-- Synchronizes a UI state to studio's theme.
function UI._sync_theme(state)
	local ui = state.ui
	
	local theme = settings().Studio.Theme

	-- we unfortunately have to update everything manually
	local bg = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
	local text = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	local dim_text = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText)
	local border = theme:GetColor(Enum.StudioStyleGuideColor.Border)
	local input_bg = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
	local button = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton)
	local button_border = theme:GetColor(Enum.StudioStyleGuideColor.DialogButtonBorder)
	local button_text = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText)
	local input_border = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder)

	ui.BackgroundColor3 = bg
	ui.Contents.Title.TextColor3 = text
	ui.Contents.Preview.Icon.BorderColor3 = border
	ui.Contents.Preview.Icon.BackgroundColor3 = bg

	UI._update_name_field_border(state)
	ui.Contents.PlrName.Field.BackgroundColor3 = input_bg
	ui.Contents.PlrName.Field.TextColor3 = text
	ui.Contents.PlrName.Field.PlaceholderColor3 = dim_text

	ui.Contents.AtOrigin.Check.Checkmark.BackgroundColor3 = input_bg
	ui.Contents.AtOrigin.Check.Checkmark.BorderColor3 = input_border

	ui.Contents.Buttons.LoadR6.BackgroundColor3 = button
	ui.Contents.Buttons.LoadR6.BorderColor3 = button_border
	ui.Contents.Buttons.LoadR6.TextLabel.TextColor3 = button_text

	ui.Contents.Buttons.LoadR15.BackgroundColor3 = button
	ui.Contents.Buttons.LoadR15.BorderColor3 = button_border
	ui.Contents.Buttons.LoadR15.TextLabel.TextColor3 = button_text

	ui.Contents.AtOrigin.Text.Label.TextColor3 = text
end

-- Updates the player preview.
function UI._update_preview_thumbnail(state)
	if state.current_id then
		state.ui.Contents.Preview.Icon.Image = "rbxthumb://type=AvatarHeadShot&w=150&h=150&id="..state.current_id
	end
end

-- Updates the name input field's border depending on whether the input is valid or not.
function UI._update_name_field_border(state)
	local theme = settings().Studio.Theme
	if state.input_valid then
		state.ui.Contents.PlrName.Field.BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder)
	else
		state.ui.Contents.PlrName.Field.BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText)
	end
end

-- Updates the "Spawn at (0,0,0)" checkmark.
function UI._update_origin_check(state)
	local button = state.ui.Contents.AtOrigin.Check.Checkmark
	button.ImageTransparency = state.spawn_at_origin and 0 or 1
end

-- Toggles the spawn at origin checkmark.
function UI._toggle_at_origin(state)
	state.spawn_at_origin = not state.spawn_at_origin
	UI._update_origin_check(state)
end

-- Fires when the name field is changed by the user.
function UI._on_input_focus_lost(state)
	local Fetcher = require(script.Parent.Fetcher)
	local id = Fetcher.get_id(state.ui.Contents.PlrName.Field.Text)
	if id then
		state.current_id = id
		state.input_valid = true
		UI._update_name_field_border(state)
		UI._update_preview_thumbnail(state)
	else
		state.input_valid = false
		UI._update_name_field_border(state)
	end
end

return UI