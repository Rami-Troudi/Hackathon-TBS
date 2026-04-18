import React, { useState } from 'react'
import type { Screen } from '../types'

interface MedicationScanProps {
  onNavigate: (screen: Screen) => void
}

export default function MedicationScan({ onNavigate }: MedicationScanProps) {
  const [scanned, setScanned] = useState(false)

  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      <div className="bg-gradient-to-r from-sky-50 to-blue-100 px-6 py-4 border-b border-blue-100">
        <p className="text-sm font-semibold text-blue-700 uppercase tracking-wide">Senior Assistant</p>
        <h2 className="text-2xl font-bold text-slate-900 mt-1">Scan a medicament</h2>
        <p className="text-sm text-slate-600 mt-2">
          Point the camera at any medicine box or blister pack and I will help you understand it.
        </p>
      </div>

      <div className="p-6 space-y-6">
        <div className="rounded-2xl border-2 border-dashed border-sky-300 bg-sky-50 p-5 text-center">
          <div className="mx-auto mb-4 flex h-20 w-20 items-center justify-center rounded-full bg-white shadow-sm">
            <span className="text-3xl">📷</span>
          </div>
          <h3 className="text-lg font-semibold text-slate-900">Camera scanner</h3>
          <p className="mt-2 text-sm text-slate-600">
            Hold the medicine near the camera so the label and dosage are visible.
          </p>
          <div className="mt-5 flex items-center justify-center gap-3">
            <button
              onClick={() => setScanned(true)}
              className="rounded-lg bg-sky-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-sky-700"
            >
              Scan medicine
            </button>
            <button
              onClick={() => setScanned(false)}
              className="rounded-lg bg-white px-4 py-3 text-sm font-semibold text-slate-700 ring-1 ring-slate-200 transition hover:bg-slate-50"
            >
              Reset
            </button>
          </div>
        </div>

        {scanned ? (
          <div className="space-y-4 rounded-2xl border border-emerald-200 bg-emerald-50 p-5">
            <div className="flex items-start gap-3">
              <div className="mt-1 flex h-10 w-10 items-center justify-center rounded-full bg-emerald-600 text-white">
                ✓
              </div>
              <div>
                <p className="text-sm font-semibold text-emerald-700 uppercase tracking-wide">AI identified</p>
                <h3 className="text-xl font-bold text-slate-900">Atorvastatin 20 mg</h3>
                <p className="mt-1 text-sm text-slate-700">Tablet for cholesterol management</p>
              </div>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <div className="rounded-xl bg-white p-4 ring-1 ring-emerald-100">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Recommended use</p>
                <p className="mt-2 text-sm text-slate-900">Take 1 tablet after dinner with water.</p>
              </div>
              <div className="rounded-xl bg-white p-4 ring-1 ring-emerald-100">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Safety note</p>
                <p className="mt-2 text-sm text-slate-900">Do not take twice in the same day unless instructed.</p>
              </div>
            </div>

            <div className="rounded-xl bg-white p-4 ring-1 ring-emerald-100">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">AI guidance</p>
              <ul className="mt-3 space-y-2 text-sm text-slate-700">
                <li>• This looks like a daily maintenance medicine.</li>
                <li>• Keep it with water and avoid alcohol near the dose.</li>
                <li>• If you feel unwell, contact your guardian or doctor.</li>
              </ul>
            </div>

            <div className="space-y-3 pt-1">
              <button
                onClick={() => alert('Medication guidance saved and shared with guardian')}
                className="w-full rounded-lg bg-emerald-600 py-4 text-lg font-semibold text-white transition hover:bg-emerald-700"
              >
                Mark as understood
              </button>
              <button
                onClick={() => alert('Calling guardian for help')}
                className="w-full rounded-lg bg-slate-900 py-4 text-lg font-semibold text-white transition hover:bg-slate-800"
              >
                Ask my guardian
              </button>
            </div>
          </div>
        ) : (
          <div className="rounded-2xl border border-slate-200 bg-slate-50 p-5">
            <h3 className="text-lg font-semibold text-slate-900">What the AI will do</h3>
            <div className="mt-3 space-y-3 text-sm text-slate-700">
              <p>1. Read the medicine name and dose from the package.</p>
              <p>2. Explain what it is for in simple language.</p>
              <p>3. Show how and when to take it safely.</p>
              <p>4. Offer to notify the guardian if anything is unclear.</p>
            </div>
          </div>
        )}

        <button
          onClick={() => onNavigate('senior-home')}
          className="w-full text-sm font-medium text-slate-600 transition hover:text-slate-900"
        >
          Back to Home
        </button>
      </div>
    </div>
  )
}
