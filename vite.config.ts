import reactRefresh from '@vitejs/plugin-react-refresh'
import { UserConfig, ConfigEnv } from 'vite'
import { join } from 'path'
import svgrPlugin from 'vite-plugin-svgr'
import checker from 'vite-plugin-checker'

const srcRoot = join(__dirname, 'src')

export default ({ command }: ConfigEnv): UserConfig => {
  const isDev = command === 'serve'
  return {
    base: isDev ? '/' : `${__dirname}/src/out/`,
    plugins: [
      reactRefresh(),
      svgrPlugin(),
      checker({
        typescript: true,
        overlay: false,
      }),
    ],
    resolve: {
      alias: {
        '/@': srcRoot,
      },
    },
    build: {
      outDir: join(srcRoot, '/out'),
      emptyOutDir: true,
      rollupOptions: {},
    },
    server: {
      port: process.env.PORT === undefined ? 3000 : +process.env.PORT,
    },
    optimizeDeps: {
      exclude: ['path'],
    },
  }
}
