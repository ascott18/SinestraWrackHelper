local SWH = LibStub("AceAddon-3.0"):NewAddon(CreateFrame("Frame", "SinestraWrackHelper"), "SinestraWrackHelper", "AceEvent-3.0", "AceConsole-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("SinestraWrackHelper", true)
local LSM = LibStub("LibSharedMedia-3.0")
local LBZ = LibStub("LibBabble-Zone-3.0", true)
local BZ = LBZ and LBZ:GetLookupTable() or setmetatable({}, {__index = function(t,k) return k end})

local sort, ipairs, pairs, rawget, ceil, format, max, random, UnitClass, UnitName, UnitDebuff, UnitBuff, GetSpellTexture, GetRealZoneText, UnitPlayerOrPetInRaid, CreateFrame = 
	  sort, ipairs, pairs, rawget, ceil, format, max, random, UnitClass, UnitName, UnitDebuff, UnitBuff, GetSpellTexture, GetRealZoneText, UnitPlayerOrPetInRaid, CreateFrame
	  
--@debug@
 _G.SWH = SWH
--@end-debug@

local GetTime = GetTime
local db, st, co
local clientVersion = select(4, GetBuildInfo())

local Defaults = {
	profile = {
		Locked		=	true,
		barx		=	160,
		bary		=	20,
		barMax		=	20,
		barspace	=	0,
		bardir		=	-1,
		st		 	= 	{r=0, g=1, b=0},
		co 			= 	{r=1, g=0, b=0},
		barTexture	= 	"Blizzard",
		icside		= 	-1,
		icscale		=	1,
		icx			=	0,
		icy			=	0,
		icenabled	=	true,
		point = {
			point = "TOP",
			relpoint = "CENTER",
			x = 200,
			y = 0,
		},
		Fonts = {
			["**"] = {
				Enabled = true,
				Name = "Arial Narrow",
				Size = 12,
				Outline = "OUTLINE",
				x = 0,
				y = 0,
				Color = NORMAL_FONT_COLOR
			},
			Name = {
				x = 3,
			},
			Time = {
				x = -40,
			},
			Damage = {
				x = -3,
			},
		},
	},
}

local fontsettingnames = {
	Name = L["Font - Player Name"],
	Time = L["Font - Time Active"],
	Damage = L["Font - Last Damage"],
}
local fontsettingorders = {
	Name = 10,
	Time = 11,
	Damage = 12,
}

local barContainer = CreateFrame("Frame", "SWH_Container", UIParent)
barContainer:SetMovable(1)
barContainer.text = barContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
barContainer.text:SetText(L["Click and drag bars to reposition. Type '/swh options' to display the options, and '/swh' to leave config mode."])
local backdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark"
}
local wrack = {
    [89421] = 1,
	[89435] = 1,
	[92955] = 1,
	[92956] = 1,
}
local reductions = {
    [642] = 1, -- pally bubble
    [45438] = 1, -- ice block
    [47585] = 1, -- disperse
    [48707] = 1, -- AMS
    [50461] = 1, -- AMZ
    [47788] = 1, -- guardian spirit
    [33206] = 1, -- pain supp
}
for k, v in pairs(reductions) do
	reductions[k] = GetSpellInfo(k)
end
local orderedBars = {}
local function sortbars(a, b)
	if a.start and b.start then
		return a.start < b.start
	else
		return a.start
	end
