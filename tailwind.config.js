/** Jetons de design repris des maquettes validées (vert médical, lisibilité
 *  sur écrans d'entrée de gamme, contrastes conformes AA). */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        bg: '#f1f4f6',
        surface: { DEFAULT: '#ffffff', 2: '#f7f9fa' },
        line: '#dde4e8',
        ink: { DEFAULT: '#152029', 2: '#4a5c69', 3: '#7b8b97' },
        primary: { DEFAULT: '#0f6b5c', dark: '#0a4d42', soft: '#e3f2ee' },
        accent: { DEFAULT: '#1a5f8f', soft: '#e6f0f8' },
        warn: { DEFAULT: '#9a5b00', soft: '#fdf1dd' },
        danger: { DEFAULT: '#a52222', soft: '#fbe9e9' },
        ok: { DEFAULT: '#1d6b32', soft: '#e6f4ea' },
        night: '#0c1a21'
      },
      fontFamily: {
        sans: ['Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial', 'sans-serif']
      },
      borderRadius: { card: '10px', sm2: '6px' },
      boxShadow: {
        card: '0 1px 2px rgba(21,32,41,.06), 0 1px 8px rgba(21,32,41,.05)'
      },
      fontSize: { '13': '13px', '13.5': '13.5px', '14.5': '14.5px' }
    }
  },
  plugins: []
}
