import http from 'node:http';

const groqApiKey = process.env.GROQ_API_KEY;
const groqModel =
  process.env.GROQ_MODEL || 'meta-llama/llama-4-scout-17b-16e-instruct';
const port = Number(process.env.PORT || 8787);

const allowedDenominations = new Set([
  1000,
  2000,
  5000,
  10000,
  20000,
  50000,
  100000,
]);

const server = http.createServer(async (request, response) => {
  if (request.method !== 'POST' || request.url !== '/recognize-currency') {
    sendJson(response, 404, { error: 'Not found' });
    return;
  }

  if (!groqApiKey) {
    sendJson(response, 500, { error: 'GROQ_API_KEY is not configured' });
    return;
  }

  try {
    const body = await readJson(request);
    const imageBase64 = body.imageBase64;
    const mediaType = body.mediaType || 'image/jpeg';

    if (typeof imageBase64 !== 'string' || imageBase64.length === 0) {
      sendJson(response, 400, { error: 'imageBase64 is required' });
      return;
    }

    const result = await recognizeCurrency({ imageBase64, mediaType });
    sendJson(response, 200, result);
  } catch (error) {
    sendJson(response, 500, {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(port, () => {
  console.log(`RUPI-EYE Groq proxy listening on http://localhost:${port}`);
});

function sendJson(response, statusCode, payload) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
  });
  response.end(JSON.stringify(payload));
}

async function readJson(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }

  const raw = Buffer.concat(chunks).toString('utf8');
  return raw.length === 0 ? {} : JSON.parse(raw);
}

async function recognizeCurrency({ imageBase64, mediaType }) {
  const groqResponse = await fetch(
    'https://api.groq.com/openai/v1/chat/completions',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${groqApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: groqModel,
        temperature: 0,
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'system',
            content:
              'You identify Indonesian rupiah banknote denominations. Return JSON only with amount and confidence.',
          },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text:
                  'Identify the rupiah banknote in this image. amount must be one of 1000, 2000, 5000, 10000, 20000, 50000, 100000. confidence must be between 0 and 1.',
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:${mediaType};base64,${imageBase64}`,
                },
              },
            ],
          },
        ],
      }),
    },
  );

  const responseText = await groqResponse.text();

  if (!groqResponse.ok) {
    throw new Error(`Groq API failed (${groqResponse.status}): ${responseText}`);
  }

  const groqJson = JSON.parse(responseText);
  const content = groqJson.choices?.[0]?.message?.content;
  if (typeof content !== 'string') {
    throw new Error('Groq API response did not include message content');
  }

  const parsed = JSON.parse(content);
  const amount = Number(parsed.amount);
  const confidence = parsed.confidence == null ? null : Number(parsed.confidence);

  if (!allowedDenominations.has(amount)) {
    throw new Error(`Invalid rupiah denomination: ${parsed.amount}`);
  }

  return {
    amount,
    confidence,
    model: groqModel,
  };
}
