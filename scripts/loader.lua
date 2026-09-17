local Games = {
    ['rivals'] = { ID = 6035872082, State = true },
    ['ttk'] = { ID = 10090256806, State = true },
    ['silent-assassin'] = { ID = 9503696692, State = true },
}

local function detectGame()
    for name, info in pairs(Games) do
        if info.State and game.GameId == info.ID then
            return name, info
        end
    end

    return nil
end

local name = detectGame()

if name == "rivals" then
    loadstring(game:HttpGet("https://alacrity.eu.cc/scripts/rivals.lua"))()
elseif name == "ttk" then
    loadstring(game:HttpGet("https://alacrity.eu.cc/scripts/ttk.lua"))()
elseif name == "silent-assassin" then
    loadstring(game:HttpGet("https://alacrity.eu.cc/scripts/silent-assassin.lua"))()
elseif not name then
    local Notification = loadstring(
        game:HttpGet(
            "https://raw.githubusercontent.com/juywvm/ui-libs/main/unnamed_Notify_Library/NotifyLibrary",
            true
        )
    )()

    Notification.new(
        "error",
        "Alacrity",
        "This game is not supported. Please join a supported game.",
        3
    )
end
