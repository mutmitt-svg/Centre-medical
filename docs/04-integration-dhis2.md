# Intégration DHIS2 et interopérabilité

Document technique complémentaire au cahier des charges (modules M22 « Rapportage SNIS » et M28 « Interopérabilité »). Il décrit comment l'application transforme ses données de production en rapport mensuel transmissible, puis en charge utile DHIS2.

## 1. Principe général

L'application est la source primaire : chaque valeur du canevas SNIS est calculée depuis les enregistrements individuels (venues, consultations, vaccinations, dispensations, paiements), jamais saisie deux fois. Le canevas SNIS du centre de santé et le canevas mensuel de la zone de santé définissent les rubriques et les ventilations attendues ([Canevas SNIS CS](https://bv-assk.org/wp-content/uploads/2024/03/Canevas-SNIS-CS-AVEC-VPI2-ET-VAR-2-OK.pdf), [Canevas mensuel BCZ](https://bv-assk.org/wp-content/uploads/2024/02/2021-05-30-Canevas-mensuel-BCZ-Vfini-2.pdf)). Les règles de remplissage retenues pour les registres et le rapport mensuel suivent le manuel de procédures du SNIS de routine ([Manuel de procédures SNIS](https://malariaportal.org/sites/default/files/2023-11/DRC-511.1_%20Manuel%20de%20Procedures%20de%20Remplissage%20des%20outils%20de%20Gestion%20du%20SNIS%20de%20Routine_%20Registres%20et%20Canevas%20de%20Rapport%20Mensuel%20D%E2%80%99Activites_%202016%20(Part%201_3).pdf)).

Trois états successifs, correspondant au cycle réel du centre :

1. Brouillon calculé — disponible en continu, consultable dès le 1er du mois.
2. Contrôlé — les 23 contrôles de cohérence CTL-001 à CTL-023 ont été exécutés ; les contrôles bloquants doivent être levés ou justifiés.
3. Transmis — la période est figée (règle RG-11) ; toute correction ultérieure passe par un rapport rectificatif versionné.

## 2. Table de correspondance

Le fichier `mapping_dhis2.csv` (séparateur point-virgule, UTF-8) associe chaque élément de données interne à sa destination DHIS2. Colonnes :

| Colonne | Contenu |
| --- | --- |
| `code_interne` | code stable de l'élément dans la table `element_donnee_snis` |
| `rubrique_canevas` | rubrique du canevas SNIS du centre de santé |
| `libelle_snis` | libellé exact figurant sur le canevas papier |
| `ventilation_interne` | axes de désagrégation gérés par l'application |
| `dhis2_dataSet` | jeu de données cible (`DS_SNIS_CS_MENSUEL`, `DS_SIGL_FOSA_MENSUEL`) |
| `dhis2_dataElement_uid_placeholder` | emplacement de l'UID à 11 caractères du serveur national |
| `dhis2_categoryCombo` | combinaison de catégories attendue |
| `dhis2_categoryOptionCombo_placeholder` | modèle de combinaison d'options, développé à l'import du référentiel |
| `periode_type` | périodicité DHIS2 (`Monthly`) |
| `source_calcul` | expression métier sur les tables de production |
| `regle_agregation` | somme, dernier du mois, ou saisie manuelle |
| `controle_coherence` | contrôle associé, exécuté avant transmission |

Important : les valeurs de la colonne UID sont des marqueurs (`DE_...`), pas des UID DHIS2. Les UID réels sont propres à l'instance nationale et doivent être importés lors du paramétrage, puis stockés dans `element_donnee_snis.code_dhis2_de` et `element_donnee_snis.code_dhis2_coc`. Publier ou coder en dur des UID inventés provoquerait des rejets silencieux à l'import.

## 3. Paramétrage initial

Étapes à réaliser une fois par déploiement, avec le responsable SNIS de la division provinciale :

1. Obtenir les identifiants d'un compte de service DHIS2 disposant de `F_DATAVALUE_ADD` sur l'unité d'organisation du centre.
2. Récupérer l'unité d'organisation : `GET /api/organisationUnits?filter=code:eq:CS-KAM-001&fields=id,name,code`. L'UID obtenu est enregistré dans `structure.code_dhis2_ou`.
3. Récupérer les métadonnées du jeu de données : `GET /api/dataSets/{uid}?fields=id,name,periodType,dataSetElements[dataElement[id,name,code,categoryCombo[id,categoryOptionCombos[id,name]]]]`.
4. Rapprocher automatiquement par `code`, puis manuellement par libellé pour les éléments restants. Le rapprochement est validé écran par écran et journalisé.
5. Geler la correspondance dans une version de référentiel datée ; tout changement crée une nouvelle version, l'ancienne restant consultable pour les périodes déjà transmises.

