local SCRIPT_URL = "https://raw.githubusercontent.com/HeavenlyScripts/HeavenlyRivals/refs/heads/main/Rivals.lua?token=GHSAT0AAAAAADORTUREGIT5WWWJJ2SL7GFE2MGCYQQ" --replace with ur repo

if queue_on_teleport then
    pcall(queue_on_teleport, [[
        task.wait(1) --delay so the script actually loads
        loadstring(game:HttpGet("]] .. SCRIPT_URL .. [[", true))()
    ]])
end

loadstring(game:HttpGet(SCRIPT_URL, true))()

if getgenv().___SCRIPT_ALREADY_LOADED then
    return
end
getgenv().___SCRIPT_ALREADY_LOADED = true

local itemLib = require(game:GetService("ReplicatedStorage").Modules.ItemLibrary)
local cosmeticLib = require(game:GetService("ReplicatedStorage").Modules.CosmeticLibrary)

-- Store equipped cosmetics for each weapon
local equippedCosmetics = {}

local function changeSkin(gunName, skinName, wrapName, charmName)
    if not gunName then return end
    
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    
    -- Store the cosmetics for this weapon
    equippedCosmetics[gunName] = {
        Skin = skinName,
        Wrap = wrapName,
        Charm = charmName
    }
    
    -- Hook into the viewmodel creation
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Modules = ReplicatedStorage:WaitForChild("Modules")
    
    -- Try to find and hook into the ClientItem module
    local success, ClientItem = pcall(function()
        return require(player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
    end)
    
    if success and ClientItem then
        -- Hook the _CreateViewModel function to apply our cosmetics
        if not ClientItem._CreateViewModel_Original then
            ClientItem._CreateViewModel_Original = ClientItem._CreateViewModel
        end
        
        ClientItem._CreateViewModel = function(self, vmRef)
            -- Call original function first
            local result = ClientItem._CreateViewModel_Original(self, vmRef)
            
            -- Apply our cosmetics if this is our local weapon
            local isLocal = self.ClientFighter and self.ClientFighter.Player == player
            if isLocal and equippedCosmetics[self.Name] then
                local cosmetics = equippedCosmetics[self.Name]
                
                -- Apply skin
                if cosmetics.Skin and cosmetics.Skin ~= "" and cosmetics.Skin ~= "None" then
                    local skinCosmetic = cosmeticLib.Cosmetics[cosmetics.Skin]
                    if skinCosmetic and skinCosmetic.Type == "Skin" then
                        -- Find the skin model
                        local skinModel
                        for _, thing in ipairs(game:GetService("StarterPlayer").StarterPlayerScripts.Assets.ViewModels:GetDescendants()) do
                            if thing:IsA("Model") and thing.Name == cosmetics.Skin then
                                skinModel = thing
                                break
                            end
                        end
                        
                        if skinModel then
                            -- Replace the viewmodel with skin model
                            local normalModel
                            for _, thing in ipairs(player.PlayerScripts.Assets.ViewModels:GetDescendants()) do
                                if thing:IsA("Model") and thing.Name == self.Name then
                                    normalModel = thing
                                    break
                                end
                            end
                            
                            if normalModel then
                                normalModel:ClearAllChildren()
                                for _, part in ipairs(skinModel:GetChildren()) do
                                    part:Clone().Parent = normalModel
                                end
                            end
                        end
                    end
                end
                
                -- Apply wrap
                if cosmetics.Wrap and cosmetics.Wrap ~= "" and cosmetics.Wrap ~= "None" then
                    local wrapCosmetic = cosmeticLib.Cosmetics[cosmetics.Wrap]
                    if wrapCosmetic and wrapCosmetic.Type == "Wrap" then
                        -- You'll need to implement wrap application here
                        -- This might involve modifying material properties
                    end
                end
                
                -- Apply charm
                if cosmetics.Charm and cosmetics.Charm ~= "" and cosmetics.Charm ~= "None" then
                    local charmCosmetic = cosmeticLib.Cosmetics[cosmetics.Charm]
                    if charmCosmetic and charmCosmetic.Type == "Charm" then
                        -- Find charm model and attach it
                        local charmFolder = game:GetService("StarterPlayer").StarterPlayerScripts.Assets:FindFirstChild("Charms")
                        if charmFolder then
                            local charmModel = charmFolder:FindFirstChild(cosmetics.Charm)
                            if charmModel then
                                -- Attach charm to weapon
                                local weaponModel
                                for _, thing in ipairs(player.PlayerScripts.Assets.ViewModels:GetDescendants()) do
                                    if thing:IsA("Model") and thing.Name == self.Name then
                                        weaponModel = thing
                                        break
                                    end
                                end
                                
                                if weaponModel then
                                    -- Remove existing charms
                                    for _, obj in ipairs(weaponModel:GetChildren()) do
                                        if obj.Name == "__CHARM" then
                                            obj:Destroy()
                                        end
                                    end
                                    
                                    -- Find attachment point
                                    local weaponAttach
                                    for _, d in ipairs(weaponModel:GetDescendants()) do
                                        if d:IsA("Attachment") and d.Name == "_charm_pivot_attachment" then
                                            weaponAttach = d
                                            break
                                        end
                                    end
                                    
                                    if weaponAttach then
                                        local charmClone = charmModel:Clone()
                                        charmClone.Name = "__CHARM"
                                        
                                        -- Create WeldConstraint to attach charm
                                        local weld = Instance.new("WeldConstraint")
                                        weld.Part0 = weaponAttach.Parent
                                        weld.Part1 = charmClone.PrimaryPart or charmClone:FindFirstChildWhichIsA("BasePart")
                                        weld.Parent = charmClone
                                        
                                        charmClone.Parent = weaponModel
                                        
                                        -- Position charm at attachment
                                        if charmClone.PrimaryPart then
                                            charmClone:SetPrimaryPartCFrame(weaponAttach.WorldCFrame)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            return result
        end
    end
    
    -- Also hook the equip function to apply when weapon is equipped
    local success2, ClientFighter = pcall(function()
        return require(player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter)
    end)
    
    if success2 and ClientFighter then
        -- Hook weapon equip function
        local clientFighterInstance = ClientFighter.Get(player)
        if clientFighterInstance and clientFighterInstance.EquipWeapon then
            if not clientFighterInstance.EquipWeapon_Original then
                clientFighterInstance.EquipWeapon_Original = clientFighterInstance.EquipWeapon
            end
            
            clientFighterInstance.EquipWeapon = function(self, weaponName, ...)
                local result = clientFighterInstance.EquipWeapon_Original(self, weaponName, ...)
                
                -- Apply cosmetics when weapon is equipped
                if equippedCosmetics[weaponName] then
                    task.wait(0.1) -- Wait for viewmodel to load
                    changeSkin(weaponName, equippedCosmetics[weaponName].Skin, equippedCosmetics[weaponName].Wrap, equippedCosmetics[weaponName].Charm)
                end
                
                return result
            end
        end
    end
end

local Settings = {
    FileName = "HeavenlyRVLXcfg.txt"
}

local UserSettings = {}

function Settings:Save(data)
    if writefile then
        local success, errorMsg = pcall(function()
            writefile(self.FileName, game:GetService("HttpService"):JSONEncode(data))
        end)

        if success then
            
        else
            warn("Could not save:", errorMsg)
        end
    end
end

function Settings:Load()
    local loadedSettings = {}

    if isfile and isfile(self.FileName) then
        local success, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(self.FileName))
        end)

        if success and data then
            loadedSettings = data
        end
    end
    
    return loadedSettings
