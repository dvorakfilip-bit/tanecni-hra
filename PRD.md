# PRD: Taneční hra (salsa & bachata)

| | |
|---|---|
| Stav | Návrh v0.1 |
| Platforma | Android (portrait) |
| Engine | Godot 4.x (aktuální stabilní při startu vývoje, pak zafixovaná), GDScript |
| Jazyk UI | čeština (angličtina v pozdější verzi) |
| Distribuce | osobní projekt, instalace přes APK |
| Testovací zařízení | Samsung Galaxy A35 5G (SM-A356B/DS) |
| Min. Android | výchozí minimum Godotu 4 |

---

## 1. Vize

Rytmická hra na motivy párového tance (bachata, později salsa). Hráč je **leader** a do hudby „vede“ partnerku pomocí karet figur. Spojuje dvě věci:

- **rytmus:** figuru je potřeba zadat ve správnou dobu,
- **taktiku:** figura musí dávat smysl v aktuálním držení a pro danou partnerku.

Pocitově jde o karetní hru hranou do hudby. Hra má učit reálný princip, že se tancuje pro partnerku, ne pro sebe.

## 2. Cíle a ne-cíle

### Cíle
- Hratelné MVP s jednou bachatovou písní, které je zábavné samo o sobě.
- Spolehlivý timing na Androidu, včetně kalibrace audio latence.
- Datově řízený obsah (figury, partnerky, písně v datových souborech), aby šlo přidávat obsah bez úprav kódu.

### Ne-cíle (MVP)
- Salsa, tap mechanika na doby 4 a 8, víc partnerek, kariéra.
- Import vlastních mp3.
- Propracovaná grafika a animace, monetizace, online funkce, angličtina.

## 3. Základní herní smyčka

### Úvod písně (prvních 16 dob)
- Počítá se od první doby 1 (offset písně). Hudební intro před ní se nepočítá.
- Dole jsou normálně zobrazené 4 karty, aby podle nich hráč mohl naplánovat.
- Přes animaci páru jsou dvě tlačítka **Otevřené** a **Zavřené** pro volbu výchozího držení. Platí poslední volba.
- Když hráč nic nevybere, začíná se v zavřeném držení.
- Pár tančí základní krok, nečinnost se nepostihuje.
- Karty nejde v úvodu potvrdit. Ve druhém cyklu úvodu (doby 13–15, tedy 5–7) jde ale kartu vybrat jako přípravu, takže první figura jde potvrdit hned na dobu 17.

### Cyklus figury
1. Hraje hudba, pár tančí základní krok.
2. Během dob **5–6–7** hráč vybere kartu figury (ťuknutím na kartu). Tím partnerku „připraví“, podobně jako signál rukou v reálném tanci. Kartu lze vybrat kdykoli a výběr lze měnit, ale za správnou přípravu se počítá jen výběr v okně 5–7 (viz 4.2).
3. Na dobu **1** hráč figuru potvrdí **druhým ťuknutím na vybranou kartu**.
4. Hra vyhodnotí:
   - **timing:** Perfect / Good / Miss podle odchylky od doby 1,
   - **přípravu:** jestli byla karta vybrána včas,
   - **logiku:** jestli figura jde z aktuálního držení a jestli ji partnerka zvládne.
5. Pár figuru zatančí (8 dob). Během dob 5–7 této figury se vybírá další.

### Nečinnost
Když hráč na dobu 1 nic nepotvrdí, pár tančí základní krok.
- Jeden základní krok je v pořádku a partnerce doplní energii.
- Při **3 a více** základních krocích po sobě se partnerka začne nudit a pohoda mírně klesá.

### Konec písně
Píseň se vždy dotančí do konce. Pak následuje obrazovka hodnocení (skóre, max. combo, výsledná pohoda, 1–3 hvězdičky).

## 4. Pravidla vyhodnocení

### 4.1 Timing
Odchylka ťuknutí od doby 1 (výchozí hodnoty, budou se ladit):

