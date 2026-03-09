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
    const { id, body, is_pinned = false } = await req.json()

    if (!body) {
      return new Response(
        JSON.stringify({ error: "body is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const now = new Date().toISOString()
    const record = id
      ? { id, contact_id: contactId, body, is_pinned, updated_at: now }
      : { contact_id: contactId, body, is_pinned, created_at: now, updated_at: now }

    const { data, error } = await supabase
      .from("contact_notes")
      .upsert(record, { onConflict: "id" })
      .select()
      .single()

    if (error) throw error

    return new Response(
      JSON.stringify({
        id: data.id,
        contact_id: data.contact_id,
        body: data.body,
        is_pinned: data.is_pinned,
        created_at: data.created_at,
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
