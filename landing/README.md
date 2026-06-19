# Karacookie landing page

One-page Astro site for [karacookie.app](https://karacookie.app).

## Develop

```sh
cd landing
npm install
npm run dev    # http://localhost:4321
```

## Build

```sh
npm run build  # → dist/
```

## Deploy to GitHub Pages (recommended)

Already wired. To turn it on:

1. Push this repo to GitHub
2. **Settings → Pages → Build and deployment → Source: GitHub Actions**
3. (Optional) Custom domain: edit `landing/public/CNAME` to your domain → push → in **Pages settings** add the same domain
4. Push to `main` — `.github/workflows/deploy-landing.yml` builds + deploys automatically

The site lives at `https://<your-user>.github.io/<repo>/` by default, or your CNAME-mapped domain.

## Deploy elsewhere

The `dist/` folder is a fully static site — drop it on Vercel, Netlify, Cloudflare Pages, S3, or any static host. No backend, no env vars needed.

## Editing copy

- Hero copy, theme list, feature list, FAQ → `src/pages/index.astro`
- Styling → `src/styles/global.css`
- Favicon → `public/favicon.svg`
