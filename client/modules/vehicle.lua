local self = {
    custom = {}
}

local function addInVehicle (data)
    self.custom[#self.custom+1] = data
    return true
end
exports('addInVehicle', addInVehicle)

local function removeInVehicle (data)
    for i, _data in pairs (self.custom) do
        for __, __data in pairs (data) do
            if __data == _data[__] then
                self.custom[i] = nil
                return true
            end
        end
    end
    return false
end
exports('removeInVehicle', removeInVehicle)

local lastSpeed = nil
local function setMaxSpeed (target, item, update, close)
    if lastSpeed ~= item.speed then
        lastSpeed = item.speed
        return SetEntityMaxSpeed(target, item.speed*0.5)
    end

    lastSpeed = nil
    SetEntityMaxSpeed(target, GetVehicleMaxSpeed(target)*3.6)
end

local function updateLockState (entity)
    local state <const> = GetVehicleDoorLockStatus(entity) == 2
    print('Current lock state:', state)
    TriggerServerEvent('inventory:server:changeLockState', NetworkGetNetworkIdFromEntity(entity), not state)
    Core.sendNotification(state and 'Fordonet låstes upp' or 'Fordonet låstes')
    return not state
end

local function setDoorState (target, item, update, close)
    if GetVehicleDoorAngleRatio(target, item.id) > 0.0 then
        SetVehicleDoorShut(target, item.id, false)
    else
        SetVehicleDoorOpen(target, item.id, false)
    end
end

local function playAnimation (entity, dict, lib, flag)
    flag = flag or 49
    if not IsEntityPlayingAnim(entity, dict, lib, flag) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
        TaskPlayAnim(entity, dict, lib, 2.0, -1.0, -1, flag, 0, 0, 0, 0)
    end
end

function openSelfVehicle (entity)
    if not Core.isLoaded() then return end
    print('self vehicle: '..entity)

    local manageSub = {
        {
            label = GetVehicleDoorLockStatus(entity) == 2 and 'Lås upp' or 'Lås',
            disabled = not exports.inventory:hasKey(GetVehicleNumberPlateText(entity), true),
            callback = function (target, item, update, close)
                if not exports.inventory:hasKey(GetVehicleNumberPlateText(entity), true) then
                    return
                end

                update({ label = updateLockState(entity) and 'Lås upp' or 'Lås' })
            end
        },
        {
            label = exports.inventory:hasKey(GetVehicleNumberPlateText(entity), true) and (GetIsVehicleEngineRunning(entity) and 'Stäng av motorn' or 'Starta motorn') or (GetIsVehicleEngineRunning(entity) and 'Stäng av motor' or 'Använd skruvmejsel'),
            callback = function (target, item, update, close)
                if item.label == 'Använd skruvmejsel' then
                    local hotbar = exports.inventory:getCurrentHotbarItem()
                    if hotbar and hotbar.itemName == 'skruvmejsel' then
                        close()

                        if hotbar.metadata.durability < 1.5 then
                            Core.sendNotification('Skruvmejsel är för skaddad för detta...', 'Contextmeny', 'error')
                            return
                        end

                        local success, message = exports.inventory:setUsingItem(hotbar.item, true)
                        if not success then
                            Core.sendNotification(message)
                            return
                        end

                        playAnimation(cache.ped, 'anim@veh@helicopter@havok@ds@base', 'hotwire', 1)
                        Wait(350)
                        local success = exports.bl_ui:KeySpam(math.random(1 , 3), 65)
                        if success then
                            local success = Core.triggerCallback('inventory:server:removeDurability', hotbar.inv, hotbar.item, 4.7)
                            if success then
                                SetVehicleEngineOn(entity, true, true, true)
                            end
                        else
                            local success = Core.triggerCallback('inventory:server:removeDurability', hotbar.inv, hotbar.item, 9.6)
                        end
                        local success, message = exports.inventory:setUsingItem(hotbar.item, false)
                        ClearPedTasks(cache.ped)
                    else
                        Core.sendNotification('Du måste ha en skruvmejsel i handen', 'Contextmeny', 'error')
                    end
                    return
                end

                local label = exports.inventory:hasKey(GetVehicleNumberPlateText(entity), true) and (not GetIsVehicleEngineRunning(entity) and 'Stäng av motorn' or 'Starta motorn') or (not GetIsVehicleEngineRunning(entity) and 'Stäng av motor' or 'Använd skruvmejsel')
                update({ label = label })
                SetVehicleEngineOn(entity, not GetIsVehicleEngineRunning(entity), true, true)
            end
        },
        {
            label = LocalPlayer.state.belt and 'Ta av bälte' or 'Sätt på bälte',
            callback = function (target, item, update, close)
                ExecuteCommand('toggleseatbelt')
                Wait(200)
                update({ label = LocalPlayer.state.belt and 'Ta av bälte' or 'Sätt på bälte' })
            end
        }
    }
    local options = {
        {
            label = 'Karaktär',
            callback = function (target, item, update, close)
                -- close()
                openSelfMenu()
            end
        },
        {
            label = 'Hantera',
            sub = manageSub
        },
        {
            label = 'Handskfack',
            callback = function (target, item, update, close)
                close()
                local plate = GetVehicleNumberPlateText(entity)
                local storageId = ('glovebox-%s'):format(plate)
                exports.inventory:openContainer(
                    storageId,
                    'Handskfack - ' .. plate,
                    5,
                    nil, nil,
                    'stash'
                )
            end
        },
        {
            label = 'Farthållare',
            sub = {
                {
                    label = '20km/h',
                    speed = 20.0,
                    callback = setMaxSpeed
                },
                {
                    label = '40km/h',
                    speed = 40.0,
                    callback = setMaxSpeed
                },
                {
                    label = '60km/h',
                    speed = 60.0,
                    callback = setMaxSpeed
                },
                {
                    label = '80km/h',
                    speed = 80.0,
                    callback = setMaxSpeed
                },
                {
                    label = '120km/h',
                    speed = 120.0,
                    callback = setMaxSpeed
                }
            }
        },
        {
            label = 'Dörrar',
            sub = {
                {
                    label = 'Främre förardörr',
                    id = 0,
                    callback = setDoorState
                },
                {
                    label = 'Främre passagerardörr',
                    id = 1,
                    callback = setDoorState
                },
                {
                    label = 'Bakre förardörr',
                    id = 2,
                    callback = setDoorState
                },
                {
                    label = 'Bakre passagerardörr',
                    id = 3,
                    callback = setDoorState
                },
                {
                    label = 'Motorhuv',
                    id = 4,
                    callback = setDoorState
                },
                {
                    label = 'Bakluka',
                    id = 5,
                    callback = setDoorState
                }
            }
        }
    }

    for i, data in pairs (self.custom) do
        options[#options+1] = {
            label = data.label,
            sub = data.sub or nil,
            callback = data.callback
        }
    end

    open(entity, {
        label = GetVehicleNumberPlateText(entity),
        onClose = function (target)
        end
    }, options, {
        x = 50.0,
        y = 50.0
    })
end

function openVehicle (entity)
    print('vehicle: '..entity)
    local hasKey = exports.inventory:hasKey(GetVehicleNumberPlateText(entity), true)
    local options = {}

    if hasKey then
        options[#options+1] = {
            label = GetVehicleDoorLockStatus(entity) == 2 and 'Lås upp' or 'Lås',
            callback = function (entity, item, update, close)
                if not exports.inventory:hasKey(GetVehicleNumberPlateText(entity), true) then
                    open(entity, {
                        label = GetVehicleNumberPlateText(entity),
                        onClose = function (entity)
                        end
                    }, {
                        {
                            label = 'Använd dyrkset',
                            callback = function (entity, item, update, close)
                                close()

                                hotbar = exports.inventory:getCurrentHotbarItem()
                                if not hotbar or hotbar.itemName ~= 'lockpick' then
                                    Core.sendNotification('Du måste ha ett dyrkset i handen', 'Contextmeny', 'error')
                                    return
                                end

                                if hotbar.metadata.durability < 1.5 then
                                    Core.sendNotification('Dyrksetet är för skaddat', 'Contextmeny', 'error')
                                    return
                                end

                                local success, message = exports.inventory:setUsingItem(hotbar.item, true)
                                if not success then
                                    Core.sendNotification(message)
                                    return
                                end

                                playAnimation(PlayerPedId(), 'missheistfbisetup1', 'hassle_intro_loop_f', 1)
                                Wait(350)

                                local success = exports.bl_ui:Untangle(3, {
                                    numberOfNodes = 2,
                                    duration = 15000,
                                })

                                if success then
                                    local dsuccess = Core.triggerCallback('inventory:server:removeDurability', hotbar.inv, hotbar.item, 4.7)
                                    if dsuccess then
                                        updateLockState(entity)
                                    end
                                else
                                    local dsuccess = Core.triggerCallback('inventory:server:removeDurability', hotbar.inv, hotbar.item, 9.6)
                                end

                                StartVehicleAlarm(entity)
                                local success, message = exports.inventory:setUsingItem(hotbar.item, false)
                                ClearPedTasks(PlayerPedId())
                            end
                        }
                    })
                    return
                end
                updateLockState(entity)
                close()
                Wait(100)
               openVehicle(entity)
            end
        }
    elseif not hasKey and GetVehicleDoorLockStatus(entity) == 2 then
        local hotbar = exports.inventory:getCurrentHotbarItem()
        if hotbar and hotbar.itemName == 'lockpick' then
            print('Lockpick')
            return
        end
        return Core.sendNotification('Fordonet är låst', 'Context', 'error')
    end

    if GetVehicleDoorLockStatus(entity) == 1 then
        options[#options+1] = {
            label = 'Dörrar',
            sub = {
                {
                    label = 'Främre förardörr',
                    id = 0,
                    callback = setDoorState
                },
                {
                    label = 'Främre passagerardörr',
                    id = 1,
                    callback = setDoorState
                },
                {
                    label = 'Bakre förardörr',
                    id = 2,
                    callback = setDoorState
                },
                {
                    label = 'Bakre passagerardörr',
                    id = 3,
                    callback = setDoorState
                },
                {
                    label = 'Motorhuv',
                    id = 4,
                    callback = setDoorState
                },
                {
                    label = 'Bakluka',
                    id = 5,
                    callback = setDoorState
                }
            }
        }

        options[#options+1] = {
            label = 'Öppna baklukan',
            callback = function (entity, item, update, close)
                close()

                if GetVehicleDoorLockStatus(entity) == 2 then
                    Core.sendNotification('Fordonet är låst', 'Contextmenyn', 'error')
                    return
                end

                if DoesEntityExist(entity) and (#(GetOffsetFromEntityInWorldCoords(entity, 0.0, -2.0, 0.0) - GetEntityCoords(PlayerPedId())) < 2.0) then
                    SetVehicleDoorOpen(entity, 5, false, true)
                    local plate = trim(GetVehicleNumberPlateText(entity))
                    local storageId = ('baklucka-%s'):format(plate)
                    exports.inventory:openContainer(
                        storageId,
                        plate,
                        12,
                        nil, nil,
                        'stash'
                    )
                else
                    Core.sendNotification('Ställ dig bakom fordonet', 'Contextmenyn', 'error')
                end
            end
        }
    end

    open(entity, {
        label = GetVehicleNumberPlateText(entity),
        onClose = function (entity)
        end
    }, options)
end