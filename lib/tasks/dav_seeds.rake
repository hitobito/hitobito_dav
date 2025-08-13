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

      Group::Sektion.all.find_each do |sektion|
        SacSectionMembershipConfig.seed_once(
          :valid_from, :group_id,
          group_id: sektion.id,
          valid_from: "2024",
          section_fee_adult: 42,
          section_fee_family: 84,
          section_fee_youth: 21,
          section_entry_fee_adult: 10,
          section_entry_fee_family: 20,
          section_entry_fee_youth: 5,
          bulletin_postage_abroad: 13,
          sac_fee_exemption_for_honorary_members: false,
          section_fee_exemption_for_honorary_members: true,
          sac_fee_exemption_for_benefited_members: true,
          section_fee_exemption_for_benefited_members: false,
          reduction_amount: 10,
          reduction_required_membership_years: 50,
          reduction_required_age: 42
        )

        MailingList.seed_once(:group_id, :internal_key, {
          name: "Sektionsbulletin physisch",
          group_id: sektion.id,
          internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY
        })
        list = MailingList.find_by(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY, group_id: sektion.id)
        list.subscriptions.create!(subscriber: sektion, role_types: [Group::SektionsMitglieder::Mitglied])
      end
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

    desc "Seed common groups"
    task common_groups: :environment do
      root = Group.root

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
    end

    desc "Seed various data (event kinds, qualifications, membership configs etc.)"
    task various_data: :environment do
      basedir = HitobitoDav::Wagon.root.join("db", "seeds", "development")
      require basedir.join("2_course_compensation").to_s
      require basedir.join("3_event_kinds_and_qualifications").to_s
      require basedir.join("4_sac_membership_configs").to_s
      require basedir.join("6_termination_reasons").to_s
      require basedir.join("7_section_offerings").to_s
    end

    desc "Seed events for all sections"
    task events: :environment do
      require HitobitoDav::Wagon.root.join("db", "seeds", "development", "events").to_s
    end
  end
end
