#!/bin/bash

# 1. Create Astro project
npm create astro@latest . -- --template minimal --yes

# 2. Install Tailwind, Tailwind Vite plugin, DaisyUI
npm install tailwindcss@latest @tailwindcss/vite@latest daisyui@latest

# 3. Update astro.config.mjs
cat > astro.config.mjs << 'EOF'
// @ts-check
import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";
import sitemap from "@astrojs/sitemap";

export default defineConfig({
  site: "https://example.com",
  vite: {
    plugins: [tailwindcss()],
  },
  integrations: [sitemap()],
});
EOF

# 4. Create CSS file with Tailwind + DaisyUI
mkdir -p src/assets
cat > src/assets/app.css << 'EOF'
@import "tailwindcss";
@plugin "daisyui";
EOF

# 5. Update Layout.astro
mkdir -p src/layouts
cat > src/layouts/Layout.astro << 'EOF'
---
import "../assets/app.css";
const { title = "My Site" } = Astro.props;
---

<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>{title}</title>
    <link rel="sitemap" href="/sitemap-index.xml" />
  </head>
  <body class="min-h-screen bg-base-200 text-base-content">
    <slot />
  </body>
</html>
EOF

# 6. Add sitemap integration (already in config)
npx astro add sitemap --yes

# 7. Create robots.txt route
mkdir -p src/pages
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

# 10. Create rules.md (accessibility-focused)
cat > rules.md << 'EOF'
# Accessibility Rules for AI‑Generated Websites

## 1. Semantic HTML
- Always use proper semantic tags: <header>, <main>, <nav>, <footer>, <section>, <article>.
- Avoid <div> soup.

## 2. Responsiveness
- Layouts must work on mobile, tablet, and desktop.
- Avoid horizontal scrolling.


echo "Setup complete!"
