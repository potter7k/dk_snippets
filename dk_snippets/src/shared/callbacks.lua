--[[ 
    -- CREDITS:
    https://github.com/pitermcflebor/pmc-callbacks
]]

-- MIT License
-- Copyright (c) 2020 PiterMcFlebor
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local IS_SERVER = IsDuplicityVersion()
local table_unpack = table.unpack
local debug = debug
local debug_getinfo = debug.getinfo
local msgpack = msgpack
local msgpack_pack = msgpack.pack
local msgpack_unpack = msgpack.unpack
local msgpack_pack_args = msgpack.pack_args
local PENDING = 0
local REJECTING = 2
local REJECTED = 4

local function ensure(obj, typeof, opt_typeof, errMessage)
	local objtype = type(obj)
	local di = debug_getinfo(2)
	local diName = di.name or 'unknown'
	local errMessage = errMessage or (opt_typeof == nil and ((diName) .. ' expected %s, but got %s') or ((diName) .. ' expected %s or %s, but got %s'))
	if typeof ~= 'function' then
		if objtype ~= typeof and objtype ~= opt_typeof then
			error((errMessage):format(typeof, (opt_typeof == nil and objtype or opt_typeof), objtype))
		end
	else
		if objtype == 'table' and not rawget(obj, '__cfx_functionReference') then
			error((errMessage):format(typeof, (opt_typeof == nil and objtype or opt_typeof), objtype))
		end
	end
end

if IS_SERVER then
	_G.RegisterServerCallback = function(eventName, eventCallback)
		ensure(eventName, 'string'); ensure(eventCallback, 'function')

		local eventCallback = eventCallback
		local eventName = eventName
		local eventData = RegisterNetEvent('dk__server_callback:'..eventName, function(packed, src, cb)
			local source = tonumber(source)
			if not source then
				cb( msgpack_pack_args( eventCallback(src, table_unpack(msgpack_unpack(packed)) ) ) )
			else
				TriggerClientEvent(('dk__client_callback_response:%s:%s'):format(eventName, source), source, msgpack_pack_args( eventCallback(source, table_unpack(msgpack_unpack(packed)) ) ))
			end
		end)
		return eventData
	end

	_G.UnregisterServerCallback = function(eventData)
		RemoveEventHandler(eventData)
	end

	_G.TriggerClientCallback = function(source, eventName, args, eventCallback, timeout, timedout)
		ensure(source, 'string', 'number'); ensure(eventName, 'string'); ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')
		if tonumber(source) >= 0 then
			local ticket = tostring(source) .. 'x' .. tostring(GetGameTimer())
			local prom = promise.new()
			local eventCallback = eventCallback
			local eventData = RegisterNetEvent(('dk__callback_retval:%s:%s:%s'):format(source, eventName, ticket), function(packed)
				if eventCallback and prom.state == PENDING then eventCallback( table_unpack(msgpack_unpack(packed)) ) end
				prom:resolve( table_unpack(msgpack_unpack(packed)) )
			end)

			TriggerClientEvent(('dk__client_callback:%s'):format(eventName), source, msgpack_pack(args or {}), ticket)

			if timeout ~= nil and timedout then
				local timedout = timedout
				SetTimeout(timeout * 1000, function()
					if
						prom.state == PENDING or
						prom.state == REJECTED or
						prom.state == REJECTING
					then
						timedout(prom.state)
						if prom.state == PENDING then prom:reject() end
						RemoveEventHandler(eventData)
					end
				end)
			end

			if not eventCallback then
				local result = Citizen.Await(prom)
				RemoveEventHandler(eventData)
				return result
			end
		else
			error 'source should be equal too or higher than 0'
		end
	end

	_G.TriggerServerCallback = function(source, eventName, args, eventCallback, timeout, timedout)
		ensure(source, 'string', 'number'); ensure(eventName, 'string'); ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')

		local prom = promise.new()
		local eventCallback = eventCallback
		local eventName = eventName
		TriggerEvent('dk__server_callback:'..eventName, msgpack_pack(args or {}), source,
		function(packed)
			if eventCallback and prom.state == PENDING then eventCallback( table_unpack(msgpack_unpack(packed)) ) end
			prom:resolve( table_unpack(msgpack_unpack(packed)) )
		end)

		if timeout ~= nil and timedout then
			local timedout = timedout
			SetTimeout(timeout * 1000, function()
				if
					prom.state == PENDING or
					prom.state == REJECTED or
					prom.state == REJECTING
				then
					timedout(prom.state)
					if prom.state == PENDING then prom:reject() end
				end
			end)
		end

		if not eventCallback then
			return Citizen.Await(prom)
		end
	end
end

if not IS_SERVER then
	local SERVER_ID = GetPlayerServerId(PlayerId())

	_G.RegisterClientCallback = function(eventName, eventCallback)
		ensure(eventName, 'string'); ensure(eventCallback, 'function')
		
		local eventCallback = eventCallback
		local eventName = eventName
		local eventData = RegisterNetEvent('dk__client_callback:'..eventName, function(packed, ticket)
			if type(ticket) == 'function' then
				ticket( msgpack_pack_args( eventCallback( table_unpack(msgpack_unpack(packed)) ) ) )
			else
				TriggerServerEvent(('dk__callback_retval:%s:%s:%s'):format(SERVER_ID, eventName, ticket), msgpack_pack_args( eventCallback( table_unpack(msgpack_unpack(packed)) ) ))
			end
		end)
		return eventData
	end

	_G.UnregisterClientCallback = function(eventData)
		RemoveEventHandler(eventData)
	end

	_G.TriggerServerCallback = function(eventName, args, eventCallback, timeout, timedout)
		ensure(args, 'table', 'nil'); ensure(eventName, 'string'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')
		
		local prom = promise.new()
		local eventCallback = eventCallback
		local eventData = RegisterNetEvent(('dk__client_callback_response:%s:%s'):format(eventName, SERVER_ID),
		function(packed)
			if eventCallback and prom.state == PENDING then eventCallback( table_unpack(msgpack_unpack(packed)) ) end
			prom:resolve( table_unpack(msgpack_unpack(packed)) )

		end)

		TriggerServerEvent('dk__server_callback:'..eventName, msgpack_pack( args ))

		if timeout ~= nil and timedout then
			local timedout = timedout
			SetTimeout(timeout * 1000, function()
				if
					prom.state == PENDING or
					prom.state == REJECTED or
					prom.state == REJECTING
				then
					timedout(prom.state)
					if prom.state == PENDING then prom:reject() end
					RemoveEventHandler(eventData)
				end
			end)
		end

		if not eventCallback then
			local result = Citizen.Await(prom)
			RemoveEventHandler(eventData)
			return result
		end
	end

	_G.TriggerClientCallback = function(eventName, args, eventCallback, timeout, timedout)
		ensure(eventName, 'string'); ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')

		local prom = promise.new()
		local eventCallback = eventCallback
		local eventName = eventName
		TriggerEvent('dk__client_callback:'..eventName, msgpack_pack(args or {}),
		function(packed)
			if eventCallback and prom.state == PENDING then eventCallback( table_unpack(msgpack_unpack(packed)) ) end
			prom:resolve( table_unpack(msgpack_unpack(packed)) )
		end)

		-- timeout response
		if timeout ~= nil and timedout then
			local timedout = timedout
			SetTimeout(timeout * 1000, function()
				if
					prom.state == PENDING or
					prom.state == REJECTED or
					prom.state == REJECTING
				then
					timedout(prom.state)
					if prom.state == PENDING then prom:reject() end
				end
			end)
		end

		if not eventCallback then
			return Citizen.Await(prom)
		end
	end
end