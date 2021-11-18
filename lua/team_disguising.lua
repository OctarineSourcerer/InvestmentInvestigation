-- Handle viewing sides as on a specific "team" on the player's turn.
-- Each side may have a "disguise" team, and after the players turn will revert to its real team 

realTeams = wml.array_access.get_proxy("realTeams")
sideDisguises = wml.array_access.get_proxy("sideDisguises")

-- set teams according to teamsTable: {[sideID] = "teamName"}
function setTeams(teamsTable)
    for id,teamName in pairs(teamsTable) do
        wesnoth.sides.get(id).team_name = teamName
    end
end
-- store each side's current team in realTeams
function storeRealTeams()
    local teamsCache = {}
    local sides = wesnoth.sides.find{}
    for id,side in pairs(sides) do
        teamsCache[id] = side.team_name
    end
    realTeams = teamsCache
    wml.array_variables["realTeams"] = arrayToTag(realTeams)
end

-- temporarily switch sides from real teams to their player-chosen disguises. Used at the beginning of player's turn
function disguiseTeams()
    storeRealTeams()
    setTeams(sideDisguises)
    showingRealTeams = false
end

-- If a side's name has changed since we masked it, we keep that changed name as real
function preserveRealTeamChange(sideID)
    if showingRealTeams then
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
    showingRealTeams = true
end
-- When player clears whether they consider a team as ally or enemy
function clearSideDisguise(sideID)
    sideDisguise = sideDisguises[sideID]
    if showingRealTeams or sideDisguise == nil then
        return
    end
    preserveRealTeamChange(sideID)
    setTeams({[sideID] = realTeams[sideID]})
    sideDisguises[sideID] = nil
end
function changeSideDisguise(sideID, newDisguise, applyNow)
    if applyNow then
        preserveRealTeamChange(sideID)
        wesnoth.sides.get(sideID).team_name = newShownTeam
    end
    sideDisguises[sideID] = newDisguise
end
function sideHasDisguise(side)
    sideID = side or getSideAt()
    return sideDisguises[sideID] ~= nil
end

-- Store what the current teams are while showing a different allegiance, if applicable
-- Hmm. This will break if they
realTeams = nil
-- What team names are set at the beginning of a player's turn. eg {2="ENEMY", 3="Indrith"}
sideDisguises = {}
showingRealTeams = true