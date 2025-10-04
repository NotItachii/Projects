--[[
Welcome to my amazing script! This was my first (final) prototype of a working system I've made for a round based game.
It's pretty simple, it contains 4 actually main functions that are being looped continuously within a while loop. 
Props to a random discord user who had given me tips on how to handle game related timers and statelog updates for GUI utilising
propertyChangedSignal which was a life saver. I might one day edit this script and add another way might even be more functionable which is
FireAllClients to update the client sided GUI but I'll see. Anyhow this is still probably a very sucky script and mind you im still a beginner! So 
have mercy :)) If you have any suggestions please please don't be shy and request a pull with the explanation!



]]


--EASIER WAY TO UPDATE PLAYERS TABLE TO HAVE SERVER REACT IN REAL TIME UTILISING TASK.SPAWN

--[[
ps I know this might not be considered the best way to do so by many, maybe it might be better to have a separate function that when called
updates the table instead of the table being updated on an entirely different thread, but it just feels more, faster performance wise at least?
when there's a separate independent threat doing continuous update of the most important table currently instead of having it update only when necessary
but hey maybe i am stupidly wrong and this is stupidly wrong to do so please let me know if so 
]]

--idk how many lines of code you wish me to explain so ill skim through them fast!

local players = game.Players:GetChildren()
local moduleScript = require(game.ReplicatedStorage.ModuleScript) --requires the module script


task.spawn(function()
	while true do
		task.wait()
		players = game.Players:GetChildren() --starts a new thread and updates player table continuously
	end
end)


--Tweakable Variables

local minNumberOfPlayers = 3 --min num of players required to start 
local IntermissionTimerNumber = 20 --intermission timer 
local RoundLength = 60 --how long the round will last

--EXTRA FUNCTIONS FOR READABILITY

local function teleportPlayers(spawnPoints)
	
	local spawnPoints = game.Workspace.Map.Spawns:GetChildren()
	
	for plri,plr in pairs(players) do --iterates through player table

		local inv = plr:WaitForChild("Inventory")
		local equipped = inv:WaitForChild("CurrentlyEquipped")
		local character = plr.Character
		local hum = character.HumanoidRootPart
		local weapons = game.ReplicatedStorage.Weapons:GetChildren()

		--fetches important data like inv, and string value of currently equipped so the server can dupe items in invetory

		if hum then

			for spwni,spawnP in pairs(spawnPoints) do --iterates through spawnpoint and teleport based on index (yes I know how to make it random this is a prototype!)
				if plri == spwni then
					hum.CFrame = spawnP.CFrame + Vector3.new(0, 1, 0) --Makes sure the player doesn't teleport inside the part
					for i,v in pairs(weapons) do --gives each character their equipped weapon
						if v.Name == equipped.Value then
							local clonedSword = v:Clone()
							clonedSword.Parent = plr.Backpack
							clonedSword.Name = "Sword"
						end
					end

				end
			end
		end
	end
end

local function TableAndKIll(alivePlayers)
	if #alivePlayers > 1 then --table found within module script, includes all the alive players I put it in module script so localscript can access for spectate purposes
		for i,plr in pairs(players) do
			local hum = plr.Character.Humanoid
			if hum then
				--IF HUMANOID DIES ITS REMOVED FROM THE TABLE
				hum.Died:Connect(function()
					local index = table.find(alivePlayers, plr)
					if index then

						table.remove(alivePlayers, index)
						task.wait(0.5)


					end

					local tag = hum:FindFirstChild("creator")
					--INCREMENTS KILLERS VALUE TO PLUS ONE
					if tag then
						local killer = tag.Value
						killer.leaderstats.Kills.Value += 1
						tag:Destroy()
					end
				end)
			end
		end
	end
end

local function randomMap()
	local allMaps = moduleScript.Maps
	local chosenToVoteMaps = moduleScript.ChosenToVote --so there are multiple maps stored, but this table only takes a few for now
	

	local randomVariable = 1
	while #chosenToVoteMaps < 2 do --aka 2
		for i,v in pairs(allMaps) do
			
			randomVariable = math.random(1, #allMaps)
			if randomVariable == i then
				if not table.find(chosenToVoteMaps, v) and #chosenToVoteMaps < 2 then 
					table.insert(chosenToVoteMaps, v) --takes two random maps and adds them into the table
				
				end
			end
		end
	end
	if #chosenToVoteMaps == 2 then
		return chosenToVoteMaps --once it has two it returns the table
	end

end

--MAIN FOUR FUNCTIONS THAT RUN THE GAME (Note: the names of the functions might make absolutely no sense and some of them could be merged, but again this is just for readability)

local function waitingForPlayers()


--fairly straightforward, a while loop that checks the amount of players to start the game
	while true do
		task.wait()
		if #players >= minNumberOfPlayers then
			game.Workspace:SetAttribute("NotEnough", false)
			break
		else
			game.Workspace:SetAttribute("NotEnough", true)
		end
	end

end

local function gameBegins()
 --attribute changes so local gui can catch it
	game.Workspace:SetAttribute("Intermission", IntermissionTimerNumber)
	game.Workspace:SetAttribute("GameTimer", RoundLength)

	local timer = true
	local number = IntermissionTimerNumber
--same for the timer
	while timer do
		game.Workspace:SetAttribute("Intermission", number)
		print(number)
		number = number - 1
		if #players < minNumberOfPlayers then
			waitingForPlayers()
			break
		end
		task.wait(1)
		if number == 0 then --ends the timer and starts the voting stage
			timer = false
			game.Workspace:SetAttribute("Intermission", number)
			task.wait(1)
			game.Workspace:SetAttribute("VotingStage", true) --voting stage :))
		
		end
	end

	
