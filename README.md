# Conteneur d'outils de préservation numérique en ligne de commandes

[![fr](https://img.shields.io/badge/README-fr-green.svg)](https://github.com/tledoux/preservation-container/blob/main/README.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 1. Présentation

Ce projet fournit un environnement Linux conteneurisé destiné à l'identification, à la caractérisation et à l'inventaire de fichiers dans le cadre d'opérations de préservation numérique.

L'image repose sur Debian et regroupe les utilitaires Unix classiques, les outils d'extraction de métadonnées et les outils de traitement de données structurées.


**Outils inclus**

| Domaine                                | Outils principaux                        |
|----------------------------------------|------------------------------------------|
| Inspection et manipulation de fichiers | wc, od, stat, xxd, hexdump               |
| Empreintes et intégrité                | md5sum, sha256sum, b3sum, openssl, rhash |
| Identification                         | file, droid, siegfried                   |
| Métadonnées                            | exiftool, tika, jhove, jpylyzer          |
| Audiovisuel                            | mediainfo, ffprobe, ffmpeg               |
| PDF                                    | verapdf, pdfbox                          |
| JSON et XML                            | jq, xmllint, xmlstarlet                  |
| Schémas XML                            | `/opt/xml-schemas`                       |
| Archives                               | tar, gzip, bzip2, xz, zip, unzip, zstd   |
| Empaquetage                            | bagit                                    |
| Administration et scripts              | bash, python3, git, curl, wget, rsync    |

Un script complémentaire, `tool-versions`, permet de générer un inventaire JSON des versions des outils installés.

Un autre script, `start-session`, génère un identifiant de session et crée un répertoire horodaté pour regrouper les sorties des outils.

De plus, tika est accompagné d'un lanceur `tika-analyze` pour faciliter l'analyse. Il prend en argument le chemin relatif d'un répertoire dans `/mnt/input`.

## 2. Organisation des volumes

Le conteneur utilise trois répertoires distincts.

| Répertoire  | Usage                               | Accès            |
|-------------|-------------------------------------|------------------|
|/mnt/input   | Fichiers sources à analyser         | Lecture seule    |
|/mnt/ouput   | Rapports, inventaires et empreintes | Lecture-écriture |
|/work        | Espace de travail temporaire        | Lecture-écriture |

Les répertoires `/mnt/input` et `/mnt/output` sont des montages provenant du système hôte. Les résultats produits dans `/mnt/output` restent donc accessibles après la fermeture du conteneur.

**Principe de sécurité :** les fichiers sources ne doivent jamais être modifiés pendant les opérations de caractérisation. Le montage en lecture seule constitue une première protection contre les écritures accidentelles.

## 3. Prérequis

Les éléments suivants sont nécessaires :

- Un environnement hôte disposant de `wslc`.
- Une version de `wslc` compatible avec la construction d'images et les montages de volumes.
- Les fichiers `Containerfile`, `tool-versions`, `start-session` et `tika-analyze` du projet.
- Un répertoire hôte contenant les données à analyser.
- Un répertoire hôte destiné à recevoir les sorties des outils (rapports, paquets, ...).

La syntaxe des commandes ci-dessous suppose une interface wslc compatible avec les options de construction et de lancement illustrées. Vérifier les options disponibles avec `wslc --help` et `wslc run --help` si nécessaire.

## 4. Construction de l'image

Placer les fichiers suivants dans un même répertoire de projet :

```text
preservation-container/
├── Containerfile
├── tool-versions
├── start-session
├── tika-analyze
└── README.md
```

Depuis ce répertoire, construire l'image :
```cmd
wslc build -t preservation-tools:1.0 .
```

L'image est identifiée par le nom `preservation-tools` et le tag `1.0`.

Pour consulter les images disponibles :

```cmd
wslc image list
```

Après une modification du `Containerfile` ou d'un des scripts, reconstruire l'image avant de lancer une nouvelle session.

L'image peut être supprimer par :
```cmd
wslc rmi preservation-tools:1.0
```
mais il est préférable de changer le tag pour incrémenter le numéro de version et ainsi suivre les évolutions.

## 5. Préparation des répertoires sur l'hôte

Dans cet exemple, les données sont stockées sous `D:\Donnees` et les rapports sous `D:\Rapports`.

Créer ces répertoires sur l'hôte :

```cmd
mkdir D:\Donnees
mkdir D:\Rapports
```
Copier les fichiers à analyser dans le répertoire `D:\Donnees`, en utilisant les procédures habituelles de transfert de l'organisation.

Le répertoire `D:\Rapports` doit être accessible en écriture à l'utilisateur utilisé par le conteneur. Dans l'image proposée, cet utilisateur possède l'UID et le GID 1000.

## 6. Lancement du conteneur

La commande suivante monte les deux répertoires hôtes dans le conteneur :

```bash
wslc run --rm -it \
  --mount type=bind,source=D:\Donnees,target=/mnt/input,readonly \
  --mount type=bind,source=D:\Rapports,target=/mnt/output \
  preservation-tools:1.0
```

Les options utilisées sont les suivantes :

- `--rm` : supprime le conteneur à sa fermeture.
- `-it` : ouvre une session interactive dans un terminal.
- Le premier `--mount` expose les données sources en lecture seule.
- Le second `--mount` expose le répertoire de rapports en lecture-écriture.
- `preservation-tools:1.0` désigne l'image à lancer.

Les chemins source doivent correspondre à des chemins accessibles depuis l'environnement où wslc exécute les conteneurs.

Vous pouvez utiliser directement les scripts `run-preservation.cmd` (console cmd) ou `run-preservation.ps1` (console PowerShell) avec comme arguments les 2 répertoires :
```cmd
> run-preservation.cmd D:\Donnees D:\Rapports

PS > run-preservation.ps1 D:\Donnees D:\Rapports
``` 

Une fois dans le conteneur, vérifier les montages :

```bash
ls -lah /mnt/input
ls -lah /mnt/output
```

Vérifier également que le répertoire de sortie est accessible en écriture :

```bash
touch /mnt/output/.write-test
rm /mnt/output/.write-test
```

Si ces commandes échouent, corriger les permissions avant de commencer l'analyse.

## 7. Exemple complet d'une session de travail

L'exemple suivant réalise les opérations suivantes :

- Création d'un répertoire de session horodaté en UTC.
- Génération d'un inventaire des fichiers sources avec leur chemin et leur empreinte MD5.
- Génération d'un inventaire des métadonnées avec ExifTool au format JSON.
- Génération d'une analyse avec Siegfried au format CSV.
- Enregistrement de la version des outils utilisés.
- Conservation d'une trace des commandes et de leurs éventuelles erreurs.

### 7.1. Créer le répertoire de session

Dans le conteneur, utiliser le script pour initialiser une session :
```bash
source /usr/local/bin/start-session
```

Ce script crée un répertoire horodaté, appelle `tool-versions` pour garder trace des versions des utilitaires disponibles et crée aussi 2 variables qui permettent d'avoir l'horodatage de session et le répertoire associé.

Un exemple de sortie du script est fourni ci-dessous :

```text

Inventaire logiciel écrit dans : /mnt/output/20261028T110323Z/tool-versions.json

Session initialisée avec succès.
SESSION_ID = 20261028T110323Z
REPORT_DIR = /mnt/output/20261028T110323Z

total 4.0K
drwxr-xr-x 1 analyst analyst 4.0K Oct 28 11:03 .
drwxrwxrwx 1 root    root    4.0K Oct 28 11:03 ..
drwxr-xr-x 1 analyst analyst 4.0K Oct 28 11:03 logs
-rw-r--r-- 1 analyst analyst 2.2K Oct 28 11:03 tool-versions.json
```


Si vous voulez tout gérer vous-même, saisissez, dans le conteneur, les instructions. Par exemple :

```bash
SESSION_ID="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT_DIR="/mnt/output/${SESSION_ID}"

mkdir -p "$REPORT_DIR/logs"

printf 'Session : %s\n' "$SESSION_ID"
printf 'Rapports : %s\n' "$REPORT_DIR"
```

Exemple de nom généré :

```text
20261028T093000Z
```

Le répertoire de session est créé sous `/mnt/output`. Les résultats restent ainsi disponibles sur l'hôte après la fermeture du conteneur.

### 7.2. Générer le listing des fichiers avec leurs empreintes MD5

Créer un inventaire contenant les chemins des fichiers et leur empreinte MD5 :

``` bash
find /mnt/input -type f -print0 |
  sort -z |
  xargs -0 -r md5sum \
  > "$REPORT_DIR/manifest-md5.txt" \
  2> "$REPORT_DIR/logs/md5-errors.log"
```

Cette commande :

- parcourt récursivement `/mnt/input` ;
- sélectionne les fichiers ordinaires ;
- trie les chemins ;
- calcule une empreinte MD5 pour chaque fichier ;
- écrit les résultats dans manifest-md5.txt ;
- enregistre les messages d'erreur éventuels dans md5-errors.log.

Le manifeste pourra contenir des lignes de ce type :

``` text
d41d8cd98f00b204e9800998ecf8427e  /mnt/input/document.txt
098f6bcd4621d373cade4e832627b4f6  /mnt/input/image.jpg
```

Ces empreintes sont des exemples illustratifs.

Une autre solution est d'utiliser `rhash` avec la commande :
``` bash
rhash --md5 -r /mnt/input \
  > "$REPORT_DIR/manifest-md5.txt" \
  2> "$REPORT_DIR/logs/md5-errors.log" 
```


### 7.3. Extraire les métadonnées avec ExifTool

Pour analyser récursivement les fichiers de `/mnt/input` et produire un rapport JSON :

```bash
exiftool \
  -r \
  -json \
  -charset filename=UTF8 \
  /mnt/input \
  > "$REPORT_DIR/exiftool-inventory.json" \
  2> "$REPORT_DIR/logs/exiftool-errors.log"
```

Le rapport JSON contient les métadonnées extraites par ExifTool pour les fichiers qu'il parvient à analyser.

Pour consulter le résultat :

```bash
jq 'length' "$REPORT_DIR/exiftool-inventory.json"
```

Cette commande affiche le nombre d'entrées JSON produites.

Pour consulter les informations du premier fichier :

```bash
jq '.[0]' "$REPORT_DIR/exiftool-inventory.json"
```

Pour obtenir une vue synthétique des noms de fichiers et des formats détectés :

```bash
jq '.[] | {
  SourceFile,
  FileType,
  FileTypeExtension,
  MIMEType
}' "$REPORT_DIR/exiftool-inventory.json"
```

La présence d'un fichier JSON ne garantit pas que tous les fichiers ont pu être analysés. Il convient de vérifier les journaux d'erreurs et les éventuelles erreurs signalées par les outils.

### 7.4 Analyse avec Siegfred

```bash
sf -csv /mnt/input > "$REPORT_DIR/siegfried.csv"
```

### 7.5. Enregistrer les versions des outils

Produire l'inventaire logiciel de la session :

```bash
tool-versions "$REPORT_DIR/tool-versions.json"
```

Le rapport permet de documenter les versions des outils de caractérisation présents dans l'environnement.

Pour afficher les informations relatives à ExifTool et FFprobe :

```bash
jq '{
  exiftool: .tools.exiftool,
  ffprobe: .tools.ffprobe
}' "$REPORT_DIR/tool-versions.json"
```

### 7.6. Créer un résumé de session

Enregistrer quelques informations de contexte :

```bash
{
  printf 'session_id=%s\n' "$SESSION_ID"
  printf 'started_at_utc=%s\n' "$SESSION_ID"
  printf 'source=/mnt/input\n'
  printf 'reports=%s\n' "$REPORT_DIR"
  printf 'image=preservation-tools:1.0\n'
} > "$REPORT_DIR/session-info.txt"
```

Ce fichier est un résumé minimal. Pour une traçabilité renforcée, il est recommandé d'y ajouter l'identifiant immuable de l'image, le digest de l'image OCI, la version du Containerfile, l'identité de l'opérateur et les paramètres de traitement.

### 7.7. Résultat attendu

À l'issue de la session, l'organisation des rapports sera la suivante :

```text
/mnt/output/
└── 20261028T093000Z/
    ├── session-info.txt
    ├── manifest-md5.txt
    ├── siegfried.csv
    ├── exiftool-inventory.json
    ├── tool-versions.json
    └── logs/
        ├── md5-errors.log
        ├── sha256-errors.log
        └── exiftool-errors.log
```

Le répertoire est horodaté en UTC afin d'éviter les ambiguïtés liées aux fuseaux horaires.

## 8. Utilisation de bagit

L'outil bagit est également présent. Il peut servir à créer des bags ou à les valider.

#### 8.1 Création d'un bagit

On suppose que les fichiers à empaqueter sont dans le répertoire `input`. Comme il est monté en lecture seule, il est nécessaire de faire une copie dans le répertoire de sortie avant de pouvoir lancer la commande.

```bash
BAG_DIR="$REPORT_DIR/bag"

mkdir -p "$BAG_DIR/data"

# Copier les fichiers en conservant leur arborescence
cp -a /mnt/input/. "$BAG_DIR/data/"

# Créer le bag avec un manifeste SHA-256
bagit --sha256 \
  --source-organization "Preservation" \
  "$BAG_DIR"
```

Le paquet obtenu aura cette structure :
```text

bag/
├── bagit.txt
├── bag-info.txt
├── manifest-sha256.txt
├── tagmanifest-sha256.txt
└── data/
    └── ... fichiers archivés ...
```

#### 8.2 Validation d'un bagit

La validation peut générer un rapport que l'on mettra dans le répertoire de sortie. Ainsi, une session peut se représenter de cette façon :
```bash
bagit --validate "$BAG_DIR" \
  > "$REPORT_DIR/logs/bagit-validation.log" 2>&1

rc=$?

if [ "$rc" -eq 0 ]; then
    echo "Validation BagIt réussie."
else
    echo "ERREUR : validation BagIt échouée (code $rc)."
fi
```

## 9. Validation de fichiers XML

Le conteneur contient un certain nombre de schémas classiques dans le répertoire `/opt/xml-schemas` et peut donc valider des fichiers XML localement. Il faut pour cela utiliser l'outil `xmllint`. La variable d'environnement `XML_CATALOG_FILES` est déjà prépositionnée sur le catalogue des schémas disponibles.

Par exemple, un manifeste METS peut être valider ainsi :
```bash
xmllint \
  --nonet --nowarning --noout \
  --schema /opt/xml-schemas/combined-bnf.xsd \
  /mnt/input/mon-fichier-mets.xml \
  > "$REPORT_DIR/logs/mets-validation.log" 2>&1

rc=$?

if [ "$rc" -eq 0 ]; then
    echo "Validation METS réussie."
else
    echo "Échec de validation METS : code $rc"
fi
```

À noter que l'on a utilisé ici le pseudo-schéma `combined-bnf.xsd` qui permet d'importer plusieurs schémas **simultanément** : pour le cas des manifestes METS, il importe à la fois mets.xsd et spar_dc.xsd pour permettre une validation sans souci.

## 10. Vérifications complémentaires

Avant de terminer une session, contrôler les fichiers produits :

```bash
find "$REPORT_DIR" -maxdepth 2 -type f -print
```

Vérifier que le JSON d'ExifTool est syntaxiquement valide :

```bash
jq empty "$REPORT_DIR/exiftool-inventory.json"
```

Vérifier que le JSON des versions est valide :

```bash
jq empty "$REPORT_DIR/tool-versions.json"
```

Examiner les journaux :

```bash
for log in "$REPORT_DIR"/logs/*.log; do
  echo "===== $log ====="
  cat "$log"
done
```

Un journal vide n'indique pas nécessairement que tous les fichiers ont été correctement caractérisés : il faut également examiner les codes de retour des commandes et le contenu des rapports.

## 11. Bonnes pratiques de préservation numérique

- Ne jamais utiliser le conteneur pour modifier les originaux.
- Monter les données en lecture seule et conserver les rapports séparément.
- Produire des empreintes SHA-256 en complément de MD5.
- Conserver les rapports d'erreurs et ne pas considérer une sortie partielle comme un succès complet.
- Enregistrer les versions des outils et l'identifiant de l'image utilisée.
- Créer un nouveau répertoire horodaté pour chaque session.
- Sauvegarder les manifestes et les rapports selon la politique de conservation de l'organisation.
- Éviter d'écraser les rapports antérieurs.
- Vérifier les empreintes à des échéances définies pour surveiller l'intégrité des données conservées.

## 12. Limites

Le conteneur fournit un environnement reproductible pour les opérations de caractérisation, mais ne constitue pas à lui seul un système complet d'archivage numérique.

Il ne remplace pas :

- une stratégie de sauvegarde ;
- une gestion formalisée des droits d'accès ;
- une politique de conservation et de contrôle périodique de l'intégrité ;
- une documentation des événements affectant les objets numériques ;
- une procédure de validation des outils et des résultats.

Pour les opérations importantes, conserver les rapports dans un espace distinct des originaux et documenter les procédures appliquées afin de garantir leur auditabilité.
