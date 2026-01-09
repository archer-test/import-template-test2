# import-template-test2

A Hello World application with a global visit counter, built with Next.js and Supabase.

## Live Demo

**Production URL:** https://import-template-test2.vercel.app

## Features

### Hello World Display (Doc 024)
- Large, bold "Hello World" text centered on the page
- Gradient background with professional styling
- Responsive design that adapts to all screen sizes

### Global Visit Counter (Doc 025)
- Tracks total site visits across all users using Supabase PostgreSQL
- Atomic increment operation prevents race conditions
- Real-time count displayed to visitors
- Graceful error handling when backend is unavailable

### Responsive Styling (Doc 026)
- Mobile-first responsive design
- Glassmorphism effect on the visit counter card
- High contrast mode support for accessibility
- Reduced motion support for users with motion sensitivity

## Tech Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Frontend | Next.js 16 + TypeScript | Server-side rendering, TypeScript for type safety, optimal Vercel integration |
| Backend | Supabase | Managed PostgreSQL with built-in RLS, edge functions, and real-time capabilities |
| Database | PostgreSQL (via Supabase) | ACID compliance, atomic operations for visit counter |
| Hosting | Vercel | Seamless Next.js deployment, global CDN, automatic SSL |
| Testing | Vitest + React Testing Library | Fast unit tests, React-specific testing utilities |

## Architecture Decisions

### Visit Counter Implementation
The visit counter uses a PostgreSQL function (`increment_visit_count`) to atomically increment the count. This approach was chosen over client-side increments to:
- Prevent race conditions from concurrent visitors
- Ensure count accuracy across all sessions
- Leverage database-level atomicity guarantees

### Row Level Security (RLS)
Supabase RLS policies allow:
- Anonymous read access to view the current count
- Anonymous update access for incrementing the counter
- No direct INSERT/DELETE to maintain data integrity

### Test-Driven Development
All components were developed following TDD principles:
1. Tests written first (failing)
2. Minimal implementation to pass tests
3. Refactoring while maintaining green tests

## Project Structure

```
src/
├── app/
│   ├── layout.tsx      # Root layout with metadata
│   ├── page.tsx        # Home page
│   └── globals.css     # Global styles
├── components/
│   ├── HelloWorld.tsx  # Main display component
│   ├── HelloWorld.css  # HelloWorld styles
│   ├── HelloWorld.test.tsx
│   ├── VisitCounter.tsx # Visit counter component
│   ├── VisitCounter.css # Visit counter styles
│   └── VisitCounter.test.tsx
├── lib/
│   └── supabase.ts     # Supabase client and utilities
└── test/
    └── setup.ts        # Test configuration

supabase/
└── migrations/
    └── 20240101000000_create_site_visits.sql

scripts/
├── deploy-frontend-vercel.sh
└── deploy-backend-supabase.sh
```

## Development

### Prerequisites
- Node.js 18+
- npm or yarn

### Setup
```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm run test

# Build for production
npm run build
```

### Environment Variables

The following environment variables must be provided:

| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anonymous key |

**Note:** These values must be provided via environment variables. Never commit secrets to the repository.

## Deployment

### Automated Deployment Scripts

```bash
# Deploy backend (Supabase)
./scripts/deploy-backend-supabase.sh

# Deploy frontend (Vercel)
./scripts/deploy-frontend-vercel.sh
```

### Required Environment Variables for Deployment

| Variable | Description |
|----------|-------------|
| `VERCEL_TOKEN` | Vercel API token |
| `SUPABASE_ACCESS_TOKEN` | Supabase management API token |

## Testing

```bash
# Run tests once
npm run test:run

# Run tests in watch mode
npm run test
```

Test coverage includes:
- HelloWorld component rendering and styling
- VisitCounter loading, error, and success states
- Component accessibility attributes

## Security

- No secrets are hardcoded in the codebase
- Environment variables are used for all sensitive configuration
- Supabase RLS policies protect database operations
- HTTPS enforced via Vercel
