local Players = game:GetService("Players")
local AI = Players.LocalPlayer
local AI_Char = AI.Character or AI:WaitForChild("Character")
local Health, MaxHealth  = AI_Char.Humanoid.Health, AI_Char.Humanoid.MaxHealth
local VirutalInput =  game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
