import React, { ButtonHTMLAttributes } from 'react'
import classNames from 'classnames'

type ButtonProps = {
  variant?: 'primary' | 'default'
} & ButtonHTMLAttributes<unknown>

export const Button: React.FC<ButtonProps> = ({ variant = 'default', children, ...props }) => {
  return (
    <button
      type="button"
      {...props}
      className={classNames(
        'inline-flex uppercase transition-colors font-semibold rounded',
        variant === 'default' && 'bg-green-200 hover:bg-green-300 px-2 py-1 font-semibold text-xs',
        variant === 'primary' && 'bg-green-500 hover:bg-green-600 text-white px-3 py-2 font-bold text-xs',
        props.className
      )}
    >
      {children}
    </button>
  )
}
