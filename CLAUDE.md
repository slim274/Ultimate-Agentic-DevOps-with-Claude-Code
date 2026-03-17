# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Static HTML/CSS portfolio website deployed to AWS using S3 and CloudFront.
## Deployment

There is no build step. Deploy by copying files to the Nginx document root:

```bash
sudo cp -r /path/to/repo/* /var/www/html/
sudo systemctl start nginx
# Verify at http://<public-ip>
```

## Mandatory DMI Customization

Students deploying this site **must** edit the footer in `index.html` to prove ownership:

```html
<p><strong>Deployed by:</strong> [Name] | [Group] | Week 1 | [Date]</p>
```

## Architecture

The project is a static website consisting of the following main file:

-index.html - main single-page website layout
-style.css - conatina all styling and responsive design
-images/- stores all image assets used in the site
-privacy.html - privacy policy page
-term.html - Terms and conditions pag
-README.md - REspository documentation

the website uses a single page layout with multiple sections including hero, about, services , courses, books, community, contact and footer.

## Conventions

No JavaScript allowed in the project

Mobile-first CSS approach

All images stored in images/

**Page sections (by anchor ID):** `#home` → `#about` → `#services` → `#courses` → `#book` → `#community` → `#contact`

**Color tokens (defined in CSS):**
- Yellow accent: `#facc15`
- Blue accent: `#3b82f6`
- Dark backgrounds: `#000` / `#111`

**Responsive breakpoints:** 900px (tablet grid adjustments), 768px and 600px (single-column mobile layouts).

**External dependencies (CDN only):**
- Font Awesome v6.5.0 for icons
- Course thumbnail images from Udemy CDN

**Assets in `images/`:** `logo.png`, `profile.jpg`, `image.png` (3.5 MB hero banner), book covers (`Git.jpg`, `awsCloud.jpg`, `Devops.jpg`), `dmi-course.jpg`, `signature.png`.
