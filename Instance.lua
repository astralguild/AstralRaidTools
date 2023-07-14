local _, addon = ...

local EJ_GetEncounterInfo,EJ_GetInstanceInfo = EJ_GetEncounterInfo, EJ_GetInstanceInfo

addon.InInstance = false
addon.InstanceType = nil

addon.InEncounter = false
addon.Encounter = nil

function addon.GetInstanceChannel()
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and addon.InInstance then
		return 'INSTANCE_CHAT'
	elseif IsInRaid() then
		return 'RAID'
	elseif IsInGroup() then
		return 'PARTY'
	end
end

local bw, bwClear
do
	local isAdded = nil
	local prevPhase = nil
	function bw()
		if isAdded then
			return
		end
		if (BigWigsLoader) and BigWigsLoader.RegisterMessage then
			local r = {}
			function r:BigWigs_Message(event, module, key, text, ...)
				if (key == 'stages') then
					local phase = text:gsub ('.*%s', '')
					phase = tonumber(phase)
					if (phase and type(phase) == 'number' and prevPhase ~= phase) then
						prevPhase = phase
						addon.Encounter.phase = phase
					end
				end
			end
			BigWigsLoader.RegisterMessage(r, 'BigWigs_Message')
			isAdded = true
		end
	end
	function bwClear()
		prevPhase = nil
	end
end

AstralRaidEvents:Register('PLAYER_ENTERING_WORLD', function()
	addon.InInstance, addon.InstanceType = IsInInstance()
end, 'astralRaidGetInstance')

AstralRaidEvents:Register('ENCOUNTER_START', function(encounterID, encounterName, difficultyID, groupSize)
  addon.InEncounter = true
  addon.Encounter = {
    encounterID = encounterID,
    encounterName = encounterName,
    difficultyID = difficultyID,
    groupSize = groupSize,
    start = GetTime(),
    phase = 1,
  }
  bwClear()
	bw()
end, 'astralRaidStartEncounter')

AstralRaidEvents:Register('ENCOUNTER_END', function()
  addon.InEncounter = false
  addon.Encounter['end'] = GetTime()
end, 'astralRaidEndEncounter')

MYTHIC_DIFFICULTY = 16

