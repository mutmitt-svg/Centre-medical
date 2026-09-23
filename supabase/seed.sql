-- =====================================================================
-- Jeu de données de démonstration et d'initialisation
-- Application de gestion d'un centre de santé — PostgreSQL
-- À exécuter APRÈS schema_centre_sante.sql
--
-- Contenu
--   Partie 1 : référentiels réels d'initialisation (à conserver en production)
--   Partie 2 : données fictives de démonstration et de formation (à purger)
-- =====================================================================
SET search_path TO public;

-- =====================================================================
-- PARTIE 1 — RÉFÉRENTIELS D'INITIALISATION
-- =====================================================================

-- 1.1 Découpage sanitaire ---------------------------------------------
INSERT INTO province (id, code, nom) VALUES
 ('11111111-0000-0000-0000-000000000001','HKA','Haut-Katanga');

INSERT INTO zone_sante (id, province_id, code, nom, code_dhis2) VALUES
 ('11111111-0000-0000-0000-000000000011','11111111-0000-0000-0000-000000000001','ZS-LSH','Lubumbashi','ZSlubDHIS01');

INSERT INTO aire_sante (id, zone_sante_id, code, nom, code_dhis2) VALUES
 ('11111111-0000-0000-0000-000000000021','11111111-0000-0000-0000-000000000011','AS-KAM','Kamalondo','ASkamDHIS01');

INSERT INTO structure (id, aire_sante_id, code_snis, code_dhis2, nom, type, statut_juridique,
                       telephone, adresse, rayon_action_km, devise_principale) VALUES
 ('22222222-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000021','CS-KAM-001','FOSAkamDHIS1',
  'Centre de Santé Kamalondo','CENTRE_SANTE','Public','+243 970 000 000','Av. Kasaï n°14, Kamalondo',9.0,'CDF');

INSERT INTO population_annuelle (structure_id, annee, population_totale, enfants_0_11_mois,
                                 enfants_0_59_mois, femmes_enceintes_attendues, femmes_age_procreer) VALUES
 ('22222222-0000-0000-0000-000000000001',2026, 9450, 378, 1701, 425, 2174);

INSERT INTO village (id, aire_sante_id, nom, population, distance_km) VALUES
 ('33333333-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000021','Kalubwe',2180,1.5),
 ('33333333-0000-0000-0000-000000000002','11111111-0000-0000-0000-000000000021','Nsele',1940,3.0),
 ('33333333-0000-0000-0000-000000000003','11111111-0000-0000-0000-000000000021','Kamalondo Centre',3120,0.4),
 ('33333333-0000-0000-0000-000000000004','11111111-0000-0000-0000-000000000021','Katuba II',1410,6.2),
 ('33333333-0000-0000-0000-000000000005','11111111-0000-0000-0000-000000000021','Mwenge',800,11.0);

-- 1.2 Services et lits (normes : 7 services, maternité 5 lits, observation 2)
INSERT INTO service (id, structure_id, code, nom, nb_lits) VALUES
 ('44444444-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','RECEPTION','Réception',0),
 ('44444444-0000-0000-0000-000000000002','22222222-0000-0000-0000-000000000001','CONSULT','Consultation',0),
 ('44444444-0000-0000-0000-000000000003','22222222-0000-0000-0000-000000000001','SOINS','Salle de soins',0),
 ('44444444-0000-0000-0000-000000000004','22222222-0000-0000-0000-000000000001','MATERNITE','Maternité',5),
 ('44444444-0000-0000-0000-000000000005','22222222-0000-0000-0000-000000000001','OBSERVATION','Observation',2),
 ('44444444-0000-0000-0000-000000000006','22222222-0000-0000-0000-000000000001','LABO','Laboratoire',0),
 ('44444444-0000-0000-0000-000000000007','22222222-0000-0000-0000-000000000001','PHARMACIE','Pharmacie',0),
 ('44444444-0000-0000-0000-000000000008','22222222-0000-0000-0000-000000000001','LOGISTIQUE','Logistique et maintenance',0);

INSERT INTO lit (service_id, code, type) VALUES
 ('44444444-0000-0000-0000-000000000004','MAT-T1','travail'),
 ('44444444-0000-0000-0000-000000000004','MAT-T2','travail'),
 ('44444444-0000-0000-0000-000000000004','MAT-O1','observation'),
 ('44444444-0000-0000-0000-000000000004','MAT-O2','observation'),
 ('44444444-0000-0000-0000-000000000004','MAT-TA','table accouchement'),
 ('44444444-0000-0000-0000-000000000005','OBS-1','observation'),
 ('44444444-0000-0000-0000-000000000005','OBS-2','observation');

INSERT INTO depot (id, structure_id, code, nom, type) VALUES
 ('55555555-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','PH-PRINC','Pharmacie principale','PHARMACIE_PRINCIPALE'),
 ('55555555-0000-0000-0000-000000000002','22222222-0000-0000-0000-000000000001','OFFICINE','Officine de vente','OFFICINE'),
 ('55555555-0000-0000-0000-000000000003','22222222-0000-0000-0000-000000000001','DEP-LABO','Dépôt laboratoire','LABO'),
 ('55555555-0000-0000-0000-000000000004','22222222-0000-0000-0000-000000000001','DEP-PEV','Dépôt PEV / chaîne du froid','PEV');

-- 1.3 Rôles et permissions -------------------------------------------
INSERT INTO role (id, code, libelle) VALUES
 ('66666666-0000-0000-0000-000000000001','IT','Infirmier Titulaire'),
 ('66666666-0000-0000-0000-000000000002','INFIRMIER','Infirmier / consultation'),
 ('66666666-0000-0000-0000-000000000003','SAGE_FEMME','Sage-femme / accoucheuse'),
 ('66666666-0000-0000-0000-000000000004','LABO','Technicien de laboratoire'),
 ('66666666-0000-0000-0000-000000000005','PHARMACIE','Gestionnaire de pharmacie'),
 ('66666666-0000-0000-0000-000000000006','CAISSE','Caissier'),
 ('66666666-0000-0000-0000-000000000007','COMPTA','Comptable / gestionnaire'),
 ('66666666-0000-0000-0000-000000000008','RH','Gestionnaire RH'),
 ('66666666-0000-0000-0000-000000000009','ADMIN','Administrateur système'),
 ('66666666-0000-0000-0000-00000000000a','SUPERVISEUR_ECZS','Superviseur ECZS (lecture seule)');

INSERT INTO permission (code, module, libelle) VALUES
 ('PATIENT_CREER','M02','Créer un patient'),
 ('PATIENT_FUSIONNER','M02','Fusionner deux dossiers'),
 ('DOSSIER_SENSIBLE_LIRE','M25','Lire un dossier sensible (VIH, VBG, santé mentale)'),
 ('VENUE_CREER','M03','Enregistrer une venue'),
 ('TRIAGE_SAISIR','M03','Saisir le triage'),
 ('CONSULTATION_CREER','M04','Créer une consultation'),
 ('CONSULTATION_VALIDER','M04','Valider une consultation'),
 ('PRESCRIPTION_CREER','M05','Prescrire'),
 ('LABO_RESULTAT_SAISIR','M06','Saisir un résultat de laboratoire'),
 ('LABO_RESULTAT_VALIDER','M06','Valider et rendre un résultat'),
 ('STOCK_MOUVEMENT','M07','Enregistrer un mouvement de stock'),
 ('STOCK_INVENTAIRE_VALIDER','M07','Valider un inventaire'),
 ('STOCK_DEROGATION_FEFO','M07','Déroger à la règle FEFO'),
 ('DISPENSATION_CREER','M07','Dispenser des médicaments'),
 ('FACTURE_VALIDER','M15','Valider une facture'),
 ('PAIEMENT_ENCAISSER','M15','Encaisser un paiement'),
 ('PAIEMENT_ANNULER','M15','Annuler un encaissement (contre-passation)'),
 ('EXONERATION_VALIDER','M15','Valider une exonération'),
 ('CAISSE_CLOTURER','M15','Clôturer une session de caisse'),
 ('TIERS_PAYANT_FACTURER','M16','Éditer un bordereau tiers payant'),
 ('COMPTA_SAISIR','M17','Saisir des écritures comptables'),
 ('BUDGET_VALIDER','M17','Valider un budget'),
 ('RH_GERER','M18','Gérer les agents et présences'),
 ('PAIE_VALIDER','M18','Valider la paie'),
 ('RAPPORT_GENERER','M22','Générer un rapport mensuel'),
 ('RAPPORT_TRANSMETTRE','M22','Transmettre un rapport à l''ECZS'),
 ('FBP_DECLARER','M23','Établir la déclaration FBP'),
 ('REFERENTIEL_MODIFIER','M01','Modifier les référentiels et tarifs'),
 ('UTILISATEUR_GERER','M25','Gérer les utilisateurs et habilitations'),
 ('AUDIT_CONSULTER','M25','Consulter le journal d''audit'),
 ('SAUVEGARDE_RESTAURER','M25','Restaurer une sauvegarde'),
 ('SYNC_ARBITRER','M26','Arbitrer les conflits de synchronisation');

-- Profil IT : toutes les permissions sauf administration système
INSERT INTO role_permission (role_id, permission_id)
SELECT '66666666-0000-0000-0000-000000000001', id FROM permission
WHERE code NOT IN ('UTILISATEUR_GERER','SAUVEGARDE_RESTAURER','SYNC_ARBITRER');

INSERT INTO role_permission (role_id, permission_id)
SELECT '66666666-0000-0000-0000-000000000002', id FROM permission
WHERE code IN ('PATIENT_CREER','VENUE_CREER','TRIAGE_SAISIR','CONSULTATION_CREER',
               'CONSULTATION_VALIDER','PRESCRIPTION_CREER');

INSERT INTO role_permission (role_id, permission_id)
SELECT '66666666-0000-0000-0000-000000000005', id FROM permission
WHERE code IN ('STOCK_MOUVEMENT','DISPENSATION_CREER','STOCK_INVENTAIRE_VALIDER','STOCK_DEROGATION_FEFO');

