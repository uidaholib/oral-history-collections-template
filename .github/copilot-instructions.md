# Oral History Collections Template - AI Agent Guide

## Project Overview

This is a **Jekyll-based static site generator** for oral history collections, built on the **Oral History as Data (OHD)** framework—a specialized extension of **CollectionBuilder-CSV**. The collection presents coded oral history interviews with interactive transcripts, qualitative analysis tools, and geographic visualizations.

## Architecture & Data Flow

### Person-Centered Data Model

The collection uses a **hierarchical relationship** between person records and interview records:

- **Person items** (`display_template: "person"`) serve as biographical hubs containing aggregated data
- **Interview items** (`display_template: "transcript"`) link to persons via `personid` field
- **Record items** (`display_template: "record"`) represent shared interviews linked via `connected_objectid`

**Key relationship**: `personid` in interview records → `objectid` in person records

### CSV-Driven Configuration

All site behavior is controlled through CSV files in `_data/`, NOT code modification:

- `lcoh.csv` - Main metadata (interviews, persons, records)
- `config-browse.csv` - Browse page field definitions
- `config-metadata.csv` - Metadata display configuration
- `config-transcript.csv` - Transcript display settings
- `theme.yml` - Theme configuration including icon mappings

### Jekyll Page Generation

The `_plugins/cb_page_gen.rb` plugin generates pages from CSV metadata:

```ruby
# Configured in _config.yml
page_gen:
  - data: 'lcoh'      # Source CSV
    dir: 'people'     # Output directory
```

Pages are filtered by `display_template` field and output to appropriate directories (`items/`, `people/`).

## Critical Workflows

### Development Commands

```bash
# Install dependencies
bundle install

# Local development (serves at localhost:4000)
bundle exec jekyll serve

# Production build (includes analytics)
rake deploy
# OR: JEKYLL_ENV=production bundle exec jekyll build
```

### Rake Tasks

Located in `rakelib/`, accessible via `rake <task>`:

- `rake deploy` - Build with production environment
- `rake generate_json` - Generate JSON files for large collections (if `json-generation: true` in theme.yml)
- `rake generate_derivatives` - Create image derivatives
- `rake rename_by_csv` - Batch rename files using CSV mapping

## Project-Specific Conventions

### Liquid Template Patterns

**Aggregate data from child records**:
```liquid
{% assign children = site.data[site.metadata] | where_exp: 'item','item.personid == page.objectid' %}
{% for interview in children %}
  {% if interview.subject %}
    {% assign total_subjects = total_subjects | append: ";" | append: interview.subject %}
  {% endif %}
{% endfor %}
```

**Parse pipe-delimited coordinates** (person maps):
```liquid
{% assign coords_array = page.map_markers | split: "|" %}
```

### Icon System

Three-layer icon system avoids hardcoding Bootstrap Icons:

1. **theme.yml**: Maps semantic names to Bootstrap icons (`icon-map-pin: geo-alt-fill`)
2. **cb_helpers.rb**: Processes configuration, generates SVG sprite at build time
3. **Templates**: Reference via `<use xlink:href="/assets/lib/cb-icons.svg#icon-map-pin"/>`

### File Paths

- **Transcripts**: `_data/transcripts/{objectid}.csv`
- **Index files**: `_data/indexes/{objectid}.csv`
- **XML source**: `xml/{filename}.xml`
- **Object files**: `objects/{filename}.mp3` (referenced via `object_location` field)

### Metadata Fields Reference

**Person record essentials**:
- `objectid`, `title` (person name), `display_template: "person"`
- `birth_year`, `occupation`, `origin`, `residence` (biographical)
- `map_markers` (pipe-delimited coordinates: `lat,lng,popup|lat,lng,popup`)

**Interview record essentials**:
- `objectid`, `personid` (links to person), `display_template: "transcript"`
- `transcript_xml` (source XML filename for tracking)
- `object_transcript` (path to CSV: `_data/transcripts/{objectid}.csv`)
- `subject` (semicolon-delimited qualitative codes)
- `latitude`, `longitude`, `location` (for mapping)

## Integration Points

### External Assets

Collections typically load shared assets from main library site:

```yaml
# _config.yml
digital-assets: https://www.lib.uidaho.edu/assets
```

### Bootstrap 5 & Leaflet.js

- **Bootstrap 5** grid system (`col-md-7`, `col-md-5`) used in person.html for responsive layout
- **Leaflet.js** for interactive maps (`_includes/item/person-map.html`)
- **Bootstrap Icons** as SVG sprite (never hardcode icon names)

### CollectionBuilder Inheritance

This template extends CollectionBuilder-CSV but **trails behind** the main CB development. When updating CB features:

1. Test in this codebase first
2. Maintain U of I-specific customizations (person layout, OHD features)
3. Check `base-layout` setting in theme.yml (CB vs OHD styling)

## Common Pitfalls

1. **Don't modify layouts directly** - Configure via CSV files in `_data/`
2. **Icon references** - Use semantic names from theme.yml, not Bootstrap icon names directly
3. **Person vs transcript templates** - Check `display_template` field when troubleshooting page generation
4. **Production builds** - Use `rake deploy` or `JEKYLL_ENV=production` to include analytics

## Key Files to Reference

- [_layouts/item/person.html](_layouts/item/person.html) - Person layout with data aggregation patterns
- [_plugins/cb_page_gen.rb](_plugins/cb_page_gen.rb) - Page generation logic and filtering
- [_plugins/cb_helpers.rb](_plugins/cb_helpers.rb) - Icon system and theme helpers
- [_config.yml](_config.yml) - Site configuration and page generation settings
- [_data/theme.yml](_data/theme.yml) - OHD and theme configuration options
- [Claude.md](Claude.md) - Comprehensive technical documentation of the framework
