local Buffer = {}
Buffer.__index = Buffer

function Buffer:append(str)
    self.n = self.n + 1
    self[self.n] = str
end

function Buffer:appendf(...)
    self:append(string.format(...))
end

function Buffer:concat(sep)
    return table.concat(self, sep)
end

function Buffer.new()
    return setmetatable({n = 0}, Buffer)
end

local function IndentGenerator(indent)
    return setmetatable({[0] = "", [1] = indent or "    "}, {
        __index = function(self, i)
            self[i] = self[1]:rep(i)
            return self[i]
        end
    })
end

local function wrap(text, indent)
    local limit = 78
    local indent_width = #indent
    local pos = 1 - indent_width
    local str = text:gsub("(%s+)()(%S+)()", function(_, start, word, stop)
        if stop - pos > limit then
            pos = start - indent_width
            return "\n" .. indent .. word
        else
            return " " .. word
        end
    end)
    return indent .. str .. "\n"
end

return {
    Buffer = Buffer.new,
    IndentGenerator = IndentGenerator,
    wrap = wrap
}