INSERT INTO role_permission (role_id, permission_id)
SELECT '66666666-0000-0000-0000-000000000006', id FROM permission
WHERE code IN ('PAIEMENT_ENCAISSER','FACTURE_VALIDER','CAISSE_CLOTURER');

INSERT INTO role_permission (role_id, permission_id)
SELECT '66666666-0000-0000-0000-000000000009', id FROM permission;

-- 1.4 Diagnostics CIM-10 (sous-ensemble opérationnel du canevas SNIS)
INSERT INTO diagnostic_ref (code_cim10, libelle, notifiable, rubrique_snis) VALUES
 ('B54',  'Paludisme non précisé', false, 'PALUDISME'),
 ('B50.0','Paludisme à P. falciparum avec complications cérébrales', true, 'PALUDISME_GRAVE'),
 ('B50.9','Paludisme à P. falciparum, sans précision', false, 'PALUDISME'),
 ('J18.9','Pneumonie, sans précision', false, 'PNEUMONIE'),
 ('J06.9','Infection aiguë des voies respiratoires supérieures', false, 'IRA'),
 ('A09',  'Diarrhée et gastro-entérite d''origine infectieuse', false, 'DIARRHEE'),
 ('A00',  'Choléra', true, 'CHOLERA'),
 ('A01.0','Fièvre typhoïde', true, 'TYPHOIDE'),
 ('B05',  'Rougeole', true, 'ROUGEOLE'),
 ('A33',  'Tétanos néonatal', true, 'TETANOS_NEONATAL'),
 ('A36',  'Diphtérie', true, 'DIPHTERIE'),
 ('A37',  'Coqueluche', true, 'COQUELUCHE'),
 ('A80',  'Poliomyélite aiguë', true, 'PFA'),
 ('A95',  'Fièvre jaune', true, 'FIEVRE_JAUNE'),
 ('A98.4','Maladie à virus Ebola', true, 'EBOLA'),
 ('A15',  'Tuberculose respiratoire confirmée', true, 'TUBERCULOSE'),
 ('B20',  'Maladie à VIH', false, 'VIH'),
 ('A64',  'Infection sexuellement transmissible, sans précision', false, 'IST'),
 ('B56',  'Trypanosomiase africaine', true, 'THA'),
 ('A30',  'Lèpre', true, 'LEPRE'),
 ('E11',  'Diabète sucré de type 2', false, 'MALADIE_CHRONIQUE'),
 ('I10',  'Hypertension essentielle', false, 'MALADIE_CHRONIQUE'),
 ('E43',  'Malnutrition protéino-énergétique grave', false, 'MALNUTRITION'),
 ('E44',  'Malnutrition protéino-énergétique modérée', false, 'MALNUTRITION'),
 ('D50.9','Anémie par carence en fer, sans précision', false, 'ANEMIE'),
 ('O15',  'Éclampsie', true, 'COMPLICATION_OBSTETRICALE'),
 ('O72',  'Hémorragie du post-partum', true, 'COMPLICATION_OBSTETRICALE'),
 ('T14.9','Traumatisme de siège non précisé', false, 'TRAUMATISME'),
 ('Z00.0','Examen médical général', false, 'AUTRE'),
 ('R50.9','Fièvre, sans précision', false, 'AUTRE');

-- 1.5 Examens de laboratoire du PMA
INSERT INTO examen_ref (code, code_loinc, libelle, type_resultat, unite, valeur_min, valeur_max,
                        seuil_critique_bas, seuil_critique_haut, options_qualitatives, rubrique_snis) VALUES
 ('TDR-PALU','51587-4','TDR paludisme','QUALITATIF',NULL,NULL,NULL,NULL,NULL,'{POSITIF,NEGATIF,INVALIDE}','LABO_TDR'),
 ('GE','32700-7','Goutte épaisse / densité parasitaire','NUMERIQUE','/µl',0,0,NULL,NULL,NULL,'LABO_GE'),
 ('HB','718-7','Hémoglobine','NUMERIQUE','g/dl',11.0,14.0,7.0,NULL,NULL,'LABO_HB'),
 ('TDR-VIH','75622-1','Test rapide VIH','QUALITATIF',NULL,NULL,NULL,NULL,NULL,'{POSITIF,NEGATIF,INDETERMINE}','LABO_VIH'),
 ('SELLES','10701-4','Selles fraîches','TEXTE',NULL,NULL,NULL,NULL,NULL,NULL,'LABO_SELLES'),
 ('NFS','58410-2','Numération globulaire','NUMERIQUE','/mm3',4000,10000,NULL,NULL,NULL,'LABO_NFS'),
 ('EMMEL','30341-2','Test d''Emmel','QUALITATIF',NULL,NULL,NULL,NULL,NULL,'{POSITIF,NEGATIF}','LABO_EMMEL'),
 ('SED-URIN','5767-9','Sédiment urinaire','TEXTE',NULL,NULL,NULL,NULL,NULL,NULL,'LABO_URINE'),
 ('VS','4537-7','Vitesse de sédimentation','NUMERIQUE','mm/h',0,20,NULL,NULL,NULL,'LABO_VS'),
 ('BANDELETTE','50556-0','Bandelette urinaire','TEXTE',NULL,NULL,NULL,NULL,NULL,NULL,'LABO_BANDELETTE'),
 ('GLYCEMIE','2345-7','Glycémie','NUMERIQUE','mg/dl',70,110,40,400,NULL,'LABO_GLYCEMIE'),
 ('GROUPE','882-1','Groupe sanguin et Rhésus','QUALITATIF',NULL,NULL,NULL,NULL,NULL,'{O+,O-,A+,A-,B+,B-,AB+,AB-}','LABO_GS'),
 ('SYPHILIS','20507-0','Test syphilis (RPR)','QUALITATIF',NULL,NULL,NULL,NULL,NULL,'{POSITIF,NEGATIF}','LABO_SYPHILIS'),
 ('PONCTION','664-3','Ponction ganglionnaire','TEXTE',NULL,NULL,NULL,NULL,NULL,NULL,'LABO_PONCTION');

-- 1.6 Produits (extrait de la liste nationale des médicaments essentiels)
INSERT INTO produit (code, dci, forme, dosage, conditionnement, classe_therapeutique,
                     liste_nationale_me, traceur, chaine_froid, intrant_pev, reactif_labo,
                     contraceptif, unite_sortie, mois_stock_max, mois_stock_securite) VALUES
 ('MED-001','Artéméther-luméfantrine','comprimé','20/120 mg','blister de 6',   'Antipaludique',true,true,false,false,false,false,'comprimé',3,1),
 ('MED-002','Artésunate','injectable','60 mg','flacon',                         'Antipaludique',true,true,false,false,false,false,'flacon',3,1),
 ('MED-003','Amoxicilline','comprimé','250 mg','boîte de 100',                  'Antibiotique',true,true,false,false,false,false,'comprimé',3,1),
 ('MED-004','Cotrimoxazole','comprimé','480 mg','boîte de 100',                 'Antibiotique',true,true,false,false,false,false,'comprimé',3,1),
 ('MED-005','Paracétamol','sirop','120 mg/5 ml','flacon 60 ml',                 'Antalgique',true,false,false,false,false,false,'flacon',3,1),
 ('MED-006','Paracétamol','comprimé','500 mg','boîte de 100',                   'Antalgique',true,false,false,false,false,false,'comprimé',3,1),
 ('MED-007','Sels de réhydratation orale','sachet','20,5 g','sachet',            'Réhydratation',true,true,false,false,false,false,'sachet',3,1),
 ('MED-008','Zinc','comprimé dispersible','20 mg','plaquette',                  'Micronutriment',true,true,false,false,false,false,'comprimé',3,1),
 ('MED-009','Fer + acide folique','sirop','—','flacon 100 ml',                  'Micronutriment',true,false,false,false,false,false,'flacon',3,1),
 ('MED-010','Ocytocine','injectable','10 UI/ml','ampoule',                      'Utérotonique',true,true,true,false,false,false,'ampoule',3,1),
 ('MED-011','Sulfadoxine-pyriméthamine','comprimé','500/25 mg','plaquette',      'TPI grossesse',true,true,false,false,false,false,'comprimé',3,1),
 ('MED-012','Mébendazole','comprimé','500 mg','comprimé',                       'Antiparasitaire',true,false,false,false,false,false,'comprimé',3,1),
 ('MED-013','Vitamine A','capsule','200 000 UI','capsule',                      'Micronutriment',true,true,false,false,false,false,'capsule',3,1),
 ('MED-014','Diazépam','injectable','10 mg/2 ml','ampoule',                     'Anticonvulsivant',true,false,false,false,false,false,'ampoule',3,1),
 ('MED-015','Gants stériles','dispositif','taille 7,5','paire',                 'Consommable',true,true,false,false,false,false,'paire',3,1),
 ('VAC-001','Vaccin BCG','injectable','—','flacon 20 doses',                    'Vaccin',true,true,true,true,false,false,'dose',3,1),
 ('VAC-002','Vaccin pentavalent (DTC-HepB-Hib)','injectable','—','flacon 10 doses','Vaccin',true,true,true,true,false,false,'dose',3,1),
 ('VAC-003','Vaccin polio oral (VPO)','oral','—','flacon 20 doses',             'Vaccin',true,true,true,true,false,false,'dose',3,1),
 ('VAC-004','Vaccin polio inactivé (VPI)','injectable','—','flacon 5 doses',     'Vaccin',true,true,true,true,false,false,'dose',3,1),
 ('VAC-005','Vaccin antirougeoleux (VAR)','injectable','—','flacon 10 doses',    'Vaccin',true,true,true,true,false,false,'dose',3,1),
 ('VAC-006','Vaccin pneumococcique (PCV13)','injectable','—','flacon 4 doses',   'Vaccin',true,true,true,true,false,false,'dose',3,1),
 ('VAC-007','Vaccin antitétanique (VAT)','injectable','—','flacon 10 doses',     'Vaccin',true,true,true,true,false,false,'dose',3,1),
 ('VAC-008','Vaccin antirotavirus','oral','—','tube',                           'Vaccin',true,true,true,true,false,false,'dose',3,1),
 ('LAB-001','Test rapide paludisme (TDR)','test','—','boîte de 25',             'Réactif',true,true,false,false,true,false,'test',3,1),
 ('LAB-002','Réactif hémoglobine','réactif','—','cuvette',                      'Réactif',true,false,false,false,true,false,'cuvette',3,1),
 ('LAB-003','Test rapide VIH (Determine)','test','—','boîte de 100',            'Réactif',true,true,false,false,true,false,'test',3,1),
 ('LAB-004','Coloration Giemsa','réactif','—','flacon 500 ml',                  'Réactif',true,false,false,false,true,false,'ml',3,1),
 ('PF-001','Contraceptif oral combiné','comprimé','—','cycle',                  'Contraceptif',true,true,false,false,false,true,'cycle',3,1),
 ('PF-002','Médroxyprogestérone injectable','injectable','150 mg','flacon',      'Contraceptif',true,true,false,false,false,true,'flacon',3,1),
 ('PF-003','Implant contraceptif','implant','2 tiges','unité',                   'Contraceptif',true,true,false,false,false,true,'unité',3,1),
 ('PF-004','Préservatif masculin','dispositif','—','pièce',                      'Contraceptif',true,false,false,false,false,true,'pièce',3,1),
 ('PF-005','Dispositif intra-utérin','dispositif','TCu 380A','unité',            'Contraceptif',true,true,false,false,false,true,'unité',3,1),
 ('NUT-001','ATPE (Plumpy''Nut)','pâte','92 g','sachet',                        'Nutrition',true,true,false,false,false,false,'sachet',3,1),
 ('NUT-002','Farine CSB++','farine','—','sac 25 kg',                            'Nutrition',true,false,false,false,false,false,'kg',3,1),
 ('AUT-001','MILDA','dispositif','—','pièce',                                   'Lutte antivectorielle',true,true,false,false,false,false,'pièce',3,1);

