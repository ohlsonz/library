if IsDuplicityVersion() then return end

_G.NetScene = {}
_G.NetScene.__index = _G.NetScene

--- @type string
local resourceName = GetCurrentResourceName()

--- @class (exact) NetSceneEntity
--- @field public handle integer; Entity handle to add to the scene.
--- @field public animDict string; Animation dictionary to play on this entity.
--- @field public animName string; Animation name from the dictionary to play on this entity.
--- @field public blendIn? number; Blend in speed of the animation. Default is 8.0.
--- @field public blendOut? number; Blend out speed of the animation. Default is -8.0.
--- @field public flag? NetSceneFlags; Default is 1.

--- @class (exact) NetScenePed
--- @field public handle integer; Ped handle to add to the scene.
--- @field public animDict string; Animation dictionary to play on this ped.
--- @field public animName string; Animation name from the dictionary to play on this ped.
--- @field public blendInSpeed? number; Blend in speed. The lower the value, the slower the blend in speed is. Default is 8.0.
--- @field public blendOutSpeed? number; Blend out speed. This should be the negative value of blendInSpeed. Default is -8.0.
--- @field public syncedSceneFlags? NetSceneFlags; Synchronized scene flags bit field from the above table.
--- @field public ragdollFlags? integer; Ragdoll blocking flags. Default is 0.
--- @field public moverBlendInDelta? number; Determines the rate at which the mover blends in to the scene. Useful for ensuring a seamless entry onto a synchronized scene. Default is 1000.0.
--- @field public ikFlags? NetSceneFlags; Inverse kinematics flags. Default is 0.

--- @class (exact) NetScene: NetSceneOptions
--- @field public new fun(options: NetSceneOptions): NetScene; Creates a networked synchronized scene.
--- @field public handle integer; The handle for the scene.
--- @field public addEntity async fun(self: self, entity: NetSceneEntity); Adds a entity to the synchronized scene.
--- @field public addPed async fun(self: self, ped: NetScenePed); Adds a ped to the synchronized scene.
--- @field public destroy fun(self: self); Destroys the scene.
--- @field public localHandle integer; The local handle for the scene. (NetworkGetLocalSceneFromNetworkId)
--- @field private loadedAnimations string[]; All the loaded animations. Used for cleanup when the scene is destroyed.
--- @field public addedPeds NetScenePed[]; All the peds you have added to the scene.
--- @field public addedEntities NetSceneEntity[]; All the entities tou have added to the scene.
--- @field private eventHandler EventHandler; Creating a event handler that destroys the scene if the invoking resource is stopped.

--- @class (exact) NetSceneOptions
--- @field public location vector3; The location, this field is required.
--- @field public rotation? vector3; The rotation of the scene. Default is vector3(0.0, 0.0, 0.0)
--- @field public rotationOrder? integer; Rotation order. Default is 2.
--- @field public holdLastFrame? boolean; If true, the scene stays on the last frame once it finishes, making GetSynchronizedScenePhase keep returning 1.0. Script is expected to clean up it's memory and stop the animation if this is passed as true and the phase reaches 1.0. Default is false.
--- @field public looped? boolean; If true, the scene will be looped and holdLastFrame will be disregarded. Default is false.
--- @field public phaseToStopScene? number; Which phase (from 0.0 to 1.0 to stop the scene. Default is 1.0).
--- @field public phaseToStartScene? number; Which phase (from 0.0 to 1.0 to start the scene. Default is 0.0).
--- @field public animSpeed? number; Speed of the animation. Default is 1.0.
--- @field public entities? NetSceneEntity[]; Entities to add.
--- @field public peds? NetScenePed[]; Peds to add.

