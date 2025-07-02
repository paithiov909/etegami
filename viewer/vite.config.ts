import { defineConfig } from 'vite'
import path from 'path'

export default defineConfig({
  publicDir: false,
  worker: {
    format: 'es',
  },
  resolve: {
    alias: {
      etegami: path.resolve(__dirname, '../srcjs/src'),
    },
  },
})
