# Cahier des charges — Application de gestion complète d'un centre de santé

Version 1.0 — 22 septembre 2026
Contexte de référence : République Démocratique du Congo (zone de santé, aire de santé), déployable dans d'autres contextes d'Afrique centrale.
Statut : document de référence pour la conception, le développement, la recette et le déploiement.

---

## 1. Préambule et objet du document

### 1.1 Objet

Ce cahier des charges définit l'ensemble des besoins fonctionnels, techniques, réglementaires et organisationnels d'une application de gestion intégrée d'un centre de santé (CS). Il sert de référence contractuelle entre le commanditaire (direction du centre de santé, ONG, réseau de structures, ministère) et l'équipe de réalisation, et de base à la recette.

### 1.2 Méthode d'élaboration

Le périmètre fonctionnel n'a pas été déduit d'un catalogue de logiciel générique : il a été construit à partir de l'étude du fonctionnement réel d'un centre de santé et des obligations qui pèsent sur lui :

- le **Recueil des normes de création, d'organisation et de fonctionnement des structures de la zone de santé en RDC** (Ministère de la Santé Publique, 2019), qui définit le Paquet Minimum d'Activités (PMA), les services, les locaux et les catégories de personnel ([Recueil des normes MSP 2019](https://bv-assk.org/wp-content/uploads/2024/03/Recueil-des-normes-de-creation-dorganisation-de-fonctionnement-des-structures-de-la-ZS-en-RDC-MSP-2019.pdf)) ;
- l'**arrêté du 15 septembre 2017** instituant les outils minimum de gestion standardisés (circuit du malade, pharmacie, finances, ressources humaines), qui énumère nominativement les registres, fiches et pièces comptables à tenir ([arrêté sur les outils de standardisation](https://www.droitcongolais.info/files/810.09.17.2-Arrete-du-15-septembre-2017_outils-de-standardisartion.pdf)) ;
- le **canevas SNIS du rapport mensuel du centre de santé**, qui fixe la structure exacte des données à rapporter mensuellement ([canevas SNIS CS](https://bv-assk.org/wp-content/uploads/2024/03/Canevas-SNIS-CS-AVEC-VPI2-ET-VAR-2-OK.pdf)) ;
- le **manuel descriptif du SIGL** (système d'information en gestion logistique) pour la gestion des médicaments et intrants ([manuel SIGL, ASRAMES 2020](https://asrames.org/wp-content/uploads/2020/06/Manuel-Descriptif-du-SIGL-version-Mai-2020.pdf)) ;
- le **manuel opérationnel du Financement Basé sur la Performance (FBP/PDSS)**, qui définit les prestations achetées, les outils de vérification et les critères de qualité ([manuel FBP PDSS](https://santenews.info/wp-content/uploads/2020/04/Manuel_PBF_PDSS_FINANCEMENT.pdf)) ;
- le cadre juridique du numérique et des données personnelles, notamment l'**ordonnance-loi n° 23/010 du 13 mars 2023 portant Code du numérique** ([synthèse du Livre III du Code du numérique](https://www.anove.ai/fr/regulations/drc-digital-code-book-iii)) ;
- le cadre de financement en évolution : **gratuité de la maternité et des soins du nouveau-né** lancée en septembre 2023 et étendue progressivement ([UNFPA RDC](https://drc.unfpa.org/fr/news/lancement-de-la-gratuit%C3%A9-des-accouchements-en-rdc), [Ministère de la Santé Publique](https://sante.gouv.cd/actualites/revue-annuelle-du-programme-de-la-gratuite-de-la-maternite-et-des-soins-du-nouveau-ne)), mutuelles de santé en tiers payant ([OIT, guide de gestion des mutuelles de santé](https://www.ilo.org/sites/default/files/wcmsp5/groups/public/@ed_protect/@soc_sec/documents/instructionalmaterial/wcms_secsoc_106.pdf)), paiement direct encore dominant ([analyse du financement des soins en RDC](https://ccsc-rdc.com/doc/02-Analyse-des-modalit%C3%A9s-de-financement-des-soins-de-sant%C3%A9-en-R%C3%A9publique-d%C3%A9mocratique-du-Congo.pdf)).

### 1.3 Documents de référence applicables

| Réf. | Document | Usage dans le projet |
|---|---|---|
| R1 | Recueil des normes de la zone de santé, MSP, 2019 | Périmètre métier, PMA, services, personnel |
| R2 | Arrêté du 15/09/2017 — outils minimum de gestion | Liste exhaustive des documents à dématérialiser |
| R3 | Canevas SNIS mensuel CS (édition 2019 et versions simplifiées ultérieures) | Modèle du rapport mensuel et des agrégats |
| R4 | Manuel descriptif du SIGL, 2020 | Règles de gestion de la pharmacie |
| R5 | Manuel opérationnel FBP / PDSS | Indicateurs achetés, vérifiabilité, qualité |
| R6 | Ordonnance-loi n° 23/010 du 13 mars 2023 (Code du numérique) | Protection des données, conservation, consentement |
| R7 | Loi n° 18/035 du 13 décembre 2018 telle que modifiée par l'ordonnance-loi n° 23/006 du 3 mars 2023 | Principes fondamentaux de l'organisation de la santé publique, assistance médicale ([texte](https://www.annuairetravail-rdc.cd/admin/pdf_storage/ordonnance-loi-n-23-006-du-3-mars-2023-modifiant-et-completant-la-loi-n-18-035-du-13-decembre-2018-fixant-les-principes-fondamentaux-relatifs-a-l-organisation-de-la-sante-publique_695638331dd6d.pdf)) |
| R8 | CIM-10 (OMS), LOINC, DCI, HL7 FHIR R4 | Terminologies et interopérabilité |
| R9 | Spécifications DHIS2 et InfoMED RDC | Export des rapports SNIS et SIGL |

---

## 2. Compréhension du métier : comment fonctionne un centre de santé

Cette section est la base de justification de chaque exigence fonctionnelle. Elle décrit la réalité opérationnelle que l'application doit refléter, et non un modèle abstrait.

### 2.1 Place du centre de santé dans le système

Le centre de santé est la structure du premier échelon d'une aire de santé. Il dessert une population de 5 000 à 10 000 habitants, dans un rayon d'action de 8 à 15 km, et chaque aire de santé doit disposer d'un CS. Il est supervisé par l'Équipe Cadre de la Zone de Santé (ECZS) et réfère les cas qui dépassent le PMA vers l'Hôpital Général de Référence (HGR), qui offre le Paquet Complémentaire d'Activités ([Recueil des normes MSP 2019](https://bv-assk.org/wp-content/uploads/2024/03/Recueil-des-normes-de-creation-dorganisation-de-fonctionnement-des-structures-de-la-ZS-en-RDC-MSP-2019.pdf)). La zone de santé compte au moins 100 000 habitants et est dirigée par un médecin chef de zone ([Plan National de Développement Sanitaire](https://www.prb.org/wp-content/uploads/2020/06/RDC-Plan-National-de-Developpement-Sanitaire-2016-2020.pdf)).

Conséquences pour l'application :
- l'application est **mono-établissement par défaut mais multi-structures en option** (réseau, zone de santé), avec hiérarchie Province → Zone de santé → Aire de santé → Structure ;
- la **référence / contre-référence** vers l'HGR est un processus de première classe, pas un simple champ texte ;
- le **dénominateur population** de l'aire de santé doit être paramétrable pour calculer les taux de couverture.

### 2.2 Les services du centre de santé

Les normes exigent les services suivants : réception, consultation, soins, maternité, observation, laboratoire, logistique et maintenance. La maternité comporte 5 lits (2 de travail, 2 d'observation, 1 table d'accouchement), l'observation 2 lits, pour une surface bâtie normative d'environ 140 m² ([Recueil des normes MSP 2019](https://bv-assk.org/wp-content/uploads/2024/03/Recueil-des-normes-de-creation-dorganisation-de-fonctionnement-des-structures-de-la-ZS-en-RDC-MSP-2019.pdf)).

L'application doit donc couvrir **7 unités fonctionnelles** et non seulement « consultation + caisse ».

### 2.3 Le Paquet Minimum d'Activités (PMA) à informatiser

| Domaine | Activités du PMA (source R1) | Traduction applicative |
|---|---|---|
| Curatif | Consultations curatives, PCIME, prise en charge des IST, dépistage et traitement des maladies chroniques (HTA, diabète, VIH, THA, tuberculose), petites interventions médico-chirurgicales, accouchements eutociques, traitement du paludisme simple selon la politique nationale, réhabilitation nutritionnelle, kinésithérapie respiratoire, transfusion sanguine | Module consultation, module actes/petite chirurgie, module maternité, protocoles et ordinogrammes intégrés, suivi des cohortes chroniques |
| Observation | Surveillance des malades sous traitement | Module observation / mini-hospitalisation avec lits, signes vitaux, feuille de traitement |
| Laboratoire | TDR, hémoglobine, test rapide VIH, selles fraîches, numération globulaire, test d'Emmel, sédiment urinaire, vitesse de sédimentation | Module laboratoire avec catalogue d'examens, bon d'analyse, saisie et rendu de résultats |
| Pharmacie | Gestion du stock de médicaments, officine de vente | Module pharmacie + dispensation + RUMER |
| Préventif | Surveillance de la croissance des moins de 5 ans, CPN recentrées, TPI, planification familiale, CPoN, vaccination, zinc et mébendazole, vitamine A, dépistage des infirmités, dépistage conseil initié par le prestataire, dépistage lèpre et tuberculose, prophylaxie au cotrimoxazole, prise en charge des personnes âgées | Modules CPN, CPoN, CPS, PEV, PF, dépistage, avec échéanciers et rappels |
| Promotion | Préservatifs, assainissement, allaitement maternel exclusif, nutrition, sel iodé, MILDA, latrines, lutte contre les maladies diarrhéiques | Module activités de promotion et séances de sensibilisation |
| Réadaptation | Détection et référence précoce des infirmités (audiologie, kinésithérapie, mobilité, acuité visuelle) | Fiches de dépistage fonctionnel et référence |
| Gestion | Gestion des ressources humaines, matérielles et financières, gestion des médicaments, formation continue, planification et supervision des activités communautaires, monitorage de l'aire de santé, encadrement des relais, gestion de l'information sanitaire | Modules RH, finances, stock, monitorage, SNIS |
| Communautaire | Activités des RECO/CAC, visites à domicile, récupération des perdus de vue, PCIME communautaire, sites de soins communautaires, soins palliatifs à domicile | Module communautaire : RECO, sites de soins, perdus de vue |

### 2.4 Le circuit du patient tel qu'il se déroule réellement

1. **Arrivée et accueil.** Le patient se présente à la réception. Le FBP exige un circuit affiché, un personnel d'accueil, un système d'attente par cartes numérotées, avec des jetons distincts pour les cas urgents et référés ([manuel FBP PDSS](https://santenews.info/wp-content/uploads/2020/04/Manuel_PBF_PDSS_FINANCEMENT.pdf)).
2. **Identification.** Recherche du patient dans le registre des malades ; s'il est nouveau, ouverture d'un dossier et remise d'une carte du patient. Les outils normatifs de la réception sont : registre de malades, fiche de consultation, carte du patient, carte CPN, carte CPS (R2).
3. **Triage.** Registre de triage et fiche d'identification (R2) ; priorisation des urgences.
4. **Tarification et paiement.** Les tarifs forfaitaires ou de recouvrement des coûts doivent être affichés, avec prix unitaire par acte ou produit et prix du traitement standard (R5). Le paiement peut être direct, différé, pris en charge par une mutuelle en tiers payant, couvert par la gratuité maternité/nouveau-né, ou exonéré (indigent).
5. **Consultation.** Cabinet de consultation : registre de consultation, bon d'analyses, ordonnance médicale, carte de rendez-vous, fiche d'hospitalisation (R2). Les ordinogrammes et protocoles nationaux (paludisme, IRA, diarrhée) doivent être accessibles dans la salle (R5). La salle doit être séparée de la salle d'attente pour la confidentialité (R5).
6. **Examens complémentaires.** Laboratoire : registre de laboratoire, registre de résultats, fiche de rendu de résultat, carte de groupe sanguin, fiche de compatibilité, fiche de surveillance de température (R2).
7. **Traitement et dispensation.** Pharmacie : sortie de stock par DCI, enregistrement dans le registre de consommation journalière et le RUMER (R4).
8. **Observation ou maternité.** Feuille de signes vitaux, feuille de traitement, feuille d'évolution, feuille de température, fiche de transfusion, plan de soins ; maternité : partogramme, registre de travail, registre d'accouchement, certificat de naissance, feuille de protocole d'accouchement (R2).
9. **Sortie.** Note médicale de sortie, billet de transfert, rapport médical, attestation médicale, carte de rendez-vous, billet de sortie, certificat de décès (R2).
10. **Référence.** Billet de référence, fiche de contre-référence, registre des malades référés, classement des lettres de contre-référence, et moyen de communication dédié avec l'HGR (R5).
11. **Suivi communautaire.** Récupération des perdus de vue par les RECO, visites à domicile, notification des cas.

### 2.5 Les cycles de gestion mensuels

| Cycle | Contenu | Échéance de référence |
|---|---|---|
| Rapport mensuel SNIS | Consultations et morbidité, santé de la mère, PF, santé de l'enfant et PEV, laboratoire, nutrition (UNTA/UNS), références et observation, décès par cause et groupe d'âge, activités communautaires, supervision, personnel, recettes et dépenses, valeur de la pharmacie, matériel et équipement (R3) | Transmission à l'ECZS, saisie dans DHIS2 au niveau du BCZS |
| Commande de médicaments | Les FOSA commandent mensuellement auprès du BCZS au plus tard le 5 du mois ; le BCZS rapporte au plus tard le 10 du mois suivant la période ([manuel SIGL](https://asrames.org/wp-content/uploads/2020/06/Manuel-Descriptif-version-revis%C3%A9e-Mai-2020.pdf)) | Calendrier paramétrable |
| Rapport de gestion des médicaments | Rapport synthèse mensuel FOSA : stock disponible utilisable, quantité consommée, pertes, nombre de jours de rupture (R4) | Mensuel |
| Facturation FBP | Bordereau de déclaration des prestations à subventionner, vérification quantitative sur les registres, évaluation qualitative, contre-vérification communautaire (R5) | Mensuel / trimestriel |
| Monitorage de l'aire de santé | Taux de couverture par service, cartographie des villages, analyse des écarts | Mensuel / trimestriel |
| Clôture financière | Rapport de caisse, journal de caisse, bordereau de versement, plan et rapport de trésorerie, suivi budgétaire (R2) | Journalier et mensuel |

### 2.6 Les acteurs et leurs besoins

| Acteur | Rôle | Besoins principaux |
|---|---|---|
| Infirmier Titulaire (IT) | Responsable du CS | Pilotage, validation des rapports, visa du RUMER, supervision, tableau de bord |
| Infirmier A1/A2/L2 | Consultations, soins, préventif | Saisie rapide, ordinogrammes, faible latence, fonctionnement hors ligne |
| Accoucheuse / sage-femme | Maternité, CPN, CPoN | Partogramme, registre d'accouchement, gratuité maternité |
| Technicien de laboratoire | Examens | File d'attente des demandes, saisie de résultats, contrôle des réactifs |
| Gestionnaire de pharmacie | Stock et dispensation | Fiche de stock, inventaires, commandes, péremptions, FEFO |
| Caissier / trésorier | Recettes | Encaissements, reçus, journal de caisse, versements |
| Comptable / gestionnaire | Finances | Budget, trésorerie, états financiers, paie |
| Nutritionniste | UNTA/UNS | Admissions, suivi anthropométrique, issues |
| Relais communautaire (RECO) | Activités communautaires | Saisie simplifiée mobile, visites à domicile, perdus de vue |
| ECZS / BCZS | Supervision, agrégation | Rapports conformes, exports DHIS2, grilles de supervision |
| Partenaires / bailleurs | Financement, FBP | Indicateurs vérifiables, traçabilité, pistes d'audit |
| Patient | Bénéficiaire | Attente réduite, carte de patient, confidentialité, ordonnance et résultats lisibles |

Les catégories de personnel à gérer découlent du canevas SNIS : infirmier L2, A1, A2, accoucheur(se)/sage-femme, nutritionniste A2/A1/L2, technicien de laboratoire A2/A1/L2, médecin généraliste, autre personnel, avec jours prévus, jours prestés et absences justifiées (R3).

### 2.7 Contraintes du terrain à intégrer dès la conception

| Contrainte observée | Conséquence de conception |
|---|---|
| Électricité intermittente | Mode hors ligne complet, sauvegarde continue, tolérance aux coupures, reprise sans perte, alimentation sur onduleur/solaire |
| Connectivité faible ou absente | Architecture local-first, synchronisation différée, compression, coût data maîtrisé |
| Matériel modeste | Fonctionnement sur PC d'entrée de gamme, tablette Android, impression sur imprimante thermique/A5 |
| Personnel peu familier de l'outil informatique | Interfaces en français simple, calquées sur les registres papier, nombre minimal de clics, saisie au clavier possible sans souris |
| Coexistence papier / numérique pendant la transition | Impression des registres et fiches au format officiel, numéros d'ordre identiques, reprise de données rétroactive |
| Pluralité de payeurs | Moteur de tarification et de prise en charge multi-régimes |
| Rotation du personnel | Gestion fine des comptes, habilitations, journalisation |
| Vérification externe (FBP, audits) | Traçabilité inaltérable, horodatage, non-suppression des enregistrements validés |

---

## 3. Objectifs, périmètre et exclusions

### 3.1 Objectifs

| Code | Objectif | Indicateur de succès |
|---|---|---|
| O1 | Dématérialiser l'intégralité des outils minimum de gestion exigés (R2) | 100 % des registres du périmètre produits par l'application |
| O2 | Produire automatiquement le rapport mensuel SNIS conforme au canevas (R3) | Rapport généré sans ressaisie, complétude 100 %, promptitude avant le 5 |
| O3 | Réduire le temps d'accueil et de consultation | Temps moyen accueil → consultation réduit d'au moins 40 % |
| O4 | Supprimer les ruptures de stock évitables | Jours de rupture des produits traceurs réduits d'au moins 50 % |
| O5 | Sécuriser les recettes | Écart caisse/registre inférieur à 1 %, 100 % des actes encaissés rattachés à un patient |
| O6 | Rendre les données vérifiables pour le FBP et les audits | Taux d'écart à la contre-vérification inférieur à 5 % |
| O7 | Fonctionner sans internet ni électricité continue | Zéro perte de données sur coupure, 30 jours d'autonomie hors ligne |
| O8 | Respecter la réglementation sur les données personnelles (R6) | Registre des traitements, chiffrement, politique de conservation en place |

### 3.2 Périmètre fonctionnel (modules)

M01 Référentiels et paramétrage · M02 Identité patient et dossier unique · M03 Accueil, file d'attente et triage · M04 Consultation curative et dossier médical · M05 Prescription et aide à la décision · M06 Laboratoire · M07 Pharmacie et stock · M08 Observation et lits · M09 Maternité, CPN, CPoN et gratuité · M10 Santé de l'enfant, CPS et PEV · M11 Planification familiale · M12 Nutrition (UNTA/UNS) · M13 Programmes verticaux (paludisme, tuberculose, VIH/PTME, IST, maladies chroniques) · M14 Référence et contre-référence · M15 Caisse, tarification et facturation · M16 Tiers payants, mutuelles et régimes de gratuité · M17 Comptabilité et budget · M18 Ressources humaines et paie · M19 Immobilisations, équipements et maintenance · M20 Hygiène, déchets et stérilisation · M21 Activités communautaires et RECO · M22 SNIS, DHIS2 et rapports réglementaires · M23 FBP et qualité · M24 Tableaux de bord et monitorage · M25 Administration, sécurité et audit · M26 Synchronisation et multi-sites · M27 Notifications SMS/USSD · M28 Interopérabilité (FHIR, SIGL/InfoMED, mobile money).

### 3.3 Hors périmètre (v1)

Imagerie médicale et PACS ; bloc opératoire lourd et anesthésie ; téléconsultation vidéo ; comptabilité consolidée multi-entités au format SYSCOHADA complet (v1 limitée à la comptabilité de trésorerie et au plan de comptes simplifié) ; gestion de la paie déclarative CNSS/INPP automatisée (v1 produit les états, pas les télédéclarations) ; portail patient public.

---

## 4. Exigences fonctionnelles détaillées

Convention : `EF-Mxx-nn`. Priorité : **I** indispensable (v1), **S** souhaitable (v1.1), **O** optionnel.

### M01 — Référentiels et paramétrage

| Code | Exigence | Prio |
|---|---|---|
| EF-M01-01 | Paramétrer la structure : nom, type (CS, CSR, poste de santé, HGR), province, zone de santé, aire de santé, code SNIS, population de responsabilité par année, villages et quartiers rattachés | I |
| EF-M01-02 | Gérer le référentiel des services et unités fonctionnelles (réception, consultation, soins, maternité, observation, laboratoire, pharmacie, logistique) | I |
| EF-M01-03 | Gérer le catalogue des actes et prestations avec code, libellé, unité, tarif, service, durée, coût de revient indicatif | I |
| EF-M01-04 | Gérer le référentiel des diagnostics basé sur la CIM-10, avec sous-ensemble « maladies à notification obligatoire » du canevas SNIS et libellés locaux | I |
| EF-M01-05 | Gérer le référentiel des examens de laboratoire aligné sur LOINC, avec valeurs de référence par âge et sexe, unités et seuils d'alerte | I |
| EF-M01-06 | Gérer le référentiel des médicaments en DCI, forme, dosage, conditionnement, classe thérapeutique, statut « liste nationale des médicaments essentiels », produit traceur oui/non, chaîne du froid oui/non | I |
| EF-M01-07 | Gérer les grilles tarifaires multiples : tarif forfaitaire par épisode, tarif à l'acte, tarif par régime de prise en charge, date d'effet et historique | I |
| EF-M01-08 | Gérer les jours fériés, horaires d'ouverture, tours de garde et roulements de service | I |
| EF-M01-09 | Gérer les unités de mesure, devises (CDF, USD) avec taux de change daté et arrondis paramétrables | I |
| EF-M01-10 | Importer/exporter tous les référentiels en CSV/Excel pour initialisation et mise à jour de masse | I |
| EF-M01-11 | Versionner les référentiels : toute modification conserve l'historique et n'altère pas les enregistrements passés | I |
| EF-M01-12 | Paramétrer les ordinogrammes et protocoles nationaux (paludisme, IRA, diarrhée, PCIME, IST) sous forme d'arbres de décision éditables sans redéploiement | S |

### M02 — Identité patient et dossier unique

| Code | Exigence | Prio |
|---|---|---|
| EF-M02-01 | Créer un patient avec identifiant unique permanent (numéro de dossier) et code-barres/QR imprimable sur la carte du patient | I |
| EF-M02-02 | Champs minimaux : nom, post-nom, prénom, sexe, date de naissance ou âge estimé, état civil, profession, téléphone, adresse (avenue, quartier, village, aire de santé), personne à contacter, provenance (zone de santé / hors zone) | I |
| EF-M02-03 | Gérer les cas d'âge inconnu (âge déclaré, année approximative) et les nouveau-nés sans prénom, avec régularisation ultérieure | I |
| EF-M02-04 | Recherche tolérante aux fautes : phonétique adaptée aux noms locaux, recherche par téléphone, par numéro de dossier, par scan de carte, par nom de la mère | I |
| EF-M02-05 | Détecter les doublons à la création (score de similarité) et permettre la fusion de dossiers avec conservation de l'historique et de la trace de fusion | I |
| EF-M02-06 | Gérer les liens familiaux : ménage, mère–enfant (obligatoire pour la CPS, le PEV et la PTME), tuteur | I |
| EF-M02-07 | Rattacher un patient à un ou plusieurs régimes de prise en charge : payant, mutualiste (n° d'affiliation, mutuelle, taux), indigent (décision et validité), gratuité maternité/nouveau-né, programme vertical, employeur conventionné | I |
| EF-M02-08 | Dossier patient chronologique unique consolidant consultations, examens, prescriptions, dispensations, vaccins, hospitalisations, accouchements, factures, références | I |
| EF-M02-09 | Marquer les alertes cliniques : allergies, groupe sanguin, pathologies chroniques, traitements au long cours, grossesse en cours | I |
| EF-M02-10 | Gérer le consentement du patient au traitement de ses données et à la réception de SMS, conformément au Code du numérique (R6) | I |
| EF-M02-11 | Journaliser tout accès en lecture au dossier d'un patient (qui, quand, quoi) | I |

### M03 — Accueil, file d'attente et triage

| Code | Exigence | Prio |
|---|---|---|
| EF-M03-01 | Enregistrer une venue (épisode de soins) avec date, heure, motif, type (nouveau cas, ancien cas, référé, urgence, préventif) | I |
| EF-M03-02 | Distinguer explicitement **nouveau cas / ancien cas** selon les règles SNIS, avec calcul automatique proposé et possibilité de correction motivée | I |
| EF-M03-03 | Gérer une file d'attente par service, avec numéro d'ordre, jeton de couleur pour urgence/référé, et affichage écran ou impression de ticket | I |
| EF-M03-04 | Triage avec constantes (poids, taille, température, tension, pouls, fréquence respiratoire, SpO2, périmètre brachial) et calcul automatique IMC, z-scores, signes de danger PCIME | I |
| EF-M03-05 | Orienter automatiquement vers le service compétent selon le motif et le triage | I |
| EF-M03-06 | Afficher au patient le circuit et le tarif applicable avant la prestation (exigence FBP d'affichage des tarifs) | I |
| EF-M03-07 | Mesurer et restituer les temps d'attente par étape | S |

### M04 — Consultation curative et dossier médical

| Code | Exigence | Prio |
|---|---|---|
| EF-M04-01 | Saisir une consultation structurée : plainte principale, anamnèse, antécédents, examen physique par appareil, hypothèses, diagnostic retenu codé CIM-10, diagnostics associés, conduite à tenir | I |
| EF-M04-02 | Proposer des modèles de consultation par motif fréquent et la reprise des données de la venue précédente | I |
| EF-M04-03 | Appliquer les ordinogrammes PCIME et protocoles nationaux avec suggestion de conduite, sans blocage du prescripteur | I |
| EF-M04-04 | Gérer les actes réalisés en salle de soins : pansement, injection, suture, petite chirurgie, perfusion, transfusion, avec traçabilité du praticien et des consommables | I |
| EF-M04-05 | Générer automatiquement le **registre de consultation curative** conforme, imprimable et exportable | I |
| EF-M04-06 | Gérer les rendez-vous et la carte de rendez-vous, avec liste des rendez-vous manqués | I |
| EF-M04-07 | Gérer la déclaration des maladies à notification obligatoire avec alerte immédiate et fiche de notification | I |
| EF-M04-08 | Enregistrer les décès avec cause et groupe d'âge conformément au canevas SNIS, et produire le certificat de décès | I |
| EF-M04-09 | Gérer la prise en charge des survivants de violences sexuelles avec confidentialité renforcée et accès restreint | I |
| EF-M04-10 | Verrouiller une consultation validée : plus de modification silencieuse, seulement des addenda tracés | I |

### M05 — Prescription et aide à la décision

| Code | Exigence | Prio |
|---|---|---|
| EF-M05-01 | Prescrire en DCI avec posologie structurée (dose, voie, fréquence, durée), calcul automatique de la quantité à dispenser | I |
| EF-M05-02 | Calculer les posologies pédiatriques au poids avec bornes de sécurité et alerte de dépassement | I |
| EF-M05-03 | Alerter sur allergie déclarée, contre-indication grossesse/allaitement, redondance thérapeutique et interactions majeures (base paramétrable) | S |
| EF-M05-04 | Afficher la disponibilité en stock et le coût prévisionnel au moment de la prescription, avec proposition d'équivalents disponibles | I |
| EF-M05-05 | Imprimer l'ordonnance et le bon d'analyses au format officiel, avec identification du prescripteur | I |
| EF-M05-06 | Gérer les protocoles pré-remplis (paludisme simple, IRA, diarrhée, TPI, déparasitage, vitamine A) en un clic | I |
| EF-M05-07 | Gérer les prescriptions au long cours et le renouvellement pour les maladies chroniques et les ARV | S |

### M06 — Laboratoire

| Code | Exigence | Prio |
|---|---|---|
| EF-M06-01 | Recevoir les demandes d'examens depuis la consultation, avec file d'attente laboratoire et priorité urgence | I |
| EF-M06-02 | Gérer les examens du PMA : TDR paludisme, hémoglobine, test rapide VIH, selles fraîches, numération globulaire, test d'Emmel, sédiment urinaire, vitesse de sédimentation, bandelettes, examens colorimétriques, culot urinaire, ponction ganglionnaire | I |
| EF-M06-03 | Saisir les résultats avec unités, valeurs de référence, interprétation automatique normal/anormal, résultats critiques signalés au prescripteur | I |
| EF-M06-04 | Générer le registre de laboratoire, le registre de résultats et la fiche de rendu de résultat | I |
| EF-M06-05 | Gérer le groupe sanguin, la carte de groupe sanguin, la fiche de compatibilité et le dossier de transfusion | I |
| EF-M06-06 | Décrémenter automatiquement les réactifs et consommables consommés par examen | I |
| EF-M06-07 | Suivre les températures d'équipements (réfrigérateur, chaîne du froid) via la fiche de surveillance de température, avec alerte hors plage | I |
| EF-M06-08 | Suivre le contrôle de qualité interne et la traçabilité des lots de réactifs | S |

### M07 — Pharmacie et stock

Cette section applique strictement les règles du SIGL (R4).

| Code | Exigence | Prio |
|---|---|---|
| EF-M07-01 | Tenir une **fiche de stock électronique** par produit et par lot : entrées, sorties, pertes, ajustements d'inventaire, solde, avec désignation en DCI | I |
| EF-M07-02 | Calculer et afficher les **quatre données essentielles** : stock disponible utilisable (hors périmés et altérés), quantité consommée, pertes, nombre de jours de rupture de stock, plus stock initial et entrées du mois | I |
| EF-M07-03 | Gérer les lots, dates de péremption et sortie **FEFO**, avec blocage ou alerte forte en cas de sortie d'un lot périmé | I |
| EF-M07-04 | Calculer la consommation moyenne mensuelle (CMM), le stock de sécurité, le stock maximum, le point de commande et la quantité à commander selon la formule paramétrable | I |
| EF-M07-05 | Générer le bon de commande vers le BCZS/CDR selon le calendrier (mensuel, au plus tard le 5) et suivre les commandes en cours | I |
| EF-M07-06 | Réceptionner avec bon de livraison et **procès-verbal de réception**, contrôle des écarts quantité/qualité, enregistrement des lots | I |
| EF-M07-07 | Gérer les inventaires physiques périodiques : feuille de comptage, fiche d'inventaire, rapport d'inventaire, écarts et ajustements justifiés | I |
| EF-M07-08 | Gérer les produits hors d'usage : fiche/registre, motif (péremption, avarie, vol), procès-verbal de destruction | I |
| EF-M07-09 | Dispenser sur ordonnance interne, avec substitution tracée et refus pour rupture tracé | I |
| EF-M07-10 | Tenir le **registre de consommation journalière** et le **RUMER** (valeur du stock consommé, recettes du jour, versement au trésorier, date et visa de l'IT) | I |
| EF-M07-11 | Gérer l'officine de vente au public, distincte du stock de service, avec marge paramétrable | I |
| EF-M07-12 | Gérer les intrants PEV séparément : vaccins, diluants, seringues, réceptacles, pétrole, avec suivi de la chaîne du froid | I |
| EF-M07-13 | Produire le rapport synthèse mensuel de gestion des médicaments de la FOSA et l'exporter vers le SIGL/InfoMED et DHIS2 | I |
| EF-M07-14 | Alerter sur seuils : sous stock de sécurité, surstock, péremption à 3/6 mois, produit traceur en rupture | I |
| EF-M07-15 | Valoriser le stock (prix d'achat, valeur du stock) pour la rubrique « valeur de la pharmacie » du canevas SNIS | I |
| EF-M07-16 | Gérer les transferts entre structures ou entre dépôts avec fiche de transfert | S |

### M08 — Observation et lits

| Code | Exigence | Prio |
|---|---|---|
| EF-M08-01 | Gérer 2 lits d'observation (et plus si la structure est plus grande) : plan des lits, admission, sortie, transfert | I |
| EF-M08-02 | Tenir le dossier infirmier : feuille de signes vitaux, feuille de température, feuille de traitement avec administration horodatée, feuille d'évolution/surveillance, plan de soins | I |
| EF-M08-03 | Tenir le registre d'hospitalisation/observation avec date d'entrée, date de sortie, journées, diagnostic principal, condition de sortie | I |
| EF-M08-04 | Gérer la mise en observation prolongée, la décision de référence, la sortie contre avis médical et le décès | I |
| EF-M08-05 | Calculer automatiquement les journées d'hospitalisation, le taux d'occupation et la durée moyenne de séjour | I |
| EF-M08-06 | Gérer le tour de salle (cahier TDS) et les consignes de garde | S |

### M09 — Maternité, CPN, CPoN et gratuité

| Code | Exigence | Prio |
|---|---|---|
| EF-M09-01 | Gérer la CPN recentrée : ouverture du dossier de grossesse, calcul du terme et de l'âge gestationnel, parité, gestité, antécédents obstétricaux, visites CPN 1 à 4+, examens, TPI, VAT, fer/acide folique, MILDA, dépistage VIH et syphilis | I |
| EF-M09-02 | Éditer la fiche CPN et la carte CPN de la gestante ; tenir le registre CPN avec identité, provenance, dates, grossesse, parité, examens, services reçus, issue de grossesse | I |
| EF-M09-03 | Planifier et rappeler les rendez-vous CPN, identifier les gestantes en retard et les perdues de vue | I |
| EF-M09-04 | Gérer le travail et l'accouchement : registre de travail, **partogramme** (dilatation, descente, contractions, rythme cardiaque fœtal, constantes), feuille de protocole d'accouchement | I |
| EF-M09-05 | Enregistrer l'accouchement : date/heure, type (eutocique, dystocique, référé), lieu (FOSA, hors FOSA), assistance qualifiée, délivrance, pertes sanguines, complications, GATPA | I |
| EF-M09-06 | Enregistrer le nouveau-né : sexe, poids, APGAR, vivant/mort-né, réanimation, soins essentiels, allaitement précoce, fiche de suivi du nouveau-né, certificat de naissance | I |
| EF-M09-07 | Enregistrer les décès maternels et néonatals avec cause, et déclencher la fiche de revue des décès | I |
| EF-M09-08 | Gérer la CPoN avec échéancier (J0-J2, J3-J7, J8-J42) et les consultations du post-partum | I |
| EF-M09-09 | Appliquer automatiquement la **gratuité de la maternité et des soins du nouveau-né** : exonération du patient, valorisation de l'acte, constitution du dossier de remboursement et état de facturation au programme | I |
| EF-M09-10 | Gérer les urgences obstétricales : décision, délai, référence vers l'HGR avec fiche de référence obstétricale | I |
| EF-M09-11 | Gérer la PTME : registre PTME, femmes enceintes séropositives sous ARV, prophylaxie du nouveau-né, suivi de l'enfant exposé | I |

### M10 — Santé de l'enfant, CPS et PEV

| Code | Exigence | Prio |
|---|---|---|
| EF-M10-01 | Gérer la consultation préscolaire : registre CPS, carte CPS, suivi de croissance avec courbes OMS (poids/âge, poids/taille, taille/âge, PB) et calcul des z-scores | I |
| EF-M10-02 | Gérer le calendrier vaccinal national complet, y compris les antigènes récents du canevas (VPI2, VAR2), avec doses, âges cibles, intervalles | I |
| EF-M10-03 | Enregistrer les vaccinations par antigène, dose, lot, date, stratégie (fixe, avancée, mobile), site, vaccinateur | I |
| EF-M10-04 | Calculer les enfants complètement vaccinés, les abandons (perdus de vue entre doses), les taux de couverture par antigène et par village | I |
| EF-M10-05 | Gérer les intrants PEV et la chaîne du froid : stock de vaccins et diluants, relevés de température deux fois par jour, alerte de rupture de chaîne, gestion des flacons ouverts | I |
| EF-M10-06 | Gérer les MAPI (manifestations post-vaccinales indésirables) | S |
| EF-M10-07 | Gérer les interventions associées : vitamine A, mébendazole, zinc, MILDA | I |
| EF-M10-08 | Produire les listes de rappel pour récupération par les RECO/CAC | I |

### M11 — Planification familiale

| Code | Exigence | Prio |
|---|---|---|
| EF-M11-01 | Gérer le counseling PF (fiche de counseling) et le registre PF avec nouvelles et anciennes utilisatrices | I |
| EF-M11-02 | Gérer les méthodes (orales, injectables, implants, DIU, préservatifs, méthodes naturelles, définitives) avec dates de renouvellement et conversion en couples-années de protection | I |
| EF-M11-03 | Suivre les acceptantes, les abandons, les effets secondaires et les retraits d'implants/DIU | I |
| EF-M11-04 | Gérer les stocks de produits contraceptifs avec les règles SIGL | I |

### M12 — Nutrition

| Code | Exigence | Prio |
|---|---|---|
| EF-M12-01 | Dépister la malnutrition aiguë modérée et sévère (PB, z-score P/T, œdèmes, test de l'appétit) | I |
| EF-M12-02 | Gérer les admissions et issues UNTA et UNS conformément au canevas SNIS (guéri, décès, abandon, non-répondant, transfert), y compris les groupes spécifiques | I |
| EF-M12-03 | Suivre les rations (ATPE, farines) avec sortie de stock et cartes de ration | I |
| EF-M12-04 | Produire les indicateurs de performance nutritionnelle (taux de guérison, décès, abandon, gain de poids) | I |

### M13 — Programmes verticaux

| Code | Exigence | Prio |
|---|---|---|
| EF-M13-01 | Paludisme : cas suspects, testés (TDR/GE), confirmés, traités selon la politique nationale, paludisme grave référé, TPI chez la femme enceinte | I |
| EF-M13-02 | Tuberculose : registre TB, dépistage, mise sous traitement, catégorie, suivi des crachats, issues (guéri, traitement terminé, échec, décès, perdu de vue), contacts | I |
| EF-M13-03 | VIH : dépistage et conseil (registres pré-test et post-test), registre de prise en charge, file active sous ARV, registre des rendez-vous, prophylaxie au cotrimoxazole, charge virale | I |
| EF-M13-04 | IST : prise en charge syndromique, notification des partenaires | I |
| EF-M13-05 | Maladies chroniques : cohortes HTA, diabète, avec suivi de la tension, de la glycémie, de l'observance et des rendez-vous | I |
| EF-M13-06 | Autres : lèpre, trypanosomiase humaine africaine, personnes du troisième âge, dépistage des infirmités | S |
| EF-M13-07 | Calculer et exporter les indicateurs propres à chaque programme dans leurs canevas respectifs | I |

### M14 — Référence et contre-référence

| Code | Exigence | Prio |
|---|---|---|
| EF-M14-01 | Créer une référence vers l'HGR ou une autre structure : motif, diagnostic, actes déjà posés, traitement administré, degré d'urgence, moyen de transport | I |
| EF-M14-02 | Imprimer le billet/fiche de référence conforme et tenir le registre des malades référés | I |
| EF-M14-03 | Enregistrer la contre-référence reçue et la rattacher au dossier ; classer les lettres de contre-référence | I |
| EF-M14-04 | Suivre le taux de référence, le taux de contre-référence effective et les délais | I |
| EF-M14-05 | Notifier la structure d'accueil par SMS ou message si le réseau est disponible | S |

### M15 — Caisse, tarification et facturation

| Code | Exigence | Prio |
|---|---|---|
| EF-M15-01 | Facturer selon un moteur de tarification gérant le forfait par épisode, le tarif à l'acte, le tarif par régime et le prix du traitement standard | I |
| EF-M15-02 | Générer automatiquement la facture à partir des actes, examens, médicaments et journées d'observation consommés | I |
| EF-M15-03 | Encaisser en espèces (CDF/USD), mobile money, chèque, avec reçu/quittance numéroté en série inaltérable | I |
| EF-M15-04 | Gérer les paiements partiels, les avances, les crédits et les dettes patients avec échéancier et suivi des impayés | I |
| EF-M15-05 | Gérer les exonérations : indigent, personnel, gratuité maternité, programme, avec motif, pièce justificative et validation hiérarchique | I |
| EF-M15-06 | Tenir le journal de caisse, le bon d'entrée caisse, le bon de sortie caisse, le rapport de caisse journalier et le bordereau de versement au trésorier | I |
| EF-M15-07 | Clôturer la caisse par caissier et par poste, avec comptage des espèces, écart constaté et justification obligatoire | I |
| EF-M15-08 | Interdire la suppression d'une opération encaissée : correction uniquement par annulation contre-passée et tracée | I |
| EF-M15-09 | Produire le tableau récapitulatif des recettes par service, par acte, par régime et par période | I |
| EF-M15-10 | Gérer la double devise avec taux journalier et conversion tracée sur chaque opération | I |

### M16 — Tiers payants, mutuelles et régimes de gratuité

| Code | Exigence | Prio |
|---|---|---|
| EF-M16-01 | Gérer les conventions avec mutuelles, employeurs, assurances et programmes : périmètre couvert, taux de prise en charge, ticket modérateur, plafonds, exclusions, délais de facturation | I |
| EF-M16-02 | Vérifier l'éligibilité de l'assuré à l'accueil (numéro d'affiliation, validité, ayants droit) | I |
| EF-M16-03 | Éclater automatiquement la facture entre part patient et part tiers payant | I |
| EF-M16-04 | Produire les bordereaux de facturation périodiques par tiers payant, avec pièces justificatives attendues par la convention | I |
| EF-M16-05 | Suivre les créances tiers payants : envoyé, reçu, contesté, rejeté (avec motif), payé, et relances | I |
| EF-M16-06 | Identifier dans les rapports SNIS les nouveaux cas **mutualistes** et **indigents**, comme l'exige le canevas | I |
| EF-M16-07 | Produire les états de remboursement du programme de gratuité maternité et nouveau-né | I |

### M17 — Comptabilité et budget

| Code | Exigence | Prio |
|---|---|---|
| EF-M17-01 | Gérer le plan comptable et la liste des comptes paramétrables, les journaux comptables, le grand livre, la balance provisoire et définitive | I |
| EF-M17-02 | Générer les écritures automatiquement depuis la caisse, la pharmacie et la paie | I |
| EF-M17-03 | Gérer la banque : journal de banque, ordres de paiement et de virement, rapprochement bancaire | I |
| EF-M17-04 | Gérer le budget : élaboration, fiche budgétaire, tableau de suivi budgétaire, engagements, alerte de dépassement | I |
| EF-M17-05 | Gérer la trésorerie : plan de trésorerie, rapport de trésorerie, prévisions de décaissement | I |
| EF-M17-06 | Gérer les pièces de dépense : bon de demande de fonds, bon d'engagement, bon de réquisition, bon de commande, bon à justifier, facture fournisseur | I |
| EF-M17-07 | Produire le compte de résultat, le bilan simplifié, le livre d'inventaire et les états annexes | S |
| EF-M17-08 | Produire les rubriques recettes, dépenses et financement indirect du canevas SNIS | I |
| EF-M17-09 | Gérer les projets et bailleurs : affectation analytique des recettes et dépenses par source de financement | I |

### M18 — Ressources humaines et paie

| Code | Exigence | Prio |
|---|---|---|
| EF-M18-01 | Tenir le dossier de l'agent : identité, qualification (L2, A1, A2, sage-femme, nutritionniste, technicien de laboratoire, médecin, autre), matricule, statut, ancienneté, diplômes, description de poste | I |
| EF-M18-02 | Gérer les présences : liste/registre de présences, jours prévus, jours prestés, absences justifiées et injustifiées, conformément au canevas SNIS | I |
| EF-M18-03 | Gérer les congés : planning, décision de congé, soldes | I |
| EF-M18-04 | Gérer les roulements de service et les gardes | I |
| EF-M18-05 | Gérer la paie : éléments de rémunération, prime de performance FBP individuelle, retenues, état de paie, bulletins | I |
| EF-M18-06 | Gérer l'évaluation (fiche de cotation) et la discipline (procès-verbaux d'ouverture, de clôture, de transmission) | S |
| EF-M18-07 | Gérer la formation continue : plan, sessions, participation, attestations | S |
| EF-M18-08 | Gérer les ordres de mission et les frais de mission | S |

### M19 — Immobilisations, équipements et maintenance

| Code | Exigence | Prio |
|---|---|---|
| EF-M19-01 | Inventorier les équipements : code, localisation, date d'acquisition, valeur, source de financement, état (fonctionnel, en panne, hors d'usage) | I |
| EF-M19-02 | Suivre les équipements exigés par le canevas SNIS : électricité, frigo, microscope, glucomètre, spectrophotomètre, centrifugeuse, et leur fonctionnalité | I |
| EF-M19-03 | Gérer la maintenance préventive (calendrier, alertes) et curative (demande d'intervention, coût, pièces) | I |
| EF-M19-04 | Gérer les amortissements et la réforme des biens | S |

### M20 — Hygiène, déchets et stérilisation

| Code | Exigence | Prio |
|---|---|---|
| EF-M20-01 | Suivre les cycles de stérilisation (charge, température, durée, contrôle) et la traçabilité des instruments | S |
| EF-M20-02 | Suivre la gestion des déchets biomédicaux : tri, collecte, incinération/enfouissement, registre | I |
| EF-M20-03 | Suivre les indicateurs d'hygiène et de prévention des infections, les accidents d'exposition au sang et les checklists de nettoyage | S |
| EF-M20-04 | Suivre la disponibilité de l'eau, de l'électricité et des consommables d'hygiène (critères de qualité FBP) | I |

### M21 — Activités communautaires et RECO

| Code | Exigence | Prio |
|---|---|---|
| EF-M21-01 | Gérer les relais communautaires et les CAC : identité, village, formation, supervision | I |
| EF-M21-02 | Enregistrer les activités des RECO : visites à domicile, sensibilisations, récupérations d'enfants et de femmes enceintes, référence communautaire | I |
| EF-M21-03 | Gérer les sites de soins communautaires : fonctionnement, prise en charge des cas, stock de proximité, rapportage | I |
| EF-M21-04 | Gérer la PCIME communautaire et les perdus de vue à récupérer, avec listes nominatives par village | I |
| EF-M21-05 | Gérer les séances de communication pour le changement de comportement et la participation communautaire (COSA, réunions) | I |
| EF-M21-06 | Application mobile légère ou formulaire USSD/SMS pour la saisie par les RECO sans connexion permanente | S |

### M22 — SNIS, DHIS2 et rapports réglementaires

| Code | Exigence | Prio |
|---|---|---|
| EF-M22-01 | Générer le **rapport mensuel du centre de santé** conforme au canevas SNIS, sans ressaisie, à partir des données de production | I |
| EF-M22-02 | Couvrir toutes les rubriques : consultations et caractéristiques des nouveaux cas (femmes enceintes, mutualistes, indigents), morbidité notifiable, santé de la mère, PF, santé de l'enfant et PEV, laboratoire, nutrition, références et observation, décès par cause et âge, activités communautaires, sites de soins, supervision, personnel, pharmacie, matériel, recettes, dépenses, financement indirect | I |
| EF-M22-03 | Contrôler la cohérence avant transmission : totaux, ventilations par sexe et par groupe d'âge (moins de 5 ans / 5 ans et plus), valeurs aberrantes, complétude | I |
| EF-M22-04 | Exporter en PDF pour signature, en Excel/CSV, et par API DHIS2 (`dataValueSets`) avec mapping des éléments de données et des unités d'organisation | I |
| EF-M22-05 | Tracer l'envoi : date, auteur, accusé, version corrective (rapport rectificatif) | I |
| EF-M22-06 | Mesurer la complétude et la promptitude des rapports, indicateurs suivis par la DPS | I |
| EF-M22-07 | Produire les rapports spécifiques des programmes (PEV, paludisme, TB, VIH, nutrition) et le rapport SIGL | I |
| EF-M22-08 | Permettre la reconstitution du rapport à partir des données individuelles pour toute vérification externe (piste d'audit descendante) | I |

### M23 — FBP et qualité

| Code | Exigence | Prio |
|---|---|---|
| EF-M23-01 | Gérer les indicateurs quantitatifs achetés, avec quantité déclarée, tarif unitaire, subside calculé | I |
| EF-M23-02 | Produire le **bordereau de déclaration des prestations** et le dossier de vérification | I |
| EF-M23-03 | Relier chaque prestation déclarée à sa source primaire (registre, fiche, dossier) pour la vérification quantitative | I |
| EF-M23-04 | Gérer la grille d'évaluation qualitative par service, le score obtenu et le plan d'amélioration | I |
| EF-M23-05 | Gérer la contre-vérification communautaire : échantillon de patients, existence et satisfaction, écarts constatés | I |
| EF-M23-06 | Calculer les primes de performance et leur répartition selon la clé paramétrée | I |
| EF-M23-07 | Gérer le plan de management/plan d'action du centre et son suivi | I |

### M24 — Tableaux de bord et monitorage

| Code | Exigence | Prio |
|---|---|---|
| EF-M24-01 | Tableau de bord IT : activité du jour, file d'attente, recettes du jour, alertes stock, rapports en retard | I |
| EF-M24-02 | Monitorage de l'aire de santé : taux d'utilisation des services curatifs, couverture CPN 1 et 4, accouchements assistés, couverture vaccinale par antigène, PF, par mois et par village, avec dénominateurs population | I |
| EF-M24-03 | Indicateurs financiers : recettes par service, coût par épisode, taux de recouvrement, part des exonérations, créances tiers payants | I |
| EF-M24-04 | Indicateurs logistiques : taux de disponibilité des produits traceurs, jours de rupture, taux de péremption, rotation du stock | I |
| EF-M24-05 | Indicateurs de qualité : taux de référence, décès, contre-référence, complétude et promptitude des rapports | I |
| EF-M24-06 | Graphiques d'évolution, comparaison à l'objectif et à la période précédente, export image et PDF | I |
| EF-M24-07 | Cartographie simple des villages et de la couverture (si coordonnées disponibles) | O |

### M25 — Administration, sécurité et audit

| Code | Exigence | Prio |
|---|---|---|
| EF-M25-01 | Gérer les utilisateurs, les rôles et les permissions fines (par module, par action, par service) ; profils prédéfinis : IT, infirmier, sage-femme, laborantin, pharmacien, caissier, comptable, gestionnaire RH, administrateur, superviseur ECZS (lecture) | I |
| EF-M25-02 | Authentification par mot de passe fort, avec option code PIN pour postes partagés et déconnexion automatique après inactivité | I |
| EF-M25-03 | Journal d'audit inaltérable : création, modification, consultation, suppression logique, connexion, export, impression ; horodatage et utilisateur | I |
| EF-M25-04 | Aucune suppression physique des données cliniques et financières : suppression logique motivée uniquement | I |
| EF-M25-05 | Sauvegardes automatiques locales chiffrées (quotidiennes), export sur support externe, et sauvegarde distante si connexion | I |
| EF-M25-06 | Procédure de restauration testée et documentée, avec test de restauration mensuel | I |
| EF-M25-07 | Registre des traitements de données personnelles, politique de conservation et d'anonymisation conforme au Code du numérique (R6) | I |
| EF-M25-08 | Gestion du consentement, droit d'accès et de rectification du patient, export des données d'un patient sur demande | I |
| EF-M25-09 | Masquage renforcé des données sensibles (VIH, violences sexuelles, santé mentale) avec accès dédié et justification | I |
| EF-M25-10 | Mode « bris de glace » d'urgence, journalisé et notifié à l'administrateur | S |

### M26 — Synchronisation et multi-sites

| Code | Exigence | Prio |
|---|---|---|
| EF-M26-01 | Fonctionnement **hors ligne complet** : toutes les fonctions cliniques, pharmaceutiques et de caisse disponibles sans internet | I |
| EF-M26-02 | Synchronisation incrémentale opportuniste dès que la connexion est disponible, avec reprise après interruption | I |
| EF-M26-03 | Résolution des conflits déterministe et traçable, avec file des conflits à arbitrer par un administrateur | I |
| EF-M26-04 | Identifiants globalement uniques (UUID) pour éviter les collisions entre sites | I |
| EF-M26-05 | Consolidation multi-structures pour un réseau ou une zone de santé, avec cloisonnement des données par structure | S |
| EF-M26-06 | Indicateur visible de l'état de synchronisation et de la dernière sauvegarde réussie | I |

### M27 — Notifications

| Code | Exigence | Prio |
|---|---|---|
| EF-M27-01 | Rappels de rendez-vous par SMS (CPN, CPS/vaccination, PF, ARV, TB), avec consentement préalable | S |
| EF-M27-02 | Alertes internes : rupture de stock, péremption, résultat critique, rapport en retard, écart de caisse | I |
| EF-M27-03 | Alerte de notification épidémiologique à l'ECZS | I |
| EF-M27-04 | Paramétrage des modèles de messages, quotas et coûts | S |

### M28 — Interopérabilité

| Code | Exigence | Prio |
|---|---|---|
| EF-M28-01 | API REST documentée (OpenAPI) sur toutes les entités métier, avec authentification par jeton et journalisation | I |
| EF-M28-02 | Export/import **HL7 FHIR R4** au minimum pour Patient, Encounter, Observation, Condition, MedicationRequest, Immunization, Location, Practitioner | S |
| EF-M28-03 | Intégration DHIS2 : `dataValueSets`, métadonnées, mapping paramétrable, rejeu des envois échoués | I |
| EF-M28-04 | Intégration SIGL/InfoMED pour la remontée des données logistiques | S |
| EF-M28-05 | Intégration mobile money (encaissement et rapprochement), en mode connecteur remplaçable | S |
| EF-M28-06 | Lecture/écriture de codes-barres et QR (carte patient, lots de médicaments, étiquettes d'échantillons) | I |
| EF-M28-07 | Impression sur imprimante thermique 58/80 mm et A5/A4, avec gabarits éditables | I |

---

## 5. Exigences non fonctionnelles

### 5.1 Performance

| Code | Exigence | Cible |
|---|---|---|
| ENF-P01 | Recherche d'un patient parmi 200 000 dossiers | < 1 s |
| ENF-P02 | Ouverture d'un dossier patient complet | < 2 s |
| ENF-P03 | Enregistrement d'une consultation | < 1 s |
| ENF-P04 | Génération du rapport mensuel SNIS | < 30 s |
| ENF-P05 | Utilisateurs simultanés sur poste serveur local d'entrée de gamme | 15 minimum |
| ENF-P06 | Volumétrie supportée sans dégradation | 10 ans de données, 500 000 consultations |

### 5.2 Disponibilité et robustesse

- Fonctionnement en cas de coupure électrique brutale sans corruption de base (transactions ACID, journalisation).
- Disponibilité locale visée : 99 % des heures d'ouverture.
- Point de reprise (RPO) ≤ 15 minutes ; délai de reprise (RTO) ≤ 2 heures avec procédure documentée.
- Mode dégradé : impression de fiches vierges officielles permettant de travailler sur papier puis de ressaisir.

### 5.3 Ergonomie et accessibilité

- Interface en français ; architecture d'internationalisation prévue pour swahili, lingala, tshiluba, kikongo et anglais.
- Écrans calqués sur les registres officiels, avec les mêmes intitulés de colonnes, pour réduire la courbe d'apprentissage.
- Saisie complète au clavier (tabulation, raccourcis), sans dépendance à la souris.
- Maximum 3 clics pour les opérations les plus fréquentes (accueil d'un ancien patient, encaissement, dispensation).
- Lisibilité sur écran 13 pouces et tablette 8 pouces, contraste élevé, taille de police réglable.
- Messages d'erreur explicites, en langage métier, avec la correction à apporter.

### 5.4 Sécurité

- Chiffrement au repos de la base de données et des sauvegardes ; chiffrement en transit (TLS 1.2+).
- Hachage des mots de passe (algorithme à coût paramétrable), politique de rotation, verrouillage après échecs répétés.
- Principe du moindre privilège, séparation des fonctions (celui qui facture n'encaisse pas nécessairement).
- Journal d'audit exportable et non modifiable par les utilisateurs applicatifs.
- Tests d'intrusion applicatifs avant mise en production ; revue des dépendances et correctifs de sécurité.
- Conformité au Code du numérique : base légale du traitement, information des personnes, sécurité, durée de conservation, encadrement des transferts hors du pays.

### 5.5 Maintenabilité et évolutivité

- Code documenté, revue de code obligatoire, couverture de tests automatisés ≥ 70 % sur la logique métier.
- Architecture modulaire permettant d'activer/désactiver un module par structure.
- Paramétrage sans recompilation pour : tarifs, formulaires, ordinogrammes, seuils, gabarits d'impression, mapping DHIS2.
- Migrations de schéma versionnées et réversibles.
- Documentation d'architecture, dictionnaire de données et guide de contribution livrés.

### 5.6 Portabilité et environnement technique cible

- Serveur local : Linux ou Windows, 4 Go de RAM minimum, 128 Go de stockage, onduleur obligatoire.
- Postes clients : navigateur récent ; application Android 8+ pour tablette ; réseau local filaire ou Wi-Fi.
- Installation par paquet unique avec assistant, sans compétence système avancée.
- Base de données relationnelle transactionnelle (PostgreSQL recommandé en serveur, SQLite en poste isolé).
- Aucune dépendance obligatoire à un service cloud pour le fonctionnement quotidien.

### 5.7 Exigences légales et documentaires

- Les documents imprimés doivent être conformes aux modèles officiels (registres, canevas, reçus) et porter l'identification de la structure, le code SNIS et la signature du responsable.
- Conservation des données cliniques selon la réglementation applicable ; archivage des données au-delà de la période active avec accès restreint.
- Propriété des données : la structure de santé est responsable de traitement ; le prestataire est sous-traitant, lié par un contrat de sous-traitance.

---

## 6. Architecture fonctionnelle et modèle de données

### 6.1 Principes d'architecture

1. **Local-first** : la source de vérité opérationnelle est le serveur local de la structure ; le cloud est une destination de synchronisation, jamais un prérequis.
2. **Séparation noyau / modules** : noyau (identité, sécurité, référentiels, audit, synchronisation) et modules métier greffés.
3. **Événements métier** : chaque acte produit un événement horodaté, immuable, à partir duquel les registres et agrégats sont dérivés. Cela garantit la vérifiabilité FBP et la reconstitution des rapports.
4. **Agrégats calculés et non saisis** : les rapports SNIS sont toujours dérivés des événements, jamais saisis à la main (sauf données non issues des soins, comme le matériel).
5. **Terminologies externalisées** : CIM-10, LOINC, DCI dans des tables de référence versionnées.

### 6.2 Entités principales (extrait du dictionnaire de données)

| Entité | Attributs clés | Relations |
|---|---|---|
| Structure | code SNIS, type, province, zone de santé, aire de santé, population par année | 1-n Service, 1-n Utilisateur |
| Patient | UUID, numéro de dossier, nom, post-nom, prénom, sexe, date de naissance, village, téléphone, régimes | 1-n Venue, 1-n Régime, n-n Ménage |
| Venue (épisode) | date/heure, type, nouveau/ancien cas, service, agent d'accueil | 1-n Consultation, 1-n Acte, 1 Facture |
| Consultation | plaintes, examen, diagnostic CIM-10, conduite, praticien | 1-n Prescription, 1-n DemandeExamen |
| Prescription | produit DCI, posologie, durée, quantité | 1-n Dispensation |
| DemandeExamen / Résultat | examen LOINC, urgence, valeur, unité, interprétation | 1-1 Consultation |
| Produit | DCI, forme, dosage, classe, traceur, chaîne du froid | 1-n Lot |
| Lot | numéro, péremption, quantité, prix | 1-n MouvementStock |
| MouvementStock | type (entrée, sortie, perte, ajustement), quantité, motif, pièce | n-1 Lot |
| DossierGrossesse | terme, parité, gestité, CPN 1..n, issue | 1-1 Accouchement |
| Accouchement | date, type, assistance, complications | 1-n NouveauNe |
| Vaccination | antigène, dose, lot, stratégie, date | n-1 Patient |
| Facture | lignes, montant, part patient, part tiers, statut | 1-n Paiement |
| Paiement | mode, devise, montant, reçu, caissier, session de caisse | n-1 Facture |
| Référence | motif, destination, urgence, contre-référence | n-1 Venue |
| Agent | qualification, matricule, statut, poste | 1-n Présence, 1-n Paie |
| RapportMensuel | période, rubriques, statut, envois | n-1 Structure |
| JournalAudit | utilisateur, action, entité, avant/après, horodatage | — |

### 6.3 Règles de gestion critiques

| Code | Règle |
|---|---|
| RG-01 | Un patient ne peut avoir qu'un seul dossier actif ; toute fusion conserve les deux identifiants historiques. |
| RG-02 | Un nouveau cas est déterminé par l'absence d'épisode clos pour le même problème dans la fenêtre paramétrée (par défaut 14 jours). |
| RG-03 | Aucune dispensation sans prescription ou sans vente enregistrée en officine. |
| RG-04 | Aucune sortie de stock ne peut rendre un solde de lot négatif. |
| RG-05 | Sortie de stock FEFO obligatoire, dérogation motivée et tracée. |
| RG-06 | Une prestation relevant de la gratuité maternité ne peut être encaissée auprès du patient. |
| RG-07 | Une facture validée n'est plus modifiable ; seule une note d'annulation contre-passée est possible. |
| RG-08 | La session de caisse doit être clôturée avant la fin du service, avec comptage et écart justifié. |
| RG-09 | Le rapport mensuel ne peut être transmis que si les contrôles de cohérence bloquants sont levés. |
| RG-10 | Tout accès à un dossier sensible exige une justification enregistrée. |
| RG-11 | Les données d'un mois clos sont figées ; une correction produit un rapport rectificatif versionné. |
| RG-12 | Chaque enregistrement porte l'agent, la date système et, si différente, la date de l'événement clinique. |

---

## 7. Livrables attendus

| Code | Livrable | Contenu |
|---|---|---|
| L1 | Spécifications détaillées validées | Maquettes de tous les écrans, règles de gestion, dictionnaire de données |
| L2 | Application | Code source complet, licence et droits cédés au commanditaire, dépôt versionné |
| L3 | Paquet d'installation | Installeur serveur et client, script d'initialisation, jeu de données de démonstration |
| L4 | Gabarits d'impression | Tous les registres, fiches, reçus, ordonnances, cartes, rapports au format officiel |
| L5 | Connecteurs | DHIS2, SIGL/InfoMED, FHIR, SMS, mobile money (selon priorités) |
| L6 | Documentation technique | Architecture, modèle de données, API OpenAPI, procédures d'exploitation et de sauvegarde |
| L7 | Documentation utilisateur | Manuel par profil, aide-mémoire d'une page par poste, tutoriels vidéo courts |
| L8 | Plan et dossier de tests | Cas de tests, jeux de données, résultats, procès-verbal de recette |
| L9 | Formation | Supports, sessions par profil, formation des formateurs, évaluation des acquis |
| L10 | Plan de reprise de données | Méthode de saisie rétroactive, contrôles de qualité, bilan de reprise |
| L11 | Dossier de conformité | Registre des traitements, analyse d'impact, politique de sécurité et de conservation |
| L12 | Contrat de maintenance | Niveaux de service, délais d'intervention, périmètre correctif et évolutif |

---

## 8. Démarche de réalisation et planning indicatif

Approche itérative : chaque lot est livré, testé en conditions réelles dans une structure pilote, corrigé, puis étendu.

| Lot | Contenu | Durée indicative |
|---|---|---|
| Lot 0 | Cadrage, observation terrain d'au moins 2 structures, validation des spécifications et des maquettes | 4 semaines |
| Lot 1 | Noyau : référentiels, sécurité, audit, identité patient, accueil, file d'attente, sauvegardes | 6 semaines |
| Lot 2 | Consultation, prescription, laboratoire, actes de soins, registres associés | 6 semaines |
| Lot 3 | Pharmacie et stock complets (SIGL), dispensation, RUMER, commandes, inventaires | 6 semaines |
| Lot 4 | Caisse, tarification, tiers payants, gratuité, recettes et dépenses | 5 semaines |
| Lot 5 | Maternité, CPN/CPoN, PEV/CPS, PF, nutrition, programmes verticaux | 8 semaines |
| Lot 6 | SNIS, DHIS2, FBP, tableaux de bord, monitorage | 5 semaines |
| Lot 7 | RH, comptabilité, budget, équipements, hygiène et déchets | 5 semaines |
| Lot 8 | Communautaire, RECO, mobile, notifications, synchronisation multi-sites | 5 semaines |
| Lot 9 | Durcissement, performance, sécurité, documentation, formation, recette finale | 4 semaines |

Durée cumulée indicative : 12 à 14 mois pour le périmètre complet, avec une première mise en service utile (lots 1 à 4) à partir du 6e mois.

---

## 9. Stratégie de tests et recette

### 9.1 Niveaux de tests

- Tests unitaires sur les calculs sensibles : posologies au poids, z-scores, CMM et stock de sécurité, agrégats SNIS, éclatement des factures, conversions de devises.
- Tests d'intégration sur les parcours complets.
- Tests de non-régression automatisés à chaque livraison.
- Tests de charge (15 utilisateurs, 10 ans de données).
- Tests de résilience : coupure d'électricité en pleine transaction, perte de réseau pendant la synchronisation, disque plein.
- Tests de sécurité : élévation de privilèges, injection, accès direct aux URL, exports non autorisés.
- Tests d'utilisabilité avec les agents réels, mesure du temps de saisie par cas.

### 9.2 Scénarios de recette obligatoires (extrait)

| N° | Scénario | Critère de réussite |
|---|---|---|
| T01 | Nouveau patient, consultation paludisme simple, TDR positif, traitement, dispensation, paiement, sortie | Registre de consultation, registre de laboratoire, fiche de stock, journal de caisse tous cohérents sans ressaisie |
| T02 | Patient mutualiste avec taux de 80 % | Facture éclatée 80/20, bordereau mutuelle correct |
| T03 | Accouchement eutocique sous gratuité maternité | Aucun encaissement patient, acte valorisé, état de remboursement produit |
| T04 | Enfant de 11 mois, CPS, malnutrition aiguë sévère, admission UNTA, vaccination VAR | z-score correct, admission UNTA, carnet vaccinal, stocks ATPE et vaccins décrémentés |
| T05 | Urgence obstétricale référée à l'HGR puis contre-référence reçue | Registre des référés, délai calculé, contre-référence rattachée |
| T06 | Rupture de stock d'un produit traceur pendant 4 jours | Jours de rupture = 4 dans le rapport SIGL, alerte émise, commande proposée |
| T07 | Inventaire physique avec écart de 3 unités et 2 unités périmées | Ajustement tracé, produit hors d'usage enregistré, SDU recalculé hors périmés |
| T08 | Clôture de caisse avec écart de 500 CDF | Blocage jusqu'à justification, écart visible dans le rapport de caisse |
| T09 | Génération du rapport mensuel SNIS et export DHIS2 | Rapport complet, contrôles passés, envoi tracé, valeurs identiques à la reconstitution manuelle sur échantillon |
| T10 | Vérification FBP sur 20 prestations déclarées | 100 % retrouvées dans les sources primaires |
| T11 | Coupure de courant pendant l'enregistrement d'une consultation | Aucune corruption, reprise avec au plus la dernière saisie non validée perdue |
| T12 | 30 jours de fonctionnement hors ligne puis synchronisation | Aucune perte, conflits arbitrés, agrégats identiques |
| T13 | Tentative d'accès d'un caissier au dossier VIH d'un patient | Accès refusé, tentative journalisée |
| T14 | Fusion de deux doublons patient | Historique complet préservé, aucun double comptage dans les agrégats |
| T15 | Restauration d'une sauvegarde de la veille sur un poste neuf | Restauration réussie en moins de 2 heures, intégrité vérifiée |

### 9.3 Critères d'acceptation globaux

- 100 % des exigences de priorité I vérifiées et tracées dans la matrice de couverture.
- Zéro anomalie bloquante, au plus 5 anomalies majeures avec plan de correction daté.
- Rapport mensuel SNIS accepté par l'ECZS pour deux mois consécutifs.
- Écart de contre-vérification inférieur à 5 % sur un échantillon de 100 prestations.
- Formation validée : au moins 80 % des agents autonomes sur leur poste à l'évaluation finale.

---

## 10. Déploiement, conduite du changement et exploitation

### 10.1 Prérequis matériels par structure

| Élément | Spécification minimale |
|---|---|
| Serveur / poste principal | 4 Go RAM, SSD 128 Go, onduleur 650 VA minimum |
| Postes de saisie | 1 par poste de travail actif (accueil, consultation, laboratoire, pharmacie, caisse) ou tablettes |
| Réseau local | Routeur/switch, câblage ou Wi-Fi, sans dépendance internet |
| Énergie | Solaire avec batteries ou groupe, onduleurs, protection contre les surtensions |
| Impression | Imprimante thermique pour reçus, imprimante A4 pour registres et rapports |
| Sauvegarde | 2 disques externes chiffrés en rotation |
| Connectivité | Clé/modem 4G ou Wi-Fi partagé, utilisé ponctuellement pour la synchronisation |

### 10.2 Déploiement progressif

1. Site pilote unique, double saisie papier + application pendant 1 mois, comparaison des agrégats.
2. Correction des écarts, ajustement des écrans et des gabarits.
3. Extension à 3 à 5 structures de la même zone de santé.
4. Généralisation avec équipe de support de proximité et référent numérique par structure.

### 10.3 Conduite du changement

- Implication de l'IT et de l'ECZS dès le cadrage ; validation des maquettes par les utilisateurs.
- Un référent formé par structure, relais de premier niveau.
- Aide-mémoire d'une page affiché à chaque poste.
- Suivi hebdomadaire des indicateurs d'adoption pendant les 3 premiers mois (taux de saisie, délai de saisie, taux d'erreur).

### 10.4 Support et maintenance

| Sévérité | Exemple | Prise en charge | Rétablissement |
|---|---|---|---|
| Bloquante | Application indisponible, caisse ou pharmacie inutilisable | 2 h ouvrées | 8 h ouvrées |
| Majeure | Rapport SNIS erroné, calcul de stock faux | 8 h ouvrées | 3 jours ouvrés |
| Mineure | Libellé, confort d'usage | 3 jours ouvrés | Version suivante |

Maintenance corrective, évolutive (mises à jour des référentiels, canevas SNIS, tarifs) et adaptative (nouvelles versions de DHIS2) incluses au contrat, avec au minimum deux mises à jour annuelles.

---

## 11. Budget indicatif et postes de coût

Le budget doit distinguer clairement les postes suivants, chiffrés par le soumissionnaire :

1. Cadrage et spécifications détaillées.
2. Développement par lot fonctionnel.
3. Connecteurs et interopérabilité (DHIS2, SIGL, FHIR, SMS, mobile money).
4. Tests, sécurité et durcissement.
5. Matériel et énergie par structure.
6. Reprise et saisie rétroactive des données.
7. Formation et conduite du changement.
8. Déploiement et accompagnement du pilote.
9. Maintenance annuelle (pourcentage du coût de développement, généralement 15 à 20 %).
10. Hébergement et frais de communication éventuels.

Le modèle de licence attendu est une cession des droits d'utilisation illimitée au commanditaire, avec remise du code source ; une solution libre existante adaptée est acceptable si elle couvre les exigences de priorité I.

---

## 12. Risques et mesures de maîtrise

| Risque | Probabilité | Impact | Mesure |
|---|---|---|---|
| Rupture d'énergie prolongée | Élevée | Élevé | Onduleurs, solaire, mode papier de secours, sauvegardes fréquentes |
| Résistance ou faible appropriation du personnel | Élevée | Élevé | Écrans calqués sur le papier, formation par poste, référent local, gains visibles dès le lot 1 |
| Double saisie durable papier/numérique | Moyenne | Moyen | Impression des registres officiels par l'application, décision explicite d'abandon du papier après validation |
| Évolution du canevas SNIS ou du calendrier vaccinal | Élevée | Moyen | Formulaires et mappings paramétrables sans redéploiement |
| Panne de matériel ou vol | Moyenne | Élevé | Sauvegardes chiffrées externalisées, procédure de restauration testée, matériel de remplacement |
| Qualité insuffisante des données saisies | Moyenne | Élevé | Contrôles de saisie bloquants, indicateurs de qualité, supervision intégrée |
| Fuite de données sensibles | Faible | Très élevé | Chiffrement, habilitations fines, journalisation, masquage, sensibilisation |
| Dérive du périmètre | Élevée | Moyen | Priorisation I/S/O contractuelle, comité de pilotage, gestion formelle des changements |
| Dépendance à un prestataire unique | Moyenne | Élevé | Code source remis, documentation, standards ouverts, formation d'un technicien local |

---

## 13. Gouvernance du projet

- **Comité de pilotage** : direction du centre ou du réseau, médecin chef de zone ou son représentant, partenaire financier, chef de projet prestataire. Réunion mensuelle, arbitrage des priorités et des changements.
- **Comité utilisateurs** : IT, infirmiers, sage-femme, laborantin, gestionnaire de pharmacie, caissier. Réunion à chaque fin de lot, validation fonctionnelle.
- **Chef de projet commanditaire** : point d'entrée unique, validation des livrables, disponibilité des utilisateurs.
- **Gestion des changements** : toute demande hors périmètre fait l'objet d'une fiche chiffrée en délai et en coût, approuvée par le comité de pilotage.
- **Indicateurs de suivi du projet** : avancement par lot, nombre d'exigences validées, anomalies ouvertes par sévérité, adoption par poste.

---

## 14. Annexes

### Annexe A — Correspondance outils officiels / fonctions de l'application

| Outil officiel (R2, R4) | Module | Exigence |
|---|---|---|
| Registre de malades, carte du patient | M02, M03 | EF-M02-01, EF-M03-01 |
| Registre de triage, fiche d'identification | M03 | EF-M03-03, EF-M03-04 |
| Registre de consultation, fiche de consultation | M04 | EF-M04-05 |
| Bon d'analyses, ordonnance | M05 | EF-M05-05 |
| Carte de rendez-vous | M04 | EF-M04-06 |
| Registre de laboratoire, registre de résultats, fiche de rendu | M06 | EF-M06-04 |
| Carte de groupe sanguin, fiche de compatibilité, dossier de transfusion | M06 | EF-M06-05 |
| Feuilles de signes vitaux, traitement, évolution, température, plan de soins | M08 | EF-M08-02 |
| Registre d'hospitalisation, cahier de tour de salles | M08 | EF-M08-03, EF-M08-06 |
| Partogramme, registre de travail, registre d'accouchement, certificat de naissance | M09 | EF-M09-04, EF-M09-06 |
| Fiche CPN, carte CPN, registre CPN | M09 | EF-M09-02 |
| Registre CPS, carte CPS | M10 | EF-M10-01 |
| Registre PF, fiche de counseling PF | M11 | EF-M11-01 |
| Registres TB, VIH, PTME, pré/post-test, rendez-vous ARV | M13 | EF-M13-02, EF-M13-03 |
| Billet de référence, fiche de contre-référence, registre des référés | M14 | EF-M14-01 à 03 |
| Note de sortie, billet de sortie, rapport médical, attestation, certificat de décès | M04, M08 | EF-M04-08, EF-M08-04 |
| Tarif, reçu/quittance, journal de caisse, rapport de caisse, bordereau de versement | M15 | EF-M15-03, EF-M15-06 |
| Budget, fiche budgétaire, suivi budgétaire, plan et rapport de trésorerie | M17 | EF-M17-04, EF-M17-05 |
| Plan comptable, journaux, grand livre, balances, bilan, compte de résultat | M17 | EF-M17-01, EF-M17-07 |
| Bon de commande, PV de réception, fiche de stock, fiche d'inventaire, registre des produits hors d'usage, fiche de température | M07 | EF-M07-01 à 08 |
| Registre de consommation journalière, RUMER | M07 | EF-M07-10 |
| Dossier de l'agent, registre de présences, état de paie, planning de congé, fiche de cotation, description de poste, ordre de mission | M18 | EF-M18-01 à 08 |
| Rapport mensuel SNIS | M22 | EF-M22-01 |
| Bordereau de déclaration des prestations FBP | M23 | EF-M23-02 |

### Annexe B — Indicateurs à produire automatiquement (extrait)

Taux d'utilisation des services curatifs · nouveaux cas pour 1 000 habitants · part des nouveaux cas indigents et mutualistes · incidence du paludisme confirmé · taux de positivité des TDR · CPN 1 et CPN 4 · accouchements assistés par personnel qualifié · taux de césarienne référée · décès maternels et néonatals · CPoN dans les 48 h · couverture par antigène et taux d'abandon PEV · prévalence contraceptive et couples-années de protection · taux de guérison UNTA · taux de dépistage VIH et file active ARV · taux de détection et de succès TB · taux de référence et de contre-référence · durée moyenne de séjour en observation · disponibilité des produits traceurs et jours de rupture · taux de péremption · recettes par service et taux de recouvrement · coût moyen par épisode · complétude et promptitude des rapports · score de qualité FBP.

### Annexe C — Glossaire

ARV : antirétroviraux · ATPE : aliment thérapeutique prêt à l'emploi · BCZS : bureau central de la zone de santé · CAC : cellule d'animation communautaire · CDR : centrale de distribution régionale · CIM-10 : classification internationale des maladies · CMM : consommation moyenne mensuelle · COSA : comité de santé · CPN/CPoN/CPS : consultations prénatale, postnatale, préscolaire · DCI : dénomination commune internationale · DHIS2 : District Health Information Software 2 · DPS : division provinciale de la santé · ECZS : équipe cadre de la zone de santé · FBP : financement basé sur la performance · FEFO : first expired, first out · FHIR : Fast Healthcare Interoperability Resources · FOSA : formation sanitaire · HGR : hôpital général de référence · IT : infirmier titulaire · LOINC : Logical Observation Identifiers Names and Codes · MAPI : manifestations post-vaccinales indésirables · MILDA : moustiquaire imprégnée d'insecticide à longue durée d'action · PCA : paquet complémentaire d'activités · PCIME : prise en charge intégrée des maladies de l'enfant · PEV : programme élargi de vaccination · PF : planification familiale · PMA : paquet minimum d'activités · PTME : prévention de la transmission mère-enfant · RECO : relais communautaire · RUMER : registre d'utilisation des médicaments et des recettes · SDU : stock disponible utilisable · SIGL : système d'information en gestion logistique · SNIS : système national d'information sanitaire · TDR : test de diagnostic rapide · TPI : traitement préventif intermittent · UNTA/UNS : unité nutritionnelle thérapeutique ambulatoire / unité nutritionnelle supplémentaire · ZS : zone de santé.

### Annexe D — Sources documentaires

- Recueil des normes de création, d'organisation et de fonctionnement des structures de la zone de santé en RDC, MSP, 2019 : https://bv-assk.org/wp-content/uploads/2024/03/Recueil-des-normes-de-creation-dorganisation-de-fonctionnement-des-structures-de-la-ZS-en-RDC-MSP-2019.pdf
- Recueil des normes d'organisation et de fonctionnement de la zone de santé, 2009 : https://bv-assk.org/wp-content/uploads/2023/12/Receuil-des-normes-de-la-ZS-2009.pdf
- Arrêté du 15 septembre 2017 sur les outils minimum de gestion standardisés : https://www.droitcongolais.info/files/810.09.17.2-Arrete-du-15-septembre-2017_outils-de-standardisartion.pdf
- Canevas SNIS, rapport mensuel du centre de santé : https://bv-assk.org/wp-content/uploads/2024/03/Canevas-SNIS-CS-AVEC-VPI2-ET-VAR-2-OK.pdf
- Canevas mensuel du bureau central de la zone de santé : https://bv-assk.org/wp-content/uploads/2024/02/2021-05-30-Canevas-mensuel-BCZ-Vfini-2.pdf
- Manuel de procédures de remplissage des outils de gestion du SNIS de routine : https://malariaportal.org/sites/default/files/2023-11/DRC-511.1_%20Manuel%20de%20Procedures%20de%20Remplissage%20des%20outils%20de%20Gestion%20du%20SNIS%20de%20Routine_%20Registres%20et%20Canevas%20de%20Rapport%20Mensuel%20D%E2%80%99Activites_%202016%20(Part%201_3).pdf
- Manuel descriptif du SIGL, ASRAMES, mai 2020 : https://asrames.org/wp-content/uploads/2020/06/Manuel-Descriptif-du-SIGL-version-Mai-2020.pdf
- Manuel des outils de gestion logistique, OMS AFRO : https://files.aho.afro.who.int/afahobckpcontainer/production/files/Manuel_des_Outils_de_Gestion_Logistique.pdf
- Manuel opérationnel du Financement Basé sur la Performance, PDSS : https://santenews.info/wp-content/uploads/2020/04/Manuel_PBF_PDSS_FINANCEMENT.pdf
- Plan National de Développement Sanitaire : https://www.prb.org/wp-content/uploads/2020/06/RDC-Plan-National-de-Developpement-Sanitaire-2016-2020.pdf
- Ordonnance-loi n° 23/006 du 3 mars 2023 modifiant la loi n° 18/035 sur l'organisation de la santé publique : https://www.annuairetravail-rdc.cd/admin/pdf_storage/ordonnance-loi-n-23-006-du-3-mars-2023-modifiant-et-completant-la-loi-n-18-035-du-13-decembre-2018-fixant-les-principes-fondamentaux-relatifs-a-l-organisation-de-la-sante-publique_695638331dd6d.pdf
- Code du numérique, ordonnance-loi n° 23/010 du 13 mars 2023 (Livre III, protection des données) : https://www.anove.ai/fr/regulations/drc-digital-code-book-iii
- Programme de gratuité de la maternité et des soins du nouveau-né : https://drc.unfpa.org/fr/news/lancement-de-la-gratuit%C3%A9-des-accouchements-en-rdc et https://sante.gouv.cd/actualites/revue-annuelle-du-programme-de-la-gratuite-de-la-maternite-et-des-soins-du-nouveau-ne
- Guide de gestion des mutuelles de santé en Afrique, OIT : https://www.ilo.org/sites/default/files/wcmsp5/groups/public/@ed_protect/@soc_sec/documents/instructionalmaterial/wcms_secsoc_106.pdf
- Analyse des modalités de financement des soins de santé en RDC : https://ccsc-rdc.com/doc/02-Analyse-des-modalit%C3%A9s-de-financement-des-soins-de-sant%C3%A9-en-R%C3%A9publique-d%C3%A9mocratique-du-Congo.pdf
- Gestion adaptative des centres de santé en RDC, revue Santé Publique : https://www.cairn.info/revue-sante-publique-2020-4-page-359.htm
- Plateforme SIGL InfoMED RDC : https://sigl.infomedrdc.org/
- OpenMRS, interopérabilité et guide FHIR : https://openmrs.atlassian.net/wiki/spaces/docs/pages/300613733/Interoperability+Integration et https://fhir.openmrs.org/
