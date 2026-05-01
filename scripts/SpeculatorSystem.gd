extends Node

signal speculator_arrived(offer: Dictionary)
signal tip_resolved(offer: Dictionary, was_correct: bool)

var _pending_tips: Array = []
var _next_visit:   int   = 20
var _tip_idx:      int   = 0

const SPECULATORS := [
	{"name":"A.R.","title":"Disgraced ex-analyst, Merrill Lynch","portrait":"🕵"},
	{"name":"Chen Wei","title":"Retired floor trader, Hong Kong","portrait":"📊"},
	{"name":"Margot D.","title":"Hedge fund dropout, Citadel","portrait":"💼"},
	{"name":"The Broker","title":"Identity unknown","portrait":"🎭"},
	{"name":"Viktor S.","title":"Former central banker, BIS","portrait":"🏦"},
	{"name":"Natasha K.","title":"Ex-intelligence analyst, now freelance","portrait":"👓"},
]

const TIPS := [
	{
		"action":"BUY", "ticker":"APRI",
		"hint": "It concerns a technology company awaiting a regulatory decision. The timing is what matters.",
		"hint_tr": "Düzenleyici bir karar bekleyen bir teknoloji şirketini ilgilendiriyor. Asıl mesele zamanlama.",
		"greeting": "Good afternoon. I hope you don't mind the unannounced visit — I asked the front desk not to call ahead. My name isn't important yet. What is important is that I spent twelve years as a technology sector analyst at Merrill Lynch before certain people decided my methods were inconvenient. Those methods are about to make someone a significant amount of money. I was told you're the type to move quickly and keep quiet. Is that still true?",
		"greeting_tr": "İyi öğleden sonralar. Önceden haber vermeden geldiğim için özür dilerim — resepsiyona aramamasını söyledim. Adım henüz önemli değil. Önemli olan şu: Merrill Lynch'te teknoloji sektörü analisti olarak on iki yıl çalıştım, ta ki bazı kişiler yöntemlerimin rahatsız edici olduğuna karar verene kadar. O yöntemler yakında birine ciddi para kazandıracak. Hızlı hareket edip sessiz kaldığınız söylendi. Hâlâ doğru mu bu?",
		"reason": "Apricot Technologies is clearing a regulatory review deliberately delayed for fourteen months. When it clears — and I've seen the internal correspondence — a defense contract follows. The number has nine figures. You have roughly four weeks before the announcement.",
		"reason_tr": "Apricot Technologies, on dört aydır kasıtlı olarak geciktirilen bir düzenleyici incelemeden geçmek üzere. İnceleme tamamlandığında — iç yazışmaları gördüm — bir savunma sözleşmesi geliyor. Rakamın dokuz hanesi var. Duyurudan önce yaklaşık dört haftanız var.",
		"outcome_win": "The Apricot contract was announced. The market moved exactly as I said it would. Consider this a first instalment of trust.",
		"outcome_win_tr": "Apricot sözleşmesi açıklandı. Piyasa tam dediğim gibi hareket etti. Bunu güvenin ilk taksidi olarak kabul edin.",
		"outcome_lose": "The deal was delayed again. These things happen in bureaucracy. My source was not wrong — the timing was.",
		"outcome_lose_tr": "Anlaşma yeniden ertelendi. Bürokraside böyle şeyler olur. Kaynağım yanılmadı — zamanlama sorunuydu."
	},
	{
		"action":"SELL","ticker":"ELVT",
		"hint": "It's about a vehicle manufacturer and an upcoming disclosure that analysts haven't seen yet.",
		"hint_tr": "Bir araç üreticisiyle ilgili — analistlerin henüz görmediği yaklaşan bir açıklama var.",
		"greeting": "I came in through the side entrance. I'd prefer you didn't log this meeting in any calendar. I worked twenty years on the floor in Hong Kong — I've watched more quarterly announcements than most people have had meals. I know what a company looks like three weeks before a bad number drops. Right now, I'm looking at one. I came to you specifically because you have the appetite to move quickly. Do you want to know which company?",
		"greeting_tr": "Yan kapıdan girdim. Bu toplantının hiçbir takvime kaydedilmemesini tercih ederim. Hong Kong'da yirmi yıl işlem masasında çalıştım — çoğu insanın yemek sayısından fazla çeyrek duyurusu izledim. Kötü bir rakamdan üç hafta önce şirketin nasıl göründüğünü bilirim. Şu an tam olarak böyle birine bakıyorum. Hızlı hareket edecek biri aradım, size geldim. Hangi şirket olduğunu öğrenmek ister misiniz?",
		"reason": "Electrovolt's delivery numbers for next quarter are being quietly revised downward. The official announcement comes in about a month. I've seen the draft. The gap between what analysts expect and what will be reported is embarrassing. Get out before the press release.",
		"reason_tr": "Electrovolt'un bir sonraki çeyrek teslimat rakamları sessiz sedasız aşağı revize ediliyor. Resmi duyuru yaklaşık bir ay içinde gelecek. Taslağı gördüm. Analistlerin beklediği ile raporlanacak arasındaki fark utanç verici. Basın açıklamasından önce çıkın.",
		"outcome_win": "Electrovolt's numbers came in exactly as I warned. You were on the right side of that trade.",
		"outcome_win_tr": "Electrovolt'un rakamları tam uyardığım gibi geldi. O işlemin doğru tarafındaydınız.",
		"outcome_lose": "They managed to paper over the shortfall somehow. It won't last. The underlying problem hasn't gone away.",
		"outcome_lose_tr": "Açığı bir şekilde örtmeyi başardılar. Uzun sürmez. Altta yatan sorun ortadan kalkmadı."
	},
	{
		"action":"BUY", "ticker":"XAU",
		"hint": "It concerns the gold market — movement at a sovereign level the public doesn't know about yet.",
		"hint_tr": "Altın piyasasıyla ilgili — kamuoyunun henüz bilmediği egemen düzeyde bir hareket.",
		"greeting": "I apologize for the hour — I landed from Frankfurt two hours ago and came here directly. What I'm about to share is not something I've told many people. It took me three weeks to decide whether to bring it to anyone at all. I have contacts inside central banking — not theoretical contacts, people who handle the paperwork. Something is moving in the gold market at a sovereign level that the public doesn't know about yet. Are you interested in hearing more?",
		"greeting_tr": "Bu saat için özür dilerim — Frankfurt'tan iki saat önce indim, doğruca buraya geldim. Paylaşacaklarım çok az kişiye anlattığım bir şey. Kimseyle paylaşıp paylaşmamaya karar vermek üç haftamı aldı. Merkez bankacılığının içinde bağlantılarım var — teorik değil, evrakları bizzat işleyen insanlar. Kamuoyunun henüz bilmediği egemen düzeyde altın piyasasında bir şeyler hareket ediyor. Daha fazla duymak ister misiniz?",
		"reason": "Three central banks — I will not name them — have been accumulating gold reserves for six weeks through intermediaries. The volumes are not small. When this surfaces publicly, every retail trader in the world follows. You want to be positioned before that happens, not after.",
		"reason_tr": "Üç merkez bankası — isimlerini vermeyeceğim — altı haftadır aracılar üzerinden altın rezervi biriktiriyor. Hacimler küçük değil. Bu kamuoyuna yansıdığında dünyanın her yerindeki bireysel yatırımcı peşinden gelir. Olmadan önce konumlanmak istiyorsunuz, sonra değil.",
		"outcome_win": "The central bank accumulation became public. Gold moved sharply. You were ahead of the crowd.",
		"outcome_win_tr": "Merkez bankası birikimi kamuoyuna sızdı. Altın sert yükseldi. Kitlenin önündeydınız.",
		"outcome_lose": "The accumulation continued without public disclosure. The move hasn't come yet — the position may still play out.",
		"outcome_lose_tr": "Birikim kamuoyuna açıklanmadan sürdü. Hareket henüz gelmedi — pozisyon hâlâ oynanıyor olabilir."
	},
	{
		"action":"BUY", "ticker":"XAG",
		"hint": "It's a commodity supply situation — silver. A physical disruption the market hasn't priced in.",
		"hint_tr": "Bir emtia arz durumu — gümüş. Piyasanın henüz fiyatlamadığı fiziksel bir aksaklık.",
		"greeting": "I'll be brief — I have other meetings today. I've been trading metals for fifteen years and I currently consult for mining groups in South America. I was in Santiago last week. What I witnessed at those union negotiations is not what the news is reporting. There's a very specific situation developing in Chilean silver supply that the market has almost entirely missed. If you have any interest in precious metals, you need to hear what I have to say.",
		"greeting_tr": "Kısa tutacağım — bugün başka toplantılarım var. On beş yıldır metal ticareti yapıyorum, şu an Güney Amerika'daki madencilik gruplarına danışmanlık veriyorum. Geçen hafta Santiago'daydım. O sendika müzakerelerinde tanık olduklarım haberlerde çıkanlardan çok farklı. Şili gümüş arzında piyasanın neredeyse tamamen kaçırdığı çok spesifik bir durum gelişiyor. Değerli metallere ilginiz varsa söyleyeceklerimi duymanız gerekiyor.",
		"reason": "The Chilean mining strike is about to escalate to government intervention. The union rejected the third offer. Silver supply from the Atacama — eleven percent of global output — goes to near zero for ninety days. The market has priced in four percent of this. The rest is upside. You have roughly a month before the escalation becomes public.",
		"reason_tr": "Şili madenci grevinin hükümet müdahalesine tırmanması an meselesi. Sendika üçüncü teklifi de reddetti. Atacama'dan gelen gümüş arzı — küresel üretimin yüzde on biri — doksan gün boyunca neredeyse sıfıra inecek. Piyasa bunun yalnızca yüzde dördünü fiyatladı. Geri kalanı yukarı potansiyel. Tırmanma kamuoyuna yansımadan önce yaklaşık bir ayınız var.",
		"outcome_win": "The Chilean strike escalated exactly as I described. Silver supply dropped and the price gap closed sharply in your favour.",
		"outcome_win_tr": "Şili grevi tam anlattığım gibi tırmandı. Gümüş arzı düştü, fiyat farkı keskin şekilde kapandı.",
		"outcome_lose": "The union accepted a late compromise. The disruption was smaller than expected. These negotiations are unpredictable.",
		"outcome_lose_tr": "Sendika geç bir uzlaşıyı kabul etti. Aksaklık beklenenden küçük kaldı. Bu müzakereler öngörülemez."
	},
	{
		"action":"SELL","ticker":"CNBN",
		"hint": "It concerns a financial institution — hidden exposure in their loan book that investors haven't been told about.",
		"hint_tr": "Bir finansal kurumla ilgili — kredi portföyündeki gizli maruziyet, yatırımcılara bildirilmemiş.",
		"greeting": "I need you to understand that coming here was not an easy decision. I held a senior position in the compliance department of a major European bank until eighteen months ago. I left on terms I'm not permitted to discuss. I have internal risk committee minutes describing a situation at a well-known financial institution that their investors have not been told about. I'm not selling copies. I'm sharing the implication, for a fee, with someone who can act on it quietly. Is that you?",
		"greeting_tr": "Buraya gelmenin kolay bir karar olmadığını anlamanızı istiyorum. On sekiz ay öncesine kadar büyük bir Avrupa bankasının uyum departmanında üst düzey pozisyondaydım. Ayrılış koşullarımı tartışmam yasak. Yatırımcılarına bilgi verilmemiş bilinen bir finansal kuruma dair iç risk komitesi tutanaklarına sahibim. Kopyaları satmıyorum. Sonucu, sessizce hareket edebilecek birine, bir ücret karşılığı paylaşıyorum. O kişi siz misiniz?",
		"reason": "Continental Banking's loan book has real estate exposure not being marked to market. The provisions they'll need to take are triple what the public filings suggest. Someone senior has already quietly reduced their personal position. You have about a month before the disclosures are forced.",
		"reason_tr": "Continental Banking'in kredi portföyünde piyasa değeriyle işaretlenmeyen gayrimenkul maruziyeti var. Almaları gereken karşılıklar kamuya açık dosyalamalardan üç kat fazla. Üst düzey biri kişisel pozisyonunu sessizce çoktan azalttı. Açıklamalar zorlanmadan önce yaklaşık bir ayınız var.",
		"outcome_win": "Continental's provisions were larger than the market expected. The share price adjusted accordingly. A clean call.",
		"outcome_win_tr": "Continental'ın karşılıkları piyasanın beklediğinden büyük geldi. Hisse fiyatı buna göre düzenlendi. Temiz bir tahmin.",
		"outcome_lose": "They found a way to delay the recognition. Accounting can defer reality — but not indefinitely.",
		"outcome_lose_tr": "Muhasebe ertelemesinin yolunu buldular. Muhasebe gerçeği erteleyebilir — ama sonsuza kadar değil."
	},
	{
		"action":"BUY", "ticker":"CHPX",
		"hint": "It's a classified government procurement — semiconductor sector. Not public, not even close.",
		"hint_tr": "Gizli bir devlet ihalesi — yarı iletken sektörü. Kamuoyuyla paylaşılmadı, yakın bile değil.",
		"greeting": "Sit down, please. I won't take long. I spent nine years as an intelligence analyst — you don't need to know for which government — and three years ago I transitioned to private consulting. My clients now are people who need to understand what governments are about to spend money on before the contracts become public. I have a current situation in the semiconductor sector. The buyer is defense. The value is substantial. The window to position is about four weeks. Do you want the details?",
		"greeting_tr": "Lütfen oturun. Uzun sürmeyecek. Dokuz yıl istihbarat analisti olarak çalıştım — hangi hükümet için olduğunu bilmenize gerek yok — üç yıl önce özel danışmanlığa geçtim. Müşterilerim artık hükümetlerin sözleşmeler kamuya açılmadan önce ne için para harcayacağını anlamaları gereken kişiler. Yarı iletken sektöründe güncel bir durumum var. Alıcı savunma. Değer büyük. Pozisyon için pencere yaklaşık dört hafta. Ayrıntıları ister misiniz?",
		"reason": "Chipex Semiconductor has been awarded a classified defense contract. I cannot tell you the programme or the agency. The contract value is enough to double their revenue for three fiscal years. The announcement comes through cleared channels this month. Nobody outside that building knows yet.",
		"reason_tr": "Chipex Semiconductor gizli bir savunma sözleşmesi aldı. Programı ya da ajansı söyleyemem. Sözleşme değeri üç mali yıl boyunca gelirlerini ikiye katlamaya yetecek büyüklükte. Duyuru bu ay gizli kanallardan geçiyor. O binadan başka kimse henüz bilmiyor.",
		"outcome_win": "The contract announcement came through a defence press release. Chipex moved sharply. My information was accurate.",
		"outcome_win_tr": "Sözleşme duyurusu bir savunma basın açıklamasıyla geldi. Chipex sert yükseldi. Bilgilerim doğruydu.",
		"outcome_lose": "The announcement was delayed by classification review. The contract is real — the timing was the problem.",
		"outcome_lose_tr": "Duyuru gizlilik incelemesiyle ertelendi. Sözleşme gerçek — sorun zamanlamaydı."
	},
	{
		"action":"SELL","ticker":"WTI",
		"hint": "It's about what's happening inside OPEC right now — production discipline and what's about to break.",
		"hint_tr": "OPEC'in şu an içinde bulunduğu durumla ilgili — üretim disiplini ve kırılmak üzere olan denge.",
		"greeting": "I've attended every OPEC ministerial since 1998. I know the dynamics of that room better than most delegates who sit in it. There is a fracture happening right now between member states that the official communiqués are completely concealing. I've spoken to contacts inside the Vienna secretariat in the past seventy-two hours. What I'm hearing is unambiguous. The production discipline holding this market up is about to break. The oil price does not reflect this yet. You have a window.",
		"greeting_tr": "1998'den bu yana her OPEC bakanlar toplantısına katıldım. O odanın dinamiklerini içinde oturan delegelerin çoğundan daha iyi biliyorum. Şu an resmi bildirgelerin tamamen gizlediği üye devletler arasında bir kırılma yaşanıyor. Son yetmiş iki saatte Viyana sekreterliğinin içindeki kişilerle görüştüm. Duyduklarım net. Bu piyasayı ayakta tutan üretim disiplini kırılmak üzere. Petrol fiyatı bunu henüz yansıtmıyor. Bir pencereniz var.",
		"reason": "Two members are already quietly exceeding their quotas. When the third breaks — my contact says weeks, not months — the coordinated response collapses. Oversupply hits the market and the price corrects sharply. Position yourself on the short side before the fracture becomes public.",
		"reason_tr": "İki üye ülke zaten sessizce kotalarını aşıyor. Üçüncüsü kırdığında — kaynağım haftalar içinde diyor, aylar değil — koordineli yanıt çöküyor. Aşırı arz piyasaya giriyor ve fiyat sert düzeltme yapıyor. Kırılma kamuoyuna yansımadan önce kısa tarafta konumlanın.",
		"outcome_win": "OPEC's production agreement broke down publicly. Oil moved exactly as I described. Oversupply will take months to absorb.",
		"outcome_win_tr": "OPEC'in üretim anlaşması kamuoyu önünde çöktü. Petrol tam anlattığım gibi hareket etti. Aşırı arzın emilmesi aylar alacak.",
		"outcome_lose": "Diplomatic pressure held the agreement together for now. These fractures have a way of recurring — this isn't over.",
		"outcome_lose_tr": "Diplomatik baskı anlaşmayı şimdilik bir arada tuttu. Bu kırılmaların tekrarlanma alışkanlığı var — bitmedi."
	},
	{
		"action":"BUY", "ticker":"PRMZ",
		"hint": "It concerns M&A activity — a pharmaceutical company with multiple parties circling simultaneously.",
		"hint_tr": "Birleşme ve satın alma faaliyetiyle ilgili — aynı anda birden fazla tarafın etrafını çevirdiği bir ilaç şirketi.",
		"greeting": "I'll be direct with you. I work in mergers advisory — I won't say where. I have visibility into conversations that happen before they become transactions. There is active acquisition interest in a specific pharmaceutical company right now from multiple parties simultaneously. I've seen term sheet language. Nobody has signed anything yet. But the fact that multiple bidders are circling at the same time tells you exactly where the price is going. Are you in a position to act on this before it's public?",
		"greeting_tr": "Doğrudan konuya geleceğim. Birleşme danışmanlığında çalışıyorum — nerede olduğunu söylemeyeceğim. İşlemlere dönmeden önceki görüşmelere erişimim var. Şu anda birden fazla tarafın aynı anda belirli bir ilaç şirketiyle aktif satın alma görüşmesi yürütüyor. Terim sayfası dilini gördüm. Henüz kimse bir şey imzalamadı. Ancak birden fazla alıcının aynı anda etrafını çeviriyor olması, fiyatın nereye gittiğini tam olarak söylüyor. Kamuoyuna çıkmadan önce harekete geçebilir misiniz?",
		"reason": "PharmaZ is on the short list of acquisition targets for at least two large pharmaceutical groups. The bidders are serious — I've seen the terms. At current prices, the premium required is still substantial. That gap is your opportunity. You have roughly a month before this surfaces.",
		"reason_tr": "PharmaZ, en az iki büyük ilaç grubunun satın alma kısa listesinde. Alıcılar ciddi — şartları gördüm. Mevcut fiyatlardan gereken prim hâlâ önemli. Bu fark sizin fırsatınız. Bu yüzeye çıkmadan önce yaklaşık bir ayınız var.",
		"outcome_win": "The acquisition bid emerged publicly. PharmaZ shareholders received a significant premium. You were positioned correctly.",
		"outcome_win_tr": "Satın alma teklifi kamuoyuna çıktı. PharmaZ hissedarları önemli bir prim aldı. Doğru konumlandınız.",
		"outcome_lose": "The bidders walked away from the regulatory risk. The conversation ended quietly — for now.",
		"outcome_lose_tr": "Alıcılar düzenleyici riskten çekindi. Görüşme sessizce sona erdi — şimdilik."
	},
	{
		"action":"SELL","ticker":"OMNI",
		"hint": "It involves a major tech company's legal exposure — an antitrust ruling their own lawyers aren't confident about.",
		"hint_tr": "Büyük bir teknoloji şirketinin hukuki maruziyetiyle ilgili — kendi avukatlarının dahi emin olmadığı bir antitröst kararı.",
		"greeting": "My name isn't relevant. What I can tell you is that I know someone who recently resigned from OmniSearch's legal counsel team — not because they were pushed out, but because they looked at what's coming and decided they didn't want their name on the filings. I've had two conversations with this person in the past week. The antitrust situation they're facing is substantially worse than what the company has communicated publicly. Their lawyers are preparing for a loss. Does that interest you?",
		"greeting_tr": "Adım önemli değil. Şunu söyleyebilirim: OmniSearch'ün hukuk müşavirlik ekibinden yakın zamanda istifa eden birini tanıyorum — dışarı itildikleri için değil, ne geleceğini görüp dosyalarda adlarının olmasını istemedikleri için. Bu kişiyle son bir hafta içinde iki görüşme yaptım. Kamuoyuna bildirilenle karşılaştırıldığında antitröst durumları önemli ölçüde daha kötü. Avukatları kaybı hazırlıyor. İlginizi çeker mi?",
		"reason": "OmniSearch's antitrust ruling is expected in about a month. Their own counsel has internally advised the outcome is likely adverse. The outside lawyers billed four hundred hours last month preparing a response — for a loss scenario, not a win. The lawyers always know first. Get short before the ruling comes down.",
		"reason_tr": "OmniSearch'ün antitröst kararı yaklaşık bir ay içinde bekleniyor. Kendi hukuk müşavirleri sonucun muhtemelen olumsuz olduğunu iç olarak belirtti. Dış avukatlar geçen ay bir yanıt hazırlamak için dört yüz saat faturaladı — kazanma değil, kaybetme senaryosu için. Avukatlar her zaman önce bilir. Karar açıklanmadan önce açığa gidin.",
		"outcome_win": "The antitrust ruling came in adverse. OmniSearch's legal exposure was confirmed. The market repriced accordingly.",
		"outcome_win_tr": "Antitröst kararı olumsuz geldi. OmniSearch'ün hukuki maruziyeti doğrulandı. Piyasa buna göre yeniden fiyatlandı.",
		"outcome_lose": "The regulator issued a narrow ruling. OmniSearch avoided the worst this time. It won't stop the next case.",
		"outcome_lose_tr": "Düzenleyici dar kapsamlı karar verdi. OmniSearch bu sefer en kötüyü atlattı. Bir sonraki davayı durdurmaz."
	},
	{
		"action":"BUY", "ticker":"SMTC",
		"hint": "It's an upcoming earnings disclosure in the financial sector. The street has no idea what's coming.",
		"hint_tr": "Finans sektöründe yaklaşan bir kazanç açıklaması. Piyasanın ne geleceğinden haberi yok.",
		"greeting": "You'll forgive me — I have another meeting at four. I'll come straight to the point. I have a contact inside Summit Capital's finance team. Not someone who talks much, which is precisely why I trust them when they do. They've said one thing to me recently, once: that the upcoming quarterly numbers are going to be significant. I know what their trading desk has been running this cycle. I'd like you to be positioned before those numbers land. Can we talk numbers?",
		"greeting_tr": "Affedersiniz — dörtte başka bir toplantım var. Hemen konuya gireyim. Summit Capital'ın finans ekibinin içinde bir kişi var. Fazla konuşmaz; bu yüzden konuştuğunda güvenirim. Son zamanlarda bana bir şey söyledi, tek seferlik: yaklaşan çeyrek rakamlarının önemli olacağını. Bu döngüde işlem masalarının ne yürüttüğünü biliyorum. Bu rakamlar gelmeden önce konumlanmanızı istiyorum. Rakamları konuşabilir miyiz?",
		"reason": "Summit Capital's trading desk is about to post its best quarter since 2009. The volatility strategy they've been running in debt markets has been consistently on the right side. The announcement is roughly a month out. The street has no idea. Get long before the disclosure.",
		"reason_tr": "Summit Capital'ın işlem masası 2009'dan bu yana en iyi çeyreğini açıklamak üzere. Borç piyasalarında yürüttükleri volatilite stratejisi bu döngüde tutarlı şekilde doğru tarafta kaldı. Açıklama yaklaşık bir ay uzakta. Piyasanın haberi yok. Açıklamadan önce uzun tarafta konumlanın.",
		"outcome_win": "Summit's quarterly numbers came in exactly as I described. Best quarter in over a decade. You were positioned correctly.",
		"outcome_win_tr": "Summit'in çeyrek rakamları tam anlattığım gibi geldi. On yılı aşkın sürenin en iyi çeyreği. Doğru konumlandınız.",
		"outcome_lose": "A late mark-to-market adjustment reduced their headline figure. The underlying performance was strong but the number disappointed.",
		"outcome_lose_tr": "Son dakika değerleme düzeltmesi manşet rakamını düşürdü. Altta yatan performans güçlüydü ama rakam hayal kırıklığı yarattı."
	},
	{
		"action":"SELL","ticker":"MVRS",
		"hint": "It's about the real sales data behind a high-profile hardware launch. The gap with analyst models is significant.",
		"hint_tr": "Yüksek profilli bir donanım lansmanının ardındaki gerçek satış verileriyle ilgili. Analist modelleriyle fark önemli.",
		"greeting": "I work in consumer electronics distribution — specifically logistics for large hardware launches. Returns, replacements, warranty coordination. I'm not a financial person. But I am looking at data from Metaverse Corp's headset launch right now that is very different from what their investor materials describe. I don't know exactly how long it takes for this kind of gap to surface publicly, but I know it always does. Someone said you'd understand what I'm looking at. I think it's worth something to the right person.",
		"greeting_tr": "Tüketici elektroniği dağıtımında — özellikle büyük donanım lansmanları için lojistikte — çalışıyorum. İadeler, değişimler, garanti koordinasyonu. Finans dünyasından değilim. Ama şu an Metaverse Corp'un kulaklık lansmanına ait verilere bakıyorum ve yatırımcı materyallerinde tanımlananla çok farklı. Bu tür bir farkın kamuoyuna yansımasının ne kadar sürdüğünü tam bilmiyorum, ama her zaman yansıdığını biliyorum. Birisi ne baktığımı anlayacağınızı söyledi. Doğru kişiye değer taşıdığını düşünüyorum.",
		"reason": "Metaverse Corp shipped headsets to a hundred thousand pre-order customers. The two-week return rate is twenty-three percent. I've seen the customer service volumes. Analysts are modelling a completely different number. When the gap becomes impossible to obscure — and it will, in about a month — this stock moves down hard.",
		"reason_tr": "Metaverse Corp yüz bin ön sipariş müşterisine kulaklık gönderdi. İki haftalık iade oranı yüzde yirmi üç. Müşteri hizmetleri hacimlerini gördüm. Analistler tamamen farklı bir rakam modelliyor. Fark gizlenemez hale geldiğinde — yaklaşık bir ay içinde olacak — bu hisse sert düşer.",
		"outcome_win": "Metaverse's actual sales data was disclosed. The gap with analyst estimates was substantial. Your position paid off.",
		"outcome_win_tr": "Metaverse'ün gerçek satış verileri açıklandı. Analist tahminleriyle fark büyüktü. Pozisyonunuz karşılığını verdi.",
		"outcome_lose": "They released a positive enterprise sales update that offset the consumer return rate. Unusual, but it happened.",
		"outcome_lose_tr": "Olumlu kurumsal satış güncellemesi tüketici iade oranını telafi etti. Alışılmadık ama oldu."
	},
	{
		"action":"BUY", "ticker":"BLKP",
		"hint": "It concerns a major fund's undisclosed position — emerging markets. I've been watching them build it for weeks.",
		"hint_tr": "Büyük bir fonun açıklanmamış pozisyonuyla ilgili — gelişen piyasalar. Haftalar önce inşa etmeye başladıklarını izliyorum.",
		"greeting": "I'm here because someone I trust said you're discreet and you move fast. Both matter for what I have. I used to work in prime brokerage — you learn, in that role, to notice when a major fund is building a position even when they're trying not to be noticed. I've been watching BlackPeak Investments for six weeks. What they're building is unlike anything I've seen them do before. I have a strong view on the catalyst. That view is worth money to the right person. Are you that person?",
		"greeting_tr": "Buraya geldim çünkü güvendiğim biri sizin temkinli ve hızlı hareket ettiğinizi söyledi. İkisi de söyleyeceklerim için önemli. Eskiden birincil aracılık sektöründe çalışırdım — o işte, büyük bir fonun gizlemeye çalışırken bile pozisyon inşa ettiğini fark etmeyi öğrenirsiniz. BlackPeak Investments'ı altı haftadır izliyorum. İnşa ettikleri şey onlardan daha önce gördüğüm hiçbir şeye benzemiyor. Katalizör konusunda güçlü bir görüşüm var. O görüş doğru kişiye para değer. O kişi siz misiniz?",
		"reason": "BlackPeak has been accumulating a large long position in emerging market sovereign debt for two months through intermediaries. The thesis is a coordinated rate cut cycle timed to a specific IMF meeting. Their macro track record is strong. If they're right — and I believe they are — the spread compression will be significant. Follow the position before the catalyst becomes public.",
		"reason_tr": "BlackPeak, iki aydır aracılar üzerinden gelişen piyasa egemen borcunda büyük bir uzun pozisyon biriktiriyor. Tez, belirli bir IMF toplantısına zamanlı koordineli bir faiz indirimi döngüsü. Makro geçmişleri güçlü. Haklılarsa — ve olduklarına inanıyorum — spread sıkışması önemli olacak. Katalizör kamuoyuna çıkmadan pozisyonu takip edin.",
		"outcome_win": "The IMF meeting produced the coordinated policy shift BlackPeak anticipated. Emerging market debt repriced upward. Good position.",
		"outcome_win_tr": "IMF toplantısı BlackPeak'in öngördüğü koordineli politika değişimini üretti. Gelişen piyasa borcu yukarı yeniden fiyatlandı. Güzel pozisyon.",
		"outcome_lose": "The IMF meeting ended without consensus. BlackPeak's thesis was correct — the timing slipped a cycle.",
		"outcome_lose_tr": "IMF toplantısı uzlaşısız sona erdi. BlackPeak'in tezi doğruydu — zamanlama bir döngü kaydı."
	},
]

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)

