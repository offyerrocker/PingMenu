--v2.0.0

--[[
	TODO
straighten highlight/selected/active item terminology
streamline wrapper class

--allow repositioning text (currently centered from formula: [0.5*radius  +  constant] )

* add keyboard button support
	* item var "key id" for hotkeys

* update add_item and create_item to better definitions	
	* icon definition should be separate
	
--]]

core:module("SystemMenuManager")
require("lib/managers/dialogs/Dialog")
--also requires Hooks library from BLT

local RadialMenuDialog = class(Dialog)



local RadialMenuObject = class()

local RadialMenuManager = {
	queued_items = {},
	_WIKI_URL = "https://github.com/offyerrocker/RadialMouseMenu/wiki",
	_ws = nil,
	log_to_console = true,
	log_to_blt = true,
	log_to_beardlib = false
}
--RadialMenuManager.radial_menu_objects = {}

--====================================
-- RadialMenuManager
--====================================
--this is the table that is returned from loading this file via loadfile
--new objects should be created by using NewMenu() from here,
--since this class basically represents this overall implementation of RadialMenu

function RadialMenuManager:Log(s)
	local msg = "[Radial Menu] " .. tostring(s)
	if self.log_to_console and _G.Console then
		_G.Console:Log(msg)
	end
	if self.log_to_blt then
		_G.log(msg)
	end
--	if self.log_to_beardlib and RadialMenuManager._core then
--		RadialMenuObject._core:Log(msg)
--	end
end

function RadialMenuManager.CreateQueuedMenus()
	for i=#RadialMenuManager.queued_items,1,-1 do
		local data = table.remove(RadialMenuManager.queued_items,i)
	end
end

function RadialMenuManager:CheckCreateWorkspace()
	if _G.managers.gui_data and not alive(RadialMenuManager._ws) then 
		--create classwide workspace if it doesn't already exist
		self._ws = _G.managers.gui_data:create_fullscreen_workspace()
	end
end

function RadialMenuManager:NewMenu(params,...)
	self:CheckCreateWorkspace()
	
	local new_radial_menu = RadialMenuObject:new(self,params,...)
	return new_radial_menu
end

Hooks:Add("BaseNetworkSessionOnLoadComplete","RadialMenu_OnLoaded",RadialMenuManager.CreateQueuedMenus)
--check for creating radial menus on game load, if any have been queued (attempted creation too early)

--====================================
-- RadialMenuObject class
--====================================
--this is a wrapper for the actual dialog object
--mostly it's used to provide a layer of insulation with safety checks, in case the radial menu methods are called before the menu is ready to use

function RadialMenuObject:init(radialmenumanager,params) --constructor
	self._radial_menu_manager = radialmenumanager
	
	params = params or {}
	
	if not _G.managers.gui_data then 
		table.insert(RadialMenuObject.queued_items,1,{params = params})
		--if RadialMenuObject:new() is called after RadialMenu loads but before the rest of the game,
		--save the information for later and create it on game load
		return
	end
	
	self:setup(params)
end

function RadialMenuObject:Log(s)
	return self._radial_menu_manager:Log(tostring(self._id) .. tostring(s))
end

function RadialMenuObject:setup(params) --create new instance of a radial selection menu; called from new()
	
	local class_panel = self._class_panel
	if not alive(class_panel) then 
		class_panel = self._radial_menu_manager._ws:panel()
		self._class_panel = class_panel
	end
	
	local id = params.id --radial id; used for labelling hud elements
	if not id then 
		id = "RadialMenuObject_" .. tostring(self)
		self:Log(string.format("ERROR: Missing id parameter! Please refer to the wiki: %s",self._radial_menu_manager._WIKI_URL))
	end
	self._id = id
	self:CreateDialog({
		id = id,
		parent = self,
		class_panel = class_panel,
		items = params.items,
		size = params.size or 256, --size of radial, NOT the size of the parent panel
		deadzone = params.deadzone, --minimum distance from center the mouse must be in order to select an item
		font = params.font,
		font_size = params.font_size,
		item_margin = params.item_margin,
		texture_highlight = params.texture_highlight,
		texture_darklight = params.texture_darklight,
		texture_cursor = params.texture_cursor,
		focus_alpha = params.focus_alpha or 1,
		unfocus_alpha = params.unfocus_alpha or 0.5,
		animate_focus_grow_size = params.animate_focus_grow_size or 1.66,
		animate_focus_duration = params.animate_focus_duration or 0.33,
		animate_unfocus_duration = params.animate_unfocus_duration or 0.33,
		mouseover_text_visible = params.mouseover_text_visible and true or false,
		item_text_visible = params.item_text_visible and true or false,
		reset_mouse_position_on_show = params.reset_mouse_position_on_show and true or false,
		callback_on_cancelled = params.callback_on_cancelled,
		title = "", --not used
		text = "" --not used
	})
