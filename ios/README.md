# Rondo — iPhone en Apple Watch

Intervaltimer in de huisstijl uit [`../BRAND.md`](../BRAND.md): de training is
een partituur, en de partituur is een cirkel. Twee targets, één gedeelde kern.

```
ios/
├── Rondo.xcodeproj/            met de hand geschreven, objectVersion 77
│   ├── project.pbxproj
│   ├── project.xcworkspace/
│   └── xcshareddata/xcschemes/ Rondo, Rondo Watch App
├── Rondo/
│   ├── Shared/                 in BEIDE targets
│   │   ├── Workout.swift       model + programmaregel (laatste rust vervalt)
│   │   ├── WorkoutEngine.swift de klok, op absolute Date-deadlines
│   │   ├── AudioCoach.swift    piepjes (#if os(iOS)) — uit V1, ongewijzigd
│   │   ├── CueSink.swift       protocol tussen klok en signaal
│   │   ├── RondoDial.swift     de cirkelpartituur (Canvas)
│   │   ├── RondoTheme.swift    inkt, bot, puls, diep, amber
│   │   ├── RondoType.swift     Archivo, variabele assen via CoreText
│   │   ├── SyncLink.swift      WatchConnectivity, beide richtingen
│   │   ├── Storage.swift       UserDefaults
│   │   └── Archivo-Variable.ttf (OFL, zie FONT-LICENSE.txt)
│   ├── iOS/
│   │   ├── RondoApp.swift, TimerScreen.swift,
│   │   ├── EditFieldSheet.swift, SavedWorkoutsSheet.swift
│   │   └── Assets.xcassets/
│   └── Watch/
│       ├── RondoWatchApp.swift, WatchTimerScreen.swift,
│       ├── WatchHaptics.swift, ExtendedRuntime.swift
│       └── Assets.xcassets/
├── RondoTests/WorkoutProgramTests.swift
├── Info-iOS.plist   UIBackgroundModes: [audio], UIAppFonts
├── Info-Watch.plist WKApplication, WKCompanionAppBundleIdentifier, WKBackgroundModes
├── project.yml      XcodeGen-reserve
└── README.md
```

Bundle-id's: `nl.bbruijn.rondo` en `nl.bbruijn.rondo.watchkitapp`.
Deployment targets: iOS 17.0, watchOS 10.0. `SWIFT_VERSION = 5.0`.

## Bouwen en op je telefoon zetten (gratis Apple ID)

1. Open `ios/Rondo.xcodeproj` in Xcode 16 of nieuwer.
2. Xcode → Settings → Accounts → **+** → Apple ID. Een gratis account volstaat;
   je krijgt een *Personal Team*.
3. Selecteer in de projectnavigator het project **Rondo**, dan het target
   **Rondo** → Signing & Capabilities:
   - Automatically manage signing **aan**
   - Team: jouw Personal Team
   - Bundle Identifier: `nl.bbruijn.rondo` is al ingevuld. Is die id al door
     iemand anders geclaimd, maak er dan iets eigens van (bijvoorbeeld
     `nl.jouwnaam.rondo`) **en pas dan ook** het watch-target aan naar
     `<jouw id>.watchkitapp` **en** `WKCompanionAppBundleIdentifier` in
     `Info-Watch.plist`. Die drie moeten met elkaar kloppen, anders installeert
     de Watch-app niet.
4. Doe hetzelfde voor het target **Rondo Watch App** (zelfde team).
5. Sluit je iPhone aan, kies hem als run-bestemming, ⌘R.
6. Eerste keer op het toestel: Instellingen → Algemeen → VPN en apparaatbeheer →
   jouw ontwikkelaarscertificaat → Vertrouwen.

Met een gratis Apple ID verloopt het profiel na **7 dagen**; opnieuw builden
zet de klok terug. Er zijn geen betaalde capabilities nodig: achtergrond-audio
is een Info.plist-sleutel, geen entitlement.

### Apple Watch erbij

1. Koppel de Watch met dezelfde iPhone (Watch-app → Koppel).
2. Zet op de Watch ontwikkelaarsmodus aan: Instellingen → Privacy en beveiliging
   → Ontwikkelaarsmodus (watchOS 9+), en herstart de Watch.
