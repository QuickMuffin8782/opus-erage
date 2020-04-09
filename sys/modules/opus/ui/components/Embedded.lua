local class    = require('opus.class')
local Terminal = require('opus.terminal')
local UI       = require('opus.ui')

local colors = _G.colors

UI.Embedded = class(UI.Window)
UI.Embedded.defaults = {
	UIElement = 'Embedded',
	backgroundColor = colors.black,
	textColor = colors.white,
	maxScroll = 100,
	accelerators = {
		up = 'scroll_up',
		down = 'scroll_down',
	}
}
function UI.Embedded:layout()
	UI.Window.layout(self)

	if not self.win then
		function self.render()
			self:sync()
		end
		self.win = Terminal.window(UI.term.device, self.x, self.y, self.width, self.height, false)
		self.win.canvas = self
		self.win.setMaxScroll(self.maxScroll)
		self.win.setCursorPos(1, 1)
		self.win.setBackgroundColor(self.backgroundColor)
		self.win.setTextColor(self.textColor)
		self.win.clear()
	end
end

function UI.Embedded:draw()
	self:dirty()
end

function UI.Embedded:focus()
	-- allow scrolling
end

function UI.Embedded:enable()
	UI.Window.enable(self)
	self.win.setVisible(true)
	self:dirty()
end

function UI.Embedded:disable()
	self.win.setVisible(false)
	UI.Window.disable(self)
end

function UI.Embedded:eventHandler(event)
	if event.type == 'scroll_up' then
		self.win.scrollUp()
		return true
	elseif event.type == 'scroll_down' then
		self.win.scrollDown()
		return true
	end
end

function UI.Embedded.example()
	local Event = require('opus.event')
	local Util  = require('opus.util')
	local term  = _G.term

	return UI.Embedded {
		enable = function (self)
			UI.Embedded.enable(self)
			Event.addRoutine(function()
				local oterm = term.redirect(self.win)
				Util.run(_ENV, '/sys/apps/shell.lua')
				term.redirect(oterm)
			end)
		end,
		eventHandler = function(_, event)
			if event.type == 'key' then
				return true
			end
		end
	}
end
