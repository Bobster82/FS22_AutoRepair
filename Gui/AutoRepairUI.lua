AutoRepairUI = {};
local AutoRepairUI_mt = Class(AutoRepairUI, ScreenElement);

AutoRepairUI.CONTROLS = {

    "guiTitle",
    "guiHeader",

    "option0Title",
    "option0Value",
    "option0Tooltip",

    "option1Title",
    "option1Value",
    "option1Tooltip",

    "option1bTitle",
    "option1bValue",
    "option1bTooltip",

    "option2Title",
    "option2Value",
    "option2Tooltip",

    "option2bTitle",
    "option2bValue",
    "option2bTooltip",

    "option3Title",
    "option3Value",
    "option3Tooltip",

    "option3bTitle",
    "option3bValue",
    "option3bTooltip",

    "okButton",
    "backButton",
};

function AutoRepairUI.new(target)
    local self = DialogElement.new(target, AutoRepairUI_mt);
    self:registerControls(AutoRepairUI.CONTROLS);
    return self;
end;

function AutoRepairUI:onOpen()
    AutoRepairUI:superClass().onOpen(self);

    -- Title
    self.guiTitle:setText(AutoRepair.name .." by " .. AutoRepair.author .." v".. AutoRepair.version);

    -- Header
    self.guiHeader:setText("Settings:");

    -- Time when to update
    self.option0Title:setText("Time to update in seconds (1-60)");
    self.option0Tooltip:setText("Change the time interval when vehicles/tools needs to be checked.");

    -- Repair
    self.option1Title:setText("Auto repair");
    self.option1Value:setTexts({"Yes", "No"});
    self.option1Tooltip:setText("Activate/deactivate auto repair.");

    -- Repair threshold
    self.option1bTitle:setText("Damage threshold (1-99)");
    self.option1bTooltip:setText("Change at what damage percent a vehicle/tool get repaired.")

    -- Repaint
    self.option2Title:setText("Auto repaint");
    self.option2Value:setTexts({"Yes", "No"});
    self.option2Tooltip:setText("Activate/deactivate auto repaint.");

    -- Repaint threshold
    self.option2bTitle:setText("Wear threshold (1-99)");
    self.option2bTooltip:setText("Change at what wear percent a vehicle/tool get repainted.")

    -- Wash
    self.option3Title:setText("Auto clean");
    self.option3Value:setTexts({"Yes", "No"});
    self.option3Tooltip:setText("Activate/deactivate auto clean.");

    -- Wash threshold
    self.option3bTitle:setText("Dirt threshold (1-99)");
    self.option3bTooltip:setText("Change at what dirt percent a vehicle get cleaned.")

    -- Set the values
    self:setValues();
end;

function AutoRepairUI:setValues()
    self.option0Value:setText(tostring(AutoRepair.timeToUpdate / 1000));
    self.option1Value:setState((AutoRepair.doRepair) and 1 or 2);
    self.option1bValue:setText(tostring(AutoRepair.dmgThreshold));
    self.option2Value:setState((AutoRepair.doRepaint) and 1 or 2);
    self.option2bValue:setText(tostring(AutoRepair.wearThreshold));
    self.option3Value:setState((AutoRepair.doWash) and 1 or 2);
    self.option3bValue:setText(tostring(AutoRepair.dirtThreshold));
end;

function AutoRepairUI:onClickOk()

    AutoRepair.timeToUpdate = AutoRepairUI:txtToNumTime(self.option0Value);

    local state = (self.option1Value:getState() == 1);
    AutoRepair.doRepair = state;
    AutoRepair.dmgThreshold = AutoRepairUI:txtToNum(self.option1bValue);

    state = (self.option2Value:getState() == 1);
    AutoRepair.doRepaint = state;
    AutoRepair.wearThreshold = AutoRepairUI:txtToNum(self.option2bValue);

    state = (self.option3Value:getState() == 1);
    AutoRepair.doWash = state;
    AutoRepair.dirtThreshold = AutoRepairUI:txtToNum(self.option3bValue);

    -- Send event for MP sync
    ArSettingsEvent.sendEvent(  AutoRepair.timeToUpdate,
                                AutoRepair.doRepair,
                                AutoRepair.doRepaint,
                                AutoRepair.doWash,
                                AutoRepair.dmgThreshold,
                                AutoRepair.wearThreshold,
                                AutoRepair.dirtThreshold
    );
    -- Close gui with setting changes (getting saved when game saves)
    g_gui:closeDialogByName(AutoRepair.guiName);
end;

function AutoRepairUI:onClickBack()
    -- Close gui without setting any changes
    g_gui:closeDialogByName(AutoRepair.guiName);
end;










function AutoRepairUI:txtToNumTime(option)
    local n = tonumber(option:getText());
    if n ~= nil then
      if n <= 1 then n = 1; end;
      if n > 60 then n = 60; end;
    else n = 30; end;
    return n * 1000;
end;

function AutoRepairUI:txtToNum(option)
    local n = tonumber(option:getText());
    if n ~= nil then
      if n <= 1 then n = 1; end;
      if n > 99 then n = 99; end;
    else n = 5; end;
    return n;
end;

function AutoRepairUI:onTextChangedTime(_, text)
    local n = tonumber(text);
    if n ~= nil then
        if n < 1 then n = 1 end;
        if n > 60 then n = 60 end;
    else n = "" end;
    self.option0Value:setText(tostring(n));
end;

function AutoRepairUI:onTextChangedDmg(_, text)
    local n = tonumber(text);
    if n ~= nil then
        if n < 1 then n = 1 end;
        if n > 99 then n = 99 end;
    else n = "" end;
    self.option1bValue:setText(tostring(n));
end;

function AutoRepairUI:onTextChangedWear(_, text)
    local n = tonumber(text);
    if n ~= nil then
        if n < 1 then n = 1 end;
        if n > 99 then n = 99 end;
    else n = "" end;
    self.option2bValue:setText(tostring(n));
end;

function AutoRepairUI:onTextChangedDirt(_, text)
    local n = tonumber(text);
    if n ~= nil then
        if n < 1 then n = 1 end;
        if n > 99 then n = 99 end;
    else n = "" end;
    self.option3bValue:setText(tostring(n));
end;