func _on_day(_d: String) -> void:
	for tip in _pending_tips:
		tip["days_left"] -= 1
		if tip["days_left"] <= 0:
			_resolve_tip(tip)
	_pending_tips = _pending_tips.filter(func(t): return t["days_left"] > 0)
	_next_visit -= 1
	if _next_visit <= 0:
		_next_visit = 56 + randi() % 56
		_send_speculator()

func _send_speculator() -> void:
	if not EventScheduler.can_fire():
		_next_visit = 7  # retry in 7 days
		return
	EventScheduler.mark_fired()
	var spec  = SPECULATORS[randi() % SPECULATORS.size()]
	var tmpl  = TIPS[_tip_idx % TIPS.size()]
	_tip_idx += 1
	var price := float((randi() % 10 + 3) * 5000)
	emit_signal("speculator_arrived", {
		"name":       spec["name"],
		"title":      spec["title"],
		"portrait":   spec["portrait"],
		"action":     tmpl["action"],
		"ticker":     tmpl["ticker"],
		"hint":           tmpl.get("hint",          "I have actionable information. Pay to hear it."),
		"hint_tr":        tmpl.get("hint_tr",       "Harekete değer bilgim var. Duymak için ödeyin."),
		"greeting":       tmpl["greeting"],
		"greeting_tr":    tmpl.get("greeting_tr",   tmpl["greeting"]),
		"reason":         tmpl["reason"],
		"reason_tr":      tmpl.get("reason_tr",     tmpl["reason"]),
		"outcome_win":    tmpl["outcome_win"],
		"outcome_win_tr": tmpl.get("outcome_win_tr",  tmpl["outcome_win"]),
		"outcome_lose":    tmpl["outcome_lose"],
		"outcome_lose_tr": tmpl.get("outcome_lose_tr", tmpl["outcome_lose"]),
		"price":      price,
		"correct":    randf() < 0.58,
		"id":         randi(),
	})

func accept_tip(offer: Dictionary) -> void:
	if GameState.cash < offer["price"]: return
	GameState.add_cash(-offer["price"])
	offer["days_left"] = 28 + randi() % 14
	_pending_tips.append(offer)

func _resolve_tip(tip: Dictionary) -> void:
	if tip["correct"]:
		if   tip["action"] == "BUY":  MarketEngine.apply_event_impact(tip["ticker"],  0.09)
		elif tip["action"] == "SELL": MarketEngine.apply_event_impact(tip["ticker"], -0.09)
	emit_signal("tip_resolved", tip, tip["correct"])
