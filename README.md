# Roso Games Templatet

> **In English:** This repository holds the source of the Roso Games Templates: three Solar2D game templates (visual novel, platformer and top-down adventure) and the shared core they are built on. Roso Games is a free learning and game development project run by Roso-tuotanto in Finland for young adults aged 18 to 35, and its groups build their games on these templates. The rest of this README is in Finnish. The code comments and the manuals inside the templates are in English. Licensed under [MIT](LICENSE).

Tämä repositorio on osa Roso Games -projekteja. Täällä ovat Roso Games Templatejen lähdekoodit: kaikille templateille yhteinen pohja RG CORE ja kolme sen päälle rakennettua templatea. Build-skripti yhdistää coren ja yhden templaten Solar2D-projektiksi, jonka pohjalta Roso Games -ryhmä alkaa tehdä omaa peliään.

Tämä README on suomeksi. Koodin kommentit sekä templatejen omat ohjeet ja dokumentaatio ovat englanniksi.

## Roso Games

Roso Games on Roso-tuotannon toteuttama oppimis- ja pelinkehitysprojekti, joka on suunnattu 18-35-vuotiaille peleistä ja pelaamisesta kiinnostuneille nuorille aikuisille. Osallistuminen on maksutonta, eikä aiempaa osaamista tarvita.

