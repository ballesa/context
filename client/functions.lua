local function screenToWorld (flags, ignore)
    local degToRad = function(deg)
        return (deg * math.pi) / 180.0
    end

    local GetMouseCoordinates = function()
        local screenWidth, screenHeight = GetActiveScreenResolution()
    
        local x = GetDisabledControlNormal(2, 239)
        local y = GetDisabledControlNormal(2, 240)
    
        return screenWidth * x, screenHeight * y
    end

    local mulNumber = function(vector1, value)
        local result = {}
        result.x = vector1.x * value
        result.y = vector1.y * value
        result.z = vector1.z * value
        return result
    end
    
    local addVector3 = function(vector1, vector2)
        return {
            x = vector1.x + vector2.x,
            y = vector1.y + vector2.y,
            z = vector1.z + vector2.z
        }
    end
    
    local subVector3 = function(vector1, vector2)
        return {
            x = vector1.x - vector2.x,
            y = vector1.y - vector2.y,
            z = vector1.z - vector2.z
        }
    end

    local rotationToDirection = function(rotation)
        local z = degToRad(rotation.z)
        local x = degToRad(rotation.x)
        local num = math.abs(math.cos(x))
    
        local result = {}
        result.x = -math.sin(z) * num
        result.y = math.cos(z) * num
        result.z = math.sin(x)
        return result
    end
    
    local w2s = function(position)
        local visible, screenX, screenY = GetScreenCoordFromWorldCoord(position["x"], position["y"], position["z"])
    
        if not visible then
            return nil
        end
    
        local newPos = {}
        newPos.x = (screenX - 0.5) * 2
        newPos.y = (screenY - 0.5) * 2
        newPos.z = 0
        return newPos
    end
    
    local processCoordinates = function(x, y)
        local screenX, screenY = GetActiveScreenResolution()
    
        local relativeX = 1 - (x / screenX) * 1.0 * 2
        local relativeY = 1 - (y / screenY) * 1.0 * 2
    
        if (relativeX > 0.0) then
            relativeX = -relativeX
        else
            relativeX = math.abs(relativeX)
        end
    
        if (relativeY > 0.0) then
            relativeY = -relativeY
        else
            relativeY = math.abs(relativeY)
        end
    
        return { x = relativeX, y = relativeY }
    end
    
    local s2w = function(camPos, relX, relY)
        local camRot = IsGameplayCamRendering() and GetGameplayCamRot(0) or GetCamRot(GetRenderingCam())
        local camForward = rotationToDirection(camRot)
        local rotUp = addVector3(camRot, { x = 10, y = 0, z = 0 })
        local rotDown = addVector3(camRot, { x = -10, y = 0, z = 0 })
        local rotLeft = addVector3(camRot, { x = 0, y = 0, z = -10 })
        local rotRight = addVector3(camRot, { x = 0, y = 0, z = 10 })
    
        local camRight = subVector3(
                rotationToDirection(rotRight),
                rotationToDirection(rotLeft)
        )
        local camUp = subVector3(rotationToDirection(rotUp), rotationToDirection(rotDown))
    
        local rollRad = -degToRad(camRot.y)
    
        local camRightRoll = subVector3(
                mulNumber(camRight, math.cos(rollRad)),
                mulNumber(camUp, math.sin(rollRad))
        )
        local camUpRoll = addVector3(
                mulNumber(camRight, math.sin(rollRad)),
                mulNumber(camUp, math.cos(rollRad))
        )
    
        local point3D = addVector3(
                addVector3(addVector3(camPos, mulNumber(camForward, 10.0)), camRightRoll),
                camUpRoll
        )
    
        local point2D = w2s(point3D)
    
        if not point2D then
            return addVector3(camPos, mulNumber(camForward, 10.0))
        end
    
        local point3DZero = addVector3(camPos, mulNumber(camForward, 10.0))
        local point2DZero = w2s(point3DZero)
    
        if not point2DZero then
            return addVector3(camPos, mulNumber(camForward, 10.0))
        end
    
        local eps = 0.001
    
        if (
                math.abs(point2D.x - point2DZero.x) < eps or
                        math.abs(point2D.y - point2DZero.y) < eps
        ) then
            return addVector3(camPos, mulNumber(camForward, 10.0))
        end
    
        local scaleX = (relX - point2DZero.x) / (point2D.x - point2DZero.x)
        local scaleY = (relY - point2DZero.y) / (point2D.y - point2DZero.y)
        local point3Dret = addVector3(
                addVector3(
                        addVector3(camPos, mulNumber(camForward, 10.0)),
                        mulNumber(camRightRoll, scaleX)
                ),
                mulNumber(camUpRoll, scaleY)
        )
    
        return point3Dret
    end

    local x, y = GetMouseCoordinates()

    local absoluteX = x
    local absoluteY = y

    local camPos = IsGameplayCamRendering() and GetGameplayCamCoord() or GetCamCoord(GetRenderingCam())
    local processedCoords = processCoordinates(absoluteX, absoluteY)
    local target = s2w(camPos, processedCoords.x, processedCoords.y)

    local dir = subVector3(target, camPos)
    local from = addVector3(camPos, mulNumber(dir, 0.05))
    local to = addVector3(camPos, mulNumber(dir, 300))

    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        from.x,
        from.y,
        from.z,
        to.x,
        to.y,
        to.z,
        flags,
        ignore,
        0
    )
    return GetShapeTestResult(ray)