end

function RadialMenuObject:config(params)
	if self._dialog then
		self._dialog:config(params)
	end
end

function RadialMenuObject:GetId()
	return self._id
end

function RadialMenuObject:CreateDialog(dialog_data)
	self._dialog = RadialMenuDialog:new(_G.managers.system_menu,dialog_data)
end

function RadialMenuObject:Show()
	if self._dialog then
		_G.managers.system_menu:_show_instance(self._dialog,true)
	end
end

function RadialMenuObject:Hide(...)
	if self:IsActive() then
		self._dialog:hide(...)
	end
end

function RadialMenuObject:Toggle(state,...)
	if state == nil then 
		state = not self:IsActive()
	end	
	
	if state then 
		self:Show(...)
	else
		self:Hide(...)
	end
end

function RadialMenuObject:IsActive()
	if self._dialog then 
		return self._dialog.is_active
	end
	return nil
end



--====================================
-- RadialMenuDialog class
--====================================

function RadialMenuDialog:init(manager,data,...)
	RadialMenuDialog.super.init(self,manager,data,...)
	
	self._manager = manager --RadialMenuMananger
	self._ws = manager._ws
	
	self._parent = data.parent --parent RadialMenuObject (cannot be changed afterward)
	self._items = {} --populated later
	self._panel = nil --populated later
	self._mouse_id = nil
	self.is_active = false --determines whether this dialog is active and stops gameplay input
	self._input_enabled = false --determines whether this dialog can take input
	
	self._confirm_func = callback(self, self, "button_pressed_callback") --automatic menu input for this is unreliable
	self._cancel_func = callback(self, self, "dialog_cancel_callback")
	
	self:config(data)
	
	self._selected_index = nil
end

function RadialMenuDialog:log(s)
	local msg = string.format("RadialMenuDialog: %s",s)
	return self._parent:Log(s)
end

function RadialMenuDialog:config(data)
	self._data = data
	
	self._callback_on_cancelled = data.callback_on_cancelled
	
	if data.controller_mode_enabled ~= nil then 
		self._controller_mode_enabled = data.controller_mode_enabled --if true, checks the axis movement and selects the item by that angle
	else
		local wrapper_type = _G.managers.controller:get_default_wrapper_type()
		self._controller_mode_enabled = wrapper_type ~= "pc"
	end
	
	self._class_panel = data.class_panel or self._class_panel
	self._controller = data.controller or self._manager:_get_controller() or self._controller
	self:recreate_gui()
end

function RadialMenuDialog:recreate_gui()
	local panel = self._panel
	if alive(panel) then 
		local children = panel:children()
		for i=#children,1,-1 do 
			panel:remove(table.remove(children,i))
		end