end

local function PreparinVote()
	
	--fetches the chosenamps through function callback value
	local chosenMapsToVote = randomMap()
	local mapsForVote = moduleScript.MapsForVote
	local mapList = game:GetService("ServerStorage").Maps:GetChildren()

	
--for now two maps only
	local name1 = chosenMapsToVote[1]
	local name2 = chosenMapsToVote[2] 

	--info abt the maps are stored within the module script, i also added my module script code to my github
	
	mapsForVote.Map1.Name = name1
	mapsForVote.Map2.Name = name2
	
	local vote = game.ReplicatedStorage.Vote


	
	for i,v in pairs(players) do
		local voteClone = vote:Clone()
		voteClone.Map1.Text = name1
		voteClone.Map2.Text = name2
		voteClone.Map1.Name = name1
		voteClone.Map2.Name = name2
		voteClone.Parent = v.PlayerGui.ScreenGui
	end
	
	local timer = true
	local number = 10

	while timer do
		
		print(number)
		number = number - 1
		task.wait(1)
		if number == 0 then
			timer = false
			for i,v in pairs(players) do
				local frame = v.PlayerGui.ScreenGui:FindFirstChild("Vote")
				if frame then
					frame:Destroy() --destroys the gui after the vote timer is done
				end
				game.Workspace:SetAttribute("VotingStage", false)
			end
			task.wait(1)
		end
	end
	
	local finalVoteNumber1 = #moduleScript.MapsForVote.Map1.Players
	local finalVoteNumber2 = #moduleScript.MapsForVote.Map2.Players --fetches the results
	
	
	if finalVoteNumber1 > finalVoteNumber2 then
		for i,v in pairs(game.ServerStorage.Maps:GetChildren()) do
			if v.Name == name1 then
				local clonedMap = v:Clone()
				clonedMap.Parent = workspace
				clonedMap.Name = "Map"
				teleportPlayers()
				game.Workspace:SetAttribute("GameReady", true)
			end
		end 
	end
	
	--in short, the first if statemement exists in case first map won, second in case the second won, third in case they're equal

	if finalVoteNumber2 > finalVoteNumber1 then
		for i,v in pairs(game.ServerStorage.Maps:GetChildren()) do
			if v.Name == name2 then
				local clonedMap = v:Clone()
				clonedMap.Parent = workspace
				clonedMap.Name = "Map"
				teleportPlayers()
				game.Workspace:SetAttribute("GameReady", true)
			end
		end 
	end
	
	if finalVoteNumber2 == finalVoteNumber1 then -- this here is supposed to handle what happens when theres equal amount of votes
		for i,v in pairs(game.ServerStorage.Maps:GetChildren()) do
			if v.Name == name2 then --and of course it might be a convention to have the server choose a random map but for my prefence i just had it choose map2 anyway lol
				local clonedMap = v:Clone()
				clonedMap.Parent = workspace
				clonedMap.Name = "Map"
				teleportPlayers()
				game.Workspace:SetAttribute("GameReady", true)
			end
		end 
	end
	
	
	
	
	
	

	
end

