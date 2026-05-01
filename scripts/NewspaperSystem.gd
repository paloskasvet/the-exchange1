extends Node

signal newspaper_ready(paper: Dictionary)

var _day_counter: int = 0
var _econ_idx:    int = 0
var _fill_idx:    int = 0

# ── Economic front-page stories ───────────────────────────────────────────────
const ECON_ARTICLES := [
	{
		"headline": "Pipeline Fracture Halts Central Asian Oil Flow",
		"tr_h":     "Boru Hattı Arızası Orta Asya Petrol Akışını Durdurdu",
		"body":     "A structural failure in the Caspian transit pipeline has interrupted roughly 800,000 barrels of daily crude output. Engineers estimate repairs will take six to ten weeks. Tanker brokers in Istanbul report booking rates tripling overnight as shippers scramble for alternative routes. The disruption arrives as global inventories were already running below seasonal averages.",
		"tr_b":     "Hazar transit boru hattındaki yapısal bir arıza günlük yaklaşık 800.000 varillik ham petrol üretimini kesintiye uğrattı. Mühendisler onarımların altı ila on hafta süreceğini tahmin ediyor. İstanbul'daki tanker brokerleri gece boyunca navlun ücretlerinin üç katına çıktığını bildiriyor. Bu aksaklık, küresel stokların mevsimsel ortalamaların altında seyrettiği bir döneme denk geldi.",
		"byline":   "BY JONATHAN BARWICK, ENERGY CORRESPONDENT",
		"impact_label": "WTI ↑",
		"impacts": [{"ticker":"WTI","value":0.06},{"ticker":"NTG","value":0.03},{"sector":"Energy","value":0.04}]
	},
	{
		"headline": "Three Central Banks Add Gold — No Statement Issued",
		"tr_h":     "Üç Merkez Bankası Altın Aldı — Açıklama Yapılmadı",
		"body":     "Reserve managers at institutions in Frankfurt, Singapore, and an unnamed sovereign fund increased gold allocations by a combined 340 tonnes in the past quarter. No press release was issued. The purchases emerged through BIS quarterly data released Friday morning. Analysts note this is the largest coordinated accumulation since 2010, and that the silence around it is itself a signal.",
		"tr_b":     "Frankfurt, Singapur ve adı açıklanmayan bir egemen fon bünyesindeki rezerv yöneticileri geçen çeyrekte toplam 340 ton altın alımı gerçekleştirdi. Hiçbir basın açıklaması yayımlanmadı. Alımlar Cuma sabahı yayımlanan BIS üç aylık verileriyle gün yüzüne çıktı. Analistler bunun 2010'dan bu yana görülen en büyük koordineli birikim olduğuna ve etrafındaki sessizliğin başlı başına bir sinyal olduğuna dikkat çekiyor.",
		"byline":   "BY SARAH KOENIG, COMMODITIES DESK",
		"impact_label": "XAU ↑",
		"impacts": [{"ticker":"XAU","value":0.05},{"ticker":"XAG","value":0.02}]
	},
	{
		"headline": "Senate Committee Calls Tech Giants to Testify — Again",
		"tr_h":     "Senato Komitesi Teknoloji Devlerini Yeniden İfadeye Çağırdı",
		"body":     "Four major technology companies have been subpoenaed to appear before the Commerce Committee following accusations of anti-competitive data practices. Legal experts say the hearings are unlikely to produce binding legislation before the next election cycle. Markets are less patient — the sector has absorbed $180 billion in paper losses since the announcement, with no clear floor established.",
		"tr_b":     "Dört büyük teknoloji şirketi rekabete aykırı veri uygulamaları iddialarının ardından Ticaret Komitesi'ne ifade vermeye çağrıldı. Hukuk uzmanları duruşmaların bir sonraki seçim döngüsünden önce bağlayıcı mevzuata dönüşmesinin pek mümkün olmadığını söylüyor. Piyasalar ise daha az sabırlı — açıklamanın ardından sektör net üzerinde 180 milyar dolarlık kayıpla karşı karşıya kaldı.",
		"byline":   "BY MARCUS WEBB, WASHINGTON BUREAU",
		"impact_label": "Tech ↓",
		"impacts": [{"sector":"Tech","value":-0.05},{"ticker":"OMNI","value":-0.04},{"ticker":"APRI","value":-0.03}]
	},
	{
		"headline": "Continental Credit Review Reveals Hidden Exposure",
		"tr_h":     "Continental Kredi İncelemesi Gizli Riski Gün Yüzüne Çıkardı",
		"body":     "A routine stress test conducted by European supervisors uncovered collateralised loan obligations at Continental Banking that were not fully reflected in public disclosures. The bank's internal risk committee has met four times this month. Senior management declined to comment. Traders who noticed the sudden increase in credit default swap premiums are now explaining to their compliance teams why they moved so quickly.",
		"tr_b":     "Avrupalı denetçiler tarafından yürütülen rutin bir stres testi, Continental Banking bünyesindeki teminatlı kredi yükümlülüklerinin kamuya açık bildirimlere tam yansıtılmadığını ortaya koydu. Bankanın iç risk komitesi bu ay dört kez toplandı. Üst yönetim yorum yapmaktan kaçındı. Kredi temerrüt swap primlerindeki ani yükselişi fark eden yatırımcılar şimdi uyum ekiplerine neden bu kadar hızlı hareket ettiklerini açıklamak zorunda kaldı.",
		"byline":   "BY ELENA PAPADOPOULOS, EUROPEAN MARKETS",
		"impact_label": "Finance ↓",
		"impacts": [{"sector":"Finance","value":-0.05},{"ticker":"CNBN","value":-0.06}]
	},
	{
		"headline": "Atacama Strike Enters Third Week — No Resolution in Sight",
		"tr_h":     "Atacama Grevi Üçüncü Haftasına Girdi — Çözüm Görünmüyor",
		"body":     "Chile's National Mining Federation confirmed this morning that 14,000 workers remain on strike across the Atacama basin. The union rejected the government's proposed arbitration framework, calling the wage offer 'an insult dressed in legal language.' Silver output from the region, which accounts for eleven percent of global supply, has fallen to near zero. Industrial buyers in Germany and South Korea are now paying significant spot premiums.",
		"tr_b":     "Şili Ulusal Madencilik Federasyonu bu sabah Atacama havzasındaki 14.000 işçinin greve devam ettiğini teyit etti. Sendika, hükümetin önerdiği tahkim çerçevesini 'hukuki dille giydirilmiş bir hakaret' olarak nitelendirerek reddetti. Küresel arzın yüzde on birini karşılayan bölgedeki gümüş üretimi sıfıra yaklaştı. Almanya ve Güney Kore'deki endüstriyel alıcılar önemli spot primler ödemek durumunda kaldı.",
		"byline":   "BY RICARDO SALINAS, LATIN AMERICA CORRESPONDENT",
		"impact_label": "XAG ↑",
		"impacts": [{"ticker":"XAG","value":0.06},{"ticker":"XAU","value":0.02}]
	},
	{
		"headline": "IMF Downgrades Global Forecast For Third Time This Year",
		"tr_h":     "IMF Bu Yıl Üçüncü Kez Küresel Tahminini Düşürdü",
		"body":     "The International Monetary Fund cut its world growth projection to 2.1 percent, the lowest estimate since the 2009 contraction. The report cited tightening credit conditions, elevated sovereign debt levels, and what the authors described as 'a structural deceleration in the economies that drove the previous expansion.' One deputy managing director noted the revision was made reluctantly, as though reluctance changes the arithmetic.",
		"tr_b":     "Uluslararası Para Fonu dünya büyüme tahminini 2009 daralmasından bu yana en düşük seviye olan yüzde 2,1'e indirdi. Raporda sıkılaşan kredi koşulları, yüksek kamu borç seviyeleri ve yazarların 'bir önceki genişlemeyi sürükleyen ekonomilerdeki yapısal yavaşlama' olarak tanımladığı durum gerekçe gösterildi. Bir direktör yardımcısı revizyonun isteksizce yapıldığını belirtti — sanki isteksizlik aritmetiği değiştirecekmiş gibi.",
		"byline":   "BY PRIYA MENON, ECONOMIC AFFAIRS",
		"impact_label": "Global ↓",
		"impacts": [{"global":true,"value":-0.04},{"ticker":"GIDX","value":-0.05}]
	},
	{
		"headline": "Chipex Wins Classified Contract — Value Undisclosed",
		"tr_h":     "Chipex Gizli Sözleşme Kazandı — Değer Açıklanmadı",
		"body":     "Chipex Semiconductor confirmed a multiyear supply agreement with government clients in a one-sentence filing posted at 11:58 PM on Friday. The contract value, the client, and the application were all listed as classified. Defense procurement specialists noting the filing number sequence estimate the contract exceeds $20 billion. The stock has already moved. Anyone who acted on the filing number alone made money by Saturday morning.",
		"tr_b":     "Chipex Semiconductor, Cuma gecesi 23:58'de tek cümlelik bir bildirimle devlet müşterileriyle çok yıllık tedarik anlaşması imzaladığını doğruladı. Sözleşmenin değeri, müşterisi ve uygulama alanı gizli olarak sınıflandırıldı. Dosyalama numarası sırasını inceleyen savunma tedarik uzmanları sözleşmenin 20 milyar doları aştığını tahmin ediyor. Hisse senedi zaten hareket etti. Yalnızca dosya numarasına dayanarak aksiyon alanlar Cumartesi sabahına kazanarak uyandı.",
		"byline":   "BY DAVID STRAUSS, TECHNOLOGY DESK",
		"impact_label": "CHPX ↑",
		"impacts": [{"ticker":"CHPX","value":0.07},{"sector":"Tech","value":0.02}]
	},
	{
		"headline": "Natural Gas Glut Pushes Prices to Four-Year Low",
		"tr_h":     "Doğalgaz Fazlası Fiyatları Dört Yılın En Düşük Seviyesine İtti",
		"body":     "Unusually warm weather across Europe and North America has left storage facilities at 96 percent capacity heading into spring. Producers in the Permian and North Sea have declined to curtail output, calculating that their competitors will blink first. The result is a price that covers operating costs for most but leaves no margin for debt service. Three smaller producers have already missed bond payments this quarter.",
		"tr_b":     "Avrupa ve Kuzey Amerika'da olağandışı ılıman hava, bahar girerken depolama tesislerini yüzde 96 kapasitede bıraktı. Perm Havzası ve Kuzey Denizi üreticileri rakiplerinin önce geri adım atacağı hesabıyla üretimi kısmayı reddetti. Sonuç, çoğu için işletme maliyetini karşılayan ancak borç servisine yer bırakmayan bir fiyat oldu. Üç küçük üretici bu çeyrekte tahvil ödemelerini kaçırdı.",
		"byline":   "BY CATHERINE DOYLE, ENERGY CORRESPONDENT",
		"impact_label": "NTG ↓",
		"impacts": [{"ticker":"NTG","value":-0.06},{"sector":"Energy","value":-0.03}]
	},
	{
		"headline": "BlackPeak Accumulation Confirmed — Markets Ask Why",
		"tr_h":     "BlackPeak Birikimi Teyit Edildi — Piyasalar Nedenini Soruyor",
		"body":     "Prime brokerage data published in a weekend financial review showed BlackPeak Investments has been acquiring large-cap financial sector equities for eleven consecutive weeks. The fund declined to comment. Competitors have spent the past 72 hours reconstructing the thesis. The leading theory involves a coordinated rate cut cycle timed to specific macro indicators. The secondary theory is that BlackPeak simply knows something the rest of the market does not.",
		"tr_b":     "Hafta sonu finans incelemesinde yayımlanan aracı kurum verileri, BlackPeak Investments'ın on bir ardışık haftadır büyük ölçekli finansal hisse senetleri topladığını gösterdi. Fon yorum yapmayı reddetti. Rakipler son 72 saatte tezi yeniden oluşturmaya çalıştı. Öne çıkan teori belirli makro göstergelere zamanlanmış koordineli bir faiz indirim döngüsünü kapsıyor. İkincil teori ise BlackPeak'in basitçe piyasanın geri kalanının bilmediği bir şeyi biliyor olduğu.",
		"byline":   "BY THOMAS RUBIN, MARKETS DESK",
		"impact_label": "Finance ↑",
		"impacts": [{"sector":"Finance","value":0.05},{"ticker":"BLKP","value":0.04},{"ticker":"SMTC","value":0.03}]
	},
	{
		"headline": "OPEC Meeting Ends Without Agreement — Third Consecutive Failure",
		"tr_h":     "OPEC Toplantısı Anlaşmasız Sona Erdi — Üçüncü Ardışık Başarısızlık",
		"body":     "Ministers left Vienna without issuing a joint communiqué for the third time in fourteen months. Two delegations did not attend the final session. A source inside the secretariat described the atmosphere as 'formally collegial and substantively hostile.' The production targets that held oil prices in a narrow band for two years are no longer being observed by at least four member states. The market is recalibrating what OPEC is worth without consensus.",
		"tr_b":     "Bakanlar on dört ay içinde üçüncü kez ortak bir bildiri yayımlamadan Viyana'dan ayrıldı. İki heyet son oturuma katılmadı. Sekretarya içindeki bir kaynağa göre atmosfer 'resmi anlamda nezaket içinde, esasen düşmancaydı.' İki yıl boyunca petrol fiyatlarını dar bir bantta tutan üretim hedefleri artık en az dört üye devlet tarafından uygulanmıyor. Piyasa mutabakat olmayan bir OPEC'in ne anlama geldiğini yeniden fiyatlıyor.",
		"byline":   "BY FARRUKH TASHKENTOV, VIENNA BUREAU",
		"impact_label": "WTI ↓",
		"impacts": [{"ticker":"WTI","value":-0.06},{"sector":"Energy","value":-0.04}]
	},
]