| Výsledek | Odchylka | Efekt |
|---|---|---|
| Perfect | ≤ ±50 ms | plné body, combo pokračuje |
| Good | ≤ ±120 ms | snížené body, combo pokračuje |
| Miss | ≤ ±200 ms | figura se neprovede, pár tančí základ, combo se ruší |
| (ignorováno) | > ±200 ms | ťuknutí na vybranou kartu se nebere jako potvrzení |

Potvrzení se přijímá jen v okně ±200 ms kolem doby 1. Timing se počítá po odečtení kalibrované latence (viz kap. 9).

### 4.2 Příprava
| Kdy byla karta vybrána | Výsledek |
|---|---|
| doby 1–4 | předčasná příprava: figura je „prozrazená“ moc brzy, partnerka zpomalí, maximálně Good |
| doby 5–7 | správná příprava |
| doba 8 | uspěchaná příprava: figura proběhne, ale maximálně za Good |
| bez výběru | potvrzení nejde provést (není co potvrdit) |

Rozhoduje doba posledního výběru (změny) karty.

### 4.3 Logika a partnerka
| Situace | Důsledek |
|---|---|
| Figura nejde z aktuálního držení | partnerka zakopne, pohoda klesne, držení se nemění, combo se ruší |
| Obtížnost figury > úroveň partnerky | figura proběhne nejistě, výrazný pokles pohody, combo se ruší |
| Partnerka nemá dost energie | figura proběhne, ale pohoda klesne a body se sníží |
| Vše v pořádku | figura proběhne, body, combo +1 |

## 5. Systémy

### 5.1 Držení (stavy)
Každá figura má vstupní a výstupní držení. Hráč tak musí plánovat dopředu.

| ID | Název | Popis |
|---|---|---|
| `zavrene` | Zavřené (blízké) | klasické bachatové blízké držení |
| `otevrene` | Otevřené, dvě ruce | partneři naproti sobě, drží se za obě ruce |
| `jedna_ruka` | Jedna ruka | spojené jen jednou rukou |
| `zkrizene` | Zkřížené ruce | ruce překřížené, připravené na rozplétání |

### 5.2 Figury MVP (bachata)
Všechny figury v MVP mají délku 8 dob.

| Figura | Vstup | Výstup | Obtížnost (1–3) | Energie | Typ |
|---|---|---|---|---|---|
| Základní krok | libovolné | stejné | 1 | +10 (regenerace) | základ |
| Boky | zavrene | zavrene | 1 | −5 | styling |
| Otevření | zavrene | otevrene | 1 | −5 | přechod |
| Zavření | otevrene, jedna_ruka | zavrene | 1 | −5 | přechod |
| Výměna míst | otevrene | jedna_ruka | 2 | −10 | figura |
| Otočka partnerky | jedna_ruka | jedna_ruka | 2 | −15 | otočka |
| Zkřížení | otevrene | zkrizene | 2 | −10 | přechod |
| Rozplétání s otočkou | zkrizene | otevrene | 3 | −15 | otočka |
| Vlna | zavrene | zavrene | 2 | −10 | efektní |
| Dip | zavrene | zavrene | 3 | −20 | efektní |

Základní krok není karta, děje se automaticky při nečinnosti.

Příklad logického řetězu (ze zavřeného držení): otevření → zkřížení → rozplétání s otočkou → výměna míst → otočka partnerky → zavření → dip.

### 5.3 Karty v ruce
- Hráč má v ruce **4 karty**.
- Karty se lížou náhodně z balíčku všech figur (kromě základního kroku). Použitá karta se nahradí novou.
- Karty, které z aktuálního držení nejdou, se zobrazí, ale vizuálně potlačené. Zahrát je jde (s důsledky dle 4.3).
- Hráč může 1× za cyklus (kdykoli během 8 dob) kartu zahodit **přejetím dolů** a líznout novou. (Pojistka proti ruce, se kterou nejde nic zahrát.)

