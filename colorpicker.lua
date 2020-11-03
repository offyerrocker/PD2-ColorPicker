--class file


--todo store and rebuild palettes?
--todo instructions in tooltip box?
--fix mouseover object being set/reset incorrectly

local leftclick = Idstring("0")
local rightclick = Idstring("1")

ColorPicker = ColorPicker or blt_class()
ColorPicker.current_menu = nil
ColorPicker.mouse0_held = false
ColorPicker.mouse1_held = false
function ColorPicker:init(id,title,size,changed_callback,parameters)
	self._done_cb = changed_callback
	parameters = parameters or {}
	local palettes = parameters.palettes or {
		Color(1,0,0),
		Color(1,0.5,0),
		Color(1,1,0),
		Color(0.5,1,0),
		Color(0,1,0),
		Color(0,1,0.5),
		Color(0,1,1),
		Color(0,0.5,1),
		Color(0,0,1),
		Color(0.5,0,1),
		Color(1,0,1),
		Color(1,0,0.5),
		Color(0,0,0),
		Color(0.5,0.5,0.5),
		Color(1,1,1)
	}
	if not managers.gui_data then 
		--queue creation
	end
	self.current_color = parameters.current_color or parameters.default_color or Color.blue
	self.selected_color = parameters.selected_color or parameters.default_color or Color.red

	self._name = id
	self._active = false
	self._moused_object_name = nil
	self.held_color = nil
	
	--self.hue = self.get_hue_from_rgb(self.selected_color:unpack())
	self.hue,self.saturation,self.value = self.get_hsvl_from_rgb(self.selected_color:unpack())
	
	ColorPicker._WS = ColorPicker._WS or managers.gui_data:create_fullscreen_workspace()
	
	local instance_name = "ColorPicker" .. tostring(id)
