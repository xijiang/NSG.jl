# The color plan below is better in terminal dark mode
# To use these print funcitons:
# using ABG: title, message, warning, item, done
"""
Print a title.
"""
function title(msg::AbstractString)
    printstyled('\n', msg, '\n', bold = true, color = :cyan)
    printstyled(repeat('=', length(msg) + 2), '\n', color=31)
end

"""
Print a subtitle.
"""
function subtitle(msg::AbstractString)
    printstyled('\n', msg, '\n', color = :cyan)
    printstyled(repeat('-', length(msg) + 2), '\n', color=31)
end

"""
Print a message.
"""
function message(msg::AbstractString)
    printstyled('\n', msg, '\n'; color = :light_magenta)
end

"""
Print a warning.
"""
function warning(msg::AbstractString)
    printstyled('\n', msg, '\n'; color=229)
end

"""
Print an item.
"""
function item(it::AbstractString)
    printstyled("\n- $it\n"; color=74)
end

"""
Print a `Done` message.
"""
function done(msg::AbstractString = "Done")
    printstyled(" ... $msg\n"; color=40)
end

function test_my_styled_printing()
    for i in 1:256
        printstyled(' ', lpad("$i", 3, '0'), ' ', color=i)
        (i % 16 == 0) && println()
    end
    println()

    title("This is a title using bold, color cyan and 154")
    subtitle("This is a subtitle using color cyan and 154")
    item("Item 1 using color 74")
    item("Item 2")
    message("A description message using color :light_magenta")
    warning("This is a warning using color 229")
    println("An average messages using color default")
    done("Done.  Using color 40. OK")
end
