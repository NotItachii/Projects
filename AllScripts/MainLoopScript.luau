local players = {}
local moduleScript = require(game.ReplicatedStorage.ModuleScript) --Requires pretty much requires the returned value of a module script
--Good thing about this is that i dont need to do require every time to update it, its pretty much self updating and the values will without having to repeat the code


task.spawn(function() --task.spawn starts a new thread, this code will run independently of the rest of the code in a new thread.
	--we can view threads as treadmills, the rest of the code runs on one singular treadmill, while this piece of code has its own independent treadmill it runs on
	--the reason im doing this instead of writing a function to update the player table which is a must because unlike require up there, the player table needs to be continuously updated or else its value will remain static 
	--is because i dont need to waste space and say GetPlayers in every single function that requires it, now every function can just simply do #players and it will know exactly how many players there are at the moment it called
	while true do --a while loop keeps repeating the same lines of code as long as a certain condition is met. 
		--The issue with while loops is that they're keen to breaking the code and having it stuck on one repetitive cycle, only if handled correctly can you avoid that
		task.wait()
		players = game.Players:GetChildren() --to explain getChildren once and for all so i dont have to for the remaining of the script, it retrieves every child of the said parent. GetChildren ALWAYS returns a table. GetDescendants does too but it also retrieves CHILDREN of the CHILDREN.
	end
end)


--Tweakable Variables

local minNumberOfPlayers = 1 -- Minimum amount of players to start intermission
local IntermissionTimerNumber = 4 --How long the intermission will last
local RoundLength = 30 -- How long one round will last 

--EXTRA FUNCTIONS FOR READABILITY

local function ShuffleSpawnPoints(spawnPoints) --Parameter retrieves the spawnPoints 

	for i = #spawnPoints, 1, -1 do --this for loop iterates backwards, starting from the highest number and subtracting by 1
		local randomNum = math.random(i) --math.random chooses a random number between two, now here I only had to set [i] as the parameter because the for loop itself defined between which 2 numbers math.random chooses
		spawnPoints[i], spawnPoints[randomNum] = spawnPoints[randomNum], spawnPoints[i] --Here this is were we set the value aka shuffle, we exchange the random number with the index itself
		--Note: the [i] right above this comments found inside the spawnPoints does NOT refer to the i up there in the "for i=" part, it literally refers to the index WITHIN the table itself. WE SWITCH that index value with the new received value. So we SHUFFLE the spawnPoints

	end
	return spawnPoints --We variablise this function from where its called and we get the returned value within that variable

end
--[[
For the love of God I could not figure out how to simply teleport each player to a different spawnpoint every time, without complicating the fuck out of it
This up there, the shufflespawnpoint function in short utilises something called fisher yates shuffle, its an algorithm used to shuffle a sequence, a finite one.
By having a for loop iterate through all the spawnpoints starting from the highest indexed number down to the lowest, it chooses a random number between 1 and the amount of spawnpoints there is,
it sets the current index to that randomNumber, and because the for loop goes in reverse, starting from 4 and subtracting by 1, next number will be 3. and the random number will only give 1 between 3 (because I used [i] parameter within math random so its different every iteration)
so it either sets the index value to the same number or lower, not above. What a fucking life saver.

]]

