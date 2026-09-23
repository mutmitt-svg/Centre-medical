# Plan de tests et de recette — Application de gestion d'un centre de santé

Document de livraison L9 du cahier des charges. Il définit la stratégie de vérification, les environnements, les jeux de données, les cas de test détaillés, les tests non fonctionnels et les règles d'acceptation.

## 1. Objet et portée

Le plan couvre les 28 modules M01 à M28, les 213 exigences fonctionnelles codées EF-Mxx-nn, les exigences non fonctionnelles ENF et les 12 règles de gestion RG-01 à RG-12. Il s'applique à toutes les phases : tests unitaires par l'éditeur, tests d'intégration, tests système, recette usine, recette site pilote et vérification de service régulier.

Hors portée : la certification du matériel médical, la qualité du réseau de l'opérateur, la conformité comptable des états produits par des tiers.

## 2. Stratégie de vérification

| Niveau | Responsable | Couverture visée | Outillage |
| --- | --- | --- | --- |
| Tests unitaires | Éditeur | 80 % des règles de calcul, 100 % des règles RG | Cadre de tests automatisés, exécution à chaque livraison |
| Tests d'intégration | Éditeur | Chaînes inter-modules (consultation → pharmacie → caisse → SNIS) | Jeu de données de démonstration `seed_demo.sql` |
| Tests système | Éditeur | Parcours complets, 28 modules | Scénarios CT du présent plan |
| Recette usine | Commanditaire | Exigences de priorité I et S | Grille de recette, matrice de traçabilité |
| Recette site pilote | Centre de santé pilote + commanditaire | Usage réel pendant un cycle mensuel complet | Journal d'usage, relevé d'anomalies |
| Vérification de service régulier | Commanditaire | Stabilité sur 60 jours | Indicateurs d'exploitation |

Principe de non-régression : toute anomalie corrigée devient un test automatisé permanent.

## 3. Environnements

| Environnement | Usage | Données | Particularités |
| --- | --- | --- | --- |
| Développement | Codage | Données fictives | Réinitialisé librement |
| Intégration | Tests automatisés | `seed_demo.sql` rechargé à chaque exécution | Base réinitialisée avant chaque campagne |
| Recette | Recette usine et formation | `seed_demo.sql` enrichi par les testeurs | Identique en version à la cible |
| Pilote | Site pilote en production surveillée | Données réelles | Sauvegarde quotidienne vérifiée |

Configuration matérielle minimale de test, représentative du terrain : serveur local 4 Go de mémoire vive et disque à mémoire flash, deux postes clients d'entrée de gamme, une tablette, imprimante thermique, onduleur, liaison Internet limitée volontairement à 256 kbit/s avec coupures provoquées.

## 4. Jeu de données de recette

Le jeu `seed_demo.sql` fournit le socle : découpage sanitaire de l'aire de santé de Kamalondo, huit services, référentiels CIM-10, LOINC, produits, actes et tarifs, dix rôles avec leurs permissions, et des cas cliniques complets. Les identités de démonstration sont réutilisées dans tous les cas de test pour rendre les résultats comparables :

| Référence | Usage principal |
| --- | --- |
| MUKENDI Sarah, 3 ans, dossier 2026-0418, paludisme grave, allergie au cotrimoxazole, mutuelle MUSOSA 80 % | Parcours curatif pédiatrique complet, facturation mixte |
| KASONGO Marie, G3P2, dossier de grossesse et partogramme | CPN, accouchement, gratuité maternité |
| MBAYO Daniel, nourrisson | Consultation préscolaire et vaccinations |
| TSHIBANGU Paul, hypertendu | Suivi de maladie chronique, dispensation au long cours |

Les testeurs ne modifient jamais le jeu de référence : ils travaillent sur une copie rechargeable en une commande.

## 5. Critères d'entrée et de sortie

