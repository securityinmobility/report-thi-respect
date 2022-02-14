---
title: Respect@THI App Vulnerabilities
author: Jakob Löw, Dominik Bayerl
date: 10.02.2022
documentclass: scrartcl
classoption:
    - 12pt
    - a4paper
    - final
    - oneside
geometry:
    - a4paper
    - left=3.5cm
    - right=2.5cm
    - top=3cm
    - bottom=2cm
    - headheight=2.5cm
    - headsep=0.5cm
    - footskip=1cm
mainfont: DejaVu Serif
monofont: DejaVu Sans Mono
titlegraphic: thi_logo.eps
header-includes: |
    \usepackage[onehalfspacing]{setspace}
    \usepackage{parskip}

    \newcommand{\HRule}{\rule{\linewidth}{0.5mm}}
    \renewcommand{\sectionmark}[1]{\markboth{\thesection \ #1}{}}
    \renewcommand{\subsectionmark}[1]{\markright{\thesubsection\ #1}}
    \newcommand{\sectionnumbering}[1]{
        \setcounter{section}{0}
        \renewcommand{\thesection}{\csname #1\endcsname{section}}
    }
    \pagenumbering{arabic}
    \sectionnumbering{arabic}

    \usepackage[headsepline,footsepline]{scrlayer-scrpage}
    \pagestyle{scrheadings}
    \ihead{\includegraphics[height=2cm]{thi_logo.eps}}
    \chead{}
    \ohead{\leftmark}
    \ifoot{}
    \cfoot{}
    \ofoot{\thepage}

    \providecommand{\versionortoday}{\today}

    \lstset{
    basicstyle=\ttfamily,
    columns=fullflexible,
    frame=single,
    breaklines=true,
    postbreak=\mbox{\textcolor{red}{$\hookrightarrow$}\space},
    }
...

# Einführung
An der THI wurde eine neue App entwickelt, die "Respect@THI" App.
Das Ziel der App ist es, dass Hochschulangehörige sensible Anliegen direkt
an die verantwortlichen Personen melden können.

Wir haben uns mit der Sicherheit der App genauer beschäftigt. Bei
einer App über die sensible Informationen preisgegeben werden ist es von
besonderer Bedeutung, dass die Anonymität und Vertraulichkeit der Nutzer nicht
beiinträchtigt wird.
Im Folgenden beschreiben wir die gefundenen Schwachstellen genauer. Jede
Schwachstelle erhält außerdem eine Kritikalität. Schwachstellen die hier eine
Einstufung von "Hoch" oder "Sehr Hoch" haben, sollten auf jeden Fall vor der 
Veröffentlichung der App behoben werden.

Personen die die App nutzen um ein Anliegen zu melden werden im Folgenden
**Nutzer** genannt. Personen die diese Anliegen entgegennehmen und bearbeiten
werden im **Helfer** genannt.

# Technische Umsetzung und Scope des Pentests

Die App wird zwar als reguläre App über den Play- bzw. App-Store installiert,
besteht aber im Wesentlichen nur aus einer eingebetteten Webseite.
Scope dieser Pentest Beschreibung ist daher ausschließlich die Sicherheit dieser
PHP-basierten Web-Anwendung. Technologisch macht es keinen Unterschied ob die 
Applikation über die Handy-App oder direkt im Web-Browser verwendet wird.

Durchgeführt wurde ein umfassender Penetration Test der Testinstallation der 
Anwendung (https://respect.thi.de/app/ui), sowie ein Audit des zur Verfügung 
gestellten Quellcodes in geringem Umfang.

# Schwachstellen

## Stored Cross Site Scripting Schwachstelle **Nutzer** \rightarrow{} **Helfer**
- Kritikalität: **Sehr Hoch**
- Mögliche Auswirkungen: Ausspähen von **Nutzer**- und **Helfer**-Daten
- Dateien: 
    - `management/www/authorized/answer/index.php:93`

```php
$err = $ms->getMessage($mid, $key, $requestMsg, $responseMsg);
[...]
<textarea class="textfield" <?php if ($requestMsg == null) echo "style=\"display: none\"";?> disabled><?php if ($requestMsg != null) echo $requestMsg;?></textarea>
```

### Demonstration
![Demonstration der XSS Schwachstelle [[1]](https://www.youtube.com/watch?v=dQw4w9WgXcQ).](poc-xss.png "Expertly crafted Rick Roll."){ height=8cm }

### Beschreibung
**Nutzer** haben die Möglichkeit ihr Anliegen über ein Freitext-Feld zu
beschreiben. Der Inhalt dieses Freitextfeldes wird anschließend beim
bearbeitenden **Helfer** direkt in den HTML Code eingebettet. Insbesondere
werden dabei vom Nutzer eingefügte HTML Codes nicht entfernt oder umgewandelt.
Ein Angreifer kann so über eine spezielle Anfrage Schadcode im Browser von
dem bearbeitenden **Helfer** ausführen, in dessen Namen Aktionen tätigen oder
Daten abrufen.

### Mögliche Lösung
In PHP kann die Funktion `htmlentities` benutzt werden um HTML Code in der
Nutzereingabe durch entsprechende escape-codes zu erstetzen.
Idealerweise sollte das schon vor dem ablegen des Textes in der Datenbank
erfolgen. Alternativ bieten gängige Frameworks in der Regel einen automatischen
Schutz gegen HTML Injection. 

## Stored Cross Site Scripting Schwachstelle **Helfer** \rightarrow{} **Nutzer**
- Kritikalität: **Sehr Hoch**
- Mögliche Auswirkungen: Ausspähen von **Nutzer**-Daten, Aushebelung der Anonymität von **Nutzer**innen
- Dateien: 
    - `app/activated/content/www/en/antwort.php:63`

Analog zu Stored Cross Site Scripting Schwachstelle **Nutzer** \rightarrow{} **Helfer**.

## Cross Site Request Forgery (CSRF) Schwachstelle
- Kritikalität: **Niedrig**
- Mögliche Auswirkungen: Ändern von Nutzereinstellungen beim Besuch von Dritt-Webseiten
- Dateien: 
    - `app/activated/www/api/setLanguage.php`

### Beschreibung
Die Webseite ändert Nutzereinstellungen bei einem GET-Request. Ein Angreifer
der einen **Nutzer** auf eine Dritt-Webseite lockt, kann Einstellungen des
**Nutzer**s in der React@THI App ohne dessen Wissen ändern.
Im Gegensatz zu POST-Requests bieten GET-Requests nur einen bedingten Schutz
vor sogenannten Cross-Origin-Requests, d.h. HTTP-Requests, deren Ziel ein anderer
als der ausliefernde Webserver ist. Ein Angreifer hat dadurch die Möglichkeit, 
einen GET-Request mit den Authentifizierungsinformationen des Benutzers ohne 
dessen Wissen bzw. Interaktion zu senden.

### Mögliche Lösung
Ein guten Schutz bietet bereits das SameSite=Strict Attribut beim Setzen der 
Cookies. Dadurch wird der Webbrowser angewiesen, die Cookies ausschließlich bei
Requests zu übermitteln, deren Ursprung (Origin) die selbe URL hat.
Daneben sollten GET-Requests keine Zustandsänderungen bewirken, sondern
stattdessen POST-Requests genutzt werden.

## Open Redirects
- Kritikalität: **Medium**
- Mögliche Auswirkungen: Erhöhtes Phishing-Risiko von Zugangsdaten
- Dateien:
  - `respect/app/activated/www/api/setLanguage.php:12`
  - `respect/app/activated/www/api/sendMessage.php:56`
  - `respect/app/activated/www/api/sendMessage.php:60`

```php
$redirect_success = $_GET["rdir_success"];
$redirect_error = $_GET["rdir_error"];

if (!isset($_POST["beschreibung"]) || !isset($_POST["location"]) || !isset($_POST["email"]) || !isset($_POST["date"])) {
    Header("Location: " . $redirect_error . "?err=1");
    exit;
}
```

### Beschreibung
Die Applikation nimmt das Ziel einer Weiterleitung bei Erfolg bzw. Fehler über 
einen URL-Parameter entgegen. Ein Angreifer kann den Nutzer durch einen 
manipulierten Link auf eine beliebige Website weiterleiten, was ggf. vom Nutzer
nicht bemerkt wird. Dies erhöht das Risiko eines Phishing-Angriffs.

### Mögliche Lösung
Die URLs der Weiterleitung sollten durch die Anwendung statisch vorgegeben 
werden.

## HTTP Header Injection
- Kritikalität: **Medium**
- Mögliche Auswirkungen: Bypass der Authentifikation
- Dateien:
    - `app/activated/www/ui/index.php:62`

```php
// Pass cookies
$strCookies = $_SERVER["HTTP_COOKIE"];
$opts = array(
    'http'=>array(
        'method'=>"GET",
        'header'=>"Accept-language: en\r\n" .
        "Cookie: " . $strCookies . "\r\n"
    )
);
$context = stream_context_create($opts);
```

### Beschreibung
Die Applikation implementiert zur Auslieferung statischer Ressourcen eine Art
Proxy, der eine Authentifikation erzwingt. Die Header des Requests enthalten 
über die Cookies eine nicht gefilterte Benutzereingabe. Dadurch kann ein 
Angreifer beliebige zusätzliche Header setzen, die möglicherweise zu einer 
Fehlfunktion nachfolgender Komponenten führt.

### Mögliche Lösung
Benutzereingaben (inkl. Cookies!) müssen *stets* gefiltert (sanitized) werden.
Alternativ sollte das Header-Feld (Zeile 61) direkt als Array übergeben werden.

## Missing input sanitization in LDAP search string
- Kritikalität: **Gering**
- Mögliche Auswirkungen: Unbekannt
- Dateien: 
    - `respect/modules/LDAPService.class.php`

```php
public function verify(string $username, string $password) { // RETURNS int (0 - SUCCESS, 1 - INVALID, 2 - ERROR)
    // TODO: CHECK AGAINST INJECTION?
    if (self::authenticateViaLDAP($username, $password) === true)
        return 0;
    else
        return 1;
    }
```

### Beschreibung
Benutzername und Password sind an dieser Stelle Benutzeingaben, die anschließend 
im LDAP-Query verwendet werden. Je nach Server-Implementation kann dies zu 
Schwachstellen in der Authentifizierung führen.

### Mögliche Lösung
Benutzereingaben müssen *stets* gefiltert (sanitized) werden. Alternativ wäre 
eine Authentifizierung über ein zentrales Portal (Stichwort: SAML SSO) geeignet.

## Weak Cryptography
- Kritikalität: **Gering**
- Mögliche Auswirkungen: Unbekannt
- Dateien:
    - `modules/Token.class.php`

```php
public function getSignature() { // RETURNS: string
    $plain = $this->type . "+" . $this->id . "+" . $this->issuedAt . "+" . $this->validityPeriod . "+" . self::$signatureKey;
    if ($this->cipherKey != null) $plain .= "+" . $this->cipherKey;
    
    return hash("sha256", $plain, false);
    
}
```

### Beschreibung:
Die Anwendung implementiert ein eigenes kryptographisches Verfahren zur 
Erzeugung der Signaturen für Authentifizierungsinformationen. Das verwendete 
Verfahren ist potentiell anfällig gegen Length-Extension-Attacks:
Die Signatur wird gebildet als $H(m_1||k||m_2)$, wobei $m_2$ den CipherKey 
darstellt. Ein Angreifer kann mit $H(k||m)$ und $m$ ohne Kenntnis von $k$ den 
Wert $H(k||m_1||m_2)$ berechnen, d.h. eine gefälschte Signatur erzeugen.

### Mögliche Lösung
Es sollten etablierte Verfahren für Token (JSON Web Token, JWT) bzw. 
Message Authentification Codes (HMACs) verwendet werden.

## Sensitive Data in Code
- Kritikalität: **Medium**
- Mögliche Auswirkungen: Erhöhtes Risiko für Verlust von Zugangsdaten
- Dateien:
    - `modules/Token.class.php:5`
    - `modules/OneTimeCodeGenerator.class.php:5`
    - `modules/UserCredentials.class.php:5-14`

### Beschreibung
Die Quellcode-Dateien enthalten hartcodierte Zugangsdaten und Schlüssel. Dies 
erschwert die Handhabung des Codes, da der Quellcode entweder geheim gehalten 
werden muss bzw. vor Freigabe aufwendig zensiert werden muss.

### Mögliche Lösung
Zugangsdaten sollten über eine Konfiguration getrennt vom Code erfolgen.

# Zusammenfassung
Die Anwendung demonstriert eine umfassende Awareness für Security-Anforderungen.
Insbesondere die Umsetzung der Ende-zu-Ende Verschlüsselung für Tickets ist 
robust erfolgt und weist nach dieser Analyse keine offensichtlichen Schwachstellen
auf.

Gleichzeitig exisiteren jedoch einige Schwachstellen, die vor Veröffentlichung 
dringend behoben werden sollten. Die Wartbarkeit des Codes wird erschwert, indem
er für die Lokalisierung in jeder Sprache dupliziert wird. Wir empfehlen für
zukünftige Versionen den Einsatz eines Frameworks, das solche grundlegenden 
Funktionen wie Datenbank-Queries, Authentifikationen, die Ausgabe von 
Benutzerdaten oder eine Lokalisierung auf sichere Art und Weise implementiert. 
