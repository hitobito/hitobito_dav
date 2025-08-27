# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Passes::Sections::Logo < Export::Pdf::Section
  def render
    render_logo
  end

  def render_logo
    float do
      image(logo_path, at: [160, 180], width: 120)
    end
  end

  def logo_path
    logo = "dav-logo.png"

    image_path(logo)
  end

  def image_path(name)
    Wagons.find_wagon(__FILE__).root.join("app", "assets", "images", name)
  end
end
