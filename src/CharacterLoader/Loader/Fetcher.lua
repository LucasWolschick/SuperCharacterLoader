local Players = game:GetService("Players")

local Fetcher = {}
-- We start our cache with our default user, Telamon, to avoid initial calls.
local user_id_cache = {["Telamon"] = 13645}

--- Fetches a player ID from a username and returns it.
-- Note that this function verifies firstly if the given string is an username
-- and, if not, if it is an ID afterwards. This means that querying '156', ie,
-- will return the user named '156' and not builderman (with id 156). This func-
-- tion also caches its results, which can be cleared with Fetcher.clear_cache().
-- @param query The string to be queried.
-- @return id The player ID, if it was found, or nil otherwise.
-- @see Fetcher.clear_cache
function Fetcher.get_id(query: string): number?
	-- trim the query and make it lowercase (usernames are case insensitive)
	-- note: are there any players with leading or trailing spaces in their names?
	local query = string.match(string.lower(query), "%s*(.-)%s*$")
	
	-- return from the cache if it exists
	if user_id_cache[query] then
		return user_id_cache[query]
	end

	-- first, check if there is a player with such username.
	local exists, id = pcall(Players.GetUserIdFromNameAsync, Players, query)
	if exists then
		return id
	end

	-- second, if the input is a number, check if such userid exists too with a dummy call
	local number = tonumber(query)
	if number ~= nil then
		local exists, _ = pcall(Players.GetNameFromUserIdAsync, Players, number)
		if exists then
			user_id_cache[query] = number
			return number
		end
	end

	-- otherwise, no luck
	return nil
end

--- Clears the internal name->id cache.
function Fetcher.clear_cache()
	user_id_cache = {["Telamon"] = 13645}
end

return Fetcher