local function teleportPlayers()

	local SpawnPointTable = game.Workspace.Map.Spawns:GetChildren()
	local spawnPoints = ShuffleSpawnPoints(SpawnPointTable)
	local weapons = game.ReplicatedStorage.Weapons:GetChildren()


	for plri,plr in pairs(players) do

		local inv = plr:FindFirstChild("Inventory") --FindFirstChild is a way to look for something that might not exist, and in case it doesnt, then it doesnt break the script
		--Inventory that it's looking for is a folder, that folder is created when the player joins the game, because its created through a script and its not something the player by default is joined with, there might be a chance it doesnt exist

		local equipped = inv:FindFirstChild("CurrentlyEquipped") --same goes for CurrentlyEquipped which is just a string value that stores the players currently equipped weapon
		local character = plr.Character --gets the character from Player, so fucking simple unlike viceversa where u do GetPlayerFromCharacter
		local hum = character.HumanoidRootPart --HumanoidRootPart is whats used to teleport players around, not Humanoid, and not their character either, but the HumanoidRootPart

		if hum then --gotta check if the player still is there

			for spwni,spawnP in pairs(spawnPoints) do --an iteration within an iteration, it goes through all the spawnpoints OF THE CHOSEN MAP
				if plri == spwni then --here's the magic, remember the random shuffle? Before I wrote that part of the script, the game would teleport each player in the same spot every time because their index will always match the same static index of every spawn point
					--god kill me if there's a simpler way to randomly  teleport a player between spawnpoints every time
					hum.CFrame = spawnP.CFrame + Vector3.new(0, 1, 0) --CFrame, what is a CFrame? CFrame stores player's current position AND orientation. Unlike Position which only stores, well Position.
					--I could as well use MoveTo, to move the player but it wouldnt match the orientation, the player would teleport orientated same way no matter where the spawnpoint itself is orientated
					--By utilising cframe instead, players orientation matches the orientation of the spawnpoints its teleporting to.
					--Adding Vector3.new(0, 1, 0) takes the current Y value of the spawnPoint its teleporting to AND adding 1 stud in height, that way it prevents the player from teleporting literally inside the part.
					for i,v in pairs(weapons) do --now we iterate through a weapons table that was defined up there, Weapons table is found within replicated Storage and has all weapons available within the game.
						--If the player currently has a weapon equipped and that weapon actually exists and is part of the game, the server will clone it inside his inventory
						if v.Name == equipped.Value then --takes the weapons name and compares it to the string value Equipped
							local clonedSword = v:Clone() --Clone clones whatever we set it to clone
							clonedSword.Parent = plr.Backpack --but because cloning it isnt enough, we need to set its parent to the players backpack, not characters
							clonedSword.Name = "Sword" --Despite the chance of every player using a different sword, its so much fucking easier to name the sword sword no matter which one it is so the server can look through the same string value for every player again later and remove the swords.

						end
					end

				end
			end
		end
	end
end

local function TableAndKIll(alivePlayers) --what this table does is handles when the player dies DURING THE GAME

	if #alivePlayers > 1 then --the parameter passed "alivePlayers" is a table found inside a moduleScript (it has to be inside a moduleScript so it can handle other things like spectating)
		--say theres two players left, one dies, the script checks if there are still more than 2 players inside the table, only then does it remove this player
		for i,plr in pairs(players) do --iterated through the players table
			local hum = plr.Character.Humanoid --gets humanoid of the player
			if hum then --if hum exists
				--IF HUMANOID DIES ITS REMOVED FROM THE TABLE
				hum.Died:Connect(function() --triggers when a player dies of course, its an event made for that
					local index = table.find(alivePlayers, plr) --gets the index of the player thats still in the alivePlayers table
					if index then --if it finds the players index

						table.remove(alivePlayers, index) --it removes the player of course, cause hes dead hes no longer alive his place is not within alivePlayers table, semantically and logically
						task.wait(0.5) --stops the task for certain amount of miliseconds, more efficient way of waiting unlike wait()
						--i put this here so it would prevent duplicate incrememnts down there, for some reason it works so we dont touch


					end

					local tag = hum:FindFirstChild("creator") --tags are a way to identify who killed a player. Whenever a player attacks another player, within the attacked player a tag is created, storing the last player who damaged that player
					--INCREMENTS KILLERS VALUE TO PLUS ONE
					if tag then --if such tag does exist aka if the weapon used has in build function of tagging
						local killer = tag.Value --it finds the killer by getting the value of the tag which is a string value
						killer.leaderstats.Kills.Value += 1 --increments that killers kill value by 1
						tag:Destroy() --destroys the tag to prevent duplicate incrememnts accidentally
					end
				end)
			end
		end
	end
