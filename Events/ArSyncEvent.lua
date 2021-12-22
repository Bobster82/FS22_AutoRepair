ArSyncEvent = {};
ArSyncEvent_mt = Class(ArSyncEvent, Event);

InitEventClass(ArSyncEvent, "ArSyncEvent");

function ArSyncEvent.emptyNew()
    local self = Event.new(ArSyncEvent_mt);
    return self;
end;

function ArSyncEvent.new()
    local self = ArSyncEvent.emptyNew();
    return self;
end;

function ArSyncEvent:writeStream(streamId, connection)
end;

function ArSyncEvent:readStream(streamId, connection)
    self:run(connection);
end;

function ArSyncEvent:run(connection)
    if g_server ~= nil then
        -- If server get sync event, server sends event with settings
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

function ArSyncEvent.sendEvent()
	if (g_server ~= nil) then
        -- Server broadcast
        g_server:broadcastEvent(ArSyncEvent.new(), true);
    else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(ArSyncEvent.new());
	end;
end;
