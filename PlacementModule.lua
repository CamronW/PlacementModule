--To be used later
local isServer = game:GetService("RunService"):IsServer()

local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Placement = {}


function Placement.isInRegion(Pos,A,B)
	return (Pos.X < math.max(A.X,B.X) and Pos.X > math.min(A.X,B.X)) and (Pos.Z < math.max(A.Z,B.Z) and Pos.Z > math.min(A.Z,B.Z))
end

function Placement.allowedToPlaceHere(player, partPos)
	local playerCanvas = workspace:WaitForChild("PlayerCanvas"):WaitForChild(player.UserId)

	for i,areaPart in pairs(playerCanvas.AllowedAreas:GetChildren()) do
		local bottomLeft = areaPart.Position - Vector3.new(areaPart.Size.X/2, areaPart.Size.Y/2, areaPart.Size.Z/2)
		local topRight = areaPart.Position + Vector3.new(areaPart.Size.X/2, areaPart.Size.Y/2, areaPart.Size.Z/2)
		if Placement.isInRegion(partPos, bottomLeft, topRight) then
			return true
		end
	end
	return false
end

function Placement.placePart(part, position, rotation)

	--Work out the bottom using the bounding box
	local yOffset = 0
	if part.PrimaryPart.Name == "BoundingBox" then
		yOffset = -(part.PrimaryPart.Size.Y / 2)
	end

	local currentRotation = part.PrimaryPart.Orientation.Y
	
	--local xGrid = math.round(position.X*2)/2
	--local zGrid = math.round(position.Z*2)/2
	local xGrid = math.floor(position.X / 0.5 + 1) * 0.5 
	local zGrid = math.floor(position.Z / 0.5 + 1) * 0.5 
	local gridPos =  Vector3.new(xGrid, 0 - yOffset, zGrid)
	--local gridPos = Vector3.new(
	--	math.floor(position.X / 0.5 + 0.5) * 0.5,
	--	0 - yOffset,
	--	math.floor(position.Z / 0.5 + 0.5) * 0.5
	--)
	print("gridPos", gridPos)
	local finalPos = Vector3.new(0,0,0)
 
	--Some calculations to work out any offsets to make it line up with the grid
	if part.PrimaryPart.Size.X < 1 and part.PrimaryPart.Size.Z < 1 then
		finalPos = gridPos + Vector3.new(part.PrimaryPart.Size.X/2,0,part.PrimaryPart.Size.Z/2)
	elseif part.PrimaryPart.Size.X < 1  then
		if currentRotation == 0 or currentRotation == -180 or currentRotation == 180 then
			finalPos = gridPos + Vector3.new(part.PrimaryPart.Size.X/2,0,0)
		else
			finalPos = gridPos + Vector3.new(0,0,-part.PrimaryPart.Size.X/2)
		end
	elseif part.PrimaryPart.Size.Z < 1 then
		if currentRotation == 0 or currentRotation == -180 or currentRotation == 180 then
			finalPos = gridPos + Vector3.new(0,0,-part.PrimaryPart.Size.Z/2)	
		else
			finalPos = gridPos + Vector3.new(part.PrimaryPart.Size.Z/2,0,0)
		end
	else
		--If big
		finalPos = gridPos
	end
	--Position                 --Rotation
	part:SetPrimaryPartCFrame(CFrame.new(finalPos) * CFrame.Angles(0, math.rad(rotation+currentRotation), 0))
end

function Placement.runPlaceAnimation(part)
	print("Running place animation", part)
	--The part/model is already in the final location, we just make it jump
	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = part:GetPrimaryPartCFrame()

	CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		part:SetPrimaryPartCFrame(CFrameValue.Value)
	end)

	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true)

	local tween = TweenService:Create(CFrameValue, tweenInfo, {Value = part.PrimaryPart.CFrame + Vector3.new(0,1,0)})
	tween:Play()

	tween.Completed:Connect(function()
		CFrameValue:Destroy()
	end)
end

function Placement.getParentModelFromPart(child)
	if child == nil then return end
	if string.match(child.Name, "ParentTile") then
		return child
	else
		return Placement.getParentModelFromPart(child.Parent)
	end
end

function Placement.allowedToHold(player, model)
	if model:FindFirstAncestor(player.UserId) == nil then
		return false
	else
		return true
	end
end

function Placement.isColliding(model, newCFrame)
	local isColliding = false
	
	model:SetPrimaryPartCFrame(newCFrame)
	
	-- must have a touch interest for the :GetTouchingParts() method to work
	local touch = model.BoundingBox.Touched:Connect(function() end)
	local touching = model.BoundingBox:GetTouchingParts()
	-- if intersecting with something that isn't part of the model then can't place
	for i = 1, #touching do
		if (not touching[i]:IsDescendantOf(model) and touching[i].Name == "BoundingBox" and not touching[i]:FindFirstAncestor("fakePart")) then
			isColliding = true
			print("Touching:", touching[i])
			break
		end
	end
	-- cleanup and return
	touch:Disconnect()
	return isColliding
end

return Placement
