--
-- AutoRepair
-- Copyright (C) Bobster82
--





local modDir = g_currentModDirectory;

source(Utils.getFilename("Gui/AutoRepairUI.lua", modDir));
source(Utils.getFilename("Events/ArSyncEvent.lua", modDir));
source(Utils.getFilename("Events/ArSettingsEvent.lua", modDir));


-- Main table
AutoRepair = {};
AutoRepair.name = "AutoRepair";
AutoRepair.guiName = "AutoRepairUI";

-- Settings
AutoRepair.timeToUpdate = 30000; 	-- we check every 30000 msec (30 sec) (default) if we need to repair/repaint/clean a vehicle and or tool.
AutoRepair.dmgThreshold = 5; 		-- 5% damage (default)
AutoRepair.wearThreshold = 5; 		-- 5% damage to paint (default)
AutoRepair.dirtThreshold = 5;	 	-- 5% dirty (default)
AutoRepair.doRepair = true;
AutoRepair.doRepaint = false;
AutoRepair.doWash = false;

AutoRepair.timer = 0;
AutoRepair.firstRun = true;
AutoRepair.isServer = false;


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

	if (self.firstRun) then
		self.isServer = g_currentMission:getIsServer();
		if (not self.isServer) then
			ArSyncEvent.sendEvent(); -- Sync with server
		end;
		self.firstRun = false;
	end;

	-- If not server and active, no need to go further
	if (not self.isServer) then return; end;
	if (self.doRepair) then
	elseif (self.doRepaint) then
	elseif (self.doWash) then
	else return;
	end;

	if (self.timer > self.timeToUpdate) then
		for _, vehicle in ipairs(g_currentMission.vehicles) do
			-- We repair all vehicles owned by any farm
			if (vehicle.ownerFarmId ~= 0) then
				-- Repair
				if (self.doRepair and vehicle.getDamageAmount) then
					if (vehicle:getDamageAmount() > self.dmgThreshold /100) then
						if (vehicle.repairVehicle) then vehicle:repairVehicle(); end;
					end;
				end;
				-- Repaint
				if (self.doRepaint and vehicle.getWearTotalAmount) then
					if (vehicle:getWearTotalAmount() > self.wearThreshold /100) then
						if (vehicle.repaintVehicle) then vehicle:repaintVehicle(); end;
					end;
				end;
				-- Wash
				if (self.doWash and vehicle.getDirtAmount) then
					if (vehicle:getDirtAmount() > self.dirtThreshold /100) then
						for _, node in pairs(vehicle.spec_washable.washableNodes) do
							vehicle:setNodeDirtAmount(node, 0);
						end;
					end;
				end;
				--
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
	if (not g_currentMission.isMasterUser) then return; end;

    if not g_gui:getIsGuiVisible() then
        g_gui:showDialog(AutoRepair.guiName);
    end;
end;















-- ### SAVE


function AutoRepair.saveSavegame()
	-- Only the server needs to save in MP game

	if (g_server ~= nil) then
		local xmlFilePath = AutoRepair.getXMLPath();
		local xmlFile = createXMLFile(AutoRepair.name, xmlFilePath, AutoRepair.name);

		setXMLString(xmlFile, "AutoRepair.author", AutoRepair.author);
		setXMLString(xmlFile, "AutoRepair.version", AutoRepair.version);

		setXMLBool(xmlFile, "AutoRepair.doRepair", AutoRepair.doRepair);
		setXMLBool(xmlFile, "AutoRepair.doRepaint", AutoRepair.doRepaint);
		setXMLBool(xmlFile, "AutoRepair.doWash", AutoRepair.doWash);

		setXMLInt(xmlFile, "AutoRepair.timeToUpdate", AutoRepair.timeToUpdate);
		setXMLInt(xmlFile, "AutoRepair.dmgThreshold", AutoRepair.dmgThreshold);
		setXMLInt(xmlFile, "AutoRepair.wearThreshold", AutoRepair.wearThreshold);
		setXMLInt(xmlFile, "AutoRepair.dirtThreshold", AutoRepair.dirtThreshold);

		saveXMLFile(xmlFile);
		print ("[AR] saved to xml file");
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

	AutoRepair.doRepair = 		Utils.getNoNil(getXMLBool(xmlFile, "AutoRepair.doRepair"), AutoRepair.doRepair);
	AutoRepair.doRepaint = 		Utils.getNoNil(getXMLBool(xmlFile, "AutoRepair.doRepaint"), AutoRepair.doRepaint);
	AutoRepair.doWash = 		Utils.getNoNil(getXMLBool(xmlFile, "AutoRepair.doWash"), AutoRepair.doWash);

	AutoRepair.timeToUpdate = 	Utils.getNoNil(getXMLInt(xmlFile, "AutoRepair.timeToUpdate"), AutoRepair.timeToUpdate);
	AutoRepair.dmgThreshold = 	Utils.getNoNil(getXMLInt(xmlFile, "AutoRepair.dmgThreshold"), AutoRepair.dmgThreshold);
	AutoRepair.wearThreshold = 	Utils.getNoNil(getXMLInt(xmlFile, "AutoRepair.wearThreshold"), AutoRepair.wearThreshold);
	AutoRepair.dirtThreshold = 	Utils.getNoNil(getXMLInt(xmlFile, "AutoRepair.dirtThreshold"), AutoRepair.dirtThreshold);

	print ("[AR] loaded from xml file");
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