if not tlbe then
    tlbe = {}
end

function tlbe.log(message)
    if game then
        for i, p in pairs(game.players) do
            p.print(message)
        end
    end
end
