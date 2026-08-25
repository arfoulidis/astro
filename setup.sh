#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# 0. Requirements
# ---------------------------------------------------------------------------

if (( BASH_VERSINFO[0] < 4 )); then
  echo "❌ Bash 4.0+ is required."
  echo "   Current Bash: $BASH_VERSION"
  echo ""
  echo "   On macOS, install modern Bash with:"
  echo "   brew install bash"
  exit 1
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "❌ Bun is not installed or is not in PATH."
  exit 1
fi

BUN_VERSION="$(bun --version)"

echo "Astro Minimal + Tailwind + DaisyUI setup"
echo "-----------------------------------------"
echo "Bash : $BASH_VERSION"
echo "Bun  : $BUN_VERSION"
echo ""

# ---------------------------------------------------------------------------
# 1. Project / domain
# ---------------------------------------------------------------------------

echo "Project setup"
echo "-------------"
echo ""
echo "The project/domain name will be used as:"
echo "  • the project directory"
echo "  • the domain in astro.config.mjs"
echo ""

DEFAULT_PROJECT="$(basename "$PWD")"

PROJECT_NAME=""

while [[ -z "$PROJECT_NAME" ]]; do
  read -r -p "Project/domain name (default ${DEFAULT_PROJECT}): " PROJECT_INPUT || true

  PROJECT_INPUT="${PROJECT_INPUT:-$DEFAULT_PROJECT}"

  # Remove protocol and trailing slash.
  PROJECT_INPUT="${PROJECT_INPUT#https://}"
  PROJECT_INPUT="${PROJECT_INPUT#http://}"
  PROJECT_INPUT="${PROJECT_INPUT%/}"

  if [[ -z "$PROJECT_INPUT" ]]; then
    echo "❌ Project name cannot be empty."
    continue
  fi

  if [[ ! "$PROJECT_INPUT" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$ ]]; then
    echo "❌ Invalid project/domain name: $PROJECT_INPUT"
    echo "   Use letters, numbers, dots and hyphens only."
    continue
  fi

  PROJECT_NAME="$PROJECT_INPUT"
done

SITE_DOMAIN="$PROJECT_NAME"
PROJECT_DIR="$PROJECT_NAME"

echo ""
echo "Project:"
echo "  Name   : $PROJECT_NAME"
echo "  Folder : ./$PROJECT_DIR"
echo "  Domain : https://$SITE_DOMAIN"
echo ""

# ---------------------------------------------------------------------------
# 2. Refuse to overwrite existing directory
# ---------------------------------------------------------------------------

if [[ -e "$PROJECT_DIR" ]]; then
  echo "❌ The project directory already exists:"
  echo "   ./$PROJECT_DIR"
  echo ""
  echo "For safety, this script will not overwrite an existing directory."
  exit 1
fi

read -r -p "Create Astro project in ./$PROJECT_DIR? [Y/n] " CONFIRM
CONFIRM="${CONFIRM:-Y}"

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo ""
echo "📁 Created project directory: $PWD"
echo ""

# ---------------------------------------------------------------------------
# 3. Language
# ---------------------------------------------------------------------------

echo "Language:"
echo "  1) Greek (el-gr)"
echo "  2) US English (en-us)"
read -rp "Choose [1/2] (default 1): " LANG_CHOICE

case "${LANG_CHOICE:-1}" in
  2)
    SITE_LANG="en-us"
    ;;
  *)
    SITE_LANG="el-gr"
    ;;
esac

# ---------------------------------------------------------------------------
# 4. Font
# ---------------------------------------------------------------------------

read -rp "Font (default Geologica): " FONT_INPUT
SITE_FONT="${FONT_INPUT:-Geologica}"

# Lowercase version for CSS variable names.
SITE_FONT_LC="$(printf '%s' "$SITE_FONT" | tr '[:upper:]' '[:lower:]')"

# ---------------------------------------------------------------------------
# 5. Theme
# ---------------------------------------------------------------------------

read -rp "DaisyUI theme (default bumblebee): " THEME_INPUT
SITE_THEME="${THEME_INPUT:-bumblebee}"

echo ""
echo "Config summary:"
echo "  Language : $SITE_LANG"
echo "  Font     : $SITE_FONT"
echo "  Domain   : https://$SITE_DOMAIN"
echo "  Theme    : $SITE_THEME"
echo "  Folder   : $PWD"
echo ""

# ---------------------------------------------------------------------------
# 6. Create Astro project
# ---------------------------------------------------------------------------

echo "Creating Astro project..."
echo ""

