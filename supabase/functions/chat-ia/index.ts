/**
 * OPCIÓN A — Edge Function de Supabase
 * Archivo: supabase/functions/chat-ia/index.ts
 *
 * CÓMO DESPLEGAR:
 *   1. supabase functions new chat-ia
 *   2. Copia este archivo en supabase/functions/chat-ia/index.ts
 *   3. Configura el secreto:
 *        supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
 *   4. Despliega:
 *        supabase functions deploy chat-ia --no-verify-jwt
 *      (usa --no-verify-jwt solo en desarrollo; en producción valida el JWT de Supabase)
 *
 * ENDPOINT RESULTANTE:
 *   POST https://<PROJECT_REF>.supabase.co/functions/v1/chat-ia
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// ── Tipos ────────────────────────────────────────────────────────────────────

interface CuerpoSolicitud {
  /** Mensaje que el usuario envía al chatbot */
  mensaje: string;
  /** Historial de mensajes previos para mantener contexto de la conversación */
  historial?: MensajeHistorial[];
  /** Contexto financiero opcional: balance, transacciones, presupuestos */
  contextoFinanciero?: ContextoFinanciero;
}

interface MensajeHistorial {
  rol: "user" | "assistant";
  contenido: string;
}

interface ContextoFinanciero {
  balanceActual?: number;
  moneda?: string;
  ultimasTransacciones?: TransaccionResumen[];
  presupuestosMensuales?: PresupuestoResumen[];
}

interface TransaccionResumen {
  categoria: string;
  monto: number;
  esIngreso: boolean;
  fecha: string;
}

interface PresupuestoResumen {
  categoria: string;
  montoEsperado: number;
  montoReal?: number;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Construye el system prompt con o sin contexto financiero */
function construirSystemPrompt(ctx?: ContextoFinanciero): string {
  const base = `Eres un asesor financiero personal inteligente, empático y directo.
Respondes en español (México), con tono profesional pero accesible.
Das consejos prácticos, concisos y accionables sobre finanzas personales.
Cuando el usuario comparte sus datos financieros, los analizas de forma proactiva y señalas 
oportunidades de mejora, alertas o patrones relevantes.
Si no tienes datos del usuario, das consejos generales de buenas prácticas financieras.
Nunca inventas cifras ni haces promesas de rendimiento.`;

  if (!ctx) return base;

  const lineas: string[] = [
    base,
    "",
    "=== DATOS FINANCIEROS DEL USUARIO (MES ACTUAL) ===",
  ];

  if (ctx.balanceActual !== undefined) {
    const moneda = ctx.moneda ?? "MXN";
    lineas.push(`Balance disponible: $${ctx.balanceActual.toFixed(2)} ${moneda}`);
  }

  if (ctx.presupuestosMensuales?.length) {
    lineas.push("\nPresupuestos vs. Gasto Real:");
    for (const p of ctx.presupuestosMensuales) {
      const real = p.montoReal !== undefined ? `$${p.montoReal.toFixed(2)}` : "sin dato";
      lineas.push(`  • ${p.categoria}: presupuesto $${p.montoEsperado.toFixed(2)} | real ${real}`);
    }
  }

  if (ctx.ultimasTransacciones?.length) {
    lineas.push("\nÚltimas transacciones:");
    const ultimas = ctx.ultimasTransacciones.slice(0, 10); // máximo 10
    for (const t of ultimas) {
      const tipo = t.esIngreso ? "Ingreso" : "Gasto";
      lineas.push(`  • [${t.fecha}] ${tipo} — ${t.categoria}: $${t.monto.toFixed(2)}`);
    }
  }

  lineas.push("===================================================");
  return lineas.join("\n");
}

/** Cabeceras CORS para desarrollo local */
const cabecerasCORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ── Handler principal ─────────────────────────────────────────────────────────

serve(async (req: Request) => {
  // Preflight CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cabecerasCORS });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método no permitido" }), {
      status: 405,
      headers: { ...cabecerasCORS, "Content-Type": "application/json" },
    });
  }

  try {
    // 1. Leer y validar cuerpo
    const cuerpo: CuerpoSolicitud = await req.json();

    if (!cuerpo.mensaje || typeof cuerpo.mensaje !== "string" || !cuerpo.mensaje.trim()) {
      return new Response(JSON.stringify({ error: "El campo 'mensaje' es requerido" }), {
        status: 400,
        headers: { ...cabecerasCORS, "Content-Type": "application/json" },
      });
    }

    // 2. Obtener la API Key desde variables de entorno (NUNCA expuesta al cliente)
    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) {
      console.error("ANTHROPIC_API_KEY no configurada en los secretos de Supabase");
      return new Response(JSON.stringify({ error: "Configuración del servidor incompleta" }), {
        status: 500,
        headers: { ...cabecerasCORS, "Content-Type": "application/json" },
      });
    }

    // 3. Construir historial de mensajes para la API
    const mensajes = [
      ...(cuerpo.historial ?? []).map((m) => ({
        role: m.rol,
        content: m.contenido,
      })),
      { role: "user", content: cuerpo.mensaje.trim() },
    ];

    // 4. Llamar a la API de Anthropic
    const respuestaAnthropic = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 1024,
        system: construirSystemPrompt(cuerpo.contextoFinanciero),
        messages: mensajes,
      }),
    });

    if (!respuestaAnthropic.ok) {
      const errorTexto = await respuestaAnthropic.text();
      console.error("Error de Anthropic:", errorTexto);
      return new Response(
        JSON.stringify({ error: "Error al contactar al modelo de IA" }),
        {
          status: 502,
          headers: { ...cabecerasCORS, "Content-Type": "application/json" },
        }
      );
    }

    const datosAnthropic = await respuestaAnthropic.json();
    const textoRespuesta: string = datosAnthropic.content?.[0]?.text ?? "";

    // 5. Devolver respuesta al cliente Flutter
    return new Response(
      JSON.stringify({ respuesta: textoRespuesta }),
      {
        status: 200,
        headers: { ...cabecerasCORS, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("Error inesperado en chat-ia:", err);
    return new Response(
      JSON.stringify({ error: "Error interno del servidor" }),
      {
        status: 500,
        headers: { ...cabecerasCORS, "Content-Type": "application/json" },
      }
    );
  }
});
