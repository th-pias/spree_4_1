class CreateStore
  #todo self.perform for better performance
  def self.make_store(store_name, admin_email, admin_password)
    #convert name to postgres friendly name
    store_name.gsub!('-','_')
    
    initializer = SpreeShared::TenantInitializer.new(store_name)
    
    
    puts "Creating database: #{store_name}"
    initializer.create_database
    puts "Loading seeds & sample data into database: #{store_name}"
    Apartment::Tenant.switch(store_name) do
    
      email = admin_email || "spree@example.com"
      password =  admin_password || "spree123"
      mail_from_address =  'zikoku07@gmail.com'
    
      unless Spree::User.find_by_email(email)
        admin = Spree::User.create!(:password => password,
                                    :password_confirmation => password,
                                    :email => email,
                                    :login => email)
    
        role = Spree::Role.find_or_create_by!(name: "admin")
        admin.role_users.create!(role: role)
      end
    
      store = Spree::Store.find_or_create_by!(
          name: store_name.titleize,
          url: "#{store_name}.syftet.com",
          mail_from_address: mail_from_address,
          code: store_name,
          default_currency: 'USD'
      )
    
      CsvParser.process
    end
    
    # initializer.create_admin
  end
end