Core = exports.core:load()
Heap = {
    targets = {
        -- [cache.ped] = {
        --     dist = 10.0,
        --     callback = function (entity, dist)
        --         print('Karaktär')
        --     end
        -- }
    },
    active = false,
    open = false,
    current = nil,
    callbacks = {},
    nui = {},
    target = nil
}

CreateThread(function ()
    while true do
        if Heap.doClose then
            Wait(150)
        end

        if not LocalPlayer.state.isDead then
            if IsControlPressed(1, 19) and not Heap.active then
                Heap.active = true
                hoverLoop()
            elseif not IsControlPressed(1, 19) and Heap.active then
                Heap.active = false
            end
        end

        Wait(0)
    end
end)

RegisterNUICallback('click', function (data, cb)
    local index <const> = data.index
    local subIndex <const> = data.sub
    local callbackId <const> = data.sub and tostring(index)..':'..tostring(subIndex) or tostring(index)
    local callback = Heap.callbacks[callbackId]

    if not callback then
        lib.print.error('No callback with id: '..callbackId)
        return cb(true)
    end

    local itemData = data.sub and Heap.nui[index].sub[subIndex] or Heap.nui[index]
    executeCallback(callback, Heap.target, itemData, function (newData)
        if Heap.open then
            if subIndex then
                for i, _data in pairs (newData) do
                    Heap.nui[index].sub[subIndex][i] = _data
                end
            else
                for i, _data in pairs (newData) do
                    Heap.nui[index][i] = _data
                end
            end

            update({
                options = Heap.nui
            })
        end
    end, close)
    cb(true)
end)