end

UserSettings = Settings:Load() or {}

local function AutoSave()
    task.wait(0.5)
    Settings:Save(UserSettings)
end

local function GetSetting(key, defaultValue)
    if UserSettings[key] ~= nil then
        return UserSettings[key]
    end
    return defaultValue
end

local function SaveSetting(key, value)
    UserSettings[key] = value
    task.spawn(AutoSave)
end


local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/HeavenlyScripts/OrionNew/refs/heads/main/Orion.lua"))()

local Window = OrionLib:MakeWindow({
    Name = "Heavenly",
    HidePremium = false,
    IntroIcon = "rbxassetid://120536320464344",
    SaveConfig = true,
    ConfigFolder = "HvnlyRivals",
    IntroEnabled = true,
    IntroText = "Access Granted... Welcome to Heavenly"
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local AssetsFolder = StarterPlayerScripts:WaitForChild("Assets")
local ViewModelsFolder = AssetsFolder:WaitForChild("ViewModels")

local TabCredits = Window:MakeTab({
    Name = "Credits",
    Icon = "rbxassetid://123810491451954"
})
TabCredits:AddParagraph("2025 Heavenly", "Made by the Team of Heavenly")
TabCredits:AddButton({
    Name = "Copy Discord Link",
    Callback = function()
        setclipboard("https://discord.gg/MERzRQ2UHn") 
        OrionLib:MakeNotification({
            Name = "Discord",
            Content = "Link Copied",
            Image = "rbxassetid://123810491451954",
            Time = 5
        })
    end    
})

local AimbotTab = Window:MakeTab({
    Name = "Combat",
    Icon = "rbxassetid://121615146959714",
    PremiumOnly = false
})

local ESPTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://78678714479511",
    PremiumOnly = false
})

