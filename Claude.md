# Oral History Collections Template - Technical Overview

## Project Summary

This is a digital oral history collection built using the **Oral History as Data (OHD)** framework, a specialized extension of **CollectionBuilder-CSV**. The collection focuses on presenting coded oral history interviews with interactive transcripts, qualitative analysis tools, and geographic visualizations.

## Core Technologies

### 1. Oral History as Data (OHD)

**Purpose**: A static web framework designed specifically for publishing and analyzing coded oral history and qualitative interviews on the web.

**Key Features**:
- Interactive transcript exploration with integrated media playback
- Qualitative coding analysis through configurable metadata schemas
- Geographic visualization of interview locations and themes
- Advanced search capabilities across transcripts and metadata
- Compound object management for related digital assets

**Academic Origins**: Developed by the University of Idaho Library's Center for Digital Inquiry and Learning (CDIL) in 2018. Battle-tested across multiple academic projects including:
- Voices of Gay Rodeo (2019-2021)
- Idaho Queered (2019-2021)
- CTRL+Shift (2021+)

**Documentation**: https://deepwiki.com/oralhistoryasdata/template

### 2. CollectionBuilder-CSV

**Purpose**: The foundational static site framework that OHD extends. CollectionBuilder provides the core infrastructure for creating digital collection websites without requiring complex databases or servers.

**Architecture Approach**:
- **Static Site Generation**: All pages are pre-generated HTML, making sites fast, secure, and easy to host
- **CSV-Driven**: Collection metadata lives in simple CSV spreadsheets rather than databases
- **Data-Driven Configuration**: All site behavior controlled through CSV configuration files rather than code modifications
- **Jekyll-Based**: Uses Jekyll static site generator as the build engine

**Key Advantages**:
- No server-side programming required
- Free hosting via GitHub Pages
- Version control for all content and configuration
- Sustainable long-term preservation

### 3. Jekyll Static Site Generator

**Role**: The build engine that transforms templates, data files, and configuration into a complete static website.

**Components Used**:
- **Liquid Templating**: Dynamic content generation using `{{ }}` and `{% %}` syntax
- **Ruby Plugins**: Custom plugins in `_plugins/` extend Jekyll functionality (e.g., `cb_helpers.rb` for icon generation)
- **YAML/CSV Data**: Jekyll processes CSV files in `_data/` as data sources
- **Markdown Content**: Pages in `pages/` directory written in Markdown

### 4. Frontend Technologies

**Bootstrap 5**: 
- CSS framework for responsive design
- Grid system for layouts (used in person.html: `col-md-7`, `col-md-5`)
- Component library for cards, badges, buttons, navigation

**Leaflet.js**:
- JavaScript mapping library for interactive maps
- Used in `person-map.html` to display interview locations
- Esri base layers for geographic context

**Bootstrap Icons**:
- SVG icon library integrated via `cb_helpers.rb` plugin
- Configurable in `theme.yml`
- Generated as SVG sprite file (`cb-icons.svg`)

## Collection Structure

### Person-Centered Design

This collection implements a **person layout** that serves as a biographical hub linking related interviews:

**Person Items** (display_template: "person"):
- Biographical information (birth year, occupation, origin, residence)
- Portrait images
- Aggregated statistics from all interviews
- Geographic map showing all interview locations
- Word cloud of discussed topics

**Interview Items** (display_template: "transcript"):
- Full transcript text with synchronized media
- Qualitative codes/subjects
- Interviewer information
- Location and temporal metadata
- Related to person via `personid` field

### Metadata Schema

**Key Relationship**: `personid` field in interview records links to person `objectid`

**Person Fields**:
- `objectid`: Unique identifier
- `title`: Person's name
- `display_template`: "person"
- `birth_year`, `occupation`, `origin`, `residence`: Biographical data
- `map_markers`: Pipe-delimited coordinates for all interview locations

**Interview Fields**:
- `objectid`: Unique identifier
- `personid`: Links to person record
- `title`: Interview title
- `date`, `duration`, `interviewer`: Interview metadata
- `subject`: Semicolon-delimited qualitative codes
- `location`: Geographic location
- `latitude`, `longitude`: Coordinates for mapping
- `object_transcript`: Path to transcript file

## Configuration System

### CSV Configuration Files

All in `_data/` directory:

**config-browse.csv**: Browse page field definitions
- `person_name` field enables browsing by person

