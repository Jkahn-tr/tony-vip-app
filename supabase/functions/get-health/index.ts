import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

// Tier decay rates (λ) — confirmed by Bartok
const TIER_LAMBDA: Record<string, number> = {
  "Inner Circle": 0.02,
  "VIP": 0.04,
  "Key Contact": 0.07,
}

// Interaction weights
const CHANNEL_WEIGHTS: Record<string, number> = {
  in_person: 1.0,
  call: 0.9,   // assume >15min
  text: 0.4,
  blaze: 0.4,
  email: 0.3,
  reaction: 0.1,
}

function computeScore(daysSince: number, tier: string, lastChannel: string, initiatedByTony: boolean): number {
  const lambda = TIER_LAMBDA[tier] ?? 0.04
  const weight = CHANNEL_WEIGHTS[lastChannel] ?? 0.4
  const initiatedMultiplier = initiatedByTony ? 1.5 : 1.0
  return Math.min(1.0, weight * initiatedMultiplier * Math.exp(-lambda * daysSince))
}

function scoreToHealth(score: number): string {
  if (score >= 0.75) return "Strong"
  if (score >= 0.50) return "Good"
  if (score >= 0.25) return "Fading"
  return "Cold"
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })

  try {
    const url = new URL(req.url)
    const contactId = url.pathname.split("/").at(-2) // /contacts/{id}/health

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Get contact + latest interaction
    const [{ data: contact }, { data: lastInteraction }] = await Promise.all([
      supabase.from("contacts").select("tier, last_contacted_at").eq("id", contactId).single(),
      supabase.from("interaction_log")
        .select("channel, initiated_by, occurred_at")
        .eq("contact_id", contactId)
        .order("occurred_at", { ascending: false })
        .limit(1)
        .maybeSingle(),
    ])

    const now = new Date()
    const lastContact = contact?.last_contacted_at ? new Date(contact.last_contacted_at) : null
    const daysSince = lastContact
      ? Math.floor((now.getTime() - lastContact.getTime()) / 86_400_000)
      : 999

    const tier = contact?.tier ?? "Key Contact"
    const lastChannel = lastInteraction?.channel ?? "text"
    const initiatedByTony = lastInteraction?.initiated_by === "tony"

    const score = computeScore(daysSince, tier, lastChannel, initiatedByTony)
    const health = scoreToHealth(score)
    const alertThreshold = score < 0.5

    // Persist updated health
    await supabase.from("relationship_health").upsert({
      contact_id: contactId,
      health,
      score,
      days_since_contact: daysSince,
      alert_threshold_reached: alertThreshold,
      updated_at: now.toISOString(),
    }, { onConflict: "contact_id" })

    return new Response(
      JSON.stringify({
        contact_id: contactId,
        health,
        score: Math.round(score * 1000) / 1000,
        days_since_contact: daysSince,
        last_interaction_at: lastInteraction?.occurred_at ?? null,
        last_interaction_channel: lastChannel,
        alert_threshold_reached: alertThreshold,
        updated_at: now.toISOString(),
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