# ── Filler stories (2 per issue) ─────────────────────────────────────────────
const FILLER_ARTICLES := [
	{
		"headline": "Antarctic Team Uncovers 14,000-Year-Old Ice Formation",
		"tr_h":     "Antarktika Ekibi 14.000 Yıllık Buz Oluşumu Keşfetti",
		"body":     "A Norwegian-led research expedition drilling near the Weddell Sea has recovered an ice core containing air bubbles sealed before the last glacial maximum. The trapped atmosphere provides what scientists describe as 'a direct conversation with the ancient sky.' One researcher noted the carbon readings were unexpectedly high for the period — a finding that will take years to contextualize.",
		"tr_b":     "Weddell Denizi yakınlarında sondaj yapan Norveç liderliğindeki araştırma gezisi, son buzul döneminden önce kapatılmış hava kabarcıkları içeren bir buz özü kurtardı. Hapsolmuş atmosfer, bilim insanlarının 'antik gökyüzüyle doğrudan bir diyalog' olarak tanımladığı verileri barındırıyor. Bir araştırmacı dönem için beklenmedik derecede yüksek karbon okumalarına dikkat çekti — bağlamlandırılması yıllar alacak bir bulgu.",
		"byline":   "BY DR. LENA BRANDT, SCIENCE DESK"
	},
	{
		"headline": "World Chess Champion Refuses to Shake Hand — Committee Silent",
		"tr_h":     "Dünya Satranç Şampiyonu El Sıkışmayı Reddetti — Komite Sessiz Kaldı",
		"body":     "The reigning world chess champion declined to complete the post-match handshake in round seven of the Candidates Tournament, citing what he called 'deliberate psychological provocation during adjournment.' The arbiter reviewed footage for four hours and issued a statement describing the incident as 'within the parameters of acceptable competitive behaviour.' Nobody is satisfied.",
		"tr_b":     "Mevcut dünya satranç şampiyonu, erteleme sırasında 'kasıtlı psikolojik kışkırtma' gerekçesiyle Adaylar Turnuvası'nın yedinci turundaki maç sonu el sıkışmasını tamamlamayı reddetti. Hakem görüntüleri dört saat inceledi ve olayı 'kabul edilebilir rekabetçi davranış parametreleri dahilinde' olarak tanımlayan bir açıklama yayımladı. Kimse memnun değil.",
		"byline":   "BY PAVEL VORONOV, SPORT DESK"
	},
	{
		"headline": "Marathon Runner Breaks Record, Then Disqualified",
		"tr_h":     "Maraton Koşucusu Rekoru Kırdı, Sonra Diskalifiye Edildi",
		"body":     "Kenyan runner Amara Osei crossed the finish line in 2:00:47 — a world record by eleven seconds — before officials announced his race number had been attached upside down, rendering him unidentifiable on timing mats for a 400-metre segment. The governing body spent three days reviewing the footage before issuing a disqualification. The record does not stand. The footage does.",
		"tr_b":     "Kenyalı koşucu Amara Osei dünya rekoru kıran 2:00:47 ile finish çizgisini geçti — ardından yetkililer yarış numarasının ters takıldığını ve 400 metrelik bir bölümde zamanlama sensörlerinden tanımlanamaz hale geldiğini açıkladı. Yönetim kurulu görüntüleri üç gün inceledi ve diskalifiye kararı verdi. Rekor geçerli sayılmadı. Görüntüler hâlâ var.",
		"byline":   "BY AMELIA SUTHERLAND, SPORT DESK"
	},
	{
		"headline": "Volcanic Activity Near Iceland Shifts Atlantic Shipping Lanes",
		"tr_h":     "İzlanda Yakınındaki Volkanik Aktivite Atlantik Deniz Yollarını Değiştirdi",
		"body":     "A submarine eruption 80 kilometres west of the Reykjanes Peninsula has produced a new elevation on the ocean floor that disrupts a major shipping corridor. Vessels are adding between six and eleven hours to North Atlantic crossings. The Icelandic Meteorological Office says the eruption is ongoing and that forecasting its duration is 'not presently possible with available instruments.'",
		"tr_b":     "Reykjanes Yarımadası'nın 80 kilometre batısındaki bir sualtı patlaması büyük bir deniz taşımacılığı koridorunu etkileyen okyanus tabanında yeni bir yükselti oluşturdu. Gemiler Kuzey Atlantik geçişlerine altı ila on bir saat ekliyor. İzlanda Meteoroloji Ofisi patlamanın devam ettiğini ve süresinin tahmin edilmesinin 'mevcut araçlarla şu an mümkün olmadığını' açıkladı.",
		"byline":   "BY INGRID ÓLAFSDÓTTIR, NORDIC CORRESPONDENT"
	},
	{
		"headline": "104-Year-Old Wins Regional Chess Tournament, Plans Defence",
		"tr_h":     "104 Yaşındaki Bölgesel Satranç Turnuvasını Kazandı, Kupayı Savunmayı Planlıyor",
		"body":     "Retired schoolteacher Miriam Voss of Salzburg defeated fourteen opponents across two days to claim the Upper Austria Regional Chess Championship for players over 60. Asked how she plans to prepare for the national tournament in spring, she said she would spend the winter reviewing her mistakes and that she had 'enough time left for at least one more title.' Her nearest rival was 38 years her junior.",
		"tr_b":     "Salzburglu emekli öğretmen Miriam Voss iki gün boyunca on dört rakibini yenerek 60 yaş üstü Yukarı Avusturya Bölgesel Satranç Şampiyonluğu'nu kazandı. İlkbahardaki ulusal turnuvaya nasıl hazırlanacağı sorulduğunda hatalarını gözden geçirerek kışı geçireceğini ve 'en az bir şampiyonluk daha için yeterince zamanının olduğunu' söyledi. En yakın rakibi kendisinden 38 yaş küçüktü.",
		"byline":   "BY GERHARD KLEIST, EUROPEAN DESK"
	},
	{
		"headline": "Storm Damages Lighthouse — Keeper Refuses Evacuation",
		"tr_h":     "Fırtına Feneri Hasar Gördü — Bekçi Tahliyeyi Reddetti",
		"body":     "A Category 2 storm made landfall near Wick, Scotland early Thursday morning, damaging the Noss Head lighthouse's external staircase and taking out power for 14 hours. The keeper, who had served in the position for 31 years, declined the coast guard's offer of evacuation. 'The light stayed on,' he told a local reporter. 'That is the only relevant fact.'",
		"tr_b":     "Bir Kategori 2 fırtınası Perşembe sabahı erken saatlerde İskoçya'daki Wick yakınlarına vurunca Noss Head fenerinin dış merdiveni hasar gördü ve 14 saat elektrik kesildi. 31 yıldır bu görevi sürdüren bekçi sahil güvenliğin tahliye teklifini reddetti. 'Işık yandı,' dedi yerel bir muhabire. 'Tek ilgili gerçek bu.'",
		"byline":   "BY DUNCAN MACALLISTER, UK CORRESPONDENT"
	},
	{
		"headline": "Library Discovers 200-Year-Old Letter Inside Donated Book",
		"tr_h":     "Kütüphane Bağış Kitabında 200 Yıllık Mektup Buldu",
		"body":     "Staff at the Bruges Municipal Library found a sealed letter dated 1824 tucked inside the spine of a donated copy of 'Les Confessions.' The letter was addressed to a Flemish nobleman and describes, in detail, a land transaction that historians say may rewrite the documented ownership of a significant estate in Wallonia. Archivists are examining the wax seal. Lawyers have already been contacted.",
		"tr_b":     "Bruges Belediye Kütüphanesi personeli bağışlanan 'Les Confessions' nüshasının sırtına sıkıştırılmış 1824 tarihli kapalı bir mektup buldu. Mektup bir Flaman soylusuna hitaben yazılmış ve tarihçilerin Valondan önemli bir mülkün belgelenmiş sahipliğini yeniden yazabileceğini söylediği bir arazi işlemini ayrıntılı biçimde anlatıyor. Arşivciler mum mührünü inceliyor. Avukatlar zaten arandı.",
		"byline":   "BY SOFIE VERBEKE, CULTURAL AFFAIRS"
	},
	{
		"headline": "Town of 800 Elects Mayor by Coin Flip After Exact Tie",
		"tr_h":     "800 Kişilik Kasaba Tam Beraberlik Sonrası Para Atışıyla Başkan Seçti",
		"body":     "The village of Vrancea-Nouă in Romania held its third consecutive election after two candidates tied with 312 votes each. Electoral law permits a coin flip after a second tie. The winner, a retired agronomist, called it 'a legitimate democratic outcome.' His opponent, a veterinarian, said she would run again in four years. Both agreed the road to the river needed repair and that this had been true for twelve years.",
		"tr_b":     "Romanya'daki Vrancea-Nouă köyü iki adayın 312'şer oyla berabere kaldığı üçüncü ardışık seçimini gerçekleştirdi. Seçim yasası ikinci beraberliğin ardından para atışına izin veriyor. Emekli bir agronomist olan kazanan bunu 'meşru demokratik bir sonuç' olarak nitelendirdi. Veteriner olan rakibi dört yıl sonra yeniden aday olacağını söyledi. Her ikisi de nehre giden yolun onarım gerektirdiği ve bunun on iki yıldır böyle olduğu konusunda hemfikir.",
		"byline":   "BY FLORIN IONESCU, EASTERN EUROPE DESK"
	},
	{
		"headline": "Deep-Sea Probe Returns Images of Unknown Structure at 4,200 Metres",
		"tr_h":     "Sualtı Sondası 4.200 Metrede Bilinmeyen Yapıdan Görüntüler Getirdi",
		"body":     "A remotely operated vehicle deployed by the University of Lisbon returned footage of a geometric rock formation at 4,200 metres depth in the mid-Atlantic. Geologists do not currently agree on whether the formation is natural or modified. The footage has been shared with three independent teams. Two of them have changed their initial assessments after closer review. The third has not responded.",
		"tr_b":     "Lizbon Üniversitesi tarafından kullanılan uzaktan kumandalı bir araç, Orta Atlantik'te 4.200 metre derinlikte geometrik bir kaya oluşumunun görüntülerini çekti. Jeologlar oluşumun doğal mı yoksa değiştirilmiş mi olduğu konusunda henüz fikir birliğine varamıyor. Görüntüler üç bağımsız ekiple paylaşıldı. İkisi daha yakından incelemenin ardından ilk değerlendirmelerini değiştirdi. Üçüncüsü henüz yanıt vermedi.",
		"byline":   "BY PROF. ANA COSTA, SCIENCE CORRESPONDENT"
	},
	{
		"headline": "Fisherman Lands 580-Kilogram Bluefin Tuna Off Nova Scotia",
		"tr_h":     "Balıkçı Nova Scotia Açıklarında 580 Kilogramlık Orkinos Yakaladı",
		"body":     "A Nova Scotia fishing boat returned to Lunenburg Harbour Tuesday evening with a bluefin tuna weighing 580 kilograms — the largest recorded catch in the North Atlantic this decade. The fish took eight hours to land. The captain, who has fished the banks for 22 years, said he almost cut the line after hour four. The tuna sold at Tokyo's Toyosu market for a figure the buyer declined to disclose.",
		"tr_b":     "Nova Scotia'dan bir balıkçı teknesi Salı akşamı Lunenburg Limanı'na bu on yılda Kuzey Atlantik'teki en büyük av olan 580 kilogramlık bir orkinos balığıyla döndü. Balığı karmağa almak sekiz saat sürdü. 22 yıldır o sularda balık avlayan kaptan dördüncü saatte oltayı kesmeyi neredeyse düşündüğünü söyledi. Balık Tokyo'nun Toyosu pazarında alıcının açıklamayı reddettiği bir fiyata satıldı.",
		"byline":   "BY BRETT LANGFORD, NORTH AMERICA DESK"
	},
	{
		"headline": "Retired Professor Completes Self-Taught Law Degree at 79",
		"tr_h":     "Emekli Profesör 79 Yaşında Öğrendiği Hukukla Sınavı Geçti",
		"body":     "Dr. Henryk Woźniak, a retired physics professor from Kraków, passed the Polish bar examination on his second attempt, at the age of 79. He began studying law after a dispute with his landlord that his original lawyer, in his words, 'handled with impressive theoretical confidence and no practical competence.' He has no plans to practise. He won the landlord dispute.",
		"tr_b":     "Krakovlu emekli fizik profesörü Dr. Henryk Woźniak 79 yaşında ikinci denemesinde Polonya Barosu sınavını geçti. Hukuk okumaya kendi ifadesiyle 'etkileyici teorik özgüven ve hiç pratik yetenek olmaksızın yönetilen' bir ev sahibi anlaşmazlığının ardından başladı. Avukatlık yapmayı planlamıyor. Ev sahibi anlaşmazlığını kazandı.",
		"byline":   "BY JAN KRAWCZYK, CENTRAL EUROPE CORRESPONDENT"
	},
	{
		"headline": "Bridge Collapses During Maintenance — All Workers Evacuated in Time",
		"tr_h":     "Köprü Bakım Sırasında Çöktü — Tüm İşçiler Zamanında Tahliye Edildi",
		"body":     "A 90-year-old railway viaduct outside Lyon collapsed Tuesday morning during a scheduled concrete inspection. All eleven workers had been evacuated 25 minutes before the failure after a structural monitor triggered a preliminary alert. The bridge carried no traffic. An engineer on site said the early warning system 'did exactly what it was designed to do,' which he acknowledged was not always assumed to be true.",
		"tr_b":     "Lyon dışındaki 90 yıllık bir demiryolu viyadüğü Salı sabahı planlı beton incelemesi sırasında çöktü. Yapısal bir monitörün ön uyarı vermesinin ardından tüm on bir işçi çöküşten 25 dakika önce tahliye edilmişti. Köprüden herhangi bir trafik geçmiyordu. Olay yerindeki bir mühendis erken uyarı sisteminin 'tam olarak tasarlandığı gibi çalıştığını' belirtti ve bunun her zaman doğru kabul edilmediğini kabul etti.",
		"byline":   "BY NATHALIE ROUSSEAU, EUROPEAN AFFAIRS"
	},
	{
		"headline": "Pianist Gives Final Concert — Standing Ovation Lasts 14 Minutes",
		"tr_h":     "Piyanist Son Konserini Verdi — 14 Dakika Süren Ayakta Alkış",
		"body":     "Dame Yelena Marchetti, 81, performed at the Wiener Konzerthaus for what she has announced will be her final public recital. The programme consisted of Schubert's final three piano sonatas, performed without interval. The standing ovation at the end lasted 14 minutes by multiple audience members' accounts. She bowed once, then left. She did not return for an encore. She has never given one.",
		"tr_b":     "81 yaşındaki Dame Yelena Marchetti son kamu resitali olarak duyurduğu konseri Wiener Konzerthaus'ta verdi. Program aralıksız olarak Schubert'in son üç piyano sonatından oluşuyordu. Sonundaki ayakta alkış birden fazla seyircinin hesaplamasına göre 14 dakika sürdü. Bir kez eğildi, sonra ayrıldı. Tekrar sahneye çıkmadı. Hiç çıkmamıştı.",
		"byline":   "BY FELIX HARTMANN, ARTS & CULTURE"
	},
	{
		"headline": "Archaeologists Find Bronze Age Settlement Beneath Motorway",
		"tr_h":     "Arkeologlar Otoyol Altında Tunç Çağı Yerleşimi Buldu",
		"body":     "Emergency excavations triggered by roadwork near Thessaloniki have uncovered a Bronze Age settlement dated to approximately 1600 BCE — two centuries older than current estimates for urban development in the region. The finding requires revision of at least three textbook timelines. Road construction has been suspended indefinitely. The transport ministry has not commented on cost implications.",
		"tr_b":     "Selanik yakınlarındaki yol çalışmalarının tetiklediği acil kazılar, bölgedeki kentsel gelişime dair mevcut tahminlerden iki yüz yıl daha eski MÖ 1600'e tarihlenen bir Tunç Çağı yerleşimini ortaya çıkardı. Bulgu en az üç ders kitabının zaman çizelgesinin revize edilmesini gerektiriyor. Yol inşaatı süresiz askıya alındı. Ulaştırma bakanlığı maliyet etkilerine ilişkin yorum yapmadı.",
		"byline":   "BY KONSTANTINA ALEXIOU, MEDITERRANEAN DESK"
	},
	{
		"headline": "Mountain Climbers Find Pre-War Bunker at 3,800 Metres",
		"tr_h":     "Dağcılar 3.800 Metrede Savaş Öncesi Sığınak Buldu",
		"body":     "A Swiss-Austrian climbing team reached a previously undocumented concrete structure on the northeast face of the Großglockner at 3,800 metres elevation. Documents found inside suggest it was constructed between 1938 and 1941. Historians from two universities are travelling to the site. The climbers, who reported the find rather than removing anything, called it 'deeply strange' and requested their names not be published.",
		"tr_b":     "Bir İsviçre-Avusturya tırmanış ekibi Großglockner'ın kuzey doğu yüzünde 3.800 metre yükseklikte daha önce belgelenmemiş bir beton yapıya ulaştı. İçinde bulunan belgeler yapının 1938-1941 yılları arasında inşa edildiğine işaret ediyor. İki üniversiteden tarihçiler bölgeye hareket ediyor. Hiçbir şeyi yerinden almak yerine buluşu ihbar eden dağcılar olayı 'derinden tuhaf' olarak nitelendirdi ve adlarının yayımlanmamasını talep etti.",
		"byline":   "BY ANNELIESE FRÜHWALD, ALPINE CORRESPONDENT"
	},
	{
		"headline": "Children's Art Show Outsells Contemporary Gallery Next Door",
		"tr_h":     "Çocuk Sanat Sergisi Yanındaki Çağdaş Galeriyi Geride Bıraktı",
		"body":     "An exhibition of paintings by students aged 8 to 12 at the Reykjavik Community Centre generated €14,800 in sales over one weekend — €3,200 more than the concurrent adult exhibition at the adjoining gallery. The gallery director called the result 'philosophically interesting.' Several of the children's works were purchased by collectors who spent nothing at the adult show. The children were reportedly 'very pleased.'",
		"tr_b":     "8 ile 12 yaş arası öğrencilerin tablolarından oluşan sergi Reykjavik Toplum Merkezi'nde bir hafta sonunda 14.800 Euro satış gerçekleştirdi — yanındaki galerinin eş zamanlı yetişkin sergisinden 3.200 Euro fazla. Galeri müdürü sonucu 'felsefi açıdan ilgi çekici' olarak nitelendirdi. Yetişkin sergide hiçbir şey almayan bazı koleksiyoncular çocuk eserlerinden satın aldı. Çocuklar 'çok memnun' olduklarını söyledi.",
		"byline":   "BY SIGRÍÐUR EINARSDÓTTIR, NORDIC AFFAIRS"
	},
	{
		"headline": "Dog Competes in Regional Swimming Championship, Officials Divided",
		"tr_h":     "Köpek Bölgesel Yüzme Şampiyonasına Katıldı, Yetkililer İkiye Bölündü",
		"body":     "A Labrador named Ernst entered the open-water swimming competition at Lake Constance after escaping his owner's boat and joining the field of 340 registered competitors. He finished 23rd. Race officials disqualified him on grounds of 'non-human status' but noted that his technique was, in their words, 'efficient if unconventional.' His owner was fined for unsecured animals near an event perimeter. Ernst ate his disqualification notice.",
		"tr_b":     "Ernst adlı bir labrador sahibinin teknesinden kaçarak 340 kayıtlı yarışmacının olduğu alana katıldıktan sonra Constance Gölü'ndeki açık su yüzme yarışmasına girdi. 23. oldu. Yarış yetkilileri onu 'insan olmama' gerekçesiyle diskalifiye etti, ancak tekniğinin 'alışılmadık olsa da verimli' olduğunu belirtti. Sahibine etkinlik çevresi yakınında başıboş hayvan bulundurma nedeniyle para cezası kesildi. Ernst diskalifiye bildirimini yedi.",
		"byline":   "BY TOBIAS MÜHLBAUER, FEATURE DESK"
	},
	{
		"headline": "Small Submarine Discovers Pre-Columbian Artefacts in Yucatán Cenote",
		"tr_h":     "Küçük Denizaltı Yucatán Cenote'sinde Kolomb Öncesi Eserler Keşfetti",
		"body":     "A two-person research vessel operating in a flooded cave system near Tulum recovered ceramic fragments and a jade ornament dated to approximately 900 CE. The cenote had been mapped but not explored below 60 metres. Archaeologists are calling the find significant. Local authorities have restricted access pending a federal review. The research team is already preparing a second dive, pending permission they have not yet applied for.",
		"tr_b":     "Tulum yakınlarındaki su altındaki bir mağara sisteminde faaliyet gösteren iki kişilik araştırma aracı yaklaşık MS 900'e tarihlenen seramik parçaları ve bir yeşim taşı süsü buldu. Cenote haritalanmıştı ancak 60 metrenin altında keşfedilmemişti. Arkeologlar buluşu önemli olarak nitelendiriyor. Yerel yetkililer federal inceleme beklenirken erişimi kısıtladı. Araştırma ekibi henüz başvurmadıkları bir izin bekleyerek ikinci dalışa hazırlanıyor.",
		"byline":   "BY DR. CARLOS REYES, SCIENCE DESK"
	},
	{
		"headline": "Train Engineer Halts Coastal Express, Prevents Flood Disaster",
		"tr_h":     "Tren Makinisti Sahil Ekspresini Durdurdu, Sel Felaketini Önledi",
		"body":     "The driver of a passenger service between Genoa and La Spezia stopped his train 200 metres short of a flooded embankment Tuesday afternoon, preventing what transport officials called a near-certain derailment. The driver saw the water level from the cab and made the decision in under four seconds. He has driven the route for 19 years and said he 'just knew it wasn't right.' All 180 passengers evacuated by road. Service resumed the following morning.",
		"tr_b":     "Cenova-La Spezia arasında sefer yapan trenin sürücüsü Salı öğleden sonra taşan bir set yakınında 200 metre önce durdu; ulaştırma yetkilileri neredeyse kesin raydan çıkmayı böylece önledi. Sürücü su seviyesini kabinden gördü ve dört saniyeden kısa sürede karar verdi. Güzergahı 19 yıldır kullanan sürücü 'bir şeylerin yanlış olduğunu hissettim' dedi. 180 yolcunun tamamı karayoluyla tahliye edildi. Sefer ertesi sabah normale döndü.",
		"byline":   "BY GIULIA FERRARA, ITALIAN CORRESPONDENT"
	},
	{
		"headline": "Rare Bird Spotted 4,000 Kilometres From Its Known Range",
		"tr_h":     "Nadir Kuş Bilinen Yaşam Alanından 4.000 Kilometre Uzakta Görüldü",
		"body":     "Birdwatchers and ornithologists converged on a harbour in Tromsø this week after a confirmed sighting of a black-browed albatross — a species native to the South Atlantic — resting on a fishing boat's rigging. The bird remained for three days before departing northeast. Scientists cannot explain how it arrived. One researcher speculated the bird may have been following a vessel from southern waters without understanding it was doing so. The bird had no comment.",
		"tr_b":     "Bu hafta Tromsø'daki bir limanda Güney Atlantik'e özgü bir tür olan kara kaşlı albatroz bir balıkçı teknesinin donanımında dinlenirken görüldü; bu durum kuş gözlemcileri ve ornitologları bir araya getirdi. Kuş üç gün kaldıktan sonra kuzeydoğu yönünde ayrıldı. Bilim insanları kuşun nasıl geldiğini açıklayamıyor. Bir araştırmacı kuşun bunu anlamadan güney sularından bir gemiyi takip etmiş olabileceğini öne sürdü. Kuşun yorumu mevcut değil.",
		"byline":   "BY TORBJØRN HENRIKSEN, NORDIC SCIENCE"
	},
]

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)

