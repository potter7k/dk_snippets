CreateThread(function()
    Wait(2000)
    local players = GetPlayers()

    local targetSource = nil
    if not targetSource then
        for _, playerSrc in ipairs(players) do
            local src = tonumber(playerSrc)
            if not targetSource or type(src) == "number" and src > 0 and src < targetSource then
                targetSource = tonumber(src)
            end
        end
    end

    DkNotify(targetSource, NotifyModes.GREEN, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.", 4000)
    DkNotify(targetSource, NotifyModes.RED, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.", 4000)
    DkNotify(targetSource, NotifyModes.YELLOW, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.", 4000)
    DkNotify(targetSource, NotifyModes.BLUE, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.", 4000)

    DkHint(targetSource, "create", "dk_snippets:client:test", "Aperte para não fazer nada", "E", {})
    DkHint(targetSource, "create", "dk_snippets:client:test2", "Informação importante (ignore)", nil, {
        infoIcon = true,
    })

    local request = DkRequest(targetSource, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.", 10)
    print(request)

    DkHint(targetSource, "remove", "dk_snippets:client:test")
    DkHint(targetSource, "remove", "dk_snippets:client:test2")
end)