**config-metadata.csv**: Metadata display on item pages

**config-search.csv**: Search index configuration

**config-transcript.csv**: Transcript display settings

**config-nav.csv**: Navigation menu structure

**config-theme-colors.csv**: Color scheme customization

**theme.yml**: Theme configuration including icons
- Maps icon names (e.g., `icon-map-pin`) to Bootstrap icon names (e.g., `geo-alt-fill`)

### Icon System

Icons are managed through a three-layer system:

1. **theme.yml**: Maps custom icon names to Bootstrap Icons
2. **cb_helpers.rb plugin**: Processes icon configuration, generates SVG sprite
3. **cb-icons.svg**: Generated sprite file containing all icon symbols
4. **HTML templates**: Reference icons via `<use xlink:href="#icon-name"/>`

## Custom Development

### Person Layout (_layouts/item/person.html)

**Two-Column Responsive Design**:
- **Left Column (70%)**: Person information card, interview list with cards
- **Right Column (30%)**: Interactive map, word cloud of topics
- **Mobile**: Stacked layout with "Jump to Interviews" button

**Data Aggregation**: Liquid loops aggregate data from child interviews:
- Total unique subjects and locations
- All interviewers (deduplicated)
- Date range (earliest to latest interview)

**Interactive Elements**:
- Clickable occupation badges → browse by occupation
- Clickable interviewer badges → browse by interviewer
- Clickable location badges → browse by location
- Subject tags on interview cards
- Word cloud buttons → browse by subject

### Person Map Include (_includes/item/person-map.html)

**Features**:
- Parses pipe-delimited `map_markers` field
- Creates Leaflet map with markers for each interview location
- Auto-fits bounds to show all markers
- 500px height for good visibility

### Person Word Cloud (_includes/item/person-cloud.html)

**Implementation**:
- JavaScript-based aggregation of subjects from all interviews
- Counts occurrence frequency
- Scales button sizes based on frequency (1-10 scale)
- Links to browse page filtered by subject

## Development Workflow

### Local Development

```bash
bundle install              # Install Ruby dependencies
bundle exec jekyll serve    # Start development server at localhost:4000
```

### Build Process

1. Jekyll reads configuration from `_config.yml`
2. Processes data from CSV files in `_data/`
3. Generates pages from layouts in `_layouts/`
4. Compiles SASS from `_sass/` to CSS
5. Copies static assets from `assets/`
6. Outputs complete site to `_site/`

### Deployment

**GitHub Pages**: Automated deployment via `.github/workflows/jekyll.yml`
- Triggered on push to main branch
- Builds site in CI environment
- Deploys to GitHub Pages automatically

## Key Design Principles

### 1. Data-Driven Configuration
All site behavior controlled through CSV files, not code modification. This allows content editors to customize the site without programming knowledge.

### 2. Sustainable and Preservable
Static HTML output means no databases, no complex server infrastructure. Sites can be archived as simple file collections.

### 3. Minimal Dependencies
Core functionality requires only Jekyll and Ruby. No database servers, no Node.js build processes beyond basic Jekyll.

### 4. Progressive Enhancement
Base functionality works without JavaScript. Enhanced features (maps, word clouds) layer on top for capable browsers.

### 5. Responsive and Accessible
Bootstrap 5 grid ensures mobile-friendly layouts. Semantic HTML and ARIA attributes support screen readers.

## Attribution and Licensing

**MIT License**: Free to use, modify, and distribute

**Key Contributors**:
- Evan Peter Williamson (ORCID: 0000-0002-7990-9924)
- Devin Becker (ORCID: 0000-0002-0974-9064)
- Olivia Wikle (ORCID: 0000-0001-8122-4169)
- University of Idaho Library Digital Initiatives

**Proper Citation**: Should reference both the OHD framework and its CollectionBuilder foundation (see CITATION.cff file).

## Resources

- **OHD Template Repository**: https://github.com/oralhistoryasdata/template
- **OHD Documentation**: https://deepwiki.com/oralhistoryasdata/template
- **CollectionBuilder Documentation**: https://collectionbuilder.github.io/
- **Jekyll Documentation**: https://jekyllrb.com/docs/

---

*This collection represents a modern approach to digital oral history publication, combining the flexibility of static site generation with specialized tools for qualitative research and public scholarship.*