3. In Xcode verschijnt de Watch onder het iPhone-toestel als run-bestemming.
   Kies scheme **Rondo Watch App** en ⌘R, of installeer de iPhone-app en laat de
   Watch-app meekomen via de "Embed Watch Content"-fase (Watch-app →
   Beschikbare apps → Installeer).
4. De eerste installatie over draadloos duurt makkelijk een paar minuten.

Werkt de simulator prettiger: kies een iPhone-simulator met een gekoppelde
Watch-simulator (Window → Devices and Simulators → Simulators). `WatchConnectivity`
werkt tussen gekoppelde simulatoren, haptiek niet.

### Reserve: project opnieuw genereren

```bash
brew install xcodegen
cd ios && xcodegen generate
```

`project.yml` beschrijft dezelfde drie targets. Gebruik dit als
`Rondo.xcodeproj` niet opent in jouw Xcode-versie (objectVersion 77 vraagt
Xcode 16).

## Hoe het in elkaar zit

### De ring (`RondoDial`)

Eén `Canvas`, één boog per interval, booglengte evenredig met de duur, startend
bovenaan en met de klok mee.

- **Dikte draagt het ritme:** werk 0,085 × diameter, reset 0,055, rust 0,032.
- **Afgelopen** bogen: accent op 20 %. **Lopend:** accent vol, 1,16 × dikker,
  plus een ademhaling van 2 s (±7 % lijndikte). **Komend:** haarlijnen in bot,
  waarbij werk nog altijd dikker is dan rust — anders zou je het ritme vóór de
  start niet meer zien, en juist dat is de belofte van de ring.
- Binnen de lopende boog is het afgelegde deel vol en de rest 34 %, met een
  botkleurig streepje op de kop: zo *reist* de voortgang, hij springt niet.
