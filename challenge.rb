require 'json'
require 'set'

def index_data(product, product_hash, models_hash, manufacturer_set)
	product_manufacturer = product["manufacturer"].downcase
	model = product["model"].tr('-','').downcase

	manufacturer_set.add(product_manufacturer)

	product_hash[product_manufacturer] ||= {}
	product_hash[product_manufacturer][model] = product["product_name"]

	models_hash[product_manufacturer] ||= Set.new
	models_hash[product_manufacturer].add(model)

end

def manufacturer_for_listing(listing, man_set)
	find_manufacturer_in_set(listing["manufacturer"], man_set) ||
	find_manufacturer_in_set(listing["title"], man_set)
end

def find_manufacturer_in_set(words_string, man_set)
	words_string.downcase.split.find{|word| man_set.member?(word)}
end

def uniq_model_for_listing(listing, model_set)
	matched_models_set = Set.new()
	
	matched_models_set.merge(find_model_in_set(listing["title"], model_set))
	matched_models_set.merge(find_model_in_set(listing["manufacturer"], model_set))
	
	matched_models_set.size == 1 ? matched_models_set.to_a.first : nil
end

def find_model_in_set(model_string, mod_set)
	model_string.downcase.split.map{|w| w.tr('-,', '')}
	 .find_all{|word| mod_set.member?(word)}
end

def group_listings(listing, prod_hash, mod_hash, man_set, res_hash)
	return unless manufacturer = manufacturer_for_listing(listing, man_set)
	return unless model = uniq_model_for_listing(listing, mod_hash[manufacturer])

	res_hash[prod_hash[manufacturer][model]] ||= []
	res_hash[prod_hash[manufacturer][model]] << listing
end

def	output_results(r_hash)
	output = File.open('results.txt', 'w')
	r_hash.each do |prod_name, listings_array|
		output.puts({"product_name" => prod_name, "listings" => listings_array}.to_json)
	end
end

def main
	product_index_hash = {}
	models_hash = {}
	manufacturer_set = Set.new
	result_hash = {}

	File.readlines('products.txt').each do |json_string|
		product = JSON.parse(json_string)
		index_data(product,product_index_hash, models_hash, manufacturer_set)
	end

	File.readlines('listings.txt').each do |string|
		listing = JSON.parse(string)
		group_listings(listing, product_index_hash, models_hash, manufacturer_set, result_hash)
	end

	output_results(result_hash)
end

if __FILE__ == $0
	main
end
