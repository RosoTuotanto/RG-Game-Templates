-- luacheck: no global (suppress warnings from this file)

-- Line length
max_line_length = 160

-- Use Lua 5.1 as base (Solar2D uses 5.1)
std = "lua51"

-- Solar2D globals (writable - allows overwriting for wrappers):
globals = {
    -- Solar2D core & internals:
    "audio",
    "display",
    "easing",
    "graphics",
    "media",
    "native",
    "network",
    "physics",
    "Runtime",
    "system",
    "timer",
    "transition",
    "metatable",

    -- project/framework specific custom globals:
    "utils",

    -- Solar2D's own table.copy, which libs/utils.lua replaces with a deep copy:
    table = { fields = { "copy" } },
}

-- Ignore unused arguments with specific names:
-- 212 = unused argument
ignore = {
    "212/self",
    "212/event",
    "212/_",
    "212/_*",
}

-- Exclude vendored third-party library (23 pre-existing warnings it cannot suppress inline).
-- Patterns resolve relative to this config: the source tree, plus the built tree in dst/.
exclude_files = {
    "src/core/game/libs/spyricStoryWeaver.lua",
    "dst/*/game/libs/spyricStoryWeaver.lua",
}

