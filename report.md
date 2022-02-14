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
    \sectionnumbering{Roman}

    \usepackage[headsepline,footsepline]{scrlayer-scrpage}
    \pagestyle{scrheadings}
    \ihead{\includegraphics[height=2cm]{thi_logo.eps}}
    \chead{}
    \ohead{\leftmark}
    \ifoot{}
    \cfoot{}
    \ofoot{\thepage}

    \providecommand{\versionortoday}{\today}
...

# Einführung
An der THI wurde eine neue App entwickelt, die "Respect@THI" App.
Das Ziel der App ist es, dass Hochschulangehörige sensible Anliegen direkt
an die verantwortlichen Personen melden können.

Wir haben uns mit der Sicherheit der App genauer beschäftigt. Bei
einer App über die sensible Informationen preisgegeben werden ist es von
besonderer Bedeutung, dass die Anonymität und Vertraulichkeit der Nutzer nicht
beiinträchtigt wird.
Im folgenden beschreiben wir die gefundenen Schwachstellen genauer. Jede
Schwachstelle erhält außerdem eine Kritikalität. Schwachstellen die hier eine
Einstufung von "Hoch" oder "Sehr Hoch" haben, sollten nach unserer Auffassung
auf jeden Fall vor der Veröffentlichung der App behoben werden.

Personen die die App nutzen um ein Anliegen zu melden werden im folgenden
**Nutzer** genannt. Personen die diese Anliegen entgegennehmen und bearbeiten
werden im folgenden **Helfer** genannt.

# Technische Umsetzung und Scope des Pentests

Die App wird zwar als reguläre App über den Play- bzw. App-Store installiert,
besteht aber im wesentlichen nur aus einer eingebetteten Webseite.
Scope dieser Pentest Beschreibung ist im wesentlichen die Sicherheit dieser
PHP-basierten Web-App.
Technologisch macht es keinen Unterschied ob die App über die Handy-App oder
direkt im Web-Browser verwendet wird.



# Schwachstellen

## Stored Cross Site Scripting Schwachstelle **Nutzer** \rightarrow{} **Helfer**
- Kritikalität: **Sehr Hoch**
- Mögliche Auswirkungen: Ausspähen von **Nutzer**- und **Helfer**-Daten
- Datei: management/www/authorized/answer/index.php
- Zeile: 93

### Demonstration
![Demonstration der XSS Schwachstelle.](poc-xss.png "Expertly crafted Rick Roll."){ height=7cm }

### Beschreibung
**Nutzer** haben die Möglichkeit ihr Anliegen über ein Freitext-Feld zu
beschreiben. Der Inhalt dieses Freitextfeldes wird anschließend beim
bearbeitenden **Helfer** direkt in den HTML Code eingebettet. Insbesondere
werden dabei vom Nutzer eingefügte HTML Codes nicht entfernt oder umgewandelt.
Ein Angreifer kann so über eine spezielle Anfrage Schadcode im Browser von
dem bearbeitenden **Helfer** ausführen, in dessen Namen Aktionen tätigen oder
Daten abrufen.

### Lösung
In PHP kann die Funktion `htmlentities` benutzt werden um HTML Code in der
Nutzereingabe durch entsprechende escape-codes zu erstetzen.
Idealerweise sollte das schon vor dem ablegen des Textes in der Datenbank
erfolgen.



## Stored Cross Site Scripting Schwachstelle **Helfer** \rightarrow{} **Nutzer**
- Kritikalität: **Sehr Hoch**
- Mögliche Auswirkungen: Ausspähen von **Nutzer**-Daten, Aushebelung der Anonymität von **Nutzer**innen
- Datei: app/activated/content/www/en/antwort.php
- Zeile: 63

#### Beschreibung
**Helfer** haben die Möglichkeit eine Antwort über ein Freitext-Feld zu
formulieren. Der Inhalt dieses Freitextfeldes wird anschließend beim
**Nutzer** direkt in den HTML Code eingebettet. Insbesondere werden dabei vom
**Helfer** eingefügte HTML Codes nicht entfernt oder umgewandelt.

#### Lösung
In PHP kann die Funktion `htmlentities` benutzt werden um HTML Code in der
Nutzereingabe durch entsprechende escape-codes zu erstetzen.
Idealerweise sollte das schon vor dem ablegen des Textes in der Datenbank
erfolgen.



## Cross Site Request Forgery Schwachstelle
- Kritikalität: **Niedrig**
- Mögliche Auswirkungen: Ändern von Nutzereinstellungen beim Besuch von Dritt-Webseiten
- Datei: app/activated/www/api/setLanguage.php

#### Beschreibung
Die Webseite ändert Nutzereinstellungen bei einem GET-Request. Ein Angreifer
der einen **Nutzer** auf eine Dritt-Webseite lockt, kann Einstellungen des
**Nutzer**s in der React@THI App ändern.

#### Lösung
Beim setzten von Cookies sollte immer `SameSite=Strict` gesetzt werden.



# Zusammenfassung
TODO
