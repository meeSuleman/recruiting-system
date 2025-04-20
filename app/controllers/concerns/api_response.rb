# app/controllers/concerns/api_response.rb
module ApiResponse
  extend ActiveSupport::Concern

  def success_response(message = nil, data = nil)
    response = {
      message: message,
      status: "success",
      data: data
    }.compact

    render json: response, status: :ok
  end

  def error_response(message = nil, error = nil, status: :bad_request)
    response = {
      status: "error",
      message: message,
      error: error
    }.compact

    render json: response, status: status
  end
end