--		self._class_panel:remove(self._panel)
	else
		panel = self._class_panel:panel({
			name = self._parent:GetId() .. "_dialog_panel",
			visible = false
		})
		self._panel = panel
	end
	
	--clear existing data
	self._selected_item = nil
	for k,v in pairs(self._items) do 
		self._items[k] = nil
	end
	
	local data = self._data
	--dialog_panel:
		--radial_cursor --free rotating segment. arc segment 
		--background --darklight for category slots
		--item:
			--active_highlight --toggle-visible for active items. arc segment
			--icon --the image primarily representing this button
			
	local HIGHLIGHT_TEXTURE = data.texture_highlight or "guis/dlcs/coco/textures/pd2/hud_absorb_stack_fg"
	local DARKLIGHT_TEXTURE = data.texture_darklight or "guis/textures/pd2/hud_radialbg"
	local CURSOR_TEXTURE = data.texture_cursor or "guis/textures/pd2/hud_shield"
	local radius = data.size
	local icon_distance = radius / 3
	local label_distance = radius / 4
	
	local num_items = #data.items
	local cursor = panel:bitmap({
		name = "cursor",
		texture = CURSOR_TEXTURE,
		rotation = 0,
		w = radius,
		h = radius,
		color = Color.white,
		halign = "grow",
		valign = "grow",
		layer = 5
	})
	local c_x,c_y = panel:center()
	cursor:set_center(c_x,c_y)
	
	local background = panel:bitmap({
		name = "background",
		texture = DARKLIGHT_TEXTURE,
		w = radius,
		h = radius,
		halign = "grow",
		valign = "grow",
		alpha = 0.66,
		layer = 1,
		visible = true
	})
	background:set_center(c_x,c_y)
	
	local mouseover_label = panel:text({
		name = "mouseover_label",
		text = "",
		font = data.font or "fonts/font_medium_shadow_mf",
		font_size = data.font_size or 24,
		align = "center",
		vertical = "center",
		valign = "grow", --halign/valign don't apply to text object font size, only clipping box
		halign = "grow",
		layer = 6,
		visible = data.mouseover_text_visible
	})
	
	local MARGIN_PERCENT = data.item_margin --10% of a slice's theta angle is cut off to create a margin
	for i,item in ipairs(data.items) do 
		local icon_w = item.w or 32
		local icon_h = item.h or 32
		local i_prog = (i - 1) / num_items
		local arc_length = (1 / num_items) * (1 - MARGIN_PERCENT)
		local arc_offset = MARGIN_PERCENT / (num_items * 2)
		local arc_length_col = Color(arc_length,1,0)
		local arc_position = 360 * (i_prog + arc_offset - (0.5 / num_items)) --highlight/darklight position
		local icon_position = (i_prog * 360) - 90 --icon position; centered so it doesn't need the -0.5rad offset
		local x = math.cos(icon_position)
		local y = math.sin(icon_position)
		local icon_x = c_x + (x * icon_distance)
		local icon_y = c_y + (y * icon_distance)
		local label_x = x * label_distance
		local label_y = y * label_distance
		local icon = panel:bitmap({
			name = "icon_" .. i,
			texture = item.texture,
			texture_rect = item.texture_rect,
			w = icon_w,
			h = icon_h,
			color = item.color,
			halign = "grow",
			valign = "grow",
			alpha = data.unfocus_alpha or 0.5,
			layer = 4
--,			visible = i == 1
		})
		icon:set_center(icon_x,icon_y)
		local highlight = panel:bitmap({
			name = "highlight_" .. i,
			texture = HIGHLIGHT_TEXTURE,
			render_template = "VertexColorTexturedRadial",
			w = radius,
			h = radius,
			color = arc_length_col,
			rotation = arc_position,
			halign = "grow",
			valign = "grow",
			layer = 3,
			visible = false --disable unless it's visible
		})
		highlight:set_center(c_x,c_y)
		
		local label = panel:text({
			name = "label_" .. i,
			text = item.text or "",
			font = item.font or "fonts/font_medium_shadow_mf",
			font_size = item.font_size or 24,
			x = label_x,
			y = label_y,
			align = "center",
			vertical = "center",
			valign = "grow",
			halign = "grow",
			layer = 5,
			visible = data.item_text_visible
		})
		
		local darklight = panel:bitmap({
			name = "darklight_" .. i,
			texture = DARKLIGHT_TEXTURE,
			render_template = "VertexColorTexturedRadial",
			w = radius,
			h = radius,
			color = arc_length_col,
			rotation = arc_position,
			halign = "grow",
			valign = "grow",
			layer = 2,
			visible = true --disabled by default
		})
		darklight:set_center(c_x,c_y)
		
		self._items[i] = {
			icon = icon,
			w = icon_w or icon:w(),
			h = icon_h or icon:h(),
			icon_x = icon_x,
			icon_y = icon_y,
			highlight = highlight,
			darklight = darklight,
			label = label,
			text = item.text,
			focus_alpha = data.focus_alpha,
			unfocus_alpha = data.unfocus_alpha,
--			active_color = active_color,
--			inactive_color = inactive_color,
			callback = item.callback
		}
	end
	
