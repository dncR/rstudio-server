# SSH Remote Docker: R ve renv Notlari

Bu not, local makinede calisan bir Docker container'a SSH ile baglanip VS Code / Antigravity uzerinden R kullanirken `renv` ve VS Code R entegrasyonu arasindaki startup zincirini netlestirmek icin hazirlandi.

Bu dokumanin amaci iki seyi ayirmaktir:

- `renv` kutuphane / lockfile problemleri
- VS Code R session attach / `.vsc.attach()` problemleri

Bu iki konu bazen ayni anda gorunur, ama ayni problem degildir.

## Hedef Senaryo

- Host: local makine
- Remote: Docker container
- Baglanti: SSH Remote
- Editor: VS Code / Antigravity
- R kullanim tipi:
  - normal R klasoru
  - `renv` kullanan proje klasoru

## Ana Problem

VS Code R entegrasyonu icin gereken `.vsc.attach()` gibi yardimci fonksiyonlar sadece uygun startup zinciri calisinca olusur.

Tipik hata:

```r
.vsc.attach()
Error in .vsc.attach() : could not find function ".vsc.attach"
```

Bu hata genelde su nedenlerden biriyle olur:

- R oturumu VS Code terminali disinda acilmistir
- `~/.Rprofile` hic yuklenmemistir
- proje kokundeki `.Rprofile`, home altindaki `~/.Rprofile` dosyasini golgelemistir
- `renv` proje startup akisi editor init zincirini eksik birakmistir

## Teshis Sonucu: Gercek Fark Nedir?

Bu senaryoda temel fark dogrudan `macOS` ile `Ubuntu` farki degildir. Asil fark, R oturumunun hangi startup zinciriyle acildigidir.

Teshiste netlesen noktalar:

- proje kokundeki `.Rprofile` sadece `source("renv/activate.R")` iceriyorsa, home `~/.Rprofile` cogu durumda otomatik olarak calismaz
- `renv/activate.R`, autoloader aktifken user profile'i ayrica source etmez
- home `~/.Rprofile`, `~/.vscode-R/init.R` dosyasini source eder
- bu init zinciri bazen `.vsc.attach` fonksiyonunu dogrudan olusturmaz; bunun yerine `.First.sys()` hook'unu hazirlar
- sizin home `~/.Rprofile` dosyaniz, gerekirse `try(.First.sys(), silent = TRUE)` fallback'i ile attach zincirini tamamlar
- proje `.Rprofile` home `~/.Rprofile` dosyasini source etmediginde bu fallback hic devreye girmez

Kisa sonuc:

- plain `renv` startup zinciri tek basina her zaman yeterli degildir
- home `~/.Rprofile` icindeki VS Code bootstrap ve fallback mantigi, remote container senaryosunda kritik rol oynar
- bu nedenle `renv` projesi icindeki `.Rprofile` dosyasinin home `~/.Rprofile` dosyasini kosullu olarak source etmesi pratik ve guvenli cozumdur

## `.Rprofile` Yukleme Sirasi Hakkinda Onemli Not

Beklenen ama yanlis olan varsayim:

1. once `~/.Rprofile`
2. sonra proje dizinindeki `.Rprofile`

Pratikte proje kokunde `.Rprofile` varsa, startup davranisi bu varsayim kadar basit degildir. `renv` projelerinde cogu zaman proje `.Rprofile` dosyasi aktif zinciri fiilen devralir ve home `~/.Rprofile` otomatik olarak islenmeyebilir.

Bu nedenle su dosya:

```r
source("renv/activate.R")
```

tek basina kullaniliyorsa, home altindaki VS Code startup ayarlari hic devreye girmeyebilir.

## Home Dizin Icin Onerilen `~/.Rprofile`

Bu varyant, SSH remote + Docker + VS Code / Antigravity senaryosu icin guvenli baslangic ayaridir:

```r
term_program <- tolower(Sys.getenv("TERM_PROGRAM", unset = ""))
is_vscode <- identical(term_program, "vscode")
is_positron <- nzchar(Sys.getenv("POSITRON")) || identical(term_program, "positron")
is_rstudio <- nzchar(Sys.getenv("RSTUDIO"))

if (interactive() && is_vscode && !is_positron && !is_rstudio) {
  vsc_init <- path.expand("~/.vscode-R/init.R")

  if (file.exists(vsc_init)) {
    source(vsc_init, local = globalenv())

    if (!exists(".vsc.attach", envir = globalenv(), inherits = FALSE) &&
        exists(".First.sys", envir = globalenv(), mode = "function", inherits = FALSE)) {
      try(.First.sys(), silent = TRUE)
    }
  }
}
```

### Bu blogun mantigi

