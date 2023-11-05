//
// Network
//

/*
Upload
    1 - Add Chat Message
Receive
    0 - Player is Ready
*/

util.AddNetworkString("gmIntegration")

// Send
function gmInte.SendNet(id, data, ply, func)
    net.Start("gmIntegration")
        net.WriteUInt(id, 8)
        net.WriteString(util.TableToJSON(data))
        if (func) then func() end
    if (ply == nil) then
        net.Broadcast()
    else
        net.Send(ply)
    end
end

// Receive
local netFuncs = {
    [0] = function(ply)
        gmInte.userFinishConnect(ply)
        // set gmInteTime to acual time
        ply.gmIntTimeConnect = os.time()
    end,
}

net.Receive("gmIntegration", function(len, ply)
    if !ply:IsPlayer() then return end
    local id = net.ReadUInt(8)
    local data = util.JSONToTable(net.ReadString() || "{}")
    if (netFuncs[id]) then netFuncs[id](ply, data) end
end)