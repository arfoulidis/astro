#!/bin/bash
echo "Starting Astro Minimal + Tailwind + DaisyUI setup..."

# 1. Create Astro project — redirect stdin so it can't consume the pipe
npm create astro@latest . -- --template minimal --yes < /dev/null

# 2. Install dependencies
npm install tailwindcss@latest @tailwindcss/vite@latest daisyui@latest

# Ensure directories exist
mkdir -p src/assets src/layouts src/pages

# 3. Write astro.config.mjs
cat > astro.config.mjs << 'EOF'
// @ts-check
import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";
import sitemap from "@astrojs/sitemap";
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
});
EOF

# 4. Create CSS file
cat > src/assets/app.css << 'EOF'
@import "tailwindcss";
@plugin "daisyui";
EOF

# 5. Create Layout.astro
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

# 6. Add sitemap integration — also redirect stdin
npx astro add sitemap --yes < /dev/null

# 7. Create robots.txt route
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

# 8. Create accessibility rules
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
