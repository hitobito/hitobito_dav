# frozen_string_literal: true

#  Copyright (c) 2025, Deutscher Alpenverein. This file is part of
#  hitobito_dav and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dav

class DavSections
  include Singleton

  attr_reader :entries

  JSON_FILE = HitobitoDav::Wagon.root.join("db", "seeds", "support", "dav_sections.json")

  def initialize
    @entries = JSON.parse(File.read(JSON_FILE))
  end

  def self.dachverband
    instance.entries.first.slice(*Group::SacCas.column_names).except("parent_id")
  end

  def self.sections = instance.entries.drop(1)
end
