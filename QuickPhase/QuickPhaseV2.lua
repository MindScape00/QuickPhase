-------------------------------------------------------------------------------
-- Initial Variables
-------------------------------------------------------------------------------

-- name = the name that shows in Right Click 'Title', prefix is used to generate the names of the buttons
local addonData = {name="QuickPhase",prefix="QPBUTTON_"}
local currentVersion = GetAddOnMetadata("QuickPhase", "Version")
local author = GetAddOnMetadata("QuickPhase", "Author")

local utils = Epsilon.utils
local messages = utils.messages
local server = utils.server
local tabs = utils.tabs

local main = Epsilon.main

local currentPhase = Epsilon.currentPhase or "(Unknown)"

-------------------------------------------------------------------------------
-- Local Simple Functions
-------------------------------------------------------------------------------

local function cmd(text)
	SendChatMessage("."..text, "GUILD");
end

local function playerName()
	local name = UIDROPDOWNMENU_INIT_MENU.name:gsub("%s","_")
	return name;
end

local function whisper(name,text)
	local name = name:gsub("%s","_")
	SendChatMessage(text, "WHISPER", nil, name);
end

local function updateCurrentPhase()
	currentPhase, ownedPhase = server.send("EPSILON_G_PHASE", "CLIENT_READY")
end

-------------------------------------------------------------------------------
-- Defining what buttons to add
-------------------------------------------------------------------------------

local menu = {
	{ text = addonData.name, name="QCSUBSECTION", isTitle = true, isUninteractable = true, isSubsectionTitle = true, isSubsection = true, isSubsectionSeparator=true, }, -- Subsection title
	
	{ text = "|cffFF6060Phase Mod", name="PMOD_MAIN", nested = 1, nest = {
			{["NAME"]="PMOD_UI", ["INFO"]={text = "|cffFF6060Mod UI", func=function() showModUI() end}},
			{["NAME"]="PMOD_KICK", ["INFO"]={text = "|cffFF6060Kick", func=function() cmd("phase kick "..playerName()); kickPrint(playerName()); end}},
			{["NAME"]="PMOD_SECTION_BLIST", ["INFO"]={text="", isTitle = true, isUninteractable = true, isSubsection = true, isSubsectionSeparator=true}},
			{["NAME"]="PMOD_BLACKLIST", ["INFO"] = {text = "|cffFF6060Blacklist",func=function() cmd("phase blacklist add "..playerName()) end}},
			{["NAME"]="PMOD_UNBLACKLIST", ["INFO"] = {text = "|cffFF6060Remove Blacklist",func=function() cmd("phase blacklist remove "..playerName()) end}},
			{["NAME"]="PMOD_SECTION_WLIST", ["INFO"]={text="", isTitle = true, isUninteractable = true, isSubsection = true, isSubsectionSeparator=true}},
			{["NAME"]="PMOD_WHITELIST", ["INFO"] = {text = "|cffFF6060Whitelist",func=function() cmd("phase whitelist add "..playerName()) end}},
			{["NAME"]="PMOD_UNWHITELIST", ["INFO"] = {text = "|cffFF6060Remove Whitelist",func=function() cmd("phase whitelist remove "..playerName()) end}},
			}, 
			func = function()
				showModUI()
			end
	},
	{ text = "|cffFF6060Phase Member", name="PMEM_MAIN", nested = 1, nest = {
		{["NAME"]="PMEM_ADD", ["INFO"] = {text = "|cffFF6060Add", func=function() cmd("phase member add "..playerName()) end}},
		{["NAME"]="PMEM_REMO", ["INFO"]={text = "|cffFF6060Remove", func=function() cmd("phase member remove "..playerName()) end}},
		{["NAME"]="PMEM_PROMO", ["INFO"] = {text = "|cffFF6060Promote",func=function() cmd("phase member promote "..playerName()) end}},
		{["NAME"]="PMEM_DEMO", ["INFO"] = {text = "|cffFF6060Demote", func=function() cmd("phase member demote "..playerName()) end}},
		},
	},
}

