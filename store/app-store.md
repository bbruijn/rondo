# App Store-teksten voor Rondo

Alles hieronder is klaar om te plakken in App Store Connect. De getallen
tussen haakjes zijn de lengte en de limiet van Apple.

## Algemeen (geldt voor beide talen)

| Veld | Waarde |
| --- | --- |
| Primaire taal | English (U.S.) |
| Extra taal | Dutch |
| Categorie | Health & Fitness |
| Leeftijd | 4+ (alle vragen "None") |
| Prijs | Gratis |
| Privacy Policy URL | https://rondo.webbart.nl/privacy.html |
| Support URL | https://rondo.webbart.nl/support.html |
| Marketing URL | https://rondo.webbart.nl |
| Copyright | 2026 Bart de Bruijn |
| App Privacy | Data Not Collected |

## English (U.S.)

**Name** (5/30)

```
Rondo
```

**Subtitle** (24/30)

```
Interval timer as a ring
```

**Promotional text** (133/170)

```
See your whole workout before you start. One ring, one arc per interval, thick for work and thin for rest. On iPhone and Apple Watch.
```

**Keywords** (99/100)

```
hiit,tabata,workout,rounds,circuit,training,rest,stopwatch,fitness,emom,gym,boxing,sprint,countdown
```

**Description** (958/4000)

```
Rondo shows your workout as a single ring instead of a list of blocks. Each arc is one interval: thick for work, thin for rest. You see the rhythm of a session before it begins, and while you train the ring follows the clock.

SET UP IN SECONDS
• Work and rest times
• Rounds, and how many work-rest pairs make up a round
• An optional longer break between rounds
• Save the workouts you use often

HEAR IT OVER YOUR MUSIC
Signals sound at every change and count down the last three seconds. They play over your music instead of pausing it, and keep going with the screen locked.

ON YOUR WRIST
The Apple Watch app fills the display with the ring and marks every change with a tap on your wrist. Settings and start and pause carry over between iPhone and Watch.

NOTHING COLLECTED
No account, no ads, no tracking. Your settings stay on your device.

Rondo is named after the musical form in which a refrain keeps returning. That is what interval training is.
```

**What's New**

```
First release.
```

## Nederlands

**Name** (5/30)

```
Rondo
```

**Subtitle** (22/30)

```
Intervaltimer als ring
```

**Promotional text** (132/170)

```
Zie je hele training voordat je begint. Eén ring, één boog per interval, dik voor arbeid en dun voor rust. Op iPhone en Apple Watch.
```

**Keywords** (94/100)

```
hiit,tabata,training,rondes,circuit,rust,stopwatch,fitness,sporten,emom,boksen,sprint,aftellen
```

**Description** (1032/4000)

```
Rondo laat je training zien als één ring in plaats van een lijst met blokken. Elke boog is een interval: dik voor arbeid, dun voor rust. Je ziet het ritme van je training voordat je begint, en tijdens het trainen loopt de ring mee met de klok.

IN EEN PAAR TELLEN INGESTELD
• Arbeid- en rusttijd
• Rondes, en hoeveel arbeid-rust-paren er in een ronde zitten
• Een langere pauze tussen rondes, als je dat wilt
• Bewaar de trainingen die je vaak doet

DOOR JE MUZIEK HEEN
Bij elke wissel klinkt een signaal, en de laatste drie seconden worden afgeteld. De signalen klinken door je muziek heen in plaats van die te pauzeren, ook met het scherm op slot.

OP JE POLS
De Apple Watch-app vult het scherm met de ring en geeft elke wissel aan met een tik op je pols. Instellingen en starten en pauzeren gaan mee tussen iPhone en Watch.

NIETS VERZAMELD
Geen account, geen reclame, geen tracking. Je instellingen blijven op je toestel.

Rondo is genoemd naar de muziekvorm waarin een refrein steeds terugkeert. Dat is wat intervaltraining is.
```

**What's New**

```
Eerste versie.
```

## App Review Information: Notes

Plak dit in het veld **Notes** onder App Review Information. Het legt uit
waarom de app op de achtergrond audio gebruikt; dat is het punt waar een
reviewer het eerst naar vraagt.

```
Rondo is an interval training timer for iPhone and Apple Watch.

HOW TO TEST
1. Open the app. The ring shows the whole workout. Tap the ring to start; tap again to pause.
2. Tap a setting below the ring (Work, Rest, Per round, Rounds) to change it. With "Per round" above 1, a "Break" setting appears.
3. To hear the signals quickly: set Work to 0:05 and Rest to 0:05, then start.

BACKGROUND AUDIO
The app declares the audio background mode because its purpose is to give audible signals during a workout: a tone at every change between work and rest, and a three-second countdown before each change. People train with the phone in a pocket or with the screen locked, usually with music playing, so the signals have to keep sounding in the background.
- The audio session uses the playback category with mixWithOthers, so the signals play over the user's music and never interrupt it.
- The audio session is only active while a workout is running. It is released when the workout is paused, reset or finished.
To verify: start music in another app, start a workout in Rondo, lock the screen. The signals are heard over the music at each change.

APPLE WATCH
The Watch app shows the same ring and gives a haptic at every change. It starts an extended runtime session while a workout is running, so the timer continues when the wrist is lowered, and ends it when the workout stops. The app does not use HealthKit.

DATA
The app makes no network requests and collects no data. Settings are stored on the device and synced between iPhone and Watch with WatchConnectivity.

No account or login is needed.
```

## Schermafbeeldingen

Apple vraagt ze per apparaattype. App Store Connect toont bij het uploaden
welke afmetingen het accepteert.

- **iPhone:** maak ze in de simulator van de grootste iPhone (Cmd-S bewaart
  een schermafbeelding op ware grootte).
- **Apple Watch:** idem in de Watch-simulator.
- Maak ze in beide talen: zet de simulator op Engels voor de Engelse
  pagina en op Nederlands voor de Nederlandse.

Goede momenten om vast te leggen: de ring vóór de start, een lopend
arbeidsinterval, een lopend rustinterval, het instelscherm, en op de Watch
arbeid, rust en het eindscherm.