Entrée en recette :
- version livrée avec son numéro, ses notes de version et son empreinte de fichiers ;
- environnement de recette installé et jeu de données chargé ;
- tests d'intégration de l'éditeur passés à 100 % sur les exigences de priorité I ;
- documentation utilisateur et guide d'installation disponibles.

Sortie de recette :
- 100 % des exigences de priorité I vérifiées et acceptées ;
- au moins 95 % des exigences de priorité S vérifiées, les restantes planifiées ;
- aucune anomalie bloquante ou majeure ouverte ;
- au plus dix anomalies mineures ouvertes, avec échéance de correction ;
- procès-verbal de recette signé par le commanditaire et l'infirmier titulaire.

## 6. Classification des anomalies

| Gravité | Définition | Délai de correction |
| --- | --- | --- |
| Bloquante | Empêche une activité de soins ou de rapportage ; perte ou corruption de données | 24 heures ouvrées |
| Majeure | Résultat erroné sans contournement acceptable ; règle de gestion non respectée | 5 jours ouvrés |
| Mineure | Gêne ergonomique, libellé, mise en page, avec contournement | Livraison suivante |
| Évolution | Besoin nouveau hors cahier des charges | Arbitrage en comité de pilotage |

Une anomalie portant sur une règle de gestion RG ou sur un calcul du rapport SNIS est au minimum majeure.

## 7. Cas de test détaillés

Chaque cas porte un identifiant CT-Mxx-nn, la ou les exigences couvertes, les préconditions, les étapes et le résultat attendu. Le résultat attendu est formulé de manière observable.

Les cas scriptés ci-dessous couvrent 92 exigences, soit les règles de gestion, les calculs et les points de rupture les plus sensibles. Les 121 exigences restantes, essentiellement des fonctions de saisie, d'édition et d'impression, sont vérifiées par une liste de contrôle par module notée CT-Mxx-CL : le testeur exécute la fonction, compare l'édition produite à l'outil officiel correspondant et coche la ligne dans la matrice de traçabilité. Aucune exigence ne reste sans moyen de vérification.

### M01 — Référentiels et paramétrage

CT-M01-01 — Versionnement d'un tarif
Exigences : EF-M01-11, RG-09.
Préconditions : tarif consultation adulte à 2 000 CDF en vigueur depuis le 01/01/2026 ; une facture validée du 15/08/2026 utilise ce tarif.
Étapes : créer un tarif à 2 500 CDF applicable au 01/10/2026 ; rouvrir la facture du 15/08/2026 ; facturer une consultation le 02/10/2026.
Résultat attendu : l'ancien tarif est clôturé au 30/09/2026 sans être modifié ; la facture d'août affiche toujours 2 000 CDF ; la nouvelle facture affiche 2 500 CDF.

CT-M01-02 — Taux de change journalier
Exigences : EF-M01-09.
Étapes : saisir un taux de 2 800 CDF pour 1 USD au jour J ; encaisser 10 USD sur une facture libellée en CDF ; modifier le taux du lendemain à 2 900 ; rouvrir le reçu de la veille.
Résultat attendu : le reçu conserve le taux de 2 800 et l'équivalent en CDF calculé à ce taux ; le nouveau taux ne s'applique qu'aux opérations postérieures.

CT-M01-03 — Contrôle d'unicité du référentiel
Exigences : EF-M01-03, EF-M01-05.
Étapes : tenter de créer deux produits avec le même code ; tenter de supprimer un diagnostic utilisé dans une consultation.
Résultat attendu : création refusée avec message explicite ; suppression refusée, désactivation proposée à la place, l'historique restant lisible.

### M02 — Identité patient

CT-M02-01 — Recherche tolérante aux fautes
Exigences : EF-M02-04.
Préconditions : patient MUKENDI Sarah enregistré.
Étapes : rechercher « Mukendi », « Moukendi », « MUKENDI SARA », puis le numéro 2026-0418.
Résultat attendu : les trois recherches approchées retournent la patiente dans les trois premiers résultats avec un score ; la recherche par numéro retourne un résultat exact unique en moins d'une seconde.

