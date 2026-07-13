local Utils = require("scripts.utils")
local Tracker = require("scripts.tracker")

-- Viewfinder boxes drawn on the map (chart) view. `key` identifies the render
-- object on the camera. The capture box uses the camera's own colour (see
-- Camera.boxColorFor); `captureBox.color` is only the default/fallback tint. The
-- target box keeps a fixed green, matching the tints previously used for the corner
-- signals (see prototypes/signal.lua).
-- Default matches the first colour preset (white) so "default" and that preset are the
-- same thing -- no separate reset needed.
local defaultBoxColor = { r = 1, g = 1, b = 1 }
local captureBox = { key = "capture", color = defaultBoxColor }
local targetBox = { key = "target", color = { r = 0.1, g = 0.6, b = 0.2 } }
-- A disabled camera's capture box is drawn with a dashed outline (in the camera's own
-- colour) so "disabled" is obvious regardless of the chosen colour -- colour-based dimming
-- alone was too subtle. Lengths are in tiles. Applied from GUI/config events, never from
-- tick(). Each box side is a separate draw_line (draw_rectangle cannot dash).
local dashLength = 4
local gapLength = 4
-- The four sides of a box, in a fixed order; each is its own render object keyed
-- "<box.key>:<side>" in camera.renderBoxes.
local boxSides = { "top", "right", "bottom", "left" }

local Camera = {}

-- Default viewfinder colour (also the first colour preset), exposed to the GUI.
Camera.defaultBoxColor = defaultBoxColor

--- @class Camera.camera
--- @field centerPos table
--- @field enabled boolean
--- @field entityInfo boolean Show entity info in the screenshots
--- @field showGUI boolean Show GUI in the screenshots
--- @field alwaysDay boolean Render screenshot in daylight
--- @field frameRate number
--- @field height number
--- @field lastKnownActiveTracker Tracker.tracker|nil
--- @field changeId integer|nil Last known change ID of the tracker
--- @field name string
--- @field saveFolder string
--- @field saveName string
--- @field screenshotNumber integer Number for the next screenshot (when sequentialNames is set in player settings)
--- @field screenshotInterval number Interval (game ticks) between two screenshots (calculated from speedGain and frameRate)
--- @field screenshotIntervalRealtime number Interval (game ticks) between two screenshots for realtime transitions (calculated from frameRate)
--- @field screenshotIntervalTransition number Interval (game ticks) between two screenshots during transitions (calculated from frameRate)
--- @field speedGain number Amount (factor) that the timelapse movie should speed up compared to the game.
--- @field surfaceName SurfaceIdentification
--- @field trackers Tracker.tracker[]
--- @field renderBoxes table<string, LuaRenderObject> Render objects (chart mode) showing the viewfinder boxes on the map, keyed by box (see captureBox/targetBox)
--- @field boxColor Color|nil Custom viewfinder box colour (r,g,b in 0-1); nil uses Camera.defaultBoxColor
--- @field width number
--- @field zoom number
--- @field transitionPeriod number Time (in seconds) a transition should take
--- @field transitionSpeedGain number Amount (factor) that the timelapse movie should speed up during transitions.
--- @field transitionTicks number Time (in ticks) a transition should take (calculated from transitionPeriod)
--- @field transitionData Camera.cameraTransition|nil When set, a transition is active

--- @class Camera.cameraTransition
--- @field ticks integer Number of ticks (screenshots) the transitions takes
--- @field transitionTicksLeft integer Number of ticks (screenshots) left of the transition
--- @field startPosition MapPosition.0 (Center) position of the camera when the current transition started
--- @field startZoom number Zoom factor of the camera when the current transition started
--- @field endPosition MapPosition.0 (Center) position of the tracker when the current transition started
--- @field endZoom number Zoom factor of the tracker when the current transition started
Camera.CameraTransition = {}

