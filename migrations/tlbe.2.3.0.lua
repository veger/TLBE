if storage.playerSettings == nil then
    return
end

-- Viewfinder boxes are now drawn as chart-mode render objects (see scripts/camera.lua)
-- instead of sets of chart tags. Remove any left-over chart tags from existing cameras
-- and initialise the new renderBoxes field.
for _, playerSettings in pairs(storage.playerSettings) do
    if playerSettings.cameras ~= nil then
        for _, camera in pairs(playerSettings.cameras) do
            ---@diagnostic disable-next-line: undefined-field -- chartTags removed in v2.3.0
            if camera.chartTags ~= nil then
                ---@diagnostic disable-next-line: undefined-field
                for _, tag in pairs(camera.chartTags) do
                    if tag.valid then
                        tag.destroy()
                    end
                end
                ---@diagnostic disable-next-line: inject-field
                camera.chartTags = nil
            end
            camera.renderBoxes = {}
        end
    end
end
