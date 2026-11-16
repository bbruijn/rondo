# Briefing: de eerste build van Rondo op een Mac

Dit bestand is geschreven voor een Claude Code-sessie die op de Mac van de
eigenaar draait, met Xcode. Lees het helemaal voordat je iets verandert.

De code in `ios/` is geschreven in een omgeving **zonder macOS en zonder
Swift-compiler**. Hij is dus nooit gecompileerd. Dat is geen slordigheid maar
een bekend gegeven: jouw taak is de eerste build rond krijgen.

---

## 1. Wat Rondo is

Een intervaltimer voor een tiener die thuis traint. Drie platforms, één idee:
**de training is een cirkelpartituur.** Eén ring, één boog per interval,
booglengte is duur, werkbogen dik en rustbogen dun — zodat je het ritme van
een training ziet vóór je begint.

- `web/` — de webversie. **Draait al live op https://rondo.webbart.nl.** Niet
  aankomen tenzij daar expliciet om gevraagd wordt.
- `ios/` — iPhone- en Apple Watch-app. Jouw werkterrein.
- `BRAND.md` — de huisstijl. Bindend.
- `design/` — de interface-concepten waar de bouw op volgt.

## 2. Wat je niet mag omgooien

1. **De huisstijl.** Kleuren, typografie en de dial liggen vast in `BRAND.md`.
   Los compileerfouten op; herontwerp niets.
2. **De programmaregel.** Per ronde krijgt elke oefening werk + rust; tussen
   rondes eventueel een reset; **de laatste rust vervalt.** Daardoor geldt
   60 s werk / 90 s rust / 1 oefening / 8 rondes = **exact 18:30**. Dat getal
   is de vertrouwde training van de gebruiker en staat in
   `RondoTests/WorkoutProgramTests.swift`. Als een refactor dat getal
   verandert, is de refactor fout.
3. **De audio-aanpak in `AudioCoach.swift`.** Die komt uit V1 en is op een
   echte iPhone bevochten:
   - `AVAudioSession.playback` met **`.mixWithOthers`** — de piepjes moeten
     dóór Spotify heen, niet in plaats van.
   - **Nooit `.duckOthers`.** Dat zet de muziek de hele training zachter in
     plaats van alleen tijdens een piep.
   - De lopende stille buffer houdt de achtergrond-audiosessie open; zonder
     die buffer stopt de timer zodra het scherm op slot gaat.
   Het ging in V1 twee keer mis op precies deze punten. Verander er niets aan
   zonder dat een echte test op een toestel daarom vraagt.
4. **De klok.** `WorkoutEngine` rekent met absolute `Date`-deadlines, niet met
   opgetelde tikken, en onderdrukt signalen bij meer dan 1,5 s achterstand.
   Een timer die optelt loopt weg zodra iOS de app even minder aandacht geeft.

## 3. Wat al nagerekend is (en dus waarschijnlijk niet je probleem)

- `Rondo.xcodeproj/project.pbxproj` parseert; 42 objecten, elke verwijzing
  lost op, drie targets (`Rondo`, `Rondo Watch App`, `RondoTests`).
- Beide `Info-*.plist` parseren en dragen hun sleutels: `UIBackgroundModes`
  `[audio]` op iOS, `WKApplication` + `WKCompanionAppBundleIdentifier` op de
  Watch, `UIAppFonts` in allebei.
- De bundle-ids kloppen onderling: watch = iOS-id + `.watchkitapp`.
- De programma-rekenkunde is onafhankelijk nagerekend, inclusief 18:30.
- Alle 18 Swift-bestanden zijn haakjes-gebalanceerd.

## 4. Wat níét geverifieerd is — begin hier als het misgaat

Op volgorde van risico:

1. **Eén gedeelde bronmap in twee targets.** `Rondo/Shared` zit als
   `PBXFileSystemSynchronizedRootGroup` in zowel de iOS- als de Watch-target.
   Het formaat accepteert het, maar of Xcode het zo teruglezt is ongetest.
   Ontbreken de gedeelde bestanden in één target: draai
   `xcodegen generate` met de meegeleverde `project.yml` (klassieke expliciete
   bestandslijsten) en bouw opnieuw.
