import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['esm', 'iife'],
  globalName: "etegami",
  dts: true,
  clean: true,
  minify: true,
});