end

local function drawSprite (coords, rgba)
    while not HasStreamedTextureDictLoaded('shared') do
        RequestStreamedTextureDict('shared', true)
        Wait(100)
    end

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawSprite("shared", "emptydot_32", 0, 0, 0.015, 0.025, 0, rgba[1], rgba[2], rgba[3], rgba[4] or 200)
    ClearDrawOrigin()
end

function update (data)
    SendNUIMessage({
        action = 'update',
        data = data
    })
end

function executeCallback (callback, ...)
    local success, result = pcall(callback, ...)
    if not success then
        lib.print.error('executeCallback:', result)
    end
    return success, result
end

local function getCommonTargets ()
    local entities = {}
    for _, entity in pairs (GetGamePool('CObject')) do
        if entity and DoesEntityExist(entity) then
            local modelName = GetEntityModel(entity)
            if Common.models[modelName] then
                entities[#entities+1] = entity
            end
        end
    end
    return entities
end

function hoverLoop ()
    CreateThread(function ()
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        Heap.doClose = false
        while Heap.active do
            if Heap.doClose then
                break
            end

            local coords = GetEntityCoords(cache.ped)
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)

            for target, data in pairs (Heap.targets) do
                if type(target) == 'vector3' then
                    local dist = #(coords - target)
                    if dist <= data.dist then
                    end
                else
                    local entCoords = GetEntityCoords(target)
                    local dist = #(coords - entCoords)
                    if dist <= data.dist then
                        drawSprite(entCoords, (Heap.current and Heap.current == target) and {0,255,0,200} or {255, 255, 255, 180})
                    end
                end
            end

            for target, callback in pairs (Common.coords) do
                local dist = #(coords - target)
                if dist <= 10.0 then
                    local endDist = (Heap.current and type(Heap.current) == 'vector3') and #(coords - Heap.current) or nil
                    drawSprite(target, (endDist and endDist < 1.5) and {0,255,0,200} or {255, 255, 255, 180})
                end
            end

            for _, entity in pairs (getCommonTargets()) do
                local entCoords = GetEntityCoords(entity)
                local dist = #(coords - entCoords)
                if dist <= 10.0 then
                    drawSprite(entCoords, (Heap.current and Heap.current == entity) and {0,255,0,200} or {255, 255, 255, 180})
                end
            end

            if not Heap.open then
                local _, hit, endCoords, surfaceNormal, entity = screenToWorld(26, -1)

                if IsPedInAnyVehicle(cache.ped, false) then
                    Heap.open = true
                    executeCallback(openSelfVehicle, GetVehiclePedIsIn(cache.ped, false))
                end

                if #(coords - endCoords) > 10.0 then
                    Heap.current = nil
                    goto continue
                end
                
                if hit == 1 then
                    Heap.current = (entity and DoesEntityExist(entity)) and entity or endCoords
                    DrawLine(coords.x, coords.y, coords.z, endCoords.x, endCoords.y, endCoords.z, 255, 255, 255, 200)

                    if IsDisabledControlJustPressed(1, 24) then
                        for target, data in pairs (Heap.targets) do
                            if type(target) == 'vector3' then
                                local dist = #(target - endCoords)
                                if #(coords - target) < data.dist and dist < 1.5 then
                                    lib.print.info('Target coords: '..target)
                                    executeCallback(data.callback, target, #(coords - target))
                                    goto continue
                                end
                            end
                        end

                        for target, callback in pairs (Common.coords) do
                            local dist = #(target - endCoords)
                            if dist < 1.5 then
                                lib.print.info('Target coords: '..target)
                                executeCallback(callback, target, #(coords - target))
                                goto continue
                            end
                        end

                        if entity and DoesEntityExist(entity) then
                            if entity == cache.ped then
                                executeCallback(openSelfMenu)
                                goto continue
                            elseif entity ~= cache.ped and IsPedAPlayer(entity) then
                                executeCallback(openTargetMenu, entity)
                                goto continue
                            end

                            local entCoords = GetEntityCoords(entity)
                            local dist = #(coords - entCoords)

                            if Heap.targets[entity] and dist <= Heap.targets[entity].dist then
                                lib.print.info('Target entity: '..entity)
                                executeCallback(Heap.targets[entity].callback, entity, dist, close)
                                goto continue
                            end

                            if NetworkGetEntityIsNetworked(entity) then
                                local netId = NetworkGetNetworkIdFromEntity(entity)
                                if Heap.targets[netId] and dist <= Heap.targets[netId].dist then
                                    lib.print.info('Target netId: '..netId)
                                    executeCallback(Heap.targets[entity].callback, entity, dist, close)
                                    goto continue
                                end
                            end

                            local modelName = GetEntityModel(entity)
                            if Common.models[modelName] and dist <= 10.0 then
                                lib.print.info('Target modelName: '..modelName)
                                executeCallback(Common.models[modelName], entity, dist, close)
                                goto continue
                            end

                            if IsModelAVehicle(modelName) then
                                executeCallback(openVehicle, entity)
                                goto continue
                            end

                            if IsEntityAPed(entity) then
                                goto continue
                            end

                            Core.sendNotification('Okänt object', 'Context', 'error')
                        end
                    end
                else
                    Heap.current = nil
                end
            end

            :: continue ::
            Wait(0)
        end

        if Heap.open and Heap.onClose then
            Heap.onClose(Heap.target or Heap.current)
        end

        Heap.active = false
        Heap.current = nil
        Heap.open = false
        Heap.callbacks = {}
        Heap.onClose = nil
        Heap.nui = {}
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        update({
            visible = false
        })
    end)
end

function close ()
    Heap.doClose = true
    Heap.active = false
end
exports('close', close)

local function add (target, callback, dist)
    Heap.targets[target] = {
        dist = dist or 10.0,
        callback = callback
    }
    lib.print.info('Added target for '..target)
end
exports('add', add)

local function remove (target)
    Heap.targets[target] = nil
    lib.print.info('Removed target for '..target)
end
exports('remove', remove)

function open (target, data, options, pos)
    Heap.open = true
    Heap.target = target or Heap.current
    Heap.onClose = data.onClose or nil

    Heap.nui = {}
    for i, el in pairs (options) do
        el.index = i

        if el.callback then
            Heap.callbacks[tostring(i)] = el.callback
            el.callback = nil
        end

        if el.sub and next(el.sub) then
            for _i, _el in pairs (el.sub) do
                _el.index = _i
                Heap.callbacks[tostring(i)..':'..tostring(_i)] = _el.callback
                _el.callback = nil
            end
        end
        Heap.nui[#Heap.nui+1] = el
    end

    local x, y = GetDisabledControlNormal(0, 239), GetDisabledControlNormal(0, 240)

    update({
        visible = true,
        label = data.label or 'Ingen label',
        options = Heap.nui,
        pos = pos or {
            x = x*100,
            y = y*100
        }
    })
end
exports('open', open)