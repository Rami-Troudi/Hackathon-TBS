import React from 'react'
import type { Screen } from '../types'

interface GuardianDashboardProps {
  onNavigate: (screen: Screen) => void
}

export default function GuardianDashboard({ onNavigate }: GuardianDashboardProps) {
  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-50 to-blue-100 px-6 py-4">
        <h2 className="text-2xl font-bold text-blue-900">Dashboard</h2>
      </div>

      <div className="p-6 space-y-6">
        {/* Status Chip */}
        <div className="flex items-center gap-3">
          <div className="bg-yellow-400 text-gray-900 font-bold text-sm px-4 py-2 rounded-full">
            WATCH
          </div>
          <p className="text-sm text-gray-600">Missed check-in • Delayed medication</p>
        </div>

        {/* Active Alerts Card */}
        <div className="border border-gray-200 rounded-lg overflow-hidden">
          <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
            <h3 className="font-semibold text-gray-900">Active Alerts</h3>
          </div>
          <div className="p-4">
            <div className="bg-gray-50 rounded p-3">
              <p className="font-medium text-gray-900">⚠️ Missed morning check-in</p>
              <p className="text-sm text-gray-600 mt-1">Last seen: 8:15 AM</p>
            </div>
          </div>
        </div>

        {/* Status Timeline */}
        <div className="border border-gray-200 rounded-lg p-4 bg-gray-50">
          <h4 className="font-semibold text-gray-900 mb-3">Recent Activity</h4>
          <div className="space-y-3 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">Morning check-in</span>
              <span className="text-gray-900 font-medium">✓ 9:00 AM</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Medication confirmed</span>
              <span className="text-gray-900 font-medium">✓ 2:30 PM</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Evening check-in</span>
              <span className="text-red-600 font-medium">✗ Not confirmed</span>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="space-y-3">
          <button
            onClick={() => alert('Calling senior...')}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 rounded-lg transition"
          >
            📞 Call Senior
          </button>
          <button
            onClick={() => onNavigate('alerts')}
            className="w-full bg-gray-200 hover:bg-gray-300 text-gray-900 font-semibold py-3 rounded-lg transition"
          >
            View All Alerts
          </button>
        </div>
      </div>
    </div>
  )
}
