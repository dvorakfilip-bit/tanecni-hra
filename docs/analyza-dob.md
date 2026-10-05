# Analýza dob v písni (`tools/analyze_beats.py`)

Skript z mp3 automaticky zjistí tempo (BPM), čas první doby a úseky, kde hudba
vybočuje z rytmu (kandidáti na akcenty). Nahrazuje ruční ťukání v editoru písně,
které je nepřesné. Výsledek se pak jen doladí poslechem v editoru písně.

Je to vývojářský nástroj na PC. Ve hře se nepoužívá; automatická detekce BPM pro
import vlastních mp3 přijde až ve verzi 0.2 (PRD 8.3).

## Instalace (jednou)

Potřeba je Python 3.12 a knihovny `numpy` a `soundfile`. Prostředí je mimo repo:

```bash
python -m venv C:/claude/tools/py-audio
C:/claude/tools/py-audio/Scripts/python -m pip install numpy soundfile
```

Proč ne knihovna librosa: potřebuje numba, jejíž DLL na tomto PC blokuje Windows
Smart App Control. Skript proto používá jen numpy (výpočty) a soundfile (čtení mp3).
Blokované jsou i části SciPy (např. `scipy.signal`), takže ji skript nepoužívá.

## Použití

```bash
C:/claude/tools/py-audio/Scripts/python tools/analyze_beats.py songs/incienso.mp3 --bpm 130
```

- `--bpm` je jen nápověda, kolem jakého tempa hledat (výchozí 130). Pomáhá, aby
  detekce nenašla poloviční nebo dvojnásobné tempo.
- Běh trvá asi 15 s na 4minutovou píseň.

## Co skript vypíše

| Část | Význam |
|---|---|
| `mřížka: … BPM, první doba … ms, sedí N/M dob, odchylka ±… ms` | hlavní výsledek: pevné tempo a čas první detekované doby. Odchylka do ~15 ms = velmi přesné |
| `lokální tempo po 16 dobách` | tempo v jednotlivých úsecích. Když je všude stejné, stačí pevné BPM. Výkyvy jen v jednom úseku obvykle znamenají break, ne změnu tempa |
| `úseky mimo mřížku` | místa, kde detekované doby nesedí na mřížku: break, stop, ztišení. Kandidáti na akcenty |
| `profil energie po pozicích v cyklu` | jak výrazná je každá z 8 dob cyklu v basech, středech a výškách. Nápověda, která doba je „1“ |
| `do JSON písně` | hodnoty pro `songs/<píseň>.json` |

Čísla dob ve výpisu se počítají od první detekované doby, ne od `offset_ms` v JSON.

## Jak to funguje

1. **Onset envelope:** mp3 se převede na mono 22 kHz a spočítá se spektrální flux
   (o kolik v každém okamžiku přibylo energie ve spektru). Špičky = údery.
2. **Tempo:** autokorelace onset envelope najde nejčastější vzdálenost mezi údery
   (60–200 BPM, s vahou kolem `--bpm`).
3. **Doby:** dynamické programování (beat tracker podle Ellis 2007) najde řadu dob,
   která nejlépe sedí na údery a zároveň drží tempo.
4. **Mřížka:** doby se proloží přímkou `čas = offset + n × doba`. Doby dál než 35 ms
   od přímky se vyřadí a proložení se opakuje. Vyřazené doby tvoří „úseky mimo mřížku“.

## Postup pro novou píseň

1. Spusť skript a zkontroluj, že lokální tempo je všude zhruba stejné.
2. Do JSON písně zapiš `bpm` a `offset_ms` podle posledního řádku výpisu.
3. V editoru písně (dev menu → Editor písně) pusť píseň s metronomem. Vyšší klik je
   doba 1. Tlačítky **±1 doba** ho posuň na skutečnou „1“ (bachata obvykle o 0–7 dob,
   podle profilu energie a poslechu).
4. Ověř, že metronom sedí i na konci písně.
5. Projdi úseky mimo mřížku a další místa, označ akcenty (klávesa A) a ulož.

`offset_ms` může být mírně záporný (první „1“ těsně před začátkem souboru),
Conductor s tím počítá.

## Omezení

- Předpokládá **pevné tempo**. Pro písně s proměnlivým tempem by bylo potřeba
  ukládat časy všech dob místo jednoho BPM (zatím nepodporováno).
- Kterou dobu je „1“, skript jen odhaduje, rozhoduje poslech.
- Akcenty navrhuje jen tam, kde se rozpadá rytmus. Akcenty uprostřed rytmu
  (vrchol, výrazný úder) je potřeba označit ručně.

## Výsledek pro Incienso (2.0)

- 130,00 BPM, 448/477 dob sedí na mřížku s odchylkou ±9 ms, tempo je stálé.
- První detekovaná doba 913 ms. Po srovnání poslechem je „1“ o 2 doby dřív:
  `offset_ms = -11`.
- Rytmus vybočuje ve 24–28 s a 93–101 s.
