
-------------------- GLOBALS/LOCALS/UPVALUES --------------------
SWH = LibStub("AceAddon-3.0"):NewAddon(CreateFrame("Frame", "SinestraWrackHelper"), "SinestraWrackHelper", "AceEvent-3.0", "AceConsole-3.0")
local SWH = SWH
local L = LibStub("AceLocale-3.0"):GetLocale("SinestraWrackHelper", true)
local LSM = LibStub("LibSharedMedia-3.0")
local LBZ = LibStub("LibBabble-Zone-3.0", true)
local BZ = LBZ and LBZ:GetLookupTable() or setmetatable({}, {__index = function(t,k) return k end})

local GetTime, sort, ipairs, pairs, rawget, ceil, format, max, random =
	  GetTime, sort, ipairs, pairs, rawget, ceil, format, max, random
local UnitClass, UnitName, UnitDebuff, UnitBuff, GetSpellTexture, GetRealZoneText, UnitPlayerOrPetInRaid, CreateFrame =
	  UnitClass, UnitName, UnitDebuff, UnitBuff, GetSpellTexture, GetRealZoneText, UnitPlayerOrPetInRaid, CreateFrame

local debug = SWH_DEBUG
local clientVersion = select(4, GetBuildInfo())

local db, st, co, bkg
local bars
local orderedBars = {}


