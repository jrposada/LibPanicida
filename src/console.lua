local this = {}

---Logs obj to chat
---@param obj any
function this.log(obj)
    zo_callLater(function() d(obj) end, 200)
end

LibPanicida.Console = this