Projekti kestää lokakuusta toukokuuhun. Osallistujat käyvät ensin kurssit [oppimisympäristössä](https://www.rosogames.fi/opetus), pitchaavat peli-ideansa ja tekevät sitten ryhmänä yhden yhteisen 2D-pelin Solar2D:llä ja Lualla. Peli tehdään jonkin tämän repositorion templaten pohjalle ja julkaistaan lopuksi itch.io:ssa.

## Templatet

| Template | Millaisen pelin pohja se on |
| --- | --- |
| `visual-novel` | Visual novel: haarautuva tarina taustakuvineen ja hahmoineen. Esimerkkitarina esittelee tarinakomennot, hahmon ilmeen vaihtamisen ja tarinan sisällä pelattavan minipelin. Hahmo antaa pelaajalle esineen inventoryyn, joka aukeaa ruudun kulmassa olevasta napista tai I-näppäimellä. Napin vieressä näkyy pelaajan rahamäärä, joka muuttuu tarinan aikana. |
| `platformer` | Tasohyppely: kaksoishyppy, köysissä kiipeäminen, trampoliini, piikit, tasot, joiden läpi voi hypätä alta, inventory ja näppäinohje. Esimerkissä on kolme aluetta, joiden välillä kuljetaan ovista. Kamera seuraa pelaajahahmoa paitsi kolmannella alueella, joka on pieni huone ja mahtuu kokonaan ruutuun. Huoneessa on hahmo, jonka kanssa voi keskustella. Hän pyytää pakettia, joka on ulkona kaikkein korkeimmassa kohdassa. |
| `top-down` | Top-down-seikkailu: Tiledillä tehdyt kartat, hahmot, joiden kanssa voi keskustella, inventory ja siirtyminen kartalta toiselle. Esimerkissä on kolme karttaa ja keskustelu, jossa lukittu ovi aukeaa, kun hahmolle antaa esineen. |

Mikään template ei ole valmis peli. Jokaisessa on pieni esimerkkisisältö harmailla placeholder-grafiikoilla. Ryhmä vaihtaa sen tilalle oman sisältönsä.

Buildatussa projektissa on templaten lisäksi aina mukana core. Templaten oma `README.md` on ohje, joka tulee buildatun projektin mukana.

## Käyttö

### Projektin buildaaminen

1. Aja `build.bat` (Windows) tai `sh build.sh` (macOS ja Linux).
2. Valitse numerolla, mitä buildataan: `1` kaikki templatet, `2` visual-novel, `3` platformer tai `4` top-down. `build.bat` reagoi heti näppäimen painallukseen. `build.sh`:ssa paina numeron jälkeen Enter.
3. Skripti poistaa ensin vanhan `dst/<template>/`-kansion ja tekee tilalle kaksi kansiota. `game/`-kansioon se kopioi coren `game/`-kansion sisällön ja sen päälle templaten `game/`-kansion sisällön. `developmentFiles/`-kansioon se kopioi coren ja templaten `developmentFiles/`-kansioiden sisällön.
4. Valikko palaa jokaisen buildin jälkeen. Buildaa lisää tai sulje skripti valitsemalla `5`.
5. Avaa `dst/<template>/game/main.lua` Solar2D-simulaattorissa, niin projekti käynnistyy.

### Projektin antaminen ryhmälle

1. Buildaa ryhmän valitsema template.
2. Poista tiedosto `dst/<template>/game/data/launchParams.json`, jos se on olemassa. Siinä ovat omat testausasetuksesi. Build kopioi sen mukaan samalla tavalla kuin muutkin tiedostot.
3. Kopioi `dst/<template>/game/`-kansion sisältö ryhmän repositorion `game`-kansioon. Templaten `README.md` korvaa kansiossa valmiina olevan `README.md`-tiedoston.
4. Kopioi `dst/<template>/developmentFiles/`-kansion sisältö ryhmän repositorion `developmentFiles`-kansioon. Uudet tiedostot ja kansiot tulevat valmiina olevien rinnalle, eikä mikään valmiina oleva tiedosto korvaudu.

Tämän jälkeen ryhmän projekti on itsenäinen: tähän repositorioon tehty korjaus ei päivity ryhmän peliin.

### Coren tai templaten muokkaaminen

Tee muutokset aina `src/`-kansioon. `dst/`-kansioon tehdyt muutokset katoavat seuraavassa buildissa.

## Rakenne

- [`src/core/game/`](src/core/game/README.md) sisältää coren (RG CORE): kokonaisen Solar2D-projektin, jonka voi ajaa sellaisenaan. Siinä ovat valmiina kaikkien templatejen käyttöön muun muassa päävalikko, asetukset, save slotit, taustamusiikki, kontrollit, inventory, Story Weaver -tarinaan perustuvat keskustelut ja näppäinohje. Sen `scenes/game.lua` on tyhjä pohja, jonka jokainen template korvaa omallaan.
- `src/core/developmentFiles/` sisältää coren moduulien dokumentaation (`docs/`).
- Templatet ovat kansioissa `src/templates/<nimi>/`: [`visual-novel`](src/templates/visual-novel/game/README.md), [`platformer`](src/templates/platformer/game/README.md) ja [`top-down`](src/templates/top-down/game/README.md). Jokainen template on jaettu samalla tavalla: projektin tiedostot ovat `game/`-kansiossa ja moduulien dokumentaatio `developmentFiles/docs/`-kansiossa. Jokaisessa templatessa on lisäksi Twine-tarinatiedosto `developmentFiles/story/`-kansiossa.
- Template ei toimi yksinään, koska siinä ovat vain ne tiedostot, jotka se lisää coren päälle tai joilla se korvaa coren tiedoston.
- Moduulien dokumentaatio tulee buildatun projektin mukana kansioon `dst/<template>/developmentFiles/docs/`.
- [`src/images/`](src/images/README.md) sisältää coren ja templatejen kuvien SVG-lähdetiedostot sekä skriptin, joka tekee niistä pelien käyttämät PNG-kuvat. Ohjeet ovat kansion README:ssä, joka on englanniksi.
- `dst/` on kansio, johon buildit tehdään. Se ei ole mukana versionhallinnassa.
- `build.bat` ja `build.sh` ovat build-skriptit.

## Templatejen säännöt

1. Template toimii vain coren päällä. Älä kopioi coren tiedostoja templateen: silloin samasta tiedostosta on kaksi kopiota, jotka alkavat erota toisistaan.
2. Sama tiedosto saa olla sekä coressa että templatessa vain silloin, kun templaten on tarkoitus korvata coren versio. Jokainen template korvaa nämä viisi tiedostoa, jotka kaikki ovat `game/`-kansiossa: `scenes/game.lua`, `data/settingsTemplate.lua`, `data/credits.lua`, `README.md` ja päävalikon taustakuva `assets/images/ui/menu.png`. Inventorya käyttävä template korvaa lisäksi tiedoston `data/items.lua`, jossa sen esineet luetellaan. Kaikki kolme templatea käyttävät inventorya.
3. Oma koodi, joka ei kuulu vain yhteen pelityyppiin, kuuluu coreen, vaikka aluksi vain yksi template tarvitsisi sitä.
4. Templaten äänet ja grafiikat sekä ne kolmansien osapuolten kirjastot, joita vain templatet käyttävät, ovat templaten omassa kansiossa. Jos kaksi templatea käyttää samaa tällaista kirjastoa, kummassakin on siitä oma kopio. Coren oman koodin käyttämät kirjastot, kuten Story Weaver, ovat coressa. Kaikkien templatejen käyttämä fontti on coren `assets/fonts/`-kansiossa. Fontti valitaan tiedostossa `data/settingsCore.lua`.

## Uuden templaten lisääminen

1. Luo kansio `src/templates/<nimi>/game/`. Siihen tulevat templaten projektitiedostot, myös kaikki tiedostot, jotka lisäät vaiheissa 2-5.
2. Lisää `data/settingsTemplate.lua`, jossa ovat templaten omat asetukset, esimerkiksi päävalikon napit ja kontrollit. Ne yhdistetään coren asetuksiin (`data/settingsCore.lua`) niin, että templaten arvot korvaavat coren arvot. Yhdistämisen säännöt ovat [coren README:ssä](src/core/game/README.md).
3. Lisää `scenes/game.lua`, päävalikon taustakuva `assets/images/ui/menu.png` sekä templaten omat scenet, luokat, datatiedostot ja assetit. Jos template käyttää inventorya, sen esineet tulevat tiedostoon `data/items.lua`.
4. Kopioi coren `data/credits.lua` templateen ja vaihda siihen templaten krediitit, myös ne, joita kolmansien osapuolten assetit vaativat. Säilytä tiedoston `config`-taulukko, koska krediittinäkymä ei toimi ilman sitä.
5. Lisää kansioon `src/templates/<nimi>/game/` tiedosto `README.md`, joka on templaten ohje ryhmille.
6. Kirjoita templaten omien moduulien dokumentaatio kansioon `src/templates/<nimi>/developmentFiles/docs/`.
7. Lisää template kummankin build-skriptin valikkoon ja vaihtoehtoon `1` (kaikki templatet). Templatejen nimet on kirjoitettu suoraan kumpaankin skriptiin. Exit-vaihtoehdon numero kasvaa samalla yhdellä, joten päivitä myös `build.bat`:n `choice`-rivi ja `errorlevel`-tarkistukset sekä tämän README:n numerot.
8. Buildaa template ja testaa se Solar2D-simulaattorissa. Tarkista lopuksi, että template korvaa coren tiedostoista vain säännössä 2 luetellut tiedostot.

## Tekijä

[© 2025-2026 Eetu Rantanen](https://www.erantanen.com)

Templatet on tehty Roso-tuotannon Roso Games -projekteja varten.

## Lisenssi

[MIT](LICENSE)

Roso Gamesia varten kirjoitetun koodin tekijänoikeudet kuuluvat Eetu Rantaselle ja Roso Gamesille (Kukunori ry). Muualta tulevat kirjastot, fontit, grafiikat ja äänet sekä niiden lisenssit on lueteltu [NOTICE.md](NOTICE.md)-tiedostossa.
