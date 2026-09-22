/**
 * Jeu de démonstration miroir de supabase/seed.sql (Centre de Santé
 * Kamalondo, Lubumbashi). Il alimente l'interface lorsque la base n'est pas
 * encore reliée, afin que chaque écran reste explicite en formation.
 */
export const demo = {
  tableauDeBord: {
    consultations_jour: 37,
    nouveaux_cas_jour: 24,
    en_attente: 6,
    recettes_jour_cdf: 184500,
    traceurs_total: 26,
    traceurs_disponibles: 23,
    peremptions_90j: 4,
    resultats_critiques: 2,
    accouchements_mois: 18,
    dernier_rapport: { periode: '2026-08-01', statut: 'TRANSMIS' },
    population: 9450
  },
  file: [
    { venue_id: 'v1', numero_jeton: 12, numero_venue: '2026-09-0418', nom_complet: 'MUKENDI Ilunga Sarah', age_affiche: '3 ans', sexe: 'F', type_venue: 'CURATIF', cas: 'NOUVEAU', priorite: 'URGENCE', statut: 'EN_CONSULTATION', motif: 'Fièvre, convulsions', attente_minutes: 8, regime: 'MUTUELLE' },
    { venue_id: 'v2', numero_jeton: 13, numero_venue: '2026-09-0419', nom_complet: 'KASONGO Mwamba Marie', age_affiche: '27 ans', sexe: 'F', type_venue: 'MATERNITE', cas: 'ANCIEN', priorite: 'ROUTINE', statut: 'TRIAGE', motif: 'Travail débutant, G3P2', attente_minutes: 15, regime: 'GRATUITE_MATERNITE' },
    { venue_id: 'v3', numero_jeton: 14, numero_venue: '2026-09-0420', nom_complet: 'MBAYO Kalume Daniel', age_affiche: '4 mois', sexe: 'M', type_venue: 'PREVENTIF', cas: 'ANCIEN', priorite: 'ROUTINE', statut: 'ATTENTE', motif: 'CPS et vaccination Penta 2', attente_minutes: 22, regime: 'PAYANT' },
    { venue_id: 'v4', numero_jeton: 15, numero_venue: '2026-09-0421', nom_complet: 'TSHIBANGU Lupembe Paul', age_affiche: '54 ans', sexe: 'M', type_venue: 'SUIVI', cas: 'ANCIEN', priorite: 'ROUTINE', statut: 'ATTENTE', motif: 'Suivi hypertension', attente_minutes: 31, regime: 'EMPLOYEUR' },
    { venue_id: 'v5', numero_jeton: 16, numero_venue: '2026-09-0422', nom_complet: 'NGOY Kabila Espérance', age_affiche: '22 ans', sexe: 'F', type_venue: 'CURATIF', cas: 'NOUVEAU', priorite: 'ROUTINE', statut: 'LABO', motif: 'Céphalées, courbatures', attente_minutes: 12, regime: 'PAYANT' },
    { venue_id: 'v6', numero_jeton: 17, numero_venue: '2026-09-0423', nom_complet: 'ILUNGA Banza Josué', age_affiche: '8 ans', sexe: 'M', type_venue: 'CURATIF', cas: 'NOUVEAU', priorite: 'ROUTINE', statut: 'PHARMACIE', motif: 'Diarrhée aiguë', attente_minutes: 5, regime: 'INDIGENT' }
  ],
  patients: [
    { id: 'p1', numero_dossier: '2026-0418', nom_complet: 'MUKENDI Ilunga Sarah', sexe: 'F', age_affiche: '3 ans', telephone: '+243 97 000 0418', village: 'Kamalondo Centre', score: 1 },
    { id: 'p2', numero_dossier: '2026-0507', nom_complet: 'MBAYO Kalume Daniel', sexe: 'M', age_affiche: '4 mois', telephone: '+243 99 000 0507', village: 'Kalubwe', score: 0.9 },
    { id: 'p3', numero_dossier: '2024-0163', nom_complet: 'KASONGO Mwamba Marie', sexe: 'F', age_affiche: '27 ans', telephone: '+243 81 000 0163', village: 'Nsele', score: 0.8 },
    { id: 'p4', numero_dossier: '2019-0221', nom_complet: 'MUKENDI Ilunga Agnès', sexe: 'F', age_affiche: '30 ans', telephone: '+243 97 000 0221', village: 'Kamalondo Centre', score: 0.7 }
  ],
  consultation: {
    patient: 'MUKENDI Ilunga Sarah, 3 ans, dossier 2026-0418',
    alertes: ['Allergie documentée au cotrimoxazole', 'Hémoglobine 5,2 g/dl — anémie sévère'],
    plainte: 'Fièvre depuis 3 jours, convulsion généralisée ce matin, refus de boire',
    anamnese: "Début brutal, température mesurée à 39,8 °C au domicile. Un épisode convulsif de 2 minutes. Pas de vomissement en jet. Moustiquaire imprégnée non utilisée.",
    examen: 'Poids 12,4 kg — Taille 92 cm — T° 39,4 °C — FR 38/min — SpO2 96 % — Conjonctives pâles — Score de Blantyre 4',
    diagnostics: [
      { code: 'B50.0', libelle: 'Paludisme à Plasmodium falciparum avec complications cérébrales', principal: true },
      { code: 'D64.9', libelle: 'Anémie sans précision', principal: false }
    ],
    prescriptions: [
      { produit: 'Artésunate injectable 60 mg', posologie: '2,4 mg/kg à H0, H12, H24 puis par jour', quantite: 3 },
      { produit: 'Paracétamol sirop 120 mg/5 ml', posologie: '10 ml x 3 par jour pendant 3 jours', quantite: 1 },
      { produit: 'Fer + acide folique sirop', posologie: '5 ml par jour pendant 30 jours', quantite: 1 }
    ]
  },
  examens: [
    { id: 'e1', numero: 'LAB-2026-1188', patient: 'MUKENDI Ilunga Sarah', examen: 'Goutte épaisse / densité parasitaire', resultat: '+++ (12 400 parasites/µl)', reference: 'Négatif', critique: true, statut: 'VALIDE' },
    { id: 'e2', numero: 'LAB-2026-1188', patient: 'MUKENDI Ilunga Sarah', examen: 'Hémoglobine', resultat: '5,2 g/dl', reference: '11,0 – 14,0', critique: true, statut: 'VALIDE' },
    { id: 'e3', numero: 'LAB-2026-1190', patient: 'NGOY Kabila Espérance', examen: 'Test de diagnostic rapide paludisme', resultat: 'Négatif', reference: 'Négatif', critique: false, statut: 'VALIDE' },
    { id: 'e4', numero: 'LAB-2026-1191', patient: 'ILUNGA Banza Josué', examen: 'Selles — examen direct', resultat: 'En cours', reference: '—', critique: false, statut: 'EN_COURS' }
  ],
  sigl: [
    { produit_id: 's1', code: 'MED-001', dci: 'Artéméther-luméfantrine 20/120 mg', traceur: true, sdu: 330, consommation: 148, pertes: 0, jours_rupture: 0, cmm: 152, stock_securite: 152, stock_max: 456, a_commander: 126, mois_de_stock: 2.2 },
    { produit_id: 's2', code: 'MED-002', dci: 'Artésunate injectable 60 mg', traceur: true, sdu: 14, consommation: 22, pertes: 0, jours_rupture: 0, cmm: 20, stock_securite: 20, stock_max: 60, a_commander: 46, mois_de_stock: 0.7 },
    { produit_id: 's3', code: 'MED-003', dci: 'Amoxicilline 250 mg dispersible', traceur: true, sdu: 0, consommation: 310, pertes: 0, jours_rupture: 6, cmm: 290, stock_securite: 290, stock_max: 870, a_commander: 870, mois_de_stock: 0 },
    { produit_id: 's4', code: 'MED-004', dci: 'Sels de réhydratation orale', traceur: true, sdu: 240, consommation: 96, pertes: 4, jours_rupture: 0, cmm: 88, stock_securite: 88, stock_max: 264, a_commander: 24, mois_de_stock: 2.7 },
    { produit_id: 's5', code: 'MED-009', dci: 'Ocytocine 10 UI injectable', traceur: true, sdu: 62, consommation: 24, pertes: 2, jours_rupture: 0, cmm: 22, stock_securite: 22, stock_max: 66, a_commander: 4, mois_de_stock: 2.8 },
    { produit_id: 's6', code: 'NUT-001', dci: 'Aliment thérapeutique prêt à l\'emploi', traceur: true, sdu: 96, consommation: 60, pertes: 0, jours_rupture: 0, cmm: 58, stock_securite: 58, stock_max: 174, a_commander: 78, mois_de_stock: 1.7 }
  ],
  facture: {
    numero: 'FAC-2026-1142',
    patient: 'MUKENDI Ilunga Sarah',
    regime: 'MUTUELLE MUSOSA — prise en charge 80 %',
    lignes: [
      { libelle: 'Consultation curative enfant', quantite: 1, prix_unitaire: 3000, montant_total: 3000 },
      { libelle: 'Goutte épaisse', quantite: 1, prix_unitaire: 2500, montant_total: 2500 },
      { libelle: 'Hémoglobine', quantite: 1, prix_unitaire: 3500, montant_total: 3500 },
      { libelle: 'Artésunate injectable 60 mg', quantite: 3, prix_unitaire: 3400, montant_total: 10200 },
      { libelle: 'Paracétamol sirop', quantite: 1, prix_unitaire: 2500, montant_total: 2500 },
      { libelle: 'Fer + acide folique sirop', quantite: 1, prix_unitaire: 3500, montant_total: 3500 }
    ],
    montant_brut: 25200,
    part_patient: 5040,
    part_tiers: 20160
  },
  maternite: {
    cpn: [
      { id: 'c1', patient: 'KASONGO Mwamba Marie', gestite: 'G3P2', ddr: '2026-01-12', dpa: '2026-10-19', visite: 'CPN 4', ta: '118/74', hu: '34 cm', bcf: '142/min', vat: 'VAT 3', tpi: 'TPI 3 reçu' },
      { id: 'c2', patient: 'MWANZA Kabeya Cécile', gestite: 'G1P0', ddr: '2026-03-02', dpa: '2026-12-07', visite: 'CPN 2', ta: '112/70', hu: '24 cm', bcf: '136/min', vat: 'VAT 2', tpi: 'TPI 1 reçu' }
    ],
    partogramme: {
      patiente: 'KASONGO Mwamba Marie — G3P2',
      debut: '2026-09-22T06:40:00',
      releves: [
        { heure: '06:40', dilatation: 4, contractions: '3/10 min', bcf: 142, ta: '118/74' },
        { heure: '08:40', dilatation: 6, contractions: '4/10 min', bcf: 138, ta: '116/72' },
        { heure: '10:40', dilatation: 8, contractions: '4/10 min', bcf: 140, ta: '120/76' },
        { heure: '12:40', dilatation: 10, contractions: '5/10 min', bcf: 136, ta: '118/70' }
      ]
    }
  },
  pev: [
    { antigene: 'BCG', libelle: 'BCG', numero_dose: 1, date_theorique: '2026-05-14', date_recue: '2026-05-14', statut: 'RECU' },
    { antigene: 'VPO0', libelle: 'Polio orale — dose zéro', numero_dose: 0, date_theorique: '2026-05-14', date_recue: '2026-05-14', statut: 'RECU' },
    { antigene: 'PENTA1', libelle: 'Pentavalent 1', numero_dose: 1, date_theorique: '2026-06-25', date_recue: '2026-06-27', statut: 'RECU' },
    { antigene: 'PENTA2', libelle: 'Pentavalent 2', numero_dose: 2, date_theorique: '2026-07-23', date_recue: null, statut: 'DU' },
    { antigene: 'PENTA3', libelle: 'Pentavalent 3', numero_dose: 3, date_theorique: '2026-08-20', date_recue: null, statut: 'PROGRAMME' },
    { antigene: 'VAR1', libelle: 'Rougeole 1', numero_dose: 1, date_theorique: '2027-02-14', date_recue: null, statut: 'PROGRAMME' }
  ],
  couverture: [
    { antigene: 'BCG', cible: 378, realise: 352, couverture: 93 },
    { antigene: 'PENTA1', cible: 378, realise: 341, couverture: 90 },
    { antigene: 'PENTA3', cible: 378, realise: 302, couverture: 80 },
    { antigene: 'VAR1', cible: 378, realise: 288, couverture: 76 },
    { antigene: 'VAR2', cible: 378, realise: 194, couverture: 51 }
  ],
  rapport: {
    periode: '2026-09-01',
    statut: 'BROUILLON',
    valeurs: [
      { code: 'SNIS-CONS-001', libelle: 'Cas reçus en consultation curative', valeur: 812 },
      { code: 'SNIS-CONS-002', libelle: 'Nouveaux cas', valeur: 596 },
      { code: 'SNIS-CONS-003', libelle: 'Anciens cas', valeur: 216 },
      { code: 'SNIS-MERE-001', libelle: 'CPN 1', valeur: 74 },
      { code: 'SNIS-MERE-002', libelle: 'CPN 4', valeur: 51 },
      { code: 'SNIS-MERE-003', libelle: 'Accouchements assistés', valeur: 18 },
      { code: 'SNIS-ENF-001', libelle: 'Penta 3 administrés', valeur: 32 },
      { code: 'SNIS-ENF-002', libelle: 'VAR 2 administrés', valeur: 21 },
      { code: 'SNIS-LAB-001', libelle: 'Examens de laboratoire validés', valeur: 431 },
      { code: 'SNIS-FIN-001', libelle: 'Recettes encaissées (CDF)', valeur: 4128600 }
    ],
    controles: [
      { code_regle: 'CTL-001', severite: 'BLOQUANT', message: 'Cas reçus = nouveaux cas + anciens cas', respecte: true },
      { code_regle: 'CTL-006', severite: 'AVERTISSEMENT', message: 'CPN 4 inférieurs ou égaux aux CPN 1', respecte: true },
      { code_regle: 'CTL-020', severite: 'BLOQUANT', message: 'Décès inférieurs ou égaux aux cas reçus', respecte: true },
      { code_regle: 'CTL-009', severite: 'AVERTISSEMENT', message: 'Accouchements cohérents avec les nouveau-nés', respecte: true }
    ]
  },
  audit: [
    { id: 'a1', horodatage: '2026-09-22T12:41:00', utilisateur: 'm.kabeya', action: 'CREATION', entite: 'consultation', justification: null },
    { id: 'a2', horodatage: '2026-09-22T12:12:00', utilisateur: 'p.kazadi', action: 'MODIFICATION', entite: 'resultat_examen', justification: 'Correction unité Hb' },
    { id: 'a3', horodatage: '2026-09-22T11:55:00', utilisateur: 'a.caissier', action: 'CREATION', entite: 'paiement', justification: null },
    { id: 'a4', horodatage: '2026-09-22T10:02:00', utilisateur: 'b.nsenga', action: 'BRIS_DE_GLACE', entite: 'consultation', justification: 'Urgence obstétricale, dossier sensible' }
  ],
  utilisateurs: [
    { id: 'u1', login: 'm.kabeya', nom: 'KABEYA Ilunga Michel', qualification: 'Infirmier titulaire', roles: 'Titulaire, Rapportage', actif: true },
    { id: 'u2', login: 'b.nsenga', nom: 'NSENGA Bwalya Béatrice', qualification: 'Sage-femme', roles: 'Maternité', actif: true },
    { id: 'u3', login: 'p.kazadi', nom: 'KAZADI Pierre', qualification: 'Laborantin', roles: 'Laboratoire', actif: true },
    { id: 'u4', login: 't.mbuyi', nom: 'MBUYI Tshibola Thérèse', qualification: 'Pharmacien', roles: 'Pharmacie, Stocks', actif: true },
    { id: 'u5', login: 'a.caissier', nom: 'AMISI Kalonda André', qualification: 'Caissier', roles: 'Caisse', actif: true }
  ]
}
