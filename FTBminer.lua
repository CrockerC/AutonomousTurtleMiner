--this miner is made to be equipped with a chunk loader, however the turtle chunk loaders do not load when the world loads
--so if the game is closed, when it is reopened, the turtle must be loaded by a chicken chunk loader or a player
--there is no way around this unless the modder or another modder makes an addon that allows the turtle's chunk loader to be loaded on world load
--because of this the turtle is nearly useless on singleplayer worlds, and only useful on servers until the server is shut off.
--aside from this flaw, which cannot really be worked around without having multiple turtles, this turtle is entirely game breaking
--just a few of these running will be equivalent to a high voltage quarry while using very little power and being easy(ish - needs ender pearls and blaze rods) to make
--turtle currently cannot deal with being shutdown under a block of bedrock


--global variables are used because lua does not have addressing so i cant pass the variables' addresses into the recursive function
log = {"none","none","none"} --global log for the turtle to use when digging an ore vein (dont hit me please)
eol = 0 --global scalar for last index of the log, because lua sucks
direction = 0 --global direction for the turtle, again please dont hurt me.
position = {0,0,0} --global position for the turtle, ditto ^^

miningLevel = 6 --level that you want the turtle to mine at,sometimes ores have a min Y level that they spawn at, so you may need to change this to accomidate those ores
--mining level cant be a user input since the turtle is expected to run autonomously
--so the level must be decided before the turtle is ran for the first time

function turtle.recursion()
--the main part of the program, drives the search. is awesome. suck it.

--check forward
  if turtle.mineThis(turtle.ID("forward")) then
   	if turtle.full() then
	     drop()
	end
	
	position = turtle.pilot(1,0,0,position, direction)
	
	--recording the position after turtle.move (or turtle.pilot) is called (do this every time)
	--add position of block to log
	turtle.logPos(position)
	
	--continue recursive function
    turtle.recursion()
	
	--return to previous place
	--get turtle's position for next check
	position = turtle.pilot(-1,0,0,position, direction)
  else
	turtle.hasChecked(0,position,direction)
  end
  
--check up
  if turtle.mineThis(turtle.ID("up")) then
	   if turtle.full() then
	     drop()
	   end
	position = turtle.pilot(0,0,1,position, direction)
	turtle.logPos(position)	
	
    turtle.recursion()
	position = turtle.pilot(0,0,-1,position, direction)
  else
	turtle.hasChecked(1,position,direction)
  end

--check left
  if not turtle.hasbeen(position,direction,-1) then --calls hasbeen function to make sure that the turtle has not already checked that block
  --this is to make sure it does not waste time turning to check a block that its already done
  
    direction = turtle.turn(direction,-1)
    if turtle.mineThis(turtle.ID("forward")) then
	     if turtle.full() then
	       drop()
	     end
	  position = turtle.pilot(1,0,0,position, direction)
	  turtle.logPos(position)
	
      turtle.recursion()
	  position = turtle.pilot(-1,0,0,position, direction)
	else
		turtle.hasChecked(0,position,direction)
	end
	
	direction = turtle.turn(direction,1)
  end
  
--check right
  if not turtle.hasbeen(position, direction, 1) then
  
    direction = turtle.turn(direction,1)
    if turtle.mineThis(turtle.ID("forward")) then
	     if turtle.full() then
	      drop()
	     end
	  position = turtle.pilot(1,0,0,position, direction)
	  turtle.logPos(position)
	
      turtle.recursion()
	  position = turtle.pilot(-1,0,0,position, direction)
	else
		turtle.hasChecked(0,position,direction)
	end
	
	direction = turtle.turn(direction, -1)
	
  end

--check down
  if turtle.mineThis(turtle.ID("down")) then
	   if turtle.full() then
	     drop()
	   end
	position = turtle.pilot(0,0,-1,position, direction)
	turtle.logPos(position)
	
    turtle.recursion()
	position = turtle.pilot(0,0,1,position, direction)
  else
	turtle.hasChecked(2,position,direction)
  end

end

function turtle.ID(dir)
--function to pull the id of a block, returns either the id of the block, or false to indicate failure
  if dir == "up" then
    success, ID = turtle.inspectUp()
  end
  
  if dir == "forward" then
    success, ID = turtle.inspect()
  end
  
  if dir == "down" then
    success, ID = turtle.inspectDown()
  end
  
  if success then
    return ID.name
  end
  return success
end

