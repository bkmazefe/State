--!nonstrict
--[[
	State management module written by @bkmazefe. Inspired from Elttob's States in Fusion Library.
	https://github.com/bkmazefe/State
]]
local Promise = require(game.ReplicatedStorage.Packages.Promise)

--[=[
	Lightweight state management module
	@class State
]=]
local State = {}
State.__index = State

--[=[
	@within State
	@interface State<T>
	.set (self: State<T>, new_value: T, force_update: boolean?) -> ()
	.get (self: State<T>) -> T
	.connect (self: State<T>, callback: (value: T) -> (), on_disconnect: (() -> ())?) -> () -> ()
]=]
export type State<T> = {
	set: (self: State<T>, new_value: T, force_update: boolean?) -> (),
	get: (self: State<T>) -> T,
	connect: (self: State<T>, callback: (value: T) -> (), on_disconnect: (() -> ())?) -> () -> (),
}

--[=[
	@within State
	@interface StateModule
	.new <T>(value: T, doesUnpack: boolean?) -> State<T>
]=]
export type StateModule = {
	new: <T>(value: T, doesUnpack: boolean?) -> State<T>,
}

--[=[
	@within State
	@interface state<T>
	.new (T) -> state<T>
	.set (self: state<T>, new_value: T, force_update: boolean?) -> ()
	.get (self: state<T>) -> T
	.connect (self: state<T>, callback: (value: T) -> (), on_disconnect: (() -> ())?) -> () -> ()
	._updateAll (self: state<T>) -> ()
	.toString (self: state<T>) -> ()
	_doesUnpack boolean
	_connections { [(value: T) -> ()]: (value: T) -> () }
	.stored_value T
	@private
]=]
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

--[=[
	Creates a new State object
	@within State
	@method new
	@param value T -- The initial value of the state
	@param doesUnpack boolean? -- Whether the state should unpack the value when calling the callback. Can be useful for passing multiple parameters to a function
	@return State<T>
]=]
function State.new<T>(value: T, doesUnpack: boolean?): State<T>
	local self = setmetatable({
		stored_value = value,
		_connections = setmetatable({}, WEAK_KEYS_METATABLE),
		_doesUnpack = doesUnpack and true or false,
	}, State)

	return self
end

--[=[
	Sets the value of the State object
	@within State
	@method set
	@param value T -- The initial value of the state
	@param force_update boolean? -- Whether the state should update the callbacks even if the value is the same
	@return state<T>
]=]
function State.set<T>(self: state<T>, new_value: T, force_update: boolean?)
	if force_update == true or (self.stored_value ~= new_value and force_update == nil) then
		self.stored_value = new_value
		self:_updateAll()
		return
	end
end

--[=[
	Gets the value of the State object
	@within State
	@method get
	@return T
]=]
function State.get<T>(self: state<T>): T
	return self.stored_value
end

--[=[
	Calls all the connected callbacks when the value of the state changes.
	@within State
	@method _updateAll
	@return nil
	@private
]=]
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

--[=[
	@within State
	@method connect
	@param callback (value: T) -> () -- The callback to connect
	@param on_disconnect (() -> ())? -- This will be called just before the connection gets disconnected
	@return () -> () -- The disconnect function, call this to disconnect the connection
]=]
function State.connect<T>(self: state<T>, callback: (value: T, ...any) -> any, on_disconnect: (() -> ())?): () -> ()
	self._connections[callback] = callback

	return function()
		self._connections[callback] = nil
		if on_disconnect ~= nil then
			on_disconnect()
		end
	end
end

--[=[
	@within State
	@method toString
	@return string
]=]
function State.toString<T>(self: state<T>)
	return tostring(self:get())
end

return State :: StateModule