local GunModsTab = Window:MakeTab({
    Name = "Gun Mods",
    Icon = "rbxassetid://98732304151282",
    PremiumOnly = false
})

local PlayerTab = Window:MakeTab({
    Name = "Player",
    Icon = "rbxassetid://110701632373035"
})

local SkinsTab = Window:MakeTab({
    Name = "Skins",
    Icon = "rbxassetid://128042779395199",
    PremiumOnly = false
})

local MiscTab = Window:MakeTab({
    Name = "Misc",
    Icon = "rbxassetid://128593575467422",
    PremiumOnly = false
})


SkinsTab:AddSection({
    Name = "Unlocker"
})

SkinsTab:AddButton({
    Name = "Unlock All (Fully)",
    Callback = function()
        -- Hook all the ownership functions
        local oldOwnsNormally = cosmeticLib.OwnsCosmeticNormally
        cosmeticLib.OwnsCosmeticNormally = function(self, playerCosmetics, cosmeticName)
            if self.Cosmetics[cosmeticName] and (self.Cosmetics[cosmeticName].Type == "Charm" or 
                                                self.Cosmetics[cosmeticName].Type == "Skin" or 
                                                self.Cosmetics[cosmeticName].Type == "Wrap" or
                                                self.Cosmetics[cosmeticName].Type == "Finisher" or
                                                self.Cosmetics[cosmeticName].Type == "Emote") then
                return true
            end
            return oldOwnsNormally(self, playerCosmetics, cosmeticName)
        end

        local oldOwnsUniversally = cosmeticLib.OwnsCosmeticUniversally
        cosmeticLib.OwnsCosmeticUniversally = function(self, playerCosmetics, cosmeticName)
            if self.Cosmetics[cosmeticName] and (self.Cosmetics[cosmeticName].Type == "Charm" or 
                                                self.Cosmetics[cosmeticName].Type == "Skin" or 
                                                self.Cosmetics[cosmeticName].Type == "Wrap" or
                                                self.Cosmetics[cosmeticName].Type == "Finisher" or
                                                self.Cosmetics[cosmeticName].Type == "Emote") then
                return true
            end
            return oldOwnsUniversally(self, playerCosmetics, cosmeticName)
        end

        local oldOwnsForWeapon = cosmeticLib.OwnsCosmeticForWeapon
        cosmeticLib.OwnsCosmeticForWeapon = function(self, playerCosmetics, cosmeticName, weaponName)
            if self.Cosmetics[cosmeticName] and (self.Cosmetics[cosmeticName].Type == "Skin" or 
                                                self.Cosmetics[cosmeticName].Type == "Wrap") then
                return true
            end
            return oldOwnsForWeapon(self, playerCosmetics, cosmeticName, weaponName)
        end

        local oldOwns = cosmeticLib.OwnsCosmetic
        cosmeticLib.OwnsCosmetic = function(self, playerCosmetics, cosmeticName, weaponName)
            if self.Cosmetics[cosmeticName] and (self.Cosmetics[cosmeticName].Type == "Charm" or 
                                                self.Cosmetics[cosmeticName].Type == "Skin" or 
                                                self.Cosmetics[cosmeticName].Type == "Wrap" or
                                                self.Cosmetics[cosmeticName].Type == "Finisher" or
                                                self.Cosmetics[cosmeticName].Type == "Emote") then
                return true
            end
            return oldOwns(self, playerCosmetics, cosmeticName, weaponName)
        end

        -- Also hook CanEquipCosmetic function
        local oldCanEquip = cosmeticLib.CanEquipCosmetic
        if oldCanEquip then
            cosmeticLib.CanEquipCosmetic = function(self, playerCosmetics, cosmeticName, weaponName)
                if self.Cosmetics[cosmeticName] and (self.Cosmetics[cosmeticName].Type == "Charm" or 
                                                    self.Cosmetics[cosmeticName].Type == "Skin" or 
                                                    self.Cosmetics[cosmeticName].Type == "Wrap" or
                                                    self.Cosmetics[cosmeticName].Type == "Finisher" or
                                                    self.Cosmetics[cosmeticName].Type == "Emote") then
                    return true
                end
                return oldCanEquip(self, playerCosmetics, cosmeticName, weaponName)
            end
        end

        -- Hook server verification if possible
        local RemoteFunctions = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunctions")
        if RemoteFunctions then
            local verifyRemote = RemoteFunctions:FindFirstChild("VerifyCosmeticOwnership") or 
                               RemoteFunctions:FindFirstChild("CheckCosmeticOwnership")
            
            if verifyRemote then
                local oldInvoke = verifyRemote.InvokeServer
                verifyRemote.InvokeServer = function(self, ...)
                    -- Always return true to server verification
                    return true
                end
            end
        end

        -- Also hook into the cosmetic data retrieval
        local oldGetCosmetic = cosmeticLib.GetCosmetic
        if oldGetCosmetic then
            cosmeticLib.GetCosmetic = function(self, cosmeticName)
                local result = oldGetCosmetic(self, cosmeticName)
                if result then
                    -- Mark all cosmetics as owned
                    if not result.IsOwned then
                        result.IsOwned = true
                    end
                end
                return result
            end
        end

        OrionLib:MakeNotification({
            Name = "Cosmetics Fully Unlocked!",
            Content = "You can now equip all skins in the game menu!",
            Image = "rbxassetid://98816484215408",
            Time = 5
        })
    end    
})

