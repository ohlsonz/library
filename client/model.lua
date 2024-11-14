if IsDuplicityVersion() then return end

_G.Model = {}
_G.Model.__index = _G.Model

--- @type string
local resourceName = GetCurrentResourceName()

--- @class (exact) Model; The model class.
--- @field public request async fun(model: string | integer); Loads the model to the clients memory.
--- @field public hash integer; The model hash.
--- @field public unload fun(self: self); Unloads the model from the clients memory. By default this function gets triggerd if the invoking resource is stopped.
--- @field public dimensions { min: vector2, max: vector2 }; The dimensions of the loaded model.
--- @field private eventHandler EventHandler; Creating a event handler for unloading the model if the invoking resource is stopped.

--- Loads the model into the clients memory.
--- @param model string | integer; The model you wish to load into memory.
--- @return Model; The model class.
--- @async
--- @public
function _G.Model:request(model)
    assert(type(model) == "number" or type(model) == "string", ("Model must to be of type number or string. Got %s"):format(type(model)))

    --- @type string | integer
    local modelHash = type(model) == "string" and GetHashKey(model) or model

    --- @cast modelHash integer

    assert(IsModelValid(modelHash) and IsModelInCdimage(modelHash), ("%s does not exist, check for typos and gamebuild."):format(model))

    --- @type Model
    self = setmetatable({
        --- @param rn string
        eventHandler = AddEventHandler("onResourceStop", function(rn)
            if rn ~= resourceName then return end

            self:unload()
        end)
    }, _G.Model)

    self.hash = modelHash

    --- @type promise
    local promise = promise.new()

    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
    end

    if not HasCollisionForModelLoaded(modelHash) then
        RequestCollisionForModel(modelHash)
    end

    Citizen.CreateThread(function()
        while not HasModelLoaded(modelHash) or not HasCollisionForModelLoaded(modelHash) do
            Citizen.Wait(100)
        end

        --- @type vector2, vector2
        local min, max = GetModelDimensions(modelHash)

        self.dimensions = {
            min = min,
            max = max
        }

        promise:resolve()
    end)

    Citizen.Await(promise)

    --- @type Model
    return self
end

--- Unloads the model from the clients memory.
--- @public
function _G.Model:unload()
    if self.eventHandler then
        RemoveEventHandler(self.eventHandler)
    end

    if HasModelLoaded(self.hash) or HasCollisionForModelLoaded(self.hash) then
        SetModelAsNoLongerNeeded(self.hash)
    end
end