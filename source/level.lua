-- import 'CoreLibs/object'
import 'levelLoader'
import 'player'

-- local references
local gfx = playdate.graphics
local Point = playdate.geometry.point
local Rect = playdate.geometry.rect
local abs, floor, ceil, min, max = math.abs, math.floor, math.ceil, math.min, math.max

-- precalculated values
local displayWidth, displayHeight = playdate.display.getSize()
local halfDisplayWidth = displayWidth / 2

-- tile layers
local walls
local bg
local objects

-- the player
local player = Player()

-- constants
local TOP_EDGE, BOTTOM_EDGE, RIGHT_EDGE, LEFT_EDGE = 1, 2, 4, 8

local QBOX_GID = 2
local BRICK_GID = 3

local ENEMY_GID = 1
local COIN_GID = 2

local TILE_SIZE = 16

local MAX_PLAYER_Y = 300	-- if player falls below this height he'll die (or respawn)


-- local variables
local minX = 0
local maxX = 0 -- real value set in init()


-- Global Variables
cameraX = 0
cameraY = 0


-- Level doesn't really need to be a sprite subclass, but it gives us automatic calls to our draw() and update() functions.

class('Level').extends(playdate.graphics.sprite)


function Level:init(pathToLevelJSON)
	
	Level.super.init(self)

	self:setZIndex(0)
	self:setCenter(0, 0)	-- set center point to center bottom
	
	self.coins = {}
	self.enemies = {}
	
	self.layers = importTilemapsFromTiledJSON(pathToLevelJSON)
	
	-- set up local references for the layers we read
	walls = self.layers["walls"]
	bg = self.layers["bg"]
	objects = self.layers["objects"]
	
	self:setBounds(0, 0, bg.pixelWidth, bg.pixelHeight)
	maxX = bg.pixelWidth - displayWidth - TILE_SIZE
	
	self:setupWallSprites()
	self:setupSprites()
	
	-- enemies sprites and coins were already added in importTilemapsFromTiledJSON()
	player:addSprite()	-- we want player's update() to be called before layer's, so add it first
	self:addSprite()
	
	-- start playing background music
	SoundManager:stopBackgroundMusic()
	SoundManager:playBackgroundMusic()

end

--! Utility

-- returns the bounds rect for the tile at column, row
local function boundsForTileAtPosition(column, row)
	return Rect.new(column * TILE_SIZE - TILE_SIZE, row * TILE_SIZE - TILE_SIZE, TILE_SIZE, TILE_SIZE)
end


-- returns a range of currently visible tiles as the tuple (startRow, endRow, startColumn, endColumn)
function Level:rangeOfTilesInRect(rect)

	local startRow = floor((rect.y) / TILE_SIZE + 1) 
	local endRow = ceil((rect.y + rect.height) / TILE_SIZE)
	
	local startColumn = floor((rect.x) / TILE_SIZE  + 1)
	local endColumn = ceil((rect.x + rect.width) / TILE_SIZE)
	
	return startRow, endRow, startColumn, endColumn
end


-- sets the tile to the new value and updates our wall edges array
function Level:setTileAtPosition(column, row, newTileValue)
	-- The tilemap isn't in a sprite, so we have to tell the display list that it needs to redraw the changed tile.
	-- Also, sprite.addDirtyRect uses screen instead of world coordinates so we also have to add the offset
	gfx.sprite.addDirtyRect(column * TILE_SIZE - TILE_SIZE + cameraX, row * TILE_SIZE - TILE_SIZE, TILE_SIZE, TILE_SIZE)
	walls.tilemap:setTileAtPosition(column, row, newTileValue)
end


--! Sprite Movement

function Level:movePlayer()
	if player.position.y > MAX_PLAYER_Y then	-- fell off of the world! Respawn at the beginning
		player:reset()
		player:moveTo(player.position)
		return
	end
	
	local collisions, len
	player.position.x, player.position.y, collisions, len = player:moveWithCollisions(player.position)
	
	
	for i = 1, len do
		
		local c = collisions[i]

		if c.other.isWall == true then
			
			if c.normal.y < 0 then	-- feet hit
				player.velocity.y = 0
			elseif c.normal.y > 0 then	-- head hit
				-- player.velocity.y = 10 -- start with some initial downward velocity when a barrier above is hit
			end
			
			if c.normal.x ~= 0 then	-- sideways hit. stop moving
				player.velocity.x = 0
			end

		end
		
		-- elseif c.other:isa(Coin) then	-- player's collisionResponse returns "overlap" for coins
		-- 	self:collectCoin(c.other)
	end
	
