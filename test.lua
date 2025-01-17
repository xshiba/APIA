while true do
-- Hàm tấn công tất cả NPC không giới hạn khoảng cách
local function attackAll()
    pcall(function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart")

        -- Lấy danh sách NPC từ workspace
        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            local args = {
                [1] = nil, -- Bộ phận của NPC chính
                [2] = {}   -- Danh sách NPC phụ
            }

            for _, enemy in pairs(enemies:GetChildren()) do
                local hitbox = enemy:FindFirstChild("UpperTorso")
                if hitbox then
                    if not args[1] then
                        -- Gán bộ phận của NPC chính (NPC đầu tiên)
                        args[1] = hitbox
                    else
                        -- Thêm các NPC phụ vào danh sách
                        table.insert(args[2], {
                            [1] = enemy,
                            [2] = hitbox
                        })
                    end
                end
            end

            if args[1] then
                -- Gửi lệnh tấn công đến server
                local replicatedStorage = game:GetService("ReplicatedStorage")
                local modulesNet = replicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
                modulesNet:WaitForChild("RE/RegisterHit"):FireServer(unpack(args))
                modulesNet:WaitForChild("RE/RegisterAttack"):FireServer("0")
            end
        end
    end)
end

-- Thực thi tấn công tất cả NPC
attackAll()
wait (0.1)
end
