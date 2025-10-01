--Pretty unorganised and all im using this modulescript for is to recycle tables that multiple scripts need to access woow
--Amazing scripter I am aint i?

local module = {}

--I wouldnt need these tables actually I dont even know why DeadPlayers exist when I dont even use it?
module.AlivePlayers = {}
--Update: It doesn't exist anymore


--This is necessary though
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


-- I wonder if there is a way to spare myself hundreds of lines of code here adding each level one by one and just create a script that increments your level by 1 and gives you random rewards?
--God I'm stupid

module.addEXP = function(plr, amount)
	local currentEXPValue = module.PlayerData.Experience[plr.UserId]
	local currentLevel = module.PlayerData.Levels[plr.UserId]
	local calculatedAmount = currentEXPValue + amount


	module.PlayerData.Experience[plr.UserId] = calculatedAmount


	task.wait()
	for i,v in pairs(module.LevelingSystem) do
		while true do
			if calculatedAmount >= v.ExpRequired and currentLevel <= v.CurrentLevel then
				module.PlayerData.Experience[plr.UserId] = calculatedAmount - v.ExpRequired
				print(module.PlayerData.Experience[plr.UserId])
				currentLevel += 1
				module.PlayerData.Levels[plr.UserId] = currentLevel
				plr:WaitForChild("leaderstats"):WaitForChild("Levels").Value = currentLevel
				print(currentLevel)
			else
				break
			end
		end
	end


end

--Trashy free model placeholders lololol

module.Swords = {
	
	Azure = {
		
		Name = "Azure",
		Price = 100,
		AssetID = "http://www.roblox.com/asset/?id=10079486673"
	},
	
	DragonSword = {
		Name = "DragonSword",
		Price = 200,
		AssetID = "http://www.roblox.com/asset/?id=105333966"
	},
	
	Zeus = {
		Name = "Zeus",
		Price = 300,
		AssetID = "http://www.roblox.com/asset/?id=101420051"
		
	},
	
	EyeOfHell = {
		Name = "EyeOfHell",
		Price = 50,
		AssetID = ""
	}

}

--These three tables are probably confusing to understand so let me explain!!




module.Maps = {  --Stores all the maps available in the game
	"Sheriff",
	"Police",
	"Space"
}

module.ChosenToVote = {} --Now this doesnt even need to be a modulescript I've no clue why I created this here instead of in the main script?

module.MapsForVote = { --So Chosen to vote takes in 2 random maps, and then sends the value to maps for vote, they take the info, fill in the necessary and that's it
	Map1 = {
		Name = "",
		Players = {}
	},
	
	Map2 = {
		Name = "",
		Players = {}
	}
}


return module
