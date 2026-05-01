extends Node

signal tech_purchased(tech: Dictionary)

# ── Tech tree — historically grounded, year-gated, prerequisite-chained ────────
const TECHS := [
	# ── 1930s ──────────────────────────────────────────────────────────────────
	{
		"id":"radio",       "icon":"📻", "year":1930, "price":800_000,         "income":8_000,
		"name":"Radio Broadcasting Network",
		"name_tr":"Radyo Yayın Ağı",
		"desc":"AM broadcast licences and a national transmitter network. Advertising pays by the hour.",
		"desc_tr":"AM yayın lisansları ve ulusal verici ağı. Reklam geliri saatlik akıyor.",
		"req":[]
	},
	{
		"id":"railroad",    "icon":"🚂", "year":1932, "price":2_000_000,       "income":20_000,
		"name":"Railroad Freight Company",
		"name_tr":"Demiryolu Nakliye Şirketi",
		"desc":"Long-haul freight contracts across the continent. Coal, steel, grain — all of it moves by rail.",
		"desc_tr":"Kıta genelinde uzun mesafe yük sözleşmeleri. Kömür, çelik, tahıl — hepsi raylarla taşınıyor.",
		"req":[]
	},
	# ── 1940s ──────────────────────────────────────────────────────────────────
	{
		"id":"steel_mill",  "icon":"🏭", "year":1940, "price":3_500_000,       "income":35_000,
		"name":"Steel Mill",
		"name_tr":"Çelik Fabrikası",
		"desc":"Blast furnace complex supplying construction and manufacturing industries.",
		"desc_tr":"İnşaat ve imalat sektörüne hammadde sağlayan yüksek fırın kompleksi.",
		"req":["railroad"]
	},
	{
		"id":"petrochemical","icon":"⚗", "year":1945, "price":4_500_000,       "income":45_000,
		"name":"Petrochemical Plant",
		"name_tr":"Petrokimya Tesisi",
		"desc":"Synthetic rubber, plastics and fuel additives. Post-war demand is insatiable.",
		"desc_tr":"Sentetik kauçuk, plastik ve yakıt katkı maddeleri. Savaş sonrası talep doymuyor.",
		"req":[]
	},
	# ── 1950s ──────────────────────────────────────────────────────────────────
	{
		"id":"tv",          "icon":"📺", "year":1950, "price":5_000_000,       "income":50_000,
		"name":"Television Broadcasting",
		"name_tr":"Televizyon Yayıncılığı",
		"desc":"Broadcast network licence and transmission towers across the nation.",
		"desc_tr":"Ulusal yayın lisansı ve verici ağı. Reklam geliri günlük akıyor.",
		"req":[]
	},
	{
		"id":"aviation",    "icon":"✈",  "year":1952, "price":8_000_000,       "income":80_000,
		"name":"Commercial Aviation",
		"name_tr":"Ticari Havacılık",
		"desc":"Passenger airline routes and airport gate contracts.",
		"desc_tr":"Yolcu havayolu hatları ve havalimanı kapı sözleşmeleri.",
		"req":[]
	},
	# ── 1960s ──────────────────────────────────────────────────────────────────
	{
		"id":"mainframe",   "icon":"🖥",  "year":1961, "price":15_000_000,      "income":150_000,
		"name":"Mainframe Computers",
		"name_tr":"Ana Bilgisayarlar",
		"desc":"Enterprise batch-processing machines leased to governments and banks.",
		"desc_tr":"Hükümetlere ve bankalara kiralanan kurumsal toplu işlem makineleri.",
		"req":[]
	},
	{
		"id":"nuclear",     "icon":"⚛",  "year":1963, "price":30_000_000,      "income":300_000,
		"name":"Nuclear Power Plant",
		"name_tr":"Nükleer Santral",
		"desc":"Civilian fission reactor. Consistent baseload power sold to the grid.",
		"desc_tr":"Sivil fisyon reaktörü. Şebekeye satılan kesintisiz baz yük gücü.",
		"req":[]
	},
	{
		"id":"satellite",   "icon":"🛰",  "year":1965, "price":22_000_000,      "income":220_000,
		"name":"Satellite Communications",
		"name_tr":"Uydu İletişimi",
		"desc":"Geostationary relay satellites leased to broadcasters and militaries.",
		"desc_tr":"Yayıncılara ve orduya kiralanan jeosenkron röle uyduları.",
		"req":["tv"]
	},
	# ── 1970s ──────────────────────────────────────────────────────────────────
	{
		"id":"cable_tv",    "icon":"📡",  "year":1972, "price":18_000_000,      "income":280_000,
		"name":"Cable Television Network",
		"name_tr":"Kablolu Televizyon Ağı",
		"desc":"Coaxial distribution to homes. Monthly subscription revenue.",
		"desc_tr":"Evlere koaksiyel dağıtım. Aylık abonelik geliri.",
		"req":["tv"]
	},
	{
		"id":"microchip",   "icon":"💾",  "year":1974, "price":40_000_000,      "income":500_000,
		"name":"Microchip Factory",
		"name_tr":"Mikro Çip Fabrikası",
		"desc":"Integrated circuit production lines. Every device needs chips.",
		"desc_tr":"Entegre devre üretim hatları. Her cihaz çip gerektirir.",
		"req":["mainframe"]
	},
	{
		"id":"oil_refinery", "icon":"🛢", "year":1973, "price":45_000_000,      "income":550_000,
		"name":"Oil Refinery",
		"name_tr":"Petrol Rafinerisi",
		"desc":"Crude-to-product processing capacity with pipeline access.",
		"desc_tr":"Boru hattı erişimli ham petrolü ürüne dönüştürme kapasitesi.",
		"req":[]
	},
	# ── 1980s ──────────────────────────────────────────────────────────────────
	{
		"id":"pc",          "icon":"💻",  "year":1981, "price":28_000_000,      "income":420_000,
		"name":"Personal Computer Manufacturer",
		"name_tr":"Kişisel Bilgisayar Üreticisi",
		"desc":"Desktop and later laptop lines sold through retail and corporate.",
		"desc_tr":"Perakende ve kurumsal kanallardan satılan masaüstü ve laptop serileri.",
		"req":["microchip"]
	},
	{
		"id":"mobile_net",  "icon":"📱",  "year":1984, "price":60_000_000,      "income":800_000,
		"name":"Mobile Phone Network",
		"name_tr":"Mobil Telefon Şebekesi",
		"desc":"First-generation cellular towers and handset distribution.",
		"desc_tr":"Birinci nesil baz istasyonları ve el cihazı dağıtımı.",
		"req":["satellite"]
	},
	{
		"id":"fiber",       "icon":"🔆",  "year":1988, "price":80_000_000,      "income":950_000,
		"name":"Fiber Optic Network",
		"name_tr":"Fiber Optik Ağ",
		"desc":"Long-haul fibre trunks leased to telecoms and ISPs.",
		"desc_tr":"Telekomünikasyon şirketlerine ve ISS'lere kiralanan uzun mesafe fiber omurgalar.",
		"req":["satellite"]
	},
	# ── 1990s ──────────────────────────────────────────────────────────────────
	{
		"id":"semiconductor","icon":"🔬", "year":1993, "price":140_000_000,     "income":2_000_000,
		"name":"Semiconductor Fabrication Plant",
		"name_tr":"Yarı İletken Fabrikası",
		"desc":"Photolithography fab producing logic and memory at scale.",
		"desc_tr":"Fotolitografi tesisi; mantık ve bellek üretimi büyük ölçekte.",
		"req":["microchip", "pc"]
	},
	{
		"id":"isp",         "icon":"🌐",  "year":1994, "price":90_000_000,      "income":1_300_000,
		"name":"Internet Service Provider",
		"name_tr":"İnternet Servis Sağlayıcı",
		"desc":"Dial-up and later broadband consumer internet access.",
		"desc_tr":"Çevirmeli ve ardından geniş bantlı tüketici internet erişimi.",
		"req":["fiber"]
	},
	{
		"id":"ecommerce",   "icon":"🛒",  "year":1996, "price":70_000_000,      "income":1_100_000,
		"name":"E-Commerce Platform",
		"name_tr":"E-Ticaret Platformu",
		"desc":"Online marketplace. Transaction fees on every sale.",
		"desc_tr":"Çevrimiçi pazar yeri. Her satıştan işlem ücreti.",
		"req":["isp"]
	},
	{
		"id":"sat_tv",      "icon":"🔭",  "year":1997, "price":110_000_000,     "income":1_600_000,
		"name":"Satellite TV Network",
		"name_tr":"Uydu TV Ağı",
		"desc":"Direct-broadcast satellite to 40 million dishes.",
		"desc_tr":"40 milyon çanak antene doğrudan yayın uydusu.",
		"req":["cable_tv", "satellite"]
	},
	# ── 2000s ──────────────────────────────────────────────────────────────────
	{
		"id":"social",      "icon":"👥",  "year":2004, "price":220_000_000,     "income":3_500_000,
		"name":"Social Media Platform",
		"name_tr":"Sosyal Medya Platformu",
		"desc":"User-generated content network monetised through targeted advertising.",
		"desc_tr":"Hedefli reklamcılıkla para kazandırılan kullanıcı içerik ağı.",
		"req":["isp"]
	},
	{
		"id":"smartphone",  "icon":"📲",  "year":2007, "price":350_000_000,     "income":5_500_000,
		"name":"Smartphone Manufacturer",
		"name_tr":"Akıllı Telefon Üreticisi",
		"desc":"Touchscreen handsets with app ecosystems and annual upgrade cycles.",
		"desc_tr":"Uygulama ekosistemi ve yıllık yükseltme döngüsüne sahip dokunmatik cihazlar.",
		"req":["mobile_net", "pc"]
	},
	{
		"id":"cloud",       "icon":"☁",  "year":2006, "price":280_000_000,     "income":4_500_000,
		"name":"Cloud Computing Services",
		"name_tr":"Bulut Bilişim Hizmetleri",
		"desc":"On-demand compute and storage billed by the second.",
		"desc_tr":"Saniye bazında faturalandırılan isteğe bağlı işlem ve depolama.",
		"req":["semiconductor", "isp"]
	},
	{
		"id":"renewable",   "icon":"🌱",  "year":2005, "price":160_000_000,     "income":2_400_000,
		"name":"Renewable Energy Farm",
		"name_tr":"Yenilenebilir Enerji Çiftliği",
		"desc":"Utility-scale solar and wind generation. Government subsidies included.",
		"desc_tr":"Kamu ölçeğinde güneş ve rüzgar enerjisi üretimi. Devlet teşvikleri dahil.",
		"req":["nuclear"]
	},
	# ── 2010s ──────────────────────────────────────────────────────────────────
	{
		"id":"ev",          "icon":"🚗",  "year":2010, "price":700_000_000,     "income":11_000_000,
		"name":"Electric Vehicle Factory",
		"name_tr":"Elektrikli Araç Fabrikası",
		"desc":"Battery-electric vehicles and charging infrastructure.",
		"desc_tr":"Pil elektrikli araçlar ve şarj altyapısı.",
		"req":["renewable", "semiconductor"]
	},
	{
		"id":"streaming",   "icon":"🎬",  "year":2011, "price":550_000_000,     "income":9_000_000,
		"name":"Streaming Platform",
		"name_tr":"Yayın Akışı Platformu",
		"desc":"On-demand video. 200 million subscribers at $15/month.",
		"desc_tr":"İsteğe bağlı video. 200 milyon abone, aylık 15 dolar.",
		"req":["social", "cloud"]
	},
	{
		"id":"drone",       "icon":"🚁",  "year":2013, "price":420_000_000,     "income":7_000_000,
		"name":"Drone Manufacturing",
		"name_tr":"İnsansız Hava Aracı Üretimi",
		"desc":"Commercial and military UAV production contracts.",
		"desc_tr":"Ticari ve askeri İHA üretim sözleşmeleri.",
		"req":["smartphone"]
	},
	{
		"id":"ai_lab",      "icon":"🤖",  "year":2016, "price":900_000_000,     "income":15_000_000,
		"name":"AI Research Laboratory",
		"name_tr":"Yapay Zeka Araştırma Laboratuvarı",
		"desc":"Foundation model development. Licenced to every industry.",
		"desc_tr":"Temel model geliştirme. Her sektöre lisanslı.",
		"req":["cloud", "semiconductor"]
	},
	{
		"id":"crypto",      "icon":"₿",  "year":2014, "price":480_000_000,     "income":7_500_000,
		"name":"Cryptocurrency Exchange",
		"name_tr":"Kripto Para Borsası",
		"desc":"Digital asset trading platform. 0.1% on every transaction.",
		"desc_tr":"Dijital varlık ticaret platformu. Her işlemden %0,1 komisyon.",
		"req":["cloud"]
	},
	# ── 2020s ──────────────────────────────────────────────────────────────────
	{
		"id":"biotech",     "icon":"🧬",  "year":2020, "price":2_200_000_000,   "income":35_000_000,
		"name":"Gene Therapy Laboratory",
		"name_tr":"Gen Terapisi Laboratuvarı",
		"desc":"CRISPR-based precision medicine. Licences worth billions per treatment.",
		"desc_tr":"CRISPR tabanlı hassas tıp. Tedavi başına milyar değerinde lisanslar.",
		"req":["ai_lab"]
	},
	{
		"id":"quantum",     "icon":"⚛",  "year":2022, "price":3_000_000_000,   "income":50_000_000,
		"name":"Quantum Computing Lab",
		"name_tr":"Kuantum Bilişim Laboratuvarı",
		"desc":"Superconducting qubit systems sold to governments and pharma.",
		"desc_tr":"Hükümetlere ve ilaç şirketlerine satılan süper iletken kubit sistemleri.",
		"req":["ai_lab", "semiconductor"]
	},
	{
		"id":"space",       "icon":"🚀",  "year":2023, "price":7_000_000_000,   "income":120_000_000,
		"name":"Space Tourism Company",
		"name_tr":"Uzay Turizm Şirketi",
		"desc":"Suborbital and orbital tourism. $450,000 a seat, fully booked.",
		"desc_tr":"Suborbit ve orbit turizmi. Koltuk başı 450.000 dolar, tamamen dolu.",
		"req":["drone", "renewable"]
	},
	{
		"id":"ai_farm",     "icon":"🏗",  "year":2023, "price":4_500_000_000,   "income":75_000_000,
		"name":"AI Compute Farm",
		"name_tr":"Yapay Zeka İşlem Çiftliği",
		"desc":"Tens of thousands of GPUs training foundation models. Every AI company pays to rent a slice.",
		"desc_tr":"Temel modelleri eğiten on binlerce GPU. Her yapay zeka şirketi dilim kiralamak için ödüyor.",
		"req":["ai_lab", "renewable"]
	},
	{
		"id":"fusion",      "icon":"🌟",  "year":2028, "price":18_000_000_000,  "income":350_000_000,
		"name":"Fusion Reactor",
		"name_tr":"Füzyon Reaktörü",
		"desc":"Commercial net-energy-gain fusion. Unlimited clean power.",
		"desc_tr":"Ticari net enerji kazançlı füzyon. Sınırsız temiz güç.",
		"req":["nuclear", "quantum"]
	},
	# ── 2040s ──────────────────────────────────────────────────────────────────
	{
		"id":"space_mining", "icon":"⛏", "year":2041, "price":45_000_000_000,  "income":900_000_000,
		"name":"Asteroid Mining Operation",
		"name_tr":"Asteroid Madenciliği Operasyonu",
		"desc":"Robotic fleets extracting platinum-group metals from near-Earth asteroids. One rock outweighs all Earth reserves.",
		"desc_tr":"Dünya'ya yakın asteroidlerden platin grubu metaller çıkaran robotik filolar. Bir kaya tüm Dünya rezervlerini geride bırakıyor.",
		"req":["space", "fusion"]
	},
]

var owned: Array = []
var _daily_income: float = 0.0

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)

func _on_day(_d: String) -> void:
	if _daily_income > 0.0:
		GameState.add_cash(_daily_income)

func buy(tech_id: String) -> bool:
	var t := _find(tech_id)
	if t.is_empty() or tech_id in owned: return false
	if GameState.game_year < t["year"]: return false
	for req in t["req"]:
		if req not in owned: return false
	if GameState.cash < t["price"]: return false
	GameState.add_cash(-t["price"])
	owned.append(tech_id)
	_recalc_income()
	emit_signal("tech_purchased", t)
	return true

func can_buy(tech_id: String) -> bool:
	var t := _find(tech_id)
	if t.is_empty() or tech_id in owned: return false
	if GameState.game_year < t["year"]: return false
	for req in t["req"]:
		if req not in owned: return false
	return true

func is_owned(tid: String) -> bool:
	return tid in owned

func get_total_daily_income() -> float:
	return _daily_income

func _recalc_income() -> void:
	_daily_income = 0.0
	for tid in owned:
		var t := _find(tid)
		if not t.is_empty():
			_daily_income += float(t["income"])

func _find(tid: String) -> Dictionary:
	for t in TECHS:
		if t["id"] == tid: return t
	return {}