end
local function SetupBar(bar)
	bar:SetSize(db.profile.barx, db.profile.bary)
	bar.tex:SetTexture(LSM:Fetch("statusbar", db.profile.barTexture))
	bar:SetMinMaxValues(0, db.profile.barMax)
	if not db.profile.Locked then
		local pct = bar:GetValue() / db.profile.barMax
		local inv = 1 - pct
		bar:SetStatusBarColor(
			(co.r*pct) + (st.r * inv),
			(co.g*pct) + (st.g * inv),
			(co.b*pct) + (st.b * inv),
			1)
	end
	
	if db.profile.icenabled then
		local s = db.profile.icscale*db.profile.bary
		bar.ic:SetSize(s, s)
		bar.ic:ClearAllPoints()
		if db.profile.icside == -1 then
			bar.ic:SetPoint("RIGHT", bar, "LEFT", db.profile.icx, db.profile.icy)
		else
			bar.ic:SetPoint("LEFT", bar, "RIGHT", db.profile.icx, db.profile.icy)
		end
		if bar.isTest then
			bar.ic:Show()
			bar.cd:Show()
		end
	else
		bar.ic:Hide()
		bar.cd:Hide()
	end
	
	local f = db.profile.Fonts.Name
	bar.namet:SetPoint("LEFT", bar, f.x, f.y)
	bar.namet:SetFont(LSM:Fetch("font", f.Name), f.Size, f.Outline)
	if f.Enabled then
		bar.namet:Show()
	else
		bar.namet:Hide()
	end
	
	f = db.profile.Fonts.Damage
	bar.dmgt:SetPoint("RIGHT", bar, f.x, f.y)
	bar.dmgt:SetFont(LSM:Fetch("font", f.Name), f.Size, f.Outline)
	bar.dmgt:SetVertexColor(f.Color.r, f.Color.g, f.Color.b)
	if f.Enabled then
		bar.dmgt:Show()
	else
		bar.dmgt:Hide()
	end
	
	f = db.profile.Fonts.Time
	bar.timet:SetPoint("RIGHT", bar, f.x, f.y)
	bar.timet:SetFont(LSM:Fetch("font", f.Name), f.Size, f.Outline)
	bar.timet:SetVertexColor(f.Color.r, f.Color.g, f.Color.b)
	if f.Enabled then
		bar.timet:Show()
	else
		bar.timet:Hide()
	end
end
local function StartMoving()
	if not db.profile.Locked then
		barContainer:StartMoving()
	end
end
local function StopMoving()
	if not db.profile.Locked then
		barContainer:StopMovingOrSizing()
		local p = db.profile.point
		p.point, _, p.relpoint, p.x, p.y = barContainer:GetPoint()
	end