### 5.4 Partnerka
Vlastnosti:
- **úroveň (1–3):** maximální obtížnost figury, kterou zvládne,
- **energie (0–100):** náročné figury ji ubírají, základní krok ji doplňuje,
- **oblíbený styl:** typ figur, za které dává bonus k pohodě (např. otočky, styling).

MVP partnerka: úroveň 3, energie 100, oblíbený styl styling.

Energie nikdy neklesne pod 0. „Nedostatek energie“ (viz 4.3) nastane, když má partnerka méně energie, než figura stojí.

### 5.5 Pohoda partnerky
- Rozsah 0–100, začíná na 70.
- Roste: Perfect timing, oblíbený styl, figura na akcent, rozmanitost figur.
- Klesá: chybná logika, příliš těžká figura, figura bez energie, Miss, dlouhá nečinnost, opakování stejné figury víckrát po sobě.
- Stejná figura hned po sobě dává jen **nízký** postih k pohodě.
- Ovlivňuje násobič skóre lineárně: pohoda 0 = ×0,5, pohoda 50 = ×1,0, pohoda 100 = ×1,5.
- Ukazatel: srdíčko / smajlík s několika stavy.

### 5.6 Skóre a combo
- Body za figuru = základ figury (podle obtížnosti) × timing (Perfect 1,0 / Good 0,6) × násobič combo × násobič pohody.
- **Combo** = počet úspěšných figur po sobě. Ruší ho Miss, chybná logika a příliš těžká figura. Základní krok combo neruší, ale nenavyšuje.
- Násobič combo: ×1,0 + 0,1 za každou figuru v combu, maximálně ×2,0 (od 10 figur).
- Bonus za rozmanitost: figura, která nebyla mezi posledními 3, dává bonus k bodům.
- **Hvězdičky** (podíl z maximálního možného skóre písně): ★ od 40 %, ★★ od 65 %, ★★★ od 85 % a zároveň pohoda na konci aspoň 50.

### 5.7 Hudebnost
- **Fráze:** 32 dob (4 cykly po 8 dobách). Figura obtížnosti 2+ zahájená na začátku fráze dává bonus.
- **Akcenty:** break, stop, vrchol písně. Jsou v datech písně a na časové ose předem vyznačené. Akcent patří k cyklu (8 dob), ve kterém leží, i když nepadne na dobu 1. Efektní karta (vlna, dip) zahájená na začátku tohoto cyklu dává velký bonus. Na ose se vyznačí celý cyklus i přesná pozice akcentu.
- Cíl balancu: hráč, který jen chrlí figury bez ohledu na hudbu, nemá dostat víc než průměrné skóre.

## 6. Obrazovky a UI

Orientace na výšku.

### 6.1 Herní obrazovka
| Oblast | Obsah |
|---|---|
| Nahoře | pár tanečníků, 2D, šikmý pohled (3/4, částečně shora a částečně zboku) |
| Uprostřed | časová osa s počítáním 1-2-3-4-5-6-7-8, doba 1 zvýrazněná, vyznačené okno výběru (5–7), začátky frází a akcenty |
| Dole | 4 karty figur |
| Lišta | pohoda, skóre, combo, ukazatel energie partnerky |

Bachata se počítá 1-2-3-tap-5-6-7-tap; doby 4 a 8 jsou na ose vyznačené jako „tap“, ale v MVP se na ně neťuká.

### 6.2 Karta figury
Každá karta zobrazuje:
- název figury,
- ikonu typu (přechod, otočka, styling, efektní…),
- vstup → výstup jako ikonky držení,
- obtížnost jako tečky 1–3,
- cenu energie.

