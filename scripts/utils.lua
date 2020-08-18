local Utils = {}

function Utils.findName(list, name)
    for _, entry in pairs(list) do
        if entry.name == name then
            return entry
        end
    end

    return nil
end

function Utils.uniqueName(list, name)
    for _, entry in pairs(list) do
        if entry.name == name then
            return false
        end
    end

    return true
end

function Utils.filterOut(completeList, filterList)
    local resultList = {}

    for _, entry1 in pairs(completeList) do
        for _, entry2 in pairs(filterList) do
            if entry1 == entry2 then
                goto nextEntry
            end
        end

        -- entry1 was not in filterList
        table.insert(resultList, entry1)

        ::nextEntry::
    end

    return resultList
end

return Utils
