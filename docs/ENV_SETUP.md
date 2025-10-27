# Environment Variable Setup

## Overview

The Green Man Tavern application loads environment variables from a `.env` file in development for convenience, while production uses actual environment variables.

## Files

- `.env` - Your actual environment variables (gitignored, not committed)
- `.env.example` - Template showing what variables are needed
- `config/runtime.exs` - Auto-loads `.env` in development

## Setup

### For Development

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your real API keys:
   ```bash
   # Example .env file
   ANTHROPIC_API_KEY=sk-ant-api03-your-actual-key-here
   ```

3. The application will automatically load these variables when running in development.

### For Production

Set environment variables directly on your server:

```bash
export ANTHROPIC_API_KEY=sk-ant-api03-your-actual-key-here
```

Or use your deployment platform's environment variable interface (Heroku, Fly.io, Railway, etc.).

## Available Environment Variables

### Required

- `ANTHROPIC_API_KEY` - Anthropic Claude API key for character chat

### Optional (for future MindsDB integration)

- `MINDSDB_HOST` - MindsDB server host (default: localhost)
- `MINDSDB_HTTP_PORT` - MindsDB HTTP port (default: 48334)
- `MINDSDB_MYSQL_PORT` - MindsDB MySQL port (default: 48335)
- `MINDSDB_DATABASE` - MindsDB database name (default: mindsdb)
- `MINDSDB_USERNAME` - MindsDB username (default: mindsdb)
- `MINDSDB_PASSWORD` - MindsDB password (default: empty)
- `MINDSDB_POOL_SIZE` - MindsDB connection pool size (default: 5)

## How It Works

### Development Mode

In development (`MIX_ENV=dev`), the application:

1. Checks if `.env` file exists in the project root
2. Reads the file and parses `KEY=VALUE` lines
3. Ignores comments (lines starting with `#`)
4. Trims whitespace and removes quotes
5. Sets each variable using `System.put_env/2`

Example:
```
# This line is ignored (comment)
ANTHROPIC_API_KEY=sk-ant-api03-abc123
ANOTHER_VAR="quoted value"
```

### Production Mode

In production, the application:
1. Reads environment variables from the system
2. Uses default values where applicable
3. Raises errors for required variables that are missing

## Security Notes

- **Never commit `.env` to version control** (already in `.gitignore`)
- **Always use `.env.example` as a template** (committed, safe to share)
- **Keep real API keys secret** - only store placeholders in examples
- **Use strong, unique keys** for production deployments
- **Rotate keys regularly** if compromised

## Troubleshooting

### Variables not loading in development

1. Check that `.env` exists in the project root
2. Verify file format is `KEY=VALUE` (no spaces around `=`)
3. Look for "Loaded environment variables from .env" in server logs
4. Ensure you're running in development (`MIX_ENV=dev`)

### Missing required variables

The application will raise a clear error message:
```
** (RuntimeError) environment variable ANTHROPIC_API_KEY is missing
```

### Production deployment

Set environment variables before starting the server:
```bash
export ANTHROPIC_API_KEY=sk-ant-api03-your-key
mix phx.server
```

Or use your platform's environment variable configuration.

## Testing Environment Variables

You can verify variables are loaded:

```bash
# In IEx console
iex -S mix
System.get_env("ANTHROPIC_API_KEY")  # Should return your key
```

## Getting API Keys

### Anthropic Claude

1. Go to https://console.anthropic.com/
2. Sign in or create an account
3. Navigate to API Keys
4. Create a new key
5. Copy the key and add to `.env`

### MindsDB (Future)

1. Run MindsDB locally or use cloud version
2. Get connection details from MindsDB dashboard
3. Add to `.env` file if needed

