


AutoRepairUI = {};
local AutoRepairUI_mt = Class(AutoRepairUI, ScreenElement);

AutoRepairUI.CONTROLS = {

    "guiTitle",
    "guiHeader",

    "option1Title",
    "option1Value",
    "option1ToolTip",

    "option2Title",
    "option2Value",
    "option2ToolTip",

    "option3Title",
    "option3Value",
    "option3ToolTip",

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

    -- Options
    self.option1Title:setText("AutoRepair Active");
    self.option1Value:setTexts({"Yes", "No"});

    self.option2Title:setText("Repaint when repairing");
    self.option2Value:setTexts({"Yes", "No"});

    self.option3Title:setText("Clean when repairing");
    self.option3Value:setTexts({"Yes", "No"});

    -- Set the values
    self:setValues();
end;

function AutoRepairUI:setValues()
    self.option1Value:setState((AutoRepair.isActive) and 1 or 2);
    self.option2Value:setState((AutoRepair.repaintWhenRepair) and 1 or 2);
    self.option3Value:setState((AutoRepair.cleanWhenRepair) and 1 or 2);
end;


function AutoRepairUI:onClickOk()

    local state = (self.option1Value:getState() == 1);
    AutoRepair.isActive = state;

    state = (self.option2Value:getState() == 1);
    AutoRepair.repaintWhenRepair = state;

    state = (self.option3Value:getState() == 1);
    AutoRepair.cleanWhenRepair = state;

    -- Close gui with setting changes (getting saved when game saves)
    g_gui:closeDialogByName(AutoRepair.guiName);
end;


function AutoRepairUI:onClickBack()
    -- Close gui without setting any changes
    g_gui:closeDialogByName(AutoRepair.guiName);
end;


