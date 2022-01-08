AutoRepairUI = {};
local AutoRepairUI_mt = Class(AutoRepairUI, ScreenElement);


AutoRepairUI.CONTROLS = {

	"guiTitle",

	"useGlobalTitle",
	"useGlobalValue",
	"useGlobalTooltip",

	"useByFarmTitle",
	"useByFarmValue",
	"useByFarmTooltip",

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

	"okButton"
	
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

	-- Global or per farm (only in MP)
	self.useGlobalValue:setDisabled(not AutoRepair.mp.isActive)
	self.useGlobalTitle:setText(g_i18n:getText("AR_gui_useGlobal_title"));
	self.useGlobalValue:setTexts({g_i18n:getText("AR_gui_useGlobal_global"), g_i18n:getText("AR_gui_useGlobal_farm")});
	self.useGlobalTooltip:setText(g_i18n:getText("AR_gui_useGlobal_tooltip"));

	self.farmId = 1;
	self.useByFarmValue:setDisabled(not AutoRepair.mp.isActive)
	self.useByFarmTitle:setText(g_i18n:getText("AR_gui_useByFarm_title"));
	self.useByFarmValue:setTexts({"1", "2", "3", "4", "5", "6", "7", "8"});
	self.useByFarmTooltip:setText(g_i18n:getText("AR_gui_useByFarm_tooltip"));

	-- Time when to update (global)
	self.option0Title:setText(g_i18n:getText("AR_gui_timeToUpdate"));
	self.option0Tooltip:setText(g_i18n:getText("AR_gui_timeToUpdate_tooltip"));

	-- Repair
	self.option1Title:setText(g_i18n:getText("AR_gui_autorepair_title"));
	self.option1Value:setTexts({g_i18n:getText("AR_gui_yes"), g_i18n:getText("AR_gui_no")});
	self.option1Tooltip:setText(g_i18n:getText("AR_gui_autorepair_tooltip"));

	-- Repair threshold
	self.option1bTitle:setText(g_i18n:getText("AR_gui_dmg_title"));
	self.option1bTooltip:setText(g_i18n:getText("AR_gui_dmg_tooltip"))

	-- Repaint
	self.option2Title:setText(g_i18n:getText("AR_gui_autorepaint_title"));
	self.option2Value:setTexts({g_i18n:getText("AR_gui_yes"), g_i18n:getText("AR_gui_no")});
	self.option2Tooltip:setText(g_i18n:getText("AR_gui_autorepaint_tooltip"));

	-- Repaint threshold
	self.option2bTitle:setText(g_i18n:getText("AR_gui_wear_title"));
	self.option2bTooltip:setText(g_i18n:getText("AR_gui_wear_tooltip"))

	-- Wash
	self.option3Title:setText(g_i18n:getText("AR_gui_autoclean_title"));
	self.option3Value:setTexts({g_i18n:getText("AR_gui_yes"), g_i18n:getText("AR_gui_no")});
	self.option3Tooltip:setText(g_i18n:getText("AR_gui_autoclean_tooltip"));

	-- Wash threshold
	self.option3bTitle:setText(g_i18n:getText("AR_gui_dirt_title"));
	self.option3bTooltip:setText(g_i18n:getText("AR_gui_dirt_tooltip"))

	-- Set the values
	self:updateValues();
end;

function AutoRepairUI:updateValues()
	self.farmId = self.useByFarmValue:getState();
	self.useGlobalValue:setState((AutoRepair.mp.useGlobal) and 1 or 2);

	self.option0Value:setText(tostring(AutoRepair.timeToUpdate / 1000));
	if (self.useGlobalValue:getState() == 1) then
		self.useByFarmValue:setDisabled(true);
		self.option1Value:setState((AutoRepair.doRepair) and 1 or 2);
		self.option1bValue:setText(tostring(AutoRepair.dmgThreshold));
		self.option2Value:setState((AutoRepair.doRepaint) and 1 or 2);
		self.option2bValue:setText(tostring(AutoRepair.wearThreshold));
		self.option3Value:setState((AutoRepair.doWash) and 1 or 2);
		self.option3bValue:setText(tostring(AutoRepair.dirtThreshold));
	else
		self.useByFarmValue:setDisabled(false);
		self.useByFarmValue:setState(self.farmId);
		self.option1Value:setState((AutoRepair.mp.farms[self.farmId].doRepair) and 1 or 2);
		self.option1bValue:setText(tostring(AutoRepair.mp.farms[self.farmId].dmgThreshold));
		self.option2Value:setState((AutoRepair.mp.farms[self.farmId].doRepaint) and 1 or 2);
		self.option2bValue:setText(tostring(AutoRepair.mp.farms[self.farmId].wearThreshold));
		self.option3Value:setState((AutoRepair.mp.farms[self.farmId].doWash) and 1 or 2);
		self.option3bValue:setText(tostring(AutoRepair.mp.farms[self.farmId].dirtThreshold));

		self:updateFramePosition()
	end;
end;

function AutoRepairUI:onUseGlobalValueChanged()
	AutoRepair.mp.useGlobal = self.useGlobalValue:getState() == 1;
	self:updateValues();
end;

function AutoRepairUI:onUseByFarmValueChanged()
	self:updateValues();
end;

function AutoRepairUI:onValueChangedDmg()
	if (AutoRepair.mp.useGlobal) then
		AutoRepair.doRepair = self.option1Value:getState() == 1;
	else
		AutoRepair.mp.farms[self.farmId].doRepair = self.option1Value:getState() == 1;
	end;
end;

function AutoRepairUI:onValueChangedWear()
	if (AutoRepair.mp.useGlobal) then
		AutoRepair.doRepaint = self.option2Value:getState() == 1;
	else
		AutoRepair.mp.farms[self.farmId].doRepaint = self.option2Value:getState() == 1;
	end;
end;

function AutoRepairUI:onValueChangedDirt()
	if (AutoRepair.mp.useGlobal) then
		AutoRepair.doWash = self.option3Value:getState() == 1;
	else
		AutoRepair.mp.farms[self.farmId].doWash = self.option3Value:getState() == 1;
	end;
end;


function AutoRepairUI:onClickOk()
	if (AutoRepair.mp.isActive) then
		ArSettingsEvent.sendEvent(  0,
									AutoRepair.timeToUpdate,
									AutoRepair.mp.useGlobal,
									AutoRepair.doRepair,
									AutoRepair.doRepaint,
									AutoRepair.doWash,
									AutoRepair.dmgThreshold,
									AutoRepair.wearThreshold,
									AutoRepair.dirtThreshold
		);
		for farmId, _ in ipairs(AutoRepair.mp.farms) do
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
	AutoRepair.timeToUpdate = AutoRepairUI:txtToNumTime(self.option0Value);
end;

function AutoRepairUI:onTextChangedDmg(_, text)
	local n = tonumber(text);
	if n ~= nil then
		if n < 1 then n = 1 end;
		if n > 99 then n = 99 end;
	else n = "" end;
	self.option1bValue:setText(tostring(n));
	if (AutoRepair.mp.useGlobal) then
		AutoRepair.dmgThreshold = AutoRepairUI:txtToNum(self.option1bValue);
	else
		AutoRepair.mp.farms[self.farmId].dmgThreshold = AutoRepairUI:txtToNum(self.option1bValue);
	end;
end;

function AutoRepairUI:onTextChangedWear(_, text)
	local n = tonumber(text);
	if n ~= nil then
		if n < 1 then n = 1 end;
		if n > 99 then n = 99 end;
	else n = "" end;
	self.option2bValue:setText(tostring(n));
	if (AutoRepair.mp.useGlobal) then
		AutoRepair.wearThreshold = AutoRepairUI:txtToNum(self.option2bValue);
	else
		AutoRepair.mp.farms[self.farmId].wearThreshold = AutoRepairUI:txtToNum(self.option2bValue);
	end;
end;

function AutoRepairUI:onTextChangedDirt(_, text)
	local n = tonumber(text);
	if n ~= nil then
		if n < 1 then n = 1 end;
		if n > 99 then n = 99 end;
	else n = "" end;
	self.option3bValue:setText(tostring(n));
	if (AutoRepair.mp.useGlobal) then
		AutoRepair.dirtThreshold = AutoRepairUI:txtToNum(self.option3bValue);
	else
		AutoRepair.mp.farms[self.farmId].dirtThreshold = AutoRepairUI:txtToNum(self.option3bValue);
	end;
end;