-- 1.7 Actes et prestations
INSERT INTO acte (code, libelle, service_code, unite, forfaitaire, indicateur_fbp, rubrique_snis) VALUES
 ('ACT-001','Consultation curative (forfait)','CONSULT','acte',true,true,'CONSULTATION_CURATIVE'),
 ('ACT-002','Consultation de suivi','CONSULT','acte',false,false,'CONSULTATION_CURATIVE'),
 ('ACT-003','Consultation prénatale','MATERNITE','acte',false,true,'CPN'),
 ('ACT-004','Consultation postnatale','MATERNITE','acte',false,true,'CPON'),
 ('ACT-005','Consultation préscolaire','CONSULT','acte',false,true,'CPS'),
 ('ACT-006','Accouchement eutocique','MATERNITE','acte',true,true,'ACCOUCHEMENT'),
 ('ACT-007','Injection','SOINS','acte',false,false,'SOINS'),
 ('ACT-008','Pansement','SOINS','acte',false,false,'SOINS'),
 ('ACT-009','Suture simple','SOINS','acte',false,false,'PETITE_CHIRURGIE'),
 ('ACT-010','Perfusion','SOINS','acte',false,false,'SOINS'),
 ('ACT-011','Transfusion sanguine','SOINS','acte',false,false,'TRANSFUSION'),
 ('ACT-012','Journée d''observation','OBSERVATION','journée',false,false,'OBSERVATION'),
 ('ACT-013','Vaccination (séance)','CONSULT','acte',false,true,'PEV'),
 ('ACT-014','Pose d''implant contraceptif','CONSULT','acte',false,true,'PF'),
 ('ACT-015','Pose de DIU','CONSULT','acte',false,true,'PF'),
 ('ACT-016','Référence vers l''HGR','CONSULT','acte',false,true,'REFERENCE'),
 ('ACT-017','Petite intervention médico-chirurgicale','SOINS','acte',false,false,'PETITE_CHIRURGIE'),
 ('ACT-018','Certificat médical','RECEPTION','acte',false,false,'ADMINISTRATIF');

-- 1.8 Tarifs en vigueur (CDF, régime payant)
INSERT INTO tarif (structure_id, acte_id, type_regime, montant, devise, date_debut)
SELECT '22222222-0000-0000-0000-000000000001', a.id, 'PAYANT', v.montant, 'CDF', DATE '2026-01-01'
FROM acte a JOIN (VALUES
 ('ACT-001',3000),('ACT-002',1500),('ACT-003',2000),('ACT-004',1500),('ACT-005',1000),
 ('ACT-006',15000),('ACT-007',500),('ACT-008',1000),('ACT-009',5000),('ACT-010',2500),
 ('ACT-011',8000),('ACT-012',6000),('ACT-013',0),('ACT-014',3000),('ACT-015',4000),
 ('ACT-016',0),('ACT-017',7000),('ACT-018',5000)
) AS v(code,montant) ON v.code = a.code;

INSERT INTO tarif (structure_id, examen_id, type_regime, montant, devise, date_debut)
SELECT '22222222-0000-0000-0000-000000000001', e.id, 'PAYANT', v.montant, 'CDF', DATE '2026-01-01'
FROM examen_ref e JOIN (VALUES
 ('TDR-PALU',1500),('GE',2000),('HB',2000),('TDR-VIH',0),('SELLES',1500),('NFS',3500),
 ('EMMEL',2000),('SED-URIN',1500),('VS',1500),('BANDELETTE',1000),('GLYCEMIE',2000),
 ('GROUPE',2500),('SYPHILIS',2000),('PONCTION',3000)
) AS v(code,montant) ON v.code = e.code;

-- Gratuité maternité : tarif à 0 pour le patient, valorisation portée par le programme
INSERT INTO tarif (structure_id, acte_id, type_regime, montant, devise, date_debut)
SELECT '22222222-0000-0000-0000-000000000001', a.id, 'GRATUITE_MATERNITE', 0, 'CDF', DATE '2026-01-01'
FROM acte a WHERE a.code IN ('ACT-003','ACT-004','ACT-006');

INSERT INTO taux_change (date_jour, devise_source, devise_cible, taux) VALUES
 (DATE '2026-09-22','USD','CDF',2850.00),
 (DATE '2026-09-22','CDF','USD',0.000351);

-- 1.9 Antigènes du calendrier vaccinal national
INSERT INTO antigene (code, libelle, produit_id, cible, age_cible_jours, numero_dose,
                      intervalle_min_jours, doses_par_flacon, duree_flacon_ouvert_heures)
SELECT v.code, v.libelle, p.id, v.cible, v.age, v.dose, v.interv, v.dpf, v.dfo
FROM (VALUES
 ('BCG','BCG','VAC-001','ENFANT',0,1,NULL,20,6),
 ('VPO0','Polio oral dose 0','VAC-003','ENFANT',0,0,NULL,20,24),
 ('VPO1','Polio oral 1','VAC-003','ENFANT',42,1,28,20,24),
 ('VPO2','Polio oral 2','VAC-003','ENFANT',70,2,28,20,24),
 ('VPO3','Polio oral 3','VAC-003','ENFANT',98,3,28,20,24),
 ('VPI1','Polio inactivé 1','VAC-004','ENFANT',98,1,NULL,5,6),
 ('VPI2','Polio inactivé 2','VAC-004','ENFANT',270,2,120,5,6),
 ('PENTA1','Pentavalent 1','VAC-002','ENFANT',42,1,28,10,6),
 ('PENTA2','Pentavalent 2','VAC-002','ENFANT',70,2,28,10,6),
 ('PENTA3','Pentavalent 3','VAC-002','ENFANT',98,3,28,10,6),
 ('PCV1','Pneumocoque 1','VAC-006','ENFANT',42,1,28,4,6),
 ('PCV2','Pneumocoque 2','VAC-006','ENFANT',70,2,28,4,6),
 ('PCV3','Pneumocoque 3','VAC-006','ENFANT',98,3,28,4,6),
 ('ROTA1','Rotavirus 1','VAC-008','ENFANT',42,1,28,1,6),
 ('ROTA2','Rotavirus 2','VAC-008','ENFANT',70,2,28,1,6),
 ('VAR1','Antirougeoleux 1','VAC-005','ENFANT',270,1,NULL,10,6),
 ('VAR2','Antirougeoleux 2','VAC-005','ENFANT',450,2,120,10,6),
 ('VAT1','Antitétanique 1','VAC-007','FEMME_ENCEINTE',NULL,1,NULL,10,6),
 ('VAT2','Antitétanique 2','VAC-007','FEMME_ENCEINTE',NULL,2,28,10,6)
) AS v(code,libelle,pcode,cible,age,dose,interv,dpf,dfo)
LEFT JOIN produit p ON p.code = v.pcode;

-- 1.10 Méthodes de planification familiale
INSERT INTO methode_pf (code, libelle, categorie, produit_id, duree_protection_jours, facteur_cap)
SELECT v.code, v.libelle, v.cat, p.id, v.duree, v.cap
FROM (VALUES
 ('PF-ORALE','Contraceptif oral combiné','ORALE','PF-001',28,0.0667),
 ('PF-INJ','Injectable trimestriel','INJECTABLE','PF-002',90,0.25),
 ('PF-IMPL','Implant','IMPLANT','PF-003',1095,3.0),
 ('PF-DIU','Dispositif intra-utérin','DIU','PF-005',3650,4.6),
 ('PF-PRES','Préservatif masculin','BARRIERE','PF-004',1,0.0083),
 ('PF-NAT','Méthodes naturelles','NATURELLE',NULL,NULL,NULL)
) AS v(code,libelle,cat,pcode,duree,cap)
LEFT JOIN produit p ON p.code = v.pcode;