- **Eén accent tegelijk.** Alle bogen staan in de kleur van de huidige fase;
  werk en rust verschillen in dikte, niet in kleur. Dat is de uitleg van de
  twee huisstijlregels naast elkaar ("werkbogen dik, rustbogen dun" en "nooit
  meer dan één accentkleur tegelijk").
- Een `Canvas` interpoleert zijn invoer niet, dus de ring zou bij een fasewissel
  van kleur springen. Daarom is `RondoDial` `Animatable` over de
  accentcomponenten (`AnimatablePair`), en kruisvervaagt de ring in 400 ms.
- `accessibilityReduceMotion` zet alleen de ademhaling uit; de voortgang blijft.
- De iPhone tekent hem op maximaal 420 pt breed, de Watch vult het scherm met
  `weight: 1.1`.

### De klok

Ongewijzigd uit V1: elk segment krijgt een absolute `Date`-deadline, de
tikker (50 ms) rekent alleen `timeIntervalSinceNow`. Loopt de app achter na een
onderbreking, dan worden gemiste segmenten in één keer ingehaald en worden de
signalen onderdrukt zodra de achterstand groter is dan 1,5 s. Extra ten opzichte
van V1 is `segmentFraction` (op 1/300 afgerond) voor de ring.

### Geluid (iPhone)

`AudioCoach` is letterlijk overgenomen: `.playback` met `.mixWithOthers` (nooit
`.duckOthers`), een stille loopbuffer die de achtergrondsessie openhoudt, PCM-
synthese van de tonen, en afhandeling van onderbrekingen en
`mediaServicesWereReset`. Eén wijziging: aan het eind van een training wordt de
audiosessie 1,2 s ná de slottoon losgelaten in plaats van meteen, zodat de
laatste toon niet wordt afgekapt.

### Haptiek (Watch)

`WatchHaptics` implementeert hetzelfde `CueSink`-protocol:

| signaal | haptiek |
| --- | --- |
| werk begint | `.start`, en 0,22 s later nog een keer |
| rust begint | `.stop` |
| ronde-reset | `.notification` |
| 3-2-1 | `.click` per seconde |
| klaar | `.success`, en 0,3 s later nog een keer |

Haptiek staat **los van** de geluidsschakelaar: "geluid uit" op de iPhone zet je
arm niet stil.

`ExtendedRuntime` start een `WKExtendedRuntimeSession` zodra de klok loopt en
beëindigt hem bij pauze of einde, zodat de timer doorloopt als het scherm dimt.
Geen `HKWorkoutSession` — dat zou HealthKit-rechten vragen voor iets wat geen
workout-registratie is. De sessie heeft `WKBackgroundModes: [mindfulness]` in
`Info-Watch.plist` nodig; die staat erin. **Dit is niet getest** (zie hieronder).

### Synchronisatie

`SyncLink` (gedeeld) is een dunne laag over `WatchConnectivity`:

- **Instellingen** (`Workout` als JSON + de geluidsschakelaar) gaan via
  `sendMessage` als de tegenhanger bereikbaar is, anders via
  `updateApplicationContext` — laatste stand wint, en de ander is bij zodra hij
  opstart.
- **Commando's** (`run`, `pause`, `reset`, `finished`) gaan alleen via
  `sendMessage`. Is de tegenhanger niet bereikbaar, dan worden ze *weggegooid*:
  een startcommando dat een half uur later alsnog aankomt is erger dan geen
  startcommando.
- `run` draagt segmentindex, resttijd en verzendtijd; de ontvanger trekt de
  reistijd eraf en zet zijn eigen deadline. Zo lopen de twee klokken gelijk
  zonder dat er een "meester" is.
- Een binnengekomen bericht wordt toegepast met een vlag die uitgaand verkeer
  blokkeert, anders kaatsen de twee apps elkaars commando's heen en weer.
- Alles faalt stil. Geen Watch gekoppeld, Watch-app niet geïnstalleerd, buiten
  bereik: beide apps blijven volledig zelfstandig bruikbaar, ieder met hun eigen
  `UserDefaults`.

### Typografie

Archivo staat als variabele TTF in de bundel (OFL) en wordt via `UIAppFonts`
geregistreerd. SwiftUI kan geen variatie-assen zetten, dus `RondoType` zet
`wght` en `wdth` via CoreText (`CTFontDescriptorCreateCopyWithVariation`) en
levert het resultaat als `Font(CTFont)`: cijfers `wdth 85` / `wght 600` met
`tabular-nums` en −0,02 em, labels `wdth 100` / `wght 700` in hoofdletters met
+0,14 em. Is Archivo om wat voor reden niet geregistreerd, dan valt alles terug
op het systeemfont en blijft de app werken.

## Tests

`RondoTests` bewaakt de programmaregel, inclusief de maat die alles vasthoudt:
60 s werk / 90 s rust / 1 oefening / 8 rondes = 8 × 60 + 7 × 90 = **1110 s =
18:30**, omdat de laatste rust vervalt. Verder: reset alleen *tussen* rondes,
rust 0 geeft alleen werkintervallen, en de klokopmaak.

```bash
xcodebuild test -project Rondo.xcodeproj -scheme Rondo \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Wat hier níet gecontroleerd kon worden

Dit project is geschreven op Linux, zonder macOS, zonder Xcode en zonder
Swift-compiler. **Het is nooit gecompileerd.** Wat wél is nagelopen staat
hieronder; wat niet, staat in het verslag bij de oplevering.

Gecontroleerd:
- `project.pbxproj` geparst met de `pbxproj`-bibliotheek: 42 objecten, elke
  verwijzing lost op, drie targets, de embed-fase draagt de Watch-app.
- Beide `Info.plist`-bestanden geparst met `plistlib`, met de vereiste sleutels.
- De programma-rekenkunde van `Workout.segments` is één-op-één nagerekend in
  Python; alle assertie-waarden in de tests komen daaruit.
- Haakjes- en stringbalans van alle Swift-bestanden.

Niet gecontroleerd: of het compileert, of de Watch-app echt wordt ingebed, of
`WKExtendedRuntimeSession` start met `mindfulness` als achtergrondmodus, of
`Archivo` onder de familienaam "Archivo" registreert, en of één
gesynchroniseerde map (`Rondo/Shared`) in twee targets tegelijk door Xcode 16
wordt geaccepteerd zoals hier geschreven. Werkt dat laatste niet, dan is
`xcodegen generate` de uitweg.