end

function RadialMenuDialog:check_select_item(x,y)
	
end

function RadialMenuDialog:update(t,dt)
	self:update_input(t,dt)
end

function RadialMenuDialog:update_input(t,dt)
	if self.is_active then 
		if self._input_enabled then 
--			local dir --"absolute" control- direction as determined by (analog stick direction if using controller mode) or (else mouse position relative to center)
			
--			local move = self._controller:get_input_axis("menu_move")
			local move = self._controller:get_input_axis("look")
			
			if self._controller_mode_enabled then 
				local panel = self._panel
				if alive(panel) then
					
					local cursor = panel:child("cursor")
					local x = move.x
					local y = move.y
--					_G.Console:SetTracker(string.format("%0.2f, %0.2f | %0.1fs",move.x,move.y,t),1)
					
					local new_selected_index = nil
					
					if x ~= 0 or y ~= 0 then
						--no need to check for deadzones on controllers
						--since they use directional (stick vector) input instead of absolute (mouse position)
						--they effectively have deadzones built in
						
						local c_x,c_y = panel:center()
						local m_x,m_y = x - c_x,y - c_y
						local angle = 90 - math.atan(y/x) --0/0 returns nan, but 1/0 works as intended
						if x < 0 then
							angle = angle + 180
						end
						angle = angle % 360
						cursor:set_rotation(angle)
						cursor:set_center(c_x,c_y)
						
						local num_items = #self._items
						
						local angle_interval = 360 / num_items
						new_selected_index = 1 + ((math.round((angle - angle_interval) / angle_interval) + 1) % num_items)
	--					_G.Console:SetTracker(string.format("selected: %i",new_selected_index),2)
	--					_G.Console:SetTracker(string.format("angle: %i",angle),3)
					end
					
					local selected_index = self:get_selected_index()
					if selected_index ~= new_selected_index then
						self:set_selected_index(new_selected_index)
						self:on_mouseover_item(new_selected_index,selected_index)
					end
				end
				
			end
		else
			--skip the first frame of input
			self:set_input_enabled(true)
		end
	end
	
end