function turtle.mineThis(ID)
--this function holds the list of blocks that the turtle should mine, decides if id given is one of them and returns t/f
--  print("MineThisID = ",ID)
	
	local oreList = {"minecraft:diamond_ore","minecraft:iron_ore","minecraft:coal_ore","minecraft:gold_ore",
			"ic2:resource","thermalfoundation:ore","minecraft:lapis_ore","minecraft:redstone_ore",
			"appliedenergistics:tile.OreQuartz","minecraft:emerald_ore","appliedenergistics:tile.OreQuartz",}
    
	for i in ipairs(oreList) do
		if oreList[i] == ID then
			return true
		end
	end
  
  return false
end

function turtle.fuel()
--simple function that decides if the turtle needs to be refuelled and then refuels if it needs to
  if turtle.getFuelLevel() < 400 then
    print("Place coal in first slot")
  end
  
  while turtle.getFuelLevel() < 400 do
    turtle.select(1)
    turtle.refuel(64)
	os.sleep(2)
  end
end

function turtle.move(x,y,z) --can only be used to move a single block (ie cant do 1,1,1 or 2,0,0)
--the point of this function is to improve on the turtle's default movement, allowing it to clear obstacles without messing up the movement
--has built in protections to ensure it does not destroy another turtle
--can NOT handle 2 turtles stuck looking at each other trying to move forwards ##edit, may now be able to handle two turtles stuck on eachother
  -- x is forward
  -- y is left
  -- z is up
  
--this function will fail to do anything if it does not recieve an input of 1 from one of the axis, and will scan it from x -> y -> z, the first one with a |1| will be used
  
  if  not (x == 1 or x == -1 or y == 1 or y == -1 or z == 1 or z == -1) then
    return
  end
  
  local count = 0
  
  if x == 1 then
    while not turtle.forward() do
	  while(turtle.ID("forward") == "ComputerCraft:CC-TurtleExpanded") do
	  --if the turtle runs into another turtle
	  --sleep, then if it sleeps for 5 cycles(ie if the other turtle hasnt moved)
	  --try to move around the other turtle
	  --if two turtles are stuck facing eachother they should both move to the left of the other
	  --note to self, i should make this into a function to save lines
		os.sleep(1)
		count = count + 1
	    if count > 5 then
			turtle.move(0,1,0)
			turtle.move(1,0,0)
			turtle.move(0,-1,0)
		end
      end 
	  turtle.dig()
	  turtle.attack()
	end
	return
  end
  
  if x == -1 then
	if not turtle.back() then
		turtle.turnLeft()
		turtle.turnLeft()
		while(turtle.ID("forward") == "ComputerCraft:CC-TurtleExpanded") do
		  os.sleep(1)
		count = count + 1
	    if count > 5 then
			turtle.move(0,1,0)
			turtle.move(1,0,0)
			turtle.move(0,-1,0)
		end
		end 
		while not turtle.forward() do
			turtle.dig()
			turtle.attack()
		end
		turtle.turnLeft()
		turtle.turnLeft()
	end

	--while not turtle.forward() do
	 -- turtle.dig()
	 -- turtle.attack()
	--end

	return
  end
  
  if y == 1 then
	turtle.turnLeft()
	while(turtle.ID("forward") == "ComputerCraft:CC-TurtleExpanded") do
	  os.sleep(1)
		count = count + 1
	    if count > 5 then
			turtle.move(0,1,0)
			turtle.move(1,0,0)
			turtle.move(0,-1,0)
		end
    end 
	while not turtle.forward() do
	  turtle.dig()
	  turtle.attack()
	end
	turtle.turnRight()
	return
  end
  
  if y == -1 then
    turtle.turnRight()
	while(turtle.ID("forward") == "ComputerCraft:CC-TurtleExpanded") do
	  os.sleep(1)
		count = count + 1
	    if count > 5 then
			turtle.move(0,1,0)
			turtle.move(1,0,0)
			turtle.move(0,-1,0)
		end
    end 
	while not turtle.forward() do
	  turtle.dig()
	  turtle.attack()
	end
	turtle.turnLeft()
	return
  end
  
  if z == 1 then
  	while(turtle.ID("forward") == "ComputerCraft:CC-TurtleExpanded") do
	  os.sleep(1)
		count = count + 1
	    if count > 5 then
			turtle.move(0,1,0)
			turtle.move(1,0,0)
			turtle.move(0,-1,0)
		end
    end 
	while not turtle.up() do
	  turtle.digUp()
	  turtle.attackUp()
	end
	return
  end
  
  if z == -1 then
  	while(turtle.ID("forward") == "ComputerCraft:CC-TurtleExpanded") do
	  os.sleep(1)
		count = count + 1
	    if count > 5 then
			turtle.move(0,1,0)
			turtle.move(1,0,0)
			turtle.move(0,-1,0)
		end
    end 
    while not turtle.down() do
	  turtle.digDown()
	  turtle.attackDown()
	end
	return
  end
  
