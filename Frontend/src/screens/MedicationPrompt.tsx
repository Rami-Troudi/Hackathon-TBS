import React from 'react'
import type { Screen } from '../types'

interface MedicationPromptProps {
  onNavigate: (screen: Screen) => void
}

export default function MedicationPrompt({ onNavigate }: MedicationPromptProps) {
  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      {/* Header */}
      <div className="bg-gradient-to-r from-emerald-50 to-emerald-100 px-6 py-4">
        <h2 className="text-xl font-bold text-emerald-900">Medication Time</h2>
      </div>

      <div className="p-6 space-y-6">
        {/* Medication Card */}
        <div className="bg-gray-50 rounded-lg p-6 border border-gray-200">
          <h3 className="text-2xl font-bold text-gray-900">Atorvastatin 20mg</h3>
          <p className="text-gray-600 mt-2">Cholesterol management</p>
          <p className="text-sm text-gray-500 mt-4">2:30 PM today</p>
        </div>

        {/* Actions */}
        <div className="space-y-3">
          <button
            onClick={() => alert('Medication marked as taken')}
            className="w-full bg-emerald-500 hover:bg-emerald-600 text-white font-semibold py-4 rounded-lg transition text-lg"
          >
            Taken
          </button>
          <button
            onClick={() => alert('Medication skipped')}
            className="w-full bg-gray-400 hover:bg-gray-500 text-white font-semibold py-4 rounded-lg transition text-lg"
          >
            Skip
          </button>
        </div>

        {/* Read Aloud Info */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-center">
          <p className="text-sm text-blue-700">
            🔊 Read aloud available for accessibility
          </p>
        </div>

        {/* Back Button */}
        <button
          onClick={() => onNavigate('senior-home')}
          className="w-full text-sm py-2 text-gray-600 hover:text-gray-700 font-medium"
        >
          Back to Home
        </button>
      </div>
    </div>
  )
}
