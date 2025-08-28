class DavPersonSeeder < SacPersonSeeder
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
end
