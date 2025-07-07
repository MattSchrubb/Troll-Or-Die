--[[
Instructions on how to setup your own Services and Controllers -- Wahoo!!!!

1. Make sure you have all neccessary Libraries placed properly.
	- ProfileStore and ReplicaService should be in the Libraries folder under ServerScriptService
	- ReplicaShared folder and ReplicaClient module should be under ReplicatedStorage
	- The Packages folder should be in ReplicatedStorage and should have the Comm module
	- There should also be a Services folder under ServerScriptService
		- Including the Data folder with the ProfileService module under it!!!!!!
	- And a Comms folder under ReplicatedStorage
	- As well as a Controllers folder in StarterPlayerScripts
	- Lastly the ServerMain script and ClientMain scripts in ServerScriptService and StarterPlayerScripts

2. Sectioning your Services!!!
	- The Services folder in ServerScriptService is where you'll be setting up all of your services modules
	- To differentiate between services that need to setup Replicas for the client, and ones that don't, we
		use folders to section them off.
	- ALWAYS make sure to have the Data folder with ProfileService!!!!!!!!
		- This is where we setup the player's data and replicas
	- Any other gameplay services or utility services can be placed in the corresponding folders for organization
	- The heirarchy could look something like this:
		ServerScriptService
		| Services (folder)
		| | Data (folder)
		| | | ProfileService
		| | | | ProfileTemplate
		| | | CurrencyData
		| | | ItemsData
		| | Gameplay (folder)
		| | | PipsService

3. Creating your own Services!!!
	- For any service that handles data stored in the DataStore, place the module under the Data folder
		- Also, make sure that a table is set up in the ProfileTemplate module for each Data Service with each piece of
			data that each service should handle:
		local template = {
			CurrencyData = {
				Gems = 0,
				Coins = 0
			},
			ItemsData = {
				Hammer_B = 1, -- Represents the player having 1x of the first Item
			}
		}
	- If you would like to add the ability for Players to call functions on the server, make sure to add
		a Client table to the service declaration. (Shown in the example below)
	- Reference DataServiceTemplate under this module for an example with basic usage
]]
