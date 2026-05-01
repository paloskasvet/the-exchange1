extends Node

signal news_published(article: Dictionary)
signal historical_event_triggered(event: Dictionary)

var news_queue:      Array = []
var _triggered_ids:  Array = []
var _pool_idx:       int   = 0

const HISTORICAL_EVENTS := [
	# ── 1929 ──────────────────────────────────────────────────────────────────
	{"id":"black_tuesday_1929","title":"Black Tuesday — The Crash That Changed Everything",
	 "title_tr":"Kara Salı — Her Şeyi Değiştiren Çöküş",
	 "year":1929,"month":10,"day":29,"category":"crash",
	 "body":"Thirteen million shares changed hands on the New York Stock Exchange in a single day. Brokers' phones rang without pause. Margin calls went unanswered. By the close, the market had lost $14 billion in a single session — more than the entire cost of World War One. Men wept on the trading floor. Some did not go home.",
	 "body_tr":"New York Borsası'nda tek bir günde on üç milyon hisse el değiştirdi. Komisyoncuların telefonları durmaksızın çaldı. Teminat talepleri yanıtsız kaldı. Kapanışa kadar piyasa tek bir seansta 14 milyar dolar kaybetti — Birinci Dünya Savaşı'nın toplam maliyetinden fazla. Adamlar işlem salonunda ağladı. Bir kısmı eve dönmedi.",
	 "impacts":[{"global":true,"value":-0.14},{"ticker":"GIDX","value":-0.16},{"sector":"Finance","value":-0.12}]},
	# ── 1944 ──────────────────────────────────────────────────────────────────
	{"id":"bretton_woods_1944","title":"Bretton Woods — The Dollar Becomes the World",
	 "title_tr":"Bretton Woods — Dolar Dünya Oldu",
	 "year":1944,"month":7,"day":22,"category":"macro",
	 "body":"Delegates from 44 nations convened at the Mount Washington Hotel in New Hampshire and redesigned the global financial system in three weeks. The US dollar, pegged to gold at $35 an ounce, became the reserve currency of the world. Every other currency would be fixed to it. The age of monetary sovereignty, for most nations, was over.",
	 "body_tr":"44 ülkeden delegeler New Hampshire'daki Mount Washington Oteli'nde toplandı ve üç haftada küresel finansal sistemi yeniden tasarladı. Ons başına 35 dolara altına sabitlenmiş ABD doları, dünyanın rezerv para birimi oldu. Diğer tüm para birimleri buna sabitlenecekti. Çoğu ulus için parasal egemenlik dönemi sona erdi.",
	 "impacts":[{"ticker":"XAU","value":0.04},{"ticker":"GIDX","value":0.03},{"sector":"Finance","value":0.05}]},
	# ── 1971 ──────────────────────────────────────────────────────────────────
	{"id":"nixon_shock_1971","title":"Nixon Shock — The Gold Window Closes Forever",
	 "title_tr":"Nixon Şoku — Altın Penceresi Sonsuza Dek Kapandı",
	 "year":1971,"month":8,"day":15,"category":"macro",
	 "body":"In a Sunday night television address, President Nixon announced that the United States would no longer convert dollars to gold. The Bretton Woods system, which had governed global finance for 27 years, ended in fifteen minutes of prime-time television. By Monday morning, currency traders didn't know what anything was worth. Some still aren't sure.",
	 "body_tr":"Pazar gecesi bir televizyon konuşmasında Nixon, ABD'nin artık doları altına çevirmeyeceğini duyurdu. 27 yıl boyunca küresel finansı yöneten Bretton Woods sistemi, on beş dakikalık prime-time televizyon yayınında sona erdi. Pazartesi sabahı, döviz tüccarları hiçbir şeyin değerini bilmiyordu. Bazıları hâlâ bilmiyor.",
	 "impacts":[{"ticker":"XAU","value":0.12},{"ticker":"XAG","value":0.08},{"global":true,"value":-0.04}]},
	# ── 1973 ──────────────────────────────────────────────────────────────────
	{"id":"opec_1973","title":"The Lights Go Out — OPEC Cuts the Tap",
	 "title_tr":"Işıklar Söndü — OPEC Musluğu Kapattı",
	 "year":1973,"month":10,"day":17,"category":"energy",
	 "body":"Arab oil ministers gathered in a Vienna hotel room and, without ceremony, shut off the tap. By morning, gas stations across America had lines stretching six blocks. Oil had been $3 a barrel. Within weeks it was $12. Everything built on cheap energy suddenly had a price tag.",
	 "body_tr":"Arap petrol bakanları Viyana'da bir otel odasında toplandı ve törensel bir şey olmaksızın musluğu kapattı. Sabaha kadar Amerika'daki benzin istasyonlarında altı blok uzunluğunda kuyruklar oluştu. Petrol varil başına 3 dolardı. Haftalar içinde 12 dolara ulaştı. Ucuz enerji üzerine kurulu her şeyin aniden bir bedeli oldu.",
	 "impacts":[{"ticker":"WTI","value":0.15},{"ticker":"NTG","value":0.12},{"sector":"Energy","value":0.10},{"ticker":"XAU","value":0.05},{"sector":"Tech","value":-0.04}]},
	# ── 1987 ──────────────────────────────────────────────────────────────────
	{"id":"black_monday_1987","title":"Black Monday — The Machines Did It",
	 "title_tr":"Kara Pazartesi — Makineler Yaptı",
	 "year":1987,"month":10,"day":19,"category":"crash",
	 "body":"No single trigger. No news. The Dow simply fell 22.6% in a single afternoon. Portfolio insurance algorithms fed on each other's panic. By closing bell, half a trillion dollars existed only in memory. One trader later said: 'I watched $40 million disappear in eleven minutes and I couldn't stop it.'",
	 "body_tr":"Tek bir tetikleyici yoktu. Haber yoktu. Dow basitçe tek bir öğleden sonrada yüzde 22,6 düştü. Portföy sigortası algoritmaları birbirinin paniğini körükledi. Kapanış zilinde yarım trilyon dolar yalnızca anılarda yaşıyordu. Bir tüccar daha sonra şöyle dedi: '40 milyon doların on bir dakikada yok olduğunu izledim ve durduramadım.'",
	 "impacts":[{"global":true,"value":-0.08},{"ticker":"GIDX","value":-0.10},{"ticker":"TIDX","value":-0.13}]},
	# ── 1989 ──────────────────────────────────────────────────────────────────
	{"id":"berlin_wall_1989","title":"The Wall Falls — A New Europe Opens for Business",
	 "title_tr":"Duvar Yıkıldı — Yeni Bir Avrupa İş Dünyasına Açıldı",
	 "year":1989,"month":11,"day":9,"category":"macro",
	 "body":"East Germans climbed the Berlin Wall with hammers. By midnight, the checkpoint was open. Overnight, 300 million new consumers, workers and investors were released into the global economy. Western fund managers had been quietly positioning since August. By the next morning, those positions were worth significantly more.",
	 "body_tr":"Doğu Almanlar çekiçlerle Berlin Duvarı'na tırmandı. Gece yarısına kadar kontrol noktası açıktı. Bir gecede 300 milyon yeni tüketici, işçi ve yatırımcı küresel ekonomiye katıldı. Batılı fon yöneticileri Ağustos'tan bu yana sessiz sedasız pozisyon alıyordu. Ertesi sabah, bu pozisyonlar önemli ölçüde daha değerliydi.",
	 "impacts":[{"global":true,"value":0.05},{"sector":"Finance","value":0.07},{"ticker":"GIDX","value":0.06}]},
	# ── 1994 ──────────────────────────────────────────────────────────────────
	{"id":"tequila_1994","title":"The Tequila Crisis — Mexico's Peso Collapses Overnight",
	 "title_tr":"Tekila Krizi — Meksika Pezosu Bir Gecede Çöktü",
	 "year":1994,"month":12,"day":20,"category":"currency",
	 "body":"The Mexican government devalued the peso by 15% on a Tuesday. By Thursday, the devaluation had become a rout. Capital fled at a rate that surprised even the IMF. The peso lost half its value in two weeks. Within months, the contagion had spread to Argentina, Brazil, and beyond — demonstrating that in a globalised world, no crisis stays local.",
	 "body_tr":"Meksika hükümeti salı günü pezoyu yüzde 15 devalüe etti. Perşembeye kadar devalüasyon bir bozguna dönüştü. Sermaye, IMF'i bile şaşırtan bir hızla kaçtı. Pezo iki haftada değerinin yarısını yitirdi. Aylar içinde bulaşma Arjantin, Brezilya ve daha ötesine yayıldı; küreselleşmiş bir dünyada hiçbir krizin yerel kalmadığını kanıtladı.",
	 "impacts":[{"global":true,"value":-0.04},{"ticker":"XAU","value":0.04},{"sector":"Finance","value":-0.06}]},
	# ── 1997 ──────────────────────────────────────────────────────────────────
	{"id":"asian_crisis_1997","title":"Asian Tigers Bleed — The Currency Crisis Spreads",
	 "title_tr":"Asya Kaplanları Kanıyor — Döviz Krizi Yayılıyor",
	 "year":1997,"month":7,"day":2,"category":"currency",
	 "body":"Thailand unpegged the baht and the dominoes fell. Within weeks, Indonesia, South Korea, and Malaysia had lost 30 to 80 percent of their currency value. The IMF arrived with conditions. Factories closed. The 'Asian miracle' turned out to have been partly financed by short-term dollar debt that was never hedged. The bill came due all at once.",
	 "body_tr":"Tayland bahtın sabit kurunu terk etti ve domino taşları düştü. Haftalar içinde Endonezya, Güney Kore ve Malezya para birimlerinin yüzde 30 ila 80'ini kaybetti. IMF koşullarla birlikte geldi. Fabrikalar kapandı. 'Asya mucizesi'nin kısmen hiçbir zaman hedge edilmemiş kısa vadeli dolar borçlarıyla finanse edildiği ortaya çıktı. Fatura hepsine birden kesildi.",
	 "impacts":[{"global":true,"value":-0.05},{"sector":"Finance","value":-0.08},{"ticker":"XAU","value":0.05},{"ticker":"WTI","value":-0.04}]},
	# ── 1998 ──────────────────────────────────────────────────────────────────
	{"id":"ltcm_1998","title":"LTCM Collapses — Genius Was Not Enough",
	 "title_tr":"LTCM Çöktü — Deha Yeterli Değildi",
	 "year":1998,"month":9,"day":23,"category":"financial",
	 "body":"Long-Term Capital Management employed two Nobel laureates. They built models that said their risk was essentially zero. By September they had lost $4.6 billion and held positions so large that unwinding them would destabilise global markets. The Federal Reserve orchestrated a private sector bailout over a single weekend. The models had been wrong about one thing: other people.",
	 "body_tr":"Long-Term Capital Management iki Nobel ödüllü çalıştırıyordu. Risklerinin özünde sıfır olduğunu söyleyen modeller inşa ettiler. Eylül'e gelindiğinde 4,6 milyar dolar kaybetmişler ve tasfiye edilmesi küresel piyasaları istikrarsızlaştıracak kadar büyük pozisyonlar tutuyorlardı. Federal Reserve tek bir hafta sonunda özel sektör kurtarma operasyonunu yönetti. Modeller bir konuda yanılmıştı: diğer insanlar.",
	 "impacts":[{"global":true,"value":-0.05},{"sector":"Finance","value":-0.09},{"ticker":"XAU","value":0.06}]},
	# ── 2000 ──────────────────────────────────────────────────────────────────
	{"id":"dotcom_2000","title":"The Dream Dissolves — Tech Bubble Bursts",
	 "title_tr":"Hayal Dağıldı — Teknoloji Balonu Patladı",
	 "year":2000,"month":3,"day":10,"category":"bubble",
	 "body":"Pets.com spent $2.2 million on a Super Bowl ad. By November it was dead. Across the Valley, companies with no revenue, no customers, and no plan watched their valuations collapse. The NASDAQ lost 78% over 30 months. Everyone sat with $30 stocks now worth $0.80.",
	 "body_tr":"Pets.com Super Bowl reklamına 2,2 milyon dolar harcadı. Kasım'a kadar iflas etti. Vadisi'nin dört bir yanında geliri, müşterisi ve planı olmayan şirketler değerlemelerinin çöküşünü izledi. NASDAQ 30 ayda yüzde 78 kayıp yaşadı. Herkesin elinde şimdi 0,80 dolar değerinde olan 30 dolarlık hisseler kaldı.",
	 "impacts":[{"sector":"Tech","value":-0.11},{"ticker":"TIDX","value":-0.13},{"ticker":"XAU","value":0.05}]},
	# ── 2001 ──────────────────────────────────────────────────────────────────
	{"id":"nine_eleven_2001","title":"September 11 — Markets Close, the World Changes",
	 "title_tr":"11 Eylül — Piyasalar Kapandı, Dünya Değişti",
	 "year":2001,"month":9,"day":11,"category":"crisis",
	 "body":"The New York Stock Exchange did not open on September 11. It did not open for four days. When it did, the Dow fell 684 points on the first day — then the largest single-day point drop in its history. Airlines lost 40% in a week. Defence contractors gained. The world that existed on September 10 did not return.",
	 "body_tr":"New York Borsası 11 Eylül'de açılmadı. Dört gün boyunca açılmadı. Açıldığında Dow ilk gün 684 puan düştü — o güne kadar tarihinin en büyük tek günlük puan düşüşü. Havayolları bir haftada yüzde 40 kaybetti. Savunma müteahhitleri kazandı. 10 Eylül'de var olan dünya geri dönmedi.",
	 "impacts":[{"global":true,"value":-0.07},{"sector":"Finance","value":-0.06},{"ticker":"WTI","value":0.05},{"ticker":"XAU","value":0.07}]},
	# ── 2008 ──────────────────────────────────────────────────────────────────
	{"id":"gfc_2008","title":"The Floor Falls Out — Global Financial Crisis",
	 "title_tr":"Zemin Çöktü — Küresel Finansal Kriz",
	 "year":2008,"month":9,"day":15,"category":"financial",
	 "body":"Lehman Brothers filed for bankruptcy at 1:45 AM. By 9:30 AM, credit markets had frozen. Banks stopped trusting each other. Overnight lending seized. In London, one official admitted: 'We genuinely did not know if there would be ATM cash on Thursday.'",
	 "body_tr":"Lehman Brothers saat 01:45'te iflas başvurusunda bulundu. Sabah 09:30'a kadar kredi piyasaları donmuştu. Bankalar birbirine güvenmeyi bıraktı. Gecelik borç verme durdu. Londra'da bir yetkili şunu itiraf etti: 'Gerçekten Perşembe günü ATM'lerde nakit olup olmayacağını bilmiyorduk.'",
	 "impacts":[{"global":true,"value":-0.08},{"sector":"Finance","value":-0.14},{"ticker":"XAU","value":0.07}]},
	# ── 2010 ──────────────────────────────────────────────────────────────────
	{"id":"flash_crash_2010","title":"The Flash Crash — $1 Trillion Vanished in Minutes",
	 "title_tr":"Flaş Çöküş — Dakikalar İçinde 1 Trilyon Dolar Yok Oldu",
	 "year":2010,"month":5,"day":6,"category":"crash",
	 "body":"At 2:45 PM on a Thursday afternoon, the Dow Jones fell 1,000 points in ten minutes — then recovered almost entirely within the hour. Nobody knew why. Algorithmic trading systems had interacted in ways their designers had not anticipated. Procter & Gamble traded at one cent per share for a few seconds. Some trades were cancelled. Others were not. No one was in control.",
	 "body_tr":"Bir Perşembe öğleden sonrası saat 14:45'te Dow Jones on dakikada 1.000 puan düştü — ardından bir saat içinde neredeyse tamamen toparladı. Kimse nedenini bilmiyordu. Algoritmik ticaret sistemleri, tasarımcılarının öngörmediği biçimlerde etkileşime girmişti. Procter & Gamble birkaç saniyeliğine bir sent üzerinden işlem gördü. Bazı işlemler iptal edildi. Diğerleri edilmedi. Kimse kontrolde değildi.",
	 "impacts":[{"global":true,"value":-0.04},{"ticker":"GIDX","value":-0.06},{"ticker":"TIDX","value":-0.07}]},
	# ── 2015 ──────────────────────────────────────────────────────────────────
	{"id":"china_2015","title":"China's Black Monday — The Dragon Stumbles",
	 "title_tr":"Çin'in Kara Pazartesisi — Ejderha Tökezledi",
	 "year":2015,"month":8,"day":24,"category":"crash",
	 "body":"The Shanghai Composite had already fallen 30% over the summer when Beijing devalued the yuan. On August 24, global markets opened in freefall. The Dow lost 1,000 points in the opening minutes. China had been the engine of global growth for a decade. For a few hours, traders wondered if that engine had seized.",
	 "body_tr":"Pekin yuan'ı devalüe ettiğinde Şanghay Bileşik Endeksi yaz boyunca zaten yüzde 30 düşmüştü. 24 Ağustos'ta küresel piyasalar serbest düşüşe geçerek açıldı. Dow açılışın ilk dakikalarında 1.000 puan kaybetti. Çin on yıldır küresel büyümenin motoru olmuştu. Birkaç saatliğine tüccarlar bu motorun durup durmadığını merak etti.",
	 "impacts":[{"global":true,"value":-0.06},{"ticker":"WTI","value":-0.07},{"ticker":"GIDX","value":-0.05}]},
	# ── 2016 ──────────────────────────────────────────────────────────────────
	{"id":"brexit_2016","title":"Brexit — Britain Votes to Leave",
	 "title_tr":"Brexit — Britanya Ayrılmayı Seçti",
	 "year":2016,"month":6,"day":24,"category":"macro",
	 "body":"Polls had called it for Remain. Markets had priced in Remain. At 4 AM London time, the result was clear: Leave had won by 52% to 48%. The pound fell 10% in hours — its largest single-day fall since currency markets existed. The Prime Minister resigned by breakfast. Nobody had a plan for what came next.",
	 "body_tr":"Anketler Kalma'yı işaret ediyordu. Piyasalar Kalma'yı fiyatlamıştı. Londra saatiyle sabah 4'te sonuç netti: Ayrılma yüzde 52'ye karşı yüzde 48 oranında kazanmıştı. Sterlin saatler içinde yüzde 10 düştü — döviz piyasaları var olduğundan bu yana en büyük tek günlük düşüşü. Başbakan kahvaltıya kadar istifa etti. Sırada ne olacağına dair kimsenin bir planı yoktu.",
	 "impacts":[{"global":true,"value":-0.04},{"sector":"Finance","value":-0.07},{"ticker":"XAU","value":0.06}]},
	# ── 2020 ──────────────────────────────────────────────────────────────────
	{"id":"pandemic_2020","title":"The World Stops — Global Pandemic",
	 "title_tr":"Dünya Durdu — Küresel Pandemi",
	 "year":2020,"month":2,"day":24,"category":"pandemic",
	 "body":"Airlines cancelled every flight. The oil price went negative — traders paid people to take delivery because there was nowhere to store it. The S&P fell 34% in 33 days, the fastest crash ever. Then central banks printed trillions, and within 6 months markets were at all-time highs. Nobody quite understood what had happened.",
	 "body_tr":"Havayolları tüm uçuşları iptal etti. Petrol fiyatı negatife düştü — teslim alacak yer olmadığından tüccarlar insanlara teslim almaları için para ödedi. S&P 500, 33 günde yüzde 34 düştü; tarihin en hızlı çöküşü. Ardından merkez bankaları trilyonlarca para bastı ve 6 ay içinde piyasalar tüm zamanların en yüksek seviyesine ulaştı. Kimse tam olarak ne olduğunu anlayamadı.",
	 "impacts":[{"global":true,"value":-0.07},{"ticker":"WTI","value":-0.10},{"ticker":"XAU","value":0.06},{"sector":"Tech","value":0.04}]},
]

