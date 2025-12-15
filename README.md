# Gazelle-Origin Webhook

Docker image that runs [gazelle-origin](https://github.com/spinfast319/gazelle-origin) behind a [webhook](https://github.com/adnanh/webhook) endpoint to automatically generate `origin.yaml` files for torrents from Gazelle-based trackers.

## Quick Start

### Using Docker Run

```bash
docker run -d \
  --name gazelle-webhook \
  -p 9000:9000 \
  -v /path/to/downloads:/data \
  -e RED_API_KEY=your_api_key_here \
  -e ORIGIN_TRACKER=red \
  -e WEBHOOK_SECRET=your_secret_token \
  ghcr.io/jee-r/gazelle-origin-webhook:latest
```

### Using Docker Compose

```yaml
version: '3.8'

services:
  gazelle-webhook:
    image: ghcr.io/jee-r/gazelle-origin-webhook:latest
    container_name: gazelle-webhook
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - /path/to/downloads:/data
    environment:
      RED_API_KEY: your_api_key_here
      ORIGIN_TRACKER: red
      WEBHOOK_SECRET: your_secret_token
```

Start the container:
```bash
docker-compose up -d
```

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `RED_API_KEY` | Yes | - | RED API key ([how to obtain](https://github.com/spinfast319/gazelle-origin#obtaining-your-api-key)) |
| `ORIGIN_TRACKER` | No | `red` | Tracker identifier |
| `WEBHOOK_SECRET` | Recommended | `changeme` | Authentication token |

### Volumes

| Path | Description |
|------|-------------|
| `/data` | Downloads directory where `origin.yaml` will be created |

### Ports

| Port | Description |
|------|-------------|
| `9000` | Webhook HTTP endpoint |

## Usage

### Endpoints

#### 1. Read-Only (get metadata)
```
POST http://localhost:9000/hooks/gazelle-origin
```

Returns the YAML content without writing any file.

#### 2. Write File (save origin.yaml)
```
POST http://localhost:9000/hooks/gazelle-origin-write
```

Writes `origin.yaml` file to the specified directory.

### Authentication

Include the token in the request header:

```
X-Webhook-Token: your_secret_token
```

### Request Payload

**Read-Only Hook:**
```json
{
  "torrent_identifier": "C380B62A3EC6658597C56F45D596E8081B3F7A5C"
}
```

**Write Hook:**
```json
{
  "torrent_identifier": "C380B62A3EC6658597C56F45D596E8081B3F7A5C",
  "output_path": "/data/Artist - Album/origin.yaml"
}
```

Supported identifier formats:
- Info hash
- Torrent ID
- Permalink URL

See [gazelle-origin usage](https://github.com/spinfast319/gazelle-origin#usage) for more details.

### Example

**Read-Only:**
```bash
curl -X POST http://localhost:9000/hooks/gazelle-origin \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Token: your_secret_token" \
  -d '{"torrent_identifier": "C380B62A3EC6658597C56F45D596E8081B3F7A5C"}'
```

**Write File:**
```bash
curl -X POST http://localhost:9000/hooks/gazelle-origin-write \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Token: your_secret_token" \
  -d '{
    "torrent_identifier": "C380B62A3EC6658597C56F45D596E8081B3F7A5C",
    "output_path": "/data/Pink Floyd - Dark Side of the Moon/origin.yaml"
  }'
```

## Integration with Deluge

### Using Execute Plugin

1. Install the Execute plugin in Deluge
2. Add a command for the **Torrent Complete** event:

**Write origin.yaml to torrent directory:**
```bash
curl -X POST http://localhost:9000/hooks/gazelle-origin-write \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Token: your_secret_token" \
  -d "{\"torrent_identifier\": \"%I\", \"output_path\": \"%f/origin.yaml\"}"
```

**Read-only (just get metadata):**
```bash
curl -X POST http://localhost:9000/hooks/gazelle-origin \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Token: your_secret_token" \
  -d "{\"torrent_identifier\": \"%I\"}"
```

If Deluge runs in Docker on the same network, use the container name:

```bash
curl -X POST http://gazelle-webhook:9000/hooks/gazelle-origin-write \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Token: your_secret_token" \
  -d "{\"torrent_identifier\": \"%I\", \"output_path\": \"%f/origin.yaml\"}"
```

### Deluge Event Variables

- `%I` - Info hash (recommended)
- `%n` - Torrent name
- `%p` - Save path
- `%f` - Full file path

### Output

The webhook will create an `origin.yaml` file in the torrent directory containing complete metadata. See [gazelle-origin output example](https://github.com/spinfast319/gazelle-origin#example-output) for details.

## Logs

View container logs:

```bash
docker logs -f gazelle-webhook
```

## Credits

This project combines:
- [gazelle-origin](https://github.com/spinfast319/gazelle-origin) by spinfast319
- [webhook](https://github.com/adnanh/webhook) by adnanh

## License

MIT License