func _on_day(_d: String) -> void:
	_day_counter += 1
	if _day_counter >= 60:
		_day_counter = 0
		_issue_paper()

func _issue_paper() -> void:
	if not EventScheduler.can_fire():
		_day_counter = 53  # retry in 7 days
		return
	EventScheduler.mark_fired()
	var lang := LocaleSystem.current_language
	var econ = ECON_ARTICLES[_econ_idx % ECON_ARTICLES.size()].duplicate(true)
	_econ_idx += 1
	if lang == "tr":
		econ["headline"] = econ.get("tr_h", econ["headline"])
		econ["body"]     = econ.get("tr_b", econ["body"])

	var f1 = FILLER_ARTICLES[_fill_idx % FILLER_ARTICLES.size()].duplicate(true)
	_fill_idx += 1
	var f2 = FILLER_ARTICLES[_fill_idx % FILLER_ARTICLES.size()].duplicate(true)
	_fill_idx += 1
	for fa in [f1, f2]:
		if lang == "tr":
			fa["headline"] = fa.get("tr_h", fa["headline"])
			fa["body"]     = fa.get("tr_b", fa["body"])

	# Apply economic impact when newspaper is issued
	for imp in econ.get("impacts", []):
		if   imp.has("global"):  MarketEngine.apply_global_impact(imp["value"])
		elif imp.has("sector"):  MarketEngine.apply_sector_impact(imp["sector"], imp["value"])
		elif imp.has("ticker"):  MarketEngine.apply_event_impact(imp["ticker"],  imp["value"])

	emit_signal("newspaper_ready", {
		"date":     GameState.get_date_string(),
		"articles": [econ, f1, f2]
	})
