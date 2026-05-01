extends Node

signal council_called(resolution: Dictionary)
signal council_resolved(resolution: Dictionary, passed: bool, yes_pct: float)

var _next_meeting: int = 180
var _res_idx:      int = 0
var _pending:      Dictionary = {}

const RESOLUTIONS := [
	{
		"id": "carbon_tax",
		"title": "Global Carbon Emissions Tax",
		"body": "The Council votes on a binding carbon levy applied to all energy production and heavy "
			+ "industry. The mechanism forces an immediate repricing of fossil fuel assets worldwide. "
			+ "Coal, oil, and gas companies face stranded-asset write-downs. There is no phase-in period — "
			+ "enforcement begins on passage.",
		"impact_label": "Energy sector  −25%",
		"impacts": [{"sector":"Energy","value":-0.25}],
		"yes_bias": 0.54,
	},
	{
		"id": "tech_subsidy",
		"title": "Global Technology Sovereignty Fund",
		"body": "A coordinated sovereign investment programme channels $2 trillion into domestic "
			+ "semiconductor, AI, and software industries across member states. Existing listed "
			+ "technology companies are the direct beneficiaries of procurement contracts and "
			+ "R&D subsidies that take effect immediately.",
		"impact_label": "Tech sector  +28%",
		"impacts": [{"sector":"Tech","value":0.28}],
		"yes_bias": 0.52,
	},
	{
		"id": "financial_regulation",
		"title": "International Banking Transparency Act",
		"body": "Every systemically important financial institution must disclose full derivatives "
			+ "exposure, off-balance-sheet vehicles, and cross-border capital flows within 30 days. "
			+ "Markets immediately reprice the hidden leverage. Several institutions are expected "
			+ "to require emergency recapitalisation.",
		"impact_label": "Finance sector  −22%",
		"impacts": [{"sector":"Finance","value":-0.22}],
		"yes_bias": 0.46,
	},
	{
		"id": "gold_standard",
		"title": "Emergency Return to Gold-Backed Reserves",
		"body": "Member central banks must accumulate gold to cover 20% of their monetary base within "
			+ "six months. The coordinated buying programme is the largest sovereign gold acquisition "
			+ "since Bretton Woods. Spot gold reprices violently as the announcement hits wire services.",
		"impact_label": "XAU  +35%",
		"impacts": [{"ticker":"XAU","value":0.35}],
		"yes_bias": 0.42,
	},
	{
		"id": "tech_monopoly",
		"title": "Digital Markets Antitrust Resolution",
		"body": "The Council mandates forced break-up of any digital platform with more than 30% "
			+ "market share in its category. Affected companies must divest core businesses within "
			+ "18 months. Legal costs, uncertainty, and structural destruction of value begin "
			+ "immediately on passage.",
		"impact_label": "Tech sector  −26%",
		"impacts": [{"sector":"Tech","value":-0.26}],
		"yes_bias": 0.48,
	},
	{
		"id": "oil_embargo",
		"title": "Coordinated Oil Supply Embargo",
		"body": "Major producer-member states agree to cut output by 30% indefinitely, citing "
			+ "geopolitical leverage. The supply shock is immediate. Tanker rates triple overnight. "
			+ "Energy companies holding existing reserves see their inventory revalued upward "
			+ "before trading even opens.",
		"impact_label": "Energy sector  +30%",
		"impacts": [{"sector":"Energy","value":0.30}],
		"yes_bias": 0.50,
	},
	{
		"id": "debt_jubilee",
		"title": "Global Sovereign Debt Jubilee",
		"body": "All sovereign debt issued before 2010 is declared void. Creditor nations and "
			+ "financial institutions holding this paper absorb losses immediately. "
			+ "No compensation mechanism exists. The banking sector faces a solvency crisis "
			+ "the moment the resolution passes.",
		"impact_label": "Finance sector  −30%",
		"impacts": [{"sector":"Finance","value":-0.30}],
		"yes_bias": 0.43,
	},
	{
		"id": "arms_nationalisation",
		"title": "Global Defence Industry Nationalisation",
		"body": "All private defense contractors operating in signatory states are to be nationalised "
			+ "at book value — a significant discount to market. Shareholders receive government bonds "
			+ "yielding below inflation. The technology sector, which supplies dual-use components, "
			+ "loses a major revenue stream overnight.",
		"impact_label": "Tech sector  −24%",
		"impacts": [{"sector":"Tech","value":-0.24}],
		"yes_bias": 0.38,
	},
	{
		"id": "silver_reserve",
		"title": "Industrial Silver Strategic Reserve Treaty",
		"body": "Member states commit to building a six-month strategic reserve of silver for critical "
			+ "industrial and medical applications. The combined purchase volume represents "
			+ "four times annual mining output. Physical silver is immediately unavailable "
			+ "at any previous price.",
		"impact_label": "XAG  +40%",
		"impacts": [{"ticker":"XAG","value":0.40}],
		"yes_bias": 0.47,
	},
	{
		"id": "financial_stimulus",
		"title": "Coordinated Global Quantitative Stimulus",
		"body": "Central banks across all member states simultaneously inject liquidity equivalent "
			+ "to 15% of GDP into financial markets. The transmission mechanism is direct — "
			+ "asset purchases begin within 72 hours of passage. Financial institutions are "
			+ "the primary and immediate beneficiaries.",
		"impact_label": "Finance sector  +25%",
		"impacts": [{"sector":"Finance","value":0.25}],
		"yes_bias": 0.55,
	},
	{
		"id": "energy_transition",
		"title": "Mandatory Fossil Fuel Phase-Out Declaration",
		"body": "All new fossil fuel extraction licences are void on passage. Existing operations "
			+ "face a hard closure deadline of three years with no compensation for stranded assets. "
			+ "The legal challenge will take a decade but the market reprices immediately: "
			+ "energy stocks collapse before the ink dries.",
		"impact_label": "Energy sector  −28%",
		"impacts": [{"sector":"Energy","value":-0.28}],
		"yes_bias": 0.51,
	},
	{
		"id": "wti_price_floor",
		"title": "Global Crude Oil Price Floor at $120/barrel",
		"body": "A binding floor price for crude oil trade between member states, enforced by "
			+ "export controls. Any state selling below the floor loses access to the Council's "
			+ "financial clearing infrastructure. WTI futures gap up the moment the vote result "
			+ "is read into the record.",
		"impact_label": "WTI  +32%",
		"impacts": [{"ticker":"WTI","value":0.32}],
		"yes_bias": 0.49,
	},
]

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)

