function map(table, f)
    local result = {}
    for i,v in ipairs(table) do
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
    return unit.side
end
-- return whether the given side has an enemy at WML's x1 and y1
function hasEnemyHere(side)
    local other_side = getSideAt()
    return side ~= other_side and wesnoth.sides.is_enemy(side, other_side)
end
-- return whether the given side has an ally at WML's x1 and y1
function hasAllyHere(side)
    local other_side = getSideAt()
    return side ~= other_side and not wesnoth.sides.is_enemy(side, other_side)
end