end

function turtle.full()
--simple function to see if a turtle has all 16 slots filled
  local full = false
  turtle.select(16)
 
  if turtle.getItemCount(i) > 0 then
    full = true
  end
 
  turtle.select(3)
      
  if full then
    return true
  end
  
  return false
end

function turtle.compress()
--attempts to organize and compress a turtle's inventory, usually called right after checking if a turtle is full
  local isfull = 0

  for i = 3,16 do
    turtle.select(i)
    if turtle.getItemCount() > 0 then
      turtle.transferTo(isfull+1)
      isfull = isfull + 1
    end
  end
end

function drop()
--simple funciton to drop stuff that has been marked for dropping
--uses turtle.dropThis function to determine if an item should be kept
  for i = 3,16 do
    turtle.select(i)
    if turtle.getItemCount(i) > 0 and turtle.dropThis() then
      turtle.drop()
    end
  end
  turtle.compress()
  turtle.select(16)

  if turtle.getItemCount() > 0 then
	    return true --returns true if the turtle is full
  end
  
  return false --returns false if the turtle is not full
end

function turtle.dropThis()
--decides if an object in the turtle's inventory should be dropped, contains a list of items
--would be better to use a table with a loop than a an elseif ladder
  local ID = turtle.getItemDetail()
  local ID = ID.name
  if ID == "minecraft:cobblestone" then
    return true
  elseif ID == "minecraft:dirt" then
    return true
  elseif ID == "minecraft:gravel" then
    return true
  elseif ID == "minecraft:planks" then
    return true
  elseif ID == "minecraft:fence" then
    return true
  elseif ID == "railcraft:cube" then
    return true
  end
  return false
end

function turtle.turn(direction,turn) 
--is used as a replacement for turtle.turnLeft/Right keeps track of the direciton a turtle is facing relative to the first time turn was called
--returns the direction the turtle is facing
--dir is the current direction of the turtle, turn is the direction of the turn being made.
-- 0 is forward, used for getting the direction without turning
-- -1 is left / left turn
-- 1 is right / right turn
-- -2 or 2 is backwards / turn around

	local dir = direction

	if turn == 1 then
		turtle.turnRight()
	end
	
	if turn == -1 then 
		turtle.turnLeft()
	end
	
	--turn around to the right
	if turn == 2 then
		turtle.turnRight()
		turtle.turnRight()
	end
	
	--turn around to the left
	if turn == -2 then
		turtle.turnLeft()
		turtle.turnLeft()
	end
	
	--cant use numbers outside of -2 - 2
	if turn < -2 or turn > 2 then
		print("turn must be between -2 and 2 inclusive!")
		return dir
	end
	
	--determining the new direction
	dir = dir + turn
	
	--wraps the direction
	if dir < -2 then
		dir = dir + 4
		return dir
	end
	
	--wraps the direction
	if dir > 2 then 
		dir = dir - 4
		return dir
	end
	
	return dir
end

function turtle.rps(position, direction, mv)  --rps stands for relative positioning system
--pos: is a 3d vector of current position
-- x (1) is +forward/-back
-- y (2) is +left/-right
-- z (3) is +up/-down

--returns pos as the new position

-- dir: scalar of direction the turtle is facing
-- 0 is forward
-- -1 is left / left turn
-- 1 is right / right turn
-- -2 or 2 is backwards / turn around

-- mv: scalar of direction the turtle is moving relative to current position and direction
-- 0 is forward
-- 1 is backwards
-- 2 is up
-- 3 is down
	local pos = {position[1],position[2],position[3]}
	local dir = direction
	
	--if moving up determine the new position
	if mv == 2 then
		pos[3] = pos[3] + 1
		return pos
	end

	--if moving down determine the new position
	if mv == 3 then
		pos[3] = pos[3] - 1
		return pos
	end
	
	--if moving backwards, determine the new position
	if mv == 1 then
		if dir == 0  then
			pos[1] = pos[1] - 1
			return pos
		end
		
		if dir == -2 or dir == 2 then
			pos[1] = pos[1] + 1
			return pos
		end
	
		if dir == 1  then
			pos[2] = pos[2] + 1
			return pos
		end
	
		if dir == -1 then
			pos[2] = pos[2] - 1
			return pos
		end
	end
	
	--if moving forwards determine the new position
	if mv == 0 then
		if dir == 0  then
			pos[1] = pos[1] + 1
			return pos
		end
		
		if dir == -2 or dir == 2 then
			pos[1] = pos[1] - 1
			return pos
		end
	
		if dir == 1  then
			pos[2] = pos[2] - 1
			return pos
		end
	
		if dir == -1 then
			pos[2] = pos[2] + 1
			return pos
		end
	end