SkinsTab:AddButton({
    Name = "Unlock Skins",
    Callback = function()
        local oldOwnsForWeapon = cosmeticLib.OwnsCosmeticForWeapon
        cosmeticLib.OwnsCosmeticForWeapon = function(self, playerCosmetics, cosmeticName, weaponName)
            if self.Cosmetics[cosmeticName] and self.Cosmetics[cosmeticName].Type == "Skin" then
                return true
            end
            return oldOwnsForWeapon(self, playerCosmetics, cosmeticName, weaponName)
        end

        local oldOwns = cosmeticLib.OwnsCosmetic
        cosmeticLib.OwnsCosmetic = function(self, playerCosmetics, cosmeticName, weaponName)
            if self.Cosmetics[cosmeticName] and self.Cosmetics[cosmeticName].Type == "Skin" then
                return true
            end
            return oldOwns(self, playerCosmetics, cosmeticName, weaponName)
        end

        OrionLib:MakeNotification({
            Name = "Skins Unlocked!",
            Content = "All weapon skins unlocked!",
            Image = "rbxassetid://98816484215408",
            Time = 5
        })
        
    end    
})

SkinsTab:AddButton({
    Name = "Unlock Wraps",
    Callback = function()
        local oldOwnsForWeapon = cosmeticLib.OwnsCosmeticForWeapon
        cosmeticLib.OwnsCosmeticForWeapon = function(self, playerCosmetics, cosmeticName, weaponName)
            if self.Cosmetics[cosmeticName] and self.Cosmetics[cosmeticName].Type == "Wrap" then
                return true
            end
            return oldOwnsForWeapon(self, playerCosmetics, cosmeticName, weaponName)
        end

        local oldOwns = cosmeticLib.OwnsCosmetic
        cosmeticLib.OwnsCosmetic = function(self, playerCosmetics, cosmeticName, weaponName)
            if self.Cosmetics[cosmeticName] and self.Cosmetics[cosmeticName].Type == "Wrap" then
                return true
            end
            return oldOwns(self, playerCosmetics, cosmeticName, weaponName)
        end

        OrionLib:MakeNotification({
            Name = "Wraps Unlocked!",
            Content = "All weapon wraps unlocked!",
            Image = "rbxassetid://98816484215408",
            Time = 5
        })
    end    
})

