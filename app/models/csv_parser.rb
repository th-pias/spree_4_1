class CsvParser
  require 'csv'
  require 'open-uri'

  TAXONOMY_ATTRIBUTES = { name: I18n.t('spree.taxonomy_categories_name') }

  def self.process
    csv_text = File.read("Grocery_store_catalog_india.csv")
    csv = CSV.parse(csv_text, :headers => true)
    csv.each_with_index do |row, index|
      # break if index >= 20
      process_row(row) if row['sku'].present?
    end
  end

  def self.process_row(row)
    taxonomy = Spree::Taxonomy.where(TAXONOMY_ATTRIBUTES).first_or_create!
    taxonomy_taxon = Spree::Taxon.where(TAXONOMY_ATTRIBUTES).first_or_create!

    category = create_category(taxonomy, taxonomy_taxon, row['category_name_1']) if row['category_name_1'].present?
    sub_category = create_category(taxonomy, category.present? ? category : taxonomy_taxon, row['category_name_2']) if row['category_name_2'].present?

    create_product(category, sub_category, row['name'], row['price'], row['description'], row['sku'], row['image_1'])
  end

  def self.create_category(taxonomy, category, taxon_name)
    taxon = category.children.where(name: taxon_name).first_or_create!
    taxon.permalink = taxon.permalink.gsub('categories/', '')
    taxon.taxonomy = taxonomy
    taxon.save!

    taxon
  end

  def self.create_product(category, sub_category, product_name, price, description, sku, image)
    default_shipping_category = Spree::ShippingCategory.find_or_create_by!(name: 'Default')
    clothing_tax_category = Spree::TaxCategory.where(name: 'Bakery').first_or_create!
    location = Spree::StockLocation.find_or_create_by!(name: 'default')

    product = Spree::Product.where(name: product_name.titleize).first_or_create! do |product|
      product.price = price
      product.description = description
      product.available_on = Time.zone.now
      # product.option_types = [color, size]
      product.shipping_category = default_shipping_category
      product.tax_category = clothing_tax_category
      product.sku = sku
      product.taxons << category unless product.taxons.include?(category)
      if sub_category.present?
        product.taxons << sub_category unless product.taxons.include?(sub_category)
      end
    end

    if image.present?
      p '##############################'
      p image
      downloaded_image = open(image)
      product_image = product.images.build(alt: "", viewable_id: product.id, viewable_type: 'Spree::Variant')
      product_image.attachment.attach(io: downloaded_image, filename: "#{product_name.parameterize}.jpg", content_type: 'image/jpg')
      product_image.save!
    end

    product.master.stock_items.find_by!(stock_location: location).update!(count_on_hand: 10)
  end
end