addon.EncountersList = {
	{350,652,653,654,655,656,657,658,659,660,661,662},
	{331,651},
	{330,649,650},
	{332,623,624,625,626,627,628},
	{334,730,731,732,733},
	{329,618,619,620,621,622},
	{335,724,725,726,727,728,729},
	{129,519,520,2009,522,521,2010,2011,524,523,525,526,2012,527},
	{130,2002,2003,2004,2005},
	{132,1969,1966,1967,1989,1968},
	{133,2026,2024,2025},
	{136,2030,2027,2029,2028},
	{138,1987,1985,1984,1986},
	{140,1994,1996,1995,1998},
	{141,1094},
	{142,528,2013,530,529,2014,2015,532,531,533,534,2016,535},
	{162,1107,1110,1116,1117,1112,1115,1113,1109,1121,1118,1111,1108,1120,1119,1114},
	{155,1093,1092,1091,1090},
	{147,1132,1136,1139,1142,1140,1137,1131,1135,1141,1164,1165,1166,1133,1138,1134,1143,1130},
	{153,1978,1983,1980,1988,1981},
	{156,1126,1127,1128,1129},
	{157,1971,1972,1973},
	{160,1974,1976,1977,1975},
	{168,2018,2019,2020},
	{171,2022,2023,2021},
	{172,1088,1087,1086,1089,1085},
	{183,2006,2007},
	{184,1999,2001,2000},
	{185,1992,1993,1990},
	{186,1101,1100,1099,1096,1104,1097,1102,1095,1103,1098,1105,1106},
	{200,1147,1149,1148,1150},
	{213,1443,1444,1445,1446},
	{219,593,594,595,596,597,598,599,600},
	{220,492,488,486,487,490,491,493},
	{221,1667,1668,1669,1675,1676,1670,1671,1672},
	{225,1144,1145,1146},
	{226,379,378,380,381,382},
	{230,547,548,549,551,552,553,554,1887},
	{232,663,664,665,666,667,668,669,670,671,672},
	{233,785,784,786,787,788,789,790,791,792,793},
	{234,343,344,345,346,350,347,348,349,361,362,363,364,365,366,367,368},
	{242,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245},
	{246,1935,1936,1937,1938},
	{247,718,719,720,721,722,723},
	{248,1084},
	{250,267,268,269,270,271,272,274,273,275},
	{256,1889,1890},
	{258,1902,1903,1904},
	{260,1908,1909,1910,1911},
	{261,1922,1923,1924},
	{262,1945,1946,1947,1948},
	{263,1942,1943,1944},
	{265,1939,1940,1941},
	{266,1925,1926,1927,1928,1929},
	{267,1930,1931,1932,1933,1934},
	{269,1913,1914,1915,1916},
	{272,1899,1900,250,1901},
	{273,1919,1920,1921},
	{274,1905,1906,1907},
	{277,1052,1053,1054,1055},
	{279,585,586,587,588,589,590,591,592},
	{280,422,423,427,424,425,426,428,429},
	{282,1033,1250,1332},
	{283,1040,1038,1039,1037,1036},
	{285,1027,1024,1022,1023,1025,1026},
	{287,610,611,612,613,614,615,616,617},
	{291,1064,1065,1063,1062,1060,1081},
	{293,1051,1050,1048,1049},
	{294,1030,1032,1028,1029,1082,1083},
	{297,1080,1076,1075,1077,1074,1079,1078},
	{300,1662,1663,1664,1665,1666},
	{301,1656,438,1659,1660,1661},
	{302,444,446,447,448,449,450},
	{306,451,452,453,454,455,456,457,458,459,460,461,462,463},
	{310,1069,1070,1071,1073,1072},
	{317,473,474,476,475,477,478,472,479,480,481,482,483,484,1885},
	{319,709,710,711,712,713,714,715,716,717},
	{322,1045,1044,1046,1047},
	{324,1056,1059,1058,1057},
	{325,1043,1041,1042},
	{328,1035,1034},
	{333,1189,1190,1191,1192,1193,1194},
	{337,1178,1179,1188,1180,1181,1182},
	{339,601,602,603,604,605,606,607,608,609},
	{347,1891,1892,1893},
	{348,1894,1895,1897,1898},
	{367,1197,1204,1205,1206,1200,1185,1203},
	{398,1272,1273,1274},
	{399,1337,1340,1339},
	{401,1881,1882,1883,1884,1271},
	{409,1292,1294,1295,1296,1297,1298,1291,1299},
	{429,1418,1417,1416,1439},
	{431,1422,1421,1420},
	{435,1423,1424,1425},
	{437,1397,1405,1406,1419},
	{439,1412,1413,1414},
	{443,1303,1304,1305,1306},
	{453,1442,1509,1510,1441},
	{456,1409,1505,1506,1431},
	{457,1465,1502,1447,1464},
	{471,1395,1390,1434,1436,1500,1407},
	{474,1507,1504,1463,1498,1499,1501},
	{476,1426,1427,1428,1429,1430},
	{508,1577,1575,1570,1565,1578,1573,1572,1574,1576,1559,1560,1579,1580,1581},
	{554,1563,1564,1571,1587},
	{556,1602,1598,1624,1604,1622,1600,1606,1603,1595,1594,1599,1601,1593,1623,1605},
	{573,1655,1653,1652,1654},
	{574,1677,1688,1679,1682},
	{593,1686,1685,1678,1714},
	{595,1749,1748,1750,1754},
	{601,1698,1699,1700,1701},
	{606,1715,1732,1736},

	{616,1761,1758,1759,1760,1762},
	{620,1746,1757,1751,1752,1756},
	{624,1755,1770,1801},

	{703,1805,1806,1807,1808,1809},
	{708,1822,1823,1824},
	{710,1815,1850,1816,1817,1818},
	{713,1810,1811,1812,1813,1814},
	{731,1790,1791,1792,1793},
	{732,1845,1846,1847,1848,1851,1852,1855,1856},
	{733,1836,1837,1838,1839},
	{749,1825,1826,1827,1828,1829},
	{751,1832,1833,1834,1835},
	{761,1868,1869,1870},

	{790,1879,1880,1888,1917,1950,1951,1952,1953,1949},

	{809,1957,1954,1961,1960,1964,1965,1959,2017,2031},

	{845,2055,2057,2039,2053},

	{903,2065,2066,2067,2068},

	{934,2084,2085,2086,2087},
	{936,2093,2094,2095,2096},
	{974,2101,2102,2103,2104},
	{1010,2105,2106,2107,2108},
	{1015,2113,2114,2115,2116,2117},
	{1041,2111,2118,2112,2123},
	{1162,2098,2097,2109,2099,2100},
	{1038,2124,2125,2126,2127},
	{1039,2130,2131,2132,2133},
	{1004,2139,2142,2140,2143},
	{1490,2290,2292,2312,2291,2257,2258,2259,2260},

	{1666,2387,2388,2389,2390},
	{1674,2382,2384,2385,2386},
	{1669,2397,2392,2393},	
	{1663,2401,2380,2403,2381},
	{1693,2357,2356,2358,2359},
	{1683,2391,2365,2366,2364,2404},
	{1679,2395,2394,2400,2396},
	{1675,2360,2361,2362,2363},

	{2096,2570,2568,2567,2569},
	{2071,2555,2556,2557,2558,2559},
	{2093,2637,2636,2581,2580},
	{2080,2613,2612,2610,2611},
	{2097,2562,2563,2564,2565},
	{2095,2609,2606,2623},
	{2073,2582,2585,2583,2584},
	{2082,2615,2616,2617,2618},

  {610,1721,1706,1720,1722,1719,1723,1705},--HM
	{596,1696,1691,1693,1694,1689,1692,1690,1713,1695,1704},--BF
	{661,1778,1785,1787,1798,1786,1783,1788,1794,1777,1800,1784,1795,1799},--HFC
	{777,1853,1841,1873,1854,1876,1877,1864},--EN
	{806,1958,1962,2008},--tov
	{764,1849,1865,1867,1871,1862,1886,1842,1863,1872,1866},--nighthold
	{850,2032,2048,2036,2037,2050,2054,2052,2038,2051},--tos
	{909,2076,2074,2064,2070,2075,2082,2069,2088,2073,2063,2092},--antorus
	{1148,2144,2141,2136,2128,2134,2145,2135,2122},--uldir
	{1358,2265,2263,2284,2266,2285,2271,2268,2272,2276,2280,2281},	--bfd
	{1345,2269,2273},	--storms
	{1512,2298,2305,2289,2304,2303,2311,2293,2299},	--ethernal place
	{1582,2329,2327,2334,2328,2336,2333,2331,2335,2343,2345,2337,2344}, --nyalotha
	{1735,2398,2418,2402,2383,2405,2406,2412,2399,2417,2407},	--castle Nathria
	{1998,2423,2433,2429,2432,2434,2430,2436,2431,2422,2435},	--sod
	{2047,2512,2540,2553,2544,2539,2542,2529,2546,2543,2549,2537},	--sfo

	{2119,2587,2639,2590,2592,2635,2605,2614,2607},	--voti
	{2166,2688,2682,2687,2693,2680,2689,2683,2684,2685}, --a
}

