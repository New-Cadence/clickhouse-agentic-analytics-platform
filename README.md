Agentic Analytics Platform is a tool for building and testing AI analytics agents on ClickHouse.  Ask questions in plain language and a model writes the SQL, runs it against ClickHouse and shows its reasoning, the queries it issued and the rows that came back, with 92 example scenarios across four industries to try straight away.

By [New Cadence](https://newcadence.io).

## Running

Clone the repository and create your config:

```bash
git clone https://github.com/New-Cadence/clickhouse-agentic-analytics-platform
cd clickhouse-agentic-analytics-platform
cp .env.example .env
```

Edit `.env` with your connection details. `.env.example` targets a ClickHouse running locally on port 8123 over plain HTTP, so it works unedited if that is what you have. For ClickHouse Cloud or any remote instance:

```bash
CLICKHOUSE_URL=https://your-instance.clickhouse.cloud:8443
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=your-password
```

ClickHouse is the only thing the app requires. It refuses to start if `CLICKHOUSE_URL` is unset or malformed, and names what is missing. Model providers are optional at boot and can be added from the admin UI. To reach a ClickHouse on your own machine, use `host.docker.internal` rather than `localhost`: inside the container `localhost` is the container itself. Use `localhost` only when running outside Docker.

<details>
<summary><strong>Connecting to a ClickHouse on your own machine (Linux)</strong></summary>

Docker Desktop provides `host.docker.internal` out of the box. On Linux, `docker-compose.yml` maps it to the default bridge gateway (usually `172.17.0.1`) via `extra_hosts`. Two host-side settings commonly block the connection anyway:

- **Connection timeout to `172.17.0.1:8123`** — a distro-packaged ClickHouse listens on loopback only. Uncomment `<listen_host>::</listen_host>` in `/etc/clickhouse-server/config.xml` and restart the server. Confirm with `ss -tlnp | grep 8123`, which should show `*:8123` rather than `127.0.0.1:8123`.
- **Still timing out with the listener open** — a host firewall is dropping bridge traffic. For ufw:

  ```bash
  sudo ufw allow proto tcp from 172.16.0.0/12 to 172.17.0.1 port 8123
  ```

Both open ClickHouse to local containers, so weigh that against how the machine is used.

</details>

Start with Docker Compose:

```bash
docker compose up --build
```

Access the UI at http://localhost:3000.

## Model providers

Any OpenAI-compatible endpoint works: Fireworks, Baseten, Together, Groq, OpenRouter, OpenAI itself, or anything you self-host behind vLLM, Ollama or llama.cpp. A provider needs a base URL, a model id and an API key. The key is optional, which is what makes unauthenticated local endpoints work.

Configure up to five providers in `.env` with the `PROVIDER_1_` through `PROVIDER_5_` prefixes:

```bash
PROVIDER_1_NAME=Fireworks
PROVIDER_1_API_KEY=your-api-key
PROVIDER_1_BASE_URL=https://api.fireworks.ai/inference/v1
PROVIDER_1_MODEL=accounts/fireworks/models/deepseek-v4-pro
```

Providers from `.env` are copied into the local database on first boot. After that they are managed from **Site Administration → Providers**, where you can add, edit and remove them without restarting. Every configured provider appears in a picker on the agent page, so you can put the same question to several models and compare the SQL they write.

## Agents

An agent is a ClickHouse schema, a system prompt and a set of suggested questions. Ask one a question and the answer streams back as it happens: the model's reasoning, the `query_clickhouse` tool calls, the SQL, the rows returned and finally its interpretation.

Build your own from **Site Administration → Agents** by supplying a schema and, optionally, sample data. Custom agents behave exactly like the bundled ones.

## Example scenarios

The bundled scenarios live in [`server/seed-builtins.json`](server/seed-builtins.json), a single JSON array where each entry is one agent:

```json
{
  "id": "patient-safety-incidents",
  "name": "Patient Safety Incident Agent",
  "description": "Analyse patient safety incidents — falls, medication errors...",
  "sector": "ps",
  "sectorLabel": "Patient Safety",
  "schema": "-- Patient Safety Incident Schema\nCREATE TABLE incidents (...)",
  "sampleData": "INSERT INTO incidents SELECT ... FROM numbers(420);",
  "systemPrompt": "You are a patient safety analyst...",
  "questions": ["What is our incident rate per 1,000 occupied bed days by ward?"],
  "status": "live",
  "tags": ["Patient Safety"]
}
```

On first boot, any agent whose `id` is not already in the local database is inserted, so adding an entry and restarting picks it up. Editing an existing entry does not overwrite what is stored; change those from the admin UI.

`schema` and `sampleData` are ordinary ClickHouse SQL. Deploy a scenario from its page and the app creates the database and runs both. All the data is synthetic.

The bundled set covers 92 agents across 25 sectors and four industries:

| Industry | Path | Sectors |
| --- | --- | --- |
| Financial Services | `/fs` | Capital markets, retail and commercial banking, payments, compliance, wealth and asset management, insurance, tax, private equity, accounting, crypto, corporate finance, valuations |
| iGaming | `/igaming` | Sportsbook trading, casino and live games, player CRM, responsible gambling and fraud, affiliates |
| Construction | `/construction` | Cost planning, quantity surveying, project controls, procurement, safety and quality |
| Healthcare | `/healthcare` | Patient safety |

## Observability

Set Langfuse credentials to trace every conversation, including prompts, completions, tool calls, latency and token counts:

```bash
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_HOST=
```

Leave `LANGFUSE_HOST` empty for Langfuse Cloud, or point it at a self-hosted instance. Tracing stays off until both keys are present, and can also be configured from **Site Administration → Observability**.

## Architecture

- **Backend** — Node.js and Express (`server/server.js`), streaming responses over SSE
- **LLM** — any OpenAI-compatible provider, with streaming tool use
- **Database** — ClickHouse, Cloud or self-hosted, over HTTP
- **State** — SQLite at `server/data.sqlite` for providers, agents and settings
- **Frontend** — static HTML, CSS and JavaScript served from `website/`

To run it directly rather than in Docker:

```bash
cd server && npm install && npm start
```

## Next Steps

Please visit https://newcadence.io for more details on the project and our ClickHouse consulting services.