--- @alias NetSceneFlags integer
---| 0 - (NONE) No flag set.
---| 1 - (USE_PHYSICS) Allows the ped to have physics during the scene.
---| 2 - (TAG_SYNC_OUT) The task will do a tag synchronized blend out with the movement behavior of the ped.
---| 4 - (DONT_INTERRUPT) The scene will not be interrupted by external events.
---| 8 - (ON_ABORT_STOP_SCENE) The scene will be stopped if the scripted task is aborted.
---| 16 - (ABORT_ON_WEAPON_DAMAGE) The scene will be stopped if the ped is damaged by a weapon.
---| 32 - (BLOCK_MOVER_UPDATE) The task will not update the mover.
---| 64 - (LOOP_WITHIN_SCENE) Animations within this scene will be looped until the scene is finished.
---| 128 - (PRESERVE_VELOCITY) The task will keep its velocity when the scene is cleaned up/stopped. Note: the USE_PHYSICS flag must also be present.
---| 256 - (EXPAND_PED_CAPSULE_FROM_SKELETON) The task will apply the ExpandPedCapsuleFromSkeleton reset flag to the ped (see SET_PED_RESET_FLAG).
---| 512 - (ACTIVATE_RAGDOLL_ON_COLLISION) The ped will ragdoll if it comes into contact with an object.
---| 1024 - (HIDE_WEAPON) The peds current weapon will be hidden during the scene.
---| 2048 - (ABORT_ON_DEATH) The synchronized scene will be aborted if the ped dies.
---| 4096 - (VEHICLE_ABORT_ON_LARGE_IMPACT) If the scene is running on a vehicle, it will be aborted if the vehicle takes a heavy collision with another vehicle.
---| 8192 - (VEHICLE_ALLOW_PLAYER_ENTRY) If the scene is on a vehicle, it allows players to enter it.
---| 16384 - (PROCESS_ATTACHMENTS_ON_START) Attachments will be processed at the start of the scene.
---| 32768 - (NET_ON_EARLY_NON_PED_STOP_RETURN_TO_START) A non-ped entity will be returned to its starting position if the scene finishes early.
---| 65536 - (SET_PED_OUT_OF_VEHICLE_AT_START) If the ped is in a vehicle when the scene starts, it will be set out of the vehicle.
---| 131072 - (NET_DISREGARD_ATTACHMENT_CHECKS) Attachment checks will be disregarded when the scene is running.

--- Creates a networked synchronized scene.
--- @public
--- @param options NetSceneOptions; The options for the scene.
--- @return NetScene; The NetScene class.
function _G.NetScene:new(options)
    assert(type(options) == "table", ("options must be of type table. Got %s"):format(type(options)))
    assert(type(options.location) == "vector3", ("location must be of type vector3. Got %s"):format(type(options.location)))

    --- @type NetScene
    self = setmetatable({
        --- @param rn string
        --- @type EventHandler
        eventHandler = AddEventHandler("onResourceStop", function(rn)
            if rn ~= resourceName then return end

            self:destroy()
        end),

        --- @type string[]
        loadedAnimations = {}
    }, _G.NetScene)

    --- @type NetSceneEntity[]
    self.addedEntities = {}

    --- @type NetScenePed[]
    self.addedPeds = {}

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

    --- @type integer
    self.handle = NetworkCreateSynchronisedScene(
        self.location.x, self.location.y, self.location.z,
        self.rotation.x, self.rotation.y, self.rotation.z,
        self.rotationOrder,
        self.holdLastFrame,
        self.looped,
        self.phaseToStopScene,
        self.phaseToStartScene,
        self.animSpeed
    )

    self.localHandle = NetworkGetLocalSceneFromNetworkId(self.handle)

    if type(options.entities) == "table" and #options.entities >= 1 then
        for _, v in pairs(options.entities) do
            self:addEntity(v)
        end
    end

    --- @type NetScene
    return self
end

--- Adds a entity to the synchronized scene.
--- @public
--- @async
--- @param entity NetSceneEntity
function _G.NetScene:addEntity(entity)
    assert(type(entity) == "table", ("entity must be of type table. Got %s"):format(type(entity)))
    assert(type(entity.handle) == "number", ("handle must be of type number. Got %s"):format(type(entity.handle)))
    assert(DoesEntityExist(entity.handle), ("Failed to add entity %s to netscene (%s). The entity does not exist."):format(entity.handle, self.handle))
    assert(type(entity.animDict) == "string", ("animDict must be of type string. Got %s"):format(type(entity.animDict)))
    assert(DoesAnimDictExist(entity.animDict), ("Failed to add entity %s to netscene (%s). The animation dict (%s) does not exist."):format(entity.handle, entity.animDict, self.handle))
    assert(type(entity.animName) == "string", ("animName must be of type string. Got %s"):format(type(entity.animName)))

    if not HasAnimDictLoaded(entity.animDict) then
        RequestAnimDict(entity.animDict)

        --- @type promise
        local promise = promise.new()

        Citizen.CreateThread(function()
            while not HasAnimDictLoaded(entity.animDict) do
                Citizen.Wait(50)
            end

            promise:resolve()
        end)

        Citizen.Await(promise)

        table.insert(self.loadedAnimations, entity.animDict)
    end

    --- @type number
    local blendIn = type(entity.blendIn) == "number" and entity.blendIn or 8.0

    --- @type number
    local blendOut = type(entity.blendOut) == "number" and entity.blendOut or -8.0

    --- @type integer
    local flag = type(entity.flag) == "number" and entity.flag or 1

    NetworkAddEntityToSynchronisedScene(entity.handle, self.handle, entity.animDict, entity.animName, blendIn, blendOut, flag)

    table.insert(self.addedEntities, {
        handle = entity.handle,
        animDict = entity.animDict,
        animName = entity.animName,
        blendIn = blendIn,
        blendOut = blendOut,
        flag = flag
    })
