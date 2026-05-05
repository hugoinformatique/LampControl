# LampControl landing page

Landing statique séparée de l'app macOS.

## Fichiers

- `index.html` : page française.
- `en/index.html` : page anglaise.
- `es/index.html` : page espagnole.
- `styles.css` : design system dark terminal / amber.
- `script.js` : micro-interaction header.
- `og-image.svg` : image Open Graph.
- `robots.txt` et `sitemap.xml` : fichiers SEO à adapter au domaine final.

## Deploiement

Ce dossier peut être hébergé tel quel sur Vercel, Netlify, GitHub Pages ou un
serveur statique. Il n'est pas référencé par `Package.swift`, les scripts de
build Swift ou le DMG macOS.

Avant mise en ligne, remplacer les URLs canoniques `hugoinformatique.github.io`
par le domaine final si besoin.

## Langues

La première vague de distribution utilise FR / EN / ES.

- `fr` : utile pour la communauté initiale et le support fondateur.
- `en` : langue prioritaire pour Reddit, GitHub et la majorité des acheteurs
  indie/macOS.
- `es` : gros volume mondial, bon potentiel Reddit/communautés tech, plus
  actionnable au lancement que mandarin/hindi pour ce produit.