local maxZoom = 1
local minZoom = 0.031250
local ticks_per_second = 60
local ms_per_tick = 1000 / ticks_per_second
local tileSize = 32

--- @param player LuaPlayer
--- @param cameraList Camera.camera[]
--- @return Camera.camera
function Camera.newCamera(player, cameraList)
    local nameIndex = 1
    local cameraName = "new camera"
    while cameraList ~= nil and not Utils.uniqueName(cameraList, cameraName) do
        nameIndex = nameIndex + 1
        cameraName = "new camera-" .. nameIndex
    end

    --- @type Camera.camera
    --- @diagnostic disable-next-line: missing-fields The missing fields are set in updateConfig() and setName()
    local camera = {
        enabled = false,
        surfaceName = player.surface.name,
        entityInfo = false,
        showGUI = false,
        alwaysDay = true,
        trackers = {},
        centerPos = player.position,
        zoom = 1,
        screenshotNumber = 1,
        renderBoxes = {},
        -- settings/defaults
        width = 1920,
        height = 1080,
        frameRate = 25,
        speedGain = 60,
        transitionPeriod = 1.5,
        transitionSpeedGain = 60
    }

    Camera.updateConfig(camera)
    Camera.setName(camera, cameraName);

    return camera
end

---@param camera Camera.camera
function Camera.updateConfig(camera)
    camera.screenshotInterval = math.max(math.floor((ticks_per_second * camera.speedGain) / camera.frameRate), 1)
    camera.screenshotIntervalRealtime = math.max(math.floor(ticks_per_second / camera.frameRate), 1)
    camera.screenshotIntervalTransition = math.max(
        math.floor((ticks_per_second * camera.transitionSpeedGain) / camera.frameRate), 1)
    camera.transitionTicks = math.max(math.floor(camera.frameRate * camera.transitionPeriod), 1)
end

---Update the name of the Camera and its save folder and name.
---@param camera Camera.camera
---@param newName string
function Camera.setName(camera, newName)
    local path, name = string.match(newName, "(.-)([^\\/]-)$")
    camera.name = newName
    camera.saveFolder = path
    camera.saveName = name
end

---@param camera Camera.camera
function Camera.refreshConfig(camera)
    local transitionPeriod, frameRate, speedGain
    if camera.speedGain == nil then
        -- Try to recover as good as possible...
        ---@diagnostic disable-next-line: undefined-field camera.zoomTicks is the old field (old migrations use this function as well)
        transitionPeriod = (camera.transitionTicks or camera.zoomTicks) / ticks_per_second
        ---@diagnostic disable-next-line: undefined-field camera.realtimeInterval is the old field (old migrations use this function as well)
        frameRate = ticks_per_second / (camera.screenshotIntervalRealtime or camera.realtimeInterval)

        local speedGain1 = 1 -- camera.transitionTicks / (ticks_per_second * transitionPeriod)
        local speedGain2 = (camera.screenshotInterval * frameRate) / ticks_per_second
        speedGain = (speedGain1 + speedGain2) / 2
    else
        transitionPeriod = camera.transitionTicks / (camera.speedGain * ticks_per_second)
        frameRate = math.floor((ticks_per_second * camera.speedGain) / camera.screenshotInterval)

        -- Two ways to calculate speedGain, so take average
        local speedGain1 = camera.transitionTicks / (ticks_per_second * camera.transitionPeriod)
        local speedGain2 = (camera.screenshotInterval * camera.frameRate) / ticks_per_second
        speedGain = (speedGain1 + speedGain2) / 2
    end

    camera.transitionPeriod = math.floor(transitionPeriod * 100) / 100
    camera.frameRate = math.floor(frameRate + 0.5)
    camera.speedGain = math.floor(speedGain * 100) / 100
end

--- @param camera Camera.camera
--- @param tracker Tracker.tracker
function Camera.SetActiveTracker(camera, tracker)
    camera.lastKnownActiveTracker = tracker
    camera.changeId = nil