func _on_day(_d: String) -> void:
	_next_meeting -= 1
	if _next_meeting <= 0:
		_next_meeting = 168 + randi() % 28
		_call_council()

func _call_council() -> void:
	var res = RESOLUTIONS[_res_idx % RESOLUTIONS.size()].duplicate(true)
	_res_idx += 1
	res["meeting_date"] = GameState.get_date_string()
	_pending = res
	emit_signal("council_called", res)

func get_player_vote_weight() -> float:
	if CountrySystem.owned.is_empty(): return 0.0
	var total_gdp := 0.0; var total_pop := 0.0
	for c in CountrySystem.COUNTRIES:
		total_gdp += float(c["gdp"]); total_pop += float(c["pop"])
	var w := 0.0
	for oid in CountrySystem.owned:
		var oc := CountrySystem.find_country(oid)
		if not oc.is_empty():
			w += 0.5 * (float(oc["gdp"]) / total_gdp) + 0.5 * (float(oc["pop"]) / total_pop)
	return clampf(w, 0.0, 1.0)

func vote(yes: bool) -> void:
	if _pending.is_empty(): return
	var res   := _pending
	_pending  = {}
	var player_w := get_player_vote_weight()
	var npc_w    := 1.0 - player_w
	var bias     = res.get("yes_bias", 0.5)
	var total_yes = npc_w * bias + (player_w if yes else 0.0)
	var total_no  = npc_w * (1.0 - bias) + (player_w if not yes else 0.0)
	var yes_pct   = total_yes / maxf(total_yes + total_no, 0.0001)
	var passed    = yes_pct >= 0.50
	if passed:
		for imp in res.get("impacts", []):
			if   imp.has("global"):  MarketEngine.apply_global_impact(imp["value"])
			elif imp.has("sector"):  MarketEngine.apply_sector_impact(imp["sector"], imp["value"])
			elif imp.has("ticker"):  MarketEngine.apply_event_impact(imp["ticker"], imp["value"])
	emit_signal("council_resolved", res, passed, yes_pct)

func abstain() -> void:
	if _pending.is_empty(): return
	var res   := _pending
	_pending  = {}
	var bias  = res.get("yes_bias", 0.5)
	var passed = bias >= 0.50
	if passed:
		for imp in res.get("impacts", []):
			if   imp.has("global"):  MarketEngine.apply_global_impact(imp["value"])
			elif imp.has("sector"):  MarketEngine.apply_sector_impact(imp["sector"], imp["value"])
			elif imp.has("ticker"):  MarketEngine.apply_event_impact(imp["ticker"], imp["value"])
	emit_signal("council_resolved", res, passed, bias)
