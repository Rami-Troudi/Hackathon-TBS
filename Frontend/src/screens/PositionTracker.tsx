import React from 'react'
import type { Screen } from '../types'

interface PositionTrackerProps {
  onNavigate: (screen: Screen) => void
}

export default function PositionTracker({ onNavigate }: PositionTrackerProps) {
  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      <div className="bg-gradient-to-r from-cyan-50 to-sky-100 px-6 py-4 border-b border-sky-100">
        <p className="text-sm font-semibold text-sky-700 uppercase tracking-wide">Guardian Tracking</p>
        <h2 className="text-2xl font-bold text-slate-900 mt-1">Track senior position</h2>
        <p className="text-sm text-slate-600 mt-2">
          Follow the senior's live position, confirm safety zones, and react if movement looks unusual.
        </p>
      </div>

      <div className="p-6 space-y-6">
        <div className="rounded-2xl bg-slate-900 p-4 text-white shadow-lg">
          <div className="flex items-center justify-between text-sm text-slate-300">
            <span>Senior live position</span>
            <span className="rounded-full bg-emerald-500/20 px-3 py-1 text-emerald-300">Updated 1 min ago</span>
          </div>

          <div className="mt-4 rounded-2xl bg-gradient-to-br from-sky-500 via-cyan-500 to-emerald-500 p-4">
            <div className="relative h-72 rounded-2xl bg-white/10 backdrop-blur-sm overflow-hidden">
              <div className="absolute inset-0 opacity-20" style={{ backgroundImage: 'radial-gradient(circle at 1px 1px, white 1px, transparent 0)', backgroundSize: '24px 24px' }} />
              <div className="absolute left-6 top-6 rounded-full bg-white px-3 py-1 text-xs font-semibold text-slate-900 shadow-sm">Senior home</div>
              <div className="absolute right-8 top-10 rounded-full bg-emerald-500 px-3 py-1 text-xs font-semibold text-white shadow-sm">Safe zone</div>
              <div className="absolute left-1/2 top-1/2 flex -translate-x-1/2 -translate-y-1/2 items-center justify-center">
                <div className="absolute h-28 w-28 rounded-full border-2 border-white/50" />
                <div className="absolute h-20 w-20 rounded-full border-2 border-white/70" />
                <div className="h-6 w-6 rounded-full border-4 border-white bg-sky-200 shadow-lg" />
              </div>
            </div>
          </div>

          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <div className="rounded-xl bg-white/10 p-4">
              <p className="text-xs uppercase tracking-wide text-slate-500">Current place</p>
              <p className="mt-2 text-sm font-semibold text-white">Living room, apartment 4B</p>
            </div>
            <div className="rounded-xl bg-white/10 p-4">
              <p className="text-xs uppercase tracking-wide text-slate-500">Sharing</p>
              <p className="mt-2 text-sm font-semibold text-white">Shared with family in real time</p>
            </div>
          </div>
        </div>

        <div className="grid gap-3 sm:grid-cols-2">
          <div className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Distance to home</p>
            <p className="mt-2 text-2xl font-bold text-slate-900">42 m</p>
            <p className="mt-1 text-sm text-slate-600">Inside safe area</p>
          </div>
          <div className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Battery / signal</p>
            <p className="mt-2 text-2xl font-bold text-slate-900">Good</p>
            <p className="mt-1 text-sm text-slate-600">Location sharing is active</p>
          </div>
        </div>

        <div className="rounded-2xl border border-cyan-200 bg-cyan-50 p-4">
          <h3 className="text-lg font-semibold text-slate-900">AI guidance</h3>
          <ul className="mt-3 space-y-2 text-sm text-slate-700">
            <li>• The senior is currently within the safe zone.</li>
            <li>• If they leave this area, you can be notified.</li>
            <li>• Use the call button if the position looks concerning.</li>
          </ul>
        </div>

        <div className="space-y-3">
          <button
            onClick={() => alert('Guardian tracking notification sent')}
            className="w-full rounded-lg bg-cyan-600 py-4 text-lg font-semibold text-white transition hover:bg-cyan-700"
          >
            Alert guardian
          </button>
          <button
            onClick={() => onNavigate('dashboard')}
            className="w-full text-sm font-medium text-slate-600 transition hover:text-slate-900"
          >
            Back to Dashboard
          </button>
        </div>
      </div>
    </div>
  )
}