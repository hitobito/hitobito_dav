class DbMitgliederSeeder
  def initialize(group, amount)
    @group = group
    @layer = group.layer_group
    @amount = amount
    @seed_amount = @amount - current_member_count
  end

  def seed
    return unless @seed_amount > 0

    puts "Seeding #{@seed_amount} members for #{@layer.name}"
    max_person_id = Person.maximum(:id)
    (1..@seed_amount).each_slice(100000) do |batch|
      puts "  Inserting batch #{batch.first}..#{batch.last}..."
      people_result = Person.insert_all!(people_attributes(batch, max_person_id))
      Role.insert_all!(role_attributes(people_result.rows.flatten))
    end
  end

  private

  def current_member_count
    @group.roles.with_inactive.where(type: "Group::SektionsMitglieder::Mitglied").count
  end

  def people_attributes(batch, starting_index)
    batch.map do |i|
      num = starting_index + i
      {
        first_name: num.to_s,
        last_name: @layer.name,
        email: "#{num}@example.com",
        created_at: Time.now,
        updated_at: Time.now,
        confirmed_at: Time.now,
        birthday: rand(18..67).years.ago
      }
    end
  end

  def role_attributes(people_ids)
    people_ids.map do |person_id|
      {
        person_id: person_id,
        group_id: @group.id,
        type: "Group::SektionsMitglieder::Mitglied",
        start_on: Date.today - rand(1000).days,
        end_on: 10.years.from_now,
        beitragskategorie: "adult",
        created_at: Time.now,
        updated_at: Time.now
      }
    end
  end
end
