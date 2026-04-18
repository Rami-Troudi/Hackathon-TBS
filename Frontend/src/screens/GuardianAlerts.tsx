import React from 'react'
import type { Screen } from '../types'

interface GuardianAlertsProps {
  onNavigate: (screen: Screen) => void
}

export default function GuardianAlerts({ onNavigate }: GuardianAlertsProps) {
  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-50 to-blue-100 px-6 py-4">
        <h2 className="text-2xl font-bold text-blue-900">Alerts</h2>
      </div>

      <div className="p-6 space-y-6">
        {/* Critical Alert */}
        <div className="border-2 border-red-500 rounded-lg p-4 bg-white">
          <p className="font-bold text-red-600 text-sm">🔴 CRITICAL</p>
          <h3 className="text-lg font-bold text-gray-900 mt-2">Possible fall detected</h3>
          <p className="text-sm text-gray-600 mt-2">Senior not responding • 2:45 PM</p>
          <div className="mt-4 space-y-2">
            <button
              onClick={() => alert('Escalating to emergency contacts...')}
              className="w-full bg-red-600 hover:bg-red-700 text-white text-sm font-semibold py-2 rounded transition"
            >
              Escalate Now
            </button>
          </div>
        </div>

        {/* Warning Alert */}
        <div className="border-2 border-yellow-400 rounded-lg p-4 bg-white">
          <p className="font-bold text-yellow-600 text-sm">⚠️ WARNING</p>
          <h3 className="text-lg font-bold text-gray-900 mt-2">Medication overdue</h3>
          <p className="text-sm text-gray-600 mt-2">Blood pressure med due 1 hour ago</p>
          <div className="mt-4 space-y-2">
            <button
              onClick={() => alert('Sending reminder to senior...')}
              className="w-full bg-yellow-400 hover:bg-yellow-500 text-gray-900 text-sm font-semibold py-2 rounded transition"
            >
              Send Reminder
            </button>
          </div>
        </div>

        {/* Info Alert */}
        <div className="border-2 border-blue-300 rounded-lg p-4 bg-blue-50">
          <p className="font-bold text-blue-600 text-sm">ℹ️ INFO</p>
          <h3 className="text-lg font-bold text-gray-900 mt-2">Evening check-in pending</h3>
          <p className="text-sm text-gray-600 mt-2">Last check-in was 8 hours ago</p>
          <button
            onClick={() => alert('Notification sent')}
            className="w-full mt-4 bg-blue-200 hover:bg-blue-300 text-blue-900 text-sm font-semibold py-2 rounded transition"
          >
            Send Check-In Prompt
          </button>
        </div>

        {/* Alert Settings */}
        <div className="bg-gray-50 rounded-lg p-4 text-center">
          <p className="text-sm text-gray-600 mb-3">Showing 3 active alerts</p>
          <button
            onClick={() => onNavigate('dashboard')}
            className="text-sm text-blue-600 hover:text-blue-700 font-medium"
          >
            Back to Dashboard
          </button>
        </div>
      </div>
    </div>
  )
}
