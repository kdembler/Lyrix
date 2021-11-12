import React, { ButtonHTMLAttributes } from 'react'
import classNames from 'classnames'

export const IconButton: React.FC<ButtonHTMLAttributes<unknown>> = ({ children, className, ...rest }) => {
  return (
    <button
      className={classNames(
        'inline-flex rounded-full p-2 fill-current text-gray-600 hover:bg-gray-400 transition-colors cursor-pointer',
        className
      )}
      {...rest}
    >
      {children}
    </button>
  )
}
