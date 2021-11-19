-- Handle viewing sides as on a specific "team" on the player's turn.
-- Each side may have a "disguise" team, and after the players turn will revert to its real team 
-- Bear in mind that `utils.lua` is loaded by the campaign, so consider that Required

-- Store what the current teams are while showing a different allegiance, if applicable
realTeams = shallowWMLArrayMirror("realTeams")
-- What team names are set at the beginning of a player's turn. eg {1="hah", 2="ENEMY", 3="Indrith"}
-- No disguise = same as realTeams name. 
sideDisguises = shallowWMLArrayMirror("sideDisguises")

if wml.variables["showingRealTeams"] == nil then
    wml.variables["showingRealTeams"] = true
end

-- -- initialise disguises to be a full array. 
-- if #getmetatable(sideDisguises).innerdata == 0 then
--     local sides = wesnoth.sides.find{}
--     for i, side in ipairs(sides) do
--         sideDisguises[i] = side.team_name
--     end
-- end

-- set teams according to teamsTable: {[sideID] = "teamName"}
function setTeams(teamsTable)
    for id,teamName in pairs(teamsTable) do
        wesnoth.sides.get(id).team_name = teamName
    end
end

-- store each side's current team in realTeams
function storeRealTeams()
    local sides = wesnoth.sides.find{}
    for id,side in pairs(sides) do
        -- We don't do this in a big batch-write atm, as it's just once per team
        -- and I've yet to make a WML arraymirror do a batch-write easily
        realTeams[id] = side.team_name
    end
end

-- temporarily switch sides from real teams to their player-chosen disguises. Used at the beginning of player's turn
function disguiseTeams()
    storeRealTeams()
    setTeams(sideDisguises)
    wml.variables["showingRealTeams"] = false
end

-- If a side's name has changed since we masked it, we keep that changed name as real
function preserveRealTeamChange(sideID)
    if wml.variables["showingRealTeams"] then
        return
    end
    local side = wesnoth.sides.get(sideID)
    local disguiseTeam = sideDisguises[sideID]
    -- Team has been changed from shown during the turn
    if disguiseTeam ~= nil and side.team_name ~= disguiseTeam then
        realTeams[sideID] = side.team_name
    end
end
function resetTeamsToReal()
    -- If we were showing non-real teams, then check for if team was changed again during turn. If so, respect that change
    for id,team in pairs(sideDisguises) do
        preserveRealTeamChange(id)
    end
    setTeams(realTeams)
    wml.variables["showingRealTeams"] = true
end
-- When player clears whether they consider a team as ally or enemy
function clearSideDisguise(sideID)
    local sideDisguise = sideDisguises[sideID]
    if wml.variables["showingRealTeams"] or ~sideHasDisguise(sideID) then
        return
    end
    preserveRealTeamChange(sideID)
    setTeams({[sideID] = realTeams[sideID]})
    sideDisguises[sideID] = realTeams[sideID]
end
function applyNewDisguise(sideID, newDisguise, applyNow)
    if applyNow then
        preserveRealTeamChange(sideID)
        wesnoth.sides.get(sideID).team_name = newDisguise
    end
    sideDisguises[sideID] = newDisguise
end
function sideHasDisguise(side)
    sideID = side or getSideAt()
    return sideDisguises[sideID] ~= realTeams[sideID]
end