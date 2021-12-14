--
-- AutoRepair
-- Copyright (C) Bobster82
--

--[[ TODO only if requested enough:
Maybe add cleaning
Maybe add repainting
Maybe add settings to repair at different damage
Maybe add only repairing when enough money
]]


-- Main table
AutoRepair = {};
AutoRepair.name = "AutoRepair";
AutoRepair.author = "Bobster82";
AutoRepair.version = "2.0.0.1";
AutoRepair.timeToUpdate = 30000; -- we check every 30000 msec (30 sec) if we need to repair a vehicle and or tool.
AutoRepair.timer = 0;
AutoRepair.dmgThreshold = 0.05; -- 5% damage


addModEventListener(AutoRepair);

--################################



-- FS loadMap
function AutoRepair:loadMap()
	print(string.format("** %s, version: %s, by: %s **", AutoRepair.name, AutoRepair.version, AutoRepair.author));
end;

-- FS update
function AutoRepair:update(dt)

	if (self.timer > self.timeToUpdate) then
		for _, vehicle in ipairs(g_currentMission.vehicles) do
			-- We repair all vehicles owned by any farm
			if (vehicle.ownerFarmId ~= 0) then
				if (vehicle.getDamageAmount) then
					if (vehicle:getDamageAmount() > AutoRepair.dmgThreshold) then
						vehicle:repairVehicle();
					end;
				end;
			end;
		end;
		self.timer = 0;
	end;
	self.timer = self.timer + dt;
end;