end

--- @param playerSettings playerSettings
--- @param player LuaPlayer
--- @param camera Camera.camera
--- @param tracker Tracker.tracker
--- @param disableSmooth boolean|nil Override the smooth (transition) option of the tracker
function Camera.followTracker(playerSettings, player, camera, tracker, disableSmooth)
    if tracker.centerPos == nil then
        return
    end

    if tracker.smooth and not disableSmooth then
        Camera.followTrackerSmooth(playerSettings, player, camera, tracker)
    else
        camera.centerPos = tracker.centerPos
        camera.zoom = Camera.zoom(camera, tracker)
        Camera.sanitizeZoom(camera, playerSettings, player)
    end

    -- Label the box with the camera name when the player has more than one camera,
    -- so overlapping viewfinders on the map can be told apart.
    local showName = #playerSettings.cameras > 1
    Camera.refreshBox(player, camera, captureBox, camera.centerPos, camera.zoom, showName)
end

--- @param playerSettings playerSettings
--- @param player LuaPlayer
--- @param camera Camera.camera
--- @param tracker Tracker.tracker
function Camera.followTrackerSmooth(playerSettings, player, camera, tracker)
    if camera.changeId ~= tracker.changeId then
        camera.transitionData = {
            startPosition = camera.centerPos,
            startZoom = camera.zoom,
            endPosition = tracker.centerPos,
            endZoom = Camera.zoom(camera, tracker),
            ticks = camera.transitionTicks,
            transitionTicksLeft = camera.transitionTicks
        }
        camera.changeId = tracker.changeId
        -- new transition target, so draw the target box
        Camera.refreshBox(player, camera, targetBox, camera.transitionData.endPosition,
            camera.transitionData.endZoom)
    end

    local transitionData = camera.transitionData
    if transitionData ~= nil then
        transitionData.transitionTicksLeft = transitionData.transitionTicksLeft - 1

        camera.centerPos, camera.zoom = Camera.CameraTransition.lerp(transitionData)
        Camera.sanitizeZoom(camera, playerSettings, player)

        if transitionData.transitionTicksLeft <= 0 then
            -- Transition finished
            camera.transitionData = nil
            -- remove the target box
            Camera.refreshBox(player, camera, targetBox, nil, nil)
        end
    end
end

--- Linear interpolation for the Camera transition.
--- @param transitionData Camera.cameraTransition
--- @return MapPosition.0 centerPos Current center position for the camera
--- @return number zoom Current zoom (factor) for the camera
function Camera.CameraTransition.lerp(transitionData)
    local t = Utils.clamp(0, 1, (transitionData.ticks - transitionData.transitionTicksLeft) / transitionData.ticks)
    return {
            x = transitionData.startPosition.x + (transitionData.endPosition.x - transitionData.startPosition.x) * t,
            y = transitionData.startPosition.y + (transitionData.endPosition.y - transitionData.startPosition.y) * t
        },
        transitionData.startZoom + (transitionData.endZoom - transitionData.startZoom) * t
end

-- Calculate desired zoom
--- @param camera Camera.camera
--- @param tracker Tracker.tracker
function Camera.zoom(camera, tracker)
    local zoomX = camera.width / (tileSize * tracker.size.x)
    local zoomY = camera.height / (tileSize * tracker.size.y)
    return math.min(zoomX, zoomY, maxZoom)
end

-- Check if the camera zoom is valid
--- @param camera Camera.camera
--- @param playerSettings playerSettings
--- @param player LuaPlayer
function Camera.sanitizeZoom(camera, playerSettings, player)
    if camera.zoom < minZoom then
        if playerSettings.noticeMaxZoom == nil then
            player.print({ "max-zoom" }, { r = 1 })
            player.print({ "msg-once" })
            playerSettings.noticeMaxZoom = true
        end

        camera.zoom = minZoom
    else
        -- Max (min actually) zoom is not reached (anymore)
        playerSettings.noticeMaxZoom = nil
    end