-- 1.11 Programmes verticaux
INSERT INTO programme (code, libelle) VALUES
 ('PALU','Lutte contre le paludisme'),('TB','Lutte contre la tuberculose'),
 ('VIH','Prise en charge du VIH'),('IST','Infections sexuellement transmissibles'),
 ('HTA','Hypertension artérielle'),('DIABETE','Diabète'),
 ('LEPRE','Lèpre'),('THA','Trypanosomiase humaine africaine'),('NUT','Nutrition');

-- 1.12 Plan comptable simplifié et journaux
INSERT INTO compte_comptable (numero, libelle, classe, type) VALUES
 ('411','Créances patients',4,'ACTIF'),
 ('412','Créances tiers payants',4,'ACTIF'),
 ('531','Caisse CDF',5,'ACTIF'),
 ('532','Caisse USD',5,'ACTIF'),
 ('521','Banque',5,'ACTIF'),
 ('311','Stock de médicaments',3,'ACTIF'),
 ('401','Fournisseurs',4,'PASSIF'),
 ('421','Personnel — rémunérations dues',4,'PASSIF'),
 ('601','Achats de médicaments et consommables',6,'CHARGE'),
 ('605','Eau, électricité, carburant',6,'CHARGE'),
 ('624','Entretien et maintenance',6,'CHARGE'),
 ('661','Rémunérations du personnel',6,'CHARGE'),
 ('706','Recettes de prestations de services',7,'PRODUIT'),
 ('707','Recettes de vente de médicaments',7,'PRODUIT'),
 ('758','Subventions et financement indirect',7,'PRODUIT');

INSERT INTO journal_comptable (code, libelle) VALUES
 ('CA','Journal de caisse'),('BQ','Journal de banque'),('AC','Journal des achats'),
 ('VE','Journal des ventes'),('PA','Journal de paie'),('OD','Opérations diverses');

-- 1.13 Indicateurs FBP achetés
INSERT INTO indicateur_fbp (code, libelle, unite, tarif_unitaire, devise, source_verification, date_debut) VALUES
 ('FBP-01','Nouveau cas de consultation curative','cas',0.40,'USD','Registre de consultation curative',DATE '2026-01-01'),
 ('FBP-02','Consultation prénatale 1re visite','visite',1.00,'USD','Registre CPN',DATE '2026-01-01'),
 ('FBP-03','Consultation prénatale 4e visite','visite',1.50,'USD','Registre CPN',DATE '2026-01-01'),
 ('FBP-04','Accouchement assisté par personnel qualifié','accouchement',6.00,'USD','Registre d''accouchement',DATE '2026-01-01'),
 ('FBP-05','Enfant complètement vacciné (Penta 3)','enfant',1.50,'USD','Registre PEV',DATE '2026-01-01'),
 ('FBP-06','Enfant MAS guéri (UNTA)','enfant',5.00,'USD','Registre UNTA',DATE '2026-01-01'),
 ('FBP-07','Nouvelle acceptante PF méthode longue durée','cliente',3.00,'USD','Registre PF',DATE '2026-01-01'),
 ('FBP-08','Cas de tuberculose guéri','cas',10.00,'USD','Registre TB',DATE '2026-01-01'),
 ('FBP-09','Référence arrivée à l''HGR','référence',1.00,'USD','Registre des référés + contre-référence',DATE '2026-01-01'),
 ('FBP-10','Consultation postnatale dans les 48 h','visite',1.00,'USD','Registre CPoN',DATE '2026-01-01');

-- 1.14 Éléments de données SNIS (extrait, avec correspondance DHIS2)
INSERT INTO element_donnee_snis (code, rubrique, libelle, unite, ventilation, code_dhis2_de, formule) VALUES
 ('SNIS-CONS-001','CONSULTATIONS','Cas reçus','nombre','{SEXE,AGE}','deCasRecus','count(venue WHERE type=CURATIF)'),
 ('SNIS-CONS-002','CONSULTATIONS','Nouveaux cas','nombre','{SEXE,AGE}','deNouveauxCas','count(venue WHERE cas=NOUVEAU)'),
 ('SNIS-CONS-003','CONSULTATIONS','Anciens cas','nombre','{SEXE,AGE}','deAnciensCas','count(venue WHERE cas=ANCIEN)'),
 ('SNIS-CONS-004','CONSULTATIONS','Nouveaux cas femmes enceintes','nombre','{}','deNCFemmesEnc','count(venue JOIN dossier_grossesse actif)'),
 ('SNIS-CONS-005','CONSULTATIONS','Nouveaux cas mutualistes','nombre','{}','deNCMutualistes','count(venue WHERE regime=MUTUELLE)'),
 ('SNIS-CONS-006','CONSULTATIONS','Nouveaux cas indigents','nombre','{}','deNCIndigents','count(venue WHERE regime=INDIGENT)'),
 ('SNIS-MORB-001','MORBIDITE','Paludisme confirmé','nombre','{SEXE,AGE}','dePaluConfirme','count(diag B50* AND confirme)'),
 ('SNIS-MORB-002','MORBIDITE','Pneumonie','nombre','{SEXE,AGE}','denPneumonie','count(diag J18*)'),
 ('SNIS-MORB-003','MORBIDITE','Diarrhée','nombre','{SEXE,AGE}','deDiarrhee','count(diag A09)'),
 ('SNIS-MERE-001','SANTE_MERE','CPN 1re visite','nombre','{}','deCPN1','count(visite_cpn WHERE numero=1)'),
 ('SNIS-MERE-002','SANTE_MERE','CPN 4e visite','nombre','{}','deCPN4','count(visite_cpn WHERE numero>=4)'),
 ('SNIS-MERE-003','SANTE_MERE','Accouchements assistés','nombre','{}','deAccAssistes','count(accouchement WHERE assistance_qualifiee)'),
 ('SNIS-MERE-004','SANTE_MERE','Décès maternels','nombre','{}','deDecesMat','count(deces WHERE type=MATERNEL)'),
 ('SNIS-MERE-005','SANTE_MERE','CPoN dans les 48 heures','nombre','{}','deCPoN48','count(visite_postnatale WHERE jour<=2)'),
 ('SNIS-ENF-001','SANTE_ENFANT','Penta 3','nombre','{}','dePenta3','count(vaccination antigene=PENTA3)'),
 ('SNIS-ENF-002','SANTE_ENFANT','VAR 2','nombre','{}','deVAR2','count(vaccination antigene=VAR2)'),
 ('SNIS-PF-001','PF','Nouvelles acceptantes PF','nombre','{}','dePFNouvelles','count(suivi_pf WHERE nouvelle)'),
 ('SNIS-NUT-001','NUTRITION','Admissions UNTA','nombre','{}','deUNTAAdm','count(admission_nutrition WHERE unite=UNTA)'),
 ('SNIS-NUT-002','NUTRITION','Guéris UNTA','nombre','{}','deUNTAGueri','count(admission WHERE issue=GUERI)'),
 ('SNIS-LAB-001','LABO','Examens réalisés','nombre','{}','deLabTotal','count(resultat_examen valide)'),
 ('SNIS-PHAR-001','PHARMACIE','Valeur du stock','CDF','{}','deValeurStock','sum(stock * prix_achat)'),
 ('SNIS-FIN-001','FINANCES','Recettes du mois','CDF','{}','deRecettes','sum(paiement non annulé)'),
 ('SNIS-FIN-002','FINANCES','Dépenses du mois','CDF','{}','deDepenses','sum(depense)'),
 ('SNIS-FIN-003','FINANCES','Financement indirect','CDF','{}','deFinIndirect','saisie manuelle'),
 ('SNIS-REF-001','REFERENCE','Malades référés','nombre','{}','deReferes','count(reference)'),
 ('SNIS-REF-002','REFERENCE','Contre-références reçues','nombre','{}','deContreRef','count(reference WHERE contre_reference_recue)'),
 ('SNIS-DECES-001','DECES','Décès au centre de santé','nombre','{SEXE,AGE}','deDeces','count(venue WHERE issue=DECES)'),
 ('SNIS-PERS-001','PERSONNEL','Jours de travail prestés','jours','{}','deJoursPrestes','sum(presence WHERE present)'),
 ('SNIS-MAT-001','MATERIEL','Frigo fonctionnel','oui/non','{}','deFrigoOK','equipement.etat'),
 ('SNIS-MAT-002','MATERIEL','Microscope fonctionnel','oui/non','{}','deMicroscopeOK','equipement.etat');

