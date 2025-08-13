# frozen_string_literal: true

#  Copyright (c) 2025, Deutscher Alpenverein. This file is part of
#  hitobito_dav and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dav

namespace :dav do
  namespace :seed do
    desc "Seed all DAV sections, optionally limit the amount: `dav:seed:all_sections[42]"
    task :all_sections, [:limit] => :environment do |_t, args|
      require HitobitoDav::Wagon.root.join("db", "seeds", "support", "dav_sections").to_s

      limit = Integer(args[:limit]) if args[:limit].present?
      sections = limit ? DavSections.sections.take(limit) : DavSections.sections
      Group::Sektion.seed_once(:id, sections)
    end

    desc "Seed a bazillion of people in all groups"
    task bazillion_people: :environment do
      require HitobitoDav::Wagon.root.join("db", "seeds", "development", "support", "sac_person_seeder").to_s

      seeder = Class.new(SacPersonSeeder) do
        def seed_role_type(group, role_type)
          # Skip seeding roles of given type if the group already has such roles
          return if group.roles.with_inactive.exists?(type: role_type.sti_name)

          count = amount(role_type)
          count.times do
            p = Person.seed(:email, person_attributes(role_type)).first
            seed_accounts(p, count == 1)
            seed_role(p, group, role_type)
          end
        end

        def update_role_dates(role_class)
          super
        rescue ActiveRecord::RecordInvalid => e
          puts "Error updating role dates for #{role_class.name}[#{e.record.id}]: #{e.record.errors.full_messages.join(", ")}"
        end
      end.new

      seeder.seed_all_roles
      seeder.update_mitglieder_role_dates
      seeder.update_abonnent_role_dates
      seeder.seed_families
      seeder.seed_some_ehrenmitglieder_beguenstigt_roles
    end
  end
end