function RadialMenuDialog:move_selection(dir) --unused; intended for scrolling behavior
	local selection_index = self._selection_index
	local prev_selection_index = selection_index
	selection_index = ((selection_index + dir) % #self._items) + 1
	self._selection_index = selection_index
	self:callback_set_selection(prev_selection_index,selection_index)
end

function RadialMenuDialog:get_selected_index()
	return self._selected_index
end

function RadialMenuDialog:set_selected_index(index)
	self._selected_index = index
end

function RadialMenuDialog:clear_selected_index()
	self._selected_index = nil
end

function RadialMenuDialog:callback_item_confirmed(index)
	local item_data = index and self._items[index]
	if item_data then
		if not item_data.keep_open then
			self:hide()
		else
			self:clear_selected_index()
		end
		self:_callback_item_confirmed(index,item_data)
	end
end

function RadialMenuDialog:_callback_item_confirmed(index,item_data)
	if item_data and item_data.callback then
		item_data.callback(index,item_data)
	end
	self:animate_mouseover_item_unfocus(index)
end

function RadialMenuDialog:callback_on_cancelled()
	if self._callback_on_cancelled then
		self._callback_on_cancelled(self)
	end
end

function RadialMenuDialog:on_mouseover_item(current_index,previous_index)
	local item_data = current_index and self._items[current_index]
	local prev_data = previous_index and self._items[previous_index]
	if item_data and item_data.text then 
		self:set_mouseover_text(item_data.text)
		if alive(self._panel) then
			if item_data then
				item_data.darklight:hide()
				item_data.highlight:show()
			end
		end
	else
		self:set_mouseover_text("")
	end
	if prev_data then
		prev_data.darklight:show()
		prev_data.highlight:hide()
	end
	self:animate_mouseover_item_focus(current_index)
	self:animate_mouseover_item_unfocus(previous_index)
end

function RadialMenuDialog:set_mouseover_text(s)
	local panel = self._panel
	if alive(panel) then
		local mouseover_label = panel:child("mouseover_label")
		mouseover_label:set_text(s)
	end
end

function RadialMenuDialog:button_pressed_callback()
--	self:log("Button pressed callback")
	--queue hide
end

function RadialMenuDialog:dialog_cancel_callback()
--	self:log("Dialog cancel callback")
end

function RadialMenuDialog:callback_mouse_moved(o,x,y)
	if not self._controller_mode_enabled and alive(self._panel) then
		local cursor = self._panel:child("cursor")
		local c_x,c_y = self._panel:center()
		local m_x,m_y = x - c_x,y - c_y
		local new_selected_index = nil
		
		local deadzoned = false
		if self._data.deadzone then
			local distance = math.sqrt(m_x * m_x + m_y * m_y)
			deadzoned = distance < self._data.deadzone
		end
		
		if not deadzoned then
			
			local angle = math.atan(m_y/m_x) + 90
			if m_x < 0 then
				angle = angle + 180
			end
			angle = angle % 360
			
			cursor:set_rotation(angle)
			cursor:set_center(c_x,c_y)
			local num_items = #self._items
			
			local angle_interval = 360 / num_items
			new_selected_index = 1 + ((math.round((angle - angle_interval) / angle_interval) + 1) % num_items)
	--		_G.Console:SetTracker(string.format("angle: %i",angle),3)
	--		_G.Console:SetTracker(string.format("selected: %i",new_selected_index),2)
	--		_G.managers.mouse_pointer:set_pointer_image("arrow")
			cursor:show()
		else
			cursor:hide()
		end
		
		local selected_index = self:get_selected_index()
		if selected_index ~= new_selected_index then
			self:set_selected_index(new_selected_index)
			self:on_mouseover_item(new_selected_index,selected_index)
		end
	end
--	log("moved " .. tostring(x) .. " " .. tostring(y))
end

function RadialMenuDialog:callback_mouse_pressed(o,button,x,y) --unused
--	self:log("pressed  " .. tostring(x) .. " " .. tostring(y))
end

function RadialMenuDialog:callback_mouse_released(o,button,x,y)
--	self:log("released  " .. tostring(x) .. " " .. tostring(y))
	if button == Idstring("0") then
		self:callback_item_confirmed(self:get_selected_index())
	elseif button == Idstring("1") then 
		self:hide()
	end
end

function RadialMenuDialog:callback_mouse_clicked(o,button,x,y) --don't use this
--	self:log("Mouse clicked")
	--this callback is called whenever the mouse is released after clicking.
	--but it isn't capable of checking whether the mouseover object is the same one from when the mouse was pressed.
	--and by definition a mouse must always first press before releasing. that is how clicks work.
	--also it's executed after release instead of before.
	--so it's completely worthless to me.
end

function RadialMenuDialog:set_input_enabled(enabled)
	local controller = self._controller
	local controller_mgr = _G.managers.controller
	local mouse_pointer_mgr = _G.managers.mouse_pointer
	if not self._input_enabled ~= not enabled then
		if enabled then
			controller:add_trigger("confirm", self._confirm_func)

			if controller_mgr:get_default_wrapper_type() == "pc" or controller_mgr:get_default_wrapper_type() == "steam" or controller_mgr:get_default_wrapper_type() == "vr" then
				controller:add_trigger("toggle_menu", self._cancel_func)

				self._mouse_id = mouse_pointer_mgr:get_id()
				self._removed_mouse = nil
				local data = {
					mouse_move = callback(self, self, "callback_mouse_moved"),
					mouse_press = callback(self, self, "callback_mouse_pressed"),
					mouse_release = callback(self, self, "callback_mouse_released"),
					mouse_click = callback(self, self, "callback_mouse_clicked"), --don't use this
					id = self._mouse_id
				}
--				self._ws:connect_keyboard(Input:keyboard())
--				self._input_text:key_press(callback(self, self, "callback_key_press"))
--				self._input_text:key_release(callback(self, self, "callback_key_release"))

				
				mouse_pointer_mgr:use_mouse(data)
			else
				self._removed_mouse = nil

				controller:add_trigger("cancel", self._cancel_func)
				mouse_pointer_mgr:disable()
			end
		else
--			self._ws:disconnect_keyboard()
--			self._panel:key_release(nil)
			controller:remove_trigger("confirm", self._confirm_func)

			if controller_mgr:get_default_wrapper_type() == "pc" or controller_mgr:get_default_wrapper_type() == "steam" or controller_mgr:get_default_wrapper_type() == "vr" then
				controller:remove_trigger("toggle_menu", self._cancel_func)
			else
				controller:remove_trigger("cancel", self._cancel_func)
			end

			self:remove_mouse()
		end

		self._input_enabled = enabled

		controller_mgr:set_menu_mode_enabled(enabled)
	end
end

function RadialMenuDialog:remove_mouse()
	local controller_mgr = _G.managers.controller
	local mouse_pointer_mgr = _G.managers.mouse_pointer
	if not self._removed_mouse then
		self._removed_mouse = true

		if controller_mgr:get_default_wrapper_type() == "pc" or controller_mgr:get_default_wrapper_type() == "steam" or controller_mgr:get_default_wrapper_type() == "vr" then
			mouse_pointer_mgr:remove_mouse(self._mouse_id)
		else
			mouse_pointer_mgr:enable()
		end

		self._mouse_id = nil
	end
end

function RadialMenuDialog:show()
	self._manager:event_dialog_shown(self)
	self._panel:show()
	if self._data.reset_mouse_position_on_show then
		_G.managers.mouse_pointer:set_mouse_world_position(self._panel:world_center())
	end
	self.is_active = true
	return true
end	

function RadialMenuDialog:hide(select_current)
	if select_current then
		local index = self:get_selected_index()
		if index then
			self:_callback_item_confirmed(index,self._items[index])
			self:on_mouseover_item(nil,index)
		else
			self:callback_on_cancelled()
		end
		self:clear_selected_index()
		self:set_mouseover_text("")
	end
	self:set_input_enabled(false)
	self._panel:hide()
	self.is_active = false
	self._manager:event_dialog_hidden(self)
end

function RadialMenuDialog:animate_mouseover_item_focus(index)
	local items = self._items
	local panel = self._panel
	if index and alive(panel) then
		local icon = panel:child("icon_" .. index)
		if alive(icon) then
			icon:stop()
			local item_data = self._items[index]
			local grow_size = self._data.animate_focus_grow_size or 1.66
			local duration = self._data.animate_focus_duration or 0.33
			icon:animate(self._animate_grow_center,duration,icon:w(),icon:h(),item_data.w * grow_size,item_data.h * grow_size,item_data.icon_x,item_data.icon_y,icon:alpha(),item_data.focus_alpha)
		end
	end
end

function RadialMenuDialog._animate_grow_center(o,duration,w1,h1,w2,h2,c_x,c_y,a1,a2)
	local dw,dh,da
	if w1 and w2 then
		dw = w2 - w1
	end
	if h1 and h2 then
		dh = h2 - h1
	end
	if a1 and a2 then
		da = a2 - a1
	end
	_G.over(duration,function(lerp)
		if dw then
			o:set_w(w1 + (dw * lerp))
		end
		if dh then
			o:set_h(h1 + (dh * lerp))
		end
		if da then
			o:set_alpha(a1 + (da * lerp))
		end
		o:set_center(c_x,c_y)
	end)
	if a2 then
		o:set_alpha(a2)
	end
	o:set_size(w2,h2)
	o:set_center(c_x,c_y)
end

function RadialMenuDialog:animate_mouseover_item_unfocus(index)
	local items = self._items
	local panel = self._panel
	if index and alive(panel) then
		local icon = panel:child("icon_" .. index)
		if alive(icon) then
			icon:stop()
			local duration = self._data.animate_unfocus_duration or 0.33
			local item_data = self._items[index]
			icon:animate(self._animate_grow_center,duration,icon:w(),icon:h(),item_data.w,item_data.h,item_data.icon_x,item_data.icon_y,icon:alpha(),item_data.unfocus_alpha)
		end
	end
end

return RadialMenuManager