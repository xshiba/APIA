local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatUtils = require(ReplicatedStorage.Modules.CombatUtil)
local CachedAim = {}
local AimIndex, CurrentWeapon = 1, ""
local Net = require(ReplicatedStorage.Modules.Net)
local RegisterHitEvent = Net:RemoteEvent("RegisterHit", true)
local CombatMode = "NORMAL" -- NORMAL or SPAM
local gameFlags = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Flags"));
local RegisterHitRemoteThread = nil 


function getWeaponName(Instnace) 
    local Humanoid = game.Players.LocalPlayer.Character.Humanoid
    if not Humanoid then return end 
    local Tool = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if Tool then
        if Instnace then
            return Tool
        end
        if Tool:GetAttribute("WeaponName") then
            return Tool:GetAttribute("WeaponName")
        end 
        return Tool.Name
    end
    return nil 
end

function getWeapon() 
    local Humanoid = game.Players.LocalPlayer.Character.Humanoid
    if not Humanoid then return end 
    local Tool = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if Tool then
        return Tool
    end
    return nil 
end


function getCacheAim(k) 
    if CurrentWeapon ~= k then
        AimIndex = 1
    end
    if CachedAim[k .. tostring(AimIndex)] == nil then
        AimIndex = 1 
        if CachedAim[k .. tostring(AimIndex)] then return CachedAim[k .. tostring(AimIndex)] end
        local GetMovesetAnimCache = CombatUtils:GetMovesetAnimCache(game.Players.LocalPlayer.Character.Humanoid)
        local WeaponName = getWeaponName()
        if not GetMovesetAnimCache then return end
        if not WeaponName then return end
        for i, AnimCache in pairs(GetMovesetAnimCache) do 
            local registerBlade = AnimCache.Length / (AnimCache:GetAttribute("SpeedMult") or 1)
            CachedAim[i] = registerBlade
        end
    end
    AimIndex = AimIndex + 1
    return CachedAim[k .. tostring(AimIndex)]
end

function getRegisterBladeHit() 
    local WeaponName = getWeaponName()
    if not WeaponName then 
        return nil
    end
    return getCacheAim(CombatUtils:GetPureWeaponName(WeaponName) .. "-basic")
end
function getAllBladeHits(Sizes)
    local Hits = {}
    local Client = game.Players.LocalPlayer
    local Enemies = game:GetService("Workspace").Enemies:GetChildren()
    for i=1,#Enemies do local v = Enemies[i]
        local Human = v:FindFirstChildOfClass("Humanoid")
        if Human and Human.RootPart and Human.Health > 0 and Client:DistanceFromCharacter(Human.RootPart.Position) < Sizes+5 and (Human.RootPart.Position - Client.Character.HumanoidRootPart.Position).Magnitude <= 300  then
            table.insert(Hits,Human.RootPart)
        end
    end    
    if #Hits > 0  then
        local FirstHit = Hits[1]
        local MulitHit = {}
        if #Hits > 1 and CombatMode == "SPAM" then
            for i = 2, #Hits do
                local Hit = Hits[i]
                table.insert(MulitHit, {
                    Hit.Parent,
                    Hit
                })
            end
        end
        local SpamHit = {}
        for i = 1, 5 do 
            for i, v in pairs(MulitHit) do
                table.insert(SpamHit, v)
            end
        end
        return FirstHit, SpamHit
    end
    return nil, {}
end

function getAllBladeHitsPlayers(Sizes)
    local Hits = {}
    local Client = game.Players.LocalPlayer
    local Characters = game:GetService("Workspace").Characters:GetChildren()
    for i=1,#Characters do local v = Characters[i]
        local Human = v:FindFirstChildOfClass("Humanoid")
        if v.Name ~= game.Players.LocalPlayer.Name and Human and Human.RootPart and Human.Health > 0 and Client:DistanceFromCharacter(Human.RootPart.Position) < Sizes+5 then
            table.insert(Hits,Human.RootPart)
        end
    end	    
    if #Hits > 0 then
        local FirstHit = Hits[1]
        local MulitHit = {}
        if #Hits > 1 and CombatMode == "SPAM" then
            for i = 2, #Hits do
                local Hit = Hits[i]
                table.insert(MulitHit, {
                    Hit.Parent,
                    Hit
                })
            end
        end
        return FirstHit, MulitHit
    end
    return nil, {}
end

function AttackFunction()
    local bladehit, mulithit = getAllBladeHits(120)
    local WeaponName = getWeaponName(true)
    if bladehit and WeaponName then 
        local registerBlade = getRegisterBladeHit()
        if registerBlade then 
            game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/RegisterAttack"):FireServer(registerBlade)
            if gameFlags.COMBAT_REMOTE_THREAD and RegisterHitRemoteThread then 
                coroutine.resume(RegisterHitRemoteThread, bladehit, mulithit);
            else 
                RegisterHitEvent:FireServer(bladehit, mulithit)
            end
        end
    end
end

while true do wait(.5)
    AttackFunction()
end
