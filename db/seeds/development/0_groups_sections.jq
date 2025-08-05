# Use this jq script to transform the Bundesverband_Sektionen.json to the format needed for the seeds:
#
# Usage: jq -f 0_groups_sections.jq Bundesverband_Sektionen.json > 0_groups_sections.json

.data | map({
    id: .sectionNumber | tonumber,
    parent_id: 0,
    name: .sectionNameShort,
    layer_group_id: .sectionNumber | tonumber,
    street: .contactData.postal[0].address,
    zip_code: .contactData.postal[0].zipCode,
    town: .contactData.city,
    foundation_year: 0,
    section_canton: "",
    language: "DE"
})
