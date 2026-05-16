#!/bin/bash
echo "Starting Astro Minimal + Tailwind + DaisyUI setup..."

# Remove stale config so Astro doesn't try to load it during project creation
rm -f astro.config.mjs

# 1. Create Astro project
npm create astro@latest . -- --template minimal --yes < /dev/null

# 2. Install all dependencies up front, including sitemap
npm install tailwindcss@latest @tailwindcss/vite@latest daisyui@latest @astrojs/sitemap@latest

mkdir -p src/assets src/layouts src/pages

# 3. Write config AFTER all packages are installed
cat > astro.config.mjs << 'EOF'
// @ts-check
import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";
import sitemap from "@astrojs/sitemap";
import { fontProviders } from "@fontsource/core";
export default defineConfig({
  site: "https://example.gr",
  vite: {
    plugins: [tailwindcss()],
  },
  build: {
    inlineStylesheets: "always",
  },
  integrations: [
    sitemap({
      filter: (page) => !page.includes('/admin') && !page.includes('/private'),
      changefreq: 'weekly',
      priority: 0.7,
      lastmod: new Date(),
    }),
  ],
  fonts: [{
    provider: fontProviders.fontsource(),
    name: "Geologica",
    cssVariable: "--font-geologica",
    fallbacks: [
      "Arial",
      "sans-serif"
    ]
  }],
});
EOF

cat > src/assets/app.css << 'EOF'
@import "tailwindcss";
@plugin "daisyui";

@theme inline {
  --font-sans: var(--font-geologica);
}
EOF

cat > src/layouts/Layout.astro << 'EOF'
---
import { Font } from "astro";
import "../assets/app.css";
const { title = "My Site" } = Astro.props;
---
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>{title}</title>
    <link rel="sitemap" href="/sitemap-index.xml" />
    <Font cssVariable="--font-geologica" preload />
  </head>
  <body class="min-h-screen bg-base-200 text-base-content">
    <slot />
  </body>
</html>
EOF

cat > src/pages/robots.txt.ts << 'EOF'
import type { APIRoute } from 'astro';
const getRobotsTxt = (sitemapURL: URL) => `
User-agent: *
Allow: /
Sitemap: ${sitemapURL.href}
`.trim();
export const GET: APIRoute = ({ site }) => {
  const sitemapURL = new URL('sitemap-index.xml', site);
  return new Response(getRobotsTxt(sitemapURL));
};
EOF

cat > rules.md << 'EOF'
# Accessibility Rules for AI‑Generated Websites
## Semantic HTML
Use proper semantic tags: header, main, nav, footer, section, article.
## Forms
Every input must have a label. Provide clear error and success messages.
## Responsiveness
Layouts must work on all screen sizes. Avoid horizontal scrolling.
EOF

echo "Setup complete!"
