require "pagy/extras/metadata"
require "pagy/extras/overflow"

# Pagy configuration
Pagy::DEFAULT[:items] = 12     # items per page
Pagy::DEFAULT[:overflow] = :empty # handling overflow with empty results
