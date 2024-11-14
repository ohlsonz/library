if IsDuplicityVersion() then return end

_G.NetScene = {}
_G.NetScene.__index = _G.NetScene

import('client.anim')

--- @type string
local resourceName = GetCurrentResourceName()

--- @class (exact) NetScene: NetSceneOptions
--- @field public new async fun(options: NetSceneOptions): NetScene; Creates a networked synchronized scene.
--- @field public handle integer;
--- @field private eventHandler EventHandler;

--- @class (exact) NetSceneOptions
--- @field public location vector3; The location, this field is required.
--- @field public rotation? vector3; The rotation of the scene. Default is vector3(0.0, 0.0, 0.0)
--- @field public rotationOrder? integer; Rotation order. Default is 2.
--- @field public holdLastFrame? boolean; If true, the scene stays on the last frame once it finishes, making GetSynchronizedScenePhase keep returning 1.0. Script is expected to clean up it's memory and stop the animation if this is passed as true and the phase reaches 1.0. Default is false.
--- @field public looped? boolean; If true, the scene will be looped and holdLastFrame will be disregarded. Default is false.
--- @field public phaseToStopScene? number; Which phase (from 0.0 to 1.0 to stop the scene. Default is 1.0).
--- @field public phaseToStartScene? number; Which phase (from 0.0 to 1.0 to start the scene. Default is 0.0).
--- @field public animSpeed? number; Speed of the animation. Default is 1.0.

--- Creates a networked synchronized scene.
--- @async
--- @public
--- @param options NetSceneOptions; The options for the scene.
--- @return NetScene; The NetScene class.
function _G.NetScene:new(options)
    assert(type(options) == "table", ("options must be of type table. Got %s"):format(type(options)))
    assert(type(options.location) == "vector3", ("location must be of type vector3. Got %s"):format(type(options.location)))

    --- @type NetScene
    self = setmetatable({
        --- @param rn string
        eventHandler = AddEventHandler("onResourceStop", function(rn)
            if rn ~= resourceName then return end

            --- destrory
        end)
    }, _G.NetScene)

    --- @type vector3
    self.location = options.location

    --- @type vector3
    self.rotation = type(options.rotation) == "vector3" and options.rotation or vector3(0.0, 0.0, 0.0)

    --- @type integer
    self.rotationOrder = type(options.rotationOrder) == "number" and options.rotationOrder or 2

    --- @type boolean
    self.holdLastFrame = type(options.holdLastFrame) == "boolean" and (options.holdLastFrame and true or false) or false

    --- @type boolean
    self.looped = type(options.looped) == "boolean" and (options.looped and true or false) or false

    --- @type number
    self.phaseToStopScene = type(options.phaseToStopScene) == "number" and (options.phaseToStopScene >= 0.0 and options.phaseToStopScene <= 1.0) and options.phaseToStopScene or 1.0

    --- @type number
    self.phaseToStartScene = type(options.phaseToStartScene) == "number" and (options.phaseToStartScene >= 0.0 and options.phaseToStartScene <= 1.0) and options.phaseToStartScene or 0.0

    --- @type number
    self.animSpeed = type(options.animSpeed) == "number" and options.animSpeed or 1.0

    

    --- @type NetScene
    return NetScene
end