- sadece interaktif R oturumlarinda calisir
- sadece VS Code terminalinde devreye girer
- RStudio icinde devreye girmez
- Positron icinde devreye girmez
- `~/.vscode-R/init.R` zincirini yukler
- uzak/container oturumlarinda eksik kalabilen attach hook'unu fallback ile tamamlar

## Normal R Klasoru Senaryosu

Eger proje `renv` icermiyorsa:

- `~/.Rprofile` genelde yeterlidir
- R terminalini VS Code icinden acin
- `R --vanilla` kullanmayin

Kontrol:

```r
exists(".vsc.attach")
search()
```

Beklenen:

- `exists(".vsc.attach")` -> `TRUE`
- `search()` icinde `tools:vscode`

## `renv` Projesi Senaryosu

`renv` projelerinde genelde proje kokunde `.Rprofile` bulunur. Bu dosya cogu zaman sadece asagidaki satiri icerir:

```r
source("renv/activate.R")
```

Bu tek basina yeterli degildir; cunku:

- `renv` aktif olur
- proje library path'leri kurulur
- ama home `~/.Rprofile` dosyasindaki VS Code bootstrap zinciri ve `.First.sys()` fallback'i hic calismayabilir

## Onerilen Proje `.Rprofile`

En guvenli pratik cozum, proje `.Rprofile` dosyasina `renv` aktivasyonundan sonra home `~/.Rprofile` dosyasini kosullu olarak source etmektir.

Onerilen varyant:

```r
source("renv/activate.R")

term_program <- tolower(Sys.getenv("TERM_PROGRAM", unset = ""))
is_vscode <- identical(term_program, "vscode")
is_positron <- nzchar(Sys.getenv("POSITRON")) || identical(term_program, "positron")
is_rstudio <- nzchar(Sys.getenv("RSTUDIO"))

if (interactive() && is_vscode && !is_positron && !is_rstudio && file.exists("~/.Rprofile")) {
  source("~/.Rprofile", local = globalenv())
}
```

### Neden kosullu blok tercih edilmeli?

Kosulsuz:

```r
if (file.exists("~/.Rprofile")) {
  source("~/.Rprofile")
}
```

bircok durumda calisir; ancak bu daha genis etki alanina sahiptir.

Kosullu blok daha iyidir; cunku:

- sadece interaktif oturumlarda calisir
- sadece `TERM_PROGRAM == "vscode"` oldugunda devreye girer
- RStudio / Positron / batch / `Rscript` / CI gibi baska akislara gereksiz yan etki tasimaz
- proje `renv` ayarini editor bootstrap mantigindan ayirmaya yardimci olur

Kisa karar:

- yalnizca size ait, sadece VS Code icin kullanilan kapali remote container kurgusunda kosulsuz varyant da kabul edilebilir
- genel ve tekrar kullanilabilir standart icin kosullu blok tercih edilmelidir

## Neden Sira `renv` Sonra `~/.Rprofile` Olmali?

Onerilen sira:

1. once `renv` proje kutuphane ortamini kurar
2. sonra VS Code / Antigravity entegrasyonu yuklenir
3. gerekiyorsa home `~/.Rprofile` icindeki `.First.sys()` fallback'i attach zincirini tamamlar

Bu siralama sayesinde:

- proje kutuphaneleri aktif olur
- editor watcher gerekli fonksiyonlari gorebilir
- hem `renv` hem editor entegrasyonu ayni oturumda calisir

## `RENV_CONFIG_EXTERNAL_LIBRARIES` Notu

Bu senaryoda asagidaki ayar faydalidir:

```text
RENV_CONFIG_EXTERNAL_LIBRARIES=/usr/local/lib/R/site-library
```

Ornek olarak `~/.Renviron` icinde:

```text
RENV_CONFIG_EXTERNAL_LIBRARIES=/usr/local/lib/R/site-library
```

Bu ayarin amaci:

- `renv` altinda iken site-library paketlerini gorunur kilmak
- `jsonlite`, `rlang`, `httpgd` gibi editor zincirinin veya yardimci araclarin ihtiyac duyabilecegi paketlere erisimi kolaylastirmak

Ama bu ayar sunu garanti etmez:

- `~/.Rprofile` dosyasinin calismasi
- `~/.vscode-R/init.R` zincirinin source edilmesi
- `.vsc.attach()` fonksiyonunun otomatik olusmasi

Yani bu degisken package visibility problemini azaltir; startup zinciri problemini tek basina cozmez.

## `renv` Uyarisi ve `.vsc.attach()` Hatasi Ayni Sey Degil

Sunun gibi bir mesaj:

```text
One or more packages recorded in the lockfile are not installed.
Use `renv::status()` for more details.
```

ayri bir problemdir. Bu, lockfile ile kurulu paketlerin uyusmadigini soyler.

Bu mesaj su hatanin dogrudan sebebi degildir:

