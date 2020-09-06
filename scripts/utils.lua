local Utils = {}

Utils.boundarySize = 2

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

function Utils.entityBBox(entity)
    -- top/bottom seems to be swapped, so use this table to reduce confusion of rest of the code
    return {
        left = entity.bounding_box.left_top.x - Utils.boundarySize,
        bottom = entity.bounding_box.left_top.y - Utils.boundarySize,
        right = entity.bounding_box.right_bottom.x + Utils.boundarySize,
        top = entity.bounding_box.right_bottom.y + Utils.boundarySize
    }
end

function Utils.findChartTag(tags, name)
    for _, tag in ipairs(tags) do
        if tag.text == name then
            return tag
        end
    end

    return nil
end

return Utils
