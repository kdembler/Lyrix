import React, { ButtonHTMLAttributes } from 'react'

export const Button: React.FC<ButtonHTMLAttributes<unknown>> = ({ children, ...props }) => {
  return (
    <button
      type="button"
      {...props}
      className={`inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500${
        props.className ? ` ${props.className}` : ''
      }`}
    >
      {children}
    </button>
  )
}
