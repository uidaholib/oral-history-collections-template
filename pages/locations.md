---
title: Places
layout: cloud
permalink: /locations.html
# Default locations page is configured in "_data/theme.yml"
# leave cloud-fields as "site.data.theme.locations-fields"
# a cloud visualization will be added below the content in this file
cloud-fields: site.data.theme.locations-fields
button: outline-palouse
---

## Places

Use this word cloud visualization to browse places.
Word size is determined by frequency and all words link to a corresponding collection search.

{% capture places_note %}**Looking for where a place comes up in a conversation?** This page points you to *whole interviews* about a place. To find the *exact moments* when people mention a town, ridge, or other place, use the [Topic Index A–Z]({{ '/subject-list.html' | relative_url }}) or the **Locations** category of the [Topic Map]({{ '/subject-map.html' | relative_url }}). {% endcapture %}
{% include feature/alert.html text=places_note color="info" align="start" %}
