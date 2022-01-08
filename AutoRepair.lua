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

-- Settings SinglePlayer (or global)
AutoRepair.timeToUpdate = 30000; 	-- we check every 30000 msec (30 sec) (default) if we need to repair/repaint/clean a vehicle and or tool. (Global)
AutoRepair.dmgThreshold = 5; 		-- 5% damage (default)
AutoRepair.wearThreshold = 5; 		-- 5% damage to paint (default)
AutoRepair.dirtThreshold = 5;	 	-- 5% dirty (default)
AutoRepair.doRepair = true;
AutoRepair.doRepaint = false;
AutoRepair.doWash = false;

-- Settings MultiPlayer
AutoRepair.mp = {};
AutoRepair.mp.isActive = false;
AutoRepair.mp.farms = {};
for i = 1, 8, 1 do table.insert(AutoRepair.mp.farms, i, {farmId = i}); end; -- max farms is 8
AutoRepair.mp.useGlobal = true; 	-- use same settings for all farms?

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
		self.mp.isActive = g_currentMission.missionDynamicInfo.isMultiplayer;
		self.isServer = g_currentMission:getIsServer();
		if (not self.isServer and self.mp.isActive) then
			ArSyncEvent.sendEvent(); -- Sync with server
		end;
		self.firstRun = false;
	end;

	-- If not server no need to go further
	if (not self.isServer) then return; end;

	if (self.timer > self.timeToUpdate) then
		if (self.mp.useGlobal) then self:spUpdate();
		else self:mpUpdate(); end;
		self.timer = 0;
	end;
	self.timer = self.timer + dt;
end;

function AutoRepair:spUpdate()
	for _, vehicle in ipairs(g_currentMission.vehicles) do
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
end;

function AutoRepair:mpUpdate()
	for _, vehicle in ipairs(g_currentMission.vehicles) do
		if (vehicle.ownerFarmId ~= 0) then
			local farmId = vehicle.ownerFarmId;
			-- Repair
			if (self.mp.farms[farmId].doRepair and vehicle.getDamageAmount) then
				if (vehicle:getDamageAmount() > self.mp.farms[farmId].dmgThreshold /100) then
					if (vehicle.repairVehicle) then vehicle:repairVehicle(); end;
				end;
			end;
			-- Repaint
			if (self.mp.farms[farmId].doRepaint and vehicle.getWearTotalAmount) then
				if (vehicle:getWearTotalAmount() > self.mp.farms[farmId].wearThreshold /100) then
					if (vehicle.repaintVehicle) then vehicle:repaintVehicle(); end;
				end;
			end;
			-- Wash
			if (self.mp.farms[farmId].doWash and vehicle.getDirtAmount) then
				if (vehicle:getDirtAmount() > self.mp.farms[farmId].dirtThreshold /100) then
					for _, node in pairs(vehicle.spec_washable.washableNodes) do
						vehicle:setNodeDirtAmount(node, 0);
					end;
				end;
			end;
			--
		end;
	end;
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
	if (not g_currentMission.isMasterUser) then
		g_currentMission:showBlinkingWarning(g_i18n:getText("AR_warning_noAdmin"));
		return;
	end;

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

		if (AutoRepair.mp.isActive) then
			setXMLBool(xmlFile, "AutoRepair.useGlobal", AutoRepair.mp.useGlobal);
			for farmId, _ in ipairs(AutoRepair.mp.farms) do
				local key = "AutoRepair.mp.farms.farm" .. tostring(farmId);

				setXMLBool(xmlFile, key..".doRepair", AutoRepair.mp.farms[farmId].doRepair);
				setXMLBool(xmlFile, key..".doRepaint", AutoRepair.mp.farms[farmId].doRepaint);
				setXMLBool(xmlFile, key..".doWash", AutoRepair.mp.farms[farmId].doWash);
		
				setXMLInt(xmlFile, key..".dmgThreshold", AutoRepair.mp.farms[farmId].dmgThreshold);
				setXMLInt(xmlFile, key..".wearThreshold", AutoRepair.mp.farms[farmId].wearThreshold);
				setXMLInt(xmlFile, key..".dirtThreshold", AutoRepair.mp.farms[farmId].dirtThreshold);
			end;
		end;

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

	-- SP (or global) load settings
	AutoRepair.doRepair = 		Utils.getNoNil(getXMLBool(xmlFile, "AutoRepair.doRepair"), AutoRepair.doRepair);
	AutoRepair.doRepaint = 		Utils.getNoNil(getXMLBool(xmlFile, "AutoRepair.doRepaint"), AutoRepair.doRepaint);
	AutoRepair.doWash = 		Utils.getNoNil(getXMLBool(xmlFile, "AutoRepair.doWash"), AutoRepair.doWash);

	AutoRepair.timeToUpdate = 	Utils.getNoNil(getXMLInt(xmlFile, "AutoRepair.timeToUpdate"), AutoRepair.timeToUpdate);
	AutoRepair.dmgThreshold = 	Utils.getNoNil(getXMLInt(xmlFile, "AutoRepair.dmgThreshold"), AutoRepair.dmgThreshold);
	AutoRepair.wearThreshold = 	Utils.getNoNil(getXMLInt(xmlFile, "AutoRepair.wearThreshold"), AutoRepair.wearThreshold);
	AutoRepair.dirtThreshold = 	Utils.getNoNil(getXMLInt(xmlFile, "AutoRepair.dirtThreshold"), AutoRepair.dirtThreshold);

	AutoRepair.mp.useGlobal = 	Utils.getNoNil(getXMLBool(xmlFile, "AutoRepair.useGlobal"), AutoRepair.mp.useGlobal);

	-- MP load settings (if nothing saved, use the saved SP settings or default)
	for farmId, farm in ipairs(AutoRepair.mp.farms) do
		local key = "AutoRepair.mp.farms.farm" .. tostring(farmId);

		farm.doRepair = 		Utils.getNoNil(getXMLBool(xmlFile, key..".doRepair"), AutoRepair.doRepair);
		farm.doRepaint = 		Utils.getNoNil(getXMLBool(xmlFile, key..".doRepaint"), AutoRepair.doRepaint);
		farm.doWash = 			Utils.getNoNil(getXMLBool(xmlFile, key..".doWash"), AutoRepair.doWash);

		farm.dmgThreshold = 	Utils.getNoNil(getXMLInt(xmlFile, key..".dmgThreshold"), AutoRepair.dmgThreshold);
		farm.wearThreshold = 	Utils.getNoNil(getXMLInt(xmlFile, key..".wearThreshold"), AutoRepair.wearThreshold);
		farm.dirtThreshold = 	Utils.getNoNil(getXMLInt(xmlFile, key..".dirtThreshold"), AutoRepair.dirtThreshold);
	end;

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
