class ApplicationController < ActionController::API
  include Pagy::Backend
  include ExceptionHandler
  include ApiResponse
end
