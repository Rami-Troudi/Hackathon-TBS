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

        {/* Hydration and Food Reminder */}
        <div className="rounded-lg border border-cyan-200 bg-cyan-50 p-4 space-y-3">
          <div>
            <p className="text-sm font-semibold text-cyan-700 uppercase tracking-wide">Reminder</p>
            <h3 className="text-lg font-semibold text-gray-900 mt-1">Hydration & food</h3>
            <p className="text-sm text-gray-600 mt-2">
              Drink a glass of water and check your next meal so you stay steady during the day.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-3 text-sm">
            <div className="rounded-lg bg-white p-3 ring-1 ring-cyan-100">
              <p className="text-xs font-semibold uppercase tracking-wide text-gray-500">Water</p>
              <p className="mt-1 font-semibold text-gray-900">Next: 3:00 PM</p>
            </div>
            <div className="rounded-lg bg-white p-3 ring-1 ring-cyan-100">
              <p className="text-xs font-semibold uppercase tracking-wide text-gray-500">Meal</p>
              <p className="mt-1 font-semibold text-gray-900">Lunch: 12:30 PM</p>
            </div>
          </div>

          <div className="flex gap-3">
            <button
              onClick={() => alert('Water reminder marked as done')}
              className="flex-1 rounded-lg bg-cyan-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-cyan-700"
            >
              I drank water
            </button>
            <button
              onClick={() => alert('Meal reminder logged')}
              className="flex-1 rounded-lg bg-white px-4 py-3 text-sm font-semibold text-cyan-700 ring-1 ring-cyan-200 transition hover:bg-cyan-50"
            >
              I ate
            </button>
          </div>
        </div>

        {/* Demo Action */}
        <div className="space-y-2">
          <button
            onClick={() => onNavigate('medication')}
            className="w-full text-sm py-2 text-emerald-600 hover:text-emerald-700 font-medium"
          >
            Preview Medication Prompt
          </button>
          <button
            onClick={() => onNavigate('scan-medication')}
            className="w-full text-sm py-2 text-blue-600 hover:text-blue-700 font-medium"
          >
            Scan a Medicament
          </button>
        </div>
      </div>
    </div>
  )
}
