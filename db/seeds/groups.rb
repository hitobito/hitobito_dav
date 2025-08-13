# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

def seed_magazin_abo(id, name, parent, title_de:, title_fr:, title_it:, title_en:)
  Group::AboMagazin.seed_once(:id) do |a|
    a.parent_id = parent.id
    a.id = id
    a.name = name
    a.self_registration_role_type = Group::AboMagazin::Neuanmeldung.sti_name
    a.translations = [
      Group::Translation.new(locale: "de", custom_self_registration_title: title_de),
      Group::Translation.new(locale: "fr", custom_self_registration_title: title_fr),
      Group::Translation.new(locale: "it", custom_self_registration_title: title_it),
      Group::Translation.new(locale: "en", custom_self_registration_title: title_en)
    ]
  end
end

require HitobitoDav::Wagon.root.join("db", "seeds", "support", "dav_sections").to_s
Group::SacCas.seed_once(:id, DavSections.dachverband)

# Set the next group ID to a value that is higher than the current maximum, but at
# least 10,000 to avoid collisions with the IDs of the section groups that will get imported later.
next_group_id = [Group.maximum(:id) + 1, 10_000].max
ActiveRecord::Base.connection.set_pk_sequence!(:groups, next_group_id)

Group::Abos.seed_once(:id, id: 1000, parent_id: Group.root.id)
abos = Group::Abos.find(1000)

Group::AboMagazine.seed_once(:id, id: 1001, parent_id: abos.id)
magazine = Group::AboMagazine.find(1001)

seed_magazin_abo(1002, "Magazin Panorama", magazine,
  title_de: "„Panorama“ Abo bestellen",
  title_fr: "S'abonner à la revue «Panorama»",
  title_it: "Abbonarsi a «Panorama»",
  title_en: "Subscribe to ‘Panorama’")

Group::AboTourenPortal.seed_once(:id) do |a|
  a.id = 1010
  a.parent_id = abos.id
  a.self_registration_role_type = "Group::AboTourenPortal::Abonnent"
end

Group::AboBasicLogin.seed_once(:id) do |a|
  a.id = 1020
  a.parent_id = abos.id
  a.self_registration_role_type = "Group::AboBasicLogin::BasicLogin"
  a.translations = [
    Group::Translation.new(locale: "de", custom_self_registration_title: "Kostenloses DAV-Konto erstellen"),
    Group::Translation.new(locale: "fr", custom_self_registration_title: "Créer un compte DAV gratuit"),
    Group::Translation.new(locale: "it", custom_self_registration_title: "Creare un account DAV gratuito"),
    Group::Translation.new(locale: "en", custom_self_registration_title: "Create a free DAV account")
  ]
end

Group::ExterneKontakte.seed_once(:id, id: 1100, parent_id: Group.root.id, name: "DAV Mitglieder / ehemalig")
