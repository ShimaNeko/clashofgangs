// Advance login & register - by Gammix - v2.1 - last updated: 15 Jan, 2017
#include <a_samp>

#undef MAX_PLAYERS
#define MAX_PLAYERS 30

#include <sscanf2>
#include <zcmd>
#include <easydialog>
#include <YSI_Coding\y_va>
#include <KickBan>
#include <foreach>
//#include <mapfix>
#include <crashdetect>
#include <weapon-config>
#include <safeDialogs>
#include <a_zone>


#define COLOR_WHITE (0xFFFFFFFF)
#define COL_WHITE "{FFFFFF}"

#define COL_BLACK "{808080}"
#define COL_RED   "{cc0000}"

#define COLOR_TOMATO (0xFF6347FF)
#define COL_TOMATO "{FF6347}"

#define COLOR_YELLOW (0xFFDD00FF)
#define COL_YELLOW "{FFDD00}"

#define COLOR_GREEN (0x00FF00FF)
#define COL_GREEN "{00FF00}"

#define COLOR_DEFAULT (0xA9C4E4FF)
#define COL_DEFAULT "{A9C4E4}"

#define MAX_LOGIN_ATTEMPTS 3
#define MAX_ACCOUNT_LOCKTIME 2 // mins
#define COL_BLACK   "{808080}"	

#define MIN_PASSWORD_LENGTH 4
#define MAX_PASSWORD_LENGTH 45

//#define SECURE_PASSWORD_ONLY // this forces the user to have atleast 1 Lowercase, 1 Highercase and 1 Number in their password

#define MAX_SECURITY_QUESTION_SIZE 128

#define MAX_GANGS 50
#define MAX_ZONES 32

new rtvs;

new randomMessages[][] =
{
	"{808080}[HELP] "COL_WHITE"Хочешь поменять погоду и время? Используй "COL_GREEN"/weather (/w) "COL_WHITE"и "COL_GREEN"/time (/t)",
	"{808080}[HELP] "COL_WHITE"Команда, которая поможет в любую минуту: "COL_GREEN"/help",
	"{808080}[INFO] "COL_WHITE"Вся информация находится на сайте! "COL_GREEN"sa-gdm.ru",
	"{808080}[INFO] "COL_WHITE"Вступай в группу Вконтакте! "COL_GREEN"vk.com/unknowncommand",
	"{808080}[HELP] "COL_WHITE"Помощь по бандам: "COL_GREEN"/ghelp",
	"{808080}[HELP] "COL_WHITE"Хотите отдохнуть? Используйте "COL_GREEN"/afk",
	"{808080}[INFO] "COL_WHITE"Общайтесь с игроками и администрацией сервера в дискорде! "COL_GREEN"discord.gg/DqmMvsq"
};

new connect = 0;

new DB:db;

new objecthporarmour[MAX_PLAYERS];
new hpandarmourtimer[MAX_PLAYERS];

new Text:RequestClassTD[2];
//new Text:RequestClass;

new const SECURITY_QUESTIONS[][MAX_SECURITY_QUESTION_SIZE] =
{
	"Ваше прозвище в детстве?",
	"Имя вашего лучшего друга?",
	"В каком городе познакомились ваши родители?",
	"Ваша любимая команда?",
	"Ваш любимый мувик?",
	"Имя вашей первой девушки, которую поцеловали?",
	"Какой вам автомобиль впервые понравился?",
	"Имя госпиталя, где вы лечились?",
	"Ваш супергерой в детстве?",
	"Ваш любимое оружие в сампе?",
	"Имя последнего любимого учителя?"
};

new DuelTimer[MAX_PLAYERS];

enum e_Gang
{
	gangid,
	Tag[8],
	Exp,
	LeaderId,
	ArenaExp,
	Color
}
new GangsNew[MAX_GANGS][e_Gang];


enum e_Zone
{
	ID,
	Gangid,
	Exp
}
new zones[MAX_ZONES][e_Zone];

enum e_USER
{
	e_USER_SQLID,
	e_USER_PASSWORD[64 + 1],
	e_USER_SALT[64 + 1],
	e_USER_KILLS,
	e_USER_DEATHS,
	e_USER_SCORE,
	e_USER_MONEY,
	e_USER_ADMIN_LEVEL,
	e_USER_VIP_LEVEL,
	e_USER_REGISTER_TIMESTAMP,
	e_USER_LASTLOGIN_TIMESTAMP,
	e_USER_SECURITY_QUESTION[MAX_SECURITY_QUESTION_SIZE],
	e_USER_SECURITY_ANSWER[64 + 1],
	FPS,
	DLlast,
	Float:GiveDMG,
	Float:TakenDMG,
	Name[MAX_PLAYER_NAME],
	Level,
	Float:ArenaDMG,
	ArenaKills,
	GangId,
	GangExp,
	ArenaExp,
	DuelWon,
	DuelLose
};

new eUser[MAX_PLAYERS][e_USER];
new iLoginAttempts[MAX_PLAYERS];
new iAnswerAttempts[MAX_PLAYERS];

new PlayerText:FPSPingPacket[MAX_PLAYERS];
new PlayerText:DeathInfo[2][MAX_PLAYERS];
new PlayerText:InfoStats[MAX_PLAYERS][2];
new PlayerText:killsandexp[MAX_PLAYERS][2];
new PlayerText:GangInfo[MAX_PLAYERS];

new Text:InfoAndSite;
new Text:Clock;
new Text:TopOfArena;
new Text:ArenaTime;

new arena;
new RoundMints;
new RoundSeconds;
new bool:startarena = false;

new Float:ArenaPos[MAX_ZONES][10][3] =
{
    {
	    {199.3271,-107.8495,1.5508},
		{253.8040,-57.4364,1.5703},
	    {311.1269,-57.9108,1.5781},
		{363.9011,-101.2202,1.3372},
	    {391.8799,-172.7679,16.0720},
		{291.9951,-195.1209,1.5781},
	    {199.6330,-236.5303,1.5781},
		{116.7367,-194.2906,1.4950},
	    {163.7890,-153.8534,6.7786},
		{208.1323,-28.9609,1.5781}
	},
	{
		{-117.6009,-1406.8815,6.9875},
		{-36.3093,-1428.3921,4.0195},
		{3.1173,-1458.0244,5.1373},
		{-78.6710,-1530.6475,2.6644},
		{-120.2246,-1550.3876,2.6363},
		{-170.9063,-1497.5575,8.4163},
		{-198.5758,-1471.8666,8.6207},
		{-141.9719,-1453.9283,3.0391},
		{-141.9719,-1453.9283,3.0391},
		{-62.0870,-1360.2941,11.3062}
	},
	{
		{-1080.2462,-1661.1317,76.3672},
		{-1128.2567,-1676.5533,76.4800},
		{-1122.9022,-1605.6552,76.3672},
		{-1054.1301,-1606.6140,76.3739},
		{-1040.1477,-1653.4019,77.4222},
		{-981.0045,-1655.8722,76.3672},
		{-964.3530,-1704.7002,76.4494},
		{-1003.5140,-1735.5211,77.6600},
		{-1054.6912,-1785.9447,100.0276},
		{-1165.1685,-1692.6775,88.4065}		
	},
	{	
		{143.4053,1851.1617,25.0710},
		{111.7335,1811.9020,34.0283},
		{230.9175,1831.9939,23.2422},
		{261.6122,1806.0432,33.8984},
		{279.7722,1816.3359,17.6406},
		{259.5042,1886.7520,19.1019},
		{234.0700,1932.2518,33.8984},
		{166.4502,1936.1162,18.5184},
		{101.6568,1902.5211,33.8984},
		{147.6857,1876.3315,17.8440}
	},
	{	
		{-312.1247,1384.9166,72.6930},
		{-332.3731,1374.9681,56.6728},
		{-355.4742,1348.0245,48.5577},
		{-299.6983,1363.2628,67.3446},
		{-230.5454,1432.5276,73.3292},
		{-380.6775,1472.8209,63.0202},
		{-396.8501,1509.2867,75.5625},
		{-413.8633,1564.1060,70.8765},
		{-303.3299,1584.7087,75.3594},
		{-322.8676,1551.6902,75.5601}
	},
	{		
		{-1307.5992,1837.7758,36.6598},
		{-1275.0217,1905.6368,44.3675},
		{-1287.9385,1863.6003,40.1849},
		{-1271.4227,1810.4913,38.1554},
		{-1190.0623,1763.7402,34.6325},
		{-1135.2660,1760.9503,36.9976},
		{-1117.4746,1809.9155,42.6279},
		{-1142.7048,1859.6768,55.4762},
		{-1203.7050,1895.8788,52.3502},
		{-1223.0872,1839.1566,41.6308}
	},
	{	
		{-1693.9865,1250.4637,7.1861},
		{-1755.0350,1345.8792,7.0391},
		{-1680.6300,1406.8906,7.1813},
		{-1657.2709,1433.6844,7.1811},
		{-1651.8612,1412.7207,9.8047},
		{-1694.7844,1361.9662,9.8047},
		{-1619.3749,1290.9664,7.1745},
		{-1712.0288,1228.3987,20.6641},
		{-1727.2545,1245.2456,7.5469},
		{-1743.7363,1297.1917,7.0258}
	},
	{		
		{1926.7246,-2486.1550,13.5391},
		{1860.4501,-2466.3630,13.5547},
		{1859.6936,-2256.3105,13.5469},
		{1872.5875,-2305.0493,13.5469},
		{1847.6792,-2392.8220,13.5547},
		{1882.1873,-2395.2651,15.7741},
		{1947.0573,-2391.1914,13.5469},
		{1988.5778,-2330.7246,13.5469},
		{1973.2054,-2253.2524,13.5469},
		{1984.3483,-2386.6633,13.5469}
	},
	{		
		{1547.5446,-2284.7368,13.3828},
		{1809.1184,-2191.3201,13.3818},
		{1668.8245,-2192.4805,13.3750},
		{1665.7780,-2383.0181,13.3750},
		{1819.2915,-2382.9509,13.5469},
		{1801.5446,-2318.2529,13.3828},
		{1770.9637,-2241.0320,13.5507},
		{1597.6676,-2245.8821,13.5394},
		{1583.9819,-2309.9514,13.5469},
		{1683.1620,-2330.6172,13.5469}
	},
	{	
		{1544.8311,-2286.6042,-2.9922},
		{1585.2820,-2242.6851,-2.7914},
		{1571.4890,-2324.4758,-2.6911},
		{1679.3469,-2289.5159,-1.2255},
		{1686.8708,-2331.4680,-2.6797},
		{1749.9564,-2330.6191,-2.6797},
		{1803.7800,-2310.4446,-2.6219},
		{1760.4454,-2287.3591,-2.7732},
		{1740.7540,-2243.0215,-2.6910},
		{1655.0857,-2243.4380,-2.6896}
	},
	{	
		{728.0560,-1256.8760,13.5557},
		{701.5665,-1281.1720,26.0412},
		{702.2941,-1263.3900,22.9327},
		{649.8145,-1311.2184,13.5555},
		{724.7694,-1304.6520,13.5701},
		{777.8917,-1306.3384,13.5567},
		{784.3065,-1206.5520,16.7744},
		{774.8579,-1163.5959,23.0844},
		{724.4034,-1182.4408,20.0376},
		{660.6860,-1228.6023,15.7452}
	},
	{
		{8.2674,-2631.4358,40.1128},
		{-55.3323,-2678.1758,77.8069},
		{-101.6990,-2618.3157,74.1566},
		{-166.7960,-2562.0210,41.2642},
		{-108.1469,-2500.9338,36.8207},
		{-49.0322,-2571.2065,42.8422},
		{-14.9023,-2480.6978,36.6484},
		{4.6450,-2519.6978,36.6484},
		{-21.4996,-2536.0256,36.6484},
		{-46.8964,-2493.4619,36.6028}
	},
	{		
		{-1537.9812,-2697.8601,60.6234},
		{-1581.8527,-2663.2866,60.4357},
		{-1645.8212,-2649.2463,53.9602},
		{-1685.3318,-2681.6184,48.5793},
		{-1678.8676,-2728.0603,46.1086},
		{-1566.9668,-2830.8726,45.6955},
		{-1535.1263,-2786.5266,47.4972},
		{-1544.9314,-2735.1108,48.5356},
		{-1586.0879,-2699.8438,48.5391},
		{-1666.0796,-2673.0515,48.6614}
	},
	{	
		{-2228.1426,-2373.2917,32.6078},
		{-2128.9963,-2291.3950,30.4688},
		{-2093.0269,-2332.6255,30.6250},
		{-2096.6785,-2375.4153,30.6250},
		{-2036.8303,-2468.1648,31.0163},
		{-2053.8865,-2530.6323,30.5628},
		{-2109.8040,-2504.4460,30.4688},
		{-2147.5386,-2481.1025,30.4688},
		{-2184.9177,-2432.7480,35.5234},
		{-2161.7510,-2350.6030,37.7437}
	},
	{		
		{-1843.1581,-1699.3151,23.2031},
		{-1844.9265,-1709.7623,41.1102},
		{-1873.5664,-1666.3727,25.2363},
		{-1855.3109,-1619.4558,21.9154},
		{-1830.9406,-1696.1698,21.7500},
		{-1781.5905,-1656.3510,24.2535},
		{-1754.9564,-1598.8660,19.9164},
		{-1862.5526,-1544.4542,21.7500},
		{-1898.3539,-1617.3563,21.7564},
		{-1904.2131,-1669.7869,23.0215}
	},
	{		
		{-2393.2476,-695.0678,133.1328},
		{-2344.7676,-676.4212,115.9655},
		{-2420.1995,-521.6288,118.8842},
		{-2504.3962,-476.2538,93.3743},
		{-2539.3171,-538.4984,115.8783},
		{-2538.4099,-612.7305,132.7109},
		{-2531.6321,-706.6327,139.3203},
		{-2490.1807,-681.2098,139.3203},
		{-2467.0635,-633.0711,132.8563},
		{-2413.5664,-599.6294,132.5625}
	},
	{	
		{-994.3618,-569.6893,29.1663},
		{-1065.7390,-583.6436,32.0078},
		{-1013.3826,-574.4502,32.0126},
		{-998.2231,-760.7855,37.3881},
		{-978.9332,-723.7239,32.0078},
		{-990.4335,-608.2476,32.0078},
		{-1113.0210,-593.1164,32.0078},
		{-1124.4882,-648.2303,32.0078},
		{-1077.0826,-720.9175,32.0078},
		{-1082.0474,-674.1151,32.3516}
	},
	{	
		{-577.7167,-218.4710,75.1632},
		{-527.6451,-230.9053,74.4940},
		{-519.8485,-130.0396,69.2777},
		{-583.8763,-159.2048,78.8116},
		{-559.4687,-206.4623,78.4393},
		{-499.1244,-209.2373,78.4063},
		{-458.2187,-175.8745,77.5474},
		{-479.3012,-112.4710,63.6143},
		{-429.8428,-46.3426,58.8433},
		{-507.5950,-33.5961,58.9931}
	},
	{	
		{1967.4458,-1198.8737,25.6528},
		{1967.2267,-1157.4713,20.9619},
		{1967.7073,-1235.6586,20.0542},
		{1848.8853,-1256.4127,13.3906},
		{1851.7183,-1196.3280,22.9700},
		{1925.6420,-1226.1771,19.2948},
		{1979.4081,-1258.2629,23.8203},
		{2037.9091,-1203.8202,22.7631},
		{1991.0977,-1163.9252,20.7647},
		{1970.7039,-1133.2235,25.8047}
	},
	{
		{1295.1262,-960.8229,41.8669},
		{1301.5365,-854.4642,43.5616},
		{1220.2271,-876.2722,42.8962},
		{1269.4114,-891.4436,42.8828},
		{1289.6699,-981.5960,32.6953},
		{1243.8702,-973.2240,42.5828},
		{1188.2609,-991.1951,43.4843},
		{1101.8500,-980.3213,42.7656},
		{1106.4532,-924.9628,43.3906},
		{1179.8901,-918.2614,43.2545}
	},
	{// By LENZA4		
		{2333.0596,197.0998,26.6107},
		{2529.0986,124.1290,26.4844},
		{2451.6458,4.1732,26.9844},
		{2306.2551,-8.7192,32.5313},
		{2319.5391,75.3606,26.4844},
		{2257.0027,71.2372,26.4844},
		{2188.5164,67.3270,27.8594},
		{2240.0771,-81.1857,26.5054},
		{2319.6128,-65.0935,26.4844},
		{2324.5518,-3.9855,26.5608}
	},
	{
		{-883.5191,1622.7856,26.4768},
		{-829.2407,1577.0101,26.8890},
		{-797.4338,1631.8995,27.0301},
		{-743.8248,1606.5542,27.1172},
		{-787.8079,1551.5485,27.1172},
		{-727.3171,1518.3662,38.9756},
		{-731.0945,1437.1481,17.1084},
		{-793.1195,1422.6157,13.9453},
		{-873.6974,1417.5841,13.1855},
		{-904.1409,1550.2173,25.8655}
	},
	{
		{-210.2779,981.8387,19.3211},
		{-269.4838,1084.8779,19.7422},
		{-229.1533,1117.6676,19.7422},
		{-233.2554,1220.1951,19.7422},
		{-160.2376,1225.9962,19.7422},
		{-121.9957,1082.0491,19.7706},
		{-82.4282,1110.5616,19.7500},
		{-24.8243,1115.8434,19.7493},
		{-3.2754,1234.2488,19.3537},
		{73.5918,1165.7395,18.6641}
	},
	{
		{1288.7107,156.6082,20.4658},
		{1207.5764,214.6514,19.5547},
		{1231.1062,297.6661,19.5547},
		{1239.9689,352.8928,19.4063},
		{1293.5234,385.9736,19.5625},
		{1365.6749,367.8112,20.5547},
		{1341.9817,311.0604,19.5547},
		{1301.9663,218.9047,19.5547},
		{1372.3811,190.4671,19.5547},
		{1420.7540,273.9171,19.5547}
	},
	{		
		{613.5544,-608.6547,17.2266},
		{652.2842,-642.1307,16.7570},
		{690.0687,-652.6066,16.2838},
		{769.8741,-631.5466,16.2464},
		{785.1441,-564.9972,16.3359},
		{763.0064,-509.7736,17.1465},
		{725.6656,-457.8861,16.3359},
		{695.2827,-450.6134,16.3359},
		{620.5433,-459.0887,16.9422},
		{605.9757,-536.8126,16.3359}
	},
	{// By LENZA4
		{-1435.2596,-1539.6267,101.7578},
		{-1423.8771,-1500.8796,104.7272},
		{-1465.5680,-1551.8239,101.7578},
		{-1463.4614,-1511.2646,101.7513},
		{-1463.4498,-1469.4465,101.7578},
		{-1445.6218,-1447.2496,101.7578},
		{-1410.8513,-1470.7206,101.5832},
		{-1416.8712,-1543.5258,101.7578},
		{-1432.7771,-1595.4431,101.7578},
		{-1455.9938,-1576.2056,105.1250}
	},
	{		
		{-1971.6770,-928.5280,32.2266},
		{-1916.8606,-1013.9531,32.0998},
		{-1994.8364,-1019.1458,32.1719},
		{-2045.0686,-988.1426,32.1719},
		{-2064.5413,-875.8813,32.1719},
		{-2065.7578,-782.8444,32.1719},
		{-2043.2478,-733.3047,32.1719},
		{-1950.2069,-720.0175,32.1745},
		{-1898.7330,-826.3812,32.0234},
		{-1963.3284,-865.1557,32.2188}
	},
	{		
		{-2398.3076,-245.0612,35.6296},
		{-2485.1560,-282.6703,35.5660},
		{-2473.6458,-323.4105,41.8832},
		{-2534.4067,-321.5062,38.2839},
		{-2531.9509,-273.4191,38.7030},
		{-2484.0461,-243.1522,39.8111},
		{-2415.1201,-221.5000,40.1389},
		{-2447.2422,-303.2259,56.7562},
		{-2402.5110,-343.4897,66.1639},
		{-2298.9470,-343.2345,65.3505}
	},
	{		
		{-2185.3525,-248.8438,40.7195},
		{-2162.2026,-191.9786,35.3203},
		{-2198.4307,-224.9909,35.3203},
		{-2101.9419,-268.0126,35.3203},
		{-2107.9922,-201.7024,35.3203},
		{-2146.5344,-178.3698,35.3203},
		{-2145.4128,-119.3260,38.4395},
		{-2113.0200,-144.1096,35.3203},
		{-2098.2166,-112.3581,35.3203},
		{-2149.9961,-102.0861,35.3203}
	},
	{	
		{-2540.4175,1402.0911,7.5481},
		{-2555.5945,1357.2030,7.1797},
		{-2634.0476,1397.7725,7.0938},
		{-2649.7036,1373.8199,12.2522},
		{-2600.3557,1370.9905,7.1953},
		{-2651.4373,1335.3569,7.1906},
		{-2667.8394,1298.6844,7.1875},
		{-2714.9468,1385.0498,7.5129},
		{-2668.9954,1454.1125,7.1016},
		{-2597.6909,1432.7030,6.7046}
	},	
	{// By LENZA4
		{-2507.3704,2362.0598,4.9862},
		{-2482.8706,2347.8577,8.0195},
		{-2414.5547,2384.7725,7.8377},
		{-2435.3938,2489.1101,13.7817},
		{-2477.9067,2440.5652,16.0612},
		{-2536.1338,2375.5579,13.3706},
		{-2623.7808,2336.7444,8.3458},
		{-2528.5554,2226.5889,4.9792},
		{-2424.9373,2225.9746,4.9844},
		{-2423.0742,2314.6472,3.7197}
	},
	{	
		{2109.3352,2137.3555,10.8203},
		{2092.8770,2160.8911,10.8203},
		{2042.7686,2199.5852,10.8203},
		{2043.3914,2142.4280,10.8203},
		{2005.1063,2188.2073,10.8203},
		{2040.5265,2207.8818,10.8203},
		{2117.5107,2240.9900,10.8203},
		{2161.1021,2247.7378,10.8125},
		{2169.5996,2157.9138,10.8203},
		{2097.3044,2092.1506,10.8203}
	}					
};


