  #!/bin/bash
  echo "Starting Astro Minimal + Tailwind + DaisyUI setup..."

  # Back up existing config if it exists
  if [[ -f astro.config.mjs ]]; then
    BACKUP_FILE="astro.config.mjs.backup.$(date +%s)"
    mv astro.config.mjs "$BACKUP_FILE"
    echo "📦 Backed up existing astro.config.mjs to $BACKUP_FILE"
  fi

  # 1. Create Astro project
  bun create astro@latest . -- --template minimal --yes < /dev/null

  # 2. Install all dependencies
  bun add tailwindcss@latest @tailwindcss/vite@latest daisyui@latest @astrojs/sitemap@latest

  mkdir -p src/assets src/layouts src/pages src/components public

  # 3. astro.config.mjs
  cat > astro.config.mjs << 'EOF'
  // @ts-check
  import { defineConfig } from "astro/config";
  import tailwindcss from "@tailwindcss/vite";
  import sitemap from "@astrojs/sitemap";
  import { fontProviders } from "astro/config";

  export default defineConfig({
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
      name: "Geologica",
      cssVariable: "--font-geologica",
      subsets: ["latin", "greek"],
      fallbacks: ["Arial", "sans-serif"],
    }],
  });
  EOF

  # 4. app.css
  cat > src/assets/app.css << 'EOF'
  @import "tailwindcss";
  @plugin "daisyui";

  @theme inline {
    --font-sans: var(--font-geologica);
  }
  EOF

  # 5. Layout.astro — full SEO, noindex prop, head slot, skip link, semantic structure
  cat > src/layouts/Layout.astro << 'EOF'
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
  <html lang="el-gr" data-theme="bumblebee">
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
      <Font cssVariable="--font-geologica" preload />
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

  # 6. Static robots.txt (replace YOUR_DOMAIN before deploying)
  cat > public/robots.txt << 'EOF'
  User-agent: *
  Allow: /

  Sitemap: https://YOUR_DOMAIN/sitemap-index.xml
  EOF

  # 7. 404 page
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

  # 8. netlify.toml — caching + security headers
  cat > netlify.toml << 'EOF'
  [build]
    command = "bun run build"
    publish = "dist"

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

  # 9. rules.md
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
  - Do not set lastmod in sitemap config — omitting it is better than always using build date.

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
  echo "Font configured as: Geologica"
  echo "Language configured as: el-gr (Greek)"
  echo "Theme configured as: bumblebee"
  echo ""
  echo "⚠️  Remember to:"
  echo "  1. Set site: 'https://YOUR_DOMAIN' in astro.config.mjs"
  echo "  2. Update the Sitemap URL in public/robots.txt"
  echo "  3. Add your og-image.jpg to public/"
