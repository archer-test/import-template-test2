import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import HelloWorld from './HelloWorld'

// Mock VisitCounter to isolate HelloWorld tests
vi.mock('./VisitCounter', () => ({
  default: () => <div data-testid="visit-counter-mock">Mock Counter</div>,
}))

describe('HelloWorld Component', () => {
  it('renders "Hello World" text', () => {
    render(<HelloWorld />)
    expect(screen.getByText('Hello World')).toBeInTheDocument()
  })

  it('displays text in large font', () => {
    render(<HelloWorld />)
    const heading = screen.getByRole('heading', { level: 1 })
    expect(heading).toHaveClass('hello-world-text')
  })

  it('centers the content on the page', () => {
    render(<HelloWorld />)
    const container = screen.getByTestId('hello-world-container')
    expect(container).toHaveClass('hello-world-container')
  })
})
