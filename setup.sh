#!/bin/bash
set -euo pipefail

echo "Astro Minimal + Tailwind + DaisyUI setup"
echo "-----------------------------------------"

# ---------------------------------------------------------------------------
# 1. Prompts
# ---------------------------------------------------------------------------

# Language: only two supported options, mapped to an html lang + locale
echo "Language:"
echo "  1) Greek (el-gr)"
echo "  2) US English (en-us)"
read -rp "Choose [1/2] (default 1): " LANG_CHOICE
case "${LANG_CHOICE:-1}" in
  2) SITE_LANG="en-us" ;;
  *) SITE_LANG="el-gr" ;;
esac

# Font
read -rp "Font (default Geologica): " FONT_INPUT
SITE_FONT="${FONT_INPUT:-Geologica}"

# Domain — best-effort autocomplete from the current directory name.
# This is a guess, not a real domain, so it's shown as an editable default.
DEFAULT_DOMAIN="$(basename "$PWD").gr"
read -rp "Domain, no protocol (default ${DEFAULT_DOMAIN}): " DOMAIN_INPUT
SITE_DOMAIN="${DOMAIN_INPUT:-$DEFAULT_DOMAIN}"

# Theme
read -rp "DaisyUI theme (default bumblebee): " THEME_INPUT
SITE_THEME="${THEME_INPUT:-bumblebee}"

echo ""
echo "Config summary:"
echo "  Language : $SITE_LANG"
echo "  Font     : $SITE_FONT"
echo "  Domain   : https://$SITE_DOMAIN"
echo "  Theme    : $SITE_THEME"
echo ""

# ---------------------------------------------------------------------------
# 2. Guard against running in a non-empty directory.
# `bun create astro@latest .` will happily collide with or overwrite existing
# files, and --yes suppresses the prompts that would normally catch this.
# No backups are taken (by request) — this check is the only safety net,
# so it's a hard stop, not a warning.
# ---------------------------------------------------------------------------

if [[ -n "$(ls -A . 2>/dev/null)" ]]; then
  echo "⚠️  This directory is not empty:"
  ls -A .
  read -rp "Continue and let 'bun create astro' run here anyway? [y/N] " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted. Run this from an empty directory, or confirm explicitly."
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# 3. Create Astro project
# ---------------------------------------------------------------------------

bun create astro@latest . -- --template minimal --yes < /dev/null

# 4. Install dependencies
# tailwindcss / @tailwindcss/vite are build tooling -> devDependencies
bun add daisyui@latest @astrojs/sitemap@latest
bun add -d tailwindcss@latest @tailwindcss/vite@latest

mkdir -p src/assets src/layouts src/pages src/components public

# ---------------------------------------------------------------------------
# 5. astro.config.mjs — site: set from prompt, sitemap integration kept
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
    cssVariable: "--font-${SITE_FONT,,}",
    subsets: ["latin", "greek"],
    fallbacks: ["Arial", "sans-serif"],
  }],
});
EOF

# ---------------------------------------------------------------------------
# 6. app.css
# ---------------------------------------------------------------------------

cat > src/assets/app.css << EOF
@import "tailwindcss";
@plugin "daisyui";

@theme inline {
  --font-sans: var(--font-${SITE_FONT,,});
}
EOF

# ---------------------------------------------------------------------------
# 7. Layout.astro
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
    <meta property="og:image" content={new URL("/og-image.jpg", Astro.site)} />

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={title} />
    <meta name="twitter:description" content={description} />
    <meta name="twitter:image" content={new URL("/og-image.jpg", Astro.site)} />

    <link rel="sitemap" href="/sitemap-index.xml" />
    <Font cssVariable="--font-${SITE_FONT,,}" preload />
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
# 8. robots.txt — domain is already known from the prompt, so no placeholder
# ---------------------------------------------------------------------------

cat > public/robots.txt << EOF
User-agent: *
Allow: /
Sitemap: https://${SITE_DOMAIN}/sitemap-index.xml
EOF

# ---------------------------------------------------------------------------
# 9. 404 page
# ---------------------------------------------------------------------------

cat > src/pages/404.astro << 'EOF'
---
import Layout from "../layouts/Layout.astro";
---
<Layout title="Page Not Found" noindex contained>
  <div class="min-h-[50vh] flex flex-col items-center justify-center text-center py-16">
    <p class="text-8xl font-extrabold text-primary/30 mb-4 select-none">404</p>
    <h1 class="text-2xl font-bold uppercase tracking-wide mb-4">Page Not Found</h1>
    <p class="text-base-content/70 mb-8 max-w-md">
      The page you are looking for does not exist or has been moved.
    </p>
    <a href="/" class="btn btn-neutral">Go Home</a>
  </div>
</Layout>
EOF

# ---------------------------------------------------------------------------
# 10. netlify.toml — caching + security headers
# ---------------------------------------------------------------------------

cat > netlify.toml << 'EOF'
[build]
  command = "bun run build"
  publish = "dist"

[build.environment]
  BUN_VERSION = "1.3.14"
  NODE_VERSION = "22"

# Hashed assets (JS, CSS, images processed by Astro) — cache forever
[[headers]]
  for = "/_astro/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

# Fonts
[[headers]]
  for = "/fonts/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

# HTML — always revalidate
[[headers]]
  for = "/*.html"
  [headers.values]
    Cache-Control = "public, max-age=0, must-revalidate"

# Static public assets (not hashed) — 1 day
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
# 11. rules.md
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
Layouts must work on all screen sizes. Avoid horizontal scrolling.

## SEO
- Every page needs a unique <title> and <meta name="description">.
- Legal pages (impressum, datenschutz) must have noindex prop set to true.
- Use canonical URLs. Never duplicate content across routes.

## Images
- Always use Astro's <Image> component, never raw <img> tags.
- Set loading="eager" and fetchpriority="high" on the LCP (hero) image only. All others: loading="lazy".
- For the hero image on any page, use getImage() + <link rel="preload"> injected via <slot name="head"> for best LCP.
- Always provide meaningful alt text.
- Use explicit width/height or an aspect-ratio wrapper to prevent CLS.

## Accessibility
- Every page must have a skip-to-content link (already in Layout).
- Use aria-label on icon-only buttons and navigation landmarks.
- Use aria-current="page" on active nav links.
- Color contrast must meet WCAG AA.

## Performance
- inlineStylesheets: "always" is set — do not add render-blocking <link> stylesheets.
- Netlify caching headers are configured — hashed /_astro/* assets are immutable.
- Do not load third-party scripts without defer or async.
EOF

echo ""
echo "✅ Setup complete!"
echo "  Language : $SITE_LANG"
echo "  Font     : $SITE_FONT"
echo "  Domain   : https://$SITE_DOMAIN  (already set as 'site:' in astro.config.mjs)"
echo "  Theme    : $SITE_THEME"
echo ""
echo "⚠️  Still manual:"
echo "  1. Add your og-image.jpg to public/"