--[[
Menu Template:
	text: The text actually shown in the menu || name: The internal name of the button, must be unique || func: the function to perform when clicked || nested (optional): 1 if there is a nested sub-menu with more options || nest: A table containing all the nested sub-menu buttons, these follow a slightly different set-up. || isTitle: true makes it gold & bold (header) - needed for isUninteractable to work for some reason if it's nested || isUninteractable: true makes it non-clickable || isSubsection: true defines it as a subsection (needed for the other subsection tags) || isSubsectionSeparator: true adds a nice line above it to separate it || isSubsectionTitle: true allows title to work again for subsections and not just disappear.
	
nest Template:
	["NAME"]: the internal name of the button, must be unique || ["INFO"]: the same as a 'menu template' above but without name or nested/nest (No multi-nest support, sorry)

Normal:		{ text = "Text Shown", name="INTERNAL_NAME_OF_BUTTON", func=function() doSomethingHere() end}, 
								Function is optional but if you don't give it a function, the button won't do anything...
								
Nested:		{ text = "Text Shown", name="INTERNAL_NAME_OF_BUTTON", nested = 1, nest = {
					{["NAME"]="INTERNAL_NAME_OF_NESTED_BUTTON1", ["INFO"]={text = "Click Me!", func=function() doSomethingHere() end}},
					{["NAME"]="INTERNAL_NAME_OF_NESTED_BUTTON2", ["INFO"]={text = "No, Click Me!", func=function() doSomethingHere() end}},
				}, 
			
			-- this is the function if you click the main sub-menu button - you can actually leave this off if you don't want it to do anything, and just want it as a mouse-over for the nested sub-menu.
			func = function()
				doSomethingHere()
			end
			},
]]


-------------------------------------------------------------------------------
-- Adding our Buttons to the Right-Click!
-------------------------------------------------------------------------------

-- create our onClickFunction storage table
local onClickFunction = {}

-- Creating Nested Menu options
for index, button in ipairs(menu) do
local name = addonData.prefix..button.name:upper()
	if button.nested == 1 and type(button.nest) == "table" then
		for key,value in ipairs(button.nest) do
			UnitPopupButtons[value["NAME"]] = value["INFO"]
			if not UnitPopupMenus[name] then UnitPopupMenus[name] = {} end
			table.insert(UnitPopupMenus[name], value["NAME"] )
			if value["INFO"].func then onClickFunction[value["NAME"]] = value["INFO"].func end
		end
	end
end

for _, items in pairs(UnitPopupMenus) do
	local doubleCheck = false
	local insertIndex
	for index, item in ipairs(items) do
		if item == "INTERACT_SUBSECTION_TITLE" then
			doubleCheck = true
		end
		if item == "OTHER_SUBSECTION_TITLE" and doubleCheck == true then
			insertIndex = index
		end
	end
	if insertIndex then
		for index, button in ipairs(menu) do
			local name = addonData.prefix..button.name:upper()
				UnitPopupButtons[name] = button
				onClickFunction[name] = button.func
				table.insert(items, insertIndex + index - 1, name)
		end
	end
end

hooksecurefunc("UnitPopup_OnClick", function(self)
	if onClickFunction[self.value] then onClickFunction[self.value]() end
end)

-------------------------------------------------------------------------------
-- Mod UI Functions
-------------------------------------------------------------------------------

function showModUI()
	QuickPhaseFrame01:Show();
	QPReasonBox:SetText("")
	QPPlayerNameBox:SetText(UIDROPDOWNMENU_INIT_MENU.name)
	QPReasonBox:SetFocus()
end

-- Making the GUI buttons do something OnClick

function QPSilenceCheckButton1_OnLoad()
	QPSilenceCheckButton1.silenced = false
end

function QPSilenceCheckButton1_OnClick()
	QPSilenceCheckButton1.silenced = not QPSilenceCheckButton1.silenced
end

function QPListButtonUI_OnClick()
local b = QPPlayerNameBox:GetText();
local d = QPReasonBox:GetText();
    cmd("phase blacklist add "..b);
	QuickPhaseFrame01.isKicking = true
	--updateCurrentPhase()
	QuickPhaseFrame01:Hide();
return msg;
end

function QPUnListButtonUI_OnClick()
local b = QPPlayerNameBox:GetText();
local d = QPReasonBox:GetText();
    cmd("phase blacklist remove "..b);
	QuickPhaseFrame01:Hide();
return msg;
end

function QPKickButtonUI_OnClick()
local b = QPPlayerNameBox:GetText();
local d = QPReasonBox:GetText();
    cmd("phase kick "..b);
	QuickPhaseFrame01.isKicking = true
	QuickPhaseFrame01:Hide();
	--updateCurrentPhase()
	kickPrint(b)
