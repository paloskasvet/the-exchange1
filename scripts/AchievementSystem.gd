extends Node

signal achievement_unlocked(ach: Dictionary)

const ACHIEVEMENTS := [
	{
		"id":"first_trade","icon":"📈",
		"name":"First Move","name_tr":"İlk Hamle",
		"desc":"Execute your first buy or sell order.",
		"desc_tr":"İlk alım veya satım emrini ver.",
		"type":"flag"
	},
	{
		"id":"millionaire","icon":"💵",
		"name":"Millionaire","name_tr":"Milyoner",
		"desc":"Reach a net worth of $1 million.",
		"desc_tr":"1 milyon dolar net değere ulaş.",
		"type":"net_worth","threshold":1_000_000
	},
	{
		"id":"centimillionaire","icon":"💰",
		"name":"The Inner Circle","name_tr":"Seçkin Çevre",
		"desc":"Reach a net worth of $100 million.",
		"desc_tr":"100 milyon dolar net değere ulaş.",
		"type":"net_worth","threshold":100_000_000,
		"newspaper":true,
		"news_headline":"Mystery Investor Enters the Centimillionaire Circle",
		"news_headline_tr":"Gizemli Yatırımcı Yüz Milyoner Çevresine Girdi",
		"news_body":"A figure known only by reputation has quietly crossed the $100 million threshold, according to sources close to several brokerage desks. The investment community has taken notice. 'Whoever this is,' said one analyst who declined to be named, 'they have been playing a very careful game for a very long time.' No comment has been issued. None is expected.",
		"news_body_tr":"Birçok aracı kurum kaynağına göre, yalnızca itibarıyla tanınan bir isim sessiz sedasız 100 milyon dolar eşiğini geçti. Yatırım camiası bunu fark etmiş durumda. Adını açıklamak istemeyen bir analist şunları söyledi: 'Kim olursa olsun, çok uzun süredir son derece dikkatli bir oyun oynuyor.' Henüz herhangi bir açıklama yapılmadı. Yapılması da beklenmiyor."
	},
	{
		"id":"billionaire","icon":"🏦",
		"name":"Billionaire","name_tr":"Milyarder",
		"desc":"Reach a net worth of $1 billion.",
		"desc_tr":"1 milyar dolar net değere ulaş.",
		"type":"net_worth","threshold":1_000_000_000,
		"newspaper":true,
		"news_headline":"%s Steps Into the Billionaire Class",
		"news_headline_tr":"%s Milyarderler Sınıfına Adım Atıyor",
		"news_body":"%s, whose portfolio spans markets and assets across multiple continents, crossed the $1 billion mark this quarter. The wealth was not inherited. It was built, position by position, over years of calculated risk. 'I don't celebrate milestones,' the new billionaire reportedly said when reached for comment. 'I look at what comes next.'",
		"news_body_tr":"Portföyü birden fazla kıtada piyasaları ve varlıkları kapsayan %s, bu çeyrekte 1 milyar dolar sınırını aştı. Bu servet miras değildi. Yıllarca hesaplı riskler alınarak, pozisyon pozisyon inşa edildi. Yorum için ulaşıldığında yeni milyarderin şunu söylediği aktarıldı: 'Dönüm noktalarını kutlamam. Sıradakine bakarım.'"
	},
	{
		"id":"ten_billion","icon":"🌐",
		"name":"Top Tier","name_tr":"Zirve Kadrosu",
		"desc":"Reach a net worth of $10 billion.",
		"desc_tr":"10 milyar dolar net değere ulaş.",
		"type":"net_worth","threshold":10_000_000_000,
		"newspaper":true,
		"news_headline":"%s Joins the World's Wealthiest Elite",
		"news_headline_tr":"%s Dünyanın En Zenginleri Arasına Katıldı",
		"news_body":"With a net worth now exceeding $10 billion, %s has entered a tier occupied by fewer than one hundred people on Earth. Analysts who track ultra-high-net-worth individuals say the portfolio is unusually diversified — spanning decades of positions with no obvious thematic pattern. One fund manager put it bluntly: 'They see something the rest of us don't.'",
		"news_body_tr":"10 milyar doları aşan net değeriyle %s, yeryüzünde yüzden az kişinin bulunduğu bir kademeye girdi. Çok yüksek servet sahiplerini takip eden analistler, portföyün alışılmadık biçimde çeşitlendirildiğini söylüyor. Bir fon yöneticisi bunu açıkça ifade etti: 'Bizim göremediğimiz bir şeyi görüyorlar.'"
	},
	{
		"id":"hundred_billion","icon":"👑",
		"name":"Beyond Wealth","name_tr":"Servetin Ötesi",
		"desc":"Reach a net worth of $100 billion.",
		"desc_tr":"100 milyar dolar net değere ulaş.",
		"type":"net_worth","threshold":100_000_000_000,
		"newspaper":true,
		"news_headline":"The %s Empire: $100 Billion and Counting",
		"news_headline_tr":"%s İmparatorluğu: 100 Milyar Dolar ve Artmaya Devam",
		"news_body":"At this level, standard metrics of wealth become inadequate. %s controls assets that, if liquidated simultaneously, would move global markets. Governments have begun taking calls. Central banks monitor positions. 'This is no longer just a portfolio,' one senior economist said. 'It is a geopolitical variable.'",
		"news_body_tr":"Bu düzeyde standart servet ölçütleri yetersiz kalıyor. %s, aynı anda tasfiye edilseydi küresel piyasaları sarsacak varlıkları kontrol ediyor. Hükümetler aramaya başladı. Merkez bankaları pozisyonları izliyor. Kıdemli bir ekonomist şöyle dedi: 'Bu artık sadece bir portföy değil. Jeopolitik bir değişken.'"
	},
	{
		"id":"trillionaire","icon":"🚀",
		"name":"Trillionaire","name_tr":"Trilyoner",
		"desc":"Reach a net worth of $1 trillion.",
		"desc_tr":"1 trilyon dolar net değere ulaş.",
		"type":"net_worth","threshold":1_000_000_000_000,
		"newspaper":true,
		"news_headline":"History Made: %s Becomes the World's First Trillionaire",
		"news_headline_tr":"Tarih Yazıldı: %s Dünyanın İlk Trilyoneri Oldu",
		"news_body":"It has never happened before. No individual in recorded history has ever controlled $1 trillion in personal wealth — until today. %s has done what economists once called theoretically impossible. The IMF has convened an emergency working group. Three governments have issued formal statements. The phrase 'unprecedented' appeared in 47 separate news reports before noon.",
		"news_body_tr":"Bu daha önce hiç olmamıştı. Kayıtlı tarihte hiçbir birey 1 trilyon dolar kişisel servete sahip olmamıştı — ta ki bugüne kadar. %s, ekonomistlerin bir zamanlar teorik olarak imkânsız dediği şeyi başardı. IMF acil çalışma grubu topladı. Üç hükümet resmi açıklama yaptı. 'Emsalsiz' ifadesi öğleden önce 47 ayrı haber raporunda yer aldı."
	},
	{
		"id":"first_country","icon":"🌍",
		"name":"Expansionist","name_tr":"Genişlemeci",
		"desc":"Purchase your first country investment.",
		"desc_tr":"İlk ülke yatırımını gerçekleştir.",
		"type":"countries","threshold":1
	},
	{
		"id":"empire","icon":"🗺",
		"name":"Empire Builder","name_tr":"İmparatorluk Kurucusu",
		"desc":"Hold investments in 10 or more countries.",
		"desc_tr":"10 veya daha fazla ülkede yatırım tut.",
		"type":"countries","threshold":10
	},
	{
		"id":"tech_pioneer","icon":"🔬",
		"name":"Technologist","name_tr":"Teknoloji Öncüsü",
		"desc":"Purchase your first technology.",
		"desc_tr":"İlk teknolojiyi satın al.",
		"type":"techs","threshold":1
	},
	{
		"id":"tech_magnate","icon":"⚡",
		"name":"Tech Magnate","name_tr":"Teknoloji Magnası",
		"desc":"Own 8 or more technologies.",
		"desc_tr":"8 veya daha fazla teknolojiye sahip ol.",
		"type":"techs","threshold":8
	},
	{
		"id":"luxury_taste","icon":"💎",
		"name":"Connoisseur","name_tr":"Zevk Sahibi",
		"desc":"Acquire your first luxury item.",
		"desc_tr":"İlk lüks eşyayı edin.",
		"type":"luxury","threshold":1
	},
	{
		"id":"exchange_majority","icon":"🏢",
		"name":"Majority Holder","name_tr":"Çoğunluk Hissedarı",
		"desc":"Own more than 51%% of %s.",
		"desc_tr":"%s — yüzde 51'inden fazlasına sahip ol.",
		"type":"exchange_units","threshold":52
	},
	{
		"id":"exchange_full","icon":"🔑",
		"name":"%s Is Yours","name_tr":"%s Artık Senin",
		"desc":"Achieve 100%% ownership of %s.",
		"desc_tr":"%s — tam sahipliğe ulaş.",
		"type":"exchange_units","threshold":100
	},
	{
		"id":"survived_1929","icon":"📉",
		"name":"Black Tuesday Survivor","name_tr":"Kara Salı'dan Sağ Kurtulan",
		"desc":"Keep playing past the 1929 crash.",
		"desc_tr":"1929 çöküşünün ötesine geç.",
		"type":"year_reached","threshold":1930
	},
	{
		"id":"half_century","icon":"🕰",
		"name":"Half a Century","name_tr":"Yarım Asır",
		"desc":"Play through 50 years of market history.",
		"desc_tr":"50 yıllık piyasa tarihinden geç.",
		"type":"year_reached","threshold":1979
	},
]

