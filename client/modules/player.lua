local self = {
    custom = {}
}

local function addSelf (data)
    self.custom[#self.custom+1] = data
    return true
end
exports('addSelf', addSelf)

local function removeSelf (data)
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
exports('removeSelf', removeSelf)

function openSelfMenu ()
    if not Core.isLoaded() then return end
    print('Karaktärs meny')

    local options = {
        {
            label = 'Animationer',
            callback = function (target, item, update, close)
                close()
                exports["ballesa-animationmenu"]:open()
            end
        }
    }

    for i, data in pairs (self.custom) do
        options[#options+1] = {
            label = data.label,
            sub = data.sub or nil,
            callback = data.callback
        }
    end

    print(json.encode(self.custom))

    open(cache.ped, {
        label = ('%s - ID: %s'):format(Core.getCharacter().firstname, GetPlayerServerId(PlayerId())),
        onClose = function (target)
        end
    }, options)
end

function openTargetMenu (entity)
    print('Target karaktärs meny')

end