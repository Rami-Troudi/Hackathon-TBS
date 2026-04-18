import React from 'react'
import type { Screen } from '../types'

interface SeniorHomeProps {
  onNavigate: (screen: Screen) => void
}

export default function SeniorHome({ onNavigate }: SeniorHomeProps) {
  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      {/* Header */}
      <div className="bg-gradient-to-r from-emerald-50 to-emerald-100 px-6 py-4">
        <h2 className="text-2xl font-bold text-emerald-900">Today</h2>
      </div>

      <div className="p-6 space-y-6">
        {/* Status Card */}
        <div className="border border-gray-200 rounded-lg p-5 bg-white">
          <div className="flex items-start gap-4">
            <div className="w-3 h-3 rounded-full bg-emerald-500 mt-1 flex-shrink-0"></div>
            <div className="flex-1">
              <h3 className="text-lg font-semibold text-gray-900">All good!</h3>
              <p className="text-sm text-gray-600 mt-2">
                Morning check-in confirmed • Medications on schedule
              </p>
            </div>
          </div>
        </div>

        {/* Primary Actions */}
        <div className="space-y-3">
          <button
            onClick={() => alert('Check-in recorded: I\'m okay')}
            className="w-full bg-emerald-500 hover:bg-emerald-600 text-white font-semibold py-4 rounded-lg transition text-lg"
          >
            I'm okay
          </button>
          <button
            onClick={() => onNavigate('incident')}
            className="w-full bg-red-500 hover:bg-red-600 text-white font-semibold py-4 rounded-lg transition text-lg"
          >
            I need help
          </button>
        </div>

        {/* Next Reminder */}
        <div className="border border-gray-200 rounded-lg p-4 bg-gray-50">
          <p className="font-semibold text-gray-900">Next: Medication • 2:00 PM</p>
          <p className="text-sm text-gray-600 mt-1">Blood pressure medication</p>
        </div>

        {/* Demo Action */}
        <button
          onClick={() => onNavigate('medication')}
          className="w-full text-sm py-2 text-emerald-600 hover:text-emerald-700 font-medium"
        >
          Preview Medication Prompt
        </button>
      </div>
    </div>
  )
}
