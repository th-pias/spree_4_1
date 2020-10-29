namespace :init do
  desc "TODO"
  task demo: :environment do
    %w[suresh mahabub].each do |db_name|
      #convert name to postgres friendly name
      db_name.gsub!('-','_')

      initializer = SpreeShared::TenantInitializer.new(db_name)
      puts "Creating database: #{db_name}"
      initializer.create_database
      puts "Loading seeds & sample data into database: #{db_name}"
      Apartment::Tenant.switch(db_name) do

        email = "spree@example.com"
        password = "spree123"

        unless Spree::User.find_by_email(email)
          admin = Spree::User.create!(:password => password,
                                     :password_confirmation => password,
                                     :email => email,
                                     :login => email)

          role = Spree::Role.find_or_create_by!(name: "admin")
          admin.role_users.create!(role: role)
        end

        store = Spree::Store.find_or_create_by!(
            name: db_name.titleize,
            url: "#{db_name}.syftet.com",
            mail_from_address: 'zikoku07@gmail.com',
            code: db_name,
            default_currency: 'USD'
        )

        CsvParser.process
      end

      initializer.create_admin

      puts "Bootstrap completed successfully"
    end
  end

end
