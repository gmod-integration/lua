local GmodIntegration_HTTP = {}
GmodIntegration_HTTP.__index = GmodIntegration_HTTP
setmetatable(gmInte, GmodIntegration_HTTP)
function GmodIntegration_HTTP:New()
    local self = setmetatable({}, GmodIntegration_HTTP)
    self.method = "GET"
    self.endpoint = "/"
    self.data = {}
    self.isStackableLog = false
    self.requestID = util.CRC(tostring(SysTime()))
    self.success = function() end
    self.failed = function() end
    return self
end

function GmodIntegration_HTTP:Method(method)
    self.method = method.upper()
    return self
end

function GmodIntegration_HTTP:Endpoint(endpoint)
    self.endpoint = endpoint
    return self
end

function GmodIntegration_HTTP:Data(data)
    self.data = data
    return self
end

function GmodIntegration_HTTP:OnSuccess(callback)
    self.success = callback
    return self
end

function GmodIntegration_HTTP:OnFailed(callback)
    self.failed = callback
    return self
end

function GmodIntegration_HTTP:IsStackableLog(isStackable)
    self.isStackableLog = isStackable
    return self
end

local apiVersion = "v3"
function GmodIntegration_HTTP:GetFinalUrl()
    local method = gmInte.isPrivateIP(gmInte.config.apiFQDN) && "http" || "https"
    local endpoint = string.gsub(self.endpoint, ":serverID", gmInte.config.id)
    if CLIENT then endpoint = string.gsub(endpoint, ":steamID64", LocalPlayer():SteamID64()) end
    return method .. "://" .. gmInte.config.apiFQDN .. "/" .. apiVersion .. endpoint
end

function GmodIntegration_HTTP:ShowableBody()
    if string.sub(self.endpoint, 1, 8) == "/streams" || string.sub(self.endpoint, 1, 12) == "/screenshots" then return false end
    return true
end

function GmodIntegration_HTTP:Send()
    local body = util.TableToJSON(self.data)
    local token = gmInte.config.token
    local url = self:GetFinalUrl()
    local method = self.method
    local success = self.success
    local failed = self.failed
    local version = gmInte.version
    local showableBody = self:ShowableBody()
    local localRequestID = self.requestID
    if token == "" then
        return failed(401, {
            ["error"] = "No token provided"
        })
    end

    gmInte.log("HTTP FQDN: " .. gmInte.config.apiFQDN, true)
    gmInte.log("HTTP Request ID: " .. localRequestID, true)
    gmInte.log("HTTP Request: " .. method .. " " .. url, true)
    gmInte.log("HTTP Body: " .. (showableBody && body || "HIDDEN"), true)
    HTTP({
        ["url"] = url,
        ["method"] = method,
        ["headers"] = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = string.len(body),
            ["Authorization"] = "Bearer " .. token,
            ["Gmod-Integrations-Version"] = version,
            ["Gmod-Integrations-Request-ID"] = localRequestID
        },
        ["body"] = body,
        ["type"] = "application/json",
        ["success"] = function(code, body, headers)
            gmInte.log("HTTP Request ID: " .. localRequestID, true)
            gmInte.log("HTTP Response: " .. code, true)
            gmInte.log("HTTP Body: " .. body, true)
            if !headers["Content-Type"] || string.sub(headers["Content-Type"], 1, 16) != "application/json" then
                gmInte.log("HTTP Failed: Invalid Content-Type", true)
                return failed(code, body)
            end

            body = util.JSONToTable(body || "{}")
            if code < 200 || code >= 300 then
                gmInte.log("HTTP Failed: Invalid Status Code", true)
                return failed(code, body)
            end

            gmInte.aprovedCredentials = true
            return success(code, body)
        end,
        ["failed"] = function(error)
            gmInte.log("HTTP Request ID: " .. localRequestID, true)
            gmInte.log("HTTP Failed: " .. error, true)
        end
    })
end

// Retrocompatibility
gmInte.http = {}
local function retroCompatibilityRequest(mathod, endpoint, data, onSuccess, onFailed)
    local newRequest = GmodIntegration_HTTP:New():Endpoint(endpoint)
    if data then newRequest:Data(data) end
    if onSuccess then newRequest:OnSuccess(onSuccess) end
    if onFailed then newRequest:OnFailed(onFailed) end
    newRequest:Send()
end

function gmInte.http.get(endpoint, onSuccess, onFailed)
    retroCompatibilityRequest("GET", endpoint, nil, onSuccess, onFailed)
end

function gmInte.http.post(endpoint, data, onSuccess, onFailed)
    retroCompatibilityRequest("POST", endpoint, data, onSuccess, onFailed)
end

function gmInte.http.put(endpoint, data, onSuccess, onFailed)
    retroCompatibilityRequest("PUT", endpoint, data, onSuccess, onFailed)
end

function gmInte.http.delete(endpoint, onSuccess, onFailed)
    retroCompatibilityRequest("DELETE", endpoint, nil, onSuccess, onFailed)
end