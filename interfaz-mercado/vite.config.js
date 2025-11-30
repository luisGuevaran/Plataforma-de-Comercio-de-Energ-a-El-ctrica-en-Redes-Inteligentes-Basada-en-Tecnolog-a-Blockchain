import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    // Esto permite que el túnel de Pinggy/Ngrok acceda a la web
    allowedHosts: true
  }
})