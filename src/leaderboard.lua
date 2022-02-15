local leaderboard = {}

local key_prefix = "leaderboard_"
local math_floor = math.floor
local ngx_now = ngx.now
local ttl = 2 * 60 + 30 -- 2.5s

leaderboard.key_prefix = key_prefix
leaderboard.ttl = ttl
leaderboard.now = ngx_now

leaderboard._current_minute = function()
  return math_floor((leaderboard.now() / 60) % 60)
end

leaderboard._current_key = function()
  return leaderboard.key_prefix .. leaderboard._current_minute()
end

leaderboard._past_minute = function()
  return (leaderboard._current_minute() + 59) % 60
end

leaderboard._past_key = function()
  return leaderboard.key_prefix .. leaderboard._past_minute()
end

leaderboard.hit = function(redis_client, token)
  if redis_client == nil or token == nil or token == "" then
    return nil, "you must inform the redis client and a proper token"
  end

  redis_client:init_pipeline()
  redis_client:expire(leaderboard._current_key(), leaderboard.ttl) -- set expire time for current key
  redis_client:zincrby(leaderboard._current_key(), 1, token) -- increment token usage each time

  local resp, err = redis_client:commit_pipeline()
  if err then
    return nil, err
  end

  return resp, nil
end

leaderboard.top = function(redis_client, quantity)
  if redis_client == nil then
    return nil, "you must inform the redis client"
  end
  quantity = quantity or 10

  local root_response = {}

  root_response["current_minute"]=leaderboard._current_minute()
  local response, _ = leaderboard._top(redis_client, leaderboard._current_key(), quantity)
  root_response["current_ranking"] = response

  root_response["past_minute"]=leaderboard._past_minute()
  response, _ = leaderboard._top(redis_client, leaderboard._past_key(), quantity)
  root_response["past_ranking"] = response

  return require "cjson".encode(root_response)
end

leaderboard._top = function(redis_client, key, quantity)
  local resp, err = redis_client:zrange(key, 0, quantity - 1, "REV", "WITHSCORES")

  if err then
    return {}, err
  end

  local total_items = #resp
  local i = 1
  local response = {}

  while i <= total_items do
    local item = {[resp[i]]=resp[i+1]}
    table.insert(response, item)
    i = i + 2
  end

  return response, nil
end

return leaderboard