CT-M02-02 — Détection de doublon
Exigences : EF-M02-05.
Étapes : créer un patient « MUKENDI Sara », 3 ans, même village.
Résultat attendu : l'enregistrement est suspendu, les candidats sont proposés avec leur dossier ; l'agent peut rattacher au dossier existant ou forcer la création avec justification enregistrée.

CT-M02-03 — Fusion de dossiers
Exigences : EF-M02-06.
Étapes : créer volontairement un doublon, y enregistrer une consultation, puis fusionner vers le dossier principal.
Résultat attendu : toutes les données du doublon sont rattachées au dossier cible ; le numéro du doublon reste résolvable et pointe vers le dossier cible ; la fusion est journalisée avec justification.

CT-M02-04 — Traçabilité des accès
Exigences : EF-M02-11, EF-M25-03.
Étapes : ouvrir le dossier de TSHIBANGU Paul avec le compte d'un laborantin ; consulter le journal d'audit.
Résultat attendu : une entrée de lecture datée, nominative et horodatée est présente ; elle ne peut être ni modifiée ni supprimée, y compris par l'administrateur.

### M03 — Accueil, file d'attente et triage

CT-M03-01 — Numéro d'ordre et attente
Exigences : EF-M03-03, EF-M03-07.
Étapes : enregistrer cinq venues successives, dont une urgence.
Résultat attendu : les jetons sont attribués sans trou ; l'urgence passe en tête sans renuméroter les autres ; le temps d'attente affiché correspond à l'écart entre l'heure d'arrivée et l'heure courante.

CT-M03-02 — Calcul automatique du nouveau cas
Exigences : EF-M03-02, RG-02.
Préconditions : TSHIBANGU Paul a été vu il y a 9 jours pour la même pathologie.
Étapes : enregistrer une venue ce jour, puis une venue 20 jours après la précédente.
Résultat attendu : la première est proposée comme ancien cas, la seconde comme nouveau cas ; l'agent peut corriger, la valeur d'origine et l'auteur de la correction étant conservés.

CT-M03-03 — Signes de danger
Exigences : EF-M03-04, EF-M03-05.
Étapes : saisir un triage pour un enfant de 3 ans avec température 39,8 °C, périmètre brachial 108 mm, convulsions.
Résultat attendu : l'application affiche l'alerte de danger, propose le passage en urgence et le z-score poids/taille est calculé.

### M04 et M05 — Consultation et prescription

CT-M04-01 — Verrouillage après validation
Exigences : EF-M04-10, RG-07.
Étapes : valider une consultation, puis tenter de modifier le diagnostic ; ajouter un addendum.
Résultat attendu : la modification directe est refusée ; l'addendum est enregistré avec auteur et horodatage, le contenu initial restant visible.

CT-M04-02 — Notification d'une maladie à déclaration obligatoire
Exigences : EF-M04-07, EF-M27-03.
Étapes : valider une consultation avec diagnostic de rougeole.
Résultat attendu : une fiche de notification est créée automatiquement, l'alerte apparaît au tableau de bord et la notification figure dans le rapport hebdomadaire de surveillance.

CT-M05-01 — Blocage sur allergie documentée
Exigences : EF-M05-03, RG-10.
Préconditions : allergie au cotrimoxazole enregistrée pour MUKENDI Sarah.
Étapes : prescrire du cotrimoxazole à cette patiente.
Résultat attendu : la prescription est refusée avec rappel de l'allergie ; le passage en force exige une justification écrite, tracée et visible dans le dossier.

CT-M05-02 — Calcul de la quantité à dispenser
Exigences : EF-M05-01, EF-M05-02, EF-M05-04.
Étapes : prescrire de l'amoxicilline en suspension, 50 mg/kg/jour en trois prises pendant cinq jours, pour un enfant de 12 kg.
Résultat attendu : la posologie affichée et la quantité totale sont cohérentes avec le calcul, arrondies au conditionnement, et le coût estimé est affiché avant validation.