end

local function randomMap() --now this here is an important function, it chooses a RANDOM MAP OUT OF THE AVAILABLE MAPS AND PUTS IT INSIDE A CHOSENMAPS TABLE, ITS NAME IS SELF EXPLANATORY
	local allMaps = moduleScript.Maps --allMaps is a table found inside the module script that contains ALL the available maps of the game ALL OF THEM
	local chosenToVoteMaps = {} --now THIS HERE is a different table, its value is empty for now until the game randomly chooses two maps and puts them here


	local randomVariable --this variable cant be set within a while loop because its value needs to be static until its supposed to change again

	while #chosenToVoteMaps < 2 do --this while loops condition pretty much says "until the amount of maps chosen is TWO I wont stop running the code inside me hehhe"
		for i,v in pairs(allMaps) do --iterates through ALL THE AVAILABLE MAPS

			randomVariable = math.random(1, #allMaps) --math.random as i've said before chooses a random number between 1 and the amount of available maps. The code is expandable meaning right now i can simply add another map within the moduescript, put its physical properties inside RepStorage and boom im done, easy.
			--as random as my ex was when she decided one day she doesnt love me anymore
			if randomVariable == i then --i love comparing indexes, if the random number chosen matches the index of the currently iterated map
				if not table.find(chosenToVoteMaps, v) and #chosenToVoteMaps < 2 then --and if the map is not already within the table and the number of chosen maps still is below the required
					table.insert(chosenToVoteMaps, v) --then we insert the map within this table

				end
			end
		end
	end

	return chosenToVoteMaps --once the while loop is over which means the condition of having two random maps to vote in between minimum, we just return the table to the function caller


end

local function enableSpectate()
	game.ReplicatedStorage.Spectate:Clone().Parent = game.StarterGui.ScreenGui --Clones and parents the spectate gui to the startergui, the reason I chose startergui is cause its easy to also remove it plus player keeps it if they reset chararacter after theyre out the game while the game is still ongoing
	game.ReplicatedStorage.Press:Clone().Parent = game.StarterGui.ScreenGui --another spectate important button being cloned
end
--I decided to functionise many lines of code i repeated multiple times in the last main function, also easy to modify like this in the future
local function disableSpectate()
	if game.StarterGui.ScreenGui:FindFirstChild("Spectate") and game.StarterGui.ScreenGui:FindFirstChild("Press") then --removes spectate by destroying the frame inside startgui
		game.StarterGui.ScreenGui:FindFirstChild("Press"):Destroy()
		game.StarterGui.ScreenGui:FindFirstChild("Spectate"):Destroy()
	end
end

local function RestartDestroyMap() --Another multitude lines of code repeated few times
	local map = game.Workspace:FindFirstChild("Map") --retrieves the map found physically inside workspace using findfirstchild 
	map:Destroy() --Destroys it
	moduleScript.MapsForVote.Map1.Name = "" --restarts module script variables so the next loop starts off fresh
	moduleScript.MapsForVote.Map2.Name = ""
	moduleScript.MapsForVote.Map1.Players = {}
	moduleScript.MapsForVote.Map2.Players = {}
end

local function removeWeapon(plr) --more lines of code that repeat that u put in a function
	if plr.Backpack:FindFirstChild("Sword") then --checks for a sword
		plr.Backpack:FindFirstChild("Sword"):Destroy() --destroys it
	elseif plr.Character:FindFirstChild("Sword") then --now because the player can have their sword EQUIPPED we have to check that too
		plr.Character:FindFirstChild("Sword"):Destroy() --and if they do we destroy it. Destroy() deletes the instance 
	else
		print("Sword not found")
	end
end

local function resetAttributeValues() --these reset attribute values back to default so when the loop starts again it's all where it should be
	game.Workspace:SetAttribute("GameReady", false)
	game.Workspace:SetAttribute("Winner", "")
	game.Workspace:SetAttribute("GameTimer", RoundLength)
end
--MAIN THREE FUNCTIONS THAT RUN THE GAME


--[[
If i may go over while loops. This entire script is a one while loop you can find it down there. It goes through one stage of the game
to another stage etc etc. My functions also have while loops, some conditions have to be met before the script proceeds. Every while loop
has a task wait and a clear exit, a condition which will be met in one way or another, a condition impossible to NOT be met. Meaning every while loop
despite being nested will not interrupt the outer loop, no loop will run forever (EXCEPT WAITING FOR PLAYERs because goddamn you need players for the game) and I don't see nothing wrong with utilising while loops like this unless
they have the potential to go for infinitum aka they never yield (with the exception of the first loop WaitingForPlayers I mean come on).


]]

local function waitingForPlayers() --this function is the start of the massive while loop, makes sure there are enough players to start the game
	game.Workspace:SetAttribute("NotEnough", true)
	while true do --a while loop that for now runs infinitively
		task.wait()
		if #players >= minNumberOfPlayers then --eventually at some point, the amount of players will reach the minimum required, meaning it wont run forever, only unless theres literally one guy in the server but obviously lmao

			game.Workspace:SetAttribute("NotEnough", false) --I have multiple attributes within my workspace that handle GUI related updates. Because AttributeChange can be caught by the client, im utilising it to update the main GUI panel that represents the current stage of the game

			break --BREAKS THE LOOP and proceeds with the next function

		end

	end
end

local function gameBegins() --once there are enough players we proceed

	game.Workspace:SetAttribute("Intermission", IntermissionTimerNumber) --this here sets the attributes value Intermission to the desired intermissiontimernumber
	game.Workspace:SetAttribute("GameTimer", RoundLength) --and this here sets gamestimer aka the roundlength to the set roundlength inside the variable found at the top

	local timer = true --a condition for a while loop
	local number = IntermissionTimerNumber --how long the intermission will last is set to the value of variable at the top of the script

	while timer do --while timer is true we do
		game.Workspace:SetAttribute("Intermission", number) --continuously update the GUI to match the timer so everyone knows how long intermission will last
		print(number) --this is just for my sake while i was writing the script  i could remove it but hey its proof that i wrote it in a way no?
		number = number - 1 --subtracts the timer by 1
		if #players < minNumberOfPlayers then --now this HERE is a fail check, see during intermission at ANY POINT, players could leave and there could only be one left, now instead of proceeding with the game we go back to the first function that waits until there are enough players
			waitingForPlayers() --first function in the while loop!
			break --once this condition is met this while loop ends and we go back because well there are not enough players
		end
		task.wait(1) --we wait 1 second before subtracting the timer
		if number == 0 then --checks whether the timer had reached its end
			timer = false --DISABLES THE WHILE LOOP
			game.Workspace:SetAttribute("Intermission", number) --updates the gui one last time
			task.wait(1)
			game.Workspace:SetAttribute("VotingStage", true) --updates the gui letting the players know VotingStage is happening

		end
	end


end

local function PreparingVote() --this function here handles the map voting stage of my round based script

	local chosenMapsToVote = randomMap() --what randomMap does i already explained it up there, this caller retrieves the value
	local mapsForVote = moduleScript.MapsForVote --now this is important, its the third table inside the module script that handles the votingstage part, what it does is it takes the two maps that server chose, and then puts them inside a table
	local mapList = game:GetService("ServerStorage").Maps:GetChildren() --this here handles the actual physical maps, we get all the maps within serverstorage



	local name1 = chosenMapsToVote[1] --now chosenmapstovote simply stores string values, two string values which are two maps server chose to vote in between
	local name2 = chosenMapsToVote[2]

	mapsForVote.Map1.Name = name1 --this here UPDATES the modulescript part's information to the chosen maps aka its name
	mapsForVote.Map2.Name = name2

	local vote = game.ReplicatedStorage.Vote --fetches the gui frame from repStorage


	local function cloneChosenMap()
		local voteClone = vote:Clone()  --clones the gui
		voteClone.Map1.Text = name1  --changes gui's information like whats the name of the two maps that are being voted for
		voteClone.Map2.Text = name2
		voteClone.Map1.Name = name1
		voteClone.Map2.Name = name2
		return voteClone
		
	end
	
	local StarterGuiClone = cloneChosenMap()
	StarterGuiClone.Parent = game.StarterGui.ScreenGui
	
	for i,v in pairs(players) do --iterates through all the players
		local PlayerGuiClone = cloneChosenMap()
		PlayerGuiClone.Parent = v.PlayerGui.ScreenGui 
	end

	local timer = true --another timer loop
	local number = 10 

	while timer do

		print(number) --again this print was for my sake while scripting
		number = number - 1 --subtracts the value
		task.wait(1)
		if number == 0 then --once the timer is done
			timer = false --ends the while loop
			for i,v in pairs(players) do
				local frame = v.PlayerGui.ScreenGui:FindFirstChild("Vote") --finds the gui we just cloned inside the player
				
				if frame then
					frame:Destroy() --destroys the gui for voting
					StarterGuiClone:Destroy()
				end
				game.Workspace:SetAttribute("VotingStage", false) --updates the main GUI that displays the current stage of the system
			end
			task.wait(1)
		end
	end

	local finalVoteNumber1 = #moduleScript.MapsForVote.Map1.Players --this here takes the amount of players that have voted for this map by using hashtag which retrieves the number of values stored inside a table
	--MapsForVote is a table which includes Map1 which is also a table which includes Players which is also a table, Whenever a player votes its put inside this Players table. Instead of simply having a VoteNumber int value, this here allows you to fetch info abt people who voted too,
	--and maybe if I want to I can add small little pngs of profile pictures of the players who voted for this map
	local finalVoteNumber2 = #moduleScript.MapsForVote.Map2.Players

	--BECAUSE the server ONLY CHOOSES 2 MAPS TO VOTE IN BETWEEN, I CAN LET MYSELF HANDLE THE COMPARISON PART USING three IF STATEMENTS.
	local function CloneMap(chosenMap)
		for i,v in pairs(mapList) do --iterates through the actual physical maps inside the maps folder
			if v.Name == chosenMap then --if the name of the map matches the name of the chosen map which it does of course
				local clonedMap = v:Clone() --it clones the map
				clonedMap.Parent = workspace --parents it to the workspace
				clonedMap.Name = "Map" --names the map MAP, so when I try to retrieve the spawnpoints the game simply looks for "Map" instead of a specific named map
				teleportPlayers() --this function was already explained, ONCE the map was cloned to workspace only then can I look at workspace for MAP and then do with its spawnpoints as I want
				game.Workspace:SetAttribute("GameReady", true)--every SetAttribute in my script is simply used to update the GUI cause it looks nicer and more refined, but it isnt necessary for the backend of the script at all
				--What every attributechangedsignal updates is found within a localscript
				print("265")
			end
		end 
	end
	--"What if there are 10 maps?" There won't be that's the point, only 2 maps can be voted for. Tge game can have as many maps as it wants, up to 50 maps, the server chooses only 2 random maps out of all the available maps
	--Because only 2 maps can be voted for, i can use if statements like this to handle 3 possible scenarios.
	if finalVoteNumber1 > finalVoteNumber2 then --first scenario if map1 has more votes than map2 aka if map1.Players table has more players in it than the opposing map
		CloneMap(name1)
		print("271")
	end

	if finalVoteNumber2 > finalVoteNumber1 then --same shit for the first condition, but if map 2 has more votes
		CloneMap(name2)
		print("277")
	end

	if finalVoteNumber2 == finalVoteNumber1 then --final condition if equal amount of votes
		CloneMap(name2)--I had it choose map 2 anyway, otherwise if desired I can have it choose on random. But why does THIS have to be random? it doesnt
		print("282")
	end



	--so three possible scenarios and only three, are handled easily




end

local function gameOnGoing() --function that dictates when the game will end and all the events that can happen in the middle of the game
	
	local timerGameEnd = true --important variable set to true, this used to be a while loop this entire function but i switched it up and made it a for loop
	local gameTimer = RoundLength
	game.Workspace:SetAttribute("GameTimer", RoundLength) --sets the gametimer to the roundlength

	enableSpectate() --enable spectate was explained above and as the name suggests allows players to spectate when they die

	local spawnPoints = game.Workspace.Map.Spawns:GetChildren() --fetches the current maps spawn points
	local alivePlayers = moduleScript.AlivePlayers --fetches alivePlayers table

	--INSERTS PLAYERS INSIDE THE TABLE
	for i,plr in pairs(players) do --iterates through all the players
		print(#players)
		print(alivePlayers)
		if not table.find(alivePlayers, plr) then
			table.insert(alivePlayers, plr)
			--adds them to the table
		end
	end
	
	--more practical putting all the players within the table that are part of the game, remove them when they die. Spectate scripts also uses
	--alivePlayers table to loop through all the players that are apart of the game  rather than the dead ones who lost too

	for i = gameTimer, 0, -1 do --this for loop runs first before it proceeds to the second possible outcome
		TableAndKIll(alivePlayers) -- reacts whenever a player dies, function was explained up there
		game.Workspace:SetAttribute("GameTimer", i) --every iteration it updates the timer to i, SetAttribute events are frontend only, they dont affect the backend at all. Simply to let the players know how much time is left
		if #alivePlayers <= 1 then --every iteration it checks whether the amount of players within the table is equal to 1 or below. If one player is left it ends the game. "#" in front of the table defines how many entries are within the table
			task.wait(1) --this isn't really necessary, but it looks nicer when it takes a second to load the winner and all instead of doing it instantaniously once only one player is in the table
			disableSpectate() --function explained above, disables the ability to spectate, removes the GUI from startergui
			game.Workspace:SetAttribute("Winner", alivePlayers[1].Name) --displays the winner to everyone, local script catches the attribute changed signal
			
			
			
			if alivePlayers[1] then --a check since the player can the game, and leave and then the game wont find him and teleport him, incrememnt all these values etc which would freeze the script
				alivePlayers[1]:FindFirstChild("leaderstats"):FindFirstChild("Coins").Value += 20 --incrememnts winners coins by 20 
				alivePlayers[1].leaderstats.Wins.Value += 1 --incremements leaderstats wins by 1 cause well they won
				moduleScript.addEXP(alivePlayers[1], math.random(100, 200)) --modulescript handles the backend of addingxp, how the exp is added and calculated is done inside the module script. For the purposes of this application I'll put the snippet of the code that handles that below the main while loop (line 452), separated by the comments
				removeWeapon(alivePlayers[1])
				task.wait(3)
				alivePlayers[1].Character.HumanoidRootPart.CFrame = game.Workspace.SpawnLocation.CFrame + Vector3.new(0, 1, 0) --cframe more practical since it updates orientation too, vector y axis is increased by one so they dont get stuck in the spawnpoint
				alivePlayers[1].Character.Humanoid.Health = 100
				table.remove(alivePlayers, 1) --removes the last guy left from the table, table.remove takes the index, so you can't remove the value itself only through index of the value or they key if its dictionary.
				--One way to get the index is by variablising local index = table.find("table", "value") and then doing table.remove("table", index) 
			end
			



			resetAttributeValues() --resets all the attributes to the default
			RestartDestroyMap() --destroys the map and resets necessary variables and tables
			
			timerGameEnd = false --disables the timerGameEnd so the if function below doesn't go off and the script resets the while loop
			break
		end	
		
		game.Players.PlayerRemoving:Connect(function(plr) --for some reason simply saying alivePlayers = {} doesn't reset it? so i had it iterate through all the players and remove them manually quickly
			for i = #alivePlayers, 1, -1 do --goes in backwards
				if alivePlayers[i] == plr then  --finds the player who left within the table, removes him from the table
					table.remove(alivePlayers, i)
				end
			end
		end)
		task.wait(1) --for loop takes a second to iterate again

	end			


	if timerGameEnd == true then --in case the for loop ended before the first IF condition was full filled which means the timer ended and nobody won
		disableSpectate() --disables the spectate 
		game.Workspace:SetAttribute("Winner", "None") --displays the winner to none
		task.wait(3) --waits 3 seconds
		for i,plr in pairs(players) do --iterates through all the players, removes their weapon and teleports them. 
			
			--simpyl for safety reasons I had it iterate through all the players instead of just through alivePlayers
			local character = plr.Character
			if character then
				
				removeWeapon(plr)
				character.HumanoidRootPart.CFrame = game.Workspace.SpawnLocation.CFrame + Vector3.new(0, 1, 0)

			end
			for i = #alivePlayers, 1, -1 do
				if alivePlayers[i] == plr then
					table.remove(alivePlayers, i)
					print(alivePlayers)
				end
			end
		end

		resetAttributeValues()
		RestartDestroyMap()
	end



end



--The loop

while true do
	waitingForPlayers()
	gameBegins()
	PreparingVote()
	gameOnGoing()
end




---THIS PART HAS NOTHING TO DO WITH THE SCRIPT ABOVE. REFER TO LINE: 378---

--SNIPET OF THE CODE FOUND WITHIN THE MODULE SCRIPT THAT INCREMENTS EXP FOR CLARIFICAION PURPOSES--

module.addEXP = function(plr, amount) --when called, two paramaters are passed, the player whose xp is being given, and the amount
	
	local currentEXPValue = module.PlayerData.Experience[plr.UserId] --fetches the current XP value before incrementation
	local currentLevel = module.PlayerData.Levels[plr.UserId] --fetches the currentLevel of the player
	local calculatedAmount = currentEXPValue + amount --calculates how much XP the player would have when we incremement his XP


	module.PlayerData.Experience[plr.UserId] = calculatedAmount --we SET his current exp to the calculated amount (eg. if he had 20 xp, and the got 40xp through this function, the calculatedAmount is 60)


	task.wait()
	for i,v in pairs(module.LevelingSystem) do --LevelingSystem is a table that holds all the available Levels and XP REQUIRES
		while true do --a while loop here is necessary to handle situations in which leftOverXP post levelUp still is enough to level up again
			if calculatedAmount >= v.ExpRequired and currentLevel <= v.CurrentLevel then --Checks if his XP is enough to level him up, it does so by checking the EXP required for all the stored in levels and also checks whether his current LEVEL is below the level that's he's about level up to
				module.PlayerData.Experience[plr.UserId] = calculatedAmount - v.ExpRequired --Subtracts the exp
			
				currentLevel += 1 --ADDS HIM THE LEVEL
				module.PlayerData.Levels[plr.UserId] = currentLevel --sets his level inside the playerdata table the current level
				plr:WaitForChild("leaderstats"):WaitForChild("Levels").Value = currentLevel --this is simply for frontend kinda, my leaderstats table fetches info from playerData inside module script
				
			else
				break
			end
		end
	end





--This is necessary though for the function above, for clarification purposes this is also found inside the module script
module.PlayerData = {
	Inventory = {},
	Equipped = {},
	Levels = {},
	Experience = {}
}

module.LevelingSystem = {
	Level1 = {
		CurrentLevel = 1,
		ExpRequired = 100
	},
	Level2 = {
		CurrentLevel = 2,
		ExpRequired = 300
	},
	Level3 = {
		CurrentLevel = 3,
		ExpRequired = 600
	},
	Level4 = {
		CurrentLevel = 4,
		ExpRequired = 1200
	},
	Level5 = {
		CurrentLevel = 5,
		ExpRequired = 1800
	}
}