end

---@param camera Camera.camera
---@param activeTracker Tracker.tracker
function Camera.getScreenshotInterval(camera, activeTracker)
    if camera.transitionData ~= nil then
        return camera.screenshotIntervalTransition
    end
    if activeTracker.realtimeCamera then
        return camera.screenshotIntervalRealtime
    end

    return camera.screenshotInterval
end

-- Set the camera (resolution) width
--- @param playerSettings playerSettings
--- @param player LuaPlayer
--- @param camera Camera.camera
--- @param width any Camera (resolution) width
function Camera.setWidth(playerSettings, player, camera, width)
    width = tonumber(width)

    if width == nil or width < 320 then
        -- keep minimum width
        width = 320
    end

    local requireUpdate = width ~= camera.width
    camera.width = width
    if requireUpdate then
        local _, activeTracker = Tracker.findActiveTracker(camera.trackers, camera.surfaceName)
        if activeTracker ~= nil then
            -- Force update zoom level to make sure the tracked area stays the same
            Camera.followTracker(playerSettings, player, camera, activeTracker, true)
        end
    end
end

-- Set the camera (resolution) height
--- @param playerSettings playerSettings
--- @param player LuaPlayer
--- @param camera Camera.camera
--- @param height any Camera (resolution) height
function Camera.setHeight(playerSettings, player, camera, height)
    height = tonumber(height)

    if height == nil or height < 240 then
        -- keep minimum height
        height = 240
    end

    local requireUpdate = height ~= camera.height
    camera.height = height
    if requireUpdate then
        local _, activeTracker = Tracker.findActiveTracker(camera.trackers, camera.surfaceName)
        if activeTracker ~= nil then
            -- Force update zoom level to make sure the tracked area stays the same
            Camera.followTracker(playerSettings, player, camera, activeTracker, true)
        end
    end
end

function Camera.setFrameRate(camera, framerate)
    framerate = tonumber(framerate)

    if framerate == nil or framerate < 1 then
        -- keep minimum frame rate
        framerate = 1
    end

    camera.frameRate = framerate
    Camera.updateConfig(camera)
end

---@param camera Camera.camera
---@param speedGain any
function Camera.setSpeedGain(camera, speedGain)
    speedGain = tonumber(speedGain)

    if speedGain == nil or speedGain < 1 then
        -- keep minimum speed gain
        speedGain = 1
    end

    camera.speedGain = speedGain
    Camera.updateConfig(camera)
end

---@param camera Camera.camera
---@param interval any
function Camera.setFrameInterval(camera, interval)
    interval = tonumber(interval)

    if interval == nil or interval < ms_per_tick then
        -- keep minimum interval
        interval = ms_per_tick
    end

    local speedGain = (interval * camera.frameRate) / 1000
    if speedGain < 1 then
        -- keep minimum speed gain
        speedGain = 1
    end

    camera.speedGain = speedGain
    Camera.updateConfig(camera)
end

---@param camera Camera.camera
---@return number|nil interval Camera interval
function Camera.calculateFrameInterval(camera)
    if camera.speedGain == nil or camera.frameRate == nil then
        return nil
    end


    local interval = ((1000 * camera.speedGain) / camera.frameRate)

    if interval < ms_per_tick then
        -- keep minimum interval
        interval = ms_per_tick
    end

    return interval
end

---@param camera Camera.camera
---@param speedGain any
---@param allowStopMotion boolean
function Camera.setTransitionSpeedGain(camera, speedGain, allowStopMotion)
    speedGain = tonumber(speedGain)

    if speedGain == nil then
        speedGain = 0
    end
    if not allowStopMotion and speedGain == 0 then
        speedGain = 1
    end

    camera.transitionSpeedGain = speedGain
    Camera.updateConfig(camera)
end