bun create astro@latest . -- --template minimal --yes < /dev/null

echo ""

# ---------------------------------------------------------------------------
# 7. Install dependencies
# ---------------------------------------------------------------------------

echo "Installing dependencies..."

bun add daisyui@latest @astrojs/sitemap@latest

bun add -d tailwindcss@latest @tailwindcss/vite@latest

# ---------------------------------------------------------------------------
# 8. Create directories
# ---------------------------------------------------------------------------

mkdir -p \
  src/assets \
  src/layouts \
  src/pages \
  src/components \
  public

# ---------------------------------------------------------------------------
# 9. astro.config.mjs
# ---------------------------------------------------------------------------

cat > astro.config.mjs << EOF
// @ts-check
import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";
import sitemap from "@astrojs/sitemap";
import { fontProviders } from "astro/config";

export default defineConfig({
  site: "https://${SITE_DOMAIN}",

  vite: {
    plugins: [tailwindcss()],
  },

  build: {
    inlineStylesheets: "always",
  },

  integrations: [
    sitemap({
      changefreq: "weekly",
      priority: 0.7,
    }),
  ],

  fonts: [{
    provider: fontProviders.fontsource(),
    name: "${SITE_FONT}",
    cssVariable: "--font-${SITE_FONT_LC}",
    subsets: ["latin", "greek"],
    fallbacks: ["Arial", "sans-serif"],
  }],
});
EOF

# ---------------------------------------------------------------------------
# 10. app.css
# ---------------------------------------------------------------------------

cat > src/assets/app.css << EOF
@import "tailwindcss";
@plugin "daisyui";

@theme inline {
  --font-sans: var(--font-${SITE_FONT_LC});
}
EOF

# ---------------------------------------------------------------------------
# 11. Layout.astro
# ---------------------------------------------------------------------------

cat > src/layouts/Layout.astro << EOF
---
import { Font } from "astro:assets";
import "../assets/app.css";

interface Props {
  title?: string;
  description?: string;
  contained?: boolean;
  noindex?: boolean;
}

const {
  title = "My Site",
  description = "My Site description.",
  contained = false,
  noindex = false,
} = Astro.props;

const canonicalURL = new URL(Astro.url.pathname, Astro.site);
---

<html lang="${SITE_LANG}" data-theme="${SITE_THEME}">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />

    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="icon" href="/favicon.ico" />

    <title>{title}</title>

    <meta name="description" content={description} />

    {noindex && <meta name="robots" content="noindex, nofollow" />}

    <link rel="canonical" href={canonicalURL} />

    <!-- Open Graph -->
    <meta property="og:type" content="website" />
    <meta property="og:url" content={canonicalURL} />
    <meta property="og:title" content={title} />
    <meta property="og:description" content={description} />
    <meta
      property="og:image"
      content={new URL("/og-image.jpg", Astro.site)}
    />

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={title} />
    <meta name="twitter:description" content={description} />
    <meta
      name="twitter:image"
      content={new URL("/og-image.jpg", Astro.site)}
    />

    <link rel="sitemap" href="/sitemap-index.xml" />

    <Font
      cssVariable="--font-${SITE_FONT_LC}"
      preload
    />

    <slot name="head" />
  </head>

  <body class="min-h-screen bg-base-200 text-base-content flex flex-col">

    <a
      href="#main-content"
      class="sr-only focus:not-sr-only focus:fixed focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-primary focus:text-primary-content focus:rounded"
    >
      Skip to main content
    </a>

    <slot name="navbar" />

    <main id="main-content" class="flex-1">
      {
        contained ? (
          <div class="flex items-start justify-center px-4 py-4 lg:py-8">
            <div class="w-full max-w-6xl bg-base-100 p-8 lg:p-14">
              <slot />
            </div>
          </div>
        ) : (
          <slot />
        )
      }
    </main>

    <slot name="footer" />

  </body>
</html>
EOF

# ---------------------------------------------------------------------------
# 12. 404 page
# ---------------------------------------------------------------------------

cat > src/pages/404.astro << 'EOF'
---
import Layout from "../layouts/Layout.astro";
---

<Layout title="Page Not Found" noindex contained>
  <div class="min-h-[50vh] flex flex-col items-center justify-center text-center py-16">
    <p class="text-8xl font-extrabold text-primary/30 mb-4 select-none">
      404
    </p>

    <h1 class="text-2xl font-bold uppercase tracking-wide mb-4">
      Page Not Found
    </h1>

    <p class="text-base-content/70 mb-8 max-w-md">
      The page you are looking for does not exist or has been moved.
    </p>

    <a href="/" class="btn btn-neutral">
      Go Home
    </a>
  </div>