const NEWS_POOL := [
	{"t":"A tanker registered under a Liberian flag was intercepted in the Strait of Hormuz. No cargo manifest. The crew spoke no English. Oil traders are calling it 'interesting.' Everyone else is calling their brokers.",
	 "i":[{"ticker":"WTI","value":0.04},{"ticker":"NTG","value":0.02}],"cat":"energy"},
	{"t":"Chipex Semiconductor announced a $40 billion contract with unnamed government clients. The share price jumped 8% before the filing was even fully read. Defense? AI? Both? Nobody's saying.",
	 "i":[{"ticker":"CHPX","value":0.08},{"sector":"Tech","value":0.02}],"cat":"tech"},
	{"t":"Three pension funds simultaneously reduced their Electrovolt Motors exposure. The stock fell 6%. Someone had to know something.",
	 "i":[{"ticker":"ELVT","value":-0.06}],"cat":"insider"},
	{"t":"A Chilean mining union voted to strike. Silver supply from the Atacama basin — 11% of global output — will fall to near zero for 90 days. The market is pricing in 4% of that.",
	 "i":[{"ticker":"XAG","value":0.04},{"ticker":"XAU","value":0.02}],"cat":"commodity"},
	{"t":"The Fed chair spoke for 22 minutes. Used the phrase 'data dependent' nine times. The yield curve moved 3 basis points. Billions changed hands.",
	 "i":[{"sector":"Finance","value":-0.02},{"ticker":"XAU","value":0.015}],"cat":"macro"},
	{"t":"OmniSearch posted quarterly earnings. Revenue up 23%. The market had expected 22.8%. The stock climbed 5%. This is what passes for excitement.",
	 "i":[{"ticker":"OMNI","value":0.05}],"cat":"tech"},
	{"t":"Summit Capital's trading desk posted its best quarter since 2009. Volatility, they explained, is 'a product.' Their clients who lost money might describe it differently.",
	 "i":[{"ticker":"SMTC","value":0.04}],"cat":"finance"},
	{"t":"Gold crossed $2,000/oz at 3:17 AM London time. The reason given in trading notes: 'general uncertainty.' That is the most honest thing written in finance this year.",
	 "i":[{"ticker":"XAU","value":0.03},{"ticker":"XAG","value":0.015}],"cat":"commodity"},
	{"t":"Continental Banking set aside $4.2 billion for bad loan provisions. They called it 'prudent.' The analyst community called it 'alarming.' The share price called it a 6% drop.",
	 "i":[{"ticker":"CNBN","value":-0.05}],"cat":"finance"},
	{"t":"Silver is within 12% of its all-time resistance at $67/oz — a ceiling held since 1980. Technical traders are watching. Fundamentals suggest this time may be different.",
	 "i":[{"ticker":"XAG","value":0.012}],"cat":"commodity"},
	{"t":"A leaked internal memo from BlackPeak Investments shows they have been quietly accumulating Apricot Technologies stock for 14 months. The memo was leaked by someone who sold first.",
	 "i":[{"ticker":"APRI","value":0.05},{"ticker":"BLKP","value":0.02}],"cat":"insider"},
	{"t":"New US shale fields came online 60 days ahead of schedule. Oil analysts revised forecasts downward for the third time this year.",
	 "i":[{"ticker":"WTI","value":-0.03},{"ticker":"ATLS","value":-0.02}],"cat":"energy"},
	{"t":"The IMF revised global growth estimates downward again. The report was 340 pages long and could have been summarized as: worse than we thought, better than it might get.",
	 "i":[{"global":true,"value":-0.02}],"cat":"macro"},
	{"t":"Metaverse Corp's new headset shipped to reviewers. Early impressions: technically impressive. Socially uncomfortable. Not something you'd wear in public. Sales targets have been quietly revised.",
	 "i":[{"ticker":"MVRS","value":-0.04}],"cat":"tech"},
	{"t":"Central banks across 14 countries increased gold reserve allocations simultaneously. This has not happened in this coordinated fashion since 1971.",
	 "i":[{"ticker":"XAU","value":0.04}],"cat":"commodity"},
]

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)