end

--- Adds a ped to the synchronized scene.
--- @public
--- @async
--- @param ped NetScenePed
function _G.NetScene:addPed(ped)
    assert(type(ped) == "table", ("ped must be of type table. Got %s"):format(type(ped)))

    assert(type(ped.handle) == "number", ("handle must be of type number. Got %s"):format(type(ped.handle)))
    assert(DoesEntityExist(ped.handle), ("Failed to add entity %s to netscene (%s). The entity does not exist."):format(ped.handle, self.handle))
    assert(IsEntityAPed(ped.handle), ("Failed to add entity %s to netscene (%s). The entity is not a ped."):format(ped.handle, self.handle))

    assert(type(ped.animDict) == "string", ("animDict must be of type string. Got %s"):format(type(ped.animDict)))
    assert(DoesAnimDictExist(ped.animDict), ("Failed to add entity %s to netscene (%s). The animation dict (%s) does not exist."):format(ped.handle, ped.animDict, self.handle))
    assert(type(ped.animName) == "string", ("animName must be of type string. Got %s"):format(type(ped.animName)))

    if not HasAnimDictLoaded(ped.animDict) then
        RequestAnimDict(ped.animDict)

        --- @type promise
        local promise = promise.new()

        Citizen.CreateThread(function()
            while not HasAnimDictLoaded(ped.animDict) do
                Citizen.Wait(50)
            end

            promise:resolve()
        end)

        Citizen.Await(promise)

        table.insert(self.loadedAnimations, ped.animDict)
    end

    --- @type number
    local blendInSpeed = type(ped.blendInSpeed) == "number" and ped.blendInSpeed or 8.0

    --- @type number
    local blendOutSpeed = type(ped.blendOutSpeed) == "number" and ped.blendOutSpeed or -8.0

    --- @type NetSceneFlags
    local syncedSceneFlags = type(ped.syncedSceneFlags) == "number" and ped.syncedSceneFlags or 1

    --- @type number
    local ragdollFlags = type(ped.ragdollFlags) == "number" and ped.ragdollFlags or 0

    --- @type number
    local moverBlendInDelta = type(ped.moverBlendInDelta) == "number" and ped.moverBlendInDelta or 1000.0

    --- @type number
    local ikFlags = type(ped.ikFlags) == "number" and ped.ikFlags or 0

    NetworkAddPedToSynchronisedScene(ped.handle, self.handle, ped.animDict, ped.animName, blendInSpeed, blendOutSpeed, syncedSceneFlags, ragdollFlags, moverBlendInDelta, ikFlags)

    table.insert(self.addedPeds, {
        handle = ped.handle,
        animDict = ped.animDict,
        animName = ped.animName,
        blendInSpeed = blendInSpeed,
        blendOutSpeed = blendOutSpeed,
        syncedSceneFlags = syncedSceneFlags,
        ragdollFlags = ragdollFlags,
        moverBlendInDelta = moverBlendInDelta,
        ikFlags = ikFlags
    })
end

--- @public
function _G.NetScene:destroy()
    NetworkStopSynchronisedScene(self.handle)
    TakeOwnershipOfSynchronizedScene(self.localHandle)

    if type(self.loadedAnimations) == "table" and #self.loadedAnimations >= 1 then
        for k, v in pairs(self.loadedAnimations) do
            if HasAnimDictLoaded(v) then
                RemoveAnimDict(v)
            end

            table.remove(self.loadedAnimations, k)
        end
    end

    self.addedEntities = {}
    self.addedPeds = {}
end