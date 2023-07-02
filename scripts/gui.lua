local GUI = {
    allTrackers = { "area", "base", "cityblock", "player", "rocket" },
    allTrackersLabels = { { "tracker-area" }, { "tracker-base" }, { "tracker-cityBlock" }, { "tracker-player" }, { "tracker-rocket" } },
    allTrackersLabelsMap = {
        area = { "tracker-area" },
        base = { "tracker-base" },
        cityBlock = { "tracker-cityBlock" },
        player = { "tracker-player" },
        rocket = { "tracker-rocket" },
    }
}

local Camera = require("scripts.camera")
local Main = require("scripts.main")
local Tracker = require("scripts.tracker")
local Utils = require("scripts.utils")

local ticks_per_half_second = 30

local function getWindowPlayButtonStyle(selected)
    if selected then
        return "tlbe_frame_action_button_selected"
    end

    return "frame_action_button"
end

local function findActiveTracker(trackers, surfaceName)
    for _, tracker in pairs(trackers) do
        if tracker.enabled == true and tracker.surfaceName == surfaceName then
            return tracker
        end
    end
end

-- Initialize the GUI for a new player
---@param player LuaPlayer
---@param playerSettings playerSettings
function GUI.initialize(player, playerSettings)
    GUI.updateTakeScreenshotButton(player, playerSettings)
end

function GUI.tick()
    if game.tick % ticks_per_half_second ~= 0 then
        return
    end

    -- TODO performance: Use some kind of event system to update the GUI for
    for _, player in pairs(game.players) do
        local playerSettings = global.playerSettings[player.index]
        if playerSettings.gui ~= nil then
            if playerSettings.gui.cameraInfo.valid then
                local camera = playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
                GUI.updateCameraInfo(playerSettings.gui.cameraInfo, camera)

                GUI.updateTrackerInfo(
                    playerSettings.gui.cameraTrackerInfo,
                    camera.trackers[playerSettings.guiPersist.selectedCameraTracker]
                )
            end

            if playerSettings.gui.cameraTrackerList.valid then
                GUI.createTrackerList(
                    playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
                    playerSettings.gui.cameraTrackerList,
                    playerSettings.guiPersist.selectedCameraTracker,
                    playerSettings.cameras,
                    playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
                    "camera_tracker_",
                    GUI.addCameraTrackerButtons
                )
            end

            if playerSettings.gui.trackerList.valid then
                GUI.createTrackerList(
                    playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
                    playerSettings.gui.trackerList,
                    playerSettings.guiPersist.selectedTracker,
                    playerSettings.cameras,
                    playerSettings.trackers,
                    "tracker_",
                    GUI.addTrackerButtons
                )
            end

            if playerSettings.gui.trackerInfo.valid then
                GUI.updateTrackerInfo(
                    playerSettings.gui.trackerInfo,
                    playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
                )
            end
        end
    end
end

