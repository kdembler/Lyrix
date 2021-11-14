import React, { ButtonHTMLAttributes } from 'react'
import classNames from 'classnames'

export const IconButton: React.FC<ButtonHTMLAttributes<unknown>> = ({ children, className, ...rest }) => {
  // TODO: add tooltip with action description
  return (
    <button
      className={classNames(
        'inline-flex rounded-full p-2 text-green-900 hover:bg-green-100 transition-colors cursor-pointer',
        className
      )}
      {...rest}
    >
      {children}
    </button>
  )
}
