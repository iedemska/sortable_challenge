require 'json'
require 'set'

def print_result_hash_to_file(r_hash)
	output = File.open('results.txt', 'w')
	r_hash.each do |prod_name, listings_array|
		output.puts({"product_name" => prod_name, "listings" => listings_array}.to_json)
	end
end

def index_data(product, product_hash, models_hash, manufacturer_set)
	product_manufacturer = product["manufacturer"].downcase
	model = product["model"].tr('-','').downcase

	manufacturer_set.add(product_manufacturer)	

	product_hash[product_manufacturer] ||= {}
	product_hash[product_manufacturer][model] = product["product_name"]

	models_hash[product_manufacturer] ||= Set.new
	models_hash[product_manufacturer].add(model)

end

def listing_has_valid_manufacturer(listing, man_set)
	listing["manufacturer"].split.each do |word|
	formated_word = word.downcase
		return formated_word if man_set.member?(formated_word)
	end

	listing["title"].split.each do |word|
	formated_word = word.downcase
		return formated_word if man_set.member?(formated_word)
	end
	return nil
end

def format_title_word(word)
	word.tr('-,', '').downcase
end

def listing_has_valid_unique_model(listing, model_set)
	matched_models_set = Set.new()
	
	listing["title"].split.each do |word|
	formated_word = format_title_word(word)
		matched_models_set.add(formated_word) if model_set.member?(formated_word)
	end

	listing["manufacturer"].split.each do |word|
	formated_word = format_title_word(word)
		matched_models_set.add(formated_word) if model_set.member?(formated_word)
	end
	
	if matched_models_set.size == 1 
		return matched_models_set.take(1).first
	else 
		return nil
	end

end

def sort_listings_data(listing, prod_hash, mod_hash, man_set, res_hash)
	return unless manufacturer = listing_has_valid_manufacturer(listing, man_set)
	return unless model = listing_has_valid_unique_model(listing, mod_hash[manufacturer])

	res_hash[prod_hash[manufacturer][model]] ||= []
	res_hash[prod_hash[manufacturer][model]] << listing
end

def print_result_hash_to_file(r_hash)
	output = File.open('results.txt', 'w')
	r_hash.each do |prod_name, listings_array|
		output.puts({"product_name" => prod_name, "listings" => listings_array}.to_json)
	end
end


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
	sort_listings_data(listing, product_index_hash, models_hash, manufacturer_set, result_hash)
end

print_result_hash_to_file(result_hash)
