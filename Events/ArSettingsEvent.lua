ArSettingsEvent = {};
ArSettingsEvent_mt = Class(ArSettingsEvent, Event);

InitEventClass(ArSettingsEvent, "ArSettingsEvent");

function ArSettingsEvent.emptyNew()
    local self = Event.new(ArSettingsEvent_mt);
    return self;
end;

function ArSettingsEvent.new(timeToUpdate, doRepair, doRepaint, doWash, dmgThreshold, wearThreshold, dirtThreshold)
    local self = ArSettingsEvent.emptyNew();
    self.timeToUpdate = timeToUpdate;
    self.doRepair = doRepair;
    self.doRepaint = doRepaint;
    self.doWash = doWash;
    self.dmgThreshold = dmgThreshold;
    self.wearThreshold = wearThreshold;
    self.dirtThreshold = dirtThreshold;
    return self;
end;

function ArSettingsEvent:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.timeToUpdate);
    streamWriteBool(streamId, self.doRepair);
    streamWriteBool(streamId, self.doRepaint);
    streamWriteBool(streamId, self.doWash);
    streamWriteFloat32(streamId, self.dmgThreshold);
    streamWriteFloat32(streamId, self.wearThreshold);
    streamWriteFloat32(streamId, self.dirtThreshold);
end;

function ArSettingsEvent:readStream(streamId, connection)
    AutoRepair.timeToUpdate = streamReadFloat32(streamId);
    AutoRepair.doRepair = streamReadBool(streamId);
    AutoRepair.doRepaint = streamReadBool(streamId);
    AutoRepair.doWash = streamReadBool(streamId);
    AutoRepair.dmgThreshold = streamReadFloat32(streamId);
    AutoRepair.wearThreshold = streamReadFloat32(streamId);
    AutoRepair.dirtThreshold = streamReadFloat32(streamId);

    self:run(connection);
end;

function ArSettingsEvent:run(connection)
    if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server only have to broadcast the settings
        ArSettingsEvent.sendEvent(  AutoRepair.timeToUpdate,
                                    AutoRepair.doRepair,
                                    AutoRepair.doRepaint,
                                    AutoRepair.doWash,
                                    AutoRepair.dmgThreshold,
                                    AutoRepair.wearThreshold,
                                    AutoRepair.dirtThreshold
        );
	end;
end;

function ArSettingsEvent.sendEvent(timeToUpdate, doRepair, doRepaint, doWash, dmgThreshold, wearThreshold, dirtThreshold)
	if (g_server ~= nil) then
        -- Server broadcast
		g_server:broadcastEvent(ArSettingsEvent.new(timeToUpdate, doRepair, doRepaint, doWash, dmgThreshold, wearThreshold, dirtThreshold), true);
    else
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(ArSettingsEvent.new(timeToUpdate, doRepair, doRepaint, doWash, dmgThreshold, wearThreshold, dirtThreshold));
	end;
end;
