local redis = require "resty.redis"
local leaderboard = require "leaderboard"

local controller = {}

controller.start_redis_client = function()
  local redis_client = redis:new()
  redis_client:set_timeouts(1000, 1000, 1000)
  local _, _ = redis_client:connect("redis", 6379)
  return redis_client
end

controller.finish_redis_client = function(redis_client)
  local _, _ = redis_client:set_keepalive(10000, 100)
end

controller.hit = function(token)
  local redis_client = controller.start_redis_client()
  leaderboard.hit(redis_client, token)
  controller.finish_redis_client(redis_client)
end

controller.top = function(quantity)
  local redis_client = controller.start_redis_client()
  local results = leaderboard.top(redis_client, quantity)
  controller.finish_redis_client(redis_client)
  return results
end

return controller
