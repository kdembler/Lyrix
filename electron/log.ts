import winston, { format } from 'winston'

type DoLogFn = (level: string, scope: string, msg: string, meta?: unknown) => void
type LogFn = (scope: string, msg: string, meta?: unknown) => void
type ScopedLogFn = (msg: string, meta?: unknown) => void

class _Logger {
  private winstonLogger: winston.Logger = winston.createLogger({
    transports: [
      new winston.transports.Console({
        level: 'debug',
      }),
    ],
    format: format.combine(
      format.timestamp(),
      format.colorize(),
      format.printf(({ level, message, timestamp }) => {
        return `${timestamp} ${level} ${message}`
      }),
      format.metadata({ fillExcept: ['timestamp'] })
      // format.prettyPrint()
    ),
    exitOnError: false,
  })

  info: LogFn = (...args) => this.doLog('info', ...args)
  debug: LogFn = (...args) => this.doLog('debug', ...args)
  warn: LogFn = (...args) => this.doLog('warn', ...args)
  error: LogFn = (...args) => this.doLog('error', ...args)

  private doLog: DoLogFn = (level, scope, msg, meta) => {
    try {
      this.winstonLogger.log(level, `[${scope}]: ${msg}`, meta)
    } catch (e) {
      this.error('Logger', 'Failed to do logging')
    }
  }
}

export const Logger = new _Logger()

export const createScopedLogger = (module: string) => {
  return {
    debug: ((...args) => Logger.debug(module, ...args)) as ScopedLogFn,
    info: ((...args) => Logger.info(module, ...args)) as ScopedLogFn,
    warn: ((...args) => Logger.warn(module, ...args)) as ScopedLogFn,
    error: ((...args) => Logger.error(module, ...args)) as ScopedLogFn,
  }
}
