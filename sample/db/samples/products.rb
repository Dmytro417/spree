require 'csv'

Spree::Sample.load_sample('tax_categories')
Spree::Sample.load_sample('option_types')
Spree::Sample.load_sample('taxons')
Spree::Sample.load_sample('stores')

default_shipping_category = Spree::ShippingCategory.find_or_create_by!(name: 'За замовчуванням')
clothing_tax_category = Spree::TaxCategory.find_or_create_by!(name: 'Одяг')

color = Spree::OptionType.find_by!(name: 'color')
length = Spree::OptionType.find_by!(name: 'length')
size = Spree::OptionType.find_by!(name: 'size')

PRODUCTS = CSV.read(File.join(__dir__, 'variants.csv')).map do |(parent_name, taxon_name, product_name, _color_name)|
  [parent_name, taxon_name, product_name]
end.uniq

PRODUCTS.each do |(parent_name, taxon_name, product_name)|
  parent = Spree::Taxon.find_by!(name: parent_name)
  taxon = parent.children.find_by!(name: taxon_name)
  next if Spree::Product.where(name: product_name.titleize).any?

  Spree::Product.create!(name: product_name.titleize) do |product|
    product.price = rand(10...100) + 0.99
    product.description = FFaker::LoremUA.paragraph
    product.available_on = Time.zone.now
    product.make_active_at = Time.zone.now
    product.status = 'active'
    product.option_types =
      if parent_name == 'Жінки' && %w[Сукні Спідниці].include?(taxon_name)
        [color, length, size]
      else
        [color, size]
      end
    product.shipping_category = default_shipping_category
    product.tax_category = clothing_tax_category
    product.sku = [taxon_name.delete(' '), product_name.delete(' '), product.price].join('_')
    product.taxons << parent unless product.taxons.include?(parent)
    product.taxons << taxon unless product.taxons.include?(taxon)
    product.stores = Spree::Store.all
  end
end

Spree::Taxon.where(name: ['Бестселлери', "Новий" 'В трендах', 'Вуличний стиль', 'Літній розпродаж', "Літо #{Date.today.year}", "Знижка 30%"]).each do |taxon|
  next if taxon.products.any?

  taxon.products << Spree::Product.all.sample(30)
end
