# frozen_string_literal: true

#  Copyright (c) 2025 Deutscher Alpenverein. This file is part of
#  hitobito_dav and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dav.

require Rails.root.join("db", "seeds", "support", "group_seeder")

seeder = GroupSeeder.new

root = Group.roots.first
srand(42)

def seed_club_hut(sektion, name, navision_id)
  sektions_funktionaere = Group::SektionsFunktionaere.find_or_create_by!(parent_id: sektion.id)
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

sections_file = HitobitoDav::Wagon.root.join("db", "seeds", "development", "0_groups_sections.json")
sections_data = JSON.load_file(sections_file).drop(1) # the first entry is for the root group
sections_data = sections_data.take(10) if ENV["CI"]
Group::Sektion.seed_once(:id, sections_data)

# seed_section_hut(matterhorn, "Matterhornbiwak", 99999942)
# seed_club_hut(uto, "Domhütte", 81)
# seed_club_hut(uto, "Spannorthütte", 255)
# seed_club_hut(uto, "Täschhütte", 265)
# seed_club_hut(bluemlisalp, "Blüemlisalphütte", 36)
# seed_club_hut(bluemlisalp, "Baltschiederklause", 25)
# seed_club_hut(bluemlisalp, "Stockhornbiwak", 258)
# seed_section_hut(bluemlisalp, "Ski- & Ferienhaus Obergestelen", 448786)
# seed_section_hut(bluemlisalp, "Sunnhüsi", 448785)

Group.rebuild!