CT-M05-03 — Ordinogramme non bloquant
Exigences : EF-M04-03, EF-M05-06.
Étapes : dérouler le protocole paludisme grave puis ignorer la conduite proposée.
Résultat attendu : les propositions sont préremplies mais modifiables ; l'écart avec le protocole est enregistré sans empêcher la validation.

### M06 — Laboratoire

CT-M06-01 — Valeur critique
Exigences : EF-M06-03, EF-M27-02.
Étapes : saisir une hémoglobine à 5,2 g/dl pour un enfant de 3 ans et valider.
Résultat attendu : le résultat est marqué critique, le prescripteur est notifié immédiatement, la notification est journalisée et visible dans la file de consultation.

CT-M06-02 — Consommation de réactifs
Exigences : EF-M06-06.
Étapes : réaliser dix tests de diagnostic rapide du paludisme.
Résultat attendu : le stock de tests diminue de dix unités, la fiche de stock affiche les mouvements avec référence aux demandes d'examen.

CT-M06-03 — Chaîne du froid
Exigences : EF-M06-07, EF-M10-05.
Étapes : saisir une température de 9 °C pour le réfrigérateur des vaccins.
Résultat attendu : alerte immédiate, obligation de saisir une action corrective, mention dans le rapport mensuel matériel.

### M07 — Pharmacie et stock

CT-M07-01 — Solde jamais négatif
Exigences : EF-M07-01, EF-M07-02, RG-04.
Préconditions : 12 unités en stock.
Étapes : tenter une sortie de 15 unités.
Résultat attendu : opération refusée avec le solde disponible affiché ; aucune écriture partielle n'est créée.

CT-M07-02 — Application du FEFO
Exigences : EF-M07-03, RG-05.
Préconditions : lot A périmant en 11/2026 et lot B en 03/2027, tous deux disponibles.
Étapes : dispenser une ordonnance, puis choisir volontairement le lot B.
Résultat attendu : le lot A est proposé par défaut ; le choix du lot B exige un motif, enregistré et consultable dans la fiche de stock.

CT-M07-03 — Dispensation sans prescription
Exigences : EF-M07-09, EF-M07-11, RG-03.
Étapes : tenter une dispensation de médicament sur ordonnance sans prescription rattachée.
Résultat attendu : refus ; seule une vente de produit en accès libre est possible, avec traçabilité de l'agent.

CT-M07-04 — Commande mensuelle et consommation moyenne
Exigences : EF-M07-02, EF-M07-04, EF-M07-05.
Préconditions : trois mois de consommation dont un mois avec sept jours de rupture pour un produit traceur.
Étapes : générer la commande du mois suivant.
Résultat attendu : la consommation moyenne mensuelle exclut le mois en rupture ; stock de sécurité, stock maximum et quantité à commander sont affichés avec leur formule ; le bon de commande imprimé reprend le format officiel.

CT-M07-05 — Inventaire et écarts
Exigences : EF-M07-07, EF-M07-08.
Étapes : ouvrir un inventaire, saisir un comptage inférieur de trois unités pour un produit, tenter de valider sans motif, puis saisir « casse ».
Résultat attendu : validation refusée sans motif ; après motif, un mouvement d'ajustement de perte est créé, les trois unités sortent du stock disponible utilisable et alimentent les pertes du rapport SIGL.

CT-M07-06 — Péremption
Exigences : EF-M07-03, EF-M07-14, EF-M27-02.
Étapes : avancer la date système au-delà de la péremption d'un lot.
Résultat attendu : le lot est exclu du stock disponible utilisable, une alerte est émise 90, 60 et 30 jours avant l'échéance, et la sortie du lot exige un basculement en produits hors d'usage.