SkinsTab:AddButton({
    Name = "Unlock Charms",
    Callback = function()
        local oldOwnsNormally = cosmeticLib.OwnsCosmeticNormally
        cosmeticLib.OwnsCosmeticNormally = function(self, playerCosmetics, cosmeticName)
            if self.Cosmetics[cosmeticName] and self.Cosmetics[cosmeticName].Type == "Charm" then
                return true
            end
            return oldOwnsNormally(self, playerCosmetics, cosmeticName)
        end

        OrionLib:MakeNotification({
            Name = "Charms Unlocked!",
            Content = "All charms unlocked!",
            Image = "rbxassetid://98816484215408",
            Time = 5
        })
    end    
})

local eSkins = {}
local wSkins = {}

for weaponName, _ in pairs(itemLib.ViewModels) do
    if weaponName ~= "MISSING_WEAPON" then
        wSkins[weaponName] = {"None"}
    end
end

for cosName, cosData in pairs(cosmeticLib.Cosmetics) do
    if cosData.Type == "Skin" and cosData.ItemName then
        local weaponName = cosData.ItemName

        if weaponName ~= "MISSING_WEAPON" and wSkins[weaponName] then
            table.insert(wSkins[weaponName], cosName)
        end
    end
end

local function applySkin(weaponName, skinName)
    if not weaponName then return end

    eSkins[weaponName] = skinName

    local key = "Skin_" .. weaponName
    SaveSetting(key, skinName)

    local player = Players.LocalPlayer
    if not player then return end
    
    local playerScripts = player:WaitForChild("PlayerScripts")
    local playerAssets = playerScripts:WaitForChild("Assets")
    local playerViewModels = playerAssets:WaitForChild("ViewModels")
    
    local nModel
    for _, t in ipairs(playerViewModels:GetDescendants()) do
        if t:IsA("Model") and t.Name == weaponName then
            nModel = t
            break
        end
    end

    if not nModel then
        local originalModel
        for _, t in ipairs(ViewModelsFolder:GetDescendants()) do
            if t:IsA("Model") and t.Name == weaponName then
                originalModel = t
                break
            end
        end
        
        if originalModel then
            nModel = originalModel:Clone()
            nModel.Parent = playerViewModels
        end
    end

    if not nModel then
        warn("Model not found:", weaponName)
        return
    end

    if skinName == "None" or skinName == "" or not skinName then
        nModel:ClearAllChildren()
        
        local ogModel
        for _, t in ipairs(ViewModelsFolder:GetDescendants()) do
            if t:IsA("Model") and t.Name == weaponName then
                ogModel = t
                break
            end
        end

        if ogModel then
            for _, part in ipairs(ogModel:GetChildren()) do
                part:Clone().Parent = nModel
            end
        end
        return
    end

    local skinData = cosmeticLib.Cosmetics[skinName]
    if not skinData or skinData.Type ~= "Skin" then
        warn("Skin not found in cLib:", skinName)
        return
    end

    local skinModel
    for _, t in ipairs(ViewModelsFolder:GetDescendants()) do
        if t:IsA("Model") and t.Name == skinName then
            skinModel = t
            break
        end
    end

    if not skinModel then
        for _, t in ipairs(ViewModelsFolder:GetDescendants()) do
            if t:IsA("Model") and string.find(string.lower(t.Name), string.lower(skinName)) then
                skinModel = t
                break
            end
        end
    end

    if not skinModel then
        warn("Skinmodel not found:", skinName)
        return
    end

    nModel:ClearAllChildren()
    for _, part in ipairs(skinModel:GetChildren()) do
        local clone = part:Clone()
        clone.Parent = nModel
    end

    if itemLib.ViewModels[weaponName] and itemLib.ViewModels[skinName] then
        local skinViewModel = itemLib.ViewModels[skinName]
        local weaponViewModel = itemLib.ViewModels[weaponName]

        weaponViewModel.Image = skinViewModel.Image or weaponViewModel.Image
        weaponViewModel.ImageHighResolution = skinViewModel.ImageHighResolution or weaponViewModel.ImageHighResolution
        weaponViewModel.ImageCentered = skinViewModel.ImageCentered or weaponViewModel.ImageCentered
        weaponViewModel.EliminationFeedImage = skinViewModel.EliminationFeedImage or weaponViewModel.EliminationFeedImage
        weaponViewModel.EliminationFeedImageScale = skinViewModel.EliminationFeedImageScale or weaponViewModel.EliminationFeedImageScale
        weaponViewModel.RootPartOffset = skinViewModel.RootPartOffset or weaponViewModel.RootPartOffset

        if skinViewModel.Animations then
            weaponViewModel.Animations = {}
            for animType, animName in pairs(skinViewModel.Animations) do
                weaponViewModel.Animations[animType] = animName
            end
        end
    end
    print("applied skin " .. skinName .. " to " .. weaponName)