end
local bars = setmetatable({}, {__index = function(tbl, k)
	if not k then return end
	local bar = CreateFrame("StatusBar", "SWH_Bar_"..k, barContainer)
	bar:SetScript("OnDragStart", StartMoving)
	bar:SetScript("OnDragStop", StopMoving)
	bar:SetScript("OnMouseUp", StopMoving)
	bar.Setup = SetupBar
	bar:SetBackdrop(backdrop)
	bar:RegisterForDrag("LeftButton")
	
	bar.tex = bar:CreateTexture()
	bar:SetStatusBarTexture(bar.tex)
	
	local namet = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.namet = namet
	namet:SetText(k)
	local _, class = UnitClass(k)
	if class then
		local c = RAID_CLASS_COLORS[class]
		if c then
			namet:SetVertexColor(c.r, c.g, c.b, 1)
		end
	end
	bar.ic = bar:CreateTexture()
	bar.ic:SetTexCoord(.07, .93, .07, .93)
	bar.cd = CreateFrame("Cooldown", nil, bar)
	bar.cd:SetAllPoints(bar.ic)
	
	bar.dmgt = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.timet = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar:Setup()
	
	orderedBars[#orderedBars + 1] = bar
	sort(orderedBars, sortbars)
	tbl[k] = bar
	return bar
end})
--@debug@
 _G.SWH_bars = bars
--@end-debug@

local function Reposition()
	sort(orderedBars, sortbars)
	local y = 0
	for i, bar in ipairs(orderedBars) do
		if bar.active then
			bar:SetPoint("TOPLEFT", barContainer, "TOPLEFT", 0, y*(db.profile.bary+db.profile.barspace)*db.profile.bardir)
			bar:Show()
			y = y + 1
		else
			bar:Hide()
		end
		if db.profile.Locked then
			bar:EnableMouse(0)
		else
			bar:EnableMouse(1)
		end
	end
end

function SWH:Update()
	st, co = db.profile.st, db.profile.co
	SWH:ZONE_CHANGED_NEW_AREA()
	local p = db.profile.point
	barContainer:ClearAllPoints()
	barContainer:SetPoint(p.point, UIParent, p.relpoint, p.x, p.y)
	barContainer:SetSize(db.profile.barx, db.profile.bary)
	barContainer:Show()
	
	barContainer.text:SetWidth(max(db.profile.barx, 150))
	barContainer.text:ClearAllPoints()
	if db.profile.bardir == 1 then
		barContainer.text:SetPoint("TOP", barContainer, "BOTTOM")
	else
		barContainer.text:SetPoint("BOTTOM", barContainer, "TOP")
	end
	if db.profile.Locked then
		barContainer.text:Hide()
	else
		barContainer.text:Show()
	end
	for name, bar in pairs(bars) do
		bar:Setup()
	end
	Reposition()
end

local function ToggleLock()
	db.profile.Locked = not db.profile.Locked
	if db.profile.Locked then
		for name, bar in pairs(bars) do
			if bar.isTest then
				bar:Hide()
				bar.isTest = nil
				bar.active = nil
			end
			bar.ic:Hide()
		end
		SWH:Update()
	else
		local bar = bars[UnitName("player")]
		for _, name in pairs({
			UnitName("player"),
			(UnitName("raid1") or "raid1"),
			(UnitName("raid2") or "raid2"),
		}) do
			local bar = bars[name]
			bar.ic:SetTexture(GetSpellTexture(642))
			local t = random(25)
			bar.timet:SetText(t)
			bar:SetValue(t)
			local pct = t / db.profile.barMax
			local inv = 1-pct
			bar:SetStatusBarColor(
				(co.r*pct) + (st.r * inv),
				(co.g*pct) + (st.g * inv),
				(co.b*pct) + (st.b * inv),
				1)
			bar.active = 1
			bar.isTest = 1
			bar.dmgt:SetText(format("%.1f", (random(60000)/1000)) .. "k")
			bar:Show()
		end
		Reposition()
		barContainer.text:Show()
	end
end

local fontTemplate = {
	type = "group",
	name = function(info)
		return fontsettingnames[info[#info]]
	end,
	order = function(info)
		return fontsettingorders[info[#info]]
	end,
	set = function(info, val)
		db.profile.Fonts[info[#info-1]][info[#info]] = val
		SWH:Update()
	end,
	get = function(info) return db.profile.Fonts[info[#info-1]][info[#info]] end,
	args = {
		Enabled = {
			name = L["Enabled"],
			desc = L["Check to show this font string, uncheck to hide"],
			type = "toggle",
			order = 1,
		},
		Name = {
			name = L["Font Face"],
			type = "select",
			order = 3,
			dialogControl = 'LSM30_Font',
			values = LSM:HashTable("font"),
		},
		Outline = {
			name = L["Font outline style"],
			type = "select",
			values = {
				MONOCHROME = L["No Outline"],
				OUTLINE = L["Thin Outline"],
				THICKOUTLINE = L["Thick Outline"],
			},
			style = "dropdown",
			order = 11,
		},
		Size = {
			name = L["Font Size"],
			type = "range",
			width = "full",
			order = 12,
			softMin = 6,
			softMax = 26,
			step = 1,
			bigStep = 1,
		},
		x = {
			name = L["X offset"],
			type = "range",
			width = "full",
			order = 21,
			softMin = -100,
			softMax = 100,
			step = 1,
			bigStep = 1,
		},
		y = {
			name = L["Y offset"],
			width = "full",
			type = "range",
			order = 22,
			softMin = -40,
			softMax = 40,
			step = 1,
			bigStep = 1,
		},
		Color = {
			name = L["Font color"],
			type = "color",
			order = 30,
			set = function(info, r, g, b, a)
				local c = db.profile.Fonts[info[#info-1]][info[#info]]
				c.r = r
				c.g = g
				c.b = b
				SWH:Update()
			end,
			get = function(info)
				local c = db.profile.Fonts[info[#info-1]][info[#info]]
				return c.r, c.g, c.b
			end,
			hidden = function(info)
				return info[#info-1] == "Name"
			end,
		}
	},
}

local OptionsTable = {
	type = "group",
	set = function(info, val)
		db.profile[info[#info]] = val
		SWH:Update()
	end,
	get = function(info) return db.profile[info[#info]] end,
	args = {
		bars = {
			type = "group",
			name = L["Bar Options"],
			order = 1,
			args = {
				Locked = {
					name = L["Locked"],
					desc = L["Check to show this lock the movement and hide test bars, uncheck to unlock movement and show test bars"],
					type = "toggle",
					order = 1,
					set = function(info, val)
						db.profile.Locked = not val -- intended since the value is switching in ToggleLock()
						ToggleLock()
					end,
				},
				barx = {
					name = L["Bar Width"],
					type = "range",
					order = 2,
					width = "full",
					softMin = 10,
					softMax = 500,
					step = 1,
					bigStep = 1,
				},
				bary = {
					name = L["Bar Height"],
					type = "range",
					order = 3,
					width = "full",
					softMin = 10,
					softMax = 50,
					step = 0.1,
					bigStep = 0.1,
				},
				barspace = {
					name = L["Bar Spacing"],
					desc = L["The amount of space between each bar"],
					type = "range",
					order = 4,
					width = "full",
					min = 0,
					softMax = 20,
					step = 0.1,
					bigStep = 0.1,
				},
				bardir = {
					name = L["Growth Direction"],
					desc = L["Whether the bars should expand upwards or downwards."],
					type = "select",
					style = "radio",
					order = 4,
					values = {
						[-1] = L["Down"],
						[1] = L["Up"],
					},
				},
				barMax = {
					name = L["Maximum Bar value"],
					desc = L["The time, in seconds, that the bar will be full at. Higher times than this value will continue to show a full bar."],
					type = "range",
					order = 7,
					width = "full",
					min = 1,
					softMax = 60,
					step = 1,
					bigStep = 1,
				},
				barTexture = {
					name = L["Bar Texture"],
					type = "select",
					order = 9,
					dialogControl = 'LSM30_Statusbar',
					values = LSM:HashTable("statusbar"),
				},
				color = {
					type = "group",
					name = L["Colors"],
					order = 20,	
					guiInline = true,
					dialogInline = true,
					set = function(info, r, g, b, a)
						local c = db.profile[info[#info]]
						c.r = r
						c.g = g
						c.b = b
						SWH:Update()
					end,
					get = function(info)
						local c = db.profile[info[#info]]
						return c.r, c.g, c.b
					end,
					args = {
						st = {
							name = L["Start color"],
							desc = L["The color of the status bar when wrack has just been applied to a player"],
							type = "color",
							order = 1,
						},
						co = {
							name = L["End color"],
							desc = L["The color of the status bar when the bar has reached its max (when wrack should be dispelled)"],
							type = "color",
							order = 2,
						},
					},
				},
			},
		},
		auras = {
			type = "group",
			name = L["Icon Options"],
			desc = L["Configue the icon that is displayed to the side of the bar showing various buffs on the bar's unit that affect wrack"],
			order = 2,
			args = {
				icenabled = {
					name = L["Enabled"],
					desc = L["Check to show the icons to the side of bars that show various buffs that affect wrack's damage, uncheck to hide"],
					type = "toggle",
					order = 1,
				},
				icside = {
					name = L["Side of bar to anchor to"],
					type = "select",
					style = "radio",
					order = 2,
					values = {
						[-1] = L["Left"],
						[1] = L["Right"],
					},
				},
				icscale = {
					name = L["Scale"],
					type = "range",
					order = 7,
					width = "full",
					min = 0.1,
					softMin = 0.5,
					softMax = 2,
					step = 0.01,
					bigStep = 0.01,
				},
				icx = {
					name = L["X offset"],
					type = "range",
					width = "full",
					order = 21,
					softMin = -20,
					softMax = 20,
					step = 1,
					bigStep = 1,
				},
				icy = {
					name = L["Y offset"],
					width = "full",
					type = "range",
					order = 22,
					softMin = -20,
					softMax = 20,
					step = 1,
					bigStep = 1,
				},
				
			},
		},
		Name = fontTemplate,
		Time = fontTemplate,
		Damage = fontTemplate,
	},
}

function barContainer:OnUpdate(elapsed)
	local time = GetTime()
	for name, bar in pairs(bars) do
		local start = bar.start
		if bar.active and start then
			bar.timet:SetText(ceil(time-start))
			bar:SetValue(time-start)
			
			local pct = (time - start) / db.profile.barMax
			local inv = 1-pct
			bar:SetStatusBarColor(
				(co.r*pct) + (st.r * inv),
				(co.g*pct) + (st.g * inv),
				(co.b*pct) + (st.b * inv),
				1
			)
			
		end
	end
end
barContainer:SetScript("OnUpdate", barContainer.OnUpdate)

function SWH:OnInitialize()
	SWH.db = LibStub("AceDB-3.0"):New("SinestraWrackHelperDB", Defaults)
	db = SWH.db
	db.RegisterCallback(SWH, "OnProfileChanged", "Update")
	db.RegisterCallback(SWH, "OnProfileCopied", "Update")
	db.RegisterCallback(SWH, "OnProfileReset", "Update")
	db.RegisterCallback(SWH, "OnNewProfile", "Update")
	db.profile.Locked = true
	
	OptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Sinestra Wrack Helper Options", OptionsTable)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("Sinestra Wrack Helper Options", 610, 500)
	if not SWH.AddedToBlizz then
		SWH.AddedToBlizz = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Sinestra Wrack Helper Options", "Sinestra W.H.")
	else
		LibStub("AceConfigRegistry-3.0"):NotifyChange("Sinestra Wrack Helper Options")
	end
	
	SWH:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	SWH:RegisterEvent("ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA")
	SWH:Update()
end

function SWH:ZONE_CHANGED_NEW_AREA()
	if GetRealZoneText() == BZ["The Bastion of Twilight"] then
		SWH:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		SWH:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		for name, bar in pairs(bars) do
			bar.active = nil
		end
		Reposition()
	end
end

function SWH:COMBAT_LOG_EVENT_UNFILTERED(_, ...)
	local event, destName, spellID, spellName, amount, absorbed
	if clientVersion >= 40200 then
		_, event, _, _, _, _, _, _, destName, _, _, spellID, spellName, _, amount, _, _, _, _, absorbed = ...
	elseif clientVersion >= 40100 then
		_, event, _, _, _, _, _, destName, _, spellID, spellName, _, amount, _, _, _, _, absorbed = ...
	else
		_, event, _, _, _, _, destName, _, spellID, spellName, _, amount, _, _, _, _, absorbed = ...
	end
	if event == "UNIT_DIED" then
		local bar = rawget(bars, destName)
		if bar then
			bar.active = nil
			Reposition()
		end
	elseif wrack[spellID] then
		if UnitPlayerOrPetInRaid(destName) then
			local bar = bars[destName]
			if event == "SPELL_AURA_APPLIED" then
				bar.start = GetTime()
				bar.player = destName
				local _, _, _, _, _, duration, expirationTime = UnitDebuff(destName, spellName)
				bar.duration = duration
				bar.expirationTime = expirationTime
				bar.dmgt:SetText(0)
				bar.active = 1
				Reposition()
			elseif event == "SPELL_AURA_REMOVED" then
				bar.active = nil
				bar.dmgt:SetText(0)
				Reposition()
			elseif event == "SPELL_PERIODIC_DAMAGE" then
				amount = amount or 0
				absorbed = absorbed or 0
				bar.dmgt:SetText(format("%.1f", (amount + absorbed)/1000) .. "k")
			end
		end
	elseif reductions[spellID] and db.profile.icenabled then
		if UnitPlayerOrPetInRaid(destName) then
			local bar = bars[destName]
			if event == "SPELL_AURA_APPLIED" then
				local _, _, _, _, _, duration, expirationTime = UnitBuff(destName, spellName)
				local start = duration and expirationTime - duration
				if ( start and start > 0 and duration > 0) then
					bar.cd:SetCooldown(start, duration)
					bar.cd:Show()
				else
					bar.cd:Hide()
				end
		
				bar.ic:SetTexture(GetSpellTexture(spellID))
				bar.ic:Show()
			elseif event == "SPELL_AURA_REMOVED" then
				bar.ic:Hide()
				bar.cd:Hide()
			end
		end
	end
end

function SWH:SlashCommand(str)
	local cmd = SWH:GetArgs(str)
	cmd = strlower(cmd or "")
	if cmd == strlower(L["Options"]) or cmd == strlower(L["Config"]) or cmd == "options" or cmd == "config" then --allow unlocalized "options" too
		LibStub("AceConfigDialog-3.0"):Open("Sinestra Wrack Helper Options")
	else
		ToggleLock()
	end
end
SWH:RegisterChatCommand("swh", "SlashCommand")
SWH:RegisterChatCommand("sinestrawrackhelper", "SlashCommand")
SWH:RegisterChatCommand("sinestrawh", "SlashCommand")