---@param camera Camera.camera
---@param interval any
---@param allowStopMotion boolean
function Camera.setTransitionFrameInterval(camera, interval, allowStopMotion)
    interval = tonumber(interval)

    if interval == nil then
        -- keep minimum interval
        interval = ms_per_tick
    end
    if not allowStopMotion and interval == 0 then
        interval = ms_per_tick
    end

    local speedGain = (interval * camera.frameRate) / 1000
    if not allowStopMotion and speedGain < 1 then
        -- keep minimum speed gain
        speedGain = 1
    end

    camera.transitionSpeedGain = speedGain
    Camera.updateConfig(camera)
end

---@param camera Camera.camera
---@return number|nil interval Camera interval
function Camera.calculateTransitionFrameInterval(camera)
    if camera.transitionSpeedGain == nil or camera.frameRate == nil then
        return nil
    end


    local interval = ((1000 * camera.transitionSpeedGain) / camera.frameRate)

    if interval < ms_per_tick then
        -- keep minimum interval
        interval = ms_per_tick
    end

    return interval
end

--- @param camera Camera.camera
--- @param transitionPeriod any
function Camera.setTransitionPeriod(camera, transitionPeriod)
    transitionPeriod = tonumber(transitionPeriod)

    if transitionPeriod == nil or transitionPeriod < 0 then
        -- keep minimum zoom period (0 = disabled)
        transitionPeriod = 0
    end

    camera.transitionPeriod = transitionPeriod
    Camera.updateConfig(camera)
end

--- Destroy and forget the render object stored under `key`, if any.
--- @param renderBoxes table<string, LuaRenderObject>
--- @param key string
local function removeRenderBox(renderBoxes, key)
    if renderBoxes[key] then
        renderBoxes[key].destroy() -- does not error when already invalid
        renderBoxes[key] = nil
    end
end

--- Whether a render object is present, valid, and still on the given surface.
--- Render objects are bound to their creation surface (surface is read-only), so
--- one can only be reused while the camera still points at that surface.
--- @param object LuaRenderObject?
--- @param surfaceName SurfaceIdentification
--- @return boolean
local function onSurface(object, surfaceName)
    return object ~= nil and object.valid and object.surface.name == surfaceName
end

--- Resolve the colour a camera's capture box (and name label) is drawn with: the camera's
--- custom colour, or the default. Enabled/disabled is shown by the dash pattern (see
--- boxDash), not the colour. The target box is not passed here; it keeps its fixed colour.
--- @param camera Camera.camera
--- @return Color
function Camera.boxColorFor(camera)
    local base = camera.boxColor or defaultBoxColor
    return { r = base.r, g = base.g, b = base.b }
end

-- Colour a box is drawn with: the capture box uses the camera's (custom) colour, other
-- boxes their fixed descriptor colour.
--- @param box table
--- @param camera Camera.camera
--- @return Color
local function drawColor(box, camera)
    if box.key == captureBox.key then
        return Camera.boxColorFor(camera)
    end
    return box.color
end

-- Dash pattern (tiles) for a box: a disabled camera's capture box is dashed; everything
-- else (enabled capture box, target box) is solid. dash_length is kept positive at all
-- times because Factorio requires dash_length > 0 whenever gap_length > 0 and validates
-- this on every individual property write (in any order); a solid line is therefore
-- expressed purely as gap_length = 0, which ignores dash_length.
--- @param box table
--- @param camera Camera.camera
--- @return number dash_length, number gap_length
local function boxDash(box, camera)
    local dashed = box.key == captureBox.key and not camera.enabled
    return dashLength, dashed and gapLength or 0
end