</Layout>
EOF

# ---------------------------------------------------------------------------
# 13. robots.txt
# ---------------------------------------------------------------------------

cat > public/robots.txt << EOF
User-agent: *
Allow: /

Sitemap: https://${SITE_DOMAIN}/sitemap-index.xml
EOF

# ---------------------------------------------------------------------------
# 14. netlify.toml
# ---------------------------------------------------------------------------

cat > netlify.toml << 'EOF'
[build]
  command = "bun run build"
  publish = "dist"

[build.environment]
  BUN_VERSION = "1.4.0"
  NODE_VERSION = "22"

# Hashed Astro assets
[[headers]]
  for = "/_astro/*"

  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

# Fonts
[[headers]]
  for = "/fonts/*"

  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

# HTML
[[headers]]
  for = "/*.html"

  [headers.values]
    Cache-Control = "public, max-age=0, must-revalidate"

# Static public assets
[[headers]]
  for = "/og-image.jpg"

  [headers.values]
    Cache-Control = "public, max-age=86400"

[[headers]]
  for = "/favicon.svg"

  [headers.values]
    Cache-Control = "public, max-age=86400"

[[headers]]
  for = "/favicon.ico"

  [headers.values]
    Cache-Control = "public, max-age=86400"

# Security headers
[[headers]]
  for = "/*"

  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"
    Permissions-Policy = "camera=(), microphone=(), geolocation=()"
EOF

# ---------------------------------------------------------------------------
# 15. rules.md
# ---------------------------------------------------------------------------

cat > rules.md << 'EOF'
# Rules for AI-Generated Websites

## Semantic HTML

Use proper semantic tags: header, main, nav, footer, section, article.

## Forms

Every input must have a label. Use autocomplete attributes.

Provide clear error and success messages.

Add honeypot fields for spam protection.

Always redirect to a /danke (thank-you) page on submit via action="/danke".

Add a GDPR checkbox linking to the privacy policy for any data-collecting form.

## Responsiveness

Layouts must work on all screen sizes.

Avoid horizontal scrolling.

## SEO

- Every page needs a unique <title> and <meta name="description">.
- Legal pages (impressum, datenschutz) must have noindex prop set to true.
- Use canonical URLs.
- Never duplicate content across routes.

## Images

- Always use Astro's <Image> component, never raw <img> tags.
- Set loading="eager" and fetchpriority="high" on the LCP (hero) image only.
- All other images: loading="lazy".
- For the hero image on any page, use getImage() + <link rel="preload"> injected via <slot name="head"> for best LCP.
- Always provide meaningful alt text.
- Use explicit width/height or an aspect-ratio wrapper to prevent CLS.

## Accessibility

- Every page must have a skip-to-content link.
- Use aria-label on icon-only buttons and navigation landmarks.
- Use aria-current="page" on active nav links.
- Color contrast must meet WCAG AA.

## Performance

- inlineStylesheets: "always" is set — do not add render-blocking <link> stylesheets.
- Netlify caching headers are configured — hashed /_astro/* assets are immutable.
- Do not load third-party scripts without defer or async.
EOF

# ---------------------------------------------------------------------------
# 16. Verify the project
# ---------------------------------------------------------------------------

echo ""
echo "Running Astro build to verify the setup..."
echo ""

if bun run build; then
  echo ""
  echo "✅ Build successful!"
else
  echo ""
  echo "❌ Astro build failed."
  echo "   The project was created at:"
  echo "   $PWD"
  exit 1
fi

# ---------------------------------------------------------------------------
# 17. Done
# ---------------------------------------------------------------------------

echo ""
echo "========================================="
echo "✅ Setup complete!"
echo "========================================="
echo ""
echo "Project:"
echo "  $PWD"
echo ""
echo "Configuration:"
echo "  Language : $SITE_LANG"
echo "  Font     : $SITE_FONT"
echo "  Domain   : https://$SITE_DOMAIN"
echo "  Theme    : $SITE_THEME"
echo ""
echo "Next steps:"
echo ""
echo "  cd \"$PROJECT_DIR\""
echo "  bun run dev"
echo ""
echo "Then open the local URL shown by Astro."
echo ""
echo "⚠️  Still manual:"
echo "  1. Add your og-image.jpg to public/"
echo "  2. Add favicon.svg / favicon.ico to public/"
echo "  3. Add your pages/components/content"
echo ""
