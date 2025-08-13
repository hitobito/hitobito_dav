# frozen_string_literal: true

#  Copyright (c) 2025 Deutscher Alpenverein. This file is part of
#  hitobito_dav and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dav.

require Rails.root.join("db", "seeds", "support", "group_seeder")

seeder = GroupSeeder.new

root = Group.roots.first
srand(42)

def seed_club_hut(sektion_id, name, navision_id)
  sektions_funktionaere = Group::SektionsFunktionaere.find_or_create_by!(parent_id: sektion_id)
  kommissionen = Group::SektionsKommissionen.find_or_create_by!(parent_id: sektions_funktionaere.id)
  Group::SektionsKommissionHuetten.find_or_create_by!(parent_id: kommissionen.id, name: "Hüttenkommission")
  clubhuetten = Group::SektionsClubhuetten.find_or_create_by!(parent_id: sektions_funktionaere.id)
  Group::SektionsClubhuette.seed(:name, :parent_id, {
    name: name,
    navision_id: navision_id,
    parent: clubhuetten
  })
end

def seed_section_hut(sektion, name, navision_id)
  sektions_funktionaere = Group::SektionsFunktionaere.find_or_create_by!(parent_id: sektion.id)
  kommissionen = Group::SektionsKommissionen.find_or_create_by!(parent_id: sektions_funktionaere.id)
  Group::SektionsKommissionHuetten.find_or_create_by!(parent_id: kommissionen.id, name: "Hüttenkommission")
  sektionshuetten = Group::Sektionshuetten.find_or_create_by!(parent_id: sektions_funktionaere.id)
  Group::Sektionshuette.seed(:name, :parent_id, {
    name: name,
    navision_id: navision_id,
    parent: sektionshuetten
  })
end

if root.address.blank?
  root.update(seeder.group_attributes)
  root.default_children.each do |child_class|
    child_class.first.update(seeder.group_attributes)
  end
end

Group::Geschaeftsstelle.seed_once(:parent_id, {
  parent_id: root.id
})

Group::Geschaeftsleitung.seed_once(:parent_id, {
  parent_id: root.id
})

Group::ExterneKontakte.seed_once(:name, :parent_id, {
  name: "Externe Kontakte",
  parent_id: root.id
})

Group::ExterneKontakte.seed_once(:name, :parent_id, {
  name: "Autoren",
  parent_id: Group::ExterneKontakte.find_by(name: "Externe Kontakte").id
})

Group::ExterneKontakte.seed_once(:name, :parent_id, {
  name: "Druckereien",
  parent_id: Group::ExterneKontakte.find_by(name: "Externe Kontakte").id
})

sections_subset = DavSections.sections
  .select { |row| row["name"] =~ /^Sektion/ }
  .group_by { |row| row["name"][/\s(\w)/, 1] }.except(nil)
  .sort_by { |key, _| key }
  .take(5)
  .map { |_, rows| rows.min_by { |row| row["id"] } }

Group::Sektion.seed_once(:id, sections_subset)

# Sektion Aachen
["Anton-Renk-Hütte", "Haus Rohren"].each do |hut_name|
  seed_club_hut(1, hut_name, nil)
end

# Sektion Bad Aibling
seed_club_hut(4, "Aiblinger Hütte", nil)

# Sektion Celle
seed_club_hut(49, "Celler Hütte Hohen Tauern", nil)

# Sektion Darmstadt-Starkenburg
["Felsberghütte", "Starkenburgerhütte", "Darmstädterhütte"].each do |hut_name|
  seed_club_hut(53, hut_name, nil)
end

# Sektion Ebersberg-Grafing
["Schneelahner Hütte", "Meißner Haus"].each do |hut_name|
  seed_club_hut(64, hut_name, nil)
end

Group.rebuild!