end

local function loadSkins()
    for weaponName, skins in pairs(wSkins) do
        local key = "Skin_" .. weaponName
        local savedSkin = GetSetting(key, "None")

        if savedSkin ~= "None" then
            local isValid = false
            for _, skin in ipairs(skins) do
                if skin == savedSkin then
                    isValid = true
                    break
                end
            end

            if isValid then
                eSkins[weaponName] = savedSkin
            else
                SaveSetting(key, "None")
                eSkins[weaponName] = "None"
            end
        else
            eSkins[weaponName] = "None"
        end
    end
end

local function hookWeaponEquip()
    local success, ClientFighter = pcall(function()
        return require(player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter)
    end)
    
    if success and ClientFighter then
        local clientFighterInstance = ClientFighter.Get(player)
        if clientFighterInstance and clientFighterInstance.EquipWeapon then
            if not clientFighterInstance.EquipWeapon_Original then
                clientFighterInstance.EquipWeapon_Original = clientFighterInstance.EquipWeapon
            end
            
            clientFighterInstance.EquipWeapon = function(self, weaponName, ...)
                local result = clientFighterInstance.EquipWeapon_Original(self, weaponName, ...)
                
                
                if eSkins[weaponName] and eSkins[weaponName] ~= "None" then
                    task.wait(0.2)
                    applySkin(weaponName, eSkins[weaponName])
                end
                
                return result
            end
        end
    end
end


