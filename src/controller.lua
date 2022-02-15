-- this driver is included into openresty
-- https://github.com/openresty/lua-resty-redis
local redis = require "resty.redis"
local leaderboard = require "leaderboard"

local controller = {}

local redis_host = "redis"
local redis_port = 6379
local expected_concurrent_users = 10000
local connect_timeout = 20 -- ms
local send_timeout = 20 -- ms
local read_timeout = 20 -- ms
local max_idle_timeout = 5000 -- ms (connection pool timeout)

controller.start_redis_client = function()
  local pool_size = expected_concurrent_users / ngx.worker.count()
  local redis_client, err = redis:new()
  if err ~= nil then
    return nil, err
  end

  redis_client:set_timeouts(connect_timeout, send_timeout, read_timeout)
  local _, err = redis_client:connect(redis_host, redis_port, {pool_size=pool_size})

  if err ~= nil then
    return nil, err
  end

  return redis_client, nil
end

controller.finish_redis_client = function(redis_client)
  local pool_size = expected_concurrent_users / ngx.worker.count()
  return redis_client:set_keepalive(max_idle_timeout, pool_size)
end

controller.token_hit = function()
  local redis_client, err = controller.start_redis_client()
  if err ~= nil then
    ngx.log(ngx.ERR, err)
    return
  end

  local _, err = leaderboard.hit(redis_client, ngx.var.arg_token)
  if err ~= nil then
    ngx.log(ngx.ERR, err)
    return
  end

  local _, err = controller.finish_redis_client(redis_client)
  if err ~= nil then
    ngx.log(ngx.ERR, err)
    return
  end
end

controller.render_top_used_tokens = function()
  local redis_client, err = controller.start_redis_client()
  if err ~= nil then
    ngx.log(ngx.ERR, err)
    return
  end

  local json_response, err = leaderboard.top(redis_client, ngx.var.arg_quantity or 10)
  if err ~= nil then
    ngx.log(ngx.ERR, err)
    return
  end

  ngx.header.content_type = "application/json"
  ngx.say(json_response)

  local _, err = controller.finish_redis_client(redis_client)
  if err ~= nil then
    ngx.log(ngx.ERR, err)
    return
  end
end

return controller
