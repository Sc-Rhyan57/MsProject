local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Achievements = require(RS:WaitForChild("ModulesShared"):WaitForChild("Achievements"))
local ReplicaSetValueEvent = RS:WaitForChild("ReplicaRemoteEvents"):WaitForChild("Replica_ReplicaSetValue")
local AchievementUnlockEvent = RS:WaitForChild("RemotesFolder"):WaitForChild("AchievementUnlock")
local AchievementsUpdated = RS:WaitForChild("ReplicaDataModule"):WaitForChild("AchievementsUpdated")
local ReplicaDataModule = require(RS:WaitForChild("ReplicaDataModule"))
local ReplicaController = require(RS:WaitForChild("ReplicaController"))

local replicaId = nil
for id, replica in pairs(ReplicaController._replicas) do
    if replica.Class == "PlayerProfile" and replica.Tags.Player == LocalPlayer then
        replicaId = id
        break
    end
end
if not replicaId then
    ReplicaController.ReplicaOfClassCreated("PlayerProfile", function(replica)
        if replica.Tags.Player == LocalPlayer then
            replicaId = replica.Id
        end
    end)
    local t = 0
    while replicaId == nil and t < 10 do task.wait(0.1) t += 0.1 end
end
if not replicaId then warn("ReplicaId não encontrado.") return end

local playerData = nil
local t = 0
while not playerData and t < 10 do
    playerData = ReplicaDataModule.players[LocalPlayer]
    task.wait(0.1)
    t += 0.1
end
if not playerData then warn("playerData não encontrado.") return end
if not playerData.data.Achievements then
    playerData.data.Achievements = {}
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainUI = PlayerGui:WaitForChild("MainUI")
local LobbyFrame = MainUI:WaitForChild("LobbyFrame")
local AchievementsFrame = LobbyFrame:WaitForChild("Achievements")
local List = AchievementsFrame:WaitForChild("List")
local DetailFrame = AchievementsFrame:WaitForChild("Frame")
local TextHolder = DetailFrame:WaitForChild("TextHolder")
local ApplyButton = DetailFrame:WaitForChild("Apply")
local AppliedLabel = DetailFrame:WaitForChild("Applied")

local keys = {}
for key in pairs(Achievements) do
    table.insert(keys, key)
end

for _, badge in ipairs(List:GetChildren()) do
    if not badge:IsA("ImageButton") then continue end
    if badge:GetAttribute("Have") == nil then continue end

    badge:SetAttribute("Have", true)
    badge.Visible = true
    badge.ImageColor3 = Color3.fromRGB(255, 255, 255)
    badge.ImageTransparency = 0

    local outlineImage = badge:FindFirstChild("OutlineImage")
    if outlineImage then
        outlineImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
        outlineImage.ImageTransparency = 0
    end

    local icons = badge:FindFirstChild("Icons")
    if icons then
        local question = icons:FindFirstChild("Question")
        if question then question.Visible = false end
    end

    badge.MouseButton1Click:Connect(function()
        local achName = badge:GetAttribute("Name") or badge.Name
        local desc = badge:GetAttribute("Desc") or ""
        local reason = badge:GetAttribute("Reason") or ""
        local title = badge:GetAttribute("Title") or ""
        local isSecret = badge:GetAttribute("Secret") or false
        local image = badge:GetAttribute("Image") or badge.Image

        DetailFrame:SetAttribute("CurrentAchievement", achName)

        local titleLabel = TextHolder:FindFirstChild("Title")
        if titleLabel then titleLabel.Text = title end

        local reasonLabel = TextHolder:FindFirstChild("Reason")
        if reasonLabel then reasonLabel.Text = reason reasonLabel.Visible = true end

        local descLabel = TextHolder:FindFirstChild("Desc")
        if descLabel then descLabel.Text = desc descLabel.Visible = true end

        local isSecretLabel = TextHolder:FindFirstChild("IsSecret")
        if isSecretLabel then isSecretLabel.Visible = isSecret end

        local imgLabel = DetailFrame:FindFirstChild("ImageLabel")
        if imgLabel then imgLabel.Image = image end

        ApplyButton.Visible = playerData.data.FlexAchievement ~= achName
        AppliedLabel.Visible = playerData.data.FlexAchievement == achName
    end)
end

ApplyButton.MouseButton1Click:Connect(function()
    local achName = DetailFrame:GetAttribute("CurrentAchievement")
    if not achName then return end

    playerData.data.FlexAchievement = achName

    firesignal(ReplicaSetValueEvent.OnClientEvent, replicaId, {"FlexAchievement"}, achName)

    if playerData.event and playerData.event.FlexAchievement and playerData.event.FlexAchievement.Event then
        firesignal(playerData.event.FlexAchievement.Event)
    end

    ApplyButton.Visible = false
    AppliedLabel.Visible = true
end)

firesignal(AchievementsUpdated.Event, keys)

for _, key in ipairs(keys) do
    task.spawn(function()
        firesignal(ReplicaSetValueEvent.OnClientEvent, replicaId, {"Achievements", key}, true)
        firesignal(ReplicaSetValueEvent.OnClientEvent, replicaId, {"FlexAchievement"}, key)
        firesignal(AchievementUnlockEvent.OnClientEvent, key)

        playerData.data.Achievements[key] = true
        playerData.data.FlexAchievement = key

        if playerData.event and playerData.event.FlexAchievement and playerData.event.FlexAchievement.Event then
            firesignal(playerData.event.FlexAchievement.Event)
        end

        local badge = List:FindFirstChild(key)
        if badge and badge:IsA("ImageButton") then
            badge:SetAttribute("Have", true)
            badge.Visible = true
            badge.ImageColor3 = Color3.fromRGB(255, 255, 255)
            badge.ImageTransparency = 0
            local outlineImage = badge:FindFirstChild("OutlineImage")
            if outlineImage then
                outlineImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
                outlineImage.ImageTransparency = 0
            end
        end
    end)

    task.wait(0.1)
end