### 6.3 Další obrazovky (MVP)
- **Hlavní menu:** Hrát, Jak hrát, Kalibrace, Nastavení. V MVP je jen jedna píseň, „Hrát“ ji spustí rovnou. Výběr písní přijde s importem vlastních mp3.
- **Jak hrát:** jednoduchá obrazovka s textem a obrázky. Interaktivní tutoriál později.
- **Kalibrace latence** (kap. 9).
- **Nastavení:** hlasitost hudby a efektů, metronom zap/vyp, ruční korekce latence, vibrace při ťuknutí zap/vyp.
- **Pauza:** zastaví hudbu i hru. Aktivuje se i automaticky, když aplikace přejde na pozadí. Po obnovení se hudba vrátí na začátek aktuálního cyklu a odpočítá 4 doby. Figura, která v cyklu běžela, se jen znovu přehraje (bez nového vyhodnocení) a výběr karty na další cyklus zůstává.
- **Výsledky** po písni.

## 7. Grafika a zvuk

- **Pohled:** šikmý (3/4). Podlaha je zploštělá elipsa, hloubka se řeší řazením podle osy Y (y-sort).
- **Postavičky:** jednoduchí panáčci z kruhů a obdélníků (hlava, tělo) s odlišnými barvami a stínem na podlaze, ruce jako čáry mezi nimi podle držení. Výška postav umožní ukázat dip, vlnu a boky, pohled shora zase otočky a výměny míst.
- **Pohyb:** posun po předem daných drahách na podlaze pro každou figuru (tween / Path2D), šipky naznačující směr.
- **Reakce partnerky:** zakopnutí, zmatení a radost jako jednoduché efekty (zatřesení, ikonka nad hlavou).
- **Zpětná vazba:** text Perfect / Good / Miss, zvuk ťuknutí, volitelný metronom, volitelná vibrace.

## 8. Hudba a data písní

### 8.1 Přibalené písně (MVP)
Jedna bachata píseň s pevným BPM: **Incienso (2.0) – Montelier**, 130 BPM. Offset a akcenty je potřeba změřit.

Ke každé mp3 patří datový soubor, např. `pisen.json`:

```json
{
  "nazev": "Název písně",
  "styl": "bachata",
  "soubor": "res://songs/pisen.mp3",
  "bpm": 130,
  "offset_ms": 420,
  "delka_frazi_dob": 32,
  "akcenty": [
    { "doba": 96, "typ": "break" },
    { "doba": 160, "typ": "vrchol" }
  ]
}
```

- `offset_ms`: čas první doby 1 od začátku souboru.
- `doba`: pořadové číslo doby od začátku písně (od 0).

Licence písně: protože jde o osobní projekt, řeší si to autor sám.

### 8.2 Editor písně (MVP jako vývojářský nástroj)
Slouží ke změření offsetu a akcentů přibalené písně. Ten samý editor se později použije pro import vlastních mp3 (8.3).
- přehrávání písně s metronomem,
- posun offsetu (jemně i hrubě),
- úprava BPM, včetně ×2 / ÷2,
- označení akcentů (doba + typ),
- uložení do JSON.

### 8.3 Vlastní mp3 (po MVP)
1. Hráč vybere mp3 z telefonu (systémový výběr souborů).
2. Hra automaticky odhadne BPM a pozici první doby 1.
3. Hráč výsledek doladí v editoru písně (8.2).
4. Volitelně ručně označí akcenty.
5. Data se uloží do `user://` a příště se nepočítají znovu.

## 9. Technické požadavky

### 9.1 Timing
- Čas písně počítat z pozice přehrávání audia, ne ze snímků: `AudioStreamPlayer.get_playback_position()` + `AudioServer.get_time_since_last_mix()` − `AudioServer.get_output_latency()`.
- Doba = `offset + n × (60 / BPM)`.
- Vstup zpracovávat v `_input` s časovou značkou co nejblíž ťuknutí.

### 9.2 Kalibrace latence
Na Androidu se latence audia a dotyku liší podle zařízení, proto je kalibrace nutná už v MVP:
- hráč ťuká do metronomu, hra spočítá průměrnou odchylku a uloží ji jako korekci,
- korekce jde i ručně posunout v nastavení.

### 9.3 Data
Obsah je v datových souborech, ne natvrdo v kódu:
- **Figury a partnerky:** Godot Resource (`.tres`). Edituješ je v inspektoru a hra hlídá datové typy.
- **Písně:** JSON, protože je bude za běhu vytvářet i import vlastních mp3.

