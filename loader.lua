-- NX Loader
local URL = "https://raw.githubusercontent.com/ANONIMCHR/KEY-LISN/refs/heads/main/cheatroblox.lua"
local u = URL .. "?t=" .. tostring(os.time())
local function f(x)
    local ok, r
    if syn and syn.request then ok, r = pcall(function() return syn.request({Url=x,Method="GET"}).Body end)
    elseif fluxus and fluxus.request then ok, r = pcall(function() return fluxus.request({Url=x,Method="GET"}).Body end)
    elseif http and http.request then ok, r = pcall(function() return http.request({Url=x,Method="GET"}).Body end)
    elseif request then ok, r = pcall(function() return request({Url=x,Method="GET"}).Body end)
    else ok, r = pcall(function() return game:HttpGet(x) end) end
    return ok and r or nil
end
local s = f(u) or f(URL)
if not s or #s < 100 then warn("[NX] fetch failed") return end
local fn, e = loadstring(s)
if not fn then warn("[NX] "..tostring(e)) return end
fn()
