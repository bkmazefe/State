--!strict
--[[
	State management module written by @bkmazefe. Inspired from Elttob's States in Fusion Library.
]]
local Promise = require(script.Parent.Parent.Parent.Promise)

local State = {}
State.__index = State

export type State<T> = {
	set: (self: State<T>, new_value: T, force_update: boolean?) -> (),
	get: (self: State<T>) -> T,
	connect: (self: State<T>, callback: (value: T) -> (), on_disconnect: (() -> ())?) -> () -> (),
}

export type StateModule = {
	new: <T>(value: T, doesUnpack: boolean?) -> State<T>,
}

type state<T> = {
	new: (T) -> state<T>,
	set: (self: state<T>, new_value: T, force_update: boolean?) -> (),
	get: (self: state<T>) -> T,
	connect: (self: state<T>, callback: (value: T) -> (), on_disconnect: (() -> ())?) -> () -> (),
	_updateAll: (self: state<T>) -> (),
	toString: (self: state<T>) -> (),
	_doesUnpack: boolean,

	stored_value: T,
	_connections: { [(value: T) -> ()]: (value: T) -> () },
}

local WEAK_KEYS_METATABLE = { __mode = "k" }

function State.new<T>(value: T, doesUnpack: boolean?): State<T>
	local self = setmetatable({
		stored_value = value,
		_connections = setmetatable({}, WEAK_KEYS_METATABLE),
		_doesUnpack = doesUnpack and true or false,
	}, State)

	return self
end

function State.set<T>(self: state<T>, new_value: T, force_update: boolean?)
	if force_update == true or (self.stored_value ~= new_value and force_update == nil) then
		self.stored_value = new_value
		self:_updateAll()
		return
	end
end

function State.get<T>(self: state<T>): T
	return self.stored_value
end

function State._updateAll<T>(self: state<T>)
	for _, callback in self._connections do
		Promise.new(function(resolve, reject)
			local val = self:get()
			if type(val) == "table" and self._doesUnpack == true and val and next(val) then
				resolve(callback(table.unpack(val)))
			elseif val then
				resolve(callback(val))
			else
				reject(val)
			end
		end):catch(warn)
	end
end

function State.connect<T>(self: state<T>, callback: (value: T, ...any) -> any, on_disconnect: (() -> ())?): () -> ()
	self._connections[callback] = callback

	return function()
		self._connections[callback] = nil
		if on_disconnect ~= nil then
			on_disconnect()
		end
	end
end

function State.toString<T>(self: state<T>)
	return tostring(self:get())
end

return State :: StateModule
