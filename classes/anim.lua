if IsDuplicityVersion() then return end

Anim = {}
Anim.__index = Anim

function Anim:load(dict)
    if not dict or type(dict) ~= 'string' then return end

    if not DoesAnimDictExist(dict) then return end
    if HasAnimDictLoaded(dict) then return end

    self.dict = dict:upper()

    local resourceName = GetCurrentResourceName()

    self.eventHandler = AddEventHandler('onResourceStop', function(resource)
        if (resourceName == resource) then
            self:unload()
        end
    end)

    RequestAnimDict(self.dict)

    while not HasAnimDictLoaded(self.dict) do
        Citizen.Wait(100)
    end
end

function Anim:unload()
    if self.eventHandler then
        RemoveEventHandler(self.eventHandler)
    end

    if self.dict and HasAnimDictLoaded(self.dict) then
        RemoveAnimDict(self.dict)
    end
end