/*{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{}*/

new gangs = 0;


main(){
	print("Всякой хуйни здесь не будет, не жди");
}

IpToLong(const address[])
{
	new parts[4];
	sscanf(address, "p<.>a<i>[4]", parts);
	return ((parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]);
}

ReturnTimelapse(start, till)
{
    new ret[32];
	new seconds = till - start;

	const
		MINUTE = 60,
		HOUR = 60 * MINUTE,
		DAY = 24 * HOUR,
		MONTH = 30 * DAY;

	if (seconds == 1)
		format(ret, sizeof(ret), "секунду");
	if (seconds < (1 * MINUTE))
		format(ret, sizeof(ret), "%i секунд", seconds);
	else if (seconds < (2 * MINUTE))
		format(ret, sizeof(ret), "минуту");
	else if (seconds < (45 * MINUTE))
		format(ret, sizeof(ret), "%i минут", (seconds / MINUTE));
	else if (seconds < (90 * MINUTE))
		format(ret, sizeof(ret), "час");
	else if (seconds < (24 * HOUR))
		format(ret, sizeof(ret), "%i часов", (seconds / HOUR));
	else if (seconds < (48 * HOUR))
		format(ret, sizeof(ret), "день");
	else if (seconds < (30 * DAY))
		format(ret, sizeof(ret), "%i дней", (seconds / DAY));
	else if (seconds < (12 * MONTH))
    {
		new months = floatround(seconds / DAY / 30);
      	if (months <= 1)
			format(ret, sizeof(ret), "месяц");
      	else
			format(ret, sizeof(ret), "%i месяца", months);
	}
    else
    {
      	new years = floatround(seconds / DAY / 365);
      	if (years <= 1)
			format(ret, sizeof(ret), "год");
      	else
			format(ret, sizeof(ret), "%i года/лет", years);
	}
	return ret;
}

public OnGameModeInit()
{
	db_debug_openresults();
    db = db_open("database.db");
	db_query(db, "PRAGMA synchronous = NORMAL");
 	db_query(db, "PRAGMA journal_mode = WAL");

	new string[1024];
	string = "CREATE TABLE IF NOT EXISTS `users`(\
		`id` INTEGER PRIMARY KEY, \
		`name` VARCHAR(24) NOT NULL DEFAULT '', \
		`ip` VARCHAR(18) NOT NULL DEFAULT '', \
		`longip` INT NOT NULL DEFAULT '0', \
		`password` VARCHAR(64) NOT NULL DEFAULT '', \
		`salt` VARCHAR(64) NOT NULL DEFAULT '', \
		`sec_question` VARCHAR("#MAX_SECURITY_QUESTION_SIZE") NOT NULL DEFAULT '', \
		`sec_answer` VARCHAR(64) NOT NULL DEFAULT '', ";
	strcat(string, "`register_timestamp` INT NOT NULL DEFAULT '0', \
		`lastlogin_timestamp` INT NOT NULL DEFAULT '0', \
		`kills` INT NOT NULL DEFAULT '0', \
		`deaths` INT NOT NULL DEFAULT '0', \
		`score` INT NOT NULL DEFAULT '0', \
		`money` INT NOT NULL DEFAULT '0', \
		`adminlevel` INT NOT NULL DEFAULT '0', \
		`viplevel` INT NOT NULL DEFAULT '0')");
	db_query(db, string);

	db_query(db, "CREATE TABLE IF NOT EXISTS `temp_blocked_users` (\
		`ip` VARCHAR(18) NOT NULL DEFAULT '', \
		`lock_timestamp` INT NOT NULL DEFAULT '0', \
		`user_id` INT NOT NULL DEFAULT '-1')");

	// CREATE TABLE EXISTS `gangs` (`id` INTEGER PRIMARY KEY,  `tag` VARCHAR(8) NOT NULL DEFAULT, `dmg` INT NOT NULL DEFAULT '0', `leaderid` INT NOT NULL DEFAULT '-1')

    EnableVehicleFriendlyFire();
    DisableInteriorEnterExits();
	UsePlayerPedAnims();
	SetGameModeText("FDM v?");	
	EnableStuntBonusForAll(0);	
    SetVehiclePassengerDamage(true);
    SetDisableSyncBugs(true);	
    SetTimer("OnScriptUpdate", 1000, true);
    SetTimer("teensecupdate", 60000, true);
    SetWeaponDamage(34, DAMAGE_TYPE_STATIC, 40.0);
    SetWeaponDamage(31, DAMAGE_TYPE_STATIC, 15.0);
   	gmtextdraws();
   	arena = random(MAX_ZONES);
   	ChangeArena();

   	new DBResult: Result;

    Result = db_query(db,"SELECT * FROM gangs");

    for(new i = 0; i < db_num_rows(Result); i++){
        GangsNew[gangs][gangid] = db_get_field_assoc_int(Result, "id");
        db_get_field_assoc(Result, "tag", GangsNew[gangs][Tag], 8);
        GangsNew[gangs][Exp] = db_get_field_assoc_int(Result, "dmg");
        GangsNew[gangs][LeaderId] = db_get_field_assoc_int(Result, "leaderid"); 
        GangsNew[gangs][Color] = db_get_field_assoc_int(Result, "Color"); 
        printf("Загружена %s[%d] с %d exp, цветом %d и лидер у нас %d id в бд пользователя и всего %d банд", GangsNew[gangs][Tag], GangsNew[gangs][gangid], GangsNew[gangs][Exp], GangsNew[gangs][Color], GangsNew[gangs][LeaderId], gangs+1); 
        gangs++;     	
       	db_next_row(Result);

    }
    db_free_result( Result );   


   	new DBResult: Resultt;

    Resultt = db_query(db,"SELECT * FROM zones");

    for(new i = 0; i < db_num_rows(Resultt); i++){
        zones[i][ID] = db_get_field_assoc_int(Resultt, "ID")-1;
        zones[i][Gangid] = db_get_field_assoc_int(Resultt, "Gangid"); 
        zones[i][Exp] = db_get_field_assoc_int(Resultt, "Exp");
        printf("Загружена зона номер %d с контролирующем %d и %d exp", zones[i][ID], zones[i][Gangid], zones[i][Exp]); 	
       	db_next_row(Resultt);
    }
    db_free_result( Resultt );     

    for(new i = 1; i < 300; i++) AddPlayerClass(i, 0,0,0,0, 0,0,0,0,0,0);	
    SetTimer("RandomMessages", 360000, true);
	CreateZone( 57.9765625, -328.9765625, 349.9765625, 54.0234375 ); // 0
	CreateZone( -213.015625, -1553.96875, 69.984375, -1275.96875 ); // 1
	CreateZone( -1137.03125, -1749.96875, -914.03125, -1594.96875 ); //2
	CreateZone( 86.46875, 1790.03125, 281.46875, 1960.03125 ); //3
	CreateZone( -441.515625, 1332.0234375, -258.515625, 1581.0234375 );  //4
	CreateZone( -1324.0234375, 1748.515625, -1119.0234375, 1923.515625 );  //5
	CreateZone( -1776.03125, 1246.015625, -1610.03125, 1435.015625 ); // 6
	CreateZone( 1846.453125, -2515.9609375, 2011.453125, -2224.9609375 ); //7
	CreateZone( 1556.4765625, -2383.9765625, 1699.4765625, -2186.9765625 ); //8 
	CreateZone( 1699.4609375, -2382.9765625, 1840.4609375, -2185.9765625 ); // 9
	CreateZone( 642.4609375, -1319.9765625, 794.4609375, -1136.9765625 );  //10
	CreateZone( -165.015625, -2715.984375, 78.984375, -2436.984375 );  //11
	CreateZone( -1714.03125, -2839.984375, -1454.03125, -2646.984375 );  //12
	CreateZone( -2300.015625, -2587.984375, -1996.015625, -2228.984375 );  //13 
	CreateZone( -1982.015625, -1786.984375, -1709.015625, -1496.984375 ); // 14
	CreateZone( -2605.015625, -740.984375, -2324.015625, -491.984375 ); // 15
	CreateZone( -1130.015625, -765.984375, -960.015625, -567.984375 ); // 16
	CreateZone( -600.5234375, -212.984375, -414.5234375, -28.984375 ); // 17
	CreateZone( 1846.484375, -1257.984375, 2069.484375, -1123.984375 ); // 18
	CreateZone( 1062.4765625, -993.96875, 1314.4765625, -862.96875 ); //19
	CreateZone( 2163.984375, -155.984375, 2552.984375, 159.015625 ); // 20
	CreateZone( -944.015625, 1407.015625, -652.015625, 1628.015625 ); // 21
	CreateZone( -371.015625, 974.015625, 100.984375, 1247.015625 ); // 22
	CreateZone( 1158.46875, 101.015625, 1458.46875, 512.015625 ); // 23
	CreateZone( 554.484375, -684.984375, 867.484375, -388.984375 ); // 24
	CreateZone( -1499.515625, -1615.484375, -1400.515625, -1388.484375 ); //25
	CreateZone( -2180.015625, -1131.484375, -1903.015625, -695.484375 ); //26
	CreateZone( -2580.015625, -376.484375, -2280.015625, -199.484375 ); //27
	CreateZone( -2213.0234375, -296.46875, -2000.0234375, -65.46875 ); //28
	CreateZone( -2708.015625, 1276.515625, -2510.015625, 1474.515625 ); //29
	CreateZone( -2651.0390625, 2190.5234375, -2195.0390625, 2544.5234375 ); //30
	CreateZone( 1961.9765625, 2105.546875, 2209.9765625, 2338.546875 ); //31
	for (new i = 0; i < MAX_ZONES; i++) CreateZoneNumber(i,i,1); 
	for (new i = 0; i < MAX_ZONES; i++) CreateZoneBorders(i);	
	return 1;
}

stock gmtextdraws(){
	InfoAndSite = TextDrawCreate(561.200073, 11.448841, "_");
	TextDrawLetterSize(InfoAndSite, 0.210795, 0.843375);
	TextDrawAlignment(InfoAndSite, 1);
	TextDrawColor(InfoAndSite, -1);
	TextDrawSetShadow(InfoAndSite, 0);
	TextDrawSetOutline(InfoAndSite, 1);
	TextDrawBackgroundColor(InfoAndSite, 32);
	TextDrawFont(InfoAndSite, 1);
	TextDrawSetProportional(InfoAndSite, 1);

	Clock = TextDrawCreate(545.999755, 24.888910, "_");
	TextDrawLetterSize(Clock, 0.180000, 1.000000);
	TextDrawAlignment(Clock, 1);
	TextDrawColor(Clock, -1);
	TextDrawSetShadow(Clock, 1);
	TextDrawSetOutline(Clock, 0);
	TextDrawBackgroundColor(Clock, 32);
	TextDrawFont(Clock, 2);
	TextDrawSetProportional(Clock, 1);	

	TopOfArena = TextDrawCreate(121.200027, 214.888809, "_");
	TextDrawLetterSize(TopOfArena, 0.281998, 1.316264);
	TextDrawAlignment(TopOfArena, 1);
	TextDrawColor(TopOfArena, -1);
	TextDrawSetShadow(TopOfArena, 0);
	TextDrawSetOutline(TopOfArena, 1);
	TextDrawBackgroundColor(TopOfArena, 80);
	TextDrawFont(TopOfArena, 1);
	TextDrawSetProportional(TopOfArena, 1);
	TextDrawSetShadow(TopOfArena, 0);

	ArenaTime = TextDrawCreate(635.200500, 429.731079, "_");
	TextDrawLetterSize(ArenaTime, 0.280000, 0.899999);
	TextDrawAlignment(ArenaTime, 3);
	TextDrawColor(ArenaTime, -1);
	TextDrawSetShadow(ArenaTime, 0);
	TextDrawSetOutline(ArenaTime, 1);
	TextDrawBackgroundColor(ArenaTime, 80);
	TextDrawFont(ArenaTime, 3);
	TextDrawSetProportional(ArenaTime, 1);
	TextDrawSetShadow(ArenaTime, 0);	

	RequestClassTD[0] = TextDrawCreate(32.000225, 277.608825, "_");
	TextDrawLetterSize(RequestClassTD[0], 0.302399, 1.276444);
	TextDrawAlignment(RequestClassTD[0], 1);
	TextDrawColor(RequestClassTD[0], -1);
	TextDrawSetShadow(RequestClassTD[0], 0);
	TextDrawSetOutline(RequestClassTD[0], 1);
	TextDrawBackgroundColor(RequestClassTD[0], 130);
	TextDrawFont(RequestClassTD[0], 1);
	TextDrawSetProportional(RequestClassTD[0], 1);
	TextDrawSetShadow(RequestClassTD[0], 0);

	/*RequestClass = TextDrawCreate(327.600067, 366.213165, "Set weapons~n~Vibrat' orujie");
	TextDrawLetterSize(RequestClass, 0.299199, 1.286400);
	TextDrawTextSize(RequestClass, 0.000000, 64.000000);
	TextDrawAlignment(RequestClass, 2);
	TextDrawColor(RequestClass, -2147450625);
	TextDrawUseBox(RequestClass, 1);
	TextDrawBoxColor(RequestClass, 86);
	TextDrawSetShadow(RequestClass, 0);
	TextDrawSetOutline(RequestClass, 1);
	TextDrawBackgroundColor(RequestClass, 130);
	TextDrawFont(RequestClass, 1);
	TextDrawSetProportional(RequestClass, 1);
	TextDrawSetShadow(RequestClass, 0);
	TextDrawSetSelectable(RequestClass, true);*/

	RequestClassTD[1] = TextDrawCreate(309.200103, 37.680053, "WELCOME_TO_THE_CLASH_OF_GANGS!~n~GOOD_LUCK_AND_HAVE_FUN!");
	TextDrawLetterSize(RequestClassTD[1], 0.400000, 1.600000);
	TextDrawAlignment(RequestClassTD[1], 2);
	TextDrawColor(RequestClassTD[1], -5963521);
	TextDrawSetShadow(RequestClassTD[1], 0);
	TextDrawSetOutline(RequestClassTD[1], 1);
	TextDrawBackgroundColor(RequestClassTD[1], 120);
	TextDrawFont(RequestClassTD[1], 1);
	TextDrawSetProportional(RequestClassTD[1], 1);
	TextDrawSetShadow(RequestClassTD[1], 0);	
}