### M09 — Maternité et gratuité

CT-M09-01 — Gratuité maternité
Exigences : EF-M09-09, EF-M15-05, EF-M16-07, RG-06.
Étapes : enregistrer un accouchement eutocique éligible, générer la facture, tenter d'encaisser 5 000 CDF auprès de la patiente.
Résultat attendu : la facture affiche une part patient nulle et une part prise en charge par le programme ; l'encaissement est refusé avec le motif réglementaire ; la prestation reste facturable au programme de gratuité.

CT-M09-02 — Partogramme et alertes
Exigences : EF-M09-04, EF-M09-10.
Étapes : saisir des relevés toutes les 30 minutes avec dilatation stagnant à 6 cm pendant quatre heures.
Résultat attendu : le graphique affiche les lignes d'alerte et d'action, une alerte de stagnation est émise, la référence est proposée.

CT-M09-03 — Création du dossier du nouveau-né
Exigences : EF-M02-06, EF-M09-06.
Étapes : enregistrer un nouveau-né vivant de 3 100 g.
Résultat attendu : un dossier patient est créé avec le lien mère-enfant, le calendrier vaccinal est initialisé avec BCG et VPO-0 dus, le certificat de naissance est imprimable.

### M10 — PEV

CT-M10-01 — Intervalle minimal
Exigences : EF-M10-02, EF-M10-03.
Étapes : administrer Penta 1 puis tenter Penta 2 quinze jours après.
Résultat attendu : refus avec rappel de l'intervalle de 28 jours et de la date théorique ; une dérogation motivée reste possible et tracée.

CT-M10-02 — Perdus de vue vaccinaux
Exigences : EF-M10-04, EF-M10-08, EF-M21-04.
Étapes : générer la liste des enfants en retard de Penta 3 pour le village de Kalubwe.
Résultat attendu : liste nominative avec adresse et relais communautaire assigné, imprimable, et traçant le retour de recherche active.

### M14 — Référence et contre-référence

CT-M14-01 — Boucle complète
Exigences : EF-M14-01 à EF-M14-05.
Étapes : référer MUKENDI Sarah vers l'hôpital général, imprimer la fiche, enregistrer la contre-référence reçue une semaine après.
Résultat attendu : la fiche contient le motif, les constantes, les traitements administrés et le destinataire ; la référence sans contre-référence apparaît en attente au-delà de 15 jours ; le rapport mensuel comptabilise une référence et une contre-référence.

### M15 et M16 — Caisse et tiers payants

CT-M15-01 — Éclatement patient et tiers
Exigences : EF-M15-01, EF-M15-02, EF-M16-03, EF-M16-04.
Préconditions : mutuelle MUSOSA, taux 80 %, facture brute de 25 200 CDF.
Étapes : générer la facture de l'épisode de MUKENDI Sarah.
Résultat attendu : part patient 5 040 CDF, part tiers 20 160 CDF, total inchangé, et la facture figure au bordereau mensuel de la mutuelle.

CT-M15-02 — Clôture de caisse avec écart
Exigences : EF-M15-06, EF-M15-07, RG-08.
Étapes : clôturer une session en déclarant 1 000 CDF de moins que le théorique, sans justification, puis avec justification.
Résultat attendu : première tentative refusée ; après justification, la clôture est enregistrée avec l'écart, l'auteur et le motif, et l'écart remonte au tableau de bord de gestion.

CT-M15-03 — Annulation par contre-passation
Exigences : EF-M15-08, EF-M15-09, RG-07.
Étapes : annuler une facture validée.
Résultat attendu : la facture d'origine reste lisible et inchangée ; une facture d'annulation liée est créée avec justification ; les recettes du jour sont recalculées.

CT-M16-01 — Contrôle de validité d'affiliation
Exigences : EF-M16-02.
Étapes : présenter une carte de mutuelle expirée.
Résultat attendu : l'application signale l'expiration, refuse le taux préférentiel par défaut et permet une prise en charge exceptionnelle motivée.

