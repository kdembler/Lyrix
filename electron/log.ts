import winston, { format } from 'winston'

class _Logger {
  private winstonLogger: winston.Logger = winston.createLogger({
    transports: [
      new winston.transports.Console({
        level: 'debug',
      }),
    ],
    format: format.combine(
      format.timestamp(),
      format.printf(({ level, message, timestamp }) => {
        return `${timestamp} ${level} ${message}`
      })
    ),
  })

  info(module: string, message: string) {
    this.winstonLogger.log({
      level: 'info',
      message: `[${module}]: ${message}`,
    })
  }

  debug(module: string, message: string) {
    this.winstonLogger.log({
      level: 'debug',
      message: `[${module}]: ${message}`,
    })
  }
}

export const Logger = new _Logger()
