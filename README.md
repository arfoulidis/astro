curl -s https://raw.githubusercontent.com/arfoulidis/astro/main/setup.sh | bash

## Custom Font

When running the setup script, you'll be prompted to enter a font name. The script will automatically:
- Convert it to a CSS variable format (e.g., "Open Sans" → `--font-open-sans`)
- Update all configuration files with your choice

**Example:**
```bash
curl -s https://raw.githubusercontent.com/arfoulidis/astro/main/setup.sh | bash
# When prompted: Enter font name (default: Geologica): Open Sans
```

The font will then be available as `var(--font-open-sans)` throughout your project.

Available fonts: [Fontsource](https://fontsource.org/)
