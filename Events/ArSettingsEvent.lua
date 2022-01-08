ArSettingsEvent = {};
ArSettingsEvent_mt = Class(ArSettingsEvent, Event);

InitEventClass(ArSettingsEvent, "ArSettingsEvent");

function ArSettingsEvent.emptyNew()
	local self = Event.new(ArSettingsEvent_mt);
	return self;
end;

function ArSettingsEvent.new(farmId, timeToUpdate, useGlobal, doRepair, doRepaint, doWash, dmgThreshold, wearThreshold, dirtThreshold)
	local self = ArSettingsEvent.emptyNew();
	self.farmId = farmId;
	self.timeToUpdate = timeToUpdate;
	self.useGlobal = useGlobal;
	self.doRepair = doRepair;
	self.doRepaint = doRepaint;
	self.doWash = doWash;
	self.dmgThreshold = dmgThreshold;
	self.wearThreshold = wearThreshold;
	self.dirtThreshold = dirtThreshold;
	return self;
end;

function ArSettingsEvent:writeStream(streamId, connection)
	streamWriteInt8(streamId, self.farmId);
	streamWriteInt32(streamId, self.timeToUpdate);
	streamWriteBool(streamId, self.useGlobal);
	
	streamWriteBool(streamId, self.doRepair);
	streamWriteBool(streamId, self.doRepaint);
	streamWriteBool(streamId, self.doWash);
	streamWriteInt8(streamId, self.dmgThreshold);
	streamWriteInt8(streamId, self.wearThreshold);
	streamWriteInt8(streamId, self.dirtThreshold);
end;

function ArSettingsEvent:readStream(streamId, connection)
	local farmId =  streamReadInt8(streamId);
	if (farmId == 0) then
		AutoRepair.timeToUpdate = streamReadInt32(streamId);
		AutoRepair.mp.useGlobal = streamReadBool(streamId);
		AutoRepair.doRepair = streamReadBool(streamId);
		AutoRepair.doRepaint = streamReadBool(streamId);
		AutoRepair.doWash = streamReadBool(streamId);
		AutoRepair.dmgThreshold = streamReadInt8(streamId);
		AutoRepair.wearThreshold = streamReadInt8(streamId);
		AutoRepair.dirtThreshold = streamReadInt8(streamId);
	else
		AutoRepair.timeToUpdate = streamReadInt32(streamId);
		AutoRepair.mp.useGlobal = streamReadBool(streamId);
		AutoRepair.mp.farms[farmId].doRepair = streamReadBool(streamId);
		AutoRepair.mp.farms[farmId].doRepaint = streamReadBool(streamId);
		AutoRepair.mp.farms[farmId].doWash = streamReadBool(streamId);
		AutoRepair.mp.farms[farmId].dmgThreshold = streamReadInt8(streamId);
		AutoRepair.mp.farms[farmId].wearThreshold = streamReadInt8(streamId);
		AutoRepair.mp.farms[farmId].dirtThreshold = streamReadInt8(streamId);
	end;
	self:run(connection, farmId);
end;

function ArSettingsEvent:run(connection, farmId)
	if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server only have to broadcast the settings
		if (farmId == 0) then
			ArSettingsEvent.sendEvent(  farmId,
										AutoRepair.timeToUpdate,
										AutoRepair.mp.useGlobal,
										AutoRepair.doRepair,
										AutoRepair.doRepaint,
										AutoRepair.doWash,
										AutoRepair.dmgThreshold,
										AutoRepair.wearThreshold,
										AutoRepair.dirtThreshold
			);
		else
			ArSettingsEvent.sendEvent(  farmId,
										AutoRepair.timeToUpdate,
										AutoRepair.mp.useGlobal,
										AutoRepair.mp.farms[farmId].doRepair,
										AutoRepair.mp.farms[farmId].doRepaint,
										AutoRepair.mp.farms[farmId].doWash,
										AutoRepair.mp.farms[farmId].dmgThreshold,
										AutoRepair.mp.farms[farmId].wearThreshold,
										AutoRepair.mp.farms[farmId].dirtThreshold
			);
		end;
	end;
end;

function ArSettingsEvent.sendEvent(farmId, timeToUpdate, useGlobal, doRepair, doRepaint, doWash, dmgThreshold, wearThreshold, dirtThreshold)
	if (g_server ~= nil) then
		-- Server broadcast
		g_server:broadcastEvent(ArSettingsEvent.new(farmId, timeToUpdate, useGlobal, doRepair, doRepaint, doWash, dmgThreshold, wearThreshold, dirtThreshold), true);
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(ArSettingsEvent.new(farmId, timeToUpdate, useGlobal, doRepair, doRepaint, doWash, dmgThreshold, wearThreshold, dirtThreshold));
	end;
end;