2. **Actor-isolatie.** `MainActor.assumeIsolated` wordt gebruikt rond
   WatchKit-aanroepen en de `DispatchSource`-tick. Verwacht waarschuwingen of
   fouten over isolatie, en over het `@MainActor`-closuretype in
   `SyncLink.onReceive`.
3. **Fontregistratie.** Archivo zit als variabele TTF in de bundel; de
   typografische familie is "Archivo" maar nameID 1 is "Archivo SemiBold".
   `RondoType` probeert vier namen en valt terug op het systeemfont. Als de
   cijfers er niet smal-en-zwaar uitzien, zijn de variatieassen (`wdth 85`)
   niet toegepast — dat is cosmetisch, niet blokkerend.
4. **`WKExtendedRuntimeSession`.** `WKBackgroundModes: [mindfulness]` staat in
   de watch-plist. Start de sessie niet, dan loopt de timer op de Watch alleen
   door met het scherm aan. Noteer dat, forceer het niet.
5. **SwiftUI-signaturen die niemand kon compileren**, met name: `Canvas` met
   `inout GraphicsContext`, `Path.addArc(clockwise:)` voor kloksgewijs
   tekenen, `Animatable` op een `View` die ook `@Environment` heeft (daarom
   staat er een expliciete `init`), `TimelineView(.animation(...))`,
   `.tabViewStyle(.verticalPage)` en `Stepper(value:in:step:)` op watchOS, en
   de `Text`-extensies met `.textCase`/`.tracking`.

## 5. Bouwen

```bash
cd ios

# Compileert het überhaupt? Simulator eerst — geen signing nodig.
xcodebuild -project Rondo.xcodeproj -scheme Rondo \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -40

xcodebuild -project Rondo.xcodeproj -scheme 'Rondo Watch App' \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build 2>&1 | tail -40

# De rekenkunde moet groen blijven
xcodebuild -project Rondo.xcodeproj -scheme Rondo \
  -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | tail -20
```

Werk de fouten één voor één weg en bouw opnieuw. Kleine, gerichte reparaties;
geen herschrijvingen.

### Signing

De eigenaar heeft een betaald Apple Developer-account. Vraag om het **Team
ID** (tien tekens, staat in App Store Connect onder Membership) en zet het in
beide app-targets:

```
DEVELOPMENT_TEAM = <TEAMID>
CODE_SIGN_STYLE = Automatic
```

Bundle-ids staan al op `nl.webbart.rondo` en `nl.webbart.rondo.watchkitapp`.

### Op het toestel

Aansluiten, ontgrendelen, vertrouwen, en Developer Mode aan op de telefoon
(Instellingen → Privacy en beveiliging → Ontwikkelaarsmodus). De Watch-app
verschijnt daarna in de Watch-app van diezelfde iPhone om te installeren; de
Watch moet aan die telefoon gekoppeld zijn.

## 6. Wat "klaar" betekent

Niet "het compileert". Klaar is:

- [ ] Beide targets bouwen zonder fouten, tests groen (18:30 inbegrepen)
- [ ] De app draait op een echte iPhone en de ring loopt zichtbaar mee
- [ ] De Watch-app staat op de Watch en de ring vult het scherm
- [ ] **Zet Spotify aan en start een training:** de muziek blijft spelen en de
      piepjes komen eroverheen. Dit is de reden dat deze app bestaat
- [ ] Scherm op slot tijdens een training: het geluid loopt door
- [ ] De Watch trilt bij elke fasewissel en bij het aftellen 3-2-1
- [ ] Belschuifje op stil: de piepjes klinken nog steeds

Lukt een vinkje niet, schrijf dan op wat er precies gebeurde. Niet gladstrijken.

## 7. TestFlight

De app is voor de dochter van de eigenaar, op haar eigen telefoon. TestFlight
is daarvoor de route: zij installeert zelf, updates komen draadloos.

Upload met een **App Store Connect API-key** (`.p8`), nooit met het Apple
ID-wachtwoord van de eigenaar. Vraag erom als je zover bent.

> Commit die `.p8` nooit. `*.p8` staat in `.gitignore`; houd dat zo.

## 8. Terugkoppelen

Werk op een eigen branch en push als het bouwt. Zet in de pull request wat je
hebt moeten repareren en welke vinkjes uit paragraaf 6 je echt op een toestel
hebt gezien — en welke niet.