```r
.vsc.attach()
Error in .vsc.attach() : could not find function ".vsc.attach"
```

Ilki `renv` durum bilgisidir, ikincisi startup / editor entegrasyonu problemidir.

## Hizli Teshis Akisi

R icinde asagidaki kontrolleri yapin:

```r
interactive()
Sys.getenv("TERM_PROGRAM")
Sys.getenv("RSTUDIO")
Sys.getenv("POSITRON")
Sys.getenv("R_PROFILE_USER")
exists(".vsc.attach")
exists(".First.sys")
search()
.libPaths()
requireNamespace("jsonlite", quietly = TRUE)
requireNamespace("rlang", quietly = TRUE)
```

Yorum:

- `interactive()` -> `TRUE` olmali
- `TERM_PROGRAM == "vscode"` olmali
- `exists(".vsc.attach")` -> `TRUE` olmali
- `search()` icinde `tools:vscode` gorunmeli
- `jsonlite` ve `rlang` gorunur olmali

Eger:

- `TERM_PROGRAM == "vscode"` dogru
- `jsonlite` ve `rlang` gorunur
- ama `.vsc.attach == FALSE`

ise sorun buyuk ihtimalle package eksikligi degil, startup zincirinin eksik kalmasidir.

## Tipik Davranis Kombinasyonlari

### Durum 1: Normal klasor + `~/.Rprofile`

Beklenen:

- `tools:vscode` attach olur
- `.vsc.attach` bulunur

### Durum 2: `renv` proje + sadece `source("renv/activate.R")`

Beklenen risk:

- `renv` aktif olur
- `renv:shims` gorunur
- ama `.vsc.attach` olmayabilir

### Durum 3: `renv` proje + kosullu `source("~/.Rprofile")`

Beklenen sonuc:

- `renv` aktif olur
- home profile zinciri calisir
- gerekiyorsa `.First.sys()` fallback'i attach'i tamamlar
- `tools:vscode` gorunur

## `renv` Problemlerini Duzeltme

R icinde:

```r
renv::status()
renv::restore()
```

Gerekirse:

```r
renv::diagnostics()
renv::repair()
```

Not:

- `renv::restore()` lockfile uyumsuzlugunu hedefler
- `renv::repair()` cache / symlink bozulmalarinda yardimci olabilir
- bunlar attach zinciri problemini otomatik olarak cozmez

## Kacinilmasi Gerekenler

- `~/.Rprofile` icine `rm(list = ls())` koymayin
- VS Code disinda acilan plain shell oturumunu VS Code oturumu gibi zorlamayin
- proje `.Rprofile` varsa `~/.Rprofile` nasil olsa otomatik calisir varsayimina guvenmeyin
- `R --vanilla` ile acilan oturumlarda profile davranisinin degisecegini unutmayin
- `RENV_CONFIG_EXTERNAL_LIBRARIES` ayarinin attach problemini tek basina cozecegini varsaymayin
- her ortama kosulsuz `source("~/.Rprofile")` ekleyip yan etkileri yok saymayin

## Onerilen Standart

1. Home altinda tek bir referans `~/.Rprofile` tutun
2. Bu dosyada `~/.vscode-R/init.R` source ve gerekiyorsa `.First.sys()` fallback mantigini bulundurun
3. `renv` projelerinde proje `.Rprofile` icine once `source("renv/activate.R")`, sonra kosullu home profile source blogunu ekleyin
4. R terminalini VS Code / Antigravity icinden acin
5. `~/.Renviron` icinde gerekirse `RENV_CONFIG_EXTERNAL_LIBRARIES=/usr/local/lib/R/site-library` tanimlayin
6. Lockfile uyumsuzluklari icin `renv::restore()` calistirin

## Pratik Sonuc

Bu senaryoda pratik olarak en saglam yaklasim sudur:

- home `~/.Rprofile` dosyasini VS Code bootstrap icin merkez yapin
- `renv` proje `.Rprofile` dosyasina kosullu home profile source blogunu standart snippet olarak ekleyin
- startup zinciri problemini package visibility probleminden ayri degerlendirin

## Kisa Ozet

- normal klasorlerde `~/.Rprofile` genelde yeterlidir
- `renv` projelerinde proje `.Rprofile`, home profile zincirini golgeleyebilir
- `RENV_CONFIG_EXTERNAL_LIBRARIES` faydalidir ama attach problemini tek basina cozmez
- remote Docker + SSH senaryosunda kritik nokta, home `~/.Rprofile` icindeki VS Code bootstrap ve `.First.sys()` fallback'inin calisabilmesidir
- bu nedenle `renv` proje `.Rprofile` dosyasina kosullu `source("~/.Rprofile")` blogu eklemek en pratik standart cozumdur
