# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module MembershipVerifyHelper
  def file_locale = %i[de fr it].include?(I18n.locale) ? I18n.locale : :de

  def localized_sponsor_logo_path
    "membership_verify_partner_ad_#{file_locale.downcase}.jpg"
  end

  def localized_sac_sponsors_url
    {
      de: "https://www.alpenverein.de/verband/sponsoren-partner",
      fr: "https://www.alpenverein.de/verband/sponsoren-partner",
      it: "hhttps://www.alpenverein.de/verband/sponsoren-partner"
    }[file_locale]
  end
end