var unlocked: Array = []

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)
	Portfolio.position_opened.connect(func(_a,_b,_c): _check_flag("first_trade"))

func _on_day(_d: String) -> void:
	_check_all()

func _check_all() -> void:
	for ach in ACHIEVEMENTS:
		if ach["id"] in unlocked: continue
		match ach.get("type",""):
			"net_worth":
				if GameState.get_net_worth() >= ach["threshold"]: _unlock(ach)
			"countries":
				if CountrySystem.owned.size() >= ach["threshold"]: _unlock(ach)
			"techs":
				if TechSystem.owned.size() >= ach["threshold"]: _unlock(ach)
			"luxury":
				if LuxurySystem.owned.size() >= ach["threshold"]: _unlock(ach)
			"exchange_units":
				if ShareholdingSystem.owned_units >= ach["threshold"]: _unlock(ach)
			"year_reached":
				if GameState.game_year >= ach["threshold"]: _unlock(ach)

func _check_flag(id: String) -> void:
	var ach := _find(id)
	if not ach.is_empty() and id not in unlocked: _unlock(ach)

func _unlock(ach: Dictionary) -> void:
	if ach["id"] in unlocked: return
	unlocked.append(ach["id"])
	emit_signal("achievement_unlocked", ach)

func _find(id: String) -> Dictionary:
	for a in ACHIEVEMENTS:
		if a["id"] == id: return a
	return {}

func get_count() -> int:
	return unlocked.size()