### M17 et M18 — Comptabilité, budget, paie

CT-M17-01 — Période comptable close
Exigences : EF-M17-01, EF-M17-06, RG-12.
Étapes : clôturer le mois d'août, puis tenter d'enregistrer une dépense datée du 20 août.
Résultat attendu : refus avec proposition d'imputation sur la période ouverte ou de réouverture motivée par un profil habilité, la réouverture étant journalisée.

CT-M17-02 — Suivi budgétaire
Exigences : EF-M17-04.
Étapes : engager une dépense de médicaments dépassant la ligne budgétaire.
Résultat attendu : alerte de dépassement avec taux d'exécution affiché ; l'engagement reste possible avec validation hiérarchique tracée.

CT-M18-01 — Bulletin de paie
Exigences : EF-M18-02, EF-M18-05.
Étapes : calculer la paie du mois pour sept agents dont un absent cinq jours non justifiés.
Résultat attendu : les retenues correspondent aux absences, les primes de performance issues du financement basé sur la performance sont ventilées selon la clé paramétrée, et le bulletin imprimé est équilibré.

### M22 — SNIS

CT-M22-01 — Rapport calculé sans ressaisie
Exigences : EF-M22-01, EF-M22-02, EF-M22-08.
Préconditions : mois de septembre complet dans le jeu de démonstration.
Étapes : générer le rapport SNIS du centre de santé.
Résultat attendu : toutes les rubriques calculables sont remplies ; chaque valeur est traçable jusqu'aux enregistrements sources par un clic ; seules les rubriques sans source (financement indirect) restent en saisie manuelle et sont signalées.

CT-M22-02 — Contrôles de cohérence bloquants
Exigences : EF-M22-03.
Étapes : forcer une valeur de nouveaux cas supérieure aux cas reçus, puis tenter de transmettre.
Résultat attendu : le contrôle CTL-001 signale l'incohérence en anomalie bloquante ; la transmission est refusée jusqu'à correction ou justification autorisée.

CT-M22-03 — Gel de la période transmise
Exigences : EF-M22-05, EF-M22-06, RG-11.
Étapes : transmettre le rapport de septembre, puis enregistrer une consultation datée du 28 septembre.
Résultat attendu : la saisie rétroactive est refusée ou orientée vers un rapport rectificatif ; le rectificatif crée une version 2 sans écraser la version 1, et l'écart entre versions est consultable.

CT-M22-04 — Export DHIS2 hors ligne
Exigences : EF-M22-04, EF-M28-03.
Étapes : couper le réseau, transmettre le rapport, rétablir le réseau après 30 minutes.
Résultat attendu : l'export est mis en file avec le statut en attente ; il est envoyé automatiquement au retour du réseau ; la réponse du serveur, y compris les conflits, est conservée et lisible en français.

### M23 — FBP et qualité

CT-M23-01 — Traçabilité des quantités déclarées
Exigences : EF-M23-02, EF-M23-03.
Étapes : générer la déclaration du mois, puis tirer un échantillon de dix prestations pour un indicateur.
Résultat attendu : chaque ligne déclarée est reliée à ses enregistrements primaires, avec numéro de dossier, date et registre d'origine, ce qui permet la contre-vérification sans recomptage manuel.

### M24 — Tableaux de bord

CT-M24-01 — Cohérence tableau de bord et rapport
Exigences : EF-M24-02.
Étapes : comparer les indicateurs affichés au tableau de bord et les valeurs du rapport transmis pour le même mois.
Résultat attendu : valeurs identiques ; toute différence est expliquée par un filtre affiché à l'écran.

### M25 — Sécurité et audit

CT-M25-01 — Habilitations
Exigences : EF-M25-01, EF-M25-02.
Étapes : avec un compte de caissier, tenter d'ouvrir une consultation, de modifier un tarif et d'exporter la base.
Résultat attendu : les trois actions sont refusées, chaque tentative est journalisée, aucun contournement n'est possible par l'adresse directe d'un écran.

