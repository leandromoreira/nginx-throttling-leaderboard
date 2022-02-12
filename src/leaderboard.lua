local leaderboard = {}

local key_prefix = "leaderboard"
local math_floor = math.floor
local ngx_now = ngx.now

leaderboard.hit = function(redis_client, token)
  local current_key = key_prefix .. math_floor((ngx_now() / 60) % 60)

  redis_client:init_pipeline()
  redis_client:zincrby(current_key, 1, token)
  redis_client:expire(current_key, 2 * 60, "NX")

  local resp, err = redis_client:commit_pipeline()
  if err then
    return nil, err
  end

  return resp[1]
end

leaderboard.top = function(redis_client, quantity)
  local current_key = key_prefix .. math_floor((ngx_now() / 60) % 60)
  quantity = quantity or 10

  local resp, err = redis_client:zrange(current_key, 0, quantity - 1, "REV", "WITHSCORES")
  if err then
    return nil, err
  end

  local total_items = #resp
  local i = 1
  local response = {}

  while i <= total_items do
    local item = {[resp[i]]=resp[i+1]}
    table.insert(response, item)
    i = i + 2
  end

  return require "cjson".encode(response)
end

return leaderboard
