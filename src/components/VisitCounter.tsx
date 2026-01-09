'use client'

import { useEffect, useState } from 'react'
import { incrementVisitCount, VisitCountResult } from '@/lib/supabase'
import './VisitCounter.css'

const VisitCounter = () => {
  const [count, setCount] = useState<number | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchAndIncrement = async () => {
      setLoading(true)
      const result: VisitCountResult = await incrementVisitCount()

      if (result.error) {
        setError(result.error)
      } else {
        setCount(result.count)
      }
      setLoading(false)
    }

    fetchAndIncrement()
  }, [])

  if (loading) {
    return (
      <div className="visit-counter" data-testid="visit-counter">
        <span className="visit-counter-label">Loading visits...</span>
      </div>
    )
  }

  if (error) {
    return (
      <div className="visit-counter" data-testid="visit-counter">
        <span className="visit-counter-error">Unable to load visit count</span>
      </div>
    )
  }

  return (
    <div className="visit-counter" data-testid="visit-counter">
      <span className="visit-counter-label">Total Visits:</span>
      <span className="visit-counter-value">{count}</span>
    </div>
  )
}

export default VisitCounter
