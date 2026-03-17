const html = `<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Survey</title>
  <style>
    body { font-family: sans-serif; max-width: 480px; margin: 80px auto; padding: 0 16px; }
    h1 { margin-bottom: 16px; }
    textarea { width: 100%; height: 120px; box-sizing: border-box; margin-bottom: 12px; }
    button { padding: 8px 24px; cursor: pointer; }
    #msg { margin-top: 12px; color: green; }
  </style>
</head>
<body>
  <h1>Wpisz cos</h1>
  <textarea id="text" placeholder="Wpisz tutaj..."></textarea>
  <button onclick="send()">Zapisz</button>
  <div id="token"></div>
  <div id="msg"></div>
  <script>
    const params = new URLSearchParams(window.location.search);
    const userToken = params.get('user_token') || '';
    const redirectionUrl = params.get('redirection_url') || '';
    const eventId = params.get('event_id') || '';
    document.getElementById('token').textContent = 'user_token: ' + userToken + ' | redirection_url: ' + redirectionUrl + ' | event_id: ' + eventId;
  </script>
  <script>
    async function send() {
      const text = document.getElementById('text').value;
      const res = await fetch('/survey', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text }),
      });
      const data = await res.json();
      if (data.status === 'ok') {
        window.location.href = \`\${redirectionUrl}/events/\${eventId}?user_token=\${encodeURIComponent(userToken)}\`;
      } else {
        document.getElementById('msg').textContent = 'Blad';
      }
    }
  </script>
</body>
</html>`;

const corsHeaders = {
  "Access-Control-Allow-Origin": "http://localhost:4000",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

const server = Bun.serve({
  port: 4001,
  fetch(req) {
    const url = new URL(req.url);

    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (url.pathname === "/status") {
      return Response.json({
        version: "0.0.1",
        date: new Date().toISOString(),
      }, { headers: corsHeaders });
    }

    if (url.pathname === "/view_survey") {
      return new Response(html, { headers: { "Content-Type": "text/html" } });
    }

    if (url.pathname === "/survey" && req.method === "POST") {
      return Response.json({ status: "ok" }, { headers: corsHeaders });
    }

    if (url.pathname === "/survey") {
      return Response.json({
        url: "http://localhost:4001/view_survey",
      }, { headers: corsHeaders });
    }

    return new Response("Not Found", { status: 404 });
  },
});

console.log(`Server running at http://localhost:${server.port}`);