end

function turtle.logPos(pos) 
--uses a global log variable (don't hit me, lua doesnt have pass by address)
	local i = 1
	
	log[eol + 1] = {pos[1],pos[2],pos[3]}

	eol = eol + 1
	log[eol+1] = {"none","none","none"}
	--for i = 1,eol+1 do
	--	print(log[i][1], log[i][2], log[i][3])
	--end
end

function turtle.hasbeen(position,direction,turn)
--decides if a turtle has already been to the place that is looking at/about to look at (depends on if you put dir in before or after the turn
--although somewhat pointless if the turtle has alraedy turned since the point of these functions is to stop that from
--happening

--pos is current posisiton of turtle in x,y,z, refer to rps for specifics
--dir is direction the turtle is currently looking at relative to starting position, refer to rps for specifics
--turn is the direction the turtle is about to look at relative to current dir, refer to rps for specifics
--log is the matrix of positions the turtle has already been to

--this function should never be called directly, see turtle.pilot for proper use

	local dir = direction + turn
	
	--wrap the direction
	if dir < -2 then
		dir = dir + 4
		turn = dir
	end
	
	--wrap the direction
	if dir > 2 then 
		dir = dir - 4
		turn = dir
	end
	
	turn = dir
	
	local pos = {position[1],position[2],position[3]}
	local k = 1
	
	--if go forward, add 1 to x
	if turn == 0 then
		pos[1] = pos[1] + 1
	end
	
	--if go back, subtract 1 from x
	if turn == -2 or turn == 2 then --2 and -2 are backwards
		pos[1] = pos[1] - 1
	end
	
	--if go left, add one to y
	if turn == -1 then -- -1 is turn left
		pos[2] = pos[2] + 1
	end
	
	--if go right, subtract 1 from y
	if turn == 1 then -- 1 is turn right
		pos[2] = pos[2] - 1
	end
	
	--searching the log for a match to the coordinate thats about to be checked
	while k < eol and not ((log[k][1] == pos[1]) and (log[k][2] == pos[2]) and (log[k][3] == pos[3])) do
		k = k + 1
	end
	
	--if no match is found, return false
	if k >= eol then
		return false
	end
	
	-- if a match is found, return true
	return true
end

function turtle.pilot(x,y,z,position, direction)
--function to combine turtle.move and turtle.rps
--makes it easier to code
--always use [position] and [direction] when calling function, never input constants
	
	local pos = {position[1],position[2],position[3]}
	turtle.move(x,y,z)
	
	if x == 1 then
		pos = turtle.rps(pos,direction,0)
		return pos
	end
	
	if x == -1 then
		pos = turtle.rps(pos,direction,1)
		return pos
	end
	
	if y == 1 then
		pos = turtle.rps(pos,direction,0)
		return pos
	end
	
	if y == -1 then
		pos = turtle.rps(pos,direction,0)
		return pos	
	end
	
	if z == 1 then
		pos = turtle.rps(pos,direction,2)
		return pos	
	end
	
	if z == -1 then
		pos = turtle.rps(pos,direction,3)
		return pos	
	end
end

function turtle.hasChecked(updown, position, direction)
--this function ensures that the turtle does not check blocks multiple times
--note: may be able to be used to replace rps, further testing required EDIT: probably not, but still havent tested
--updown: if turtle us looking up or down, 0 is neither, 1 is up, 2 is down

	local pos = {position[1],position[2],position[3]}
	local dir = direction
	
	--if checking up
	if updown == 1 then
		pos[3] = pos[3] + 1
		turtle.logPos(pos)
		return
	end
	
	--if checking down
	if updown == 2 then
		pos[3] = pos[3] - 1
		turtle.logPos(pos)
		return
	end
	
	--if check forward, add 1 to x
	if dir == 0 then
		pos[1] = pos[1] + 1
	end
	
	--if check left, add one to y
	if dir == -1 then -- -1 is left
		pos[2] = pos[2] + 1
	end
	
	--if check right, subtract 1 from y
	if dir == 1 then -- 1 is right
		pos[2] = pos[2] - 1
	end
	
	turtle.logPos(pos)
end

function turtle.checkForEChest()
--self explanatory
	local success, data = turtle.inspect()
	if data.name == "EnderStorage:enderChest" then
		return true
	else
		return false
	end
end

function turtle.getEChest()
	--used to pick the ender chest back up, only one can be down at a time
	--puts the chest in the empty of the two slots, this is why it is important that the
	--chests be put in correctly, as the turtle has no way to distinguish between the two
	--when used properly should never fail to pick a chest up unless another turtle digs up the chest for some reason
	--used as a startup function
	
	turtle.select(2)
	
	if turtle.compare() == false then
		print("fuel chest missing")
		turtle.dig()
		return
	end
	
	turtle.select(1)
	
	if turtle.compare() == false then
		print("supply chest missing")
		turtle.dig()
		return
	end
	
	print("no chest missing")
end

function turtle.returnToDiamonds()
--used to bring the turtle to diamond level since the turtle has no way to know exactly where to go
--goes down till it hits bedrock, then goes back up to the global variable of miningLevel

	while turtle.ID("down") ~= "minecraft:bedrock" do
		turtle.move(0,0,-1)
		--resetting global variables
		direction = 0
		log = {"none","none","none"}
		eol = 0
		turtle.recursion()
	end
		
	for i = 1,miningLevel - 2 do
		turtle.move(0,0,1)
		--resetting global variables
		direction = 0
		log = {"none","none","none"}
		eol = 0
		turtle.recursion()
	end
end

function turtle.chestFuel()
--places fuel chest down and refuels from the turtle's inventory, picks chest back up

	if turtle.getFuelLevel() > 4000 then
		return
	end
	
	
	--make sure there isnt anything blocking the turtle from placing the chest
	while turtle.detect() do
		turtle.dig()
	end

	
	turtle.select(2)
	turtle.place()

  while turtle.getFuelLevel() < 4000 do
    turtle.suck(64)
	turtle.refuel(64)
	os.sleep(2)
  end
  
	turtle.dig()
	print(turtle.getFuelLevel())
end

function turtle.depositMaterials()
--turtle transfers its inventory to the ender chest, picks chest back up

	--make sure there isnt anything blocking the turtle from placing the chest
	while turtle.detect() do
		turtle.dig()
	end
	
	turtle.select(1)
	turtle.place()
	
	for i = 3,16 do
		turtle.select(i)
		turtle.drop()
	end
  
	turtle.select(1)
	turtle.dig()	
end

function shutdownHandle()
--a bit of wishful thinking about handling a server shutdown that would place a chunk loader when the server is shudown
--one would place a chunk loader in the 3rd slot of the turtle's inventory
--would need to change all of the loops that deal with the turtle's inventory to not manage the loader, ie change 3,16 to 4,16
--unfortunately this is not how computercraft works, when the server is shut down the turtles simply cease functionality, there is no shutdown invoked
	turtle.select(3)
	turtle.place()
	os.shutdown()
end

function turtle.getLoader()
--would retrieve the chunk loader from where the turtle placed it when it shut down
	turtle.select(3)
	if not turtle.detect() then
		print("no chunk loader found, resuming without it")
	end
	turtle.dig()
end

-------------------------------------------
--main

print("Ensure that the miner has the:")
print("		supply chest in the 1st slot")
print("  	fuel   chest in the 2nd slot")
print("The turtle WILL NOT work if these are not configured properly")
print("You have 15 seconds to place the chests in the correct slots")
print("Hold CTRL + T to cancel if you need more time")
print("Then type 'startup' to restart")



os.sleep(15)

print("moving")

--run startup functions to reset turtle
if turtle.checkForEChest() then
	turtle.getEChest()
end
turtle.chestFuel()
turtle.returnToDiamonds()
turtle.depositMaterials()

--continue mining
while true do
	--resetting global variables
	direction = 0
	log = {"none","none","none"}
	eol = 0
  
	turtle.recursion()
	if turtle.full() then
		turtle.depositMaterials()
	end

	turtle.chestFuel()
	
	--using a random number to make sure that the turtle doesnt just go in a straight line until it hits the end of the map
	--the random number reduces the chance that the turtle will go over an area that is has passed over already
	--while not as good as using a math function to decide when to turn, any errors will be quickly resolved by probability
	--should keep it from hitting the edge, if that becomes an issue, reduce the value in math.random
	local rand = math.random(2000)
	if rand <= 1 then
		turtle.turnLeft()
	end
	
	turtle.move(1,0,0)
end
