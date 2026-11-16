# Rondo — huisstijl

Een *rondo* is een muziekvorm waarin een refrein steeds terugkeert tussen
contrasterende episodes: A-B-A-C-A. Dat ís intervaltraining. En "ronde" zit
er in het Nederlands gratis in.

De hele huisstijl volgt uit één beeld: **de training is een partituur, en de
partituur is een cirkel.**

## Het idee: de cirkelpartituur

Niet een lijst met blokken en een aftellende klok, maar één ring waarin de
hele training al zichtbaar is vóór je begint.

- Elke boog in de ring is één interval; de lengte van de boog is de duur.
- **Arbeidsbogen zijn dik, rustbogen zijn dun.** Daardoor lees je het ritme van
  de training in één oogopslag — een zware training ziet er zwaar uit.
- Afgelopen bogen doven naar 20%, de lopende boog is vol en iets dikker,
  komende bogen zijn haarlijnen.
- De voortgang reist langs de ring. Niets schuift in beeld, niets springt.

Eén beeld, drie platforms: op de Watch vult de ring het scherm, op de iPhone
staat hij boven de instellingen, op het web staat hij naast de instellingen.

## Kleur

Twee stemmen die elkaar afwisselen, op inkt of op papier.

| Rol | Hex | Gebruik |
| --- | --- | --- |
| Inkt | `#101217` | achtergrond (donker) |
| Inkt verhoogd | `#191C23` | kaarten, chips |
| Bot | `#F2EFE8` | tekst op inkt, achtergrond (licht) |
| Puls | `#FF2E63` | arbeid |
| Diep | `#00C2A8` | rust |
| Amber | `#FFB443` | ronde-reset |

Op papier worden puls en diep een tint dieper zodat ze leesbaar blijven:
`#E31B50` en `#00897B`.

Regels:
- Nooit meer dan één accentkleur tegelijk op het scherm. De fase bepaalt welke.
- Accenten zijn voor de ring, het cijfer en één label. Niet voor vlakken.
- Geen verlopen, geen glas, geen schaduwen, geen gloed.

## Typografie

Eén familie, twee stemmen — net als het rondo zelf. **Archivo** (variabel,
Google Fonts), met de breedte-as als verschil.

- **Cijfers:** Archivo, `wdth 85`, gewicht 600, `tabular-nums`,
  letterafstand −0.02em. Groot, smal en zwaar — zodat 00:42 op een
  Watch-scherm net zo leesbaar is als op een telefoon.
- **Labels:** Archivo, `wdth 100`, gewicht 700, hoofdletters, +0.14em.
  Klein en rustig; ze mogen het cijfer nooit beconcurreren.
- Lopende tekst: Archivo, gewicht 400.

## Beweging

Eén regel: **verandering reist, hij verschijnt niet.**

- Fasewissel: kleur kruisvervaagt in 400 ms, de ring springt niet.
- De lopende boog ademt subtiel (2 s cyclus) zodat je ziet dat hij loopt.
- `prefers-reduced-motion` zet alles stil behalve de voortgang zelf.

## Toon

Nederlands, kort, geen uitroeptekens. Arbeid, Rust, Ronde, Klaar. De app
spreekt als een coach die naast je staat, niet als een app die juicht.