-- 1.15 Protocole national (exemple : paludisme grave chez l'enfant)
INSERT INTO protocole (code, libelle, domaine, version, date_debut, contenu) VALUES
 ('PROT-PALU-GRAVE','Paludisme grave chez l''enfant','PALUDISME','2024.1',DATE '2026-01-01',
  '{"racine":{"question":"Signes de gravité présents ?","oui":{"action":"Artésunate IV 2,4 mg/kg à H0, H12, H24 puis ACT oral","controles":["Hb","glycémie"],"reference":"HGR si Hb<5 ou convulsions persistantes"},"non":{"action":"ACT selon le poids pendant 3 jours","controle":"TDR de contrôle à J3 si persistance"}}}'::jsonb),
 ('PROT-DIARRHEE','Diarrhée aiguë de l''enfant','DIARRHEE','2024.1',DATE '2026-01-01',
  '{"racine":{"question":"Signes de déshydratation ?","severe":{"action":"Plan C : Ringer lactate IV, référence"},"moderee":{"action":"Plan B : SRO 75 ml/kg sur 4 h + zinc 20 mg 10 j"},"aucune":{"action":"Plan A : SRO à domicile + zinc 20 mg 10 j"}}}'::jsonb);

-- =====================================================================
-- PARTIE 2 — DONNÉES DE DÉMONSTRATION ET DE FORMATION
-- Purge : DELETE des tables ci-dessous avant mise en production réelle
-- =====================================================================

-- 2.1 Agents et utilisateurs (mots de passe à changer à la première connexion)
INSERT INTO agent (id, structure_id, matricule, nom, post_nom, prenom, sexe, qualification, fonction, statut, date_entree) VALUES
 ('77777777-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','MAT-001','KABEYA','Mwamba','Michel','M','INFIRMIER_A1','Infirmier Titulaire','Fonctionnaire',DATE '2018-03-01'),
 ('77777777-0000-0000-0000-000000000002','22222222-0000-0000-0000-000000000001','MAT-002','NGALULA','Kapend','Thérèse','F','SAGE_FEMME','Responsable maternité','Fonctionnaire',DATE '2019-09-15'),
 ('77777777-0000-0000-0000-000000000003','22222222-0000-0000-0000-000000000001','MAT-003','MULUMBA','Tshite','Jean','M','TECH_LABO','Technicien de laboratoire','Contractuel',DATE '2021-01-10'),
 ('77777777-0000-0000-0000-000000000004','22222222-0000-0000-0000-000000000001','MAT-004','KALALA','Nsenga','Espérance','F','INFIRMIER_A2','Gestionnaire de pharmacie','Contractuel',DATE '2020-06-01'),
 ('77777777-0000-0000-0000-000000000005','22222222-0000-0000-0000-000000000001','MAT-005','ILUNGA','Banza','Bernard','M','CAISSIER','Caissier','Contractuel',DATE '2022-02-14'),
 ('77777777-0000-0000-0000-000000000006','22222222-0000-0000-0000-000000000001','MAT-006','MUJINGA','Lwamba','Alice','F','INFIRMIER_A2','Infirmière consultation','Fonctionnaire',DATE '2017-11-02'),
 ('77777777-0000-0000-0000-000000000007','22222222-0000-0000-0000-000000000001','MAT-007','KAYEMBE','Ndala','Patrick','M','NUTRITIONNISTE','Responsable nutrition','Contractuel',DATE '2023-04-03');

INSERT INTO utilisateur (id, agent_id, structure_id, login, mot_de_passe_hash, doit_changer_mdp) VALUES
 ('88888888-0000-0000-0000-000000000001','77777777-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','m.kabeya','$argon2id$CHANGEME',true),
 ('88888888-0000-0000-0000-000000000002','77777777-0000-0000-0000-000000000002','22222222-0000-0000-0000-000000000001','t.ngalula','$argon2id$CHANGEME',true),
 ('88888888-0000-0000-0000-000000000003','77777777-0000-0000-0000-000000000003','22222222-0000-0000-0000-000000000001','j.mulumba','$argon2id$CHANGEME',true),
 ('88888888-0000-0000-0000-000000000004','77777777-0000-0000-0000-000000000004','22222222-0000-0000-0000-000000000001','e.kalala','$argon2id$CHANGEME',true),
 ('88888888-0000-0000-0000-000000000005','77777777-0000-0000-0000-000000000005','22222222-0000-0000-0000-000000000001','b.ilunga','$argon2id$CHANGEME',true),
 ('88888888-0000-0000-0000-000000000006','77777777-0000-0000-0000-000000000006','22222222-0000-0000-0000-000000000001','a.mujinga','$argon2id$CHANGEME',true),
 ('88888888-0000-0000-0000-000000000007','77777777-0000-0000-0000-000000000007','22222222-0000-0000-0000-000000000001','p.kayembe','$argon2id$CHANGEME',true);

INSERT INTO utilisateur_role (utilisateur_id, role_id) VALUES
 ('88888888-0000-0000-0000-000000000001','66666666-0000-0000-0000-000000000001'),
 ('88888888-0000-0000-0000-000000000002','66666666-0000-0000-0000-000000000003'),
 ('88888888-0000-0000-0000-000000000003','66666666-0000-0000-0000-000000000004'),
 ('88888888-0000-0000-0000-000000000004','66666666-0000-0000-0000-000000000005'),
 ('88888888-0000-0000-0000-000000000005','66666666-0000-0000-0000-000000000006'),
 ('88888888-0000-0000-0000-000000000006','66666666-0000-0000-0000-000000000002'),
 ('88888888-0000-0000-0000-000000000007','66666666-0000-0000-0000-000000000002');

-- 2.2 Tiers payants
INSERT INTO tiers_payant (id, structure_id, code, nom, type, taux_prise_charge, ticket_moderateur,
                          plafond_par_episode, delai_facturation_jours, convention_debut) VALUES
 ('99999999-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','MUSOSA','Mutuelle de santé MUSOSA','MUTUELLE',80,20,50000,30,DATE '2025-01-01'),
 ('99999999-0000-0000-0000-000000000002','22222222-0000-0000-0000-000000000001','GRAT-MAT','Programme gratuité maternité et nouveau-né','GRATUITE_MATERNITE',100,0,NULL,30,DATE '2023-09-06'),
 ('99999999-0000-0000-0000-000000000003','22222222-0000-0000-0000-000000000001','MUT-GCM','Mutuelle Gécamines','EMPLOYEUR',70,30,100000,45,DATE '2024-07-01'),
 ('99999999-0000-0000-0000-000000000004','22222222-0000-0000-0000-000000000001','PROG-TB','Programme national tuberculose','PROGRAMME_VERTICAL',100,0,NULL,60,DATE '2022-01-01');

-- 2.3 Équipements
INSERT INTO equipement (id, structure_id, code, libelle, categorie, service_id, date_acquisition,
                        valeur_acquisition, source_financement, etat, chaine_froid) VALUES
 ('aaaaaaaa-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','EQ-001','Réfrigérateur PEV solaire','FRIGO','44444444-0000-0000-0000-000000000006',DATE '2022-05-10',3200000,'PEV / Gavi','FONCTIONNEL',true),
 ('aaaaaaaa-0000-0000-0000-000000000002','22222222-0000-0000-0000-000000000001','EQ-002','Microscope binoculaire','MICROSCOPE','44444444-0000-0000-0000-000000000006',DATE '2021-08-02',1800000,'PDSS','FONCTIONNEL',false),
 ('aaaaaaaa-0000-0000-0000-000000000003','22222222-0000-0000-0000-000000000001','EQ-003','Centrifugeuse','CENTRIFUGEUSE','44444444-0000-0000-0000-000000000006',DATE '2020-03-15',950000,'Fonds propres','EN_PANNE',false),
 ('aaaaaaaa-0000-0000-0000-000000000004','22222222-0000-0000-0000-000000000001','EQ-004','Glucomètre','GLUCOMETRE','44444444-0000-0000-0000-000000000006',DATE '2024-01-20',180000,'Fonds propres','FONCTIONNEL',false),
 ('aaaaaaaa-0000-0000-0000-000000000005','22222222-0000-0000-0000-000000000001','EQ-005','Spectrophotomètre','SPECTROPHOTOMETRE','44444444-0000-0000-0000-000000000006',DATE '2023-06-11',2400000,'PDSS','FONCTIONNEL',false),
 ('aaaaaaaa-0000-0000-0000-000000000006','22222222-0000-0000-0000-000000000001','EQ-006','Installation solaire 1,5 kW','SOLAIRE','44444444-0000-0000-0000-000000000008',DATE '2023-11-30',6800000,'ONG partenaire','FONCTIONNEL',false),
 ('aaaaaaaa-0000-0000-0000-000000000007','22222222-0000-0000-0000-000000000001','EQ-007','Réfrigérateur laboratoire','FRIGO','44444444-0000-0000-0000-000000000006',DATE '2022-05-10',2100000,'PDSS','FONCTIONNEL',true);

INSERT INTO releve_temperature (structure_id, equipement_id, date_jour, moment, temperature_c, hors_plage, releve_par) VALUES
 ('22222222-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001',DATE '2026-09-22','MATIN',9.4,true,'88888888-0000-0000-0000-000000000003'),
 ('22222222-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000007',DATE '2026-09-22','MATIN',6.1,false,'88888888-0000-0000-0000-000000000003');

-- 2.4 RECO et sites de soins communautaires
INSERT INTO reco (id, structure_id, nom, sexe, village_id, telephone, date_formation, type) VALUES
 ('bbbbbbbb-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','MWEMA Josué','M','33333333-0000-0000-0000-000000000001','+243 970 111 001',DATE '2024-03-12','RECO'),
 ('bbbbbbbb-0000-0000-0000-000000000002','22222222-0000-0000-0000-000000000001','KAPINGA Lydie','F','33333333-0000-0000-0000-000000000002','+243 970 111 002',DATE '2024-03-12','RECO'),
 ('bbbbbbbb-0000-0000-0000-000000000003','22222222-0000-0000-0000-000000000001','BWANGA Félix','M','33333333-0000-0000-0000-000000000005','+243 970 111 003',DATE '2025-05-20','RECO');

INSERT INTO site_soins_communautaire (structure_id, nom, village_id, reco_id, fonctionnel) VALUES
 ('22222222-0000-0000-0000-000000000001','SSC Mwenge','33333333-0000-0000-0000-000000000005','bbbbbbbb-0000-0000-0000-000000000003',true);

-- 2.5 Patients de démonstration
INSERT INTO patient (id, structure_id, numero_dossier, nom, post_nom, prenom, sexe, date_naissance,
                     village_id, telephone, provenance, consentement_donnees, date_consentement) VALUES
 ('cccccccc-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','2019-0221','MUKENDI','Ilunga','Agnès','F',DATE '1996-07-04','33333333-0000-0000-0000-000000000001','+243 971 222 001','AIRE_SANTE',true,DATE '2019-02-11'),
 ('cccccccc-0000-0000-0000-000000000002','22222222-0000-0000-0000-000000000001','2026-0418','MUKENDI','Ilunga','Sarah','F',DATE '2023-03-14','33333333-0000-0000-0000-000000000001',NULL,'AIRE_SANTE',true,DATE '2023-03-14'),
 ('cccccccc-0000-0000-0000-000000000003','22222222-0000-0000-0000-000000000001','2024-1187','NGOY','Kabamba','Joseph','M',DATE '1985-01-22','33333333-0000-0000-0000-000000000003','+243 971 222 003','AIRE_SANTE',true,DATE '2024-05-02'),
 ('cccccccc-0000-0000-0000-000000000004','22222222-0000-0000-0000-000000000001','2023-0904','KASONGO','Mwila','Marie','F',DATE '1998-11-09','33333333-0000-0000-0000-000000000002','+243 971 222 004','AIRE_SANTE',true,DATE '2023-08-19'),
 ('cccccccc-0000-0000-0000-000000000005','22222222-0000-0000-0000-000000000001','2026-0512','MBAYO','Kalonji','Daniel','M',DATE '2026-02-18','33333333-0000-0000-0000-000000000003',NULL,'AIRE_SANTE',true,DATE '2026-02-20'),
 ('cccccccc-0000-0000-0000-000000000006','22222222-0000-0000-0000-000000000001','2021-0655','TSHIBANGU','Mputu','Paul','M',DATE '1970-04-30','33333333-0000-0000-0000-000000000004','+243 971 222 006','AIRE_SANTE',true,DATE '2021-06-14'),
 ('cccccccc-0000-0000-0000-000000000007','22222222-0000-0000-0000-000000000001','2025-0330','ILUNGA','Mwadi','Béatrice','F',DATE '2002-09-12','33333333-0000-0000-0000-000000000001','+243 971 222 007','AIRE_SANTE',true,DATE '2025-03-30');

UPDATE patient SET mere_id = 'cccccccc-0000-0000-0000-000000000001' WHERE id = 'cccccccc-0000-0000-0000-000000000002';

INSERT INTO alerte_clinique (patient_id, type, libelle, gravite) VALUES
 ('cccccccc-0000-0000-0000-000000000002','ALLERGIE','Cotrimoxazole — éruption cutanée généralisée','MAJEURE'),
 ('cccccccc-0000-0000-0000-000000000006','CHRONIQUE','Hypertension artérielle sous traitement','MODEREE');

INSERT INTO patient_regime (patient_id, type_regime, tiers_payant_id, numero_affiliation, date_debut, actif) VALUES
 ('cccccccc-0000-0000-0000-000000000002','MUTUELLE','99999999-0000-0000-0000-000000000001','MU-4471',DATE '2026-01-01',true),
 ('cccccccc-0000-0000-0000-000000000004','INDIGENT',NULL,NULL,DATE '2026-01-15',true),
 ('cccccccc-0000-0000-0000-000000000007','GRATUITE_MATERNITE','99999999-0000-0000-0000-000000000002',NULL,DATE '2026-03-01',true),
 ('cccccccc-0000-0000-0000-000000000006','EMPLOYEUR','99999999-0000-0000-0000-000000000003','GCM-8812',DATE '2024-07-01',true);

-- 2.6 Lots et stock initial
INSERT INTO lot (id, produit_id, numero_lot, date_peremption, prix_achat_unitaire, devise_achat)
SELECT v.id::uuid, p.id, v.lot, v.perem::date, v.prix, 'CDF'
FROM (VALUES
 ('dddddddd-0000-0000-0000-000000000001','MED-001','AL-2511-D','2026-11-30',140),
 ('dddddddd-0000-0000-0000-000000000002','MED-001','AL-2504-A','2027-04-30',140),
 ('dddddddd-0000-0000-0000-000000000003','MED-002','AS-2605-B','2027-04-30',1400),
 ('dddddddd-0000-0000-0000-000000000004','MED-004','CT-2411','2026-11-30',60),
 ('dddddddd-0000-0000-0000-000000000005','MED-005','PA-2603-A','2027-08-31',1250),
 ('dddddddd-0000-0000-0000-000000000006','MED-009','FE-2602-C','2027-02-28',1700),
 ('dddddddd-0000-0000-0000-000000000007','MED-007','SRO-2606','2028-06-30',180),
 ('dddddddd-0000-0000-0000-000000000008','VAC-002','PEN-2608','2027-02-28',0),
 ('dddddddd-0000-0000-0000-000000000009','VAC-005','VAR-2607','2027-01-31',0),
 ('dddddddd-0000-0000-0000-00000000000a','LAB-001','TDR-2609-A','2027-09-30',900),
 ('dddddddd-0000-0000-0000-00000000000b','NUT-001','ATPE-2605','2027-05-31',2100)
) AS v(id,pcode,lot,perem,prix)
JOIN produit p ON p.code = v.pcode;

-- Stock initial via mouvements (le trigger met à jour la table stock et le solde)
INSERT INTO mouvement_stock (structure_id, depot_id, lot_id, type, quantite, solde_apres,
                             piece_reference, date_mouvement, saisi_par)
SELECT '22222222-0000-0000-0000-000000000001', v.depot::uuid, v.lot::uuid, 'ENTREE', v.qte, 0,
       'INV-INITIAL-2026-09', TIMESTAMPTZ '2026-09-01 08:00+02', '88888888-0000-0000-0000-000000000004'
FROM (VALUES
 ('55555555-0000-0000-0000-000000000001','dddddddd-0000-0000-0000-000000000001',200),
 ('55555555-0000-0000-0000-000000000001','dddddddd-0000-0000-0000-000000000002',130),
 ('55555555-0000-0000-0000-000000000001','dddddddd-0000-0000-0000-000000000003',14),
 ('55555555-0000-0000-0000-000000000001','dddddddd-0000-0000-0000-000000000004',142),
 ('55555555-0000-0000-0000-000000000001','dddddddd-0000-0000-0000-000000000005',42),
 ('55555555-0000-0000-0000-000000000001','dddddddd-0000-0000-0000-000000000006',3),
 ('55555555-0000-0000-0000-000000000001','dddddddd-0000-0000-0000-000000000007',260),
 ('55555555-0000-0000-0000-000000000004','dddddddd-0000-0000-0000-000000000008',120),
 ('55555555-0000-0000-0000-000000000004','dddddddd-0000-0000-0000-000000000009',80),
 ('55555555-0000-0000-0000-000000000003','dddddddd-0000-0000-0000-00000000000a',175),
 ('55555555-0000-0000-0000-000000000001','dddddddd-0000-0000-0000-00000000000b',96)
) AS v(depot,lot,qte);

-- Rupture en cours sur produits traceurs
INSERT INTO rupture_stock (structure_id, depot_id, produit_id, date_debut)
SELECT '22222222-0000-0000-0000-000000000001','55555555-0000-0000-0000-000000000001', p.id, v.debut::date
FROM (VALUES ('MED-003','2026-09-18'),('MED-010','2026-09-21'),('MED-015','2026-09-13')) AS v(code,debut)
JOIN produit p ON p.code = v.code;

-- 2.7 Épisode de soins complet (cas de démonstration et de recette T01/T02)
INSERT INTO venue (id, structure_id, patient_id, numero_venue, numero_jeton, date_heure_arrivee,
                   type_venue, cas, priorite, motif, service_orientation_id, statut,
                   regime_applique_id, accueil_par)
SELECT 'eeeeeeee-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001',
       'cccccccc-0000-0000-0000-000000000002','2026-09-1142',2,
       TIMESTAMPTZ '2026-09-22 12:58+02','CURATIF','NOUVEAU','URGENCE',
       'Convulsions et fièvre depuis 2 jours','44444444-0000-0000-0000-000000000002','EN_CONSULTATION',
       pr.id,'88888888-0000-0000-0000-000000000001'
FROM patient_regime pr
WHERE pr.patient_id = 'cccccccc-0000-0000-0000-000000000002' AND pr.type_regime = 'MUTUELLE';

INSERT INTO triage (venue_id, poids_kg, taille_cm, perimetre_brachial_mm, temperature_c,
                    pouls, freq_respiratoire, z_score_pt, signes_danger, mesure_par) VALUES
 ('eeeeeeee-0000-0000-0000-000000000001',11.4,89,121,39.6,148,42,-2.3,
  '{CONVULSIONS,INCAPACITE_DE_BOIRE}','88888888-0000-0000-0000-000000000006');

INSERT INTO consultation (id, venue_id, patient_id, date_heure, plainte_principale, anamnese,
                          antecedents, hypotheses, conduite, praticien_id, validee) VALUES
 ('ffffffff-0000-0000-0000-000000000001','eeeeeeee-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000002',
  TIMESTAMPTZ '2026-09-22 13:10+02',
  'Convulsions, fièvre depuis 2 jours, refus de boire',
  'Fièvre brutale il y a 48 h, 2 épisodes convulsifs tonico-cloniques, vomissements. Pas de traitement antérieur.',
  'Allergie documentée au cotrimoxazole. Penta 1-3 et VAR 1 reçus.',
  'Paludisme grave avec anémie',
  'Artésunate IV en salle de soins, contrôle Hb urgent, référence HGR si Hb < 5 g/dl.',
  '88888888-0000-0000-0000-000000000006', false);

INSERT INTO consultation_diagnostic (consultation_id, diagnostic_id, principal, confirme)
SELECT 'ffffffff-0000-0000-0000-000000000001', d.id, v.principal, v.confirme
FROM (VALUES ('B50.0',true,true),('D50.9',false,true)) AS v(code,principal,confirme)
JOIN diagnostic_ref d ON d.code_cim10 = v.code;

INSERT INTO prescription (venue_id, consultation_id, patient_id, produit_id, dose, voie,
                          frequence_par_jour, duree_jours, quantite_prescrite, posologie_texte, prescripteur_id)
SELECT 'eeeeeeee-0000-0000-0000-000000000001','ffffffff-0000-0000-0000-000000000001',
       'cccccccc-0000-0000-0000-000000000002', p.id, v.dose, v.voie, v.freq, v.duree, v.qte, v.txt,
       '88888888-0000-0000-0000-000000000006'
FROM (VALUES
 ('MED-002','27,4 mg','IV',1,3,3,'2,4 mg/kg à H0, H12, H24'),
 ('MED-001','2 comprimés','orale',2,3,12,'2 cp matin et soir pendant 3 jours'),
 ('MED-005','171 mg','orale',4,3,1,'15 mg/kg toutes les 6 heures'),
 ('MED-009','5 ml','orale',1,30,1,'1 cuillère à café par jour pendant 30 jours')
) AS v(code,dose,voie,freq,duree,qte,txt)
JOIN produit p ON p.code = v.code;

INSERT INTO demande_examen (id, venue_id, patient_id, consultation_id, numero_labo, urgent, prescripteur_id) VALUES
 ('eeeeeeee-0000-0000-0000-000000000011','eeeeeeee-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000002',
  'ffffffff-0000-0000-0000-000000000001','LAB-2026-0873',true,'88888888-0000-0000-0000-000000000006');

INSERT INTO demande_examen_ligne (id, demande_id, examen_id)
SELECT v.id::uuid, 'eeeeeeee-0000-0000-0000-000000000011', e.id
FROM (VALUES
 ('eeeeeeee-0000-0000-0000-000000000021','TDR-PALU'),
 ('eeeeeeee-0000-0000-0000-000000000022','HB'),
 ('eeeeeeee-0000-0000-0000-000000000023','GE'),
 ('eeeeeeee-0000-0000-0000-000000000024','GROUPE')
) AS v(id,code)
JOIN examen_ref e ON e.code = v.code;

INSERT INTO resultat_examen (demande_ligne_id, valeur_numerique, valeur_qualitative, unite,
                             interpretation, critique, technicien_id, valide) VALUES
 ('eeeeeeee-0000-0000-0000-000000000021',NULL,'POSITIF',NULL,'ANORMAL',false,'88888888-0000-0000-0000-000000000003',true),
 ('eeeeeeee-0000-0000-0000-000000000022',5.2,NULL,'g/dl','CRITIQUE',true,'88888888-0000-0000-0000-000000000003',true),
 ('eeeeeeee-0000-0000-0000-000000000023',12400,NULL,'/µl','ANORMAL',false,'88888888-0000-0000-0000-000000000003',true),
 ('eeeeeeee-0000-0000-0000-000000000024',NULL,'O+',NULL,NULL,false,'88888888-0000-0000-0000-000000000003',true);

-- 2.8 Dossier de grossesse et accouchement en cours (cas T03)
INSERT INTO dossier_grossesse (id, structure_id, patient_id, numero_cpn, date_ouverture, ddr, dpa,
                               gestite, parite, groupe_sanguin, statut_vih, test_syphilis) VALUES
 ('aaaabbbb-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000004',
  'CPN-2026-0087',DATE '2026-03-04',DATE '2025-12-18',DATE '2026-09-24',3,2,'A+','NEGATIF','NEGATIF');

INSERT INTO visite_cpn (dossier_grossesse_id, numero_visite, date_visite, age_gestationnel_semaines,
                        poids_kg, tension_systolique, tension_diastolique, hauteur_uterine_cm, bcf,
                        hemoglobine, vat_dose, tpi_dose, fer_acide_folique, milda_recue, prochain_rdv, prestataire_id) VALUES
 ('aaaabbbb-0000-0000-0000-000000000001',1,DATE '2026-03-04',11,58.0,112,70,12,NULL,11.4,1,1,true,true,DATE '2026-05-06','88888888-0000-0000-0000-000000000002'),
 ('aaaabbbb-0000-0000-0000-000000000001',2,DATE '2026-05-06',20,61.5,115,72,20,142,11.0,2,2,true,false,DATE '2026-07-08','88888888-0000-0000-0000-000000000002'),
 ('aaaabbbb-0000-0000-0000-000000000001',3,DATE '2026-07-08',29,65.0,118,74,28,138,10.9,NULL,3,true,false,DATE '2026-09-02','88888888-0000-0000-0000-000000000002'),
 ('aaaabbbb-0000-0000-0000-000000000001',4,DATE '2026-09-02',37,68.2,120,76,35,140,10.8,NULL,NULL,true,false,DATE '2026-09-23','88888888-0000-0000-0000-000000000002');

INSERT INTO travail_accouchement (id, structure_id, dossier_grossesse_id, patient_id, numero_accouchement,
                                  date_heure_admission, type_accouchement, lieu, assistance_qualifiee,
                                  accoucheur_id, gratuite_appliquee) VALUES
 ('aaaabbbb-0000-0000-0000-000000000011','22222222-0000-0000-0000-000000000001','aaaabbbb-0000-0000-0000-000000000001',
  'cccccccc-0000-0000-0000-000000000004','ACC-2026-0052',TIMESTAMPTZ '2026-09-22 09:10+02',
  'EUTOCIQUE','FOSA',true,'88888888-0000-0000-0000-000000000002',true);

INSERT INTO partogramme_releve (accouchement_id, horodatage, dilatation_cm, descente_tete,
                                contractions_par_10min, duree_contraction_sec, bcf, liquide_amniotique,
                                temperature_c, pouls, tension_systolique, tension_diastolique, releve_par) VALUES
 ('aaaabbbb-0000-0000-0000-000000000011',TIMESTAMPTZ '2026-09-22 09:10+02',4,'-3',2,30,142,'Intact',36.9,82,115,70,'88888888-0000-0000-0000-000000000002'),
 ('aaaabbbb-0000-0000-0000-000000000011',TIMESTAMPTZ '2026-09-22 10:10+02',5,'-2',3,35,138,'Clair',37.0,84,118,72,'88888888-0000-0000-0000-000000000002'),
 ('aaaabbbb-0000-0000-0000-000000000011',TIMESTAMPTZ '2026-09-22 11:10+02',6,'-1',4,40,140,'Clair',37.1,86,120,75,'88888888-0000-0000-0000-000000000002'),
 ('aaaabbbb-0000-0000-0000-000000000011',TIMESTAMPTZ '2026-09-22 12:10+02',8,'0',4,45,134,'Clair',37.2,88,122,78,'88888888-0000-0000-0000-000000000002'),
 ('aaaabbbb-0000-0000-0000-000000000011',TIMESTAMPTZ '2026-09-22 13:10+02',9,'+1',5,45,128,'Teinté',37.4,92,126,80,'88888888-0000-0000-0000-000000000002');

-- 2.9 Vaccinations et suivi de croissance
INSERT INTO dossier_cps (id, structure_id, patient_id, numero_cps, date_ouverture, mere_id, village_id) VALUES
 ('aaaacccc-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000005',
  'CPS-2026-0233',DATE '2026-03-02',NULL,'33333333-0000-0000-0000-000000000003');

INSERT INTO visite_cps (dossier_cps_id, date_visite, age_mois, poids_kg, taille_cm, perimetre_brachial_mm,
                        z_score_pa, courbe, vitamine_a, prochain_rdv, prestataire_id) VALUES
 ('aaaacccc-0000-0000-0000-000000000001',DATE '2026-06-02',3,5.8,59,128,-0.4,'ASCENDANTE',false,DATE '2026-07-02','88888888-0000-0000-0000-000000000006'),
 ('aaaacccc-0000-0000-0000-000000000001',DATE '2026-09-02',6,7.1,65,132,-0.6,'ASCENDANTE',true,DATE '2026-10-02','88888888-0000-0000-0000-000000000006');

INSERT INTO vaccination (structure_id, patient_id, antigene_id, date_vaccination, lot_id, strategie, vaccinateur_id)
SELECT '22222222-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000005', a.id, v.dt::date,
       CASE WHEN v.code LIKE 'PENTA%' THEN 'dddddddd-0000-0000-0000-000000000008'::uuid ELSE NULL END,
       'FIXE','88888888-0000-0000-0000-000000000006'
FROM (VALUES ('BCG','2026-02-20'),('VPO0','2026-02-20'),('PENTA1','2026-04-01'),
             ('PENTA2','2026-04-29'),('PCV1','2026-04-01'),('PCV2','2026-04-29')) AS v(code,dt)
JOIN antigene a ON a.code = v.code;

-- 2.10 Cohortes des programmes verticaux
INSERT INTO inclusion_programme (structure_id, programme_id, patient_id, numero_registre,
                                 date_inclusion, categorie, schema_traitement, date_debut_traitement)
SELECT '22222222-0000-0000-0000-000000000001', pr.id, 'cccccccc-0000-0000-0000-000000000006',
       'HTA-2021-014', DATE '2021-06-14','Nouveau cas','Amlodipine 5 mg/j', DATE '2021-06-14'
FROM programme pr WHERE pr.code = 'HTA';

INSERT INTO suivi_programme (inclusion_id, date_visite, mois_traitement, observance,
                             poids_kg, tension_systolique, tension_diastolique, prochain_rdv, prestataire_id)
SELECT i.id, DATE '2026-09-22', 63,'Bonne',78.5,148,92, DATE '2026-10-22','88888888-0000-0000-0000-000000000006'
FROM inclusion_programme i WHERE i.numero_registre = 'HTA-2021-014';

-- 2.11 Nutrition
INSERT INTO admission_nutrition (structure_id, patient_id, unite, categorie, date_admission,
                                 critere_admission, pb_admission_mm, z_score_admission, poids_admission_kg)
VALUES ('22222222-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000002','UNS','MAM',
        DATE '2026-09-22','PB',121,-2.3,11.4);

-- 2.12 Facturation, caisse et paiements
INSERT INTO session_caisse (id, structure_id, caissier_id, poste, ouverture, fonds_initial) VALUES
 ('aaaadddd-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','88888888-0000-0000-0000-000000000005',
  'Guichet 1',TIMESTAMPTZ '2026-09-22 07:30+02',20000);

INSERT INTO facture (id, structure_id, venue_id, patient_id, numero, date_facture, devise,
                     montant_brut, part_patient, part_tiers, tiers_payant_id, type_regime, statut, etablie_par) VALUES
 ('aaaaeeee-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','eeeeeeee-0000-0000-0000-000000000001',
  'cccccccc-0000-0000-0000-000000000002','FAC-2026-1142',TIMESTAMPTZ '2026-09-22 13:35+02','CDF',
  25200,5040,20160,'99999999-0000-0000-0000-000000000001','MUTUELLE','VALIDEE','88888888-0000-0000-0000-000000000005');

INSERT INTO facture_ligne (facture_id, type_ligne, libelle, quantite, prix_unitaire,
                           taux_prise_charge, montant_total, part_patient, part_tiers) VALUES
 ('aaaaeeee-0000-0000-0000-000000000001','ACTE','Consultation curative (forfait)',1,3000,80,3000,600,2400),
 ('aaaaeeee-0000-0000-0000-000000000001','EXAMEN','TDR paludisme',1,1500,80,1500,300,1200),
 ('aaaaeeee-0000-0000-0000-000000000001','EXAMEN','Hémoglobine',1,2000,80,2000,400,1600),
 ('aaaaeeee-0000-0000-0000-000000000001','EXAMEN','Goutte épaisse',1,2000,80,2000,400,1600),
 ('aaaaeeee-0000-0000-0000-000000000001','EXAMEN','Groupe sanguin',1,2500,80,2500,500,2000),
 ('aaaaeeee-0000-0000-0000-000000000001','MEDICAMENT','Artésunate 60 mg inj.',3,2000,80,6000,1200,4800),
 ('aaaaeeee-0000-0000-0000-000000000001','MEDICAMENT','Artéméther-luméfantrine 20/120',12,200,80,2400,480,1920),
 ('aaaaeeee-0000-0000-0000-000000000001','MEDICAMENT','Paracétamol sirop',1,1800,80,1800,360,1440),
 ('aaaaeeee-0000-0000-0000-000000000001','MEDICAMENT','Fer + acide folique sirop',1,2500,80,2500,500,2000),
 ('aaaaeeee-0000-0000-0000-000000000001','ACTE','Injection',3,500,80,1500,300,1200);

INSERT INTO paiement (structure_id, facture_id, session_caisse_id, numero_recu, mode, devise,
                      montant, montant_equiv_cdf, encaisse_par) VALUES
 ('22222222-0000-0000-0000-000000000001','aaaaeeee-0000-0000-0000-000000000001','aaaadddd-0000-0000-0000-000000000001',
  'REC-2026-3391','ESPECES','CDF',5040,5040,'88888888-0000-0000-0000-000000000005');

INSERT INTO rumer_jour (structure_id, date_jour, valeur_stock_consomme, recettes_jour, versement_tresorier) VALUES
 ('22222222-0000-0000-0000-000000000001',DATE '2026-09-22',187400,412500,380000);

-- 2.13 Budget et paie
INSERT INTO budget (id, structure_id, exercice, statut) VALUES
 ('aaaaffff-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001',2026,'VALIDE');

INSERT INTO budget_ligne (budget_id, rubrique, source_financement, montant_prevu, montant_engage, montant_realise) VALUES
 ('aaaaffff-0000-0000-0000-000000000001','Achats de médicaments','Recouvrement des coûts',42000000,31500000,29800000),
 ('aaaaffff-0000-0000-0000-000000000001','Primes du personnel','FBP',18000000,13200000,13200000),
 ('aaaaffff-0000-0000-0000-000000000001','Eau, électricité, carburant','Recouvrement des coûts',6000000,4700000,4700000),
 ('aaaaffff-0000-0000-0000-000000000001','Maintenance et réparations','Fonds propres',3500000,2100000,1850000),
 ('aaaaffff-0000-0000-0000-000000000001','Activités communautaires','Partenaire',4800000,3600000,3600000);

INSERT INTO periode_paie (id, structure_id, mois, statut) VALUES
 ('aaaaffff-0000-0000-0000-000000000011','22222222-0000-0000-0000-000000000001',DATE '2026-09-01','OUVERTE');

INSERT INTO bulletin_paie (periode_paie_id, agent_id, salaire_base, prime_risque, prime_fbp, retenues, net_a_payer, jours_prestes)
SELECT 'aaaaffff-0000-0000-0000-000000000011', a.id, v.base, v.risque, v.fbp, v.ret,
       v.base + v.risque + v.fbp - v.ret, v.jours
FROM (VALUES
 ('MAT-001',420000,80000,145000,21000,22),
 ('MAT-002',380000,80000,132000,19000,21),
 ('MAT-003',310000,50000,84000,15500,22),
 ('MAT-004',310000,50000,92000,15500,22),
 ('MAT-005',260000,0,61000,13000,20),
 ('MAT-006',310000,50000,97000,15500,22),
 ('MAT-007',290000,40000,73000,14500,19)
) AS v(mat,base,risque,fbp,ret,jours)
JOIN agent a ON a.matricule = v.mat;

-- 2.14 Rapport mensuel d'août 2026 transmis (historique)
INSERT INTO rapport_mensuel (id, structure_id, periode_mois, type_rapport, statut, version,
                             genere_le, genere_par, valide_par, date_validation, transmis_le,
                             canal_transmission, complet) VALUES
 ('aaaa1111-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001',DATE '2026-08-01','SNIS_CS',
  'TRANSMIS',1,TIMESTAMPTZ '2026-09-02 09:00+02','88888888-0000-0000-0000-000000000001',
  '88888888-0000-0000-0000-000000000001',TIMESTAMPTZ '2026-09-02 16:00+02',
  TIMESTAMPTZ '2026-09-03 08:30+02','DHIS2_API',true);

INSERT INTO rapport_valeur (rapport_id, element_id, ventilation_cle, valeur_calculee, valeur_retenue)
SELECT 'aaaa1111-0000-0000-0000-000000000001', e.id, 'TOTAL', v.val, v.val
FROM (VALUES
 ('SNIS-CONS-001',1198),('SNIS-CONS-002',812),('SNIS-CONS-003',386),
 ('SNIS-CONS-005',104),('SNIS-CONS-006',49),
 ('SNIS-MORB-001',352),('SNIS-MORB-002',78),('SNIS-MORB-003',131),
 ('SNIS-MERE-001',64),('SNIS-MERE-002',38),('SNIS-MERE-003',49),('SNIS-MERE-004',0),
 ('SNIS-ENF-001',69),('SNIS-ENF-002',35),('SNIS-PF-001',22),
 ('SNIS-NUT-001',15),('SNIS-NUT-002',12),('SNIS-LAB-001',612),
 ('SNIS-PHAR-001',8120000),('SNIS-FIN-001',8845000),('SNIS-FIN-002',7410000),
 ('SNIS-REF-001',31),('SNIS-REF-002',19),('SNIS-DECES-001',2)
) AS v(code,val)
JOIN element_donnee_snis e ON e.code = v.code;

-- 2.15 Supervision et activités communautaires
INSERT INTO supervision (structure_id, date_supervision, type, superviseur, domaines, constats, recommandations, score) VALUES
 ('22222222-0000-0000-0000-000000000001',DATE '2026-09-11','ECZS','Dr KILUBA, MCZ',
  '{PHARMACIE,CONSULTATION,HYGIENE,GESTION}',
  'Fiches de stock à jour. Ordinogrammes affichés. Centrifugeuse en panne depuis mars. Deux ruptures de traceurs.',
  'Réparer la centrifugeuse, passer la commande avant le 5, renforcer la récupération des perdus de vue PEV.',78.5);

INSERT INTO activite_communautaire (structure_id, reco_id, date_activite, type, village_id,
                                    nb_menages, nb_personnes, nb_enfants_recuperes, theme, saisi_par) VALUES
 ('22222222-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001',DATE '2026-09-19','VISITE_DOMICILE',
  '33333333-0000-0000-0000-000000000001',18,94,6,'Récupération des enfants non vaccinés','88888888-0000-0000-0000-000000000001'),
 ('22222222-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000002',DATE '2026-09-20','SENSIBILISATION',
  '33333333-0000-0000-0000-000000000002',0,132,0,'Utilisation des MILDA et assainissement','88888888-0000-0000-0000-000000000001');

INSERT INTO perdu_de_vue (structure_id, patient_id, domaine, date_detection, reco_id) VALUES
 ('22222222-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000005','PEV',DATE '2026-09-15','bbbbbbbb-0000-0000-0000-000000000001');

-- 2.16 Sauvegardes et notifications
INSERT INTO sauvegarde (structure_id, type, chemin, taille_octets, chiffree, succes, horodatage) VALUES
 ('22222222-0000-0000-0000-000000000001','LOCALE','/var/backups/cs/2026-09-22-0612.dump.enc',184320000,true,true,TIMESTAMPTZ '2026-09-22 06:12+02'),
 ('22222222-0000-0000-0000-000000000001','EXTERNE','/media/usb1/cs/2026-09-21.dump.enc',183296000,true,true,TIMESTAMPTZ '2026-09-21 18:05+02');

INSERT INTO notification (structure_id, canal, type, message, statut) VALUES
 ('22222222-0000-0000-0000-000000000001','INTERNE','RUPTURE_STOCK','Amoxicilline 250 mg en rupture depuis 4 jours — 14 ordonnances non servies','EN_ATTENTE'),
 ('22222222-0000-0000-0000-000000000001','INTERNE','RESULTAT_CRITIQUE','Hb 5,2 g/dl chez MUKENDI Sarah (N° 2026-0418)','EN_ATTENTE'),
 ('22222222-0000-0000-0000-000000000001','INTERNE','PEREMPTION','Lot CT-2411 Cotrimoxazole : 142 cp expirent le 30/11/2026','EN_ATTENTE');

-- =====================================================================
-- Vérifications rapides après chargement
--   SELECT count(*) FROM patient;                    -- 7
--   SELECT * FROM v_sdu;                             -- stock disponible utilisable
--   SELECT * FROM v_registre_consultation;            -- registre de consultation
--   SELECT * FROM v_snis_consultations;               -- agrégats du canevas
-- =====================================================================
