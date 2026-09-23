import { Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout.jsx'
import { useAuth } from './context/AuthContext.jsx'
import Connexion from './pages/Connexion.jsx'
import TableauDeBord from './pages/TableauDeBord.jsx'
import Accueil from './pages/Accueil.jsx'
import Patients from './pages/Patients.jsx'
import Consultation from './pages/Consultation.jsx'
import Laboratoire from './pages/Laboratoire.jsx'
import Pharmacie from './pages/Pharmacie.jsx'
import Caisse from './pages/Caisse.jsx'
import Maternite from './pages/Maternite.jsx'
import Pev from './pages/Pev.jsx'
import Snis from './pages/Snis.jsx'
import Stock from './pages/Stock.jsx'
import Referentiels from './pages/Referentiels.jsx'
import Administration from './pages/Administration.jsx'
import Synchronisation from './pages/Synchronisation.jsx'

export default function App() {
  const { profil, chargement } = useAuth()

  if (chargement) {
    return <div className="min-h-full grid place-items-center text-ink-3">Ouverture de la session…</div>
  }
  if (!profil) return <Connexion />

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<TableauDeBord />} />
        <Route path="/accueil" element={<Accueil />} />
        <Route path="/patients" element={<Patients />} />
        <Route path="/consultation" element={<Consultation />} />
        <Route path="/laboratoire" element={<Laboratoire />} />
        <Route path="/pharmacie" element={<Pharmacie />} />
        <Route path="/caisse" element={<Caisse />} />
        <Route path="/maternite" element={<Maternite />} />
        <Route path="/pev" element={<Pev />} />
        <Route path="/snis" element={<Snis />} />
        <Route path="/stock" element={<Stock />} />
        <Route path="/referentiels" element={<Referentiels />} />
        <Route path="/administration" element={<Administration />} />
        <Route path="/synchronisation" element={<Synchronisation />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  )
}