local function sort()
    SkinsTab:AddSection({
        Name = "Skin Changer"
    })

    local allWeapons = {}
    for weaponName, skins in pairs(wSkins) do
        if #skins > 1 then
            table.insert(allWeapons, weaponName)
        end
    end
    table.sort(allWeapons)

    for _, weaponName in ipairs(allWeapons) do
       local skins = wSkins[weaponName]

       local savedSkin = GetSetting("Skin_" .. weaponName, "None")

       local isValid = false
       for _, skin in ipairs(skins) do
        if skin == savedSkin then
            isValid = true
            break
        end
    end
    
    if not isValid then
        savedSkin = "None"
        SaveSetting("Skin_" .. weaponName, "None")
    end

       SkinsTab:AddDropdown({
        Name = weaponName,
        Default = savedSkin,
        Options = skins,
        Callback = function(selectedSkin)
            applySkin(weaponName, selectedSkin)
        end
       })
    end

    SkinsTab:AddButton({
        Name = "Reset Skins",
        Callback = function()
            for weaponName, _ in pairs(eSkins) do
                applySkin(weaponName, "None")
                eSkins[weaponName] = "None"
            end

            OrionLib:MakeNotification({
                Name = "Skins Reset",
                Content = "Resetted all skins",
                Time = 3
            })
        end
    })
end

sort()
loadSkins()
hookWeaponEquip()

AimbotTab:AddSection({
    Name = "Aimbot"
})

local AimbotEnabled = false
local AimbotKey = Enum.KeyCode.B
local AimPart = "HumanoidRootPart"
local TeamCheck = true
local AimbotSmoothness = 0.2
local Prediction = false
local KnockedHealthThreshold = 0
local ShowFOV = true
local FOVSize = 100
local FOVColor = Color3.fromRGB(255, 255, 255)
local FOVTransp = 0.7
local FOVThickness = 1

local FOVc = Drawing.new("Circle")
FOVc.Visible = ShowFOV
FOVc.Radius = FOVSize
FOVc.Color = FOVColor
FOVc.Transparency = FOVTransp
FOVc.Thickness = FOVThickness
FOVc.Filled = false
FOVc.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)

AimbotTab:AddToggle({
    Name = "Aimbot",
    Default = GetSetting("AimbotEnabled", false),
    Callback = function(val)
        AimbotEnabled = val
        if ShowFOV then
            FOVc.Visible = val
        end
        SaveSetting("AimbotEnabled", val)
    end
})

AimbotTab:AddSlider({
    Name = "FOV Size",
    Min = 10,
    Max = 500,
    Default = GetSetting("FOVSize", 100),
    Increment = 1,
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        FOVSize = v
        FOVc.Radius = v
        SaveSetting("FOVSize", v)
    end
})

AimbotTab:AddBind({
    Name = "Aimbot Keybind",
    Default = Enum.KeyCode.B,
    Hold = false,
    Callback = function()
        AimbotEnabled = not AimbotEnabled
        if ShowFOV then
            FOVc.Visible = AimbotEnabled
        end
    end
})

AimbotTab:AddDropdown({
    Name = "Aim Part",
    Default = GetSetting("AimPart", "HumanoidRootPart"),
    Options = { "Head", "HumanoidRootPart" },
    Callback = function(val)
        AimPart = val
        SaveSetting("AimPart", val)
    end
})

AimbotTab:AddSlider({
    Name = "Aimbot Strength",
    Min = 0.1,
    Max = 1,
    Default = GetSetting("AimbotSmoothness", 0.25),
    Increment = 0.01,
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(val)
        AimbotSmoothness = val
        SaveSetting("AimbotSmoothness", val)
    end
})

local function isEn(player)
    if LocalPlayer and player and LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    return true
end

local function gbT()
    local Camera = workspace.CurrentCamera
    local bestTarget = nil
    local closestDistance = math.huge
    local LocalPlayerTeam = LocalPlayer.Team

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(AimPart) and (not TeamCheck or isEn(player)) then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health > KnockedHealthThreshold then
                local screenPos, onScreen = Camera:WorldToScreenPoint(player.Character[AimPart].Position)
                if onScreen then
                    local magnitude = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                    if magnitude <= FOVSize and magnitude < closestDistance then
                        closestDistance = magnitude
                        bestTarget = player
                    end
                end
            end
        end
    end
    return bestTarget
end

RunService.RenderStepped:Connect(function(deltaTime)
    FOVc.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
    
    if AimbotEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = gbT()
        if target and target.Character and target.Character:FindFirstChild(AimPart) then
            local Camera = workspace.CurrentCamera
            local targetPosition = target.Character[AimPart].Position
            
            local currentTime = tick()
            local delta = math.min(currentTime - lastFrameTime, 0.033) 
            lastFrameTime = currentTime







            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newLookVector)
        end
    end