---@param event EventData.on_gui_click
function GUI.onClick(event)
    local player = game.players[event.player_index]
    ---@type playerSettings
    local playerSettings = global.playerSettings[event.player_index]

    if event.element.name == "tlbe-main-window-close" then
        GUI.closeMainWindow(event)
    elseif event.element.name == "tlbe-main-window-pause" then
        playerSettings.pauseOnOpen = not playerSettings.pauseOnOpen
        game.tick_paused = playerSettings.pauseOnOpen

        event.element.style = getWindowPlayButtonStyle(playerSettings.pauseOnOpen)
    elseif event.element.name == "tlbe_camera_enable" then
        local selectedCamera = playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        selectedCamera.enabled = not selectedCamera.enabled

        GUI.updateCameraActions(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateTakeScreenshotButton(player, playerSettings)
    elseif event.element.name == "tlbe_camera_add" then
        table.insert(playerSettings.cameras, Camera.newCamera(player, playerSettings.cameras))
        GUI.setSelectedCamera(player, playerSettings, #playerSettings.cameras)

        GUI.updateCameraList(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateCameraActions(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateCameraConfig(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
        GUI.updateCameraInfo(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
        GUI.createCameraTrackerList(playerSettings)
    elseif event.element.name == "tlbe_camera_delete" then
        if #playerSettings.cameras == 1 then
            -- Paranoia check
            return
        end

        local deadCamera = table.remove(playerSettings.cameras, playerSettings.guiPersist.selectedCamera)
        Camera.destroy(deadCamera)

        if playerSettings.guiPersist.selectedCamera > #playerSettings.cameras then
            GUI.setSelectedCamera(player, playerSettings, #playerSettings.cameras)
        end

        GUI.updateCameraList(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateCameraActions(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateCameraConfig(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
        GUI.updateCameraInfo(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
        GUI.createTrackerList(
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
            playerSettings.gui.trackerList,
            playerSettings.guiPersist.selectedTracker,
            playerSettings.cameras,
            playerSettings.trackers,
            "tracker_",
            GUI.addTrackerButtons
        )
        GUI.createCameraTrackerList(playerSettings)
    elseif event.element.name == "tlbe_camera_refresh" then
        Camera.refreshConfig(playerSettings.cameras[playerSettings.guiPersist.selectedCamera])

        GUI.updateCameraConfig(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
    elseif event.element.name == "tlbe-tracker-tr-player" then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        -- Note that game origin is top-left, so top is min and bottom is max
        selectedTracker.maxPos.x = math.floor(player.position.x)
        selectedTracker.minPos.y = math.floor(player.position.y)
        Tracker.areaUpdateCenterAndSize(selectedTracker)

        GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
        GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
    elseif event.element.name == "tlbe-tracker-bl-player" then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        -- Note that game origin is top-left, so top is min and bottom is max
        selectedTracker.minPos.x = math.floor(player.position.x)
        selectedTracker.maxPos.y = math.floor(player.position.y)
        Tracker.areaUpdateCenterAndSize(selectedTracker)

        GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
        GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
    elseif event.element.name == "tlbe-tracker-tr-map" then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        local tag = Utils.findChartTag(player.force.find_chart_tags(game.surfaces[1]), selectedTracker.name .. "-tr")
        if tag == nil then
            player.print({ "tag-not-found", selectedTracker.name .. "-tr" })
        else
            -- Note that game origin is top-left, so top is min and bottom is max
            selectedTracker.maxPos.x = math.floor(tag.position.x)
            selectedTracker.minPos.y = math.floor(tag.position.y)
            Tracker.areaUpdateCenterAndSize(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-bl-map" then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        local tag = Utils.findChartTag(player.force.find_chart_tags(game.surfaces[1]), selectedTracker.name .. "-bl")
        if tag == nil then
            player.print({ "tag-not-found", selectedTracker.name .. "-bl" })
        else
            -- Note that game origin is top-left, so top is min and bottom is max
            selectedTracker.minPos.x = math.floor(tag.position.x)
            selectedTracker.maxPos.y = math.floor(tag.position.y)
            Tracker.areaUpdateCenterAndSize(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-cityblock-player" then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        Tracker.focusCityBlock(selectedTracker, player.position)

        GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
        GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
    else
        local _, index
        _, _, index = event.element.name:find("^camera_tracker_(%d+)$")
        if index ~= nil then
            index = tonumber(index)
            ---@diagnostic disable-next-line: assign-type-mismatch Pattern only allows for integers
            playerSettings.guiPersist.selectedCameraTracker = index
            GUI.fancyListBoxSelectItem(playerSettings.gui.cameraTrackerList, index)
            GUI.updateTrackerInfo(
                playerSettings.gui.cameraTrackerInfo,
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers[
                playerSettings.guiPersist.selectedCameraTracker
                ]
            )
            return
        end

        _, _, index = event.element.name:find("^tracker_(%d+)$")
        if index ~= nil then
            index = tonumber(index)
            ---@diagnostic disable-next-line: assign-type-mismatch Pattern only allows for integers
            playerSettings.guiPersist.selectedTracker = index
            GUI.fancyListBoxSelectItem(playerSettings.gui.trackerList, index)
            GUI.createTrackerConfigAndInfo(
                playerSettings.gui.trackerInfo,
                playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
            )
            return
        end

        _, _, index = event.element.name:find("^tracker_(%d+)_enable$")
        if index ~= nil then
            index = tonumber(index)
            playerSettings.trackers[index].enabled = playerSettings.trackers[index].enabled == false

            GUI.createTrackerList(
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
                playerSettings.gui.trackerList,
                playerSettings.guiPersist.selectedTracker,
                playerSettings.cameras,
                playerSettings.trackers,
                "tracker_",
                GUI.addTrackerButtons
            )

            GUI.createTrackerList(
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
                playerSettings.gui.cameraTrackerList,
                playerSettings.guiPersist.selectedCameraTracker,
                playerSettings.cameras,
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
                "camera_tracker_",
                GUI.addCameraTrackerButtons
            )
            return
        end

        _, _, index = event.element.name:find("^camera_tracker_(%d+)_up$")
        if index ~= nil then
            index = tonumber(index)
            if index == nil then
                return
            end

            local cameraTrackers = playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers
            local tmp = cameraTrackers[index]
            cameraTrackers[index] = cameraTrackers[index - 1]
            cameraTrackers[index - 1] = tmp
            if playerSettings.guiPersist.selectedCameraTracker == index then
                playerSettings.guiPersist.selectedCameraTracker = index - 1
            elseif playerSettings.guiPersist.selectedCameraTracker == index - 1 then
                playerSettings.guiPersist.selectedCameraTracker = index
            end

            GUI.createCameraTrackerList(playerSettings)

            return
        end

        _, _, index = event.element.name:find("^camera_tracker_(%d+)_down")
        if index ~= nil then
            index = tonumber(index)
            if index == nil then
                return
            end

            local cameraTrackers = playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers
            local tmp = cameraTrackers[index]
            cameraTrackers[index] = cameraTrackers[index + 1]
            cameraTrackers[index + 1] = tmp
            if playerSettings.guiPersist.selectedCameraTracker == index then
                playerSettings.guiPersist.selectedCameraTracker = index + 1
            elseif playerSettings.guiPersist.selectedCameraTracker == index + 1 then
                playerSettings.guiPersist.selectedCameraTracker = index
            end

            GUI.createCameraTrackerList(playerSettings)

            return
        end

        _, _, index = event.element.name:find("^camera_tracker_(%d+)_remove$")
        if index ~= nil then
            index = tonumber(index)
            if index == nil then
                return
            end

            table.remove(playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers, math.floor(index))
            local currentIndex = playerSettings.guiPersist.selectedCameraTracker
            if currentIndex > 1 and currentIndex >= index then
                -- Select previous entry if entry above was deleted (so same entry stays selected)
                playerSettings.guiPersist.selectedCameraTracker = currentIndex - 1
            end

            GUI.createCameraTrackerList(playerSettings)
            GUI.createTrackerList(
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
                playerSettings.gui.trackerList,
                playerSettings.guiPersist.selectedTracker,
                playerSettings.cameras,
                playerSettings.trackers,
                "tracker_",
                GUI.addTrackerButtons
            )

            return
        end

        _, _, index = event.element.name:find("^tracker_(%d+)_delete$")
        if index ~= nil then
            if #playerSettings.trackers == 1 then
                -- Paranoia check
                return
            end

            index = tonumber(index)
            if index == nil then
                return
            end

            table.remove(playerSettings.trackers, math.floor(index))

            if playerSettings.guiPersist.selectedTracker > #playerSettings.trackers then
                playerSettings.guiPersist.selectedTracker = #playerSettings.trackers
            end

            GUI.createTrackerList(
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
                playerSettings.gui.trackerList,
                playerSettings.guiPersist.selectedTracker,
                playerSettings.cameras,
                playerSettings.trackers,
                "tracker_",
                GUI.addTrackerButtons
            )

            GUI.createCameraAddTracker(
                playerSettings.gui.cameraTrackerListFlow,
                playerSettings.trackers,
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
            )

            GUI.createTrackerConfigAndInfo(
                playerSettings.gui.trackerInfo,
                playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
            )

            return
        end

        _, _, index = event.element.name:find("^tracker_(%d+)_recalculate$")
        if index ~= nil then
            index = tonumber(index)
            local selectedTracker = playerSettings.trackers[index]
            local baseBBox = Main.getBaseBBox(selectedTracker.surfaceName)
            if baseBBox ~= nil then
                selectedTracker.minPos = baseBBox.minPos
                selectedTracker.maxPos = baseBBox.maxPos
                Tracker.updateCenterAndSize(selectedTracker)

                if index == playerSettings.guiPersist.selectedTracker then
                    GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
                end
            end

            return
        end
    end
end

--- @param event  EventData.on_gui_selection_state_changed
function GUI.onSelected(event)
    local player = game.players[event.player_index]
    local playerSettings = global.playerSettings[event.player_index]

    if event.element.name == "tlbe-cameras-list" then
        GUI.setSelectedCamera(player, playerSettings, event.element.selected_index)
        playerSettings.guiPersist.selectedCameraTracker = 1

        GUI.updateCameraActions(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateCameraConfig(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
        GUI.createTrackerList(
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
            playerSettings.gui.cameraTrackerList,
            1,
            playerSettings.cameras,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
            "camera_tracker_",
            GUI.addCameraTrackerButtons
        )
        GUI.createCameraTrackerList(playerSettings)
    elseif event.element.name == "tlbe-tracker-add" then
        local trackerIndex = event.element.selected_index - 1
        if trackerIndex < 1 then
            -- Paranoia check: ignore first item (placeholder) in the list
            return
        end
        event.element.selected_index = 1

        local newTracker = Tracker.newTracker(GUI.allTrackers[trackerIndex], playerSettings.trackers)
        table.insert(playerSettings.trackers, newTracker)
        playerSettings.guiPersist.selectedTracker = #playerSettings.trackers

        GUI.createTrackerList(
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
            playerSettings.gui.trackerList,
            playerSettings.guiPersist.selectedTracker,
            playerSettings.cameras,
            playerSettings.trackers,
            "tracker_",
            GUI.addTrackerButtons
        )

        GUI.createCameraAddTracker(
            playerSettings.gui.cameraTrackerListFlow,
            playerSettings.trackers,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )

        GUI.createTrackerConfigAndInfo(
            playerSettings.gui.trackerInfo,
            playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        )
    elseif event.element.name == "tlbe-camera-add-tracker" then
        if event.element.selected_index <= 1 then
            -- Paranoia check: ignore first item (placeholder) in the list
            return
        end

        local trackerToAdd = Utils.findName(playerSettings.trackers, event.element.items[event.element.selected_index])

        table.insert(playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers, trackerToAdd)
        playerSettings.guiPersist.selectedCameraTracker = #
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers

        GUI.createTrackerList(
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
            playerSettings.gui.cameraTrackerList,
            1,
            playerSettings.cameras,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
            "camera_tracker_",
            GUI.addCameraTrackerButtons
        )

        GUI.createCameraAddTracker(
            playerSettings.gui.cameraTrackerListFlow,
            playerSettings.trackers,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
    elseif event.element.name == "camera-surface" then
        playerSettings.cameras[playerSettings.guiPersist.selectedCamera].surfaceName = event.element.get_item(event
            .element
            .selected_index)

        GUI.createCameraTrackerList(playerSettings)
    elseif event.element.name == "tracker-surface" then
        playerSettings.trackers[playerSettings.guiPersist.selectedTracker].surfaceName = event.element.get_item(event
            .element
            .selected_index)

        GUI.createCameraTrackerList(playerSettings)
    end
end

function GUI.onTextChanged(event)
    local playerSettings = global.playerSettings[event.player_index]
    if event.element.name == "camera-name" then
        Camera.setName(playerSettings.cameras[playerSettings.guiPersist.selectedCamera], event.element.text)
        GUI.updateCameraList(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
    elseif event.element.name == "tracker-name" then
        playerSettings.trackers[playerSettings.guiPersist.selectedTracker].name = event.element.text

        GUI.createTrackerList(
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
            playerSettings.gui.trackerList,
            playerSettings.guiPersist.selectedTracker,
            playerSettings.cameras,
            playerSettings.trackers,
            "tracker_",
            GUI.addTrackerButtons
        )

        GUI.createTrackerList(
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
            playerSettings.gui.cameraTrackerList,
            1,
            playerSettings.cameras,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
            "camera_tracker_",
            GUI.addCameraTrackerButtons
        )

        GUI.createCameraAddTracker(
            playerSettings.gui.cameraTrackerListFlow,
            playerSettings.trackers,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
    elseif event.element.name == "camera-resolution-x" then
        Camera.setWidth(playerSettings.cameras[playerSettings.guiPersist.selectedCamera], event.element.text)
        GUI.updateCameraInfo(playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera])
    elseif event.element.name == "camera-resolution-y" then
        Camera.setHeight(playerSettings.cameras[playerSettings.guiPersist.selectedCamera], event.element.text)
        GUI.updateCameraInfo(playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera])
    elseif event.element.name == "camera-frame-rate" then
        Camera.setFrameRate(playerSettings.cameras[playerSettings.guiPersist.selectedCamera], event.element.text)
    elseif event.element.name == "camera-speed-gain" then
        Camera.setSpeedGain(playerSettings.cameras[playerSettings.guiPersist.selectedCamera], event.element.text)
    elseif event.element.name == "camera-transition-period" then
        Camera.setTransitionPeriod(playerSettings.cameras[playerSettings.guiPersist.selectedCamera], event.element.text)
    elseif event.element.name == "tlbe-tracker-top" then
        local value = tonumber(event.element.text)
        if value ~= nil then
            local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
            -- Note that game origin is top-left, so top is min and bottom is max
            selectedTracker.minPos.y = value
            Tracker.areaUpdateCenterAndSize(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-bottom" then
        local value = tonumber(event.element.text)
        if value ~= nil then
            local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
            -- Note that game origin is top-left, so top is min and bottom is max
            selectedTracker.maxPos.y = value
            Tracker.areaUpdateCenterAndSize(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-left" then
        local value = tonumber(event.element.text)
        if value ~= nil then
            local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
            selectedTracker.minPos.x = value
            Tracker.areaUpdateCenterAndSize(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-right" then
        local value = tonumber(event.element.text)
        if value ~= nil then
            local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
            selectedTracker.maxPos.x = value
            Tracker.areaUpdateCenterAndSize(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-cityblock-size-x" and event.element.text ~= nil then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        local value = tonumber(event.element.text)
        if value ~= nil and value >= 1 then
            selectedTracker.cityBlock.blockSize.x = math.floor(value)
            Tracker.recalculateCityBlock(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-cityblock-size-y" and event.element.text ~= nil then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        local value = tonumber(event.element.text)
        if value ~= nil and value >= 1 then
            selectedTracker.cityBlock.blockSize.y = math.floor(value)
            Tracker.recalculateCityBlock(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-cityblock-offset-x" and event.element.text ~= nil then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        local value = tonumber(event.element.text)
        if value ~= nil then
            selectedTracker.cityBlock.blockOffset.x = math.floor(value)
            Tracker.recalculateCityBlock(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-cityblock-offset-y" and event.element.text ~= nil then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        local value = tonumber(event.element.text)
        if value ~= nil then
            selectedTracker.cityBlock.blockOffset.y = math.floor(value)
            Tracker.recalculateCityBlock(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-cityblock-currentblock-x" and event.element.text ~= nil then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        local value = tonumber(event.element.text)
        if value ~= nil then
            selectedTracker.cityBlock.currentBlock.x = math.floor(value)
            Tracker.recalculateCityBlock(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    elseif event.element.name == "tlbe-tracker-cityblock-currentblock-y" and event.element.text ~= nil then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        local value = tonumber(event.element.text)
        if value ~= nil then
            selectedTracker.cityBlock.currentBlock.y = math.floor(value)
            Tracker.recalculateCityBlock(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    end
end

function GUI.onGuiConfirmed(event)
    local playerSettings = global.playerSettings[event.player_index]
    if event.element.name == "tlbe-tracker-cityblock-blockScale-value" and event.element.text ~= nil then
        local selectedTracker = playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        local value = tonumber(event.element.text)
        if value ~= nil then
            selectedTracker.cityBlock.blockScale = math.floor(value * 100)/100
            Tracker.recalculateCityBlock(selectedTracker)

            GUI.updateTrackerConfig(playerSettings.gui.trackerInfo, selectedTracker)
            GUI.updateTrackerInfo(playerSettings.gui.trackerInfo, selectedTracker)
        end
    end
end

function GUI.onStateChanged(event)
    ---@type playerSettings
    local playerSettings = global.playerSettings[event.player_index]
    if event.element.name == "camera-entity-info" then
        playerSettings.cameras[playerSettings.guiPersist.selectedCamera].entityInfo = event.element.state
    elseif event.element.name == "camera-show-gui" then
        playerSettings.cameras[playerSettings.guiPersist.selectedCamera].showGUI = event.element.state
    elseif event.element.name == "camera-always-day" then
        playerSettings.cameras[playerSettings.guiPersist.selectedCamera].alwaysDay = event.element.state
    elseif event.element.name == "tracker-smooth" then
        playerSettings.trackers[playerSettings.guiPersist.selectedTracker].smooth = event.element.state
    elseif event.element.name == "tracker-untilbuild" then
        playerSettings.trackers[playerSettings.guiPersist.selectedTracker].untilBuild = event.element.state
    end
end

--- @param event EventData.on_lua_shortcut
function GUI.onShortcut(event)
    if event.prototype_name == "tlbe-shortcut" then
        GUI.toggleMainWindow(event)
    elseif event.prototype_name == "tlbe-pause-shortcut" then
        GUI.togglePauseCameras(event)
    elseif event.prototype_name == "tlbe-screenshot-shortcut" then
        GUI.takeScreenshot(event)
    end
end

--- @param event EventData.on_lua_shortcut
function GUI.takeScreenshot(event)
    local player = game.players[event.player_index]
    local active = player.is_shortcut_available("tlbe-screenshot-shortcut")
    if active then
        ---@type playerSettings
        local playerSettings = global.playerSettings[event.player_index]
        local camera = playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        local _, activeTracker = Tracker.findActiveTracker(camera.trackers, camera.surfaceName)

        Main.takeScreenshot(player, playerSettings, camera, activeTracker)
    end
end

function GUI.onSurfacesUpdated()
    -- Surface list got updated so refresh GUI
    for _, player in pairs(game.players) do
        local playerSettings = global.playerSettings[player.index]
        if playerSettings.gui ~= nil then
            GUI.updateCameraConfig(
                playerSettings.gui.cameraInfo,
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
            )
            GUI.updateTrackerConfig(
                playerSettings.gui.trackerInfo,
                playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
            )
        end
    end
end

function GUI.onSurfaceChanged(event)
    local surfaceName = event.old_name
    if surfaceName == nil then
        -- on_pre_surface_deleted does not contain surface name in event
        surfaceName = game.surfaces[event.surface_index].name
    end

    for _, player in pairs(game.players) do
        local playerSettings = global.playerSettings[player.index]

        for _, camera in pairs(playerSettings.cameras) do
            if camera.surfaceName == surfaceName then
                -- Update surface name
                camera.surfaceName = event.new_name or game.surfaces[1].name

                if playerSettings.gui ~= nil then
                    GUI.createCameraTrackerList(playerSettings)
                    GUI.createCameraAddTracker(
                        playerSettings.gui.cameraTrackerListFlow,
                        playerSettings.trackers,
                        playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
                    )
                end

                if camera.surfaceName == game.surfaces[1].name and camera.enabled then
                    camera.enabled = false
                    if playerSettings.gui ~= nil then
                        GUI.updateCameraActions(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
                    end
                    game.players[player.index].print({ "camera-surface-deleted", camera.name }, { r = 1, g = 0.5, b = 0 })
                end
            end
        end
    end
end

function GUI.togglePauseCameras(event)
    local player = game.players[event.player_index]
    local playerSettings = global.playerSettings[event.player_index]

    playerSettings.pauseCameras = playerSettings.pauseCameras ~= true
    player.set_shortcut_toggled("tlbe-pause-shortcut", playerSettings.pauseCameras)
end

function GUI.closeMainWindow(event)
    local player = game.players[event.player_index]
    if player.gui.screen["tlbe-main-window"] ~= nil then
        GUI.toggleMainWindow(event)
    end
end

function GUI.toggleMainWindow(event)
    local player = game.players[event.player_index]
    local playerSettings = global.playerSettings[event.player_index]

    local mainWindowOpen = player.gui.screen["tlbe-main-window"] ~= nil
    player.set_shortcut_toggled("tlbe-shortcut", not mainWindowOpen)

    if playerSettings.pauseOnOpen and not game.is_multiplayer() then
        game.tick_paused = not mainWindowOpen
    end

    if mainWindowOpen then
        player.gui.screen["tlbe-main-window"].destroy()
        playerSettings.gui = nil
    else
        -- Create frame without caption (we have our own title_bar)
        local mainWindow = player.gui.screen.add { type = "frame", name = "tlbe-main-window", direction = "vertical" }
        playerSettings.gui = {}

        -- Add title bar
        local title_bar = mainWindow.add { type = "flow" }
        local title = title_bar.add { type = "label", caption = { "gui.frame-title" }, style = "frame_title" }
        title.drag_target = mainWindow

        -- Add 'dragger' (filler) between title and (close) buttons
        local dragger = title_bar.add { type = "empty-widget", style = "draggable_space_header" }
        dragger.style.vertically_stretchable = true
        dragger.style.horizontally_stretchable = true
        dragger.drag_target = mainWindow

        if not game.is_multiplayer() then
            local style = getWindowPlayButtonStyle(playerSettings.pauseOnOpen)
            title_bar.add {
                type = "sprite-button",
                name = "tlbe-main-window-pause",
                tooltip = { "tooltip.pause-on-open" },
                sprite = "pause-white",
                style = style
            }
        end

        title_bar.add {
            type = "sprite-button",
            style = "frame_action_button",
            sprite = "utility/close_white",
            name = "tlbe-main-window-close"
        }

        local tabPane = mainWindow.add { type = "tabbed-pane", style = "tlbe-tabbed_pane" }

        local cameraTab = tabPane.add { type = "tab", caption = { "gui.tab-cameras" } }
        tabPane.add_tab(
            cameraTab,
            GUI.createCameraSettings(
                tabPane,
                playerSettings.gui,
                playerSettings.guiPersist,
                playerSettings.cameras,
                playerSettings.trackers
            )
        )

        local trackerTab = tabPane.add { type = "tab", caption = { "gui.tab-trackers" } }
        tabPane.add_tab(
            trackerTab,
            GUI.createTrackerSettings(
                tabPane,
                playerSettings.gui,
                playerSettings.guiPersist,
                playerSettings.cameras,
                playerSettings.trackers
            )
        )

        mainWindow.force_auto_center()
    end
end

function GUI.createCameraSettings(parent, playerGUI, guiPersist, cameras, trackers)
    local flow = parent.add { type = "flow", direction = "vertical" }

    -- Cameras
    local cameraBox = flow.add { type = "flow" }
    local cameraLeftFlow = cameraBox.add { type = "flow", direction = "vertical", style = "tlbe_fancy_list_parent" }

    playerGUI.cameraSelector = cameraLeftFlow.add {
        type = "drop-down",
        name = "tlbe-cameras-list",
        style = "tlbe_camera_dropdown"
    }
    GUI.updateCameraList(playerGUI, guiPersist, cameras)

    playerGUI.cameraActions = cameraLeftFlow.add { type = "flow" }
    GUI.updateCameraActions(playerGUI, guiPersist, cameras)

    -- Camera info
    playerGUI.cameraInfo = cameraBox.add { type = "table", column_count = 2 }
    playerGUI.cameraInfo.add { type = "label", caption = { "gui.label-name" }, style = "description_property_name_label" }
    playerGUI.cameraInfo.add { type = "textfield", name = "camera-name", style = "tlbe_config_textfield" }
    playerGUI.cameraInfo.add {
        type = "label",
        name = "camera-surface-label",
        caption = { "gui.label-surface" },
        style = "description_property_name_label"
    }
    playerGUI.cameraInfo.add {
        type = "drop-down",
        name = "camera-surface",
        items = {},
        style = "tlbe_config_dropdown"
    }
    playerGUI.cameraInfo.add {
        type = "label",
        caption = { "gui.label-resolution" },
        style = "description_property_name_label"
    }
    local resolutionFlow = playerGUI.cameraInfo.add { type = "flow", name = "camera-resolution" }
    resolutionFlow.add {
        type = "textfield",
        name = "camera-resolution-x",
        style = "tlbe_config_half_width_textfield",
        numeric = true
    }
    resolutionFlow.add { type = "label", caption = "x", style = "tlbe_config_half_width_label" }
    resolutionFlow.add {
        type = "textfield",
        name = "camera-resolution-y",
        style = "tlbe_config_half_width_textfield",
        numeric = true
    }
    playerGUI.cameraInfo.add {
        type = "label",
        caption = { "gui.label-framerate" },
        tooltip = { "tooltip.camera-framerate" },
        style = "description_property_name_label"
    }
    playerGUI.cameraInfo.add {
        type = "textfield",
        name = "camera-frame-rate",
        tooltip = { "tooltip.camera-framerate" },
        style = "tlbe_config_half_width_textfield",
        numeric = true
    }
    playerGUI.cameraInfo.add {
        type = "label",
        caption = { "gui.label-speedgain" },
        tooltip = { "tooltip.camera-speedgain" },
        style = "description_property_name_label"
    }
    playerGUI.cameraInfo.add {
        type = "textfield",
        name = "camera-speed-gain",
        tooltip = { "tooltip.camera-speedgain" },
        style = "tlbe_config_half_width_textfield",
        numeric = true,
        allow_decimal = true
    }
    playerGUI.cameraInfo.add {
        type = "label",
        caption = { "gui.label-transitionperiod" },
        tooltip = { "tooltip.camera-transitionperiod" },
        style = "description_property_name_label"
    }
    playerGUI.cameraInfo.add {
        type = "textfield",
        name = "camera-transition-period",
        tooltip = { "tooltip.camera-transitionperiod" },
        style = "tlbe_config_half_width_textfield",
        numeric = true,
        allow_decimal = true
    }
    playerGUI.cameraInfo.add { type = "empty-widget" }
    playerGUI.cameraInfo.add {
        type = "checkbox",
        name = "camera-entity-info",
        caption = { "gui.label-entity-info" },
        tooltip = { "tooltip.camera-entity-info" },
        state = false
    }
    playerGUI.cameraInfo.add { type = "empty-widget" }
    playerGUI.cameraInfo.add {
        type = "checkbox",
        name = "camera-show-gui",
        caption = { "gui.label-show-gui" },
        tooltip = { "tooltip.camera-show-gui" },
        state = false
    }
    playerGUI.cameraInfo.add { type = "empty-widget" }
    playerGUI.cameraInfo.add {
        type = "checkbox",
        name = "camera-always-day",
        caption = { "gui.label-always-day" },
        tooltip = { "tooltip.camera-always-day" },
        state = true
    }
    playerGUI.cameraInfo.add {
        type = "label",
        caption = { "gui.label-position" },
        style = "description_property_name_label"
    }
    playerGUI.cameraInfo.add { type = "label", name = "camera-position" }
    playerGUI.cameraInfo.add { type = "label", caption = { "gui.label-zoom" }, style = "description_property_name_label" }
    playerGUI.cameraInfo.add { type = "label", name = "camera-zoom" }

    GUI.updateCameraConfig(playerGUI.cameraInfo, cameras[guiPersist.selectedCamera])
    GUI.updateCameraInfo(playerGUI.cameraInfo, cameras[guiPersist.selectedCamera])

    -- Trackers
    flow.add { type = "line" }
    flow.add { type = "label", caption = { "gui.label-camera-trackers" }, style = "description_property_name_label" }
    local trackerBox = flow.add { type = "flow" }
    playerGUI.cameraTrackerListFlow = trackerBox.add { type = "flow", direction = "vertical",
        style = "tlbe_fancy_list_parent" }
    playerGUI.cameraTrackerList = playerGUI.cameraTrackerListFlow.add {
        type = "scroll-pane",
        name = "tlbe-tracker-list",
        horizontal_scroll_policy = "never",
        style = "tlbe_tracker_list"
    }
    GUI.createTrackerList(
        cameras[guiPersist.selectedCamera],
        playerGUI.cameraTrackerList,
        guiPersist.selectedCameraTracker,
        cameras,
        cameras[guiPersist.selectedCamera].trackers,
        "camera_tracker_",
        GUI.addCameraTrackerButtons
    )

    GUI.createCameraAddTracker(playerGUI.cameraTrackerListFlow, trackers, cameras[guiPersist.selectedCamera])

    -- Tracker info
    playerGUI.cameraTrackerInfo = trackerBox.add { type = "table", column_count = 2 }
    playerGUI.cameraTrackerInfo.add {
        type = "label",
        caption = { "gui.label-type" },
        style = "description_property_name_label"
    }
    playerGUI.cameraTrackerInfo.add { type = "label", name = "tracker-type" }
    playerGUI.cameraTrackerInfo.add {
        type = "label",
        caption = { "gui.label-center" },
        style = "description_property_name_label"
    }
    playerGUI.cameraTrackerInfo.add { type = "label", name = "tracker-position" }
    playerGUI.cameraTrackerInfo.add {
        type = "label",
        caption = { "gui.label-size" },
        style = "description_property_name_label"
    }
    playerGUI.cameraTrackerInfo.add { type = "label", name = "tracker-size" }
    GUI.updateTrackerInfo(
        playerGUI.cameraTrackerInfo,
        cameras[guiPersist.selectedCamera].trackers[guiPersist.selectedCameraTracker]
    )

    return flow
end

function GUI.createTrackerSettings(parent, playerGUI, guiPersist, cameras, trackers)
    local flow = parent.add { type = "flow" }
    local trackersFlow = flow.add { type = "flow", direction = "vertical", style = "tlbe_fancy_list_parent" }

    -- New tracker GUI
    trackersFlow.add {
        type = "drop-down",
        selected_index = 1,
        name = "tlbe-tracker-add",
        items = { { "gui.item-new-tracker" }, table.unpack(GUI.allTrackersLabels) },
        style = "tble_tracker_add_dropdown"
    }

    -- Trackers
    playerGUI.trackerList = trackersFlow.add {
        type = "scroll-pane",
        name = "tlbe-tracker-list",
        horizontal_scroll_policy = "never",
        style = "tlbe_tracker_list"
    }
    GUI.createTrackerList(
        cameras[guiPersist.selectedCamera],
        playerGUI.trackerList,
        guiPersist.selectedTracker,
        cameras,
        trackers,
        "tracker_",
        GUI.addTrackerButtons
    )

    -- Tracker info
    local infoFlow = flow.add { type = "flow", direction = "vertical" }
    playerGUI.trackerInfo = infoFlow.add { type = "table", column_count = 2 }
    GUI.createTrackerConfigAndInfo(playerGUI.trackerInfo, trackers[guiPersist.selectedTracker])

    return flow
end

function GUI.createTrackerList(
    selectedCamera,
    trackerList,
    selectedIndex,
    cameras,
    trackers,
    namePrefix,
    addTrackerButtons)
    trackerList.clear()

    for index, tracker in pairs(trackers) do
        local style = "tlbe_fancy_list_box_item"
        if index == selectedIndex then
            style = "tlbe_fancy_list_box_item_selected"
        end

        local trackerRow =
            trackerList.add {
                type = "frame",
                name = namePrefix .. index,
                style = style
            }

        addTrackerButtons(index, selectedCamera, cameras, trackers, trackerRow)

        trackerRow.add {
            type = "label",
            name = namePrefix .. index,
            caption = tracker.name,
            style = "tlbe_fancy_list_box_label"
        }
    end
end

function GUI.createCameraTrackerList(playerSettings)
    GUI.createTrackerList(
        playerSettings.cameras[playerSettings.guiPersist.selectedCamera],
        playerSettings.gui.cameraTrackerList,
        playerSettings.guiPersist.selectedCameraTracker,
        playerSettings.cameras,
        playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
        "camera_tracker_",
        GUI.addCameraTrackerButtons
    )

    GUI.createCameraAddTracker(
        playerSettings.gui.cameraTrackerListFlow,
        playerSettings.trackers,
        playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
    )
end

function GUI.addCameraTrackerButtons(index, selectedCamera, _, trackers, trackerRow)
    local tracker = trackers[index]
    local isActiveTracker = findActiveTracker(trackers, selectedCamera.surfaceName) == tracker

    local orderFlow = trackerRow.add { type = "flow", direction = "vertical" }

    if index > 1 then
        orderFlow.add {
            type = "button",
            name = "camera_tracker_" .. index .. "_up",
            style = "tlbe_order_up_button"
        }
    else
        orderFlow.add {
            type = "empty-widget",
            style = "tlbe_order_hidden_button"
        }
    end

    if index < #trackers then
        orderFlow.add {
            type = "button",
            name = "camera_tracker_" .. index .. "_down",
            style = "tlbe_order_down_button"
        }
    else
        orderFlow.add {
            type = "empty-widget",
            style = "tlbe_order_hidden_button"
        }
    end

    trackerRow.add {
        type = "sprite-button",
        name = "camera_tracker_" .. index .. "_remove",
        sprite = "utility/close_black",
        style = "tlbe_tracker_remove_button"
    }

    if isActiveTracker then
        trackerRow.add {
            type = "sprite",
            sprite = "utility/play",
            style = "tlbe_fancy_list_box_image"
        }
    elseif tracker.surfaceName ~= selectedCamera.surfaceName then
        trackerRow.add {
            type = "sprite",
            sprite = "utility/warning_icon",
            style = "tlbe_fancy_list_box_image_reduce_size",
            tooltip = { "tooltip.tracker-wrong-surface" }
        }
    else
        trackerRow.add {
            type = "empty-widget",
            style = "tlbe_fancy_list_box_button_hidden"
        }
    end
end

function GUI.addTrackerButtons(index, _, cameras, trackers, trackerRow)
    local tracker = trackers[index]
    local style = "tlbe_tracker_button"
    if tracker.enabled then
        style = "tlbe_tracker_button_selected"
    end

    if tracker.userCanEnable then
        trackerRow.add {
            type = "sprite-button",
            name = "tracker_" .. index .. "_enable",
            tooltip = { "tooltip.tracker-enable" },
            sprite = "utility/play",
            style = style
        }
    else
        trackerRow.add {
            enabled = false,
            type = "sprite-button",
            tooltip = { "tooltip.tracker-cannot-enable" },
            sprite = "utility/play",
            style = "tlbe_fancy_list_box_button"
        }
    end

    if #trackers > 1 then
        local button =
            trackerRow.add {
                type = "sprite-button",
                name = "tracker_" .. index .. "_delete",
                sprite = "utility/trash",
                style = "tlbe_tracker_button_red"
            }

        if Tracker.inUse(tracker, cameras) then
            button.enabled = false
            button.tooltip = { "tooltip.tracker-cannot-delete-inuse" }
        end
    end

    if tracker.type == "base" then
        trackerRow.add {
            type = "sprite-button",
            name = "tracker_" .. index .. "_recalculate",
            tooltip = { "tooltip.base-recalculate" },
            sprite = "utility/refresh",
            style = "tlbe_fancy_list_box_button"
        }
    else
        trackerRow.add {
            type = "empty-widget",
            style = "tlbe_fancy_list_box_button_hidden"
        }
    end
end

function GUI.createCameraAddTracker(parent, allTrackers, camera)
    if parent["tlbe-camera-add-tracker"] ~= nil then
        parent["tlbe-camera-add-tracker"].destroy()
    end

    local availableTrackers = Utils.filterOut(allTrackers, camera.trackers)
    local availableTrackerNames = {}
    for _, tracker in pairs(availableTrackers) do
        if tracker.surfaceName == camera.surfaceName then
            table.insert(availableTrackerNames, tracker.name)
        end
    end

    if #availableTrackerNames > 0 then
        parent.add {
            type = "drop-down",
            selected_index = 1,
            name = "tlbe-camera-add-tracker",
            items = { { "gui.item-add-tracker" }, table.unpack(availableTrackerNames) },
            style = "tble_tracker_add_dropdown"
        }
    end
end

function GUI.updateCameraActions(playerGUI, guiPersist, cameras)
    playerGUI.cameraActions.clear()
    local selectedCamera = cameras[guiPersist.selectedCamera]

    local style = "tool_button"
    if selectedCamera.enabled then
        style = "tlbe_tool_button_selected"
    end

    playerGUI.cameraActions.add {
        type = "sprite-button",
        name = "tlbe_camera_enable",
        tooltip = { "tooltip.camera-enable" },
        sprite = "utility/play",
        style = style
    }

    playerGUI.cameraActions.add {
        type = "button",
        caption = "+",
        name = "tlbe_camera_add",
        tooltip = { "tooltip.camera-add" },
        style = "tool_button"
    }

    if #cameras > 1 then
        playerGUI.cameraActions.add {
            type = "sprite-button",
            name = "tlbe_camera_delete",
            tooltip = { "tooltip.camera-delete" },
            sprite = "utility/trash",
            style = "tool_button_red"
        }
    end

    playerGUI.cameraActions.add {
        type = "sprite-button",
        name = "tlbe_camera_refresh",
        tooltip = { "tooltip.camera-refresh" },
        sprite = "utility/refresh",
        style = "tool_button"
    }
end

function GUI.updateCameraList(playerGUI, guiPersist, cameras)
    local cameraItems = {}
    for index, camera in pairs(cameras) do
        cameraItems[index] = camera.name
    end

    playerGUI.cameraSelector.items = cameraItems
    playerGUI.cameraSelector.selected_index = guiPersist.selectedCamera
end

---@param cameraInfo table
---@param camera Camera.camera
function GUI.updateCameraConfig(cameraInfo, camera)
    -- Paranoia check
    if camera ~= nil then
        local resolutionFlow = cameraInfo["camera-resolution"]
        cameraInfo["camera-name"].text = camera.name
        cameraInfo["camera-frame-rate"].text = string.format("%d", camera.frameRate or 25)
        cameraInfo["camera-speed-gain"].text = string.format("%d", camera.speedGain or 60)
        cameraInfo["camera-transition-period"].text = string.format("%2.2f", camera.transitionPeriod or 1.5)
        cameraInfo["camera-entity-info"].state = camera.entityInfo
        cameraInfo["camera-show-gui"].state = camera.showGUI
        cameraInfo["camera-always-day"].state = camera.alwaysDay
        resolutionFlow["camera-resolution-x"].text = string.format("%d", camera.width or 1920)
        resolutionFlow["camera-resolution-y"].text = string.format("%d", camera.height or 1080)

        GUI.updateSurfacesDropdown(cameraInfo["camera-surface"], cameraInfo["camera-surface-label"], camera.surfaceName)
    end
end

function GUI.updateCameraInfo(cameraInfo, camera)
    if camera == nil or camera.centerPos == nil then
        cameraInfo["camera-position"].caption = { "gui.value-unset" }
    else
        cameraInfo["camera-position"].caption = string.format("%d, %d", camera.centerPos.x, camera.centerPos.y)
    end

    if camera == nil then
        cameraInfo["camera-zoom"].caption = { "gui.value-unset" }
    else
        cameraInfo["camera-zoom"].caption = string.format("%2.2f", camera.zoom)
    end
end

-- Update surfaces down-down items and set selected
function GUI.updateSurfacesDropdown(dropdown, label, surfaceName)
    local surfaces = {}
    local count = 0
    local selectedItem = 1
    for _, surface in pairs(game.surfaces) do
        table.insert(surfaces, surface.name)
        count = count + 1
        if surface.name == surfaceName then
            selectedItem = count
        end
    end
    if #surfaces > 1 then
        dropdown.items = surfaces
        dropdown.selected_index = selectedItem
        dropdown.visible = true
        label.visible = true
    else
        dropdown.visible = false
        label.visible = false
    end
end

function GUI.createTrackerConfigAndInfo(trackerInfo, tracker)
    trackerInfo.clear()

    trackerInfo.add { type = "label", caption = { "gui.label-name" }, style = "description_property_name_label" }
    trackerInfo.add { type = "textfield", name = "tracker-name", style = "tlbe_config_textfield" }
    trackerInfo.add {
        type = "label",
        name = "tracker-surface-label",
        caption = { "gui.label-surface" },
        style = "description_property_name_label"
    }
    trackerInfo.add {
        type = "drop-down",
        name = "tracker-surface",
        items = {},
        style = "tlbe_config_dropdown"
    }
    trackerInfo.add { type = "empty-widget" }
    trackerInfo.add {
        type = "checkbox",
        name = "tracker-smooth",
        caption = { "gui.label-smooth" },
        tooltip = { "tooltip.tracker-smooth" },
        state = false
    }

    if tracker ~= nil then
        if tracker.type == "area" then
            trackerInfo.add {
                type = "label",
                caption = { "gui.label-top-right" },
                style = "description_property_name_label"
            }
            local trFlow = trackerInfo.add { type = "flow", name = "tracker-tr" }
            trFlow.add {
                type = "textfield",
                name = "tlbe-tracker-top",
                style = "tlbe_config_half_width_textfield",
                numeric = true,
                allow_negative = true
            }
            trFlow.add { type = "label", caption = "/", style = "tlbe_config_half_width_label" }
            trFlow.add {
                type = "textfield",
                name = "tlbe-tracker-right",
                style = "tlbe_config_half_width_textfield",
                numeric = true,
                allow_negative = true
            }
            trFlow.add {
                type = "sprite-button",
                name = "tlbe-tracker-tr-player",
                tooltip = { "tooltip.tracker-area-player" },
                sprite = "utility/show_player_names_in_map_view_black",
                style = "tlbe_config_button"
            }
            trFlow.add {
                type = "sprite-button",
                name = "tlbe-tracker-tr-map",
                tooltip = { "tooltip.tracker-area-map", tracker.name .. "-tr" },
                sprite = "utility/station_name",
                style = "tlbe_config_button"
            }

            trackerInfo.add { type = "label", caption = { "gui.label-bottom-left" },
                style = "description_property_name_label" }
            local blFlow = trackerInfo.add { type = "flow", name = "tracker-bl" }
            blFlow.add {
                type = "textfield",
                name = "tlbe-tracker-bottom",
                style = "tlbe_config_half_width_textfield",
                numeric = true,
                allow_negative = true
            }
            blFlow.add { type = "label", caption = "/", style = "tlbe_config_half_width_label" }
            blFlow.add {
                type = "textfield",
                name = "tlbe-tracker-left",
                style = "tlbe_config_half_width_textfield",
                numeric = true,
                allow_negative = true
            }
            blFlow.add {
                type = "sprite-button",
                name = "tlbe-tracker-bl-player",
                tooltip = { "tooltip.tracker-area-player" },
                sprite = "utility/show_player_names_in_map_view_black",
                style = "tlbe_config_button"
            }
            blFlow.add {
                type = "sprite-button",
                name = "tlbe-tracker-bl-map",
                tooltip = { "tooltip.tracker-area-map", tracker.name .. "-bl" },
                sprite = "utility/station_name",
                style = "tlbe_config_button"
            }
        elseif tracker.type == "player" then
            trackerInfo.add { type = "empty-widget" }
            trackerInfo.add {
                type = "checkbox",
                name = "tracker-untilbuild",
                caption = { "gui.label-until-build" },
                tooltip = { "tooltip.tracker-until-build" },
                state = tracker.untilBuild
            }
        elseif tracker.type == "cityblock" then
            trackerInfo.add { 
                type = "label",
                caption = { "gui.label-cityblock-size" },
                tooltip = { "tooltip.tracker-cityblock-size" },
                style = "description_property_name_label"
            }
            local sizeFlow = trackerInfo.add { type = "flow", name = "cityblock-size" }
            sizeFlow.add {
                type = "textfield",
                name = "tlbe-tracker-cityblock-size-x",
                style = "tlbe_config_half_width_textfield",
                tooltip = { "tooltip.tracker-cityblock-size-x" },
                numeric = true,
                allow_negative = true
            }
            sizeFlow.add { type = "label", caption = "/", style = "tlbe_config_half_width_label" }
            sizeFlow.add {
                type = "textfield",
                name = "tlbe-tracker-cityblock-size-y",
                style = "tlbe_config_half_width_textfield",
                tooltip = { "tooltip.tracker-cityblock-size-y" },
                numeric = true,
                allow_negative = true
            }

            trackerInfo.add { 
                type = "label",
                caption = { "gui.label-cityblock-offset" },
                tooltip = { "tooltip.tracker-cityblock-offset" },
                style = "description_property_name_label"
            }
            local offsetFlow = trackerInfo.add { type = "flow", name = "cityblock-offset" }
            offsetFlow.add {
                type = "textfield",
                name = "tlbe-tracker-cityblock-offset-x",
                style = "tlbe_config_half_width_textfield",
                tooltip = { "tooltip.tracker-cityblock-offset-x" },
                numeric = true,
                allow_negative = true
            }
            offsetFlow.add { type = "label", caption = "/", style = "tlbe_config_half_width_label" }
            offsetFlow.add {
                type = "textfield",
                name = "tlbe-tracker-cityblock-offset-y",
                style = "tlbe_config_half_width_textfield",
                tooltip = { "tooltip.tracker-cityblock-offset-y" },
                numeric = true,
                allow_negative = true
            }

            trackerInfo.add { 
                type = "label",
                caption = { "gui.label-cityblock-currentblock" },
                tooltip = { "tooltip.tracker-cityblock-currentblock" },
                style = "description_property_name_label"
            }
            local blockFlow = trackerInfo.add { type = "flow", name = "cityblock-block" }
            blockFlow.add {
                type = "textfield",
                name = "tlbe-tracker-cityblock-currentblock-x",
                style = "tlbe_config_half_width_textfield",
                tooltip = { "tooltip.tracker-cityblock-currentblock-x" },
                numeric = true,
                allow_negative = true
            }
            blockFlow.add { type = "label", caption = "/", style = "tlbe_config_half_width_label" }
            blockFlow.add {
                type = "textfield",
                name = "tlbe-tracker-cityblock-currentblock-y",
                style = "tlbe_config_half_width_textfield",
                tooltip = { "tooltip.tracker-cityblock-currentblock-y" },
                numeric = true,
                allow_negative = true
            }

            trackerInfo.add { 
                type = "label",
                caption = { "gui.label-cityblock-blockScale" },
                tooltip = { "tooltip.tracker-cityblock-blockScale" },
                style = "description_property_name_label"
            }
            trackerInfo.add {
                type = "textfield",
                name = "tlbe-tracker-cityblock-blockScale-value",
                style = "tlbe_config_half_width_textfield",
                tooltip = { "tooltip.tracker-cityblock-blockScale-value" },
                numeric = true,
                allow_decimal = true,
                allow_negative = false
            }

            trackerInfo.add {
                type = "label",
                caption = { "gui.label-cityblock-centerOnPlayer" },
                style = "description_property_name_label"
            }
            trackerInfo.add {
                type = "sprite-button",
                name = "tlbe-tracker-cityblock-player",
                tooltip = { "tooltip.tracker-cityblock-player" },
                sprite = "utility/show_player_names_in_map_view_black",
                style = "tlbe_config_button"
            }
        end
    end

    trackerInfo.add {
        type = "label",
        caption = { "gui.label-type" },
        style = "description_property_name_label"
    }
    trackerInfo.add { type = "label", name = "tracker-type" }
    trackerInfo.add {
        type = "label",
        caption = { "gui.label-center" },
        style = "description_property_name_label"
    }
    trackerInfo.add { type = "label", name = "tracker-position" }
    trackerInfo.add { type = "label", caption = { "gui.label-size" }, style = "description_property_name_label" }
    trackerInfo.add { type = "label", name = "tracker-size" }
    GUI.updateTrackerConfig(trackerInfo, tracker)
    GUI.updateTrackerInfo(trackerInfo, tracker)
end

---@param trackerInfo any
---@param tracker Tracker.tracker
function GUI.updateTrackerConfig(trackerInfo, tracker)
    if tracker == nil then
        trackerInfo["tracker-name"].enabled = false
        trackerInfo["tracker-name"].text = ""
        trackerInfo["tracker-smooth"].enabled = false
        trackerInfo["tracker-smooth"].state = false
    else
        trackerInfo["tracker-name"].enabled = true
        GUI.updateSurfacesDropdown(
            trackerInfo["tracker-surface"],
            trackerInfo["tracker-surface-label"],
            tracker.surfaceName
        )
        trackerInfo["tracker-name"].text = tracker.name or "<unknown tracker>"
        trackerInfo["tracker-smooth"].enabled = true
        trackerInfo["tracker-smooth"].state = tracker.smooth

        if tracker.type == "area" then
            local trFlow = trackerInfo["tracker-tr"]
            local blFlow = trackerInfo["tracker-bl"]
            -- Note that game origin is top-left, so top is min and bottom is max
            trFlow["tlbe-tracker-top"].text = string.format("%d", tracker.minPos.y)
            blFlow["tlbe-tracker-bottom"].text = string.format("%d", tracker.maxPos.y)
            trFlow["tlbe-tracker-right"].text = string.format("%d", tracker.maxPos.x)
            blFlow["tlbe-tracker-left"].text = string.format("%d", tracker.minPos.x)

            local style = "tlbe_config_half_width_textfield"
            if tracker.minPos.y >= tracker.maxPos.y then
                style = "tlbe_config_half_width_textfield_invalid"
            end
            trFlow["tlbe-tracker-top"].style = style
            blFlow["tlbe-tracker-bottom"].style = style

            style = "tlbe_config_half_width_textfield"
            if tracker.minPos.x >= tracker.maxPos.x then
                style = "tlbe_config_half_width_textfield_invalid"
            end
            trFlow["tlbe-tracker-right"].style = style
            blFlow["tlbe-tracker-left"].style = style
        elseif tracker.type == "player" then
            trackerInfo["tracker-untilbuild"].state = tracker.untilBuild
        elseif tracker.type == "cityblock" then
            local cityBlock = tracker.cityBlock
            if cityBlock == nil then
                return
            end
            
            local sizeFlow = trackerInfo["cityblock-size"]
            sizeFlow["tlbe-tracker-cityblock-size-x"].text = string.format("%d", cityBlock.blockSize.x)
            sizeFlow["tlbe-tracker-cityblock-size-y"].text = string.format("%d", cityBlock.blockSize.y)

            local offsetFlow = trackerInfo["cityblock-offset"]
            offsetFlow["tlbe-tracker-cityblock-offset-x"].text = string.format("%d", cityBlock.blockOffset.x)
            offsetFlow["tlbe-tracker-cityblock-offset-y"].text = string.format("%d", cityBlock.blockOffset.y)

            local blockFlow = trackerInfo["cityblock-block"]
            blockFlow["tlbe-tracker-cityblock-currentblock-x"].text = string.format("%d", cityBlock.currentBlock.x)
            blockFlow["tlbe-tracker-cityblock-currentblock-y"].text = string.format("%d", cityBlock.currentBlock.y)

            trackerInfo["tlbe-tracker-cityblock-blockScale-value"].text = string.format("%g", cityBlock.blockScale)
        end
    end
end

function GUI.updateTrackerInfo(trackerInfo, tracker)
    if tracker == nil then
        trackerInfo["tracker-type"].caption = ""
    else
        trackerInfo["tracker-type"].caption = GUI.allTrackersLabelsMap[tracker.type] or tracker.type
    end

    if tracker == nil or tracker.centerPos == nil then
        trackerInfo["tracker-position"].caption = { "gui.value-unset" }
    else
        trackerInfo["tracker-position"].caption = string.format("%d, %d", tracker.centerPos.x, tracker.centerPos.y)
    end

    if tracker == nil or tracker.size == nil then
        trackerInfo["tracker-size"].caption = { "gui.value-unset" }
    else
        trackerInfo["tracker-size"].caption = string.format("%d, %d", tracker.size.x, tracker.size.y)
    end
end

function GUI.fancyListBoxSelectItem(fancyList, selectedIndex)
    for index, element in pairs(fancyList.children) do
        local style = "tlbe_fancy_list_box_item"
        if index == selectedIndex then
            style = "tlbe_fancy_list_box_item_selected"
        end
        element.style = style
    end
end

---@param player LuaPlayer
---@param playerSettings playerSettings
---@param index integer
function GUI.setSelectedCamera(player, playerSettings, index)
    index = Utils.clamp(1, #playerSettings.cameras, index)
    playerSettings.guiPersist.selectedCamera = index

    GUI.updateTakeScreenshotButton(player, playerSettings)
end

---@param player LuaPlayer
---@param playerSettings playerSettings
function GUI.updateTakeScreenshotButton(player, playerSettings)
    local available = playerSettings.cameras[playerSettings.guiPersist.selectedCamera].enabled == false
    player.set_shortcut_available("tlbe-screenshot-shortcut", available)
end

return GUI
