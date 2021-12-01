function map(table, f)
    local result = {}
    for i,v in pairs(table) do
        result[i] = f(v)
    end
    return result
end
-- convert a Lua array to a WML tag: {'a', 'b'} to {{value='a'}, {value='b'}}
function arrayToTag(arr)
    return map(arr, function(el) return {value=el} end)
end
-- Convert a WML tag to a Lua array
function tagToArray(table)
    return map(table, function(el) return el.value end)
end

-- return the side ID of the unit at (x,y). If x and y are not given, use WML variables x1 and y1
function getSideAt(x,y)
    local x,y = 
        x or wml.variables["x1"], 
        y or wml.variables["y1"]
    local unit = wesnoth.units.get(x, y)
    if unit == nil then
        return nil
    end
    return unit.side
end
-- return whether the given side has an enemy at WML's x1 and y1
function hasEnemyHere(side)
    local other_side = getSideAt()
    if other_side == nil then
        return nil
    end
    return side ~= other_side and wesnoth.sides.is_enemy(side, other_side)
end
-- return whether the given side has an ally at WML's x1 and y1
function hasAllyHere(side)
    local other_side = getSideAt()
    if other_side == nil then
        return nil
    end
    return side ~= other_side and not wesnoth.sides.is_enemy(side, other_side)
end

function printArr(array)
    local str = ""
    for i, v in pairs(array) do
        str = str .. " " .. tostring(v)
    end
    return str
end
-- arrays are damn weird in WML, so we have to make sure we convert them first
-- this is ONLY with arrays; it will have to have elements from 1 to X.
function storeArrayWML(wmlName, array)
    print("storing " .. printArr(array))
    wml.array_access.set(wmlName, arrayToTag(array))
end

function wmlArrayAddress(arrName, index)
    return string.format("%s[%d].value", arrName, index - 1)
end

-- A homerolled and limited kin to wml.array_access.get_proxy. While this won't reflect changes within its elements in WML, it WILL reflect element addition/removal
-- So don't do `mirror["haha"].property = "foo"`, but mirror["haha"] = modifiedWithFoo works.
-- Works best with arrays of primitives, used to track the list of realTeams and disguiseTeams properly
function shallowWMLArrayMirror(wmlName)
    local innerdata = tagToArray(wml.array_access.get(wmlName))
    local mirrortable = {}

    local result = setmetatable(mirrortable, {
        -- the inner array that gets written to with every index. Means that __newindex ALWAYS fires on mirrortable, even if its already present in innerdata
        innerdata = innerdata,
        wmlName = wmlName,

        -- Will always fire as it sets in innerdata. When doing mirror[x] = thing, update in WML
        __newindex = function(outertable, key, value)
            innerdata[key] = value
            wml.variables[wmlArrayAddress(wmlName, key)] = value
        end,

        __index = function(outertable, key)
            local wmlVal = wml.variables[wmlArrayAddress(wmlName, key)]
            -- If WML has a different value, it's almost definitely been set elsewhere; respect that if possible
            if wmlVal ~= innerdata[key] then
                innerdata[key] = wmlVal
            end
            return wmlVal
        end,

        __ipairs = function(table)
            return ipairs(innerdata)
        end,

        __pairs = function(table)
            return pairs(innerdata)
        end
    })
    return result
end