-- The from/to endpoints of each of the four sides of a box.
--- @param left_top number[]     {x, y} top-left corner
--- @param right_bottom number[] {x, y} bottom-right corner
--- @return table<string, table> keyed by side (see boxSides)
local function boxSegments(left_top, right_bottom)
    local lx, ty = left_top[1], left_top[2]
    local rx, by = right_bottom[1], right_bottom[2]
    return {
        top    = { from = { lx, ty }, to = { rx, ty } },
        right  = { from = { rx, ty }, to = { rx, by } },
        bottom = { from = { lx, by }, to = { rx, by } },
        left   = { from = { lx, ty }, to = { lx, by } },
    }
end

--- Draw, update or remove a viewfinder box on the map (chart) view.
--- Uses a chart-mode render object, so the box is only visible on the map and
--- never ends up in the (game view) screenshots taken by the camera.
--- @param player       LuaPlayer
--- @param camera       Camera.camera   the camera this box is for
--- @param box          table           box descriptor (see captureBox/targetBox)
--- @param centerPos    table?          x,y pair giving the center of the box, nil to remove the box
--- @param zoom         number?         zoom factor for the box, ignored when removing
--- @param showName     boolean?        whether to label the box with the camera name
--- @param recreate     boolean?        force redrawing the lines (used when the dash
---                                     pattern changes; see refreshCameraBox) instead of
---                                     reusing/moving the existing ones
function Camera.refreshBox(player, camera, box, centerPos, zoom, showName, recreate)
    -- we can't do this without a player or force
    if not player or not player.force then
        return
    end

    local renderBoxes = camera.renderBoxes
    local labelKey = box.key .. ":name"

    -- no position means: remove the box (e.g. finished transition)
    if not centerPos then
        for _, side in ipairs(boxSides) do
            removeRenderBox(renderBoxes, box.key .. ":" .. side)
        end
        removeRenderBox(renderBoxes, labelKey)
        return
    end

    local half_width = camera.width / (tileSize * zoom) / 2
    local half_height = camera.height / (tileSize * zoom) / 2
    local left_top = { centerPos.x - half_width, centerPos.y - half_height }
    local right_bottom = { centerPos.x + half_width, centerPos.y + half_height }

    -- The box is four separate lines so its outline can be dashed (draw_rectangle cannot).
    -- Recording just moves the endpoints (cheap); the dash pattern is only (re)applied when
    -- a line is created, so a dash change is requested via `recreate` (see refreshCameraBox)
    -- rather than by mutating dash_length/gap_length on a live line, which is unreliable.
    local segments = boxSegments(left_top, right_bottom)
    for _, side in ipairs(boxSides) do
        local seg = segments[side]
        local key = box.key .. ":" .. side
        local existing = renderBoxes[key]
        if not recreate and onSurface(existing, camera.surfaceName) then
            existing.from = seg.from
            existing.to = seg.to
        else
            removeRenderBox(renderBoxes, key) -- clean up an existing/stale line first
            local dash, gap = boxDash(box, camera)
            renderBoxes[key] = rendering.draw_line {
                color = drawColor(box, camera),
                width = 2,
                from = seg.from,
                to = seg.to,
                dash_length = dash,
                gap_length = gap,
                surface = camera.surfaceName,
                players = { player },
                render_mode = "chart",
            }
        end
    end

    -- optional camera name label, anchored just above the top-left corner
    if showName then
        local existingLabel = renderBoxes[labelKey]
        if onSurface(existingLabel, camera.surfaceName) then
            existingLabel.target = left_top
            existingLabel.text = camera.name
        else
            removeRenderBox(renderBoxes, labelKey) -- clean up a stale label left on a previous surface
            renderBoxes[labelKey] = rendering.draw_text {
                text = camera.name,
                color = drawColor(box, camera),
                surface = camera.surfaceName,
                target = left_top,
                players = { player },
                render_mode = "chart",
                scale = 1,
                scale_with_zoom = true,
                vertical_alignment = "bottom",
            }
        end
    else
        removeRenderBox(renderBoxes, labelKey)
    end
end

