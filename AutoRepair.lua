--
-- AutoRepair
-- Copyright (C) Bobster82
--





local modDir = g_currentModDirectory;

source(Utils.getFilename("Gui/AutoRepairUI.lua", modDir));

-- Main table
AutoRepair = {};
AutoRepair.name = "AutoRepair";
AutoRepair.guiName = "AutoRepairUI";
AutoRepair.timeToUpdate = 30000; -- we check every 30000 msec (30 sec) if we need to repair a vehicle and or tool.
AutoRepair.timer = 0;
AutoRepair.dmgThreshold = 0.05; -- 5% damage

AutoRepair.isActive = true;
AutoRepair.repaintWhenRepair = false;
AutoRepair.cleanWhenRepair = false;

AutoRepair.firstRun = true;
AutoRepair.mp = {}; -- MultiPlayer game
AutoRepair.mp.isActive = false;
AutoRepair.mp.isServer = false;
AutoRepair.mp.isAdmin = false;


addModEventListener(AutoRepair);

--################################



-- FS loadMap
function AutoRepair:loadMap()
	AutoRepair:init();
	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, AutoRepair.RegisterActionEvents);
	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, AutoRepair.saveSavegame);
	AutoRepair.loadStoredXML();
	print(string.format("** %s, version: %s, by: %s **", AutoRepair.name, AutoRepair.version, AutoRepair.author));
end;

function AutoRepair:RegisterActionEvents()
    local ok, eventId = InputBinding.registerActionEvent(g_inputBinding, InputAction.AR_openMenu, self, AutoRepair.openSettingsMenu ,false ,true ,false ,true, nil);
    if (ok) then
        g_inputBinding.events[eventId].displayIsVisible = true;
    end;
end;

-- FS update
function AutoRepair:update(dt)

	if (AutoRepair.firstRun)then
		if (g_currentMission.missionDynamicInfo and g_currentMission.missionDynamicInfo.isMultiplayer) then
			-- Multiplayer game...
			AutoRepair.mp.isActive = true;
			if (not g_currentMission.missionDynamicInfo.isClient) then
				-- Only the server needs to repair/repaint/clean
				AutoRepair.mp.isServer = true;
			end;
			if (g_currentMission.isMasterUser) then
				-- Admin rights to open the menu in MP game
				AutoRepair.mp.isAdmin = true;
			end;
		end;
		AutoRepair.firstRun = false;
	end;

	if (not AutoRepair.isActive) then return; end;
	-- Only the server needs to run the update script in MultiPlayer
	if (AutoRepair.mp.isActive and not AutoRepair.mp.isServer) then return; end;

	if (self.timer > self.timeToUpdate) then
		for _, vehicle in ipairs(g_currentMission.vehicles) do
			-- We repair all vehicles owned by any farm
			if (vehicle.ownerFarmId ~= 0) then
				if (vehicle.getDamageAmount) then
					if (vehicle:getDamageAmount() > AutoRepair.dmgThreshold) then
						vehicle:repairVehicle();
						-- Option set to repaint also when we repair, then repaint the vehicle
						if (AutoRepair.repaintWhenRepair and vehicle.repaintVehicle) then
							vehicle:repaintVehicle();
						end;
						-- Option set to clean als when we repair, then clean the vehicle
						if (AutoRepair.cleanWhenRepair and vehicle.spec_washable) then
							for _, node in pairs(vehicle.spec_washable.washableNodes) do
								vehicle:setNodeDirtAmount(node, 0);
							end;
						end;
					end;
				end;
			end;
		end;
		self.timer = 0;
	end;
	self.timer = self.timer + dt;
end;

function AutoRepair:init()
    local modDesc = loadXMLFile("modDesc", modDir .. "modDesc.xml");
    AutoRepair.name = getXMLString(modDesc, "modDesc.title.en");
    AutoRepair.version = getXMLString(modDesc, "modDesc.version");
    AutoRepair.author = getXMLString(modDesc, "modDesc.author");

    g_gui:loadProfiles(modDir.."Gui/guiProfiles.xml");
    MainUI = AutoRepairUI.new();
    g_gui:loadGui(modDir.."Gui/AutoRepairUI.xml", AutoRepair.guiName , MainUI);
end;

function AutoRepair:openSettingsMenu()
	-- Only admin in MP can change settings
	if (AutoRepair.mp.isActive and not AutoRepair.mp.isAdmin) then return; end;

    if not g_gui:getIsGuiVisible() then
        g_gui:showDialog(AutoRepair.guiName);
    end;
end;


















-- ### SAVE


function AutoRepair.saveSavegame()
	-- Only the server needs to save in MP game
	if (AutoRepair.mp.isActive and not AutoRepair.mp.isServer) then return; end;

	if (g_server ~= nil) then
		local xmlFilePath = AutoRepair.getXMLPath();
		local xmlFile = createXMLFile(AutoRepair.name, xmlFilePath, AutoRepair.name);

		setXMLString(xmlFile, "AutoRepair.author", AutoRepair.author);
		setXMLString(xmlFile, "AutoRepair.version", AutoRepair.version);

		setXMLBool(xmlFile, "AutoRepair.isActive", AutoRepair.isActive);
		setXMLBool(xmlFile, "AutoRepair.repaintWhenRepair", AutoRepair.repaintWhenRepair);
		setXMLBool(xmlFile, "AutoRepair.cleanWhenRepair", AutoRepair.cleanWhenRepair);

		saveXMLFile(xmlFile);
	end;
end;

function AutoRepair.loadStoredXML()
    if (g_server == nil) then return; end;

	local xmlFilePath = AutoRepair.getXMLPath();
	if fileExists(xmlFilePath) then
		local xmlFile = loadXMLFile(AutoRepair.name, xmlFilePath);
		AutoRepair.readFromXML(xmlFile);
        delete(xmlFile);
	end;
end;

function AutoRepair.readFromXML(xmlFile)
	if (xmlFile == nil) then return; end;

	AutoRepair.isActive = 			Utils.getNoNil(getXMLBool(xmlFile, "AutoRepair.isActive"), AutoRepair.isActive);
	AutoRepair.repaintWhenRepair = 	Utils.getNoNil(getXMLBool(xmlFile, "AutoRepair.repaintWhenRepair"), AutoRepair.repaintWhenRepair);
	AutoRepair.cleanWhenRepair = 	Utils.getNoNil(getXMLBool(xmlFile, "AutoRepair.cleanWhenRepair"), AutoRepair.cleanWhenRepair);
end;

-- Returns the xml file path stored in savegame directory. Creates new if not exists
function AutoRepair.getXMLPath()
	local path = g_currentMission.missionInfo.savegameDirectory;
	if path ~= nil then
		return path .. "/AutoRepair_config.xml";
	else
		return getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex .. "/AutoRepair_config.xml";
	end;
end;