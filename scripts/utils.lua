local Utils = {}

function Utils.uniqueName(list, name)
    for _, entry in pairs(list) do
        if entry.name == name then
            return false
        end
    end

    return true
end

return Utils
