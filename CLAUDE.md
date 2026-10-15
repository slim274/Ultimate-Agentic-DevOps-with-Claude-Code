# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A static HTML/CSS portfolio website used in the **DevOps Micro Internship (DMI)** program. Students deploy it on an Ubuntu VM using Nginx as a Week 1 exercise in Linux basics, Nginx hosting, and deployment verification.

## Running Locally

No build step required. Serve directly:

```bash
python -m http.server 8000
# or
npx http-server
```
For production deployment (as intended by DMI), place files in `/var/www/html` and serve via Nginx at `http://<public-ip>`.

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


- **Navigation:** Fixed navbar with `toggleMenu()` for mobile hamburger and `goToSection()` for smooth scroll
- **Styling:** Dark theme (black bg, `#facc15` yellow + `#60a5fa` blue accents), responsive breakpoints at 900px / 768px / 600px, `fadeUp` keyframe animations
- **Icons:** Font Awesome 6.5.0 via CDN (no local install)
- **No JavaScript framework, no build tooling, no dependencies**

## DMI Ownership Proof Requirement

Before deployment, the footer must be edited to add student details. Replace the original credit line with:

```html
<p><strong>Deployed by:</strong> [Name] | [Group] | [Week] | [Date]</p>
```

This visible proof is required for assignment submission screenshots.
