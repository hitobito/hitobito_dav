# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require HitobitoDav::Wagon.root.join("db", "seeds", "development", "support", "sac_person_seeder")

puzzlers = [
  "Carlo Beltrame",
  "Matthias Viehweger",
  "Nils Rauch",
  "Oliver Dietschi",
  "Olivier Brian",
  "Pascal Zumkehr",
  "Thomas Ellenberger",
  "Tobias Stern"
]

devs = {
  "Andreas Rava" => "andreas.rava@example.com"
}
puzzlers.each do |puz|
  devs[puz] = "#{puz.split.last.downcase}@puzzle.ch"
end

seeder = SacPersonSeeder.new

seeder.seed_all_roles
seeder.update_mitglieder_role_dates
seeder.update_abonnent_role_dates
seeder.seed_families
seeder.seed_some_ehrenmitglieder_beguenstigt_roles

geschaeftsstelle = Group::Geschaeftsstelle.first
devs.each do |name, email|
  seeder.seed_developer(name, email, geschaeftsstelle, Group::Geschaeftsstelle::Admin)
end
