if storage.playerSettings == nil then
    return
end

local Camera = require("scripts.camera")

-- Viewfinder boxes are now drawn as chart-mode render objects (see scripts/camera.lua)
-- instead of sets of chart tags. Remove any left-over chart tags from existing cameras,
-- initialise the new renderBoxes field, and activate the "render disabled cameras"
-- setting + draw the boxes now (Config.reload is not guaranteed to run for existing
-- players on upgrade).
for player_index, playerSettings in pairs(storage.playerSettings) do
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

        local player = game.players[player_index]
        if player ~= nil then
            playerSettings.renderDisabledCameras =
                settings.get_player_settings(player)["tlbe-render-disabled-cameras"].value
            Camera.refreshAllBoxes(player, playerSettings)
        end
    end
end
