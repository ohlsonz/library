if not _VERSION:find("5.4") then
    error("Lua 5.4 must be enabled in the resource manifest!", 2)
end

--- Imports a module from the library.
--- @param module string: The module you wish to import.
function _G.import(module)
    assert(type(module) == "string", ("Module needs to be of type string. Got %s"):format(type(module)))

    local path = module:lower():gsub("%.", "/")

    --- @type string
    local importedModule = LoadResourceFile("library", ("%s.lua"):format(path))

    assert(type(importedModule) == "string", ("Error importing module: %s"):format(module))

    local fn, err = load(importedModule, path, "t", _ENV)

    if not fn or err then
        return error(("Error importing module (%s): %s^0"):format(path, err), 3)
    end

    fn()
end