CT-M25-02 — Journal inaltérable
Exigences : EF-M25-03, EF-M25-04.
Étapes : tenter de modifier ou supprimer une entrée d'audit par l'application, puis vérifier le comportement en base.
Résultat attendu : opération impossible dans l'application ; en base, les règles de protection rejettent la modification et la suppression.

CT-M25-03 — Verrouillage de session
Exigences : EF-M25-02.
Étapes : laisser un poste inactif au-delà du délai paramétré.
Résultat attendu : la session est verrouillée, la ressaisie du mot de passe est exigée, le travail en cours n'est pas perdu.

### M26 — Synchronisation et sauvegardes

CT-M26-01 — Travail hors ligne prolongé
Exigences : EF-M26-01, EF-M26-02, EF-M26-04, ENF-O01.
Étapes : couper la liaison 72 heures, réaliser 150 venues, consultations, dispensations et encaissements, puis rétablir.
Résultat attendu : aucune fonction de soins n'est indisponible hors ligne ; à la reconnexion, la totalité des enregistrements est synchronisée sans perte ni doublon, et le compte rendu de synchronisation est consultable.

CT-M26-02 — Conflit de modification
Exigences : EF-M26-03.
Étapes : modifier le même dossier patient sur deux postes déconnectés, puis synchroniser.
Résultat attendu : le conflit est détecté et présenté avec les deux versions ; l'arbitrage est manuel et journalisé ; aucune donnée n'est écrasée silencieusement.

CT-M26-03 — Restauration de sauvegarde
Exigences : EF-M25-05, EF-M25-06, EF-M26-06.
Étapes : provoquer la perte du serveur local, restaurer la sauvegarde chiffrée de la veille sur un poste neuf.
Résultat attendu : restauration réussie en moins de deux heures ; écart de données limité aux opérations postérieures à la dernière sauvegarde ; le test de restauration est consigné avec sa date.

### M27 et M28 — Notifications et interopérabilité

CT-M27-01 — Rappel de rendez-vous
Exigences : EF-M27-01, EF-M27-04.
Étapes : planifier un rendez-vous CPN à J+7 pour une patiente ayant consenti aux messages.
Résultat attendu : le rappel est programmé, envoyé ou mis en file selon la connectivité, et l'absence de consentement empêche tout envoi.

CT-M28-01 — Conformité de l'interface applicative
Exigences : EF-M28-01.
Étapes : valider la spécification `openapi.yaml` avec un outil de validation, puis appeler dix points d'entrée représentatifs.
Résultat attendu : spécification valide ; réponses conformes aux schémas annoncés ; toute écriture sans jeton est refusée.

## 8. Scénarios de bout en bout

Les quinze scénarios T01 à T15 du cahier des charges sont rejoués intégralement en recette, dans l'ordre chronologique d'une journée puis d'un mois de travail. Ils sont exécutés par le personnel du centre, non par l'éditeur, avec chronométrage des étapes.

| Scénario | Résumé | Durée cible |
| --- | --- | --- |
| T01 | Nouveau patient, consultation, examen, ordonnance, paiement, sortie | moins de 12 minutes hors attente |
| T02 | Patient connu revenant dans les 14 jours | moins de 6 minutes |
| T03 | Urgence pédiatrique avec référence | moins de 15 minutes |
| T04 | CPN complète avec vaccination antitétanique et moustiquaire | moins de 10 minutes |
| T05 | Accouchement avec partogramme et gratuité | suivi continu |
| T06 | Séance de vaccination en stratégie avancée hors ligne | 40 enfants en 2 heures |
| T07 | Dispensation avec rupture et substitution | moins de 4 minutes |
| T08 | Réception d'une commande et mise à jour du stock | moins de 30 minutes |
| T09 | Inventaire mensuel avec écarts | moins de 3 heures |
| T10 | Clôture de caisse journalière et versement | moins de 15 minutes |
| T11 | Bordereau mensuel de mutuelle | moins de 30 minutes |
| T12 | Génération, contrôle et transmission du rapport SNIS | moins de 2 heures contre plusieurs jours sur papier |
| T13 | Déclaration du financement basé sur la performance et contre-vérification | moins de 1 heure |
| T14 | Supervision de la zone de santé avec accès aux preuves | séance de 2 heures |
| T15 | Panne électrique, bascule sur onduleur, reprise et synchronisation | reprise sans perte |

