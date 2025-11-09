Common = {
    coords = {
        [vec3(-88.167030334473, 142.20660400391, 81.126708984375)] = function (entity, dist)
            print('123')
        end
    },
    models = {
        [joaat('prop_dumpster_01a')] = function (entity, dist, close)
            close()
            exports.tasks:searchDumpster(entity)
        end,

        [joaat('prop_bench_03')] = function (entity, dist)
        end,

        [joaat('prop_atm_01')] = function (entity, dist, close)
            close()
            exports.bankz:openAtm(entity)
        end,

        [joaat('prop_atm_02')] = function (entity, dist, close)
            close()
            exports.bankz:openAtm(entity)
        end
    }
}