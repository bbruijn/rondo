# Rondo

Intervaltraining voor iPhone, Apple Watch en het web — als **cirkelpartituur**.

Een *rondo* is een muziekvorm waarin een refrein steeds terugkeert tussen
contrasterende episodes. Dat is precies wat intervaltraining is, en "ronde"
zit er in het Nederlands gratis in.

## Het idee

Niet een lijst met blokken en een aftellende klok, maar één ring waarin de
hele training al zichtbaar is vóór je begint. Elke boog is één interval;
**werkbogen zijn dik, rustbogen dun**, dus je leest het ritme van je training
in één oogopslag. De lopende boog kleurt mee met de fase en krimpt met de
klok; wat je gehad hebt, verstilt tot streepjes.

Zie [`BRAND.md`](BRAND.md) voor de volledige huisstijl, en
[`design/`](design/) voor de interface-concepten.

## Wat er in zit

| Map | Wat |
| --- | --- |
| `web/` | De webapp (PWA): offline, installeerbaar, licht en donker |
| `ios/` | De iPhone- en Apple Watch-app (SwiftUI) |
| `design/` | Interface-concepten, gegenereerd met ElevenLabs |

## De rekenwijze

Een ronde bestaat uit een aantal **werk-rust-paren** — dat aantal is de
instelling *Per ronde*. Na een hele ronde kan er een **pauze** staan: extra
rust bovenop de gewone rust, alleen tussen rondes in. **De laatste rust
vervalt** — de training eindigt op werk.

Met *Per ronde* op 1 vallen "einde interval" en "einde ronde" samen; de pauze
voegt dan niets toe en is daarom verborgen zolang hij op nul staat.

Voorbeeld: 01:00 werk, 01:30 rust, 1 per ronde, 8 rondes
→ `8 × (60 + 90) − 90 = 1110 s = 18:30`.

Alle drie de platforms rekenen zo, zodat dezelfde training overal hetzelfde
totaal geeft.

## Web lokaal draaien

```bash
cd web
python3 -m http.server 8000
```

## Live

De webversie staat op **https://rondo.webbart.nl** (en op
`https://bbruijn.github.io/rondo/`). Elke push naar `main` die `web/`
raakt, publiceert opnieuw via GitHub Actions.

Op je telefoon: open die URL in Safari → deelknop → **Zet op beginscherm**.
Dan draait hij schermvullend en offline.
