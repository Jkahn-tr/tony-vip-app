import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })

  try {
    const url = new URL(req.url)
    const contactId = url.pathname.split("/").find(s => /^[0-9a-f-]{36}$/i.test(s))

    if (!contactId) {
      return new Response(
        JSON.stringify({ error: "contact_id required in path" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Fetch stored context
    const { data: ctx, error } = await supabase
      .from("blaze_context")
      .select("*")
      .eq("contact_id", contactId)
      .maybeSingle()

    if (error) throw error

    if (!ctx) {
      // No context yet — generate a stub (Claude integration in V2)
      const { data: contact } = await supabase
        .from("contacts")
        .select("name, role, organization, last_contacted_at")
        .eq("id", contactId)
        .single()

      const now = new Date().toISOString()
      return new Response(
        JSON.stringify({
          summary: `No Blaze context yet for ${contact?.name ?? "this contact"}. Context will be generated after the first interaction.`,
          suggested_opener: null,
          key_facts: [],
          last_updated: now,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    return new Response(
      JSON.stringify({
        summary: ctx.summary,
        suggested_opener: ctx.suggested_opener,
        key_facts: ctx.key_facts ?? [],
        last_updated: ctx.updated_at,
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