public OnGameModeExit()
{
	db_close(db);
	return 1;
}

public OnPlayerConnect(playerid)
{
	return SetTimerEx("OnPlayerJoin", 0001, false, "i", playerid);
}

public OnPlayerDisconnect(playerid, reason)
{
	new string[1024],
		name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
    format(string, sizeof(string), "UPDATE `users` SET `name` = '%s', `password` = '%q', `salt` = '%q', `sec_question` = '%q', `sec_answer` = '%q', `kills` = %i, `deaths` = %i, `score` = %i, `money` = %i, `adminlevel` = %i, `viplevel` = %i, `Level` = %i, `Gangid` = %i, `GangEXP` = %i, `Wins` = %i, `Loses` = %i WHERE `id` = %i",
		name, eUser[playerid][e_USER_PASSWORD], eUser[playerid][e_USER_SALT], eUser[playerid][e_USER_SECURITY_QUESTION], eUser[playerid][e_USER_SECURITY_ANSWER],  eUser[playerid][e_USER_KILLS], eUser[playerid][e_USER_DEATHS], GetPlayerScore(playerid), GetPlayerMoney(playerid), eUser[playerid][e_USER_ADMIN_LEVEL], eUser[playerid][e_USER_VIP_LEVEL], 
		eUser[playerid][Level], eUser[playerid][GangId], eUser[playerid][GangExp], eUser[playerid][DuelWon], eUser[playerid][DuelLose], eUser[playerid][e_USER_SQLID]);
	db_query(db, string);
	SendDeathMessage(INVALID_PLAYER_ID, playerid, 201);
	PlayerTextDrawHide(playerid, FPSPingPacket[playerid]);
	PlayerTextDrawHide(playerid, InfoStats[playerid][0]);
	PlayerTextDrawHide(playerid, InfoStats[playerid][1]);
	TextDrawHideForPlayer(playerid, InfoAndSite);
	TextDrawHideForPlayer(playerid, ArenaTime);
	connect--;
	new iString[60];
	format(iString, sizeof(iString), "~g~~h~IP: ~w~~h~sa-gdm.ru:10000~n~ONLINE: ~r~%d~w~/~r~30", connect);
	TextDrawSetString(InfoAndSite, iString);
	TextDrawHideForPlayer(playerid, Clock);
	if(eUser[playerid][GangId] != 0) PlayerTextDrawHide(playerid, GangInfo[playerid]);
	if(GetPVarInt(playerid, "ReadyToDuel") == 2){
		foreach(new i: Player){
		    if(GetPVarInt(playerid, "ReadyToDuel") == 2 && GetPVarInt(i, "ReadyToDuel") == 2 && GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(i)){
		    	va_SendClientMessageToAll(-1, "%s вышел с дуели против %s", eUser[playerid][Name], eUser[i][Name]);
			}
		}
	}		
	for(new i; i < sizeof(eUser[]); i++) eUser[playerid][e_USER: i] = 0;	
	DeletePVar(playerid, "PlayerSkin");
	DeletePVar(playerid, "ReadyToDuel");
	DeletePVar(playerid, "GangWait");
	ZoneNumberStopFlashForPlayer(playerid,arena);
	for(new i; i < MAX_ZONES; i++) HideZoneForPlayer(playerid,i);
	DeletePVar(playerid, "GunOne");
	DeletePVar(playerid, "GunTwo");
	DeletePVar(playerid, "GunThree");
	DeletePVar(playerid, "GunFourth");		
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	new iString[100];
	if(reason == 255) reason = 53;
	if(killerid == INVALID_PLAYER_ID) {
	    SendDeathMessage(INVALID_PLAYER_ID, playerid, reason);
	    eUser[playerid][e_USER_DEATHS]++;
	    eUser[playerid][ArenaDMG] += eUser[playerid][GiveDMG];
		eUser[playerid][TakenDMG] = 0;
		eUser[playerid][GiveDMG] = 0;	    
	} else if( killerid != INVALID_PLAYER_ID && IsPlayerConnected(killerid)) {
		if(GetPVarInt(killerid, "ReadyToDuel") == 2){
		   SpawnPlayer(killerid);
		   eUser[killerid][DuelWon]++;
		   eUser[playerid][DuelLose]++;
		   va_SendClientMessageToAll(-1, ""COL_RED"%s {FFFFFF}выиграл дуель у "COL_RED"%s", eUser[killerid][Name], eUser[playerid][Name]);
		   SetPVarInt(playerid, "ReadyToDuel", 0);
		   SetPVarInt(killerid, "ReadyToDuel", 0);
		   GameTextForPlayer(playerid, "~w~Nice try...", 3000, 1);
		   GameTextForPlayer(killerid, "~w~Good job!", 3000, 1);
		}
		SendDeathMessage(killerid, playerid, reason);
		new giveexp;
		switch(reason){
			case 24: giveexp += 6+random(10);
			case 25: giveexp += 10+random(10);
			case 31: giveexp += 11+random(10);
			case 34: giveexp += 15+random(10);
		}
		eUser[killerid][e_USER_MONEY] += giveexp;
		eUser[killerid][ArenaExp] += giveexp;
		if(eUser[killerid][GangId] != 0 && eUser[killerid][GangId] != eUser[playerid][GangId]) GangsNew[eUser[killerid][GangId]-1][Exp] += giveexp, eUser[killerid][GangExp] += giveexp, GangsNew[eUser[killerid][GangId]-1][ArenaExp] += giveexp;
		eUser[killerid][e_USER_KILLS]++;
		eUser[playerid][e_USER_DEATHS]++;
		SetPlayerScore(killerid, eUser[killerid][e_USER_MONEY]);
		ResetPlayerMoney(killerid);
		GivePlayerMoney(killerid, eUser[killerid][e_USER_MONEY]);
		SetPlayerArmour(killerid, 50.0+eUser[playerid][Level]);
		SetPlayerHealth(killerid, 100.0);

		eUser[playerid][ArenaDMG] += eUser[playerid][GiveDMG];

		eUser[playerid][TakenDMG] = 0;
		eUser[playerid][GiveDMG] = 0;
		eUser[killerid][ArenaKills]++;

		PlayerTextDrawHide(killerid, DeathInfo[0][killerid]);
		PlayerTextDrawHide(playerid, DeathInfo[1][playerid]);

		if(GetPVarInt(playerid, "Spree") > 3){
		    va_SendClientMessageToAll(-1, ""COL_RED"%s {FFFFFF}сбил килл-стрик игроку "COL_RED"%s "COL_DEFAULT"(%d убийств)", eUser[killerid][Name], eUser[playerid][Name], GetPVarInt(playerid, "Spree"));
		}

		SetPVarInt(playerid, "Spree", 0);
		SetPVarInt(killerid, "Spree", GetPVarInt(killerid, "Spree")+1);

	    switch(GetPVarInt(killerid, "Spree")){
	        case 2:{
	        	format(iString, sizeof(iString), "~r~~h~Double kill!"); 
	        	PlayerTextDrawSetString(killerid, killsandexp[killerid][0], iString);
	        	PlayerTextDrawShow(killerid, killsandexp[killerid][0]);
	        	SetTimerEx("DoubleExp", 3300, false, "i", killerid);
	        }	
	        case 3:{
	        	format(iString, sizeof(iString), "~r~~h~Triple kill!"); 
	        	PlayerTextDrawSetString(killerid, killsandexp[killerid][0], iString); 
	        	PlayerTextDrawShow(killerid, killsandexp[killerid][0]);
	        	SetTimerEx("DoubleExp", 3300, false, "i", killerid);
	        }	
	        case 4:{
	        	format(iString, sizeof(iString), "~r~~h~Ultra kill!");
	        	PlayerTextDrawSetString(killerid, killsandexp[killerid][0], iString);
	        	PlayerTextDrawShow(killerid, killsandexp[killerid][0]);
	        	SetTimerEx("DoubleExp", 3300, false, "i", killerid);
	        }
	       	case 5:{
	       		format(iString, sizeof(iString), "~r~~h~Rampage!!!"); 
	       		PlayerTextDrawSetString(killerid, killsandexp[killerid][0], iString); 
	       		PlayerTextDrawShow(killerid, killsandexp[killerid][0]);
	       		SetTimerEx("DoubleExp", 3300, false, "i", killerid);
	       		va_SendClientMessageToAll(-1, "%s "COL_DEFAULT"сделал "COL_RED"RAMPAGE!", eUser[killerid][Name]);
	       		if(eUser[playerid][Level] < 5) GivePlayerWeapon(playerid, 34, 150);
	       	}	
	       	case 10:{
	       		if(eUser[playerid][Level] < 10) GivePlayerWeapon(playerid, 31, 150);
	       	}
	    }

	    format(iString, sizeof(iString), "~w~~h~+%d ~y~Exp!", giveexp);
	    PlayerTextDrawSetString(killerid, killsandexp[killerid][1], iString);
	    PlayerTextDrawShow(killerid, killsandexp[killerid][1]);

		format(iString, sizeof(iString), "~w~~h~You killed ~r~~h~%s", eUser[playerid][Name]);
        PlayerTextDrawSetString(killerid, DeathInfo[0][killerid], iString);
        PlayerTextDrawShow(killerid, DeathInfo[0][killerid]);

        format(iString, sizeof(iString), "~w~~h~Killed by ~g~~h~%s", eUser[killerid][Name]);
        PlayerTextDrawSetString(playerid, DeathInfo[1][playerid], iString);
        PlayerTextDrawShow(playerid, DeathInfo[1][playerid]);

	    SetTimerEx("DeathMessage", 4000, false, "ii", killerid, playerid);

	    format(iString, sizeof(iString), "~y~~h~Level ~w~~h~%d~n~~y~~h~Exp ~w~~h~%d/%d", eUser[killerid][Level], eUser[killerid][e_USER_MONEY], 800*eUser[killerid][Level]);
	    PlayerTextDrawSetString(killerid, InfoStats[killerid][1], iString);

	    if(800*eUser[killerid][Level] < eUser[killerid][e_USER_MONEY]){
	    	SendClientMessage(killerid, -1, ""COL_DEFAULT"Поздравляем, вы перешли на новый уровень!");
	    	eUser[killerid][Level]++;
	    }
        format(iString, sizeof(iString), "Убил: "COL_WHITE"%s", eUser[killerid][Name]);
        SetPlayerChatBubble(playerid, iString, 0xff7518FF, 30.0, 6000);    
	}  	
	return true;
}	

forward DoubleExp(playerid);
public DoubleExp(playerid) {
	PlayerTextDrawHide(playerid, killsandexp[playerid][0]);
}

forward DeathMessage(killerid, playerid);
public DeathMessage(killerid, playerid) {
	PlayerTextDrawHide(killerid, DeathInfo[0][killerid]);
	PlayerTextDrawHide(playerid, DeathInfo[1][playerid]);
	PlayerTextDrawHide(killerid, killsandexp[killerid][1]);
}

public OnPlayerRequestClass(playerid, classid)
{
	if (!GetPVarInt(playerid, "LoggedIn"))
	{
	    SetPlayerCameraPos(playerid, -144.2838, 1244.2357, 35.6595);
		SetPlayerCameraLookAt(playerid, -144.2255, 1243.2335, 35.3393, CAMERA_MOVE);
	}
	else
	{
    	SetPlayerPos(playerid, -314.7314, 1052.8170, 20.3403);
     	SetPlayerFacingAngle(playerid, 357.8575);
     	SetPlayerCameraPos(playerid, -312.2127, 1055.5232, 20.5785);
		SetPlayerCameraLookAt(playerid, -313.0236, 1054.9427, 20.5334, CAMERA_MOVE);
		SetPVarInt(playerid, "PlayerSkin", GetPlayerSkin(playerid));
	}
 	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if (!GetPVarInt(playerid, "LoggedIn"))
	{
	    GameTextForPlayer(playerid, "~n~~n~~n~~n~~r~AVTORIZUISYA BLEAD'!", 3000, 3);
	    return 0;
	}
    if(GetPVarInt(playerid, "GunOne") == 0 && GetPVarInt(playerid, "GunTwo") == 0 && GetPVarInt(playerid, "GunThree") == 0 && GetPVarInt(playerid, "GunFourth") == 0){
        SendClientMessage(playerid, -1, "Теперь выберите оружие.");
        Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
        return false;
    }	
	return 1;
}

public OnPlayerSpawn(playerid)
{
	new iString[60];
	if(GetPVarInt(playerid, "FirstSpawn") == 0){
		PlayerTextDrawShow(playerid, FPSPingPacket[playerid]);
		TextDrawShowForPlayer(playerid, Clock);
		TextDrawShowForPlayer(playerid, ArenaTime);
		PlayerTextDrawShow(playerid, InfoStats[playerid][0]);
		PlayerTextDrawShow(playerid, InfoStats[playerid][1]);
		TextDrawShowForPlayer(playerid, InfoAndSite);
		SetPVarInt(playerid, "FirstSpawn", 1);
		///
	    format(iString, sizeof(iString), "~y~~h~Level ~w~~h~%d~n~~y~~h~Exp ~w~~h~%d/%d", eUser[playerid][Level], eUser[playerid][e_USER_MONEY], 800*eUser[playerid][Level]);
	    PlayerTextDrawSetString(playerid, InfoStats[playerid][1], iString);

		SetPlayerScore(playerid, eUser[playerid][e_USER_MONEY]);
		GivePlayerMoney(playerid, eUser[playerid][e_USER_MONEY]);	    
		if(eUser[playerid][GangId] != 0) PlayerTextDrawShow(playerid, GangInfo[playerid]);
		SendClientMessage(playerid, -1, ""COL_DEFAULT"/changeskin {FFFFFF}- сменить скин, если знаете id.");
		ZoneNumberFlashForPlayer(playerid,arena,0xCC0000FF);
		//TextDrawHideForPlayer(playerid, RequestClass);
		TextDrawHideForPlayer(playerid, RequestClassTD[0]);
		TextDrawHideForPlayer(playerid, RequestClassTD[1]);	
		CancelSelectTextDraw(playerid);
		SetPlayerColor(playerid, GetClanColorForPlayer(playerid));
	}
	new rand = random(10);
	SetPlayerPos(playerid,ArenaPos[arena][rand][0],ArenaPos[arena][rand][1],ArenaPos[arena][rand][2]);
	SetPlayerSkin(playerid, GetPVarInt(playerid, "PlayerSkin"));
	SetPlayerInterior(playerid, 0);		
   	SetPlayerArmour(playerid, 50.0+eUser[playerid][Level]);

	if(GetPVarInt(playerid, "GunOne") != 0) GivePlayerWeapon(playerid, GetPVarInt(playerid, "GunOne"), 900);
	if(GetPVarInt(playerid, "GunTwo") != 0) GivePlayerWeapon(playerid, GetPVarInt(playerid, "GunTwo"), 900);
	if(GetPVarInt(playerid, "GunThree") != 0) GivePlayerWeapon(playerid, GetPVarInt(playerid, "GunThree"), 900);
	if(GetPVarInt(playerid, "GunFourth") != 0) GivePlayerWeapon(playerid, GetPVarInt(playerid, "GunFourth"), 900);

   	SetPlayerVirtualWorld(playerid, 0);
   	SetTimerEx("Protected", 3000, false, "i", playerid);
   	SendClientMessage(playerid, -1, "Protect on!");
   	SetPVarInt(playerid, "Protect", 1);
	return 1;
}

forward Protected(playerid);
public Protected(playerid){
   	SendClientMessage(playerid, -1, "Protect off!");
   	SetPVarInt(playerid, "Protect", 0);
	return true;
}