local actualRaid = 1735
local actualDungeon = 1666
if UnitLevel'player' > 60 then
	actualDungeon = 2096
	actualRaid = 2119
end

function addon.GetEncountersList(onlyRaid, onlyActual, reverse)
	local list = {}
	local isActual, isRaid
	for _, v in ipairs(addon.EncountersList) do
		if v[1] == 610 then
			isRaid = true
			isActual = false
		elseif v[1] == actualDungeon then
			isActual = true
		elseif v[1] == actualRaid then
			isActual = true
		end
		if (not onlyActual or isActual) and (not onlyRaid or isRaid) then
			list[#list+1] = v
		end
	end
	if reverse then
		local len = #list
		for i=1,floor(len/2) do
			list[i], list[len+1-i] = list[len+1-i], list[i]
		end
	end
	return list
end

local encounterIDtoEJidData = {
	[2688] = 2522,	--Kazzara, the Hellforged
	[2682] = 2524,	--Assault of the Zaqali
	[2687] = 2529,	--The Amalgamation Chamber
	[2693] = 2530,	--The Forgotten Experiments
	[2680] = 2525,	--Rashok, the Elder
	[2689] = 2532,	--The Vigilant Steward, Zskarn
	[2683] = 2527,	--Magmorax
	[2684] = 2523,	--Echo of Neltharion
	[2685] = 2520,	--Scalecommander Sarkareth

	[2587] = 2480,	--Eranog
	[2639] = 2500,	--Terros
	[2590] = 2486,	--The Primalist Council
	[2592] = 2482,	--Sennarth, The Cold Breath
	[2635] = 2502,	--Dathea, Ascended
	[2605] = 2491,	--Kurog Grimtotem
	[2614] = 2493,	--Broodkeeper Diurna
	[2607] = 2499,	--Raszageth the Storm-Eater

	[2512] = 2458,	--Solitary Guardian
	[2540] = 2459,	--Dausegne, the Fallen Oracle
	[2553] = 2470,	--Artificer Xy'mox
	[2544] = 2460,	--Prototype Pantheon
	[2539] = 2461,	--Lihuvim, Principal Architect
	[2542] = 2465,	--Skolex, the Insatiable Ravener
	[2529] = 2463,	--Halondrus the Reclaimer
	[2546] = 2469,	--Anduin Wrynn
	[2543] = 2457,	--Lords of Dread
	[2549] = 2467,	--Rygelon
	[2537] = 2464,	--The Jailer

	[2423] = 2435,	--The Tarragrue
	[2433] = 2442,	--The Eye of the Jailer
	[2429] = 2439,	--The Nine
	[2432] = 2444,	--Remnant of Ner'zhul
	[2434] = 2445,	--Soulrender Dormazain
	[2430] = 2443,	--Painsmith Raznal
	[2436] = 2446,	--Guardian of the First Ones
	[2431] = 2447,	--Fatescribe Roh-Kalo
	[2422] = 2440,	--Kel'Thuzad
	[2435] = 2441,	--Sylvannas Windrunner

	[2398] = 2393,	--"Shriekwing (1)",
	[2418] = 2429,	--"Huntsman Altimor (2)",
	[2402] = 2422,	--"Kael'thas (3)",
	[2383] = 2428,	--"Hungering Destroyer (4)",
	[2405] = 2418,	--"Broker Curator (5)",
	[2406] = 2420,	--"Lady Inerva Darkvein (6)",
	[2412] = 2426,	--"The Council of Blood (7)",
	[2399] = 2394,	--"Sludgefist (8)",
	[2417] = 2425,	--"Stone Legion Generals (9)",
	[2407] = 2424,	--"Sire Denathrius (10)",

	[2329] = 2368,	--Wrathion
	[2327] = 2365,	--Maut
	[2334] = 2369,	--Prophet Skitra
	[2328] = 2377,	--Dark Inquisitor Xanesh
	[2336] = 2370,	--Vexiona
	[2333] = 2372,	--The Hivemind
	[2331] = 2364,	--Ra-den the Despoiled
	[2335] = 2367,	--Shad'har the Insatiable
	[2343] = 2373,	--Drest'agath
	[2345] = 2374,	--Il'gynoth, Corruption Reborn
	[2337] = 2366,	--Carapace of N'Zoth
	[2344] = 2375,	--N'Zoth the Corruptor

	[2298] = 2352,	--Abyssal Commander Sivara
	[2305] = 2353,	--Radiance of Azshara
	[2289] = 2347,	--Blackwater Behemoth
	[2304] = 2354,	--Lady Ashvane
	[2303] = 2351,	--Orgozoa
	[2311] = 2359,	--The Queen's Court
	[2293] = 2349,	--Za'qul
	[2299] = 2361,	--Queen Azshara

	[2269] = 2328,	--The Restless Cabal
	[2273] = 2332,	--Uu'nat, Harbinger of the Void

	[2265] = 2333,	--Frida Ironbellows, Paladin;  For alliance Ra'wani Kanae, 2344
	[2263] = 2325,	--Grong [horde]
	[2284] = 2340,	--Grong [alliance]
	[2266] = 2341,	--Flamefist and the Illuminated [horde]
	[2285] = 2323,	--Grimfang and Firecaller [alliance]
	[2271] = 2342,	--Treasure Guardian
	[2268] = 2330,	--Loa Council
	[2272] = 2335,	--King Rastakhan
	[2276] = 2334,	--Mekkatorque
	[2280] = 2337,	--Sea Priest
	[2281] = 2343,	--Jaina

	[2144] = 2168,	--Taloc
	[2141] = 2167,	--MOTHER
	[2136] = 2169,	--Zek'voz
	[2128] = 2146,	--Fetid Devourer
	[2134] = 2166,	--Vectis
	[2145] = 2195,	--Zul
	[2135] = 2194,	--Mythrax
	[2122] = 2147,	--G'huun

	[2076] = 1992,	--Garothi Worldbreaker
	[2074] = 1987,	--Hounds of Sargeras
	[2064] = 1985,	--Portal Keeper Hasabel
	[2070] = 1997,	--War Council
	[2075] = 2025,	--Eonar, the Lifebinder
	[2082] = 2009,	--Imonar the Soulhunter
	[2069] = 1983,	--Varimathras
	[2088] = 2004,	--Kin'garoth
	[2073] = 1986,	--The Coven of Shivarra
	[2063] = 1984,	--Aggramar
	[2092] = 2031,	--Argus the Unmaker

	[2032] = 1862,	--Горот
	[2048] = 1867,	--Демоны-инквизиторы
	[2036] = 1856,	--Харджатан
	[2037] = 1861,	--Госпожа Сашж'ин
	[2050] = 1903,	--Сестры Луны
	[2054] = 1896,	--Переносчик Погибели
	[2052] = 1897,	--Бдительная дева
	[2038] = 1873,	--Аватара Падшего
	[2051] = 1898,	--Кил'джеден

	[1849] = 1706,	--Скорпирон
	[1865] = 1725,	--Хрономатическая аномалия
	[1867] = 1731,	--Триллиакс
	[1871] = 1751,	--Заклинательница клинков Алуриэль
	[1862] = 1762,	--Тихондрий
	[1886] = 1761,	--Верховный ботаник Тел'арн
	[1842] = 1713,	--Крос
	[1863] = 1732,	--Звездный авгур Этрей
	[1872] = 1743,	--Великий магистр Элисанда
	[1866] = 1737,	--Гул'дан
	
	[1958] = 1819,	--Один
	[1962] = 1830,	--Гарм
	[2008] = 1829,	--Хелия

	[1853] = 1703,	--Низендра
	[1841] = 1667,	--Урсок
	[1873] = 1738,	--Ил'гинот, Сердце Порчи
	[1854] = 1704,	--Драконы Кошмара
	[1876] = 1744,	--Элерет Дикая Лань
	[1877] = 1750,	--Кенарий
	[1864] = 1726,	--Ксавий
	
	[1778] = 1426,
	[1785] = 1425,
	[1787] = 1392,
	[1798] = 1432,
	[1786] = 1396,
	[1783] = 1372,
	[1788] = 1433,
	[1794] = 1427,
	[1777] = 1391,
	[1800] = 1447,
	[1784] = 1394,
	[1795] = 1395,
	[1799] = 1438,
	
	[1801] = 1452,

	[1696] = 1202,
	[1691] = 1161,
	[1693] = 1155,
	[1694] = 1122,
	[1689] = 1123,
	[1692] = 1147,
	[1690] = 1154,
	[1713] = 1162,
	[1695] = 1203,
	[1704] = 959,

	[1721] = 1128,
	[1706] = 971,
	[1720] = 1196,
	[1722] = 1195,
	[1719] = 1148,
	[1723] = 1153,
	[1705] = 1197,

	[1064]=89,[1065]=90,[1063]=91,[1062]=92,[1060]=93,[1081]=95,[1069]=96,[1070]=97,[1071]=98,[1073]=99,[1072]=100,[1045]=101,
	[1044]=102,[1046]=103,[1047]=104,[1040]=105,[1038]=106,[1039]=107,[1037]=108,[1036]=109,[1056]=110,[1059]=111,[1058]=112,[1057]=113,
	[1043]=114,[1041]=115,[1042]=116,[1052]=117,[1054]=118,[1053]=119,[1055]=122,[1080]=124,[1076]=125,[1075]=126,[1077]=127,[1074]=128,
	[1079]=129,[1078]=130,[1051]=131,[1050]=132,[1048]=133,[1049]=134,[1033]=139,[1250]=140,[1035]=154,[1034]=155,[1030]=156,[1032]=157,
	[1028]=158,[1029]=167,[1082]=168,[1027]=169,[1024]=170,[1022]=171,[1023]=172,[1025]=173,[1026]=174,[1178]=175,[1179]=176,[788]=177,
	[788]=178,[788]=179,[788]=180,[1180]=181,[1181]=184,[1182]=185,[1189]=186,[1190]=187,[1191]=188,[1192]=189,[1193]=190,[1194]=191,[1197]=192,
	[1204]=193,[1206]=194,[1205]=195,[1200]=196,[1185]=197,[1203]=198,[1884]=283,[1883]=285,[1271]=289,[1272]=290,[1273]=291,[1274]=292,[1292]=311,[1296]=317,
	[1291]=318,[1337]=322,[1882]=323,[1294]=324,[1295]=325,[1297]=331,[1298]=332,[1299]=333,[1439]=335,[1332]=339,[1881]=340,[1339]=341,[1340]=342,[1667]=368,
	[227]=369,[228]=370,[229]=371,[230]=372,[231]=373,[232]=374,[233]=375,[234]=376,[235]=377,[236]=378,[237]=379,[238]=380,[239]=381,[241]=383,[242]=384,[243]=385,
	[244]=386,[245]=387,[267]=388,[268]=389,[269]=390,[270]=391,[271]=392,[272]=393,[274]=394,[273]=395,[275]=396,[343]=402,[344]=403,[345]=404,[346]=405,[350]=406,
	[347]=407,[348]=408,[349]=409,[361]=410,[362]=411,[363]=412,[364]=413,[365]=414,[366]=415,[367]=416,[368]=417,[381]=418,[379]=419,[378]=420,[380]=421,[382]=422,
	[422]=423,[423]=424,[427]=425,[1669]=426,[424]=427,[425]=428,[426]=429,[428]=430,[429]=431,[1663]=433,[1668]=436,[1671]=437,[473]=443,[1672]=444,[474]=445,[475]=446,
	[1676]=447,[477]=448,[478]=449,[472]=450,[479]=451,[480]=452,[481]=453,[482]=454,[483]=455,[484]=456,[492]=457,[488]=458,[493]=463,[1144]=464,[1145]=465,[1146]=466,
	[547]=467,[548]=468,[549]=469,[551]=470,[552]=471,[553]=472,[554]=473,[585]=474,[586]=475,[588]=476,[587]=477,[589]=478,[590]=479,[591]=480,[592]=481,[594]=483,[595]=484,
	[596]=485,[597]=486,[598]=487,[600]=489,[1890]=523,[1889]=524,[1893]=527,[1891]=528,[1892]=529,[1897]=530,[1898]=531,[1895]=532,[1894]=533,[1900]=534,[1901]=535,[250]=536,
	[1899]=537,[1905]=538,[1907]=539,[1906]=540,[1903]=541,[1904]=542,[1902]=543,[1908]=544,[1909]=545,[1911]=546,[1910]=547,[1916]=548,[1913]=549,[1915]=550,[1914]=551,
	[1920]=552,[1921]=553,[1919]=554,[1922]=555,[1924]=556,[1923]=557,[1925]=558,[1926]=559,[1928]=560,[1927]=561,[1929]=562,[1932]=563,[1930]=564,[1931]=565,[1936]=566,
	[1937]=568,[1938]=569,[1939]=570,[1941]=571,[1940]=572,[1942]=573,[1943]=574,[1944]=575,[1946]=576,[1945]=577,[1947]=578,[1948]=579,[1969]=580,[1966]=581,[1967]=582,
	[1989]=583,[1968]=584,[1971]=585,[1972]=586,[1973]=587,[1974]=588,[1976]=589,[1977]=590,[1975]=591,[1978]=592,[1983]=593,[1980]=594,[1988]=595,[1981]=596,[1987]=597,
	[1985]=598,[1984]=599,[1986]=600,[1992]=601,[1993]=602,[1990]=603,[1994]=604,[1996]=605,[1995]=606,[1998]=607,[1999]=608,[2001]=609,[2000]=610,[2002]=611,[2004]=612,
	[2003]=613,[2005]=614,[2006]=615,[2007]=616,[519]=617,[521]=618,[522]=619,[524]=620,[527]=621,[528]=622,[530]=623,[533]=624,[534]=625,[2020]=632,[2022]=634,[2022]=635,
	[2022]=636,[2021]=637,[2026]=638,[2024]=639,[2025]=640,[2030]=641,[2027]=642,[2029]=643,[2028]=644,[1419]=649,[1421]=654,[1397]=655,[1420]=656,[1304]=657,[1416]=658,
	[1426]=659,[1422]=660,[1427]=663,[1417]=664,[1428]=665,[1429]=666,[1412]=668,[1413]=669,[1414]=670,[1424]=671,[1418]=672,[1303]=673,[1425]=674,[1405]=675,[1406]=676,
	[1407]=677,[1395]=679,[1434]=682,[1409]=683,[1430]=684,[1305]=685,[1306]=686,[1436]=687,[1423]=688,[1390]=689,[2129]=690,[1447]=692,[1465]=693,[1443]=694,[1444]=695,
	[1445]=696,[1446]=697,[1441]=698,[1442]=708,[1431]=709,[1463]=713,[1500]=726,[1464]=727,[1935]=728,[1506]=729,[1499]=737,[1502]=738,[1498]=741,[1505]=742,[1501]=743,
	[1504]=744,[1507]=745,[1887]=748,[476]=749,[1570]=816,[1559]=817,[1572]=818,[1575]=819,[1574]=820,[1578]=821,[1576]=824,[1565]=825,[1577]=827,[1573]=828,[1560]=829,
	[1580]=831,[1579]=832,[519]=833,[2022]=834,[1595]=846,[1598]=849,[1603]=850,[1599]=851,[1602]=852,[1593]=853,[1606]=856,[1600]=864,[1601]=865,[1624]=866,[1604]=867,
	[1622]=868,[1623]=869,[1594]=870,[1622]=881,[1652]=887,[1653]=888,[1654]=889,[1655]=893,[438]=895,[1656]=896,[1659]=899,[1660]=900,[1661]=901,[1698]=965,[1699]=966,
	[1700]=967,[1701]=968,[1736]=1133,[1715]=1138,[1677]=1139,[1679]=1140,[1666]=1141,[1662]=1142,[1664]=1143,[1670]=1144,[1675]=1145,[1665]=1146,[1682]=1160,[1732]=1163,
	[1688]=1168,[1686]=1185,[1685]=1186,[1757]=1207,[1751]=1208,[1752]=1209,[1756]=1210,[1746]=1214,[1678]=1216,[1714]=1225,[1761]=1226,[1758]=1227,[1759]=1228,[1760]=1229,
	[1762]=1234,[1749]=1235,[1748]=1236,[1750]=1237,[1754]=1238,[1815]=1467,[1816]=1468,[1817]=1469,[1818]=1470,[1813]=1479,[1810]=1480,[1805]=1485,[1806]=1486,[1807]=1487,
	[1808]=1488,[1809]=1489,[1811]=1490,[1812]=1491,[1814]=1492,[1827]=1497,[1825]=1498,[1828]=1499,[1826]=1500,[1829]=1501,[1822]=1502,[1823]=1512,[1832]=1518,[663]=1519,
	[664]=1520,[665]=1521,[666]=1522,[667]=1523,[668]=1524,[669]=1525,[670]=1526,[671]=1527,[672]=1528,[610]=1529,[611]=1530,[612]=1531,[613]=1532,[614]=1533,[615]=1534,
	[616]=1535,[617]=1536,[718]=1537,[719]=1538,[720]=1539,[721]=1540,[722]=1541,[723]=1542,[709]=1543,[711]=1544,[712]=1545,[714]=1546,[710]=1547,[713]=1548,[715]=1549,
	[716]=1550,[717]=1551,[652]=1553,[653]=1554,[654]=1555,[655]=1556,[656]=1557,[658]=1559,[657]=1560,[659]=1561,[660]=1562,[661]=1563,[649]=1564,[650]=1565,[651]=1566,
	[623]=1567,[624]=1568,[625]=1569,[626]=1570,[627]=1571,[628]=1572,[730]=1573,[731]=1574,[732]=1575,[733]=1576,[618]=1577,[619]=1578,[620]=1579,[621]=1580,[622]=1581,
	[601]=1582,[602]=1583,[603]=1584,[604]=1585,[605]=1586,[606]=1587,[607]=1588,[608]=1589,[609]=1590,[724]=1591,[725]=1592,[726]=1593,[727]=1594,[728]=1595,[729]=1596,
	[1126]=1597,[1127]=1598,[1128]=1599,[1129]=1600,[1107]=1601,[1110]=1602,[1116]=1603,[1117]=1604,[1112]=1605,[1115]=1606,[1113]=1607,[1109]=1608,[1121]=1609,[1118]=1610,
	[1111]=1611,[1108]=1612,[1120]=1613,[1119]=1614,[1114]=1615,[1090]=1616,[1094]=1617,[1088]=1618,[1087]=1619,[1086]=1620,[1086]=1621,[1089]=1622,[1085]=1623,[1101]=1624,
	[1100]=1625,[1099]=1626,[1099]=1627,[1096]=1628,[1097]=1629,[1104]=1630,[1102]=1631,[1095]=1632,[1103]=1633,[1098]=1634,[1105]=1635,[1106]=1636,[1132]=1637,[1136]=1638,
	[1139]=1639,[1142]=1640,[1140]=1641,[1137]=1642,[1131]=1643,[1135]=1644,[1141]=1645,[1133]=1646,[1138]=1647,[1134]=1648,[1143]=1649,[1130]=1650,[1084]=1651,[1150]=1652,
	[1833]=1653,[1836]=1654,[1837]=1655,[1838]=1656,[1839]=1657,[1790]=1662,[1824]=1663,[1834]=1664,[1791]=1665,[1835]=1672,[1792]=1673,[1846]=1686,[1793]=1687,[1847]=1688,
	[1848]=1693,[1845]=1694,[1850]=1695,[1852]=1696,[1851]=1697,[1855]=1702,[1856]=1711,[1868]=1718,[1869]=1719,[1870]=1720,[660]=1764,[1965]=1817,[1959]=1818,[1957]=1820,
	[1954]=1825,[1957]=1826,[1957]=1827,[1960]=1835,[1964]=1836,[1961]=1837,[2017]=1838,[2053]=1878,[2039]=1904,[2055]=1905,[2057]=1906,[2065]=1979,[2066]=1980,[2067]=1981,
	[2068]=1982,[2087]=2030,[2085]=2036,[2084]=2082,[2086]=2083,[2094]=2093,[2095]=2094,[2096]=2095,[2104]=2096,[2101]=2097,[2102]=2098,[2103]=2099,[2093]=2102,[2105]=2109,
	[2106]=2114,[2107]=2115,[2108]=2116,[2113]=2125,[2114]=2126,[2115]=2127,[2116]=2128,[2117]=2129,[2112]=2130,[2118]=2131,[2098]=2132,[2097]=2133,[2099]=2134,[2100]=2140,
	[2124]=2142,[2125]=2143,[2126]=2144,[2127]=2145,[2130]=2153,[2131]=2154,[2132]=2155,[2133]=2156,[2111]=2157,[2123]=2158,[2139]=2165,[2140]=2170,[2142]=2171,[2143]=2172,
	[2109]=2173,[2260]=2331,[2257]=2336,[2258]=2339,[2259]=2348,[2291]=2355,[2290]=2357,[2292]=2358,[2312]=2360,[2317]=2362,[2318]=2363,[2351]=2378,[2353]=2381,
	[2380]=2387,[2360]=2388,[2364]=2389,[2366]=2390,[2388]=2391,[2389]=2392,[2387]=2395,[2390]=2396,[2391]=2397,[2400]=2398,[2357]=2399,[2397]=2400,[2365]=2401,[2392]=2402,
	[2384]=2403,[2386]=2404,[2393]=2405,[2401]=2406,[2363]=2407,[2395]=2408,[2394]=2409,[2396]=2410,[2403]=2411,[2359]=2412,[2381]=2413,[2358]=2414,[2361]=2415,[2356]=2416,
	[2404]=2417,[2382]=2419,[2362]=2421,[2385]=2423,[2411]=2430,[2410]=2431,[2409]=2432,[2408]=2433,
}

addon.MapToEncounter = {
	--BfD
	[1358] = {2265,2263,2266},
	[1352] = {2276,2280},
	[1353] = 2271,
	[1354] = 2268,
	[1357] = 2272,
	[1364] = 2281,

	--Uldir
	[1148] = 2144,
	[1149] = 2141,
	[1151] = 2136,
	[1153] = 2128,
	[1152] = 2134,
	[1154] = {2145,2135},
	[1155] = 2122,

	--5ppl
	[1010] = -1012,
	[934] = -968,	[935] = -968,
	[1004] = -1041,
	[1041] = -1022,	[1042] = -1022,
	[1038] = -1030,	[1043] = -1030,

	[1162] = -1023,
	[974] = -1002,	[975] = -1002,	[974] = -1002,	[975] = -1002,	[976] = -1002,	[977] = -1002,	[978] = -1002,	[979] = -1002,	[980] = -1002,
	[936] = -1001,
	[1039] = -1036,	[1040] = -1036,
	[1015] = -1021,	[1016] = -1021,	[1017] = -1021,	[1018] = -1021,	[1029] = -1021,

	--nyalotha
	[1581] = {2329,2327,2334},
	[1592] = 2328,
	[1593] = 2336,
	[1590] = 2333,
	[1591] = 2331,
	[1594] = 2335,
	[1595] = 2343,
	[1596] = 2345,
	[1597] = {2337,2344},

	--5ppl
	[1666] = -1182,	[1667] = -1182,	[1668] = -1182,
	[1674] = -1183,	[1697] = -1183,
	[1669] = -1184,
	[1663] = -1185,	[1664] = -1185,	[1665] = -1185,
	[1693] = -1186,	[1694] = -1186,	[1695] = -1186,
	[1683] = -1187,	[1684] = -1187,	[1685] = -1187,	[1687] = -1187,
	[1677] = -1188,	[1678] = -1188,	[1679] = -1188,	[1680] = -1188,
	[1675] = -1189,	[1676] = -1189,

	--nathria
	[1735] = {2398,2418,2383,2399},
	[1744] = 2406,
	[1745] = 2405,
	[1746] = 2402,
	[1747] = {2417,2407},
	[1748] = 2407,
	[1750] = 2412,

	--sod
	[1998] = 2423,
	[1999] = {2433,2429},
	[2000] = {2432,2434,2430},
	[2001] = {2436,2431,2422},
	[2002] = 2435,

	--sotfo
	[2047] = 2512,
	[2048] = 2540,
	[2049] = {2544,2539},
	[2061] = {2542,2553,2529},
	[2050] = 2546,
	[2052] = {2543,2549},
	[2051] = 2537,

	--a
	[2166] = {2688,2693,2680,2689,2683},
	[2167] = 2687,
	[2168] = 2682,
	[2169] = 2684,
	[2170] = 2685,
}

local encounterIDtoEJidChache, instanceIDtoEJidChache = {}, {}

local encounterIDtoNamePredef = {
	[2688] = "Kazzara, the Hellforged",
	[2682] = "Assault of the Zaqali",
	[2687] = "The Amalgamation Chamber",
	[2693] = "The Forgotten Experiments",
	[2680] = "Rashok, the Elder",
	[2689] = "The Vigilant Steward, Zskarn",
	[2683] = "Magmorax",
	[2684] = "Echo of Neltharion",
	[2685] = "Scalecommander Sarkareth",
}

addon.BossName = setmetatable({}, {__index=function (t, k)
	if not encounterIDtoEJidChache[k] then
		encounterIDtoEJidChache[k] = EJ_GetEncounterInfo(encounterIDtoEJidData[k] or 0) or encounterIDtoNamePredef[k] or ""
	end
	return encounterIDtoEJidChache[k]
end})

addon.EJInstanceName = setmetatable({}, {__index=function (t, k)
	if not instanceIDtoEJidChache[k] then
		instanceIDtoEJidChache[k] = EJ_GetInstanceInfo(k) or ""
	end
	return instanceIDtoEJidChache[k]
end})

function addon.GetBossName(bossID)
	if not bossID then return end
	return bossID < 0 and addon.EJInstanceName[-bossID] or addon.BossName[bossID]
end

function addon.GetBossAbilities(bossID, difficultyID)
	if not bossID then return end
	if not difficultyID then
		difficultyID = MYTHIC_DIFFICULTY
	end
	local abilities = {}
	EJ_SetDifficulty(difficultyID)
	local stack, _, _, _, curSectionID = {}, EJ_GetEncounterInfo(encounterIDtoEJidData[bossID])
	if not curSectionID then
		return {}
	end
	repeat
		local info = C_EncounterJournal.GetSectionInfo(curSectionID)
		if info.spellID and info.spellID > 0 then
			table.insert(abilities, info.spellID)
		end
		table.insert(stack, info.siblingSectionID)
		table.insert(stack, info.firstChildSectionID)
		curSectionID = table.remove(stack)
	until not curSectionID
	return abilities
end