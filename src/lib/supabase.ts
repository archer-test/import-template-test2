import { createClient, SupabaseClient } from '@supabase/supabase-js'

// These values must be provided via environment variables
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase environment variables not configured')
}

export const supabase: SupabaseClient | null =
  supabaseUrl && supabaseAnonKey
    ? createClient(supabaseUrl, supabaseAnonKey)
    : null

export interface VisitCountResult {
  count: number | null
  error: string | null
}

export async function getVisitCount(): Promise<VisitCountResult> {
  if (!supabase) {
    return { count: null, error: 'Supabase not configured' }
  }

  const { data, error } = await supabase
    .from('site_visits')
    .select('visit_count')
    .eq('id', 1)
    .single()

  if (error) {
    return { count: null, error: error.message }
  }

  return { count: data?.visit_count ?? 0, error: null }
}

export async function incrementVisitCount(): Promise<VisitCountResult> {
  if (!supabase) {
    return { count: null, error: 'Supabase not configured' }
  }

  const { data, error } = await supabase.rpc('increment_visit_count')

  if (error) {
    return { count: null, error: error.message }
  }

  return { count: data, error: null }
}