forward OnPlayerJoin(playerid);
public OnPlayerJoin(playerid)
{
	SetPlayerColor(playerid, 0xB2ACAC85);
	for (new i; i < 100; i++)
	{
	    SendClientMessage(playerid, COLOR_WHITE, "");
	}
	SendClientMessage(playerid, COLOR_WHITE, "Добро пожаловать в "COL_RED"CLASH OF GANGS!");
	PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);

	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	GetPlayerName(playerid, eUser[playerid][Name], 24);

	new string[150];
	format(string, sizeof(string), "SELECT * FROM `users` WHERE `name` = '%q' LIMIT 1", name);
	new DBResult:result = db_query(db, string);
	if (db_num_rows(result) == 0)
	{
	    eUser[playerid][e_USER_SQLID] = -1;
	    eUser[playerid][e_USER_PASSWORD][0] = EOS;
	    eUser[playerid][e_USER_SALT][0] = EOS;
		eUser[playerid][e_USER_KILLS] = 0;
		eUser[playerid][e_USER_DEATHS] = 0;
		eUser[playerid][e_USER_SCORE] = 0;
		eUser[playerid][e_USER_MONEY] = 0;
		eUser[playerid][e_USER_ADMIN_LEVEL] = 0;
		eUser[playerid][e_USER_VIP_LEVEL] = 0;
		eUser[playerid][e_USER_REGISTER_TIMESTAMP] = 0;
		eUser[playerid][e_USER_LASTLOGIN_TIMESTAMP] = 0;
		eUser[playerid][e_USER_SECURITY_QUESTION][0] = EOS;
		eUser[playerid][e_USER_SECURITY_ANSWER][0] = EOS;
		eUser[playerid][Level] = 1;
		eUser[playerid][GangId] = 0;
		eUser[playerid][GangExp] = 0;
		eUser[playerid][DuelLose] = 0;
		eUser[playerid][DuelWon] = 0;

		Dialog_Show(playerid, REGISTER, DIALOG_STYLE_PASSWORD, "Регистрация аккаунта... [Шаг: 1/3]", COL_WHITE "Добро пожаловать на наш сервер. Вы должны пройти "COL_GREEN"3 просто шага, "COL_WHITE"чтобы зарегистрировтаься на сервере!\nВведите пароль "COL_TOMATO"ниже.", "Продолжить", "Настройки");
		SendClientMessage(playerid, COLOR_WHITE, "[Шаг: 1/3] Введи ваш пароль в окошко.");
	}
	else
	{
		iLoginAttempts[playerid] = 0;
		iAnswerAttempts[playerid] = 0;

		eUser[playerid][e_USER_SQLID] = db_get_field_assoc_int(result, "id");

		format(string, sizeof(string), "SELECT `lock_timestamp` FROM `temp_blocked_users` WHERE `user_id` = %i LIMIT 1", eUser[playerid][e_USER_SQLID]);
		new DBResult:lock_result = db_query(db, string);
		if (db_num_rows(lock_result) == 1)
		{
			new lock_timestamp = db_get_field_int(lock_result, 0);
			if ((gettime() - lock_timestamp) < 0)
		    {
		        SendClientMessage(playerid, COLOR_TOMATO, "Извините, но ваш аккаунт временно забанен. Попыток "#MAX_LOGIN_ATTEMPTS"/"#MAX_LOGIN_ATTEMPTS" было использовано.");
		        format(string, sizeof(string), "Попробуйте через %s.", ReturnTimelapse(gettime(), lock_timestamp));
				SendClientMessage(playerid, COLOR_TOMATO, string);
				db_free_result(result);
				db_free_result(lock_result);
				return Kick(playerid);
		    }
		    else
		    {
		        new ip[18];
				GetPlayerIp(playerid, ip, 18);
		        format(string, sizeof(string), "DELETE FROM `temp_blocked_users` WHERE `user_id` = %i AND `ip` = '%s'", eUser[playerid][e_USER_SQLID], ip);
		        db_query(db, string);
		    }
		}
		db_free_result(lock_result);

		db_get_field_assoc(result, "password", eUser[playerid][e_USER_PASSWORD], 64);
		db_get_field_assoc(result, "salt", eUser[playerid][e_USER_SALT], 64);
		eUser[playerid][e_USER_SALT][64] = EOS;
		eUser[playerid][e_USER_KILLS] = db_get_field_assoc_int(result, "kills");
		eUser[playerid][e_USER_DEATHS] = db_get_field_assoc_int(result, "deaths");
		eUser[playerid][e_USER_SCORE] = db_get_field_assoc_int(result, "score");
		eUser[playerid][e_USER_MONEY] = db_get_field_assoc_int(result, "money");
		eUser[playerid][e_USER_ADMIN_LEVEL] = db_get_field_assoc_int(result, "adminlevel");
		eUser[playerid][e_USER_VIP_LEVEL] = db_get_field_assoc_int(result, "viplevel");
		eUser[playerid][e_USER_REGISTER_TIMESTAMP] = db_get_field_assoc_int(result, "register_timestamp");
		eUser[playerid][e_USER_LASTLOGIN_TIMESTAMP] = db_get_field_assoc_int(result, "lastlogin_timestamp");
		db_get_field_assoc(result, "sec_question", eUser[playerid][e_USER_SECURITY_QUESTION], MAX_SECURITY_QUESTION_SIZE);
		db_get_field_assoc(result, "sec_answer", eUser[playerid][e_USER_SECURITY_ANSWER], MAX_PASSWORD_LENGTH * 2);
		eUser[playerid][Level] = db_get_field_assoc_int(result, "Level");
		eUser[playerid][GangId] = db_get_field_assoc_int(result, "Gangid");
		eUser[playerid][GangExp] = db_get_field_assoc_int(result, "GangEXP");
		eUser[playerid][DuelWon] = db_get_field_assoc_int(result, "Wins");
		eUser[playerid][DuelLose] = db_get_field_assoc_int(result, "Loses");

		Dialog_Show(playerid, LOGIN, DIALOG_STYLE_PASSWORD, "Авторизация...", COL_WHITE "Введите ваш пароль в окошко. Если "COL_YELLOW""#MAX_LOGIN_ATTEMPTS" "COL_WHITE"попытки будут использованы, аккаунт будет заблокирован на "COL_YELLOW""#MAX_ACCOUNT_LOCKTIME" "COL_WHITE"минут.", "Дальше", "Настройки");
	}

	db_free_result(result);
	SendDeathMessage(INVALID_PLAYER_ID, playerid, 200);
	playertextdraws(playerid);
	SetPVarInt(playerid, "FirstSpawn", 0);
	connect++;
	format(string, sizeof(string), "~g~~h~IP: ~w~~h~sa-gdm.ru:10000~n~ONLINE: ~r~%d~w~/~r~30", connect);
	TextDrawSetString(InfoAndSite, string);
	for(new i; i < MAX_ZONES; i++) ShowZoneForPlayer(playerid,i,GetClanColor(i),0xFFFFFFFF,0xFFFFFFFF);
	TextDrawShowForPlayer(playerid, RequestClassTD[1]);
	return 1;
}

DIALOG:DIALOG_CHANGE(playerid, response, listitem, inputtext[]){
    if(!response) {
        if(GetPVarInt(playerid, "GunOne") == 0 && GetPVarInt(playerid, "GunTwo") == 0 && GetPVarInt(playerid, "GunThree") == 0 && GetPVarInt(playerid, "GunFourth") == 0){
        	SendClientMessage(playerid, -1, "Вы не взяли оружие. Пожалуйста, выберите хоть что-нибудь.");
        	Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
            return false;
        }
        SpawnPlayer(playerid);
       
    }
    if(response){
        switch(listitem){
            case 0: Dialog_Show(playerid, DIALOG_CHANGE1, DIALOG_STYLE_LIST, "Выбор оружия для 1-го слота", "Desert Eagle\nShotgun\nSniper Rifle\nm4", "Выбрать", "Назад");
            case 1: Dialog_Show(playerid, DIALOG_CHANGE2, DIALOG_STYLE_LIST, "Выбор оружия для второго слота", "Desert Eagle\nShotgun\nSniper Rifle\nm4", "Выбрать", "Закрыть");
            case 2:{
            	if(eUser[playerid][Level] < 5) return SendClientMessage(playerid, -1, "Третий слот будет доступен только после достижения пятого уровня."), Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Закрыть");
            	Dialog_Show(playerid, DIALOG_CHANGE3, DIALOG_STYLE_LIST, "Выбор оружия для третьего слота", "Desert Eagle\nShotgun\nSniper Rifle\nm4", "Выбрать", "Закрыть");
            }	
            case 3: {
            	if(eUser[playerid][Level] < 10) return SendClientMessage(playerid, -1, "Третий слот будет доступен только после достижения десятого уровня."), Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Закрыть");
            	Dialog_Show(playerid, DIALOG_CHANGE4, DIALOG_STYLE_LIST, "Выбор оружия для четвертого слота", "Desert Eagle\nShotgun\nSniper Rifle\nm4", "Выбрать", "Закрыть");
        	}
        }
    }
	return 1;  
}
 
DIALOG:DIALOG_CHANGE1(playerid, response, listitem, inputtext[]){
    if(!response) Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
    if(response){
        switch(listitem){
            case 0: SetPVarInt(playerid, "GunOne", 24);
            case 1: SetPVarInt(playerid, "GunOne", 25);
            case 2: {
                 if(eUser[playerid][Level] < 5) return Dialog_Show(playerid, DIALOG_CHANGE1, DIALOG_STYLE_LIST, "Выбор оружия для 1-го слота", "Desert Eagle\nShotgun\nSniper Rifle\nm4", "Выбрать", "Назад"), SendClientMessage(playerid, -1, "Это оружие будет доступно по достижению пятого уровня.");
                 SetPVarInt(playerid, "GunOne", 34);
            }
            case 3: {
                 if(eUser[playerid][Level] < 10) return Dialog_Show(playerid, DIALOG_CHANGE1, DIALOG_STYLE_LIST, "Выбор оружия для 1-го слота", "Desert Eagle\nShotgun\nSniper Rifle\nm4", "Выбрать", "Назад"), SendClientMessage(playerid, -1, "Это оружие будет доступно по достижению десятого уровня.");

                 SetPVarInt(playerid, "GunOne", 31);
            }
        }
        Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
    }
	return 1;    
}
 
DIALOG:DIALOG_CHANGE2(playerid, response, listitem, inputtext[]){
    if(!response) Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
    if(response){
        switch(listitem){
            case 0: SetPVarInt(playerid, "GunTwo", 24);
            case 1: SetPVarInt(playerid, "GunTwo", 25);
            case 2: {
                 if(eUser[playerid][Level] < 5) return Dialog_Show(playerid, DIALOG_CHANGE2, DIALOG_STYLE_LIST, "Выбор оружия для второго слота", "Desert Eagle\nShotgun\nSniper Rifle\nm4", "Выбрать", "Закрыть"), SendClientMessage(playerid, -1, "Это оружие будет доступно по достижению пятого уровня.");

                 SetPVarInt(playerid, "GunTwo", 34);
            }
            case 3: {
                 if(eUser[playerid][Level] < 10) return Dialog_Show(playerid, DIALOG_CHANGE2, DIALOG_STYLE_LIST, "Выбор оружия для второго слота", "Desert Eagle\nShotgun\nSniper Rifle\nm4", "Выбрать", "Закрыть"), SendClientMessage(playerid, -1, "Это оружие будет доступно по достижению десятого уровня.");
                 SetPVarInt(playerid, "GunTwo", 31);
            }
        }
        Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
    }
	return 1;    
}

DIALOG:DIALOG_CHANGE3(playerid, response, listitem, inputtext[]){
    if(!response) Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
    if(response){
        switch(listitem){
            case 0: SetPVarInt(playerid, "GunThree", 24);
            case 1: SetPVarInt(playerid, "GunThree", 25);
            case 2: {
                 SetPVarInt(playerid, "GunThree", 34);
            }
            case 3: {
                 if(eUser[playerid][Level] < 10) return Dialog_Show(playerid, DIALOG_CHANGE3, DIALOG_STYLE_LIST, "Выбор оружия для третьего слота", "Desert Eagle\nShotgun\nSniper Rifle\nm4", "Выбрать", "Закрыть"), SendClientMessage(playerid, -1, "Это оружие будет доступно по достижению десятого уровня.");
                 SetPVarInt(playerid, "GunThree", 31);
            }
        }
        Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
    }
    return true;
}
 
DIALOG:DIALOG_CHANGE4(playerid, response, listitem, inputtext[]){
    if(!response) Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
    if(response){
        switch(listitem){
            case 0: SetPVarInt(playerid, "GunFourth", 24);
            case 1: SetPVarInt(playerid, "GunFourth", 25);
            case 2: {
                 SetPVarInt(playerid, "GunFourth", 34);
            }
            case 3: {
                 SetPVarInt(playerid, "GunFourth", 31);
            }
        }
        Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
    }
	return true;
}


Dialog:LOGIN(playerid, response, listitem, inputtext[])
{
	if (!response)
	{
	    Dialog_Show(playerid, OPTIONS, DIALOG_STYLE_LIST, "Настройки аккаунта...", "Забыл пароль\nЗабыл никнейм\nВыйти", "Выбрать", "Назад");
	    return 1;
	}

	new string[256];

	new hash[64];
	SHA256_PassHash(inputtext, eUser[playerid][e_USER_SALT], hash, sizeof(hash));
	if (strcmp(hash, eUser[playerid][e_USER_PASSWORD]))
	{
		if (++iLoginAttempts[playerid] == MAX_LOGIN_ATTEMPTS)
		{
		    new lock_timestamp = gettime() + (MAX_ACCOUNT_LOCKTIME * 60);
		    new ip[18];
		    GetPlayerIp(playerid, ip, 18);
			format(string, sizeof(string), "INSERT INTO `temp_blocked_users` VALUES('%s', %i, %i)", ip, lock_timestamp, eUser[playerid][e_USER_SQLID]);
			db_query(db, string);

		    SendClientMessage(playerid, COLOR_TOMATO, "Извините, но аккаунт временно забанен. "#MAX_LOGIN_ATTEMPTS"/"#MAX_LOGIN_ATTEMPTS" попыток.");
		    format(string, sizeof(string), "Если вы забыли пароль, используйте настройки для восстановления через %s минут.", ReturnTimelapse(gettime(), lock_timestamp));
			SendClientMessage(playerid, COLOR_TOMATO, string);
		    return Kick(playerid);
		}

	    Dialog_Show(playerid, LOGIN, DIALOG_STYLE_INPUT, "Авторизация...", COL_WHITE "Введите пароль в окошко. Если "COL_YELLOW""#MAX_LOGIN_ATTEMPTS" "COL_WHITE"попыток будет использовано, то аккаунт будет забанен на "COL_YELLOW""#MAX_ACCOUNT_LOCKTIME" "COL_WHITE"минут.", "Continue", "Options");
	    format(string, sizeof(string), "Неправильный пароль! У вас осталось: %i/"#MAX_LOGIN_ATTEMPTS" попыток.", iLoginAttempts[playerid]);
		SendClientMessage(playerid, COLOR_TOMATO, string);
	    return 1;
	}

	new name[MAX_PLAYER_NAME],
		ip[18];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	GetPlayerIp(playerid, ip, 18);
	format(string, sizeof(string), "UPDATE `users` SET `lastlogin_timestamp` = %i, `ip` = '%s', `longip` = %i WHERE `id` = %i", gettime(), ip, IpToLong(ip), eUser[playerid][e_USER_SQLID]);
	db_query(db, string);

	format(string, sizeof(string), ""COL_DEFAULT"Успешно авторизовались! Добро пожаловать обратно, %s. {FFFFFF}[Последний логин: %s назад]", name, ReturnTimelapse(eUser[playerid][e_USER_LASTLOGIN_TIMESTAMP], gettime()));
	SendClientMessage(playerid, COLOR_GREEN, string);
	SendClientMessage(playerid, -1, "{FFFFFF}Введение "COL_DEFAULT"/help /credits");
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	SetPVarInt(playerid, "LoggedIn", 1);
	OnPlayerRequestClass(playerid, 0);
	if(GangsNew[eUser[playerid][GangId]-1][LeaderId] == eUser[playerid][e_USER_SQLID]) va_SendClientMessage(playerid, -1, "Добро пожаловать, лидер банды %s", GangsNew[eUser[playerid][GangId]-1][Tag]);

    new Tagg[24], gangexp, gangidd = -1;
    for(new i = 0; i < MAX_GANGS; i++){
	    if(GangsNew[i][Exp] > gangexp && GangsNew[i][Exp] > 0)
		{
			gangexp = GangsNew[i][Exp]; 
			gangidd = i;
		}
	}	

	new DBResult:result = db_query(db, "SELECT * FROM `users` ORDER BY `score` DESC LIMIT 1");
    db_get_field_assoc(result, "name", Tagg, 24);
    format(string, sizeof(string), "~r~Tops~n~~w~~h~Player:_~g~%s_~w~~h~-_~g~~h~%d_~w~~h~exp~n~~w~~h~Gang:_~g~%s_~w~~h~-_~g~~h~%d_~w~~h~exp~n~~g~~h~/cmds /help /afk~n~~g~~h~/changeskin /time /weather~n~~g~~h~/changepack", Tagg, db_get_field_assoc_int(result, "score"), GangsNew[gangidd][Tag], gangexp);
    db_free_result( result );
	TextDrawSetString(RequestClassTD[0], string);
	TextDrawShowForPlayer(playerid, RequestClassTD[0]);
	//TextDrawShowForPlayer(playerid, RequestClass);
	return 1;
}

Dialog:REGISTER(playerid, response, listitem, inputtext[])
{
	if (!response)
	{
	    Dialog_Show(playerid, OPTIONS, DIALOG_STYLE_LIST, "Настройки аккаунта...", "Забыл пароль\nЗабыл никнейм\nВыйти", "Выбрать", "Назад");
	    return 1;
	}

	if (!(MIN_PASSWORD_LENGTH <= strlen(inputtext) <= MAX_PASSWORD_LENGTH))
	{
	    Dialog_Show(playerid, REGISTER, DIALOG_STYLE_PASSWORD, "Регистрация аккаунта... [Шаг: 1/3]", COL_WHITE "Добро пожаловать на наш сервер. Вы должны пройти "COL_GREEN"3 просто шага, "COL_WHITE"чтобы зарегистрировтаься на сервере!\nВведите пароль "COL_TOMATO"ниже.", "Continue", "Options");
		SendClientMessage(playerid, COLOR_TOMATO, "Неправильный пароль, он должен состоять из "#MIN_PASSWORD_LENGTH" - "#MAX_PASSWORD_LENGTH" характеров.");
	    return 1;
	}

	#if defined SECURE_PASSWORD_ONLY
		new bool:contain_number,
		    bool:contain_highercase,
		    bool:contain_lowercase;
		for (new i, j = strlen(inputtext); i < j; i++)
		{
		    switch (inputtext[i])
		    {
		        case '0'..'9':
		            contain_number = true;
				case 'A'..'Z':
				    contain_highercase = true;
				case 'a'..'z':
				    contain_lowercase = true;
		    }

		    if (contain_number && contain_highercase && contain_lowercase)
		        break;
		} 

		if (!contain_number || !contain_highercase || !contain_lowercase)
		{
		    Dialog_Show(playerid, REGISTER, DIALOG_STYLE_INPUT, "Регистрация аккаунта... [Шаг: 1/3]", COL_WHITE "Добро пожаловать на наш сервер. Вы должны пройти "COL_GREEN"3 просто шага, "COL_WHITE"чтобы зарегистрировтаься на сервере!\nВведите пароль "COL_TOMATO"ниже.", "Далее", "Настройки");
			SendClientMessage(playerid, COLOR_TOMATO, "Пароль должен состоять из цифр и букв.");
		    return 1;
		}
	#endif

	for (new i; i < 64; i++)
	{
		eUser[playerid][e_USER_SALT][i] = (random('z' - 'A') + 'A');
	}
	eUser[playerid][e_USER_SALT][64] = EOS;
	SHA256_PassHash(inputtext, eUser[playerid][e_USER_SALT], eUser[playerid][e_USER_PASSWORD], 64);

	new list[2 + (sizeof(SECURITY_QUESTIONS) * MAX_SECURITY_QUESTION_SIZE)];
	for (new i; i < sizeof(SECURITY_QUESTIONS); i++)
	{
	    strcat(list, SECURITY_QUESTIONS[i]);
	    strcat(list, "\n");
	}
	Dialog_Show(playerid, SEC_QUESTION, DIALOG_STYLE_LIST, "Регистрация аккаунта... [Шаг: 2/3]", list, "Дальше", "Назад");
	SendClientMessage(playerid, COLOR_WHITE, "[Шаг: 2/3] Выберите ваш секретный вопрос!");
	PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
	return 1;
}

Dialog:SEC_QUESTION(playerid, response, listitem, inputtext[])
{
	if (!response)
	{
	    Dialog_Show(playerid, REGISTER, DIALOG_STYLE_PASSWORD, "Регисрация аккаунта... [Шаг: 1/3]", COL_WHITE "Добро пожаловать на наш сервер. Вы должны пройти "COL_GREEN"3 просто шага, "COL_WHITE"чтобы зарегистрировтаься на сервере!\nВведите пароль "COL_TOMATO"ниже.", "Далее", "Настройки");
		SendClientMessage(playerid, COLOR_WHITE, "[Шаг: 1/3] Введите ваш пароль.");
		return 1;
	}

	format(eUser[playerid][e_USER_SECURITY_QUESTION], MAX_SECURITY_QUESTION_SIZE, SECURITY_QUESTIONS[listitem]);

	new string[256];
	format(string, sizeof(string), COL_TOMATO "%s\n"COL_WHITE"Введите ваш ответ на вопрос.", SECURITY_QUESTIONS[listitem]);
	Dialog_Show(playerid, SEC_ANSWER, DIALOG_STYLE_INPUT, "Регистрация аккаунта... [Шаг: 3/3]", string, "Подтвердить", "Назад");
	SendClientMessage(playerid, COLOR_WHITE, "[Шаг: 3/3] Введите ответ на ваш секретный вопрос и приступайте к игре! ;)");
	PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
	return 1;
}

Dialog:SEC_ANSWER(playerid, response, listitem, inputtext[])
{
	if (!response)
	{
	    new list[2 + (sizeof(SECURITY_QUESTIONS) * MAX_SECURITY_QUESTION_SIZE)];
		for (new i; i < sizeof(SECURITY_QUESTIONS); i++)
		{
		    strcat(list, SECURITY_QUESTIONS[i]);
		    strcat(list, "\n");
		}
		Dialog_Show(playerid, SEC_QUESTION, DIALOG_STYLE_LIST, "Регистрация аккаунта... [Шаг: 2/3]", list, "Далее", "Назад");
		SendClientMessage(playerid, COLOR_WHITE, "[Шаг: 2/3] Выберите ваш секретный вопрос!");
		return 1;
	}

	new string[512];

	if (strlen(inputtext) < MIN_PASSWORD_LENGTH || inputtext[0] == ' ')
	{
	    format(string, sizeof(string), COL_TOMATO "%s\n"COL_WHITE"Введите ваш ответ на вопрос.", SECURITY_QUESTIONS[listitem]);
		Dialog_Show(playerid, SEC_ANSWER, DIALOG_STYLE_INPUT, "Регистрация аккаунта... [Шаг: 3/3]", string, "Подтвердить", "Назад");
		SendClientMessage(playerid, COLOR_TOMATO, "Ответ должен состоять из "#MIN_PASSWORD_LENGTH" символов.");
		return 1;
	}

	for (new i, j = strlen(inputtext); i < j; i++)
	{
        inputtext[i] = tolower(inputtext[i]);
	}
	SHA256_PassHash(inputtext, eUser[playerid][e_USER_SALT], eUser[playerid][e_USER_SECURITY_ANSWER], 64);

	new name[MAX_PLAYER_NAME],
		ip[18];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	GetPlayerIp(playerid, ip, 18);
	format(string, sizeof(string), "INSERT INTO `users`(`name`, `ip`, `longip`, `password`, `salt`, `sec_question`, `sec_answer`, `register_timestamp`, `lastlogin_timestamp`) VALUES('%s', '%s', %i, '%q', '%q', '%q', '%q', %i, %i)", name, ip, IpToLong(ip), eUser[playerid][e_USER_PASSWORD], eUser[playerid][e_USER_SALT], eUser[playerid][e_USER_SECURITY_QUESTION], eUser[playerid][e_USER_SECURITY_ANSWER], gettime(), gettime());
	db_query(db, string);

	format(string, sizeof(string), "SELECT `id` FROM `users` WHERE `name` = '%q' LIMIT 1", name);
	new DBResult:result = db_query(db, string);
    eUser[playerid][e_USER_SQLID] = db_get_field_int(result, 0);
	db_free_result(result);

	format(string, sizeof(string), ""COL_DEFAULT"Успешно зарегистрировались! Добро пожаловать, %s. {FFFFFF}[IP: %s]", name, ip);
	SendClientMessage(playerid, COLOR_GREEN, string);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	SetPVarInt(playerid, "LoggedIn", 1);
	OnPlayerRequestClass(playerid, random(250));
	TextDrawShowForPlayer(playerid, RequestClassTD[0]);
	//TextDrawShowForPlayer(playerid, RequestClass);
	return 1;
}

Dialog:OPTIONS(playerid, response, listitem, inputtext[])
{
	if (!response)
	{
		if (eUser[playerid][e_USER_SQLID] != -1)
			Dialog_Show(playerid, LOGIN, DIALOG_STYLE_PASSWORD, "Авторизация аккаунта...", COL_WHITE "Insert your secret password to access this account. If you failed in "COL_YELLOW""#MAX_LOGIN_ATTEMPTS" "COL_WHITE"attempts, account will be locked for "COL_YELLOW""#MAX_ACCOUNT_LOCKTIME" "COL_WHITE"minutes.", "Continue", "Options");
		else
			Dialog_Show(playerid, REGISTER, DIALOG_STYLE_PASSWORD, "Регистрация аккаунта... [Шаг: 1/3]", COL_WHITE "Добро пожаловать на наш сервер. Вы должны пройти "COL_GREEN"3 просто шага, "COL_WHITE"чтобы зарегистрировтаься на сервере!\nВведите пароль "COL_TOMATO"ниже.", "Continue", "Options");
		return 1;
	}

	switch (listitem)
	{
	    case 0:
	    {
	        if (eUser[playerid][e_USER_SQLID] == -1)
	        {
	            SendClientMessage(playerid, COLOR_TOMATO, "Этот аккаунт не зарегистрирован. Попробуйте нажать на 'Забыл пароль'");
	        	Dialog_Show(playerid, OPTIONS, DIALOG_STYLE_LIST, "Настройки аккаунта...", "Забыл пароль\nЗабыл никнейм\nВыйти", "Выбрать", "Назад");
	        	return 1;
	        }

			new string[64 + MAX_SECURITY_QUESTION_SIZE];
			format(string, sizeof(string), COL_WHITE "Введите ваш ответ на секретный вопрос, чтобы восстановить пароль.\n\n"COL_TOMATO"%s", eUser[playerid][e_USER_SECURITY_QUESTION]);
			Dialog_Show(playerid, FORGOT_PASSWORD, DIALOG_STYLE_INPUT, "Забыл пароль:", string, "Далее", "Отмена");
	    }
	    case 1:
	    {
	        const MASK = (-1 << (32 - 36));
			new string[256],
				ip[18];
			GetPlayerIp(playerid, ip, 18);
			format(string, sizeof(string), "SELECT `name`, `lastlogin_timestamp` FROM `users` WHERE ((`longip` & %i) = %i) LIMIT 1", MASK, (IpToLong(ip) & MASK));
			new DBResult:result = db_query(db, string);
			if (db_num_rows(result) == 0)
			{
			    SendClientMessage(playerid, COLOR_TOMATO, "Не найден первый IP-логин. Кажется, вы заходите впервые!");
		     	Dialog_Show(playerid, OPTIONS, DIALOG_STYLE_LIST, "Настройки аккаунта...", "Забыл пароль\nЗабыл никнейм\nВыйти", "Выбрать", "Назад");
			    return 1;
			}

			new list[25 * (MAX_PLAYER_NAME + 32)],
				name[MAX_PLAYER_NAME],
				lastlogin_timestamp,
				i,
				j = ((db_num_rows(result) > 10) ? (10) : (db_num_rows(result)));

			do
			{
			    db_get_field_assoc(result, "name", name, MAX_PLAYER_NAME);
				lastlogin_timestamp = db_get_field_assoc_int(result, "lastlogin_timestamp");
			    format(list, sizeof(list), "%s"COL_TOMATO"%s "COL_WHITE"|| Последний логин: %s назад\n", list, name, ReturnTimelapse(lastlogin_timestamp, gettime()));
			}
			while (db_next_row(result) && i > j);
			db_free_result(result);

			Dialog_Show(playerid, FORGOT_USERNAME, DIALOG_STYLE_LIST, "Ваша история никнеймов...", list, "Ok", "");
			PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
	    }
	    case 2:
	    {
	        return Kick(playerid);
	    }
	}
	return 1;
}

Dialog:FORGOT_PASSWORD(playerid, response, listitem, inputtext[])
{
	if (!response)
	{
	    Dialog_Show(playerid, OPTIONS, DIALOG_STYLE_LIST, "Настройки аккаунта...", "Забыл пароль\nЗабыл никнейм\nВыйти", "Выбрать", "Назад");
	    return 1;
	}

	new string[256],
		hash[64];
	SHA256_PassHash(inputtext, eUser[playerid][e_USER_SALT], hash, sizeof(hash));
	if (strcmp(hash, eUser[playerid][e_USER_SECURITY_ANSWER]))
	{
		if (++iAnswerAttempts[playerid] == MAX_LOGIN_ATTEMPTS)
		{
		    new lock_timestamp = gettime() + (MAX_ACCOUNT_LOCKTIME * 60);
		    new ip[18];
		    GetPlayerIp(playerid, ip, 18);
            format(string, sizeof(string), "INSERT INTO `temp_blocked_users` VALUES('%s', %i, %i)", ip, lock_timestamp, eUser[playerid][e_USER_SQLID]);
			db_query(db, string);

		    SendClientMessage(playerid, COLOR_TOMATO, "Извините этот аккаунта временно забанен. Использовано "#MAX_LOGIN_ATTEMPTS"/"#MAX_LOGIN_ATTEMPTS" попыток.");
		    format(string, sizeof(string), "If you forgot your password/username, click on 'Options' in login window next time (you may retry in %s).", ReturnTimelapse(gettime(), lock_timestamp));
			SendClientMessage(playerid, COLOR_TOMATO, string);
		    return Kick(playerid);
		}

	    format(string, sizeof(string), COL_WHITE "Введите ваш ответ на секретный вопрос, чтобы сбросить пароль.\n\n"COL_TOMATO"%s", eUser[playerid][e_USER_SECURITY_QUESTION]);
		Dialog_Show(playerid, FORGOT_PASSWORD, DIALOG_STYLE_INPUT, "Забыл пароль:", string, "Далее", "Отмена");
		format(string, sizeof(string), "Неправильный ответ. Осталось: %i/"#MAX_LOGIN_ATTEMPTS" попыток.", iAnswerAttempts[playerid]);
		SendClientMessage(playerid, COLOR_TOMATO, string);
	    return 1;
	}

	Dialog_Show(playerid, RESET_PASSWORD, DIALOG_STYLE_PASSWORD, "Восстановление пароля:", COL_WHITE "Введите ваш новый пароль.", "Подтвердить", "");
	SendClientMessage(playerid, COLOR_GREEN, "Успешно ввели ответ. Теперь введите ваш новый пароль");
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

Dialog:RESET_PASSWORD(playerid, response, listitem, inputtext[])
{
	if (!response)
	{
		Dialog_Show(playerid, RESET_PASSWORD, DIALOG_STYLE_PASSWORD, "Изменить пароль:", COL_WHITE "Введите ваш новый пароль.", "Подтверидть", "");
		return 1;
	}

	new string[256];

	if (!(MIN_PASSWORD_LENGTH <= strlen(inputtext) <= MAX_PASSWORD_LENGTH))
	{
	    Dialog_Show(playerid, RESET_PASSWORD, DIALOG_STYLE_PASSWORD, "Изменить пароль:", COL_WHITE "Введите ваш новый пароль", "Подтвердить", "");
		SendClientMessage(playerid, COLOR_TOMATO, "Пароль должен иметь "#MIN_PASSWORD_LENGTH" - "#MAX_PASSWORD_LENGTH" символов.");
	    return 1;
	}

	#if defined SECURE_PASSWORD_ONLY
		new bool:contain_number,
		    bool:contain_highercase,
		    bool:contain_lowercase;
		for (new i, j = strlen(inputtext); i < j; i++)
		{
		    switch (inputtext[i])
		    {
		        case '0'..'9':
		            contain_number = true;
				case 'A'..'Z':
				    contain_highercase = true;
				case 'a'..'z':
				    contain_lowercase = true;
		    }

		    if (contain_number && contain_highercase && contain_lowercase)
		        break;
		}

		if (!contain_number || !contain_highercase || !contain_lowercase)
		{
		    Dialog_Show(playerid, RESET_PASSWORD, DIALOG_STYLE_PASSWORD, "Изменить пароль:", COL_WHITE "Введите ваш новый пароль", "Подтверидть", "");
			SendClientMessage(playerid, COLOR_TOMATO, "Пароль должен состоять из букв и цифр.");
		    return 1;
		}
	#endif

	SHA256_PassHash(inputtext, eUser[playerid][e_USER_SALT], eUser[playerid][e_USER_PASSWORD], 64);

	new name[MAX_PLAYER_NAME],
		ip[18];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	GetPlayerIp(playerid, ip, 18);
	format(string, sizeof(string), "UPDATE `users` SET `password` = '%q', `ip` = '%s', `longip` = %i, `lastlogin_timestamp` = %i WHERE `id` = %i", eUser[playerid][e_USER_PASSWORD], ip, IpToLong(ip), gettime(), eUser[playerid][e_USER_SQLID]);
	db_query(db, string);

	format(string, sizeof(string), "Успешно авторизованы с новым паролем! %s. [Последний логин: %s назад]", name, ReturnTimelapse(eUser[playerid][e_USER_LASTLOGIN_TIMESTAMP], gettime()));
	SendClientMessage(playerid, COLOR_GREEN, string);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	SetPVarInt(playerid, "LoggedIn", 1);
	OnPlayerRequestClass(playerid, random(250));
	return 1;
}

Dialog:FORGOT_USERNAME(playerid, response, listitem, inputtext[])
{
	Dialog_Show(playerid, OPTIONS, DIALOG_STYLE_LIST, "Настройки аккаунта...", "Забыл пароль\nЗабыл никнейм\nВыйти", "Выбрать", "Назад");
	return 1;
}

CMD:randomchangearena(playerid, params[])
{
	if(eUser[playerid][e_USER_ADMIN_LEVEL] < 2) return SendClientMessage(playerid, -1, "У вас нет прав");
	ZoneNumberStopFlashForAll(arena);
	arena = random(MAX_ZONES);
	PrepareChangeArena();
	va_SendClientMessage(playerid, -1, "Администратор ", arena);
	return 1;
}

CMD:changearena(playerid, params[])
{
	if(eUser[playerid][e_USER_ADMIN_LEVEL] < 2) return SendClientMessage(playerid, -1, "У вас нет прав");
	new arenaid = strval(params);
	ZoneNumberStopFlashForAll(arena);
	arena = arenaid;
	PrepareChangeArena();
	va_SendClientMessage(playerid, -1, "Администратор сменил арену на ID: "COL_DEFAULT"%d", arena);
	return 1;
}

CMD:rtv(playerid, params[])
{
	if(connect < 3) return SendClientMessage(playerid, -1, "На сервер должно быть не меньше трёх игроков");
	rtvs++;
	va_SendClientMessageToAll(-1, "%s голосует за смену карты! (%d из %d)", eUser[playerid][Name], rtvs, connect);
	return 1;
}

CMD:changepass(playerid, params[])
{
	if (eUser[playerid][e_USER_SQLID] != 1)
	{
		SendClientMessage(playerid, COLOR_TOMATO, "Только авторизованные могут использовать команды.");
		return 1;
	}

    Dialog_Show(playerid, CHANGE_PASSWORD, DIALOG_STYLE_PASSWORD, "Изменение пароля...", COL_WHITE "Введите новый пароль"COL_WHITE".", "Подтвердить", "Отмена");
	SendClientMessage(playerid, COLOR_WHITE, "Введите новый пароль.");
	PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
	return 1;
}

Dialog:CHANGE_PASSWORD(playerid, response, listitem, inputtext[])
{
	if (!response)
		return 1;

	if (!(MIN_PASSWORD_LENGTH <= strlen(inputtext) <= MAX_PASSWORD_LENGTH))
	{
	    Dialog_Show(playerid, CHANGE_PASSWORD, DIALOG_STYLE_PASSWORD, "Изменение пароля от аккаунта...", COL_WHITE "Введите новый пароль.", "Подтвердить", "Отмена");
		SendClientMessage(playerid, COLOR_TOMATO, "Пароль должен иметь "#MIN_PASSWORD_LENGTH" - "#MAX_PASSWORD_LENGTH" символов.");
	    return 1;
	}

	#if defined SECURE_PASSWORD_ONLY
		new bool:contain_number,
		    bool:contain_highercase,
		    bool:contain_lowercase;
		for (new i, j = strlen(inputtext); i < j; i++)
		{
		    switch (inputtext[i])
		    {
		        case '0'..'9':
		            contain_number = true;
				case 'A'..'Z':
				    contain_highercase = true;
				case 'a'..'z':
				    contain_lowercase = true;
		    }

		    if (contain_number && contain_highercase && contain_lowercase)
		        break;
		}

		if (!contain_number || !contain_highercase || !contain_lowercase)
		{
		    Dialog_Show(playerid, CHANGE_PASSWORD, DIALOG_STYLE_INPUT, "Изменение пароля от аккаунта...", COL_WHITE "Введите новый пароль.", "Подтвердить", "Отмена");
			SendClientMessage(playerid, COLOR_TOMATO, "Пароль должен состоять из букв и цифр.");
		    return 1;
		}
	#endif

	SHA256_PassHash(inputtext, eUser[playerid][e_USER_SALT], eUser[playerid][e_USER_PASSWORD], 64);

	new string[256];
	for (new i, j = strlen(inputtext); i < j; i++)
	{
	    inputtext[i] = '*';
	}
	format(string, sizeof(string), "Пароль успешно изменён! [P: %s]", inputtext);
	SendClientMessage(playerid, COLOR_GREEN, string);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:changeques(playerid, params[])
{
	if (eUser[playerid][e_USER_SQLID] != 1)
	{
		SendClientMessage(playerid, COLOR_TOMATO, "Только авторизованные могут использовать команды.");
		return 1;
	}

    new list[2 + (sizeof(SECURITY_QUESTIONS) * MAX_SECURITY_QUESTION_SIZE)];
	for (new i; i < sizeof(SECURITY_QUESTIONS); i++)
	{
	    strcat(list, SECURITY_QUESTIONS[i]);
	    strcat(list, "\n");
	}
	Dialog_Show(playerid, CHANGE_SEC_QUESTION, DIALOG_STYLE_LIST, "Изменение секретного вопроса... [Шаг: 1/2]", list, "Далее", "Отмена");
	SendClientMessage(playerid, COLOR_WHITE, "[Шаг: 1/2] Выберите секретный вопрос!");
	PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
	return 1;
}

Dialog:CHANGE_SEC_QUESTION(playerid, response, listitem, inputext[])
{
	if (!response)
		return 1;

	SetPVarInt(playerid, "Question", listitem);

	new string[256];
	format(string, sizeof(string), COL_YELLOW "%s\n"COL_WHITE"Введите ваш ответ.", SECURITY_QUESTIONS[listitem]);
	Dialog_Show(playerid, CHANGE_SEC_ANSWER, DIALOG_STYLE_INPUT, "Изменение секретного вопроса... [Шаг: 2/2]", string, "Подтвердить", "Отмена");
	SendClientMessage(playerid, COLOR_WHITE, "[Шаг: 2/2] Write the answer to your secuirty question.");
	PlayerPlaySound(playerid, 1054, 0.0, 0.0, 0.0);
	return 1;
}

Dialog:CHANGE_SEC_ANSWER(playerid, response, listitem, inputtext[])
{
	if (!response)
	{
		new list[2 + (sizeof(SECURITY_QUESTIONS) * MAX_SECURITY_QUESTION_SIZE)];
		for (new i; i < sizeof(SECURITY_QUESTIONS); i++)
		{
		    strcat(list, SECURITY_QUESTIONS[i]);
		    strcat(list, "\n");
		}
		Dialog_Show(playerid, CHANGE_SEC_QUESTION, DIALOG_STYLE_LIST, "Изменение секретного вопроса... [Шаг: 1/2]", list, "Далее", "Отмена");
		SendClientMessage(playerid, COLOR_WHITE, "[Шаг: 1/2] Выберите секретный вопрос!");
		return 1;
	}

	new string[512];

	if (strlen(inputtext) < MIN_PASSWORD_LENGTH || inputtext[0] == ' ')
	{
	    format(string, sizeof(string), COL_YELLOW "%s\n"COL_WHITE"Введите ответ на секретный вопрос.", SECURITY_QUESTIONS[listitem]);
		Dialog_Show(playerid, CHANGE_SEC_ANSWER, DIALOG_STYLE_INPUT, "Изменение секретного вопроса... [Шаг: 2/2]", string, "Подтвердить", "Отмена");
		SendClientMessage(playerid, COLOR_TOMATO, "Ответ должен состоять минимум из "#MIN_PASSWORD_LENGTH" символов.");
		return 1;
	}

	format(eUser[playerid][e_USER_SECURITY_QUESTION], MAX_SECURITY_QUESTION_SIZE, SECURITY_QUESTIONS[GetPVarInt(playerid, "Question")]);
	DeletePVar(playerid, "Question");

	for (new i, j = strlen(inputtext); i < j; i++)
	{
        inputtext[i] = tolower(inputtext[i]);
	}
	SHA256_PassHash(inputtext, eUser[playerid][e_USER_SALT], eUser[playerid][e_USER_SECURITY_ANSWER], 64);
	format(string, sizeof(string), "Ответ на секретный вопрос успешно изменён! [Q: %s].", eUser[playerid][e_USER_SECURITY_QUESTION]);
	SendClientMessage(playerid, COLOR_GREEN, string);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:stats(playerid, params[])
{
	new targetid;
	if (sscanf(params, "u", targetid))
	{
  		targetid = playerid;
		SendClientMessage(playerid, COLOR_DEFAULT, "Tip: Используйте /stats [player id]");
	}

	if (!IsPlayerConnected(targetid))
		return SendClientMessage(playerid, COLOR_TOMATO, "Игрок не подключен.");

	new name[MAX_PLAYER_NAME];
	GetPlayerName(targetid, name, MAX_PLAYER_NAME);

	SendClientMessage(playerid, -1, "_______________________________________________");
	SendClientMessage(playerid, -1, "");
	va_SendClientMessage(playerid, -1, "{00ff00}%s[%i] {FFFFFF}статистика: (AccountId: %i)", name, targetid, eUser[targetid][e_USER_SQLID]);

	new Float:ratio = ((eUser[targetid][e_USER_DEATHS] < 0) ? (0.0) : (floatdiv(eUser[targetid][e_USER_KILLS], eUser[targetid][e_USER_DEATHS])));

	static levelname[6][25];
	if (!levelname[0][0])
	{
		levelname[0] = "Player";
		levelname[1] = "Operator";
		levelname[2] = "Moderator";
		levelname[3] = "Administrator";
		levelname[4] = "Manager";
		levelname[5] = "Owner/RCON";
	}

	static gangname[15];
	if(eUser[targetid][GangId] == 0){
		gangname = "Нет банды";
	}else{
		format(gangname, 15, GangsNew[eUser[targetid][GangId]-1][Tag]);
	}

	va_SendClientMessage(playerid, -1, "Exp: %i || Убийств: %i || Смертей: %i || Ratio: %0.2f || Админ уровень: %i - %s || Vip уровень: %i",
		GetPlayerScore(targetid), eUser[targetid][e_USER_KILLS], eUser[targetid][e_USER_DEATHS], ratio, eUser[targetid][e_USER_ADMIN_LEVEL], levelname[((eUser[targetid][e_USER_ADMIN_LEVEL] > 5) ? (5) : (eUser[targetid][e_USER_ADMIN_LEVEL]))], eUser[targetid][e_USER_VIP_LEVEL]);
	va_SendClientMessage(playerid, -1, "Выиграно дуелей: %i || Проиграно дуелей: %i || Банда: %s", eUser[targetid][DuelWon], eUser[targetid][DuelLose], gangname);

	va_SendClientMessage(playerid, -1, "{FFFFFF}Зарегистрировался: "COL_RED"%s назад {FFFFFF}|| Последний логин: "COL_RED"%s назад",
	 	ReturnTimelapse(eUser[playerid][e_USER_REGISTER_TIMESTAMP], gettime()), ReturnTimelapse(eUser[playerid][e_USER_LASTLOGIN_TIMESTAMP], gettime()));

	SendClientMessage(playerid, -1, "");
	SendClientMessage(playerid, -1, "_______________________________________________");
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source){
	new string[3];
	format(string, sizeof(string), "%d", clickedplayerid);
	cmd_stats(playerid, string);
	return true;
}

CMD:help(playerid, params[]){
	Dialog_Show(playerid, DIALOG_HELP, DIALOG_STYLE_MSGBOX, "{FFFFFF}Помощь", ""COL_DEFAULT"- /credits {FFFFFF}- узнать разработчиков.\n"COL_DEFAULT"- /cmds {FFFFFF}- команды сервера\n"COL_DEFAULT"- sa-gdm.ru {FFFFFF}- сайт", "Ok", "Отмена");	
	return true;
}

CMD:credits(playerid, params[]){
	Dialog_Show(playerid, DIALOG_HELP, DIALOG_STYLE_MSGBOX, ""COL_DEFAULT"Кредиты", "{FFFFFF}Писал всё, всё, кроме основы - ShimaNeko\nТекстдравы - ShimaNeko\nАрены - ShimaNeko, Renzo, Sowngarde, FroG\nОснова reg/log от Gammix'a\nМои контакты\nvk: vk.com/shimaneko или discord: ShimaNeko#6885\n\nАккаунты на SQLite, weapon-config от Slice'a", "Ok", "Отмена");
	return true;
}

CMD:cmds(playerid, params[]){
	Dialog_Show(playerid, DIALOG_COMMANDS, DIALOG_STYLE_MSGBOX, "{FFFFFF}Команды [1 из No-one]", ""COL_DEFAULT"/stats - статистика\n/changeskin - изменить скин\n/afk - уйти в афк/вернуться\n/weather - изменить погоду\n/time - изменить время\n/changeques - изменить секретный вопрос\n\
		/changepass - изменить пароль\n/duel - сообщить о дуеле в чат\n/respawn - сделать респавн\n/ghelp - команды для банд\n/changepack - изменить пак", "Ok", "Отмена");
	return true;
}

CMD:ghelp(playerid, params[]){
	Dialog_Show(playerid, DIALOG_GCOMMANDS, DIALOG_STYLE_MSGBOX, "{FFFFFF}Команды для банд", ""COL_DEFAULT"/gangcreate - создать банду\n/gangjoin - подать заявку\n/leave - выйти из банды\n/ginfo - узнать информацию о банд\n/gangtop - узнать ТОП-10 банд", "Ok", "Отмена");
	return true;
}

// сделать показ л в дуелей в стате
// по клику смотреть стату игрока и дополнить ее
// украсить теест
CMD:changeskin(playerid, params[]){
    new skinid = strval(params);
    if(isnull(params)) return SendClientMessage(playerid, -1, ""COL_BLACK"Используйте: /changeskin [ID].");
	if(!IsNumeric(params)) return SendClientMessage(playerid,-1,""COL_DEFAULT"[ОШИБКА] "COL_WHITE"Введите число."); 
    //if raz proverka
    // if dva proverka
    if(skinid < 1 || skinid > 300) return true;
    SetPlayerSkin(playerid, skinid);
    SetPVarInt(playerid, "PlayerSkin", skinid);
    // выводим диалог о том, хочет ли игрок сохранить свой скин и использовать его в дальнейшем

    return true;
}

// ban, kick, delgang, mute, changename, 

CMD:changepack(playerid, params[]){
	new Float:Armour;
	GetPlayerArmour(playerid, Armour);
	if(Armour < 20.0) return SendClientMessage(playerid, -1, "Вы не можете уйти в афк.");	
	Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Спавн");
	SetPlayerVirtualWorld(playerid, 15);
    return true;
}

CMD:afk(playerid, params[]){
	new Float:Armour;
	GetPlayerArmour(playerid, Armour);
	if(Armour < 20.0) return SendClientMessage(playerid, -1, "Вы не можете уйти в афк.");	
    if(GetPVarInt(playerid, "onafk") == 0){
       SendClientMessage(playerid, -1, ""COL_RED"Вы решили отдохнуть. Повторно используйте "COL_WHITE"/afk"COL_RED", чтобы вернутся.");
       SetPVarInt(playerid, "onafk", 1);
       SetPlayerPos(playerid, 1361.9303,-15.6455,1000.9219);
       SetPlayerVirtualWorld(playerid, 123);
       SetPlayerInterior(playerid, 1);
       ResetPlayerWeapons(playerid);
    }else{
       SendClientMessage(playerid, -1, ""COL_RED"С возвращением!");
       SetPVarInt(playerid, "onafk", 0);
       SpawnPlayer(playerid);
       GameTextForPlayer(playerid, "~r~Welcome Back!", 3000, 1);
    }
    return true;
}

CMD:weather(playerid,params[])
{
    if(isnull(params)) return SendClientMessage(playerid, -1, ""COL_BLACK"Используйте: /weather [id weather].");
	if(!IsNumeric(params)) return SendClientMessage(playerid,-1,""COL_DEFAULT"[ОШИБКА] "COL_WHITE"Введите число.");
	

	new myweather;
	myweather = strval(params);

	SetPlayerWeather(playerid, myweather);
    va_SendClientMessage(playerid, -1, ""COL_WHITE"Погода изменена на "COL_DEFAULT"%d"COL_WHITE".", myweather);

    return 1;
}

CMD:w(playerid, params[])
{
	cmd_weather(playerid, params);
	return 1;
}

CMD:time(playerid, params[])
{
	if(isnull(params)) return SendClientMessage(playerid, -1, ""COL_BLACK"Используйте: /time [время].");
	if(!IsNumeric(params)) return SendClientMessage(playerid,-1,""COL_DEFAULT"[ОШИБКА] "COL_WHITE"Введите число.");

	new mytime;
	mytime = strval(params);

	SetPlayerTime(playerid, mytime, 0);
    va_SendClientMessage(playerid, -1, ""COL_WHITE"Вы установили время на "COL_DEFAULT"%d:00"COL_WHITE".", mytime);
    return 1;
}

CMD:t(playerid, params[])
{
	cmd_time(playerid, params);
	return 1;
}

CMD:respawn(playerid, params[]){
	new Float:Armour;
	GetPlayerArmour(playerid, Armour);
	if(Armour < 20.0) return SendClientMessage(playerid, -1, "Вы не можете сделать респавн.");
	SpawnPlayer(playerid);
	return true;
}

CMD:kick(playerid, params[])
{
	//if(Player[playerid][Level] < 3) return SendClientMessage(playerid,-1,""COL_RED"[ОШИБКА] "COL_WHITE"You need to be a higher admin level.");

	new Params[2][128];
	sscanf(params, "s[128]s[128]", Params[0], Params[1]);
	if(isnull(Params[0]) || !IsNumeric(Params[0])) return SendClientMessage(playerid,-1,""COL_BLACK"Используйте: /kick [playerid] [reason] - Kick player from the server.");
	new pID = strval(Params[0]);

	if(!IsPlayerConnected(pID)) return SendClientMessage(playerid,-1,""COL_RED"[ОШИБКА] "COL_WHITE"Этот игрок не подключён");
	//if(Player[pID][Level] >= Player[playerid][Level]) return SendClientMessage(playerid,-1,""COL_RED"[ОШИБКА] "COL_WHITE"Can't kick someone of same or higher admin level.");

	new bool:GiveReason;
	if(isnull(Params[1])) GiveReason = false;
	else GiveReason = true;

	if(GiveReason == false) {
		va_SendClientMessageToAll(-1,""COL_DEFAULT"Админ{FFFFFF} %s"COL_DEFAULT" кикнул %s (%d).", eUser[playerid][Name], eUser[pID][Name], pID);
	} else {
		va_SendClientMessageToAll(-1,""COL_DEFAULT"Админ{FFFFFF} %s"COL_DEFAULT" кикнул %s (%d). Причина: %s", eUser[playerid][Name], eUser[pID][Name], pID, Params[1]);
	}


    Kick(playerid);
//	Player[pID][IsKicked] = true;
//	Kick(pID);


	return 1;
}

CMD:ban(playerid, params[])
{
	//if(Player[playerid][Level] < 3) return SendClientMessage(playerid,-1,""COL_RED"[ОШИБКА] {FFFFFF}You need to be a higher Админ level.");

	new Params[2][128];
	sscanf(params, "s[128]s[128]", Params[0], Params[1]);
	if(isnull(Params[0]) || !IsNumeric(Params[0])) return SendClientMessage(playerid,-1,""COL_BLACK"Используйте: /ban [playerid] [Причина] - Ban player.");
	new pID = strval(Params[0]);

	if(!IsPlayerConnected(pID)) return SendClientMessage(playerid,-1,""COL_RED"[ОШИБКА] {FFFFFF}Этот игрок не подключён.");
	//if(Player[pID][Level] >= Player[playerid][Level]) return SendClientMessage(playerid,-1,""COL_RED"[ОШИБКА] {FFFFFF}Can't ban someone of same or higher Админ level.");

	new IP[50];
	GetPlayerIp(pID, IP, sizeof(IP));

	new bool:GiveReason;
	if(isnull(Params[1])) GiveReason = false;
	else GiveReason = true;


	if(GiveReason == false) {
		va_SendClientMessageToAll(-1,""COL_DEFAULT"Админ{FFFFFF} %s"COL_DEFAULT" забанил %s (%d) на.", eUser[playerid][Name], eUser[pID][Name], pID);
//		Ban(pID);
	} else {
		va_SendClientMessageToAll(-1,""COL_DEFAULT"Админ{FFFFFF} %s"COL_DEFAULT" забанил %s (%d) на. Причина: %s", eUser[playerid][Name], eUser[pID][Name], pID, Params[1]);
//		BanEx(pID, Params[1]);
	}

    Kick(playerid);

	return 1;
}

CMD:ginfo(playerid, params[]){
	new gangidd = strval(params);
	if(!IsNumeric(params)) return true;
	if(isnull(params)) return true;
	if(gangidd > gangs) return true;
	va_SendClientMessage(playerid, -1, "{808080}[GANG INFO] {FFFFFF}Банда: %s || ID: %d || Всего Exp: %d || Никнейм лидера: -1", GangsNew[gangidd][Tag], gangidd, GangsNew[gangidd][Exp]);
	return true;
}

CMD:gangcreate(playerid, params[]){
	new Option[8], string[85];	
	if(sscanf(params, "s[8]",Option)) return SendClientMessage(playerid, -1, "Введите: /gangcreate [Tag]");
	if(strlen(Option) < 1 || strlen(Option) > 8) return SendClientMessage(playerid, COLOR_WHITE, "Введите: /gangcreate Tag [8 символов]");
	if(eUser[playerid][GangId] != 0) return SendClientMessage(playerid, -1, "{808080}[GANG] {FFFFFF}Вы уже состоите в банде. Выйдите с помощью /gangleave");
	if(eUser[playerid][Level] < 2) return SendClientMessage(playerid, -1, "{808080}[GANG] {FFFFFF}Вы должны быть как минимум второго уровня");
	format(string, sizeof(string), "SELECT * FROM `gangs` WHERE `tag` = '%q' LIMIT 1", Option);
	new DBResult:result = db_query(db, string);
	if (db_num_rows(result) == 1)
	{	
		SendClientMessage(playerid, -1, "{808080}[GANG] {FFFFFF}Данный клан тег уже существует. Придумайте другой.");
		return true;
	}
	db_free_result(result);
	format(string, sizeof(string), "INSERT INTO `gangs`(`tag`,`dmg`,`leaderid`) VALUES('%s', '0', '%i')", Option, eUser[playerid][e_USER_SQLID]);
	db_query(db, string);
	gangs++;
	va_SendClientMessage(playerid, -1, "{808080}[GANG] "COL_DEFAULT"Вы успешно создали банду {FFFFFF}%s!", Option);
	eUser[playerid][GangId] = gangs+1;
	PlayerTextDrawShow(playerid, GangInfo[playerid]);
	return true;
}

CMD:gangjoin(playerid, params[]){
	new gangidd = strval(params);
	if(!IsNumeric(params)) return true;
	if(isnull(params)) return true;
	if(eUser[playerid][GangId] != 0) return SendClientMessage(playerid, -1, "{808080}[GANG] {FFFFFF}Вы уже состоите в банде. Выйдите с помощью /gangleave");
	//If lider etoi bandi ne v seti
	new bool:gangleader = false;
	foreach(new i: Player){
		if(GangsNew[gangidd][LeaderId] == eUser[i][e_USER_SQLID]) gangleader = true;
	}
	if(gangleader == false) return SendClientMessage(playerid, -1, "{808080}[GANG] {FFFFFF}Лидера этой банды нет в сети! Пожалуйста, перезвоните позже...");
	//SendClientMessage(playerid, color, const message[]) Для пидобира лидера
	SendClientMessage(playerid, -1, ""COL_DEFAULT"Вы подали заявку. Ожидайте.");
	SetPVarInt(playerid, "GangWait", gangidd+1);
	foreach(new i: Player){
		if(eUser[i][e_USER_SQLID] == GangsNew[gangidd][LeaderId]) va_SendClientMessage(i, -1, "{808080}[GANG] {FFFFFF}Игрок %s(%d) желает вступить в вашу банду. /accept (принять) или /denied (отказать)", eUser[playerid][Name], playerid);
	}
	return true;
}

CMD:gangtop(playerid, params[]){
	new fulldialog[600], str[60];
	fulldialog = "{ffffff}Место\t\tТег [ID банды]\t\t  Респектов\n\n";
	new DBResult:result = db_query(db, "SELECT * FROM `gangs` ORDER BY `dmg` DESC LIMIT 10");

    for(new i = 0; i < db_num_rows(result); i++){
    	new Tagg[8];

        db_get_field_assoc(result, "tag", Tagg, 8);
		format(str, sizeof str, ""COL_DEFAULT"%d\t\t {ffffff}[%s] [%d]\t\t  {E60000}%d\n",i+1, Tagg, db_get_field_assoc_int(result, "id")-1, db_get_field_assoc_int(result, "dmg"));
        strcat(fulldialog, str);
        db_next_row(result);
    }
    db_free_result( result );   
    Dialog_Show(playerid, 1488, DIALOG_STYLE_MSGBOX, "Топ 10 банд", fulldialog, "Готово", "");	
	return true;
}	

CMD:accept(playerid, params[]){
	new targetid = strval(params);
	if(!IsNumeric(params)) return SendClientMessage(playerid, -1, "{808080}[GANG] {FFFFFF}Ошибка 1");
	if(GetPVarInt(targetid, "GangWait") != eUser[playerid][GangId]) return SendClientMessage(playerid, -1, "{808080}[GANG] {FFFFFF}Ошибка 2");
	// if eto ne lider
	eUser[targetid][GangId] = eUser[playerid][GangId];
	PlayerTextDrawShow(targetid, GangInfo[targetid]);
	foreach(new i: Player){
		if(eUser[playerid][GangId] == eUser[i][GangId]){
			va_SendClientMessage(i, -1, "{808080}[GANG] "COL_DEFAULT"%s присоединился к банде!", eUser[targetid][Name]);
		}
	}	
	return true;
}

CMD:leave(playerid, params[]){
	if(eUser[playerid][GangId] == 0) return SendClientMessage(playerid, -1, "Вы не состоите в банде.");
	foreach(new i: Player){
		if(eUser[playerid][GangId] == eUser[i][GangId]){
			va_SendClientMessage(i, -1, "{808080}[GANG] "COL_DEFAULT"%s вышел из вашей банды.", eUser[playerid][Name]);
		}
	}
	PlayerTextDrawHide(playerid, GangInfo[playerid]);
	eUser[playerid][GangId] = 0;
	eUser[playerid][GangExp] = 0;
	return true;
}

CMD:duel(playerid, params[]){
	if(GetPVarInt(playerid, "ReadyToDuel") == 1) return true;
	if(GetPVarInt(playerid, "ReadyToDuel") == 2) return true;	
	va_SendClientMessageToAll(-1, ""COL_RED"%s(%d) {FFFFFF}хочет дуель. Чтобы ответить ему, напишите "COL_DEFAULT"/go %d", eUser[playerid][Name], playerid, playerid);
	SetPVarInt(playerid, "ReadyToDuel", 1);
	SendClientMessage(playerid, -1, ""COL_DEFAULT"Ожидайте. Через 8 секунд ваше предложение отменится.");
	DuelTimer[playerid] = SetTimerEx("Otkat", 8000, false, "i", playerid);
	return true;
}

forward Otkat(playerid);
public Otkat(playerid){
	SetPVarInt(playerid, "ReadyToDuel", 0);
	return true;
}

CMD:go(playerid, params[]){
	new targetid = strval(params);
	if(GetPVarInt(playerid, "ReadyToDuel") == 1) return true;
	if(GetPVarInt(playerid, "ReadyToDuel") == 2) return true;		
	if(GetPVarInt(targetid, "ReadyToDuel") == 2) return true;		
	if(GetPVarInt(targetid, "ReadyToDuel") == 0) return SendClientMessage(playerid, -1, "Этот игрок не хочет дуель.");
	SetPlayerPos(playerid, 1417.5233,-17.1838,1000.9268);
	SetPlayerPos(targetid, 1361.9303,-15.6455,1000.9219);
	SetPlayerInterior(playerid, 1);
	SetPlayerInterior(targetid, 1);
	ResetPlayerWeapons(playerid);
	SetPlayerHealth(playerid, 100.0);
	SetPlayerHealth(targetid, 100.0);
	SetPlayerArmour(playerid, 100.0);
	SetPlayerArmour(targetid, 100.0);
	GivePlayerWeapon(playerid, 24, 200);
	GivePlayerWeapon(playerid, 25, 200);
	GivePlayerWeapon(playerid, 34, 200);
	ResetPlayerWeapons(targetid);
	GivePlayerWeapon(targetid, 24, 200);
	GivePlayerWeapon(targetid, 25, 200);
	GivePlayerWeapon(targetid, 34, 200);	
	SetPlayerVirtualWorld(playerid, targetid+3);
	SetPlayerVirtualWorld(targetid, targetid+3);
	KillTimer(DuelTimer[playerid]);
	SetPVarInt(playerid, "ReadyToDuel", 2);
	SetPVarInt(targetid, "ReadyToDuel", 2);
	return true;
}


public OnPlayerDamage(&playerid, &Float:amount, &issuerid, &weapon, &bodypart)
{
	if(issuerid != INVALID_PLAYER_ID && playerid != INVALID_PLAYER_ID)
	{	
		if(weapon == 24){
			switch(bodypart){
				case 3: amount = 35.0;
				case 4: amount = 35.0;
				case 5: amount = 30.0;
				case 6: amount = 30.0;
				case 7: amount = 30.0;
				case 8: amount = 30.0;
				case 9: amount = 40.0;
			}
		}
		new Float:arm, Float:Health;
		GetPlayerArmour(playerid, arm);
		GetPlayerHealth(playerid, Health);
		if(GetPVarInt(playerid, "Protect") == 1){
			SetPlayerHealth(playerid, Health);
			SetPlayerArmour(playerid, arm);
			return false;
		}
		if(GetPVarInt(issuerid, "Protect") == 1){
			SetPlayerHealth(playerid, Health);
			SetPlayerArmour(playerid, arm);
			return false;
		}		
		eUser[issuerid][GiveDMG] += amount;
		eUser[playerid][TakenDMG] += amount;				
		if(objecthporarmour[playerid] != 0) DestroyObject(objecthporarmour[playerid]), KillTimer(hpandarmourtimer[playerid]);
		if(arm > 1){
			objecthporarmour[playerid] = CreateObject(1242, 0, 0, 0, 0, 0, 0);
			AttachObjectToPlayer(objecthporarmour[playerid], playerid, 0, 0, 1.60, 0, 0, 0);	
		}else{
			objecthporarmour[playerid] = CreateObject(1240, 0, 0, 0, 0, 0, 0);
			AttachObjectToPlayer(objecthporarmour[playerid], playerid, 0, 0, 1.60, 0, 0, 0);			
		}
		hpandarmourtimer[playerid] = SetTimerEx("HideWeaponObject", 1500, false, "i", playerid);
	    if(eUser[issuerid][GangId] > 0 && eUser[issuerid][GangId] == eUser[playerid][GangId]){
	        GameTextForPlayer(issuerid, "~r~Stop shoting your gangsta!", 1000, 6);
	    }
	}	
	return true;
}

forward HideWeaponObject(playerid);
public HideWeaponObject(playerid)
{
    DestroyObject(objecthporarmour[playerid]);
	objecthporarmour[playerid] = 0;
}

public OnPlayerText(playerid, text[]){
    if(GetTickCount() < GetPVarInt(playerid, "ChatTime")) { SendClientMessage(playerid, -1, ""COL_WHITE"[Ошибка] "COL_DEFAULT"Пожалуйста, подождите!"); return false; }
	SetPVarInt(playerid, "ChatTime", GetTickCount()+1000);	
	if(text[0] == '!') {
		foreach(new i: Player)
			if(eUser[playerid][GangId] == eUser[i][GangId]) va_SendClientMessage(i, -1, "{FFFFFF}'!' {%06x}%s {FFFFFF}[%d]: %s", (GetPlayerColor(playerid) >>> 8), eUser[playerid][Name], playerid, text[1]);
		return false;
	}
	if(eUser[playerid][GangId] == 0) va_SendClientMessageToAll(-1, "{%06x}%s {FFFFFF}[%d]: %s", (GetPlayerColor(playerid) >>> 8), eUser[playerid][Name], playerid, text);
	if(eUser[playerid][GangId] == 1) va_SendClientMessageToAll(-1, "{%06x}[%s]%s {FFFFFF}[%d]: %s", (GetPlayerColor(playerid) >>> 8), GangsNew[eUser[playerid][GangId]-1][Tag], eUser[playerid][Name], playerid, text);
	SetPlayerChatBubble(playerid, text, 0xFFFFFFFF, 70.0, 4000);
	return false;
}

forward OnScriptUpdate();
public OnScriptUpdate()
{
	new iString[200];
	foreach(new i : Player) {
		new drunk2 = GetPlayerDrunkLevel(i);
		if(drunk2 < 100){
		    SetPlayerDrunkLevel(i,2000);
		}else{
		    if(eUser[i][DLlast] != drunk2){
		        new fps = eUser[i][DLlast] - drunk2;
		        if((fps > 0) && (fps < 450))
	   			eUser[i][FPS] = fps;
				eUser[i][DLlast] = drunk2;
			}
		}

		if(GetPlayerWeapon(i) == 26 || GetPlayerWeapon(i) == 35 || GetPlayerWeapon(i) == 35|| GetPlayerWeapon(i) == 38) Kick(i);

		new Float:ratio = ((eUser[i][e_USER_DEATHS] < 0) ? (0.0) : (floatdiv(eUser[i][e_USER_KILLS], eUser[i][e_USER_DEATHS])));

		format(iString,sizeof(iString),"~w~~h~~h~FPS ~r~~h~%d ~w~~h~~h~Ping ~r~~h~%d ~w~~h~~h~PacketLoss ~r~~h~%.1f%%",  eUser[i][FPS], GetPlayerPing(i), NetStats_PacketLossPercent(i));
		PlayerTextDrawSetString(i, FPSPingPacket[i],iString);

	    format(iString, sizeof(iString), "_~n~_~n~~y~~h~Kills~w~~h~_%d_~y~~h~Deaths_~w~~h~%d_~y~~h~Won_~w~~h~%d_~y~~h~Lose_~w~~h~%d_~y~~h~K/D_~w~~h~%0.2f_~y~~h~Spree_~w~~h~%d", eUser[i][e_USER_KILLS], eUser[i][e_USER_DEATHS], eUser[i][DuelWon], eUser[i][DuelLose], ratio, GetPVarInt(i, "Spree"));  
		PlayerTextDrawSetString(i, InfoStats[i][0], iString);

		if(eUser[i][GangId] != 0){
			format(iString,sizeof(iString),"~r~~h~%s~n~~w~~h~%d~r~/~w~~h~%d",  GangsNew[eUser[i][GangId]-1][Tag], eUser[i][GangExp], GangsNew[eUser[i][GangId]-1][Exp]);
			PlayerTextDrawSetString(i, GangInfo[i],iString);				
		}
	}
	if(startarena == true){
		RoundSeconds--;
		if(RoundSeconds == 1) {
			RoundSeconds = 59;		 
			RoundMints--;
			if(RoundMints < 0){
				new gangexp, gangidd = -1;
				for(new i = 0; i < MAX_GANGS; i++){
					if(GangsNew[i][ArenaExp] > gangexp && GangsNew[i][ArenaExp] > 0)
					{
					    gangexp = GangsNew[i][ArenaExp]; 
					    gangidd = i;
					}		
				}	
				if(gangexp > zones[arena][Exp]){
					zones[arena][Exp] = gangexp;
					zones[arena][Gangid] = gangidd;
					HideZoneForAll(arena), ShowZoneForAll(arena,GetClanColor(arena),0xFFFFFFFF,0xFFFFFFFF);
					va_SendClientMessageToAll(-1, ""COL_RED"%s {FFFFFF}захватили арену номер "COL_DEFAULT"%d!", GangsNew[gangidd][Tag], arena);
				}	
				ZoneNumberStopFlashForAll(arena), arena = random(MAX_ZONES), PrepareChangeArena();
				return true;
			}
		}
	}	
    new hour, minute, second;
    new year, month, day;
    getdate(year, month, day);
    gettime(hour, minute, second);
	format(iString, sizeof(iString), "~w~%02d/%02d/%d~n~%02d:%02d:%02d", day, month, year, hour, minute, second);
	TextDrawSetString(Clock, iString);

	format(iString, sizeof(iString), "~g~~h~Arena_~w~~h~%d~n~~r~~h~Time_~w~~h~%d:~w~%02d", arena, RoundMints, RoundSeconds);
	TextDrawSetString(ArenaTime, iString);
	//format(iString, sizeof(iString), "~w~~h~Top~n~~w~~h~Kills: ~r~~h~%s ~w~~h~- %d Kills~N~Damage: ~r~~h~%s ~w~~h~- %0.2f DMG", eUser[arenakillsid][Name], eUser[arenakillsid][ArenaKills], eUser[arenadmgid][Name], eUser[arenadmgid][ArenaDMG]);
	//TextDrawSetString(TopOfArena, iString);			
	return 1;
}

forward teensecupdate();
public teensecupdate(){
	new string[120];
	for(new g = 0; g < gangs; g++){
	    format(string, sizeof(string), "UPDATE `gangs` SET `dmg` = '%i' WHERE `id` = '%i'", GangsNew[g][Exp], g+1);
	    db_query(db, string);
	    printf("Сохранил %d", g);
	}	
	for(new a = 0; a < MAX_ZONES; a++){
	    format(string, sizeof(string), "UPDATE `zones` SET `Gangid` = '%i', `Exp` = '%i' WHERE `id` = '%i'", zones[a][Gangid], zones[a][Exp], a+1);
	    db_query(db, string);
	}							
	return true;
}

stock PrepareChangeArena(){	
	new Float:arenadmgg, arenadmgid = -1, arenakillss, arenakillsid = -1, arenaexp, arenaexpid = -1, gangexp, gangidd = -1;
	new iString[250];	
	foreach(new i: Player){
		if(eUser[i][ArenaDMG] > arenadmgg && eUser[i][ArenaDMG] > 0){
			arenadmgg = eUser[i][ArenaDMG]; 
			arenadmgid = i;
		}	
		if(eUser[i][ArenaKills] > arenakillss && eUser[i][ArenaKills] > 0)
		{
		    arenakillss = eUser[i][ArenaKills]; 
		    arenakillsid = i;
		}		
		if(eUser[i][ArenaExp] > arenaexp && eUser[i][ArenaExp] > 0)
		{
		    arenaexp = eUser[i][ArenaExp]; 
		    arenaexpid = i;
		}		
		if(GetPVarInt(i, "ReadyToDuel") == 0){
			TogglePlayerControllable(i, 0);			
		}			
	}
	for(new i = 0; i < MAX_GANGS; i++){
		if(GangsNew[i][ArenaExp] > gangexp && GangsNew[i][ArenaExp] > 0)
		{
		    gangexp = GangsNew[i][ArenaExp]; 
		    gangidd = i;
		}		
	}
	if(gangexp == 0) gangidd = 0;
	if(arenadmgid != -1 && arenakillsid != -1 && arenaexpid != -1){
		format(iString, sizeof(iString), "~r~~h~Round finished! ~w~~h~Top Of Arena:~n~~g~~h~Top gang (exp):~w~~h~ %s - %d exp~n~~g~~h~Top Exp:~w~~h~ %s - %d exp~n~~g~~h~Top Kills:~w~~h~ %s - %d kills~n~~g~~h~Top dmg:~w~~h~ %s - %.2f dmg", GangsNew[gangidd][Tag], GangsNew[gangidd][ArenaExp], eUser[arenaexpid][Name], eUser[arenaexpid][ArenaExp], eUser[arenakillsid][Name], eUser[arenakillsid][ArenaKills], eUser[arenadmgid][Name], eUser[arenadmgid][ArenaDMG]);
		//strcat(iString,"~r~~h~Round_finished!~n~~w~~h~Top_Of_Arena~n~~g~~h~Top_gang_(exp):~w~~h~_%s_-_%d_exp~n~~g~~h~Top_Exp:~w~~h~_%s_-_%d", GangsNew[gangidd][Tag], GangsNew[gangidd][ArenaExp], eUser[arenaexpid][Name], eUser[arenaexpid][ArenaExp]);
		//strcat(iString,"_exp~n~~g~~h~Top_Kills:~w~~h~_%s_-_%d_kills~n~~g~~h~Top_dmg:~w~~h~_%s_-_%d_dmg", eUser[arenakillsid][Name], eUser[arenakillsid][ArenaKills], eUser[arenadmgid][Name], eUser[arenadmgid][ArenaDMG]);
		TextDrawSetString(TopOfArena, iString);
	}	

	TextDrawShowForAll(TopOfArena);

	startarena = false;
	SetTimer("ChangeArena", 6000, false);
	GameTextForAll("~r~ROUND FINISHED",2000,1);	
	rtvs = 0;


	return true;
}

forward ChangeArena();
public ChangeArena()
{
	new iString[21];
	format(iString, 21, "language Arena %d", arena);
	SendRconCommand(iString);
	va_SendClientMessageToAll(-1,"{FFFFFF}Арена {FF0000}(ID: %d) {FFFFFF}запущена!", arena);
	foreach(new i: Player){
		if(GetPVarInt(i, "ReadyToDuel") == 0){
			SpawnPlayer(i);
		}	
		eUser[i][ArenaDMG] = 0;
		eUser[i][ArenaKills] = 0;	
		eUser[i][ArenaExp] = 0;		
	}
	for(new i = 0; i < MAX_GANGS; i++) GangsNew[i][ArenaExp] = 0;
	ZoneNumberFlashForAll(arena,0xCC0000FF);
	TextDrawHideForAll(TopOfArena);
	RoundMints = 7;
	startarena = true;
	return 1;
}

stock IsNumeric(string[]){
    for (new i = 0, j = strlen(string); i < j; i++){
            if (string[i] > '9' || string[i] < '0') return 0;
    }
    return 1;
}

stock playertextdraws(playerid){
	FPSPingPacket[playerid] = CreatePlayerTextDraw(playerid, 554.400024, 2.986654, "_");
	PlayerTextDrawLetterSize(playerid, FPSPingPacket[playerid], 0.210795, 0.843375);
	PlayerTextDrawAlignment(playerid, FPSPingPacket[playerid], 2);
	PlayerTextDrawColor(playerid, FPSPingPacket[playerid], -1);
	PlayerTextDrawSetShadow(playerid, FPSPingPacket[playerid], 0);
	PlayerTextDrawSetOutline(playerid, FPSPingPacket[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, FPSPingPacket[playerid], 32);
	PlayerTextDrawFont(playerid, FPSPingPacket[playerid], 1);
	PlayerTextDrawSetProportional(playerid, FPSPingPacket[playerid], 1);

	DeathInfo[0][playerid] = CreatePlayerTextDraw(playerid, 326.400146, 383.786285, "_");
	PlayerTextDrawLetterSize(playerid, DeathInfo[0][playerid], 0.280000, 1.000000);
	PlayerTextDrawAlignment(playerid, DeathInfo[0][playerid], 2);
	PlayerTextDrawColor(playerid, DeathInfo[0][playerid], -1);
	PlayerTextDrawSetShadow(playerid, DeathInfo[0][playerid], 0);
	PlayerTextDrawSetOutline(playerid, DeathInfo[0][playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, DeathInfo[0][playerid], 51);
	PlayerTextDrawFont(playerid, DeathInfo[0][playerid], 1);
	PlayerTextDrawSetProportional(playerid, DeathInfo[0][playerid], 1);

	DeathInfo[1][playerid] = CreatePlayerTextDraw(playerid, 326.000000, 400.000000, "_");
	PlayerTextDrawLetterSize(playerid, DeathInfo[1][playerid], 0.280000, 1.000000);
	PlayerTextDrawAlignment(playerid, DeathInfo[1][playerid], 2);
	PlayerTextDrawColor(playerid, DeathInfo[1][playerid], -1);
	PlayerTextDrawSetShadow(playerid, DeathInfo[1][playerid], 0);
	PlayerTextDrawSetOutline(playerid, DeathInfo[1][playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, DeathInfo[1][playerid], 51);
	PlayerTextDrawFont(playerid, DeathInfo[1][playerid], 1);
	PlayerTextDrawSetProportional(playerid, DeathInfo[1][playerid], 1);		


	InfoStats[playerid][0] = CreatePlayerTextDraw(playerid, 317.701721, 421.909545, "_");
	PlayerTextDrawLetterSize(playerid, InfoStats[playerid][0], 0.280000, 0.899999);
	PlayerTextDrawAlignment(playerid, InfoStats[playerid][0], 2);
	PlayerTextDrawColor(playerid, InfoStats[playerid][0], -1);
	PlayerTextDrawSetShadow(playerid, InfoStats[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, InfoStats[playerid][0], 1);
	PlayerTextDrawBackgroundColor(playerid, InfoStats[playerid][0], 80);
	PlayerTextDrawFont(playerid, InfoStats[playerid][0], 3);
	PlayerTextDrawSetProportional(playerid, InfoStats[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, InfoStats[playerid][0], 0);

	InfoStats[playerid][1] = CreatePlayerTextDraw(playerid, 2.900062, 430.539916, "_");
	PlayerTextDrawLetterSize(playerid, InfoStats[playerid][1], 0.250000, 0.850000);
	PlayerTextDrawAlignment(playerid, InfoStats[playerid][1], 1);
	PlayerTextDrawColor(playerid, InfoStats[playerid][1], -1);
	PlayerTextDrawSetShadow(playerid, InfoStats[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, InfoStats[playerid][1], 1);
	PlayerTextDrawBackgroundColor(playerid, InfoStats[playerid][1], 80);
	PlayerTextDrawFont(playerid, InfoStats[playerid][1], 3);
	PlayerTextDrawSetProportional(playerid, InfoStats[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, InfoStats[playerid][1], 0);

	GangInfo[playerid] = CreatePlayerTextDraw(playerid, 476.709930, 430.136047, "_");
	PlayerTextDrawLetterSize(playerid, GangInfo[playerid], 0.209999, 0.899999);
	PlayerTextDrawAlignment(playerid, GangInfo[playerid], 2);
	PlayerTextDrawColor(playerid, GangInfo[playerid], -1);
	PlayerTextDrawSetShadow(playerid, GangInfo[playerid], 0);
	PlayerTextDrawSetOutline(playerid, GangInfo[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, GangInfo[playerid], 80);
	PlayerTextDrawFont(playerid, GangInfo[playerid], 1);
	PlayerTextDrawSetProportional(playerid, GangInfo[playerid], 1);
	PlayerTextDrawSetShadow(playerid, GangInfo[playerid], 0);

	killsandexp[playerid][0] = CreatePlayerTextDraw(playerid, 320.399749, 92.933311, "Double_kill!");
	PlayerTextDrawLetterSize(playerid, killsandexp[playerid][0], 0.400000, 1.600000);
	PlayerTextDrawAlignment(playerid, killsandexp[playerid][0], 2);
	PlayerTextDrawColor(playerid, killsandexp[playerid][0], -1);
	PlayerTextDrawSetShadow(playerid, killsandexp[playerid][0], 1);
	PlayerTextDrawSetOutline(playerid, killsandexp[playerid][0], 0);
	PlayerTextDrawBackgroundColor(playerid, killsandexp[playerid][0], 100);
	PlayerTextDrawFont(playerid, killsandexp[playerid][0], 1);
	PlayerTextDrawSetProportional(playerid, killsandexp[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, killsandexp[playerid][0], 1);

	killsandexp[playerid][1] = CreatePlayerTextDraw(playerid, 317.599884, 77.900024, "+15_Exp!");
	PlayerTextDrawLetterSize(playerid, killsandexp[playerid][1], 0.287198, 1.107197);
	PlayerTextDrawAlignment(playerid, killsandexp[playerid][1], 2);
	PlayerTextDrawColor(playerid, killsandexp[playerid][1], -1);
	PlayerTextDrawSetShadow(playerid, killsandexp[playerid][1], 1);
	PlayerTextDrawSetOutline(playerid, killsandexp[playerid][1], 0);
	PlayerTextDrawBackgroundColor(playerid, killsandexp[playerid][1], 100);
	PlayerTextDrawFont(playerid, killsandexp[playerid][1], 1);
	PlayerTextDrawSetProportional(playerid, killsandexp[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, killsandexp[playerid][1], 1);	
}

forward RandomMessages();
public RandomMessages(){
    new randomMsg = random(sizeof(randomMessages));
    SendClientMessageToAll(-1, randomMessages[randomMsg]);
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
    if(GetTickCount() < GetPVarInt(playerid, "ChatTime")) { SendClientMessage(playerid, -1, ""COL_WHITE"[Ошибка] "COL_DEFAULT"Пожалуйста, подождите!"); return false; }
	SetPVarInt(playerid, "ChatTime", GetTickCount()+1000);
	if(GetPVarInt(playerid, "ReadyToDuel") == 2){
		SendClientMessage(playerid, 0xFFFFFFFF, "{C0C0C0} Вы играете с кем-то дуель.");
		return false;
	}
	if(GetPVarInt(playerid, "onafk") == 1 && strcmp(cmdtext, "afk", true)){
		SendClientMessage(playerid, 0xFFFFFFFF, "{C0C0C0} Вы находитесь в комнате отдыха.");
		SendClientMessage(playerid, 0xFFFFFFFF, "{C0C0C0} Используйте {3667E9}/afk{C0C0C0}, чтобы выйти.");
		return false;		
	}

	if(!IsPlayerSpawned(playerid))
	{
		SendClientMessage(playerid, -1, "[Ошибка]: {C0C0C0}Вы не заспавнены.");
		return false;
	}		
    return true;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
   	if(newkeys == 160 && (GetPlayerWeapon(playerid) == 0 || GetPlayerWeapon(playerid) == 1) && !IsPlayerInAnyVehicle(playerid)){
		ResyncPlayer(playerid);	
		return 1;
	} 	
	return true;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(success == 0)
	{
		SendClientMessage(playerid, 0xCE0000FF, "<< {FFFFFF}Неизвестная команда {CE0000}>>");
		return true;
	}
	return true;
}

stock GetClanColor(gangidd){
	new prof;
	if(zones[gangidd][Gangid] == -1) return prof = 0xB2ACAC65;
	if(GangsNew[zones[gangidd][Gangid]][Color] == -1) return prof = 0xB2ACAC65;
	switch(GangsNew[zones[gangidd][Gangid]][Color]){
		case 0: prof = 0xB2ACAC85;
		case 1: prof = 0x8B000085;
		case 2: prof = 0x00e60085;
		case 3: prof = 0x42AAFF85;
		case 4: prof = 0xFFFF0085;
		case 5: prof = 0xFF033E85;
		case 6: prof = 0x0000FF85;
		case 7: prof = 0xFFA50085;
		case 8: prof = 0x80808085;
		case 9: prof = 0x8B00FF85;
		case 10: prof = 0x964B0085;
	}
	return prof;
}

stock GetClanColorForPlayer(playerid){
	new prof;
	if(eUser[playerid][GangId] == 0) return prof = 0xB2ACAC65;
	if(GangsNew[eUser[playerid][GangId]-1][Color] == -1) return prof = 0xB2ACAC65;
	switch(GangsNew[eUser[playerid][GangId]-1][Color]){
		case 0: prof = 0xB2ACAC85;
		case 1: prof = 0x8B000085;
		case 2: prof = 0x00e60085;
		case 3: prof = 0x42AAFF85;
		case 4: prof = 0xFFFF0085;
		case 5: prof = 0xFF033E85;
		case 6: prof = 0x0000FF85;
		case 7: prof = 0xFFA50085;
		case 8: prof = 0x80808085;
		case 9: prof = 0x8B00FF85;
		case 10: prof = 0x964B0085;
	}
	return prof;
}

/*public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(clickedid == RequestClass) {
    	Dialog_Show(playerid, DIALOG_CHANGE, DIALOG_STYLE_LIST, "Выбор оружия", "1 слот\n2 слот\n3 слот\n4 слот", "Выбрать", "Закрыть");
    }	
    return 1;
}*/