Příklad třídy figury:

```gdscript
class_name Figura
extends Resource

@export var id: StringName
@export var nazev: String
@export var styl: StringName          # "bachata", "salsa"
@export var vstup: Array[StringName]  # držení, ze kterých jde figura zahrát
@export var vystup: StringName        # držení po figuře
@export var delka_dob: int = 8
@export_range(1, 3) var obtiznost: int = 1
@export var narocnost_energie: int = 0
@export var typ: StringName           # "prechod", "otocka", "styling", "efektni"
```

### 9.4 Ukládání
Do `user://` se ukládá:
- nejlepší skóre a hvězdičky pro každou píseň,
- nastavení,
- kalibrace latence,
- (po MVP) data importovaných písní.

### 9.5 Architektura (návrh)
| Komponenta | Odpovědnost |
|---|---|
| `Conductor` | přehrávání, aktuální doba, signály `beat(n)` a `cycle_start` |
| `FigureDb`, `PartnerDb`, `SongDb` | načtení dat |
| `DanceState` | aktuální držení, energie, pohoda |
| `Judge` | vyhodnocení timingu, přípravy a logiky |
| `ScoreSystem` | skóre, combo, bonusy |
| `Hand` | balíček a karty v ruce |
| `DancerView` | vykreslení a animace páru |
| `TimelineView` | časová osa |
| `SaveManager` | ukládání skóre, nastavení a kalibrace |
| `SongEditor` | editor písně (8.2) |

### 9.6 Rizika
| Riziko | Dopad | Opatření |
|---|---|---|
| Audio latence na Androidu | nepřesný timing | kalibrace, čas z audio pozice |
| Automatická detekce BPM | náročné, v GDScriptu pomalé, Godot nedává snadno PCM data z mp3 | až po MVP; ověřit dekódování a případně GDExtension (např. minimp3 + aubio) |
| Přístup k souborům na Androidu | omezení úložiště v novějších verzích | systémový výběr souborů (SAF), ověřit podporu v Godot 4 |
| Balanc | hra je nudná nebo frustrující | všechny konstanty v datech, rychlé ladění |

## 10. Roadmapa

| Verze | Obsah |
|---|---|
| **0.1 MVP** | 1 bachata píseň, 4 držení, 10 figur, 1 partnerka, pohoda, skóre, combo, hudebnost, kalibrace, jednoduchá 2D grafika, obrazovka Jak hrát, editor písně jako vývojářský nástroj, ukládání skóre |
| 0.2 | import vlastních mp3 s automatickou detekcí BPM, editor písně dostupný hráči, výběr písní |
| 0.3 | tap mechanika na doby 4 a 8 |
| 0.4 | salsa (rychlé tempo, počítání 1-2-3, 5-6-7, salsové figury) |
| 0.5 | víc partnerek s různými vlastnostmi |
| později | kariéra (zatím nespecifikováno), angličtina |

## 11. Kritéria úspěchu MVP

- Celou píseň jde odehrát bez pádu na Galaxy A35.
- Plynulých 60 FPS.
- Po kalibraci působí timing přesně (Perfect jde opakovaně trefit).
- Hra autora baví hrát opakovaně a rozhodování o figurách má smysl.

## 12. Rozhodnutí

| Téma | Rozhodnutí |
|---|---|
| Počet figur MVP | 10 (všechna 4 držení propojená) |
| Karty v ruce | náhodné lízání z balíčku, nehratelné karty potlačené, 1 zahození za cyklus |
| Délka fráze | 32 dob |
| Pohled | šikmý 3/4 |
| Nečinnost | pohoda klesá od 3. základního kroku po sobě |
| Testovací zařízení | Galaxy A35 5G, minimum Androidu podle Godotu 4 |
| Píseň MVP | Incienso (2.0) – Montelier, 130 BPM |

## 13. Otevřené otázky

1. Změřit offset první doby 1 a akcenty písně Incienso (2.0) v editoru písně (8.2).