func _on_day(_d: String) -> void:
	_check_historical()
	if GameState.total_days_passed % 3 == 0:
		_gen_news()

func _check_historical() -> void:
	for ev in HISTORICAL_EVENTS:
		if ev["id"] in _triggered_ids: continue
		if GameState.game_year == ev["year"] and GameState.game_month == ev["month"]:
			if not ev.has("day") or GameState.game_day >= ev["day"]:
				_trigger(ev)

func _trigger(ev: Dictionary) -> void:
	_triggered_ids.append(ev["id"])
	for imp in ev["impacts"]: _apply(imp)
	_publish({"headline":"⚡  "+ev["title"],"body":ev["body"],"cat":ev["category"],"crisis":true,"date":GameState.get_date_string()})
	emit_signal("historical_event_triggered", ev)

func _gen_news() -> void:
	var item = NEWS_POOL[_pool_idx % NEWS_POOL.size()]
	_pool_idx += 1
	for imp in item["i"]: _apply(imp)
	_publish({"headline":item["t"].substr(0,80)+"…","body":item["t"],"cat":item["cat"],"crisis":false,"date":GameState.get_date_string()})

func _apply(imp: Dictionary) -> void:
	if   imp.has("global"):  MarketEngine.apply_global_impact(imp["value"])
	elif imp.has("sector"):  MarketEngine.apply_sector_impact(imp["sector"], imp["value"])
	elif imp.has("ticker"):  MarketEngine.apply_event_impact(imp["ticker"],  imp["value"])

func _publish(article: Dictionary) -> void:
	news_queue.push_front(article)
	if news_queue.size() > 20: news_queue.pop_back()
	emit_signal("news_published", article)

func get_recent(count: int = 5) -> Array:
	return news_queue.slice(0, mini(count, news_queue.size()))
