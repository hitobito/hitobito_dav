# frozen_string_literal: true

#  Copyright (c) 2025, Deutscher Alpenverein. This file is part of
#  hitobito_dav and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dav

namespace :dav do
  namespace :seed do
    desc "Seed Demo data"
    task :demo, [:limit] => :environment do |_t, args|
      limit = args[:limit].present? ? Integer(args[:limit]) : 15
      Rake::Task["dav:seed:all_sections"].invoke(limit)
      [
        "dav:seed:common_groups",
        "dav:seed:various_data",
        "dav:seed:bazillion_people",
        "dav:seed:events"
      ].each do |task_name|
        Rake::Task[task_name].invoke
      end
    end

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

      seeder = DavPersonSeeder.new

      seeder.seed_all_roles
      seeder.update_mitglieder_role_dates
      seeder.update_abonnent_role_dates
      seeder.seed_families
      seeder.seed_some_ehrenmitglieder_beguenstigt_roles
    end

    desc "Seed common groups"
    task common_groups: :environment do
      root = Group.root

      Group::Geschaeftsstelle.seed_once(:parent_id, parent_id: root.id)
      Group::Geschaeftsleitung.seed_once(:parent_id, parent_id: root.id)
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

      unless Group::SacCasKurskader.exists?
        Group::SacCasKurskader.seed_once(:type, parent: Group.root)
      end

      unless Group::SacCasVerbaende.exists?
        Group::SacCasVerbaende.seed_once(:type, :parent_id, name: "Verbände & Organisationen", parent: Group.root)
      end

      unless Group::SacCasPrivathuetten.exists?
        Group::SacCasPrivathuetten.seed_once(:type, parent: Group.root)
      end
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
      require HitobitoDav::Wagon.root.join("db", "seeds", "development", "support", "sac_event_seeder")

      srand(42)

      seeder = SacEventSeeder.new

      unless Event.joins(:groups).where(groups: {id: Group.root.id}).exists?
        8.times do
          seeder.seed_event(Group.root.id, :course)
        end
        2.times do
          seeder.seed_event(Group.root.id, :course).update_column(:state, :assignment_closed)
        end
      end

      Group.where(type: [Group::Sektion, Group::Ortsgruppe].map(&:sti_name)).find_each do |group|
        next if Event.joins(:groups).where(groups: {id: group.id}).exists?

        10.times do
          seeder.seed_event(group.id, :tour)
        end
        2.times do
          seeder.seed_event(group.id, :course)
        end
        2.times do
          seeder.seed_event(group.id, :base)
        end
      end
    end

    # desc "Purge before load testing seeding: removes all sections and people"
    # task purge: :environment do
    #   PaperTrail.enabled = false
    #   groups = Group.where(type: [Group::Sektion.sti_name, Group::Ortsgruppe.sti_name])
    #   Group::Translation.where(group_id: groups.pluck(:id)).delete_all
    #   groups.delete_all
    #   Person.delete_all
    # end

    desc "Seed for load testing"
    task load_testing: :environment do |_t, args|
      PaperTrail.enabled = false
      Person.skip_callback :update, :after, :schedule_duplicate_locator

      # Rake::Task["dev:local:admin"].invoke
      # Rake::Task["dav:seed:common_groups"].invoke
      # Rake::Task["dav:seed:various_data"].invoke
      # Rake::Task["dav:seed:all_sections"].invoke

      %w[sac_person_seeder loadtest_person_seeder db_mitglieder_seeder].each do |file|
        require HitobitoDav::Wagon.root.join("db", "seeds", "development", "support", file).to_s
      end

      # seeder = LoadtestPersonSeeder.new
      # seeder.seed_all_roles

      max_amount = 2_000_000
      Group::SektionsMitglieder.includes(:layer_group).each do |group|
        amount = [
          (max_amount.to_f / group.layer_group_id).to_i,
          10_000
        ].max

        DbMitgliederSeeder.new(group, amount).seed
      end

      puts "\e[32mDone\e[0m"
    end

    desc "Enable tours on all sections"
    task enable_tours: :environment do
      Group.where(type: [Group::Sektion.sti_name, Group::Ortsgruppe.sti_name]).find_each do |group|
        group.update!(tours_enabled: true)
      end
    end

    desc "Disable tours on all sections"
    task disable_tours: :environment do
      Group.where(type: [Group::Sektion.sti_name, Group::Ortsgruppe.sti_name]).find_each do |group|
        group.update!(tours_enabled: false)
      end
    end
  end
end
