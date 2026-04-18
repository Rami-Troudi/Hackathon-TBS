import React, { useState, useEffect } from 'react'
import type { Screen } from '../types'

interface IncidentConfirmationProps {
  onNavigate: (screen: Screen) => void
}

export default function IncidentConfirmation({ onNavigate }: IncidentConfirmationProps) {
  const [countdown, setCountdown] = useState(30)

  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000)
      return () => clearTimeout(timer)
    }
  }, [countdown])

  const handleConfirm = () => {
    alert('Confirmed: You\'re okay. Alert cancelled.')
    onNavigate('senior-home')
  }

  const handleNeedHelp = () => {
    alert('ALERT: Guardian will be notified immediately!')
    onNavigate('senior-home')
  }

  return (
    <div className="bg-red-500 rounded-lg shadow-md overflow-hidden min-h-screen flex flex-col">
      {/* Header */}
      <div className="px-6 py-8 text-center text-white flex-1 flex flex-col justify-center">
        <h2 className="text-3xl font-bold mb-4">Are you okay?</h2>
        <p className="text-lg text-red-100 mb-12">Unusual activity detected</p>

        {/* Countdown */}
        <div className="mb-8">
          <div className="text-7xl font-bold text-white mb-4">{countdown}</div>
          <p className="text-sm text-red-100">seconds until we contact someone</p>
        </div>
      </div>

      {/* Actions */}
      <div className="px-6 pb-6 space-y-3">
        <button
          onClick={handleConfirm}
          className="w-full bg-emerald-500 hover:bg-emerald-600 text-white font-semibold py-4 rounded-lg transition text-lg"
        >
          Yes, I'm okay
        </button>
        <button
          onClick={handleNeedHelp}
          className="w-full bg-white hover:bg-gray-100 text-red-600 font-semibold py-4 rounded-lg transition text-lg"
        >
          I need help now
        </button>
      </div>
    </div>
  )
}