--- @param player LuaPlayer
function Camera.recordingSensor(player)
    local playerSettings = storage.playerSettings[player.index]

    if playerSettings == nil or not playerSettings.showCameraStatus then
        return nil
    end

    if playerSettings.pauseCameras == true then
        return {
            "stats.all-paused"
        }
    end

    local cameraStatuses = {}
    for _, camera in pairs(playerSettings.cameras) do
        table.insert(cameraStatuses, ", ")
        table.insert(cameraStatuses, camera.name .. " = ")
        if not camera.enabled then
            table.insert(cameraStatuses, { "stats.disabled" })
        elseif camera.transitionData ~= nil then
            table.insert(cameraStatuses, { "stats.transition", camera.transitionData.transitionTicksLeft })
        else
            table.insert(cameraStatuses, { "stats.recording" })
        end
    end

    if #cameraStatuses == 0 then
        return nil
    end

    -- Get rid of first ',' and let Factorio localization concatenate the table
    cameraStatuses[1] = ""

    return cameraStatuses
end

--- Recolour a camera's existing capture box (its four sides and name label). Only the
--- colour is changed here (e.g. from the colour picker); the dash pattern is applied when
--- the box is (re)created (see refreshCameraBox), because toggling dash_length/gap_length
--- on a live line is unreliable -- Factorio ignores dash_length while gap_length is 0, so a
--- later gap_length > 0 would fail the "dash_length must be > 0" check.
--- @param camera Camera.camera
function Camera.updateBoxColor(camera)
    local color = Camera.boxColorFor(camera)
    for _, side in ipairs(boxSides) do
        local line = camera.renderBoxes[captureBox.key .. ":" .. side]
        if line and line.valid then
            line.color = color
        end
    end
    local label = camera.renderBoxes[captureBox.key .. ":name"]
    if label and label.valid then
        label.color = color
    end
end

--- Set (or clear) a camera's custom viewfinder colour and recolour its box on the map.
--- @param camera Camera.camera
--- @param color Color|nil r,g,b (0-1); nil resets to Camera.defaultBoxColor
function Camera.setBoxColor(camera, color)
    if color == nil then
        camera.boxColor = nil
    else
        camera.boxColor = { r = color.r, g = color.g, b = color.b }
    end
    Camera.updateBoxColor(camera)
end

--- Show, hide or restyle a camera's viewfinder box in response to a GUI/config event
--- (never from tick()). Enabled cameras always show a box (drawn right away, then kept
--- up to date by the recording loop); disabled cameras show a dashed box only when
--- `render` is set, otherwise their box is removed.
--- @param player LuaPlayer
--- @param camera Camera.camera
--- @param render boolean whether disabled cameras should be shown on the map
--- @param showName boolean whether to label the box with the camera name
function Camera.refreshCameraBox(player, camera, render, showName)
    if camera.enabled or render then
        -- recreate=true so the dash pattern (solid when enabled, dashed when disabled) is
        -- applied atomically by draw_line -- mutating dash/gap on a live line is unreliable.
        -- Only runs on GUI/config events; the per-frame recording path reuses instead.
        Camera.refreshBox(player, camera, captureBox, camera.centerPos, camera.zoom, showName, true)
    else
        Camera.refreshBox(player, camera, captureBox, nil, nil) -- disabled and hidden: remove
    end
end

--- Refresh every camera's viewfinder box for a player, e.g. after the "render disabled
--- cameras" setting changed or a camera was added/removed.
--- @param player LuaPlayer
--- @param playerSettings playerSettings
function Camera.refreshAllBoxes(player, playerSettings)
    local showName = #playerSettings.cameras > 1
    for _, camera in pairs(playerSettings.cameras) do
        Camera.refreshCameraBox(player, camera, playerSettings.renderDisabledCameras, showName)
    end
end

--- @param camera Camera.camera
function Camera.destroy(camera)
    for _, box in pairs(camera.renderBoxes) do
        box.destroy() -- does not error when already invalid
    end
end

return Camera