end


-- function Level:moveEnemies()
	
-- 	local enemies = self.enemies
-- 	for i=1, #enemies do
-- 		local enemy = enemies[i]
		
-- 		if not enemy.crushed then		
-- 			enemy.position.x, enemy.position.y, cols, cols_len = enemy:moveWithCollisions(enemy.position.x, enemy.position.y)
			
-- 			for i=1, cols_len do
-- 				local col = cols[i]      
-- 				if col.normal.x ~= 0 then -- hit something in the X direction
-- 					enemy:changeDirections()
-- 				end
-- 			end
-- 		end
-- 	end
	
-- end


-- moves the camera horizontally based on player's current position
function Level:updateCameraPosition()
	local newX = floor(max(min(player.position.x - halfDisplayWidth + 60, maxX), minX))
	
	if newX ~= -cameraX then
		cameraX = -newX
		gfx.setDrawOffset(cameraX,0)
		playdate.graphics.sprite.addDirtyRect(newX, 0, displayWidth, displayHeight)	

		--[[
		 Possible optimization: Instead of redrawing the entire screen when it scrolls, draw the previous frame at an offset
		 and only mark the exposed area as dirty.
		
		local d = newX + cameraX
		cameraX = -newX
		gfx.setDrawOffset(cameraX,0)
		gfx.getDisplayImage():draw(newX,0)
		
		if d > 0 then
			playdate.graphics.sprite.addDirtyRect(newX + displayWidth - d, 0, d, displayHeight)	
		else
			playdate.graphics.sprite.addDirtyRect(newX, 0, -d, displayHeight)	
		end
		]]
	end
end


--! Sprite library callbacks

function Level:update()
	self:movePlayer()
	-- self:moveEnemies()
	self:updateCameraPosition()
end


function Level:draw(x, y, width, height)
	bg.tilemap:draw(0, 0)
	walls.tilemap:draw(0, 0)
end


--! Sprite setup (enemies)


-- function Level:addEnemySprite(column, row)
-- 	local tilePosition = boundsForTileAtPosition(column, row)
-- 	local newEnemy = Enemy(tilePosition)
-- 	newEnemy:addSprite()
-- 	self.enemies[#self.enemies+1] = newEnemy
-- end



function Level:setupSprites()
    -- load from objects layer
	-- local tilemap = sprites.tilemap	
	-- local width, height = tilemap:getSize()

	-- for column = 1, width + 1 do
	-- 	for row = 1, height do
	-- 		local gid = tilemap:getTileAtPosition(column, row)
			
	-- 		if gid ~= nil and gid > 0 then
	-- 			-- if gid == COIN_GID then
	-- 			-- 	self:addCoinSprite(column, row)
	-- 			-- elseif gid == ENEMY_GID then
	-- 			-- 	self:addEnemySprite(column, row)
	-- 			-- end
	-- 		end
			
	-- 	end
	-- end
	
end


--! Wall setup

function Level:setupWallSprites()
	
	-- for a real game, you'd probably want to dynamically load and unload sprites as the player moves around the level
	-- for the purposes of this demo we'll just load them all

	local tilemap = walls.tilemap	
	local width, height = tilemap:getSize()
	
	local x = 0
	local y = 0
	
	for row = 1, height do
		local column = 1
		while column <= width do
		
			local gid = tilemap:getTileAtPosition(column, row, gid)

			if gid ~= nil and gid > 0 then
				
				local startX = x
				local cellWidth = TILE_SIZE
				
				-- add "wall" sprites for bricks and question blocks
				if gid == BRICK_GID or gid == QBOX_GID then
					local w = gfx.sprite.new()
					w:setUpdatesEnabled(false) -- remove from update cycle
					w:setVisible(false) -- invisible sprites can still collide
					w:setCenter(0,0)
					w:setBounds(startX, y, cellWidth, TILE_SIZE)
					w:setCollideRect(0, 0, cellWidth, TILE_SIZE)
					w:addSprite()
					w.gid = gid
					w.column = column
					w.row = row
					w.isWall = true
				end
			end
			x += TILE_SIZE
			column += 1
					
		end
		
		x = 0
		y = y + TILE_SIZE
	end
	
	-- group the wall/floor/pipe areas into larger areas and add wall sprites for them so we have fewer total sprites
	local walls = gfx.sprite.addWallSprites(tilemap, {1, 2, 3})
	for i = 1, #walls do
		local w = walls[i]
		w.isWall = true
	end
	
end

