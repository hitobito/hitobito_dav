class LoadtestPersonSeeder < SacPersonSeeder
  def amount(role_type, layer_group_id)
    case role_type.name.demodulize
    when "Mitglied", "Beguenstigt", "Ehrenmitglied", "MitgliedZusatzsektion", "NeuanmeldungZusatzsektion" then 0
    when "Neuanmeldung" then layer_group_id
    else 1
    end
  end

  def seed_role_type(group, role_type)
    count = amount(role_type, group.layer_group_id)
    existing_count = group.roles.with_inactive.where(type: role_type.sti_name).count
    return if existing_count >= count

    (count - existing_count).times do
      p = Person.seed(:email, person_attributes(role_type)).first
      seed_accounts(p, count == 1)
      seed_role(p, group, role_type)
    end
  end

  def seed_all_roles
    Group.root.self_and_descendants.sort_by { [_1.layer_group_id, _1.id] }.each do |group|
      group.role_types.reject(&:restricted?).each do |role_type|
        seed_role_type(group, role_type)
      end
    end
  end
end
