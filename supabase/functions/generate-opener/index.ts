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
    // Extract UUID from path: /generate-opener/contacts/{uuid}/opener/generate
    const contactId = url.pathname.split("/").find(s => /^[0-9a-f-]{36}$/i.test(s))
    const { hint } = await req.json().catch(() => ({ hint: null }))

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Load contact + recent interactions for Claude context
    const [{ data: contact }, { data: recentMessages }, { data: ctx }] = await Promise.all([
      supabase.from("contacts").select("name, role, organization, tier, last_contacted_at").eq("id", contactId).single(),
      supabase.from("contact_messages").select("body, is_from_tony, sent_at").eq("contact_id", contactId).order("sent_at", { ascending: false }).limit(5),
      supabase.from("blaze_context").select("summary, key_facts").eq("contact_id", contactId).maybeSingle(),
    ])

    const claudeApiKey = Deno.env.get("ANTHROPIC_API_KEY")
    if (!claudeApiKey) throw new Error("ANTHROPIC_API_KEY not configured")

    const systemPrompt = `You are Blaze, Tony Robbins' personal AI relationship assistant. 
Generate a short, warm, direct message opener from Tony to ${contact?.name}.
Tony's style: high-energy, genuine, action-oriented, no fluff.
Keep it under 2 sentences. No emojis unless natural. Sound like Tony, not a bot.`

    const userPrompt = `Contact: ${contact?.name} (${contact?.role} at ${contact?.organization})
Relationship tier: ${contact?.tier}
${ctx?.summary ? `Context: ${ctx.summary}` : ""}
${ctx?.key_facts?.length ? `Key facts: ${ctx.key_facts.join(", ")}` : ""}
${hint ? `Hint from Tony: ${hint}` : ""}
Recent messages: ${recentMessages?.slice(0, 3).map((m: { is_from_tony: boolean; body: string }) => `${m.is_from_tony ? "Tony" : contact?.name}: ${m.body}`).join(" | ") ?? "None yet"}

Generate the opener.`

    const claudeRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": claudeApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-3-5-haiku-20241022",
        max_tokens: 150,
        system: systemPrompt,
        messages: [{ role: "user", content: userPrompt }],
      }),
    })

    const claudeData = await claudeRes.json()
    const opener = claudeData.content?.[0]?.text?.trim() ?? `Hey ${contact?.name?.split(" ")[0]} — been thinking about you. What are you working through right now?`

    // Cache in blaze_context
    await supabase.from("blaze_context").upsert({
      contact_id: contactId,
      suggested_opener: opener,
      updated_at: new Date().toISOString(),
    }, { onConflict: "contact_id" })

    return new Response(
      JSON.stringify({ opener, generated_at: new Date().toISOString() }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