return msg;
end

-------------------------------------------------------------------------------
-- Chat Filter
-------------------------------------------------------------------------------

function kickPrint(name)
	kickPrintFailCheck = true
	C_Timer.After(1, function()
		if kickFailed then
			kickFailed = false
			kickPrintFailCheck = false
		else
			TimeRightNow = time()
			KickMessage = {
				"Kicking "..name.." from the phase.", -- [1]
				"", -- [2]
				"", -- [3]
				"", -- [4]
				"", -- [5]
				"", -- [6]
				0, -- [7]
				0, -- [8]
				"", -- [9]
				0, -- [10]
				2328, -- [11]
				nil, -- [12]
				0, -- [13]
				false, -- [14]
				false, -- [15]
				false, -- [16]
				false, -- [17]
				[30] = "CHAT_MSG_SYSTEM",
				[31] = TimeRightNow,
			}; -- [1]
			ChatFrame_MessageEventHandler(ChatFrame1, "CHAT_MSG_SYSTEM", unpack(KickMessage))
			kickPrintFailCheck = false
		end
	end)
end


function filter(self, event, msg, ...)
local clearmsg = gsub(msg,"|cff%x%x%x%x%x%x","");
local b = QPPlayerNameBox:GetText();
local d = QPReasonBox:GetText();
	if QuickPhaseFrame01.isKicking == true and clearmsg:find("Kicking "..b.." from the phase") then
		if d == nil or d == "" then
			whisper(b, '[ALERT] You have been kicked from phase '..currentPhase..'.');
				if QPSilenceCheckButton1.silenced == false then 
					cmd('phase announce [ALERT]: '..b..' has been kicked from the phase.'); 
				end
			QuickPhaseFrame01:Hide();
			QuickPhaseFrame01.isKicking = false;
		else
			whisper(b, '[ALERT] You have been kicked from phase '..currentPhase..' for reason: ' ..d);
				if QPSilenceCheckButton1.silenced == false then 
					cmd('phase announce [ALERT]: '..b..' has been kicked from the phase for reason: ' ..d);
				end
			QuickPhaseFrame01:Hide();
			QuickPhaseFrame01.isKicking = false;
		end
	elseif QuickPhaseFrame01.isKicking == true and clearmsg:find("Player has been added to the blacklist.") then
		if d == nil or d == "" then
			whisper(b, 'ALERT] You have been blacklisted from phase '..currentPhase..'.');
				if QPSilenceCheckButton1.silenced == false then 
					cmd('phase announce [ALERT]: '..b..' has been listed from the phase.');
				end
			QuickPhaseFrame01:Hide();
			QuickPhaseFrame01.isKicking = false;
		else
			whisper(b, 'ALERT] You have been listed from phase '..currentPhase..' for reason: ' ..d);
				if QPSilenceCheckButton1.silenced == false then 
					cmd('phase announce [ALERT]: '..b..' has been listed from the phase for reason: ' ..d);
				end
			QuickPhaseFrame01:Hide();
			QuickPhaseFrame01.isKicking = false;
		end
	elseif kickPrintFailCheck == true and (clearmsg:find("You must be an officer to use this command.") or clearmsg:find("Player not found.") or clearmsg:find("Player is not in your phase.")) then
		kickFailed = true
		kickPrintFailCheck = false;
	elseif QuickPhaseFrame01.isKicking == true then
		QuickPhaseFrame01.isKicking = false;
	end
end

-- Turning the Filter on

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filter)


-- local loginevent = CreateFrame("frame","loginevent");
-- loginevent:RegisterEvent("PLAYER_ENTERING_WORLD");
-- loginevent:SetScript("OnEvent", function(self, event)
	-- if event == "PLAYER_ENTERING_WORLD" then
		-- updateCurrentPhase()
	-- end
-- end);

-------------------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------------------

SLASH_CCQKVERSION1, SLASH_CCQKVERSION2 = '/QuickPhase', '/qp'; -- 3.
function SlashCmdList.CCQKVERSION(msg, editbox) -- 4.
 print("|cffFF6060QuickPhase v"..currentVersion);
end

SLASH_CCQKDEVBOX1 = '/qpbox'; -- 3.
function SlashCmdList.CCQKDEVBOX(msg, editbox) -- 4.
 QuickPhaseFrame01:Show();
end

--- End for now