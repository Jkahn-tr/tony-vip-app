import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const { contact_id, body, channel = "blaze" } = await req.json()

    if (!contact_id || !body) {
      return new Response(
        JSON.stringify({ error: "contact_id and body are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Insert message
    const { data, error } = await supabase
      .from("contact_messages")
      .insert({
        contact_id,
        body,
        is_from_tony: true,
        channel,
        is_read: true,
        sent_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (error) throw error

    // Update contact last_contacted_at
    await supabase
      .from("contacts")
      .update({ last_contacted_at: new Date().toISOString(), updated_at: new Date().toISOString() })
      .eq("id", contact_id)

    // Log to interaction_log
    await supabase.from("interaction_log").insert({
      contact_id,
      channel: channel === "blaze" ? "text" : channel,
      initiated_by: "tony",
      occurred_at: new Date().toISOString(),
    })

    return new Response(
      JSON.stringify({
        id: data.id,
        contact_id: data.contact_id,
        body: data.body,
        is_from_tony: data.is_from_tony,
        sent_at: data.sent_at,
        channel: data.channel,
        is_read: data.is_read,
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