## 9. Tests non fonctionnels

| Code | Test | Critère d'acceptation |
| --- | --- | --- |
| ENF-P01 | Temps de réponse des écrans courants sur poste d'entrée de gamme | 95e centile inférieur à 2 secondes |
| ENF-P02 | Recherche patient sur 50 000 dossiers | moins de 1 seconde |
| ENF-P03 | Génération du rapport mensuel | moins de 60 secondes |
| ENF-P04 | Dix postes simultanés en pointe | aucune dégradation supérieure à 30 % |
| ENF-P05 | Impression d'un reçu thermique | moins de 3 secondes |
| ENF-P06 | Démarrage complet du poste | moins de 60 secondes |
| ENF-O01 | Autonomie hors ligne | 30 jours de fonctionnement complet |
| ENF-S01 | Test d'intrusion applicatif sur les rôles et les accès directs | aucune élévation de privilège |
| ENF-S02 | Chiffrement au repos et en transit | vérifié par inspection technique |
| ENF-S03 | Politique de mots de passe et verrouillage après échecs | conforme au paramétrage |
| ENF-F01 | Coupure électrique brutale pendant une écriture | aucune corruption, reprise automatique |
| ENF-F02 | Perte du serveur, restauration | objectif de reprise inférieur à 2 heures, perte de données inférieure à 24 heures |
| ENF-U01 | Prise en main par un agent non informaticien | tâches courantes réalisées après 4 heures de formation |
| ENF-U02 | Utilisation sur écran de 10 pouces | tous les écrans utilisables sans défilement horizontal |

## 10. Conduite de la campagne

Organisation d'une campagne de recette usine sur dix jours ouvrés :

| Jour | Contenu |
| --- | --- |
| 1 | Installation, chargement du jeu de données, vérification des habilitations |
| 2 à 3 | Modules d'accueil, consultation, prescription, laboratoire |
| 4 à 5 | Pharmacie, stock, commandes, inventaire |
| 6 | Maternité, PEV, programmes verticaux, nutrition |
| 7 | Caisse, tiers payants, comptabilité, paie |
| 8 | SNIS, financement basé sur la performance, tableaux de bord |
| 9 | Sécurité, synchronisation, sauvegarde et restauration, tests non fonctionnels |
| 10 | Rejeu des anomalies corrigées, réunion de clôture, procès-verbal |

Chaque journée se termine par un relevé d'anomalies partagé, avec gravité proposée par le testeur et confirmée en séance.

## 11. Modèle de procès-verbal de recette

Le procès-verbal comporte : version livrée et empreinte de la livraison, période et lieu de la recette, liste des participants et de leurs fonctions, nombre d'exigences vérifiées par priorité, liste des anomalies par gravité avec leur statut, réserves éventuelles avec échéance de levée, décision finale parmi acceptation, acceptation sous réserves ou refus, puis signatures du commanditaire, de l'infirmier titulaire et de l'éditeur.

## 12. Traçabilité

Le fichier `matrice_tracabilite.csv` relie chaque exigence du cahier des charges à son module, sa priorité, le ou les cas de test qui la vérifient et le livrable concerné. Il sert de support unique de suivi pendant la recette : une exigence non reliée à un cas de test exécuté ne peut pas être déclarée acceptée.