end)

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    FOVc.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
end)

local SilentEnabled = false
local SilentKey = Enum.KeyCode.V
local SilentFOV = 100
local SilentFOVColor = Color3.fromRGB(241, 142, 255)
local SilentFOVTransp = 0.7
local SilentFOVThickness = 1
local SilentShooting = false

local SilentFOVc = Drawing.new("Circle")
SilentFOVc.Visible = false  
SilentFOVc.Radius = SilentFOV
SilentFOVc.Color = SilentFOVColor
SilentFOVc.Transparency = SilentFOVTransp
SilentFOVc.Thickness = SilentFOVThickness
SilentFOVc.Filled = false
SilentFOVc.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)

AimbotTab:AddSection({
    Name = "Silent Aim",
})

AimbotTab:AddToggle({
    Name = "Silent Aim",
    Default = false,
    Callback = function(val)
        SilentEnabled = val
        SilentFOVc.Visible = val

        if not SilentEnabled then
            if clickConn then
                clickConn:Disconnect()
                clickConn = nil
            end
            lDown = false
            rDown = false
        end
    end
})

AimbotTab:AddSlider({
    Name = "FOV Size",
    Min = 10,
    Max = 500,
    Default = 100,
    Increment = 1,
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        SilentFOV = v
        SilentFOVc.Radius = v
    end
})

AimbotTab:AddBind({
    Name = "Keybind",
    Default = SilentKey,
    Hold = false,
    Callback = function()
        SilentEnabled = not SilentEnabled
        SilentFOVc.Visible = SilentEnabled

        if not SilentEnabled then
            if clickConn then
                clickConn:Disconnect()
                clickConn = nil
            end
            lDown = false
            rDown = false
        end
    end
})

local cam = workspace.CurrentCamera
local targetP = nil
local Int = 0.10
local lDown = false
local rDown = false
local clickConn = nil

local function lV()
    return LocalPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Visible == true
end

local function getClosest()
    local closestP = nil
    local sDist = math.huge
    local mP = UIS:GetMouseLocation()
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local h = p.Character.Head
            local hP, oS = cam:WorldToViewportPoint(h.Position)
            if oS then
                local sP = Vector2.new(hP.X, hP.Y)
                local dist = (sP - mP).Magnitude
                
                local distFromCenter = (sP - screenCenter).Magnitude
                if dist < sDist and distFromCenter <= SilentFOV then
                    closestP = p
                    sDist = dist
                end
            end
        end
    end
    return closestP
end

local function LCH()
    if targetP and targetP.Character and targetP.Character:FindFirstChild("Head") then
        local h = targetP.Character.Head
        local hP = cam:WorldToViewportPoint(h.Position)
        if hP.Z > 0 then
            local cP = cam.CFrame.Position
            local dir = (hP - cP).Unit
            cam.CFrame = CFrame.new(cP, h.Position)
        end
    end
end

local function a()
    if clickConn then
        clickConn:Disconnect()
    end
    clickConn = RunService.Heartbeat:Connect(function()
        if lDown or rDown then
            if not lV() then
                mouse1click()
            end
        else
            clickConn:Disconnect()
        end
    end)
end

UIS.InputBegan:Connect(function(input, isProcessed)
    if not SilentEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed then
        if not lDown then
            lDown = true
            a()
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed then
        if not rDown then
            rDown = true
            a()
        end
    end
end)

UIS.InputEnded:Connect(function(input, isProcessed)
    if not SilentEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed then
        lDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed then
        rDown = false
    end
end)

RunService.Heartbeat:Connect(function()
    SilentFOVc.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    if not lV() and SilentEnabled then
        targetP = getClosest()
        if targetP then
            LCH()
        end
    end
end)

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    SilentFOVc.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
end)

OrionLib:Init()