--	if alive(ColorPicker._WS:child(instance_name)) then 
--		ColorPicker._WS:remove(ColorPicker._WS:child(instance_name))
--	end
	
	self._panel = ColorPicker._WS:panel():panel({
		name = instance_name,
		layer = 999
	})
	
	self._bg_main = self._panel:rect({
		name = "bg_main",
		color = Color.black,
		layer = -1000,
		visible = false
	})
	
	--todo different colorspaces
	if true then 
		--list of interactable ui objects
			--callbacks:
				--UNUSED get_color: when the color of this object is requested, returns the result of this function
				--drop_color: when a color is dragged (and released) onto this object, performs this function, with the color as the first argument
				--UNUSED drag_color: only defined if a color can be dragged from this object. when this object is dragged, sets the held color to the result of this function
				--on_leftdrag: when leftclick is pressed over this object and held, performs this function once
				--leftdoubleclick: when leftclick is quickly pressed twice over this object, performs this function
				--rightdoubleclick: when rightclick is quickly pressed twice over this object, performs this function
				--leftclick: when leftclick is quick pressed and released over this object, performs this function, with x and y as the first two arguments
				--rightclick: when rightclick is quickly pressed and released over this object, performs this function, with x and y as the first two arguments
				--leftdrag: while leftclick is pressed over this object and held (even if the mouse leaves the object), performs this function, with x and y as the first two arguments
				--mouseover: when this object is moused over, performs this function
				--mouseover_end: when this object was moused over but then another object is moused over, performs this function
		self._mouseover_objects = {
			bg_white = {
				callbacks = {
					get_color = callback(self,self,"get_selected_color"),
					leftdoubleclick = nil,
					rightdoubleclick = nil,
					leftclick = callback(self,self,"update_colorspace_position"), --check current color
					rightclick = nil,
					leftdrag = function(x,y)--callback(self,self,"update_colorspace_position"),
						self:update_colorspace_position(x,y)
					end,
					on_leftdrag = callback(self,self,"set_pointer_image","none"),
					drop_color = function(color)
						self:set_selected_color(color,true)
					end,
					--callback(self,self,"set_selected_color"),
					mouseover = callback(self,self,"set_pointer_image","link"),
					mouseover_end = nil
				}
			}, --main color field
			hue_slider_bg = {
				callbacks = {
--					get_color = callback(self,self,"get_selected_color"), --get hue value
					leftdoubleclick = nil,
					rightdoubleclick = nil,
					leftclick = nil,
					rightclick = nil,
					leftdrag = function(x,y) 
						self:update_colorspace_hue(x,y)
--						self:update_colorspace_position(self._panel:child("eyedropper_circle"):center())
--						callback(self,self,"update_colorspace_hue"), --check current hue value
					end,
					on_leftdrag = callback(self,self,"set_pointer_image","grab"),
					drop_color = nil,
					mouseover = callback(self,self,"set_pointer_image","hand"),
					mouseover_end = nil
				}
			},
			--slider_handle is clone of hue_slider
			preview_current_box = {
				callbacks = {
					get_color = callback(self,self,"get_current_color"),
					leftdoubleclick = nil,
					rightdoubleclick = nil,
					leftclick = function()
						self:set_selected_color(self:get_current_color())
					end,
					rightclick = nil,
					leftdrag = nil,
					on_leftdrag = function()
						self:set_held_color(self:get_current_color())
						self:set_pointer_image("grab")
					end, --set current held to get_current_color
					on_leftdrag = callback(self,self,"set_pointer_image","grab"),
					drop_color = nil, --callback(self,self,"set_selected_color"),
					mouseover = callback(self,self,"set_pointer_image","link"),
					mouseover_end = nil
				}
			},
			preview_new_box = {
				callbacks = {
					get_color = callback(self,self,"get_selected_color"),
					leftdoubleclick = nil,
					rightdoubleclick = nil,
					leftclick = nil,
					rightclick = nil,
					leftdrag = nil,
					on_leftdrag = function()
						self:set_held_color(self:get_selected_color())
						self:set_pointer_image("grab")
					end, --set current held to get_selected_color
					drop_color = callback(self,self,"set_selected_color"),
					mouseover = nil,
					mouseover_end = nil
				}
			},
			tooltip_box = {
				callbacks = {
					get_color = callback(self,self,"get_selected_color"),
					leftdoubleclick = nil,
					rightdoubleclick = nil,
					leftclick = function()
						self:copy_selected_color()
						--give notification that thing was copied in tooltip box
					end,
					rightclick = nil,
					leftdrag = nil,
					on_leftdrag = function()
						self:set_held_color(self:get_selected_color())
						self:set_pointer_image("grab")
					end, --set current held to get_selected_color
					drop_color = callback(self,self,"set_selected_color"),
					mouseover = nil
				}
			},
			accept_button_box = {
				callbacks = {
					get_color = nil,
					leftclick = callback(self,self,"Hide",true), --return selected color/do select callback with selected color, and exit
					rightdoubleclick = nil,
					leftdoubleclick = nil,
					rightclick = nil,
					leftdrag = nil,
					drop_color = nil,
					mouseover = callback(self,self,"set_pointer_image","link") --highlight box to indicate interact-ability
				}
			},
			cancel_button_box = {
				callbacks = {
					get_color = nil,
					leftclick = callback(self,self,"Hide"), --return previous color/do select callback with previous color, and exit
					rightdoubleclick = nil,
					leftdoubleclick = nil,
					rightclick = nil,
					leftdrag = nil,
					drop_color = nil,
					mouseover = callback(self,self,"set_pointer_image","link") --highlight box to indicate interact-ability
				}
			}
			--palette data is generated at the time of palette bitmaps generation
		}
		self._mouseover_objects.hue_slider_cursor = self._mouseover_objects.hue_slider
	
	
		size = size or 500
		self._size = size
		local color_preview_box_size = 100
		local preview_current_box_x = size / 20
		local preview_current_box_y = size / 20
		local preview_new_box_x = preview_current_box_x
		local preview_new_box_y = preview_current_box_y + color_preview_box_size
		
		local slider_w = size / 20
		local slider_handle_w = 8
		local slider_handle_h = 8 -- math.max(1,size / 100)
		local slider_x = 30
		local slider_y = 0

		local palette_x = size * 1.15
		local palette_y = size * 0.8
		local palette_size = size / 20
		local palette_spacing = size / 75
		local palette_rows = 3
		local palette_columns = 5
		
		local hex_label_x = size
		local hex_label_y = size
		local label_font_size = size / 40
		
		local button_font_size = size / 40
		local accept_button_text_x = size * 1.2
		local accept_button_text_y = size
		local accept_button_box_w  = size / 15
		local accept_button_box_h  = size / 30
		local accept_button_box_x  = size * 1.2
		local accept_button_box_y  = size
		
		local cancel_button_text_x = size * 1.2
		local cancel_button_text_y = size
		local cancel_button_box_w  = size / 15
		local cancel_button_box_h  = size / 30
		local cancel_button_box_x  = size * 1.2
		local cancel_button_box_y  = accept_button_box_y + (accept_button_box_h * 1.1)
		
		local tooltip_box_x = size
		local tooltip_box_y = size
		local tooltip_box_w = size / 10
		local tooltip_box_h = size / 25
		local tooltip_text_font_size = size / 40
		
		local gradient_v = self._panel:gradient({
			name = "gradient_v",
			rotation = 90,
			layer = 3,
			alpha = 1,
			w = size,
			h = size,
			blend_mode = "normal",
			gradient_points = {
				0,
				Color.black:with_alpha(0),
				1,
				Color.black
			}
		})
		local gradient_s = self._panel:gradient({
			name = "gradient_s",
			layer = 2,
			alpha = 1,
			w = size,
			h = size,
			blend_mode = "normal",
			gradient_points = {
				0,
				Color.red:with_alpha(0),
				1,
				Color.red
			}
		})
		
		local eyedropper_circle = self._panel:bitmap({
			name = "eyedropper_circle",
			layer = 4,
			x = -42069,
			y = -42069, --todo get position from current color; make sure to use centered instead of set position
			texture = tweak_data.hud_icons.pd2_kill.texture,
			texture_rect = tweak_data.hud_icons.pd2_kill.texture_rect
		})
		
		local bg_white = self._panel:rect({
			name = "bg_white",
			layer = 1,
			alpha = 1,
--			color = Color.black,
			w = size,
			h = size,
			blend_mode = "normal"
		})
		local c = {
			Color(1,0,0),
			Color(1,1,0),
			Color(0,1,0),
			Color(0,1,1),
			Color(0,0,1),
			Color(1,0,1),
			Color(1,0,0)
		}
		local c_processed = {}
		for index,color in pairs(c) do 
			table.insert(c_processed,#c_processed + 1,(index - 1)/(#c - 1)) --num
			table.insert(c_processed,#c_processed + 1,c[index]) --color
		end
		
		local hue_slider = self._panel:gradient({
			name = "hue_slider",
			layer = 4,
			alpha = 1,
			rotation = 90,
			x = slider_x + ((size + slider_w)/2),
			y = slider_y + ((size - slider_w)/2),
			w = size,
			h = slider_w,
			blend_mode = "normal",
			gradient_points = c_processed,
		})
		local hue_slider_bg = self._panel:rect({
			name = "hue_slider_bg",
			layer = 1,
			alpha = 1,
			color = Color.black,
			x = slider_x + size,
			y = slider_y,
			w = slider_w,
			h = size,
			blend_mode = "normal"
		})
		local hue_slider_cursor = self._panel:bitmap({
			name = "hue_slider_cursor",
			layer = 5,
			alpha = 1,
			texture = tweak_data.hud_icons.wp_arrow.texture,
			texture_rect = tweak_data.hud_icons.wp_arrow.texture_rect,
			w = slider_handle_w,
			h = slider_handle_h,
			x = hue_slider_bg:x() - slider_handle_w,
			y = hue_slider_bg:y(),
			blend_mode = "normal"
		})
		
		--set indicator at default color pos

		local preview_current_box = self._panel:rect({
			name = "preview_current_box",
			layer = 6,
			alpha = 1,
			color = self.current_color,
			w = color_preview_box_size,
			h = color_preview_box_size,
			x = preview_current_box_x + size + slider_handle_h + slider_w,
			y = preview_current_box_y
		})
		local preview_current_label = self._panel:text({
			name = "preview_current_label",
			layer = 10,
			x = preview_current_box:x(),
			y = preview_current_box:y(),
			text = "Current",
			font = tweak_data.hud.medium_font,
			font_size = label_font_size,
			color = Color.green
		})
		
		local preview_new_box = self._panel:rect({
			name = "preview_new_box",
			layer = 6,
			alpha = 1,
			color = self.selected_color,
			w = color_preview_box_size,
			h = color_preview_box_size,
			x = preview_new_box_x + size + slider_handle_h + slider_w,
			y = preview_new_box_y
		})
		local preview_new_label = self._panel:text({
			name = "preview_new_label",
			layer = 10,
			x = preview_new_box:x(),
			y = preview_new_box:y(),
			text = "New",
			font = tweak_data.hud.medium_font,
			font_size = label_font_size,
			color = Color.green
		})
		
		for i = 0,(palette_rows * palette_columns) - 1,1 do 
			local palette_name = "palette_" .. (i + 1)
			local palette = self._panel:rect({
				name = palette_name,
				color = palettes[i] or Color.white,
				w = palette_size,
				h = palette_size,
				x = palette_x + ((palette_size + palette_spacing) * (i % palette_columns)),
				y = palette_y + ((palette_size + palette_spacing) * math.floor(i / palette_columns)),
				layer = 5
			})
			self._mouseover_objects[palette_name] = {
				callbacks = {
					get_color = callback(palette,palette,"color"),
					leftdoubleclick = nil,
					rightdoubleclick = nil,
					leftclick = function()
						self:set_selected_color(palette:color())
--						self:set_selected_color(self:get_palette_color(i + 1))
					end,
					rightclick = function()
							palette:set_color(self:get_selected_color())
						end,
					drop_color = callback(palette,palette,"set_color"),
--					function(color)
--						log("getting drop color on " .. palette_name .. " with color " .. tostring(color))
--						palette:set_color(color)
--					end,--callback(self,self,"set_palette_color"),
					on_leftdrag = function()
						self:set_held_color(palette:color())
						self:set_pointer_image("grab")
					end,
					mouseover = callback(self,self,"set_pointer_image","hand")
				}
			}
		end
		
		local hex_label_text = self._panel:text({
			name = "hex_label_text",
			layer = 10,
			x = hex_label_x,
			y = hex_label_y,
			text = "#" .. Color.white:to_hex(),
			font = tweak_data.hud.medium_font,
			font_size = label_font_size,
			color = Color.white
		})
		
		
		local accept_button_box = self._panel:rect({
			name = "accept_button_box",
			layer = 9,
			x = accept_button_box_x,
			y = accept_button_box_y,
			w = accept_button_box_w,
			h = accept_button_box_h,
			color = Color.blue,
			alpha = 1
		})
		
		local accept_button_text = self._panel:text({
			name = "accept_button_text",
			layer = 10,
			x = accept_button_box_x,
			y = accept_button_box_y,
			text = "Accept",
			font = tweak_data.hud.medium_font,
			font_size = button_font_size,
			color = Color.white
		})
		local cancel_button_box = self._panel:rect({
			name = "cancel_button_box",
			layer = 9,
			x = cancel_button_box_x,
			y = cancel_button_box_y,
			w = cancel_button_box_w,
			h = cancel_button_box_h,
			color = Color.blue,
			alpha = 1
		})
		
		local cancel_button_text = self._panel:text({
			name = "cancel_button_text",
			layer = 10,
			x = cancel_button_box_x,
			y = cancel_button_box_y,
			text = "Cancel",
			font = tweak_data.hud.medium_font,
			font_size = button_font_size,
			color = Color.white
		})
		
		local tooltip_box = self._panel:rect({
			name = "tooltip_box",
			layer = 8,
			x = tooltip_box_x,
			y = tooltip_box_y,
			w = tooltip_box_w,
			h = tooltip_box_h,
			color = Color(0.5,0.5,0.5)
		})
					
--	elseif display_mode == 2 or display_mode == "hsb" or display_mode == "hsv" then 
--	elseif display_mode == 3 or display_mode == "cym" or display_mode == "cymk" then 
	end
end

function ColorPicker:update_colorspace_position(x,y) --clbk colorspace box
	local colorspace = self._panel:child("bg_white")
	local s_x,s_y = colorspace:position()
	local w,h = colorspace:size()
	local saturation = math.clamp(x-s_x,0,w)/w
	local value = 1 - (math.clamp(y-s_y,0,h)/h)
	self.saturation = saturation
	self.value = value
	self._panel:child("eyedropper_circle"):set_center(math.clamp(x,s_x,s_x+w),math.clamp(y,s_y,s_y+h))
--[[
	local chroma = saturation * value
	local hue = self.hue / 60
	local n = chroma * (1 - math.abs(hue % 2 - 1))
	local r,g,b = 0,0,0
	if self.hue <= 0 then 
		--oops! all zeroes
	elseif 0 <= hue and hue <= 1 then 
		r = chroma
		g = n
		b = 0
	elseif 1 <= hue and hue <= 2 then 
		r = n
		g = chroma
		b = 0
	elseif 2 <= hue and hue <= 3 then 
		r = 0
		g = chroma
		b = n
	elseif 3 <= hue and hue <= 4 then 
		r = 0
		g = n
		b = chroma
	elseif 4 <= hue and hue <= 5 then 
		r = n
		g = 0
		b = chroma
	elseif 5 <= hue and hue <= 6 then 
		r = chroma
		g = 0
		b = n
	end
	local xm = value - chroma
	r = r + xm
	g = g + xm
	b = b + xm
	--]]
	local r,g,b = self.get_rgb_from_hsv(self.hue,saturation,value)
	self:set_selected_color(Color(r,g,b),true)
	--create color from s/v and use as selected color
end

function ColorPicker:update_colorspace_hue(x,y) --clbk hue slider
	local slider = self._panel:child("hue_slider_bg")
	local s_x,s_y = slider:position()
	local h = slider:h()
	self:set_hue(360 * math.clamp(y-s_y,0,h)/h,true)

	local hue_slider_cursor = self._panel:child("hue_slider_cursor")
	hue_slider_cursor:set_y(math.clamp(y - s_y, s_y, s_y + h) - (hue_slider_cursor:h() / 2))
--	self:update_colorspace_position(self._panel:child("eyedropper_circle"):center())

--this doesn't build colors correctly since it needs sat/val
--TODO 
end

function ColorPicker:set_pointer_image(icon)
	if icon == "none" then 
		managers.mouse_pointer._mouse:child("pointer"):hide()
	else
		managers.mouse_pointer._mouse:child("pointer"):show()
		managers.mouse_pointer:set_pointer_image(icon)
	end
--	managers.mouse_pointer:set_pointer_image("grab") --arrow (cursor arrow), link (pointer hand). hand (open hand), grab (closed hand)
end

function ColorPicker:Show()
	
	--todo if menu is not created, then create menu
	
	if ColorPicker.current_menu and self._name ~= ColorPicker.current_menu:get_name() then 
		ColorPicker.current_menu:hide()
	end
	ColorPicker.current_menu = self
	self._panel:show()
	if not self._active then
		self._panel:key_release(callback(self,self,"key_press"))
		managers.mouse_pointer:use_mouse({
		mouse_move = callback(self, self, "on_mouse_moved"),
		mouse_click = callback(self, self, "on_mouse_clicked"),
		mouse_press = callback(self, self, "on_mouse_pressed"),
		mouse_double_click = callback(self, self, "on_mouse_doubleclicked"),
		mouse_release = callback(self, self, "on_mouse_released"),
		id = "colorpicker"
	})
		game_state_machine:_set_controller_enabled(false)
		self._active = true
	end
end

function ColorPicker:Hide(accepted)
	if self._active then 
		managers.mouse_pointer:remove_mouse("colorpicker")
		game_state_machine:_set_controller_enabled(true)
		self._panel:key_release(nil)
		self._active = false
		if type(self._done_cb) == "function" then 
			if accepted then 
				self._done_cb(self:get_current_color())
			else
				self._done_cb(self:get_selected_color())
			end
		end
	end
	self._panel:hide()
end

function ColorPicker:get_mouseover_object(x,y)
	local panel = self._panel
	if not (panel and alive(panel) and x and y) then
		return
	end
	for name,data in pairs(self._mouseover_objects) do 
		local obj = panel:child(name)
		if alive(obj) then 
			if obj:inside(x,y) then 
				return name,obj
			end
		end
	end
end

function ColorPicker:on_mouse_moved(o,x,y)
	local panel = self._panel
	
	local prev_moused_object_name = self._moused_object_name -- or self:get_mouseover_object(x,y)
	
	if ColorPicker.mouse0_held then 
		local moused_object_data = self._mouseover_objects[prev_moused_object_name]
		if moused_object_data and moused_object_data.callbacks.leftdrag then 
			moused_object_data.callbacks.leftdrag(x,y)
		end
	end
	
	local moused_object_name = self:get_mouseover_object(x,y)
	if not self:get_held_color() then
		if prev_moused_object_name ~= moused_object_name then --if mouseover changed then 
			if prev_moused_object_name and self._mouseover_objects[prev_moused_object_name] then 
				--if previous moused object exists, then do mouseover end event if extant
				if self._mouseover_objects[prev_moused_object_name].callbacks.mouseover_end then 
					self._mouseover_objects[prev_moused_object_name].callbacks.mouseover_end()
				end
			end
			if moused_object_name and not ColorPicker.mouse0_held then
				self._moused_object_name = moused_object_name --save this object so that we don't have to perform multiple mouseover checks at once
				
				--if new mouseover exists then do mouseover event
				if self._mouseover_objects[moused_object_name] and self._mouseover_objects[moused_object_name].callbacks.mouseover then 
					self._mouseover_objects[moused_object_name].callbacks.mouseover(x,y)
				end
			end
		end
	elseif moused_object_name then 
		if self._mouseover_objects[moused_object_name] and self._mouseover_objects[moused_object_name].callbacks.drop_color then 
			--do ui indication that object can be dropped
		end
	end
	
	if not (moused_object_name or ColorPicker.mouse0_held) then
		self._moused_object_name = nil
		self:set_pointer_image("arrow")
	end
end

function ColorPicker:on_mouse_pressed(o,button,x,y)
	local moused_object_name = self._moused_object_name or self:get_mouseover_object(x,y)
	local moused_object_data
	if moused_object_name then 
		moused_object_data = self._mouseover_objects[moused_object_name]
	end
	if button == leftclick then 
		if not ColorPicker.mouse0_held and moused_object_data then 
			if moused_object_data.callbacks.on_leftdrag then 
				moused_object_data.callbacks.on_leftdrag()
			end
		end
		ColorPicker.mouse0_held = true
	elseif button == rightclick then 
		ColorPicker.mouse1_held = true
	end
	
end

function ColorPicker:on_mouse_clicked(o,button,x,y)
	local moused_object_name = self:get_mouseover_object(x,y)
	local moused_object_data
	if moused_object_name then 
		moused_object_data = self._mouseover_objects[moused_object_name]
	end
	if button == leftclick then 
		if moused_object_data and moused_object_data.callbacks.leftclick then 
			moused_object_data.callbacks.leftclick(x,y)
		end
	elseif button == rightclick then 
		if moused_object_data and moused_object_data.callbacks.rightclick then 
			moused_object_data.callbacks.rightclick(x,y)
		end
	end
	self.held_color = nil
end

function ColorPicker:on_mouse_released(o,button,x,y)
	local moused_object_name = self._moused_object_name or self:get_mouseover_object(x,y)
	local moused_object_data
	if moused_object_name then 
		moused_object_data = self._mouseover_objects[moused_object_name]
	end
	if button == leftclick then 
--		log("Released on " .. tostring(moused_object_name))
		ColorPicker.mouse0_held = false
		local held_color = self:get_held_color()
--		log("doing drop color, held " .. tostring(held_color))
		if held_color then 
			--check mouseover object if held color
			moused_object_name = self:get_mouseover_object(x,y)
			moused_object_data = moused_object_name and self._mouseover_objects[moused_object_name]
--			log("doing drop color on " .. tostring(moused_object_name))
			if moused_object_data and moused_object_data.callbacks.drop_color then 
				moused_object_data.callbacks.drop_color(held_color)
--				log("did drop color on " .. moused_object_name .. ", used color " .. tostring(held_color))
			end
			self:set_held_color(nil)
		end
	elseif button == rightclick then
		ColorPicker.mouse1_held = false
	end
	self:set_pointer_image("arrow")
	self._moused_object_name = nil
end

function ColorPicker:on_mouse_doubleclicked(o,button,x,y)
	local moused_object_name = self:get_mouseover_object(x,y)
	local moused_object_data = moused_object_name and self._mouseover_objects[moused_object_name]
	if button == leftclick then 
		if moused_object_data.callbacks.leftdoubleclick then 
			moused_object_data.callbacks.leftdoubleclick()
		end
	elseif button == rightclick then 
		if moused_object_data.callbacks.rightdoubleclick then 
			moused_object_data.callbacks.rightdoubleclick()
		end	
	end
end

function ColorPicker:set_held_color(color)
	self.held_color = color
end

function ColorPicker:get_held_color()
	return self.held_color
end

function ColorPicker:get_name()
	return self._name
end

function ColorPicker:active()
	return self._active
end

function ColorPicker:get_selected_color(color)
	return self.selected_color
end

function ColorPicker:set_palette_color(color,index)
	local palette = self._panel and self._panel:child("palette_" .. tostring(index))
	if palette then 
		return palette:color()
	end
end

function ColorPicker:get_palette_color(index) --not used anywhere
	local palette = self._panel and self._panel:child("palette_" .. tostring(index))
	if palette then 
		return palette:color()
	end
end

function ColorPicker.get_hsvl_from_rgb(r,g,b)
	local value = math.max(r,g,b)
	local xm = math.min(r,g,b)
	local chroma = value-xm
	local hue = 0
	if chroma == 0 then 
		hue = 0
	elseif value == r then
		hue = 60 * (0 + ((g-b)/chroma))
	elseif value == g then
		hue = 60 * (2 + ((b-r)/chroma))
	elseif value == b then 
		hue = 60 * (4 + ((r-g)/chroma))
	end
	local saturation = 0
	if value == 0 then 
		return 0,0,0,0
	else
		saturation = chroma/value
	end
	local lightness = (value + xm) / 2
	return ((hue - 1) % 360) + 1,saturation,value,lightness
end

function ColorPicker.get_rgb_from_hsv(_hue,saturation,value)
	local chroma = value * saturation
	local r,g,b
	if not _hue or (_hue <= 0) then 
		--oops! all zeroes
		return 0,0,0
	else
		local hue = math.clamp(_hue,0,360) / 60
		local n = chroma * (1 - math.abs((hue % 2) - 1))
		if 0 <= hue and hue <= 1 then 
			r = chroma
			g = n
			b = 0
		elseif 1 <= hue and hue <= 2 then 
			r = n
			g = chroma
			b = 0
		elseif 2 <= hue and hue <= 3 then 
			r = 0
			g = chroma
			b = n
		elseif 3 <= hue and hue <= 4 then 
			r = 0
			g = n
			b = chroma
		elseif 4 <= hue and hue <= 5 then 
			r = n
			g = 0
			b = chroma
		elseif 5 <= hue and hue <= 6 then 
			r = chroma
			g = 0
			b = n
		else --dead code
			log("[ColorPicker] Error! hue exceeded expected bounds: " .. tostring(hue))
			r = 0
			g = 0
			b = 0
		end
	end
	local m = value - chroma
	r = r + m
	g = g + m
	b = b + m
	return r,g,b
end

function ColorPicker.get_rgb_from_hue(hue)
--	local n = tonumber(color:to_hex())
--	local r = n/tonumber("0xffffff")
--	return r
	return (1+math.cos(hue))/2,(1+math.cos(hue+240))/2,(1+math.cos(hue+120))/2
end

function ColorPicker.get_hue_from_rgb(r,g,b)
	return ( (math.atan2(math.sqrt(3) * (g - b),2 * (r - g - b)) - 1) % 360) + 1
end

function ColorPicker:set_hue(hue,from_slider)
	if hue == 0 then 
		hue = 360
	end
	self.hue = hue
	
	local color = Color(self.get_rgb_from_hsv(hue,1,1))
	self._panel:child("gradient_s"):set_gradient_points({
		0,
		color:with_alpha(0),
		1,
		color
	})
	
	if not from_slider then 
		local slider = self._panel:child("hue_slider_bg")
		local s_x,s_y = slider:position()
		local h = slider:h()
		local hue_slider_cursor = self._panel:child("hue_slider_cursor")
		hue_slider_cursor:set_y(s_y + (h * hue/360) - (hue_slider_cursor:h() / 2))
	else
		self:set_selected_color(Color(self.get_rgb_from_hsv(self.hue,self.saturation,self.value)))
--		self:set_selected_color(Color(self.get_rgb_from_hue(hue)))
	end
end

function ColorPicker:check_hue_slider_position()
	--really it's more like setting the slider's position according to color
	
	local slider = self._panel:child("hue_slider_bg")
	local slider_cursor = self._panel:child("hue_slider_cursor")
	local s_x,s_y = slider:position()
	local h = slider:h()
	slider_cursor:set_y(s_y + math.clamp(h * self.hue/360,0,h) - (slider_cursor:h() / 2))
	
	--[[
	local hue = color and self.get_hue_from_rgb(color:unpack())
	if hue then
		local hue_slider_cursor = self._panel:child("hue_slider_cursor")
--		hue_slider_cursor:set_y(self._size * hue / 360) --todo use slider position/size
		log("slider position " .. tostring(hue/360))
	end
	--]]
end

function ColorPicker:set_colorspace_color(color) --not used
	local r,g,b = color:unpack()
	local s = math.min(r,g,b)
	local b = math.max(r,g,b)
	self._panel:child("gradient_s"):set_gradient_points({
		0,
		color:with_alpha(0),
		1,
		color
	})
	local x = s * self._size
	local y = b * self._size
--	self._panel:child("eyedropper_circle"):set_position(x,y)
end

function ColorPicker:set_preview_new_color(color)
	self._panel:child("preview_new_box"):set_color(color)
end

function ColorPicker:key_press(o,k)
	if k == Idstring("esc") then 
		self:Hide()
	elseif k == Idstring("enter") then 
		self:Hide(true)
--	elseif k == Idstring("insert") or (k == Idstring("v") and ctrl_held) then --todo paste from clipboard through keystroke
	end
end

function ColorPicker:set_tooltip(id,data) --todo
	
end

function ColorPicker:set_hex_label(color)
	self._panel:child("hex_label_text"):set_text(color:to_hex())
end

function ColorPicker:get_current_color()
	return self.current_color
end

function ColorPicker:set_current_color(color) --not used
	self.current_color = color
end

function ColorPicker:copy_selected_color() --copies the hex value of the selected color to the clipboard
	Application:set_clipboard(self:get_selected_color():to_hex())
end

function ColorPicker:set_selected_color(color,skip_check_hue)
	self.selected_color = color
	self:set_preview_new_color(color)
	self:set_hex_label(color)
	
	if not skip_check_hue then 
		local hue = self.get_hsvl_from_rgb(color:unpack()) --self.get_hue_from_rgb(color:unpack())
		self:set_hue(hue)
		self:check_hue_slider_position()
	end
end

function ColorPicker:get_clipboard_color()
	local s = Application:get_clipboard()
	if s then 
		return self:parse_color(tostring(s))
	end
end

function ColorPicker:parse_color(input)
	--does its darndest to interpret a color from input of multiple types

	if Color[input] and type(Color[input]) == "userdata" then 
		return Color[input]
	elseif input == "magenta" then --red, yellow, green, cyan, blue, purple, white, and black are all defined, among others. magenta and orange are not
		return Color(1,0,1)
	elseif input == "orange" then 
		return Color(1,0.5,0)
	end
	
	local a,b = string.find(tostring(input),"0x")
	if b and string.len(input) > b then   --find hex string
		a = string.sub(input,b+1)
		if a then 
			return Color:from_hex(a)
		end
	end
	
	b = getmetatable(input) 
	if type(b) == "table" then 
		if b.type_name == "Vector3" then 
			return Color(unpack(input))
		end
	end
	
	a = LuaNetworking:StringToColour(input)
	if a then 
		return a
	end
	
	if type(input) == "table" then 
		if input[1] and input[2] and input[3] and (type(input[1]) == "number" and type(input[2]) == "number" and type(input[3]) == "number") then 
			if input[1] > 1 or input[2] > 1 or input[3] > 1 then 
				return Color(input[1]/255,input[2]/255,input[3]/255)
			else
				return Color(input[1],input[2],input[3])
			end
		end
		return Color(unpack(input))
	end
	
	if type(input) == "number" then --get hex string from number
		return Color(string.format("%X",input))
	else
		-- attempt converting input to a number, then that number to hex
		b = tonumber(input)
		if b then 
			return Color(string.format("%X",b))
		end
	end
	
--	return Color(input) 
end

function ColorPicker:pre_destroy()
	if ColorPicker.current_menu == self then 
		ColorPicker.current_menu = nil
	end
	if alive(self._panel) then 
		self._panel:parent():remove(self._panel)
	end
	self._panel = nil
end
