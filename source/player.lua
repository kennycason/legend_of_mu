
class('Player').extends(playdate.graphics.sprite)


-- local references
local Point = playdate.geometry.point
local Rect = playdate.geometry.rect
local vector2D = playdate.geometry.vector2D
local affineTransform = playdate.geometry.affineTransform
local min, max, abs, floor = math.min, math.max, math.abs, math.floor

-- constants
local dt = 0.05					-- time between frames at 20fps
local GROUND_FRICTION = 0.8			-- could be increased for different types of terrain
local WALK_VELOCITY = 32 			-- velocity change for walk
local MAX_WALK_VELOCITY = 64

local LEFT, RIGHT, UP, DOWN = 1, 2, 3, 4
local STAND, WALK = 1, 2

-- local variables - these are "class local" but since we only have one player this isn't a problem
playerStates = {}
local spriteHeight = 16

local facing = RIGHT

function Player:init()
	Player.super.init(self)

	self.playerImages = playdate.graphics.imagetable.new('img/player')
	self:setImage(self.playerImages:getImage(1))
	self:setZIndex(1000)
	self:setCenter(0.5, 1)	-- set center point to center bottom middle
	self:moveTo(102, 210)
	self:setCollideRect(2, 2, 16 - 4, 16 - 4)
	
	self.position = Point.new(102, 210)
	self.velocity = vector2D.new(0,0)
end


function Player:reset()
	self.position = Point.new(102, 108)
	self.velocity = vector2D.new(0,0)
end



function Player:collisionResponse(other)
	if (other.crushed == true) then
		return "overlap"
	end

	return "slide"
end


function Player:update()

	if playdate.buttonIsPressed("left") then
		self:walkLeft()
	elseif playdate.buttonIsPressed("right") then
		self:walkRight()
	end

	if playdate.buttonIsPressed("up") then
		self:walkUp()
	elseif playdate.buttonIsPressed("down") then
		self:walkDown()
	end

	if playdate.buttonIsPressed("a") then
		level = Level('0_0_house.json')
	end
	
	self.velocity.x = self.velocity.x * GROUND_FRICTION
	self.velocity.y = self.velocity.y * GROUND_FRICTION


	if playdate.buttonJustPressed("A") then
		-- pressed A
	end
	
	if playdate.buttonIsPressed("B") then
		-- presssed B
	end

	self.position = self.position + self.velocity * dt
	
	self:updateImage()
end


function Player:updateImage()
	if facing == LEFT then
		self:setImage(self.playerImages:getImage(STAND), "flipX")
	else
		self:setImage(self.playerImages:getImage(STAND))
	end
end


function Player:walkLeft()
	facing = LEFT
	self.velocity.x = max(self.velocity.x - WALK_VELOCITY, -MAX_WALK_VELOCITY)
end


function Player:walkRight()
	facing = RIGHT
	self.velocity.x = min(self.velocity.x + WALK_VELOCITY, MAX_WALK_VELOCITY)
end


function Player:walkUp()
	-- facing = UP
	self.velocity.y = max(self.velocity.y - WALK_VELOCITY, -MAX_WALK_VELOCITY)
end


function Player:walkDown()
	-- facing = DOWN
	self.velocity.y = min(self.velocity.y + WALK_VELOCITY, MAX_WALK_VELOCITY)
end