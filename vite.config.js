import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

// Application installable et utilisable hors ligne (EF-M26-01, ENF-O01) :
// la coque applicative est mise en cache, les données passent par la file
// locale gérée dans src/lib/offline.js.
export default defineConfig({
  // Chemins relatifs : l'application fonctionne à la racine d'un domaine
  // comme dans un sous-répertoire (intranet du centre, clé USB, aperçu).
  base: './',
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg', 'icone-192.png', 'icone-512.png'],
      manifest: {
        name: 'Gestion Centre de Santé',
        short_name: 'CS Santé',
        description: "Gestion complète d'un centre de santé : patients, consultations, pharmacie, caisse, SNIS",
        lang: 'fr',
        dir: 'ltr',
        start_url: './',
        scope: './',
        display: 'standalone',
        orientation: 'any',
        background_color: '#f1f4f6',
        theme_color: '#0f6b5c',
        icons: [
          { src: 'icone-192.png', sizes: '192x192', type: 'image/png' },
          { src: 'icone-512.png', sizes: '512x512', type: 'image/png' },
          { src: 'icone-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' }
        ]
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,svg,png,woff2}'],
        navigateFallback: 'index.html',
        runtimeCaching: [
          {
            // Référentiels : lecture tolérante au réseau absent
            urlPattern: /\/rest\/v1\/(produit|acte|diagnostic_ref|examen_ref|antigene|tarif)/,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'referentiels',
              expiration: { maxEntries: 200, maxAgeSeconds: 60 * 60 * 24 * 30 },
              networkTimeoutSeconds: 4
            }
          },
          {
            urlPattern: /\/rest\/v1\/rpc\//,
            handler: 'NetworkOnly'
          }
        ]
      },
      devOptions: { enabled: false }
    })
  ],
  server: { port: 5173, host: true },
  build: { outDir: 'dist', sourcemap: false, target: 'es2020' }
})
