extends Node

signal call_received(tip: Dictionary)

var _day_counter: int = 0
var _pending:     Array = []
var _tip_pool:    Array = []

const CALLS := [
	{
		"voice":    "They're moving out of energy. All of it. By the end of the week. Don't ask how I know.",
		"voice_tr": "Enerjiden çıkıyorlar. Hepsinden. Bu hafta sonuna kadar. Nasıl bildiğimi sorma.",
		"true_prob": 0.70,
		"real_impacts":  [{"ticker":"WTI","value":-0.07},{"sector":"Energy","value":-0.04}],
		"false_impacts": []
	},
	{
		"voice":    "Someone moved three million units through a shell in Liechtenstein. CHPX. The filing won't surface for sixty days.",
		"voice_tr": "Biri Lihtenştayn'daki bir paravan şirket üzerinden üç milyon lot geçirdi. CHPX. Dosyalama altmış gün boyunca gün yüzüne çıkmaz.",
		"true_prob": 0.65,
		"real_impacts":  [{"ticker":"CHPX","value":0.08}],
		"false_impacts": [{"ticker":"CHPX","value":-0.03}]
	},
	{
		"voice":    "The gold figures they're publishing aren't the ones they actually have. Not even close.",
		"voice_tr": "Yayımladıkları altın rakamları ellerindekilerle örtüşmüyor. Yakın bile değil.",
		"true_prob": 0.60,
		"real_impacts":  [{"ticker":"XAU","value":0.06},{"ticker":"XAG","value":0.03}],
		"false_impacts": []
	},
	{
		"voice":    "Finance is going to get hit. Something was found in the audit. I can't say more than that.",
		"voice_tr": "Finans sektörü sert yiyecek. Denetimde bir şey bulundu. Bundan fazlasını söyleyemem.",
		"true_prob": 0.75,
		"real_impacts":  [{"sector":"Finance","value":-0.06},{"ticker":"CNBN","value":-0.05}],
		"false_impacts": []
	},
	{
		"voice":    "There's a buyer for PRMZ that hasn't surfaced yet. Institutional. The size would surprise you.",
		"voice_tr": "PRMZ için henüz ortaya çıkmamış bir alıcı var. Kurumsal. Büyüklüğü sizi şaşırtır.",
		"true_prob": 0.65,
		"real_impacts":  [{"ticker":"PRMZ","value":0.07}],
		"false_impacts": []
	},
	{
		"voice":    "The report has a different second page than the one they'll release to the public. A very different second page.",
		"voice_tr": "Raporun kamuoyuna açıklayacaklarından farklı bir ikinci sayfası var. Çok farklı bir ikinci sayfa.",
		"true_prob": 0.55,
		"real_impacts":  [{"global":true,"value":-0.05},{"ticker":"GIDX","value":-0.06}],
		"false_impacts": []
	},
	{
		"voice":    "OMNI's internal data was compromised four months ago. They've been sitting on it. Someone will force their hand.",
		"voice_tr": "OMNI'nin iç verileri dört ay önce ele geçirildi. Üzerinde oturdular. Biri onları açıklamak zorunda bırakacak.",
		"true_prob": 0.70,
		"real_impacts":  [{"ticker":"OMNI","value":-0.08},{"sector":"Tech","value":-0.03}],
		"false_impacts": []
	},
	{
		"voice":    "The silver strike ends this week. A deal was made yesterday — it just hasn't been announced yet.",
		"voice_tr": "Gümüş grevi bu hafta bitiyor. Dün bir anlaşma yapıldı — sadece henüz duyurulmadı.",
		"true_prob": 0.60,
		"real_impacts":  [{"ticker":"XAG","value":-0.05}],
		"false_impacts": [{"ticker":"XAG","value":0.03}]
	},
	{
		"voice":    "BLKP is about to make a move that will redraw the sector map. I've seen the paperwork. It's real.",
		"voice_tr": "BLKP sektör haritasını yeniden çizecek bir hamle yapmak üzere. Evrakları gördüm. Gerçek.",
		"true_prob": 0.65,
		"real_impacts":  [{"ticker":"BLKP","value":0.06},{"sector":"Finance","value":0.04}],
		"false_impacts": []
	},
	{
		"voice":    "There's a sovereign fund quietly liquidating WTI positions. Has been for three weeks. Nobody's noticed yet.",
		"voice_tr": "Sessizce WTI pozisyonlarını tasfiye eden bir egemen fon var. Üç haftadır yapıyor. Henüz kimse fark etmedi.",
		"true_prob": 0.70,
		"real_impacts":  [{"ticker":"WTI","value":-0.06}],
		"false_impacts": []
	},
	{
		"voice":    "SMTC won something. The kind of contract that doesn't get announced in a press release. Ever.",
		"voice_tr": "SMTC bir şey kazandı. Basın açıklamasında hiç duyurulmayan türden bir sözleşme.",
		"true_prob": 0.60,
		"real_impacts":  [{"ticker":"SMTC","value":0.07}],
		"false_impacts": []
	},
	{
		"voice":    "The numbers coming out of the northern corridor aren't real. There's a gap between what's reported and what's actually moving.",
		"voice_tr": "Kuzey koridorundan gelen rakamlar gerçek değil. Raporlananla gerçekte hareket eden arasında bir fark var.",
		"true_prob": 0.55,
		"real_impacts":  [{"ticker":"NTG","value":-0.05},{"global":true,"value":-0.03}],
		"false_impacts": []
	},
]

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)
	_tip_pool = range(CALLS.size())
	_tip_pool.shuffle()

func _on_day(_d: String) -> void:
	var still: Array = []
	for p in _pending:
		p["days_left"] -= 1
		if p["days_left"] <= 0:
			for imp in p["impacts"]:
				_apply_impact(imp)
		else:
			still.append(p)
	_pending = still

	_day_counter += 1
	if _day_counter >= 180:
		_day_counter = 0
		_trigger_call()

func _trigger_call() -> void:
	if not EventScheduler.can_fire():
		_day_counter = 173  # retry in 7 days
		return
	EventScheduler.mark_fired()
	if _tip_pool.is_empty():
		_tip_pool = range(CALLS.size())
		_tip_pool.shuffle()
	var idx: int = _tip_pool.pop_front()
	var tip: Dictionary = CALLS[idx].duplicate(true)
	emit_signal("call_received", tip)

	var impacts: Array
	if randf() < tip["true_prob"]:
		impacts = tip.get("real_impacts", [])
	else:
		impacts = tip.get("false_impacts", [])
	if not impacts.is_empty():
		_pending.append({"days_left": randi_range(7, 21), "impacts": impacts})

func _apply_impact(imp: Dictionary) -> void:
	if   imp.has("global"):  MarketEngine.apply_global_impact(imp["value"])
	elif imp.has("sector"):  MarketEngine.apply_sector_impact(imp["sector"], imp["value"])
	elif imp.has("ticker"):  MarketEngine.apply_event_impact(imp["ticker"],  imp["value"])
