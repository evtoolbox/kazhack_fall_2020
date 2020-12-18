local logger = set_lua_logger("baltay")

local BALL_SPEED = 4	-- m/s

local intersector	= reactorController:getReactorByName("intersector")
local ballReactor	= reactorController:getReactorByName("ball")
local bearPosition	= reactorController:getReactorByName("bear_position")
local ballState		= reactorController:getReactorByName("ball_state")
local camera		= viewer:getCamera()

--[[
local prevTime = timer:getTime()
local ballCallback = osg.NodeCallback(function()
	local ballPos = ballReactor.trans
	local cameraPos = camera:getInverseViewMatrix():getTrans()
	local velocity = cameraPos - ballPos; velocity:normalize()
	local t = timer:getTime()

	ballReactor.trans = ballReactor.trans + velocity*(t - prevTime)*BALL_SPEED

	prevTime = t

	return true
end)
--]]

local ballPositions = {
	reactorController:getReactorByName("ball_position_1").trans,
	reactorController:getReactorByName("ball_position_2").trans,
}

ballReactor:subscribeEvent("onShowed", function()
	local startTime		= timer:getTime()
	local startPos		= ballPositions[bearPosition.value > 50 and 2 or 1]
	local cameraPos		= camera:getInverseViewMatrix():getTrans()
	local velocity		= cameraPos - startPos; velocity:normalize(); velocity = velocity*BALL_SPEED

	local ballCallback = osg.NodeCallback(function()
		ballReactor.trans = startPos + velocity*(timer:getTime() - startTime)

		local cameraPos = camera:getInverseViewMatrix():getTrans()
		local distance = math.abs((ballReactor.trans - cameraPos):length())
		logger:warn("ball distance (m) = ", distance)
		logger:warn(math.abs((cameraPos - startPos):length()))

		if distance < 0.2 then
			logger:info("HIT!")
			ballState:setCurrentOption(1)		-- "мяч попал"
			ballReactor:hide()
		elseif math.abs((ballReactor.trans - startPos):length()) > math.abs((cameraPos - startPos):length()) then
			logger:info("MISSED!")
			ballState:setCurrentOption(5)		-- "мяч улетел"
			ballReactor:hide()
		end

		intersector:findIntersection()

		return true
	end)

	ballReactor.node:setUpdateCallback(ballCallback)
end)

-- Color for the ball
local color = osg.Vec4(1.0, 0.0, 0.0, 1.0)	-- Red
local materialUniform = osg.Uniform.Vec4f("ev_MaterialDiffuse", color)
materialUniform:setDataVariance(osg.Object.DYNAMIC)

local ss = ballReactor.node:getOrCreateStateSet()
ss:addUniform(materialUniform)