## 4. Charge utile d'export

L'export utilise `POST /api/dataValueSets` au format JSON, avec `importStrategy=CREATE_AND_UPDATE` et `dryRun=true` lors d'un contrôle préalable.

```json
{
  "dataSet": "<uid du jeu de données>",
  "completeDate": "2026-09-05",
  "period": "202609",
  "orgUnit": "<uid de l'unité d'organisation>",
  "dataValues": [
    { "dataElement": "<uid>", "categoryOptionCombo": "<uid>", "value": "412", "comment": "SNIS-CONS-001 M 12-59M" },
    { "dataElement": "<uid>", "categoryOptionCombo": "<uid>", "value": "39" }
  ]
}
```

Règles d'émission :

- une seule requête par période et par jeu de données, avec reprise possible ;
- les valeurs nulles ne sont pas omises lorsque l'activité existe mais vaut zéro : un zéro explicite se distingue d'une donnée manquante ;
- la réponse est conservée intégralement dans `export_dhis2` (statut, `importCount`, conflits) pour audit ;
- en cas de conflit, la ligne fautive est reliée à son élément interne et présentée à l'utilisateur en français, sans jargon d'API ;
- l'export est rejouable sans doublon puisque DHIS2 remplace la valeur pour un triplet (élément, période, unité d'organisation).

## 5. Fonctionnement hors ligne

La connectivité étant intermittente, l'export suit une file persistante :

1. la charge utile est constituée et signée localement dès la validation du rapport ;
2. elle est déposée dans la file `export_dhis2` avec le statut `EN_ATTENTE` ;
3. un travail de fond tente l'envoi à chaque fenêtre de connexion, avec temporisation croissante (1, 5, 15, 60 minutes, puis horaire) ;
4. après cinq échecs, l'application propose l'export d'un fichier JSON ou CSV à transmettre par clé USB au bureau central de la zone de santé, tout en conservant la file ;
5. le tableau de bord de l'administrateur affiche en permanence l'âge du plus ancien export en attente.

Le rapport papier reste produit en parallèle, au format du canevas officiel, car il demeure la pièce de référence lors des supervisions.

## 6. Export SIGL

Les données essentielles de gestion logistique — stock disponible utilisable, quantité consommée, pertes et ajustements, jours de rupture — alimentent le jeu `DS_SIGL_FOSA_MENSUEL`, conformément au manuel descriptif du système d'information en gestion logistique ([Manuel SIGL, ASRAMES](https://asrames.org/wp-content/uploads/2020/06/Manuel-Descriptif-du-SIGL-version-Mai-2020.pdf)). Le calcul de la consommation moyenne mensuelle exclut les mois comportant des jours de rupture, conformément aux outils de gestion logistique recommandés ([OMS AFRO](https://files.aho.afro.who.int/afahobckpcontainer/production/files/Manuel_des_Outils_de_Gestion_Logistique.pdf)). Lorsque la plateforme nationale est accessible, la transmission peut également se faire par dépôt sur le portail SIGL ([SIGL InfoMED RDC](https://sigl.infomedrdc.org/)).

## 7. Interopérabilité clinique FHIR

Pour les échanges avec un hôpital général de référence ou un dossier patient partagé, l'application expose un profil FHIR R4 en lecture seule sur les ressources Patient, Encounter, Observation, Condition, MedicationRequest, Immunization, Location et Practitioner, en s'alignant sur les conventions du module FHIR d'OpenMRS ([OpenMRS FHIR](https://fhir.openmrs.org/)). Les identifiants patients sont exposés sous un système propre à la structure (`urn:cd:fosa:CS-KAM-001:dossier`), jamais sous un identifiant national inexistant.

## 8. Protection des données

Tout transfert sortant est chiffré en transit, limité aux données strictement nécessaires et journalisé avec son destinataire, conformément aux obligations de sécurité et de confidentialité du Livre III du Code du numérique ([Code du numérique, Livre III](https://www.anove.ai/fr/regulations/drc-digital-code-book-iii)). Les exports agrégés SNIS ne contiennent aucune donnée nominative. Les exports cliniques nominatifs (référence, contre-référence, FHIR) exigent une base légale explicite : prise en charge du patient concerné ou consentement tracé.