-------------------- OPTIONS --------------------
local Defaults = {
	profile = {
		Locked		=	true,
		barx		=	160,
		bary		=	20,
		barMax		=	20,
		barspace	=	0,
		bardir		=	-1,
		st		 	= 	{r=0, g=1, b=0, a=1},
		co 			= 	{r=1, g=0, b=0, a=1},
		bkg 		= 	{r=0, g=0, b=0, a=0.5},
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
	Name = L["FONT_HEADER_PLAYERNAME"],
	Time = L["FONT_HEADER_TIMEACTIVE"],
	Damage = L["FONT_HEADER_LASTDAMAGE"],
}
local fontsettingorders = {
	Name = 10,
	Time = 11,
	Damage = 12,
}
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
			name = L["ENABLED"],
			desc = L["FONT_ENABLE"],
			type = "toggle",
			order = 1,
		},
		Name = {
			name = L["FONT_TYPEFACE"],
			type = "select",
			order = 3,
			dialogControl = 'LSM30_Font',
			values = LSM:HashTable("font"),
		},
		Outline = {
			name = L["FONT_OUTLINE"],
			type = "select",
			values = {
				MONOCHROME = L["MONOCHROME"],
				OUTLINE = L["OUTLINE"],
				THICKOUTLINE = L["THICKOUTLINE"],
			},
			style = "dropdown",
			order = 11,
		},
		Size = {
			name = L["FONT_SIZE"],
			type = "range",
			width = "full",
			order = 12,
			softMin = 6,
			softMax = 26,
			step = 1,
			bigStep = 1,
		},
		x = {
			name = L["XOFFS"],
			type = "range",
			width = "full",
			order = 21,
			softMin = -100,
			softMax = 100,
			step = 1,
			bigStep = 1,
		},
		y = {
			name = L["YOFFS"],
			width = "full",
			type = "range",
			order = 22,
			softMin = -40,
			softMax = 40,
			step = 1,
			bigStep = 1,
		},
		Color = {
			name = L["FONT_COLOR"],
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
			name = L["BAR_HEADER"],
			order = 1,
			args = {
				Locked = {
					name = L["LOCKED"],
					desc = L["CONFIG_LOCK"],
					type = "toggle",
					order = 1,
					set = function(info, val)
						db.profile.Locked = not val -- intended since the value is switching in SWH:ToggleLock()
						SWH:ToggleLock()
					end,
				},
				barx = {
					name = L["BAR_WIDTH"],
					type = "range",
					order = 2,
					width = "full",
					softMin = 10,
					softMax = 500,
					step = 1,
					bigStep = 1,
				},
				bary = {
					name = L["BAR_HEIGHT"],
					type = "range",
					order = 3,
					width = "full",
					softMin = 10,
					softMax = 50,
					step = 0.1,
					bigStep = 0.1,
				},
				barspace = {
					name = L["BAR_SPACING"],
					desc = L["BAR_SPACING_DESC"],
					type = "range",
					order = 4,
					width = "full",
					min = 0,
					softMax = 20,
					step = 0.1,
					bigStep = 0.1,
				},
				bardir = {
					name = L["BAR_DIRECTION"],
					desc = L["BAR_DIRECTION_DESC"],
					type = "select",
					style = "radio",
					order = 4,
					values = {
						[-1] = L["DOWN"],
						[1] = L["UP"],
					},
				},
				barMax = {
					name = L["BAX_MAX"],
					desc = L["BAR_MAX_DESC"],
					type = "range",
					order = 7,
					width = "full",
					min = 1,
					softMax = 60,
					step = 1,
					bigStep = 1,
				},
				barTexture = {
					name = L["BAR_TEXTURE"],
					type = "select",
					order = 9,
					dialogControl = 'LSM30_Statusbar',
					values = LSM:HashTable("statusbar"),
				},
				color = {
					type = "group",
					name = L["BAR_COLORS"],
					order = 20,
					guiInline = true,
					dialogInline = true,
					set = function(info, r, g, b, a)
						local c = db.profile[info[#info]]
						c.r = r
						c.g = g
						c.b = b
						c.a = a
						SWH:Update()
					end,
					get = function(info)
						local c = db.profile[info[#info]]
						return c.r, c.g, c.b, c.a
					end,
					args = {
						st = {
							name = L["BAR_COLOR_START"],
							desc = L["BAR_COLOR_START_DESC"],
							type = "color",
							hasAlpha = true,
							order = 1,
						},
						co = {
							name = L["BAR_COLOR_END"],
							desc = L["BAR_COLOR_END_DESC"],
							type = "color",
							hasAlpha = true,
							order = 2,
						},
						bkg = {
							name = L["BAR_COLOR_BKG"],
							desc = L["BAR_COLOR_BKG_DESC"],
							type = "color",
							hasAlpha = true,
							order = 3,
						},
					},
				},
			},
		},
		auras = {
			type = "group",
			name = L["ICON_HEADER"],
			desc = L["ICON_DESC"],
			order = 2,
			args = {
				icenabled = {
					name = L["ENABLED"],
					desc = L["ICON_ENABLE_DESC"],
					type = "toggle",
					order = 1,
				},
				icside = {
					name = L["ICON_ANCHORSIDE"],
					type = "select",
					style = "radio",
					order = 2,
					values = {
						[-1] = L["LEFT"],
						[1] = L["RIGHT"],
					},
				},
				icscale = {
					name = L["SCALE"],
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
					name = L["XOFFS"],
					type = "range",
					width = "full",
					order = 21,
					softMin = -20,
					softMax = 20,
					step = 1,
					bigStep = 1,
				},
				icy = {
					name = L["YOFFS"],
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


-------------------- DATA --------------------
local wrack = {
    [89421] = 1,
	[89435] = 1,
	[92955] = 1,
	[92956] = 1,
}
local reductions = {
    [47585] = 1, -- disperse
    [48707] = 1, -- AMS
    [50461] = 1, -- AMZ
    [47788] = 1, -- guardian spirit
    [33206] = 1, -- pain supp
}
for k, v in pairs(reductions) do
	reductions[k] = GetSpellInfo(k)
end


-------------------- BAR CONTAINER --------------------
SWH:SetMovable(1)
SWH.text = SWH:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SWH.text:SetText(L["CONFIG_TEXT"])

local function SortBars(a, b)
	if a.start and b.start then
		return a.start < b.start
	else
		return a.start
	end
end
local function Reposition()
	sort(orderedBars, SortBars)
	local y = 0
	for i, bar in ipairs(orderedBars) do
		if bar.active then
			bar:SetPoint("TOPLEFT", SWH, "TOPLEFT", 0, y*(db.profile.bary+db.profile.barspace)*db.profile.bardir)
			bar:Show()
			y = y + 1
		else
			bar:Hide()
		end
	end
end

function SWH:OnUpdate(elapsed)
	local time = GetTime()
	for name, bar in pairs(bars) do
		local start = bar.start
		if bar.active and start and not bar.isTest then
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
			bar:SetAlpha((co.a*pct) + (st.a * inv))

		end
	end
end


-------------------- BARS --------------------
local function UpdateBar(bar)

	---- SET SETTINGS ----
	bar:SetSize(db.profile.barx, db.profile.bary)
	bar.tex:SetTexture(LSM:Fetch("statusbar", db.profile.barTexture))
	bar:SetMinMaxValues(0, db.profile.barMax)

	local bkg = db.profile.bkg
	bar.bkg:SetTexture(bkg.r, bkg.g, bkg.b, bkg.a)

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
	---- SETTINGS SET ----


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
		elseif not bar.icEnabled then
			bar.ic:Hide()
			bar.cd:Hide()
		end
	else
		bar.ic:Hide()
		bar.cd:Hide()
	end

	if db.profile.Locked then
			bar:EnableMouse(0)
		bar.ic:SetTexture(bar.texpath)
		if bar.icEnabled then
			bar.ic:Show()
			bar.cd:Show()
		else
			bar.ic:Hide()
			bar.cd:Hide()
		end
		if bar.isTest then
			bar.active = nil
		end
		if bar.active and not bar.isTest then
			bar:Show()
		else
			bar:Hide()
		end
	else
		bar:EnableMouse(1)
		if bar.isTest then
			-- stupid hack because bars dont update their visual when their size changes unless their value is changed
			bar:SetValue(0)
			bar:SetValue(bar.isTest)
			-- update the color for when the max changes
			local pct = bar.isTest / db.profile.barMax
			local inv = 1-pct
			bar:SetStatusBarColor(
				(co.r*pct) + (st.r * inv),
				(co.g*pct) + (st.g * inv),
				(co.b*pct) + (st.b * inv),
				1
			)
			bar:SetAlpha((co.a*pct) + (st.a * inv))
			bar.active = 1
		else
			bar:Hide()
		end
	end
end
local function StartMoving()
	if not db.profile.Locked then
		SWH:StartMoving()
	end
end
local function StopMoving()
	if not db.profile.Locked then
		SWH:StopMovingOrSizing()
		local p = db.profile.point
		p.point, _, p.relpoint, p.x, p.y = SWH:GetPoint()
	end
end
local function OnShow(bar)
	bar:SetStatusBarColor(st.r, st.g, st.b, 1)
	bar:SetAlpha(st.a)
end
local function CreateBar(name)
	local bar = CreateFrame("StatusBar", "SWH_Bar_"..name, SWH)
	bar:SetScript("OnDragStart", StartMoving)
	bar:SetScript("OnDragStop", StopMoving)
	bar:SetScript("OnMouseUp", StopMoving)
	bar:SetScript("OnShow", OnShow)
	bar.UpdateBar = UpdateBar
	bar:RegisterForDrag("LeftButton")

	bar.bkg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bkg:SetAllPoints(bar)
	bar.bkg:SetTexture(1, 1, 1, 1)

	bar.tex = bar:CreateTexture()
	bar:SetStatusBarTexture(bar.tex)

	local namet = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.namet = namet
	namet:SetText(name)
	local _, class = UnitClass(name)
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
	bar:UpdateBar()

	tinsert(orderedBars, bar)
	return bar
end

bars = setmetatable({}, {__index = function(tbl, k)
	if not k then return end
	local bar = CreateBar(k)
	tbl[k] = bar
	return bar
end}) SWH.bars = bars


-------------------- GENERAL --------------------
function SWH:Update()
	local rzt = GetRealZoneText()
	if debug or rzt == BZ["The Bastion of Twilight"] or rzt == "The Bastion of Twilight" then
		SWH:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		SWH:SetScript("OnUpdate", SWH.OnUpdate)
	else
		SWH:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		SWH:SetScript("OnUpdate", nil)
		for name, bar in pairs(bars) do
			bar.active = nil
		end
	end

	st, co = db.profile.st, db.profile.co

	local p = db.profile.point
	SWH:ClearAllPoints()
	SWH:SetPoint(p.point, UIParent, p.relpoint, p.x, p.y)
	SWH:SetSize(db.profile.barx, db.profile.bary)
	SWH:Show()

	SWH.text:SetWidth(max(db.profile.barx, 150))
	SWH.text:ClearAllPoints()
	if db.profile.bardir == 1 then
		SWH.text:SetPoint("TOP", SWH, "BOTTOM")
	else
		SWH.text:SetPoint("BOTTOM", SWH, "TOP")
	end
	if db.profile.Locked then
		SWH.text:Hide()
	else
		SWH.text:Show()
	end
	for name, bar in pairs(bars) do
		bar:UpdateBar()
	end
	Reposition()
end

function SWH:ToggleLock()
	db.profile.Locked = not db.profile.Locked
	if not db.profile.Locked then
		for _, name in pairs({
			"TEST 1",
			"TEST 2",
			"TEST 3",
		}) do
			local bar = bars[name]
			local t = random(db.profile.barMax)
			bar.isTest = t

			bar.timet:SetText(t)
			bar:SetValue(t)
			bar.start = GetTime() - t
			local pct = t / db.profile.barMax
			local inv = 1-pct
			bar:SetStatusBarColor(
				(co.r*pct) + (st.r * inv),
				(co.g*pct) + (st.g * inv),
				(co.b*pct) + (st.b * inv),
				1)
			bar:SetAlpha((co.a*pct) + (st.a * inv))
			bar.ic:SetTexture(GetSpellTexture(47585))
			bar.dmgt:SetText(format("%.1f", (random(60000)/1000)) .. "k")

			bar.ic:Show()
			bar.cd:Show()
			bar:Show()
		end
		SWH.text:Show()
	end

	SWH:Update()
end

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

	SWH:RegisterEvent("ZONE_CHANGED_NEW_AREA", "Update")
	SWH:RegisterEvent("ZONE_CHANGED_INDOORS", "Update")

	for k, v in pairs(INTERFACEOPTIONS_ADDONCATEGORIES) do
		if v.addon == "SinestraWrackHelper" and not v.obj then -- this is the AddonLoader interface options stub
			tremove(INTERFACEOPTIONS_ADDONCATEGORIES, k)
			InterfaceAddOnsList_Update()
			break
		end
	end

	SWH:Update()
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
	elseif reductions[spellID] and db.profile.icenabled then
		local bar = bars[destName]
		if event == "SPELL_AURA_APPLIED" then
			local _, _, _, _, _, duration, expirationTime = UnitBuff(destName, spellName)
			local start = duration and expirationTime - duration
			if debug and not start then
				start = GetTime()
				duration = random(10)
			end
			if ( start and start > 0 and duration > 0) then
				bar.cd:SetCooldown(start, duration)
				bar.cd:Show()
			else
				bar.cd:Hide()
			end
			local tex = GetSpellTexture(spellID)
			bar.texpath = tex
			bar.ic:SetTexture(GetSpellTexture(spellID))
			bar.ic:Show()
			bar.icActive = 1
		elseif event == "SPELL_AURA_REMOVED" then
			bar.ic:Hide()
			bar.cd:Hide()
			bar.texpath = nil
			bar.icActive = nil
		end
	end
end

function SWH:SlashCommand(str)
	local cmd = SWH:GetArgs(str)
	cmd = strlower(cmd or "")
	if cmd == strlower(L["OPTIONS"]) or cmd == strlower(L["CONFIG"]) or cmd == "options" or cmd == "config" then --allow unlocalized "options" too
		LibStub("AceConfigDialog-3.0"):Open("Sinestra Wrack Helper Options")
	else
		SWH:ToggleLock()
	end
end
SWH:RegisterChatCommand("swh", "SlashCommand")
SWH:RegisterChatCommand("sinestrawrackhelper", "SlashCommand")
SWH:RegisterChatCommand("sinestrawh", "SlashCommand")