local function gameOnGoing()
	--this is the longest fucking function please dont have me explain all of this sigh i guess i will
	game.ReplicatedStorage.Spectate:Clone().Parent = game.StarterGui.ScreenGui
	game.ReplicatedStorage.Press:Clone().Parent = game.StarterGui.ScreenGui
	local spawnPoints = game.Workspace.Map.Spawns:GetChildren()
	local alivePlayers = moduleScript.AlivePlayers
	local onGoing = false



	--INSERTS PLAYERS INSIDE THE TABLE
	for i,plr in pairs(players) do
		print(#players)
		print(alivePlayers)
		if not table.find(alivePlayers, plr) then
			table.insert(alivePlayers, plr)
			onGoing = true
			
		end
	end


	while onGoing do
		task.wait(1)
		TableAndKIll(alivePlayers) --reacts whenever a player dies


		--UPDATES GAME TIMER (better to use epoch time but whatever)
		local gameTimer = game.Workspace:GetAttribute("GameTimer")
		gameTimer -= 1
		game.Workspace:SetAttribute("GameTimer", gameTimer)

--[[
    The same random discordian who had told me about propertychangedsignals also told me it's better to use unixtimestamps and have the
    timer end actually be a time translated in unix epoch but with added seconds depending on how long you want the game timer to last, if you get what i mean.
]]

		--WHEN ONE PLAYER LEFT IN THE TABLE (ENDS THE GAME)

		if #alivePlayers <= 1 then
			game.StarterGui.ScreenGui:FindFirstChild("Spectate"):Destroy()
			game.StarterGui.ScreenGui:FindFirstChild("Press"):Destroy()
			print("Winner is: " ..alivePlayers[1].Name)
			alivePlayers[1]:FindFirstChild("leaderstats"):FindFirstChild("Coins").Value += 20
			moduleScript.addEXP(alivePlayers[1], math.random(100, 200)) --gives exp (function can be find inside the modulescript)
			if alivePlayers[1].Backpack:FindFirstChild("Sword") then
				alivePlayers[1].Backpack:FindFirstChild("Sword"):Destroy()
			elseif alivePlayers[1].Character:FindFirstChild("Sword") then
				alivePlayers[1].Character:FindFirstChild("Sword"):Destroy()
			else
				print("Sword not found") --should use waitforchild or findfirstchild much more often to stop code from breaking
			end

			game.Workspace:SetAttribute("Winner", alivePlayers[1].Name)
			alivePlayers[1].leaderstats.Wins.Value += 1
			alivePlayers[1].Character.Humanoid.Health = 100 --shows the winner and gives him its rewards
			task.wait(3)
			if alivePlayers[1] then
				alivePlayers[1].Character.HumanoidRootPart.CFrame = game.Workspace.SpawnLocation.CFrame + Vector3.new(0, 1, 0) --teleports the winner back
				table.remove(alivePlayers, 1)
			end
            
			
			onGoing = false

			game.Workspace:SetAttribute("GameReady", false)
			game.Workspace:SetAttribute("Winner", "")
			game.Workspace:SetAttribute("GameTimer", RoundLength) --restores the attributes back

			--IF TIMER RUNS OUT	

		elseif game.Workspace:GetAttribute("GameTimer") == -1 then --once timer runs out without a winner
			game.StarterGui.ScreenGui:FindFirstChild("Spectate"):Destroy()
			game.StarterGui.ScreenGui:FindFirstChild("Press"):Destroy()
			game.Workspace:SetAttribute("Winner", "None") --no winners
			task.wait(2)
			for i,plr in pairs(players) do
				local character = plr.Character
				if character then
					if plr.Backpack:FindFirstChild("Sword") then
						plr.Backpack:FindFirstChild("Sword"):Destroy()
					elseif plr.Character:FindFirstChild("Sword") then
						plr.Character:FindFirstChild("Sword"):Destroy()
					else
						print("Sword not found") --handles if the sword doesnt exist aka if the player leaves the game per say before the game tped them
					end

					character.HumanoidRootPart.CFrame = game.Workspace.SpawnLocation.CFrame + Vector3.new(0, 1, 0) --teleports the remaining players back
					alivePlayers = {} --resets the table
					onGoing = false
					game.Workspace:SetAttribute("GameReady", false)
					game.Workspace:SetAttribute("GameTimer", RoundLength)
					game.Workspace:SetAttribute("Winner", "") --restores the values to default
				end
			end
		end

		--FAIL CHECKS 	(these are self explanatory right? right?)

		--REMOVES PLAYERS WHO LEAVE MIDGAME FROM THE TABLE
		game.Players.PlayerRemoving:Connect(function(plr)
			for i = #alivePlayers, 1, -1 do
				if alivePlayers[i] == plr then
					table.remove(alivePlayers, i)
					print(alivePlayers) --makes sure to remoeve the player from the table so it doesnt happen that it accidentally tries looking for them if they leave
				end
			end

			--CHECKS IF THERES ONE PLAYER LEFT AFTERWARDS (ENDS THE GAME)
			if #alivePlayers <= 1 then
				onGoing = false
				game.Workspace:SetAttribute("GameReady", false)
				game.Workspace:SetAttribute("GameTimer", RoundLength)
				game.Workspace:SetAttribute("Winner", "") --checks if maybe one player is left if someone leaves
			end
		end)

	end
	local map = game.Workspace:FindFirstChild("Map")
	map:Destroy()
	moduleScript.MapsForVote.Map1.Name = ""
	moduleScript.MapsForVote.Map2.Name = ""
	moduleScript.MapsForVote.Map1.Players = {}
	moduleScript.MapsForVote.Map2.Players = {}

	--resets all the map voting tables and values
end

--The loop

while true do --a loop!
	waitingForPlayers()
	gameBegins()
	PreparinVote()
	gameOnGoing()
end

