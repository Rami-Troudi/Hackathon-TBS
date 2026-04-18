import React, { useState } from 'react'
import SeniorHome from './screens/SeniorHome'
import MedicationPrompt from './screens/MedicationPrompt'
import MedicationScan from './screens/MedicationScan'
import PositionTracker from './screens/PositionTracker'
import IncidentConfirmation from './screens/IncidentConfirmation'
import GuardianDashboard from './screens/GuardianDashboard'
import GuardianAlerts from './screens/GuardianAlerts'
import type { Screen } from './types'
type Role = 'senior' | 'guardian'

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('senior-home')
  const [role, setRole] = useState<Role>('senior')

  const showSeniorNav = role === 'senior'
  const showGuardianNav = role === 'guardian'

  const renderScreen = () => {
    switch (currentScreen) {
      case 'senior-home':
        return <SeniorHome onNavigate={setCurrentScreen} />
      case 'medication':
        return <MedicationPrompt onNavigate={setCurrentScreen} />
      case 'scan-medication':
        return <MedicationScan onNavigate={setCurrentScreen} />
      case 'guardian-position':
        return <PositionTracker onNavigate={setCurrentScreen} />
      case 'incident':
        return <IncidentConfirmation onNavigate={setCurrentScreen} />
      case 'dashboard':
        return <GuardianDashboard onNavigate={setCurrentScreen} />
      case 'alerts':
        return <GuardianAlerts onNavigate={setCurrentScreen} />
      default:
        return <SeniorHome onNavigate={setCurrentScreen} />
    }
  }

  return (
    <div className="min-h-screen bg-slate-100 pb-36">
      {/* Top navigation */}
      <div className="sticky top-0 z-10 bg-white/95 backdrop-blur shadow-sm border-b">
        <div className="max-w-2xl mx-auto px-4 py-4 flex items-center justify-between">
          <h1 className="text-2xl font-bold text-emerald-600">Senior Companion</h1>
          <div className="flex gap-4">
            <button
              onClick={() => { setRole('senior'); setCurrentScreen('senior-home') }}
              className={`px-4 py-2 rounded-lg font-medium transition ${
                role === 'senior'
                  ? 'bg-emerald-600 text-white'
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              }`}
            >
              Senior
            </button>
            <button
              onClick={() => { setRole('guardian'); setCurrentScreen('dashboard') }}
              className={`px-4 py-2 rounded-lg font-medium transition ${
                role === 'guardian'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              }`}
            >
              Guardian
            </button>
          </div>
        </div>
      </div>

      {/* Screen container */}
      <div className="flex justify-center px-4 py-8">
        <div className="w-full max-w-md">
          {renderScreen()}
        </div>
      </div>

      {/* Screen selector */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t shadow-lg z-20">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <p className="text-sm font-semibold text-gray-600 mb-3">Quick Navigation:</p>
          {showSeniorNav ? (
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
              <button
                onClick={() => setCurrentScreen('senior-home')}
                className="text-xs py-2 px-3 rounded bg-emerald-100 text-emerald-700 hover:bg-emerald-200"
              >
                S-01 Home
              </button>
              <button
                onClick={() => setCurrentScreen('medication')}
                className="text-xs py-2 px-3 rounded bg-emerald-100 text-emerald-700 hover:bg-emerald-200"
              >
                S-02 Medication
              </button>
              <button
                onClick={() => setCurrentScreen('scan-medication')}
                className="text-xs py-2 px-3 rounded bg-emerald-100 text-emerald-700 hover:bg-emerald-200"
              >
                S-02 Scan
              </button>
              <button
                onClick={() => setCurrentScreen('incident')}
                className="text-xs py-2 px-3 rounded bg-emerald-100 text-emerald-700 hover:bg-emerald-200"
              >
                S-03 Incident
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-3 gap-2">
              <button
                onClick={() => setCurrentScreen('dashboard')}
                className="text-xs py-2 px-3 rounded bg-blue-100 text-blue-700 hover:bg-blue-200"
              >
                G-01 Dashboard
              </button>
              <button
                onClick={() => setCurrentScreen('alerts')}
                className="text-xs py-2 px-3 rounded bg-blue-100 text-blue-700 hover:bg-blue-200"
              >
                G-02 Alerts
              </button>
              <button
                onClick={() => setCurrentScreen('guardian-position')}
                className="text-xs py-2 px-3 rounded bg-blue-100 text-blue-700 hover:bg-blue-200"
              >
                G-03 Position
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
