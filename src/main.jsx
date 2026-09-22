import React from 'react'
import ReactDOM from 'react-dom/client'
// Navigation par ancre : indépendante de la configuration du serveur web,
// elle évite toute réécriture d'URL et fonctionne aussi en sous-répertoire.
import { HashRouter } from 'react-router-dom'
import App from './App.jsx'
import { AuthProvider } from './context/AuthContext.jsx'
import { OfflineProvider } from './context/OfflineContext.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <HashRouter>
      <OfflineProvider>
        <AuthProvider>
          <App />
        </AuthProvider>
      </OfflineProvider>
    </HashRouter>
  </React.StrictMode>
)
