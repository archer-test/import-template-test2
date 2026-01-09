import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import VisitCounter from './VisitCounter'

// Mock the supabase module
vi.mock('@/lib/supabase', () => ({
  getVisitCount: vi.fn(),
  incrementVisitCount: vi.fn(),
}))

import { getVisitCount, incrementVisitCount } from '@/lib/supabase'

describe('VisitCounter Component', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the visit counter container', () => {
    vi.mocked(getVisitCount).mockResolvedValue({ count: 42, error: null })
    vi.mocked(incrementVisitCount).mockResolvedValue({ count: 43, error: null })

    render(<VisitCounter />)
    const container = screen.getByTestId('visit-counter')
    expect(container).toBeInTheDocument()
  })

  it('displays loading state initially', () => {
    vi.mocked(getVisitCount).mockResolvedValue({ count: 42, error: null })
    vi.mocked(incrementVisitCount).mockResolvedValue({ count: 43, error: null })

    render(<VisitCounter />)
    expect(screen.getByText(/loading/i)).toBeInTheDocument()
  })

  it('displays the visit count after loading', async () => {
    vi.mocked(incrementVisitCount).mockResolvedValue({ count: 100, error: null })

    render(<VisitCounter />)

    const countElement = await screen.findByText(/100/i)
    expect(countElement).toBeInTheDocument()
  })

  it('displays error message when supabase fails', async () => {
    vi.mocked(incrementVisitCount).mockResolvedValue({
      count: null,
      error: 'Connection failed',
    })

    render(<VisitCounter />)

    const errorMessage = await screen.findByText(/unable to load/i)
    expect(errorMessage).toBeInTheDocument()
  })

  it('has accessible styling classes', async () => {
    vi.mocked(incrementVisitCount).mockResolvedValue({ count: 50, error: null })

    render(<VisitCounter />)

    await screen.findByText(/50/i)
    const container = screen.getByTestId('visit-counter')
    expect(container).toHaveClass('visit-counter')
  })
})
