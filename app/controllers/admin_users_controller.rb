class AdminUsersController < ApplicationController
  before_action :authenticate_admin_user!
  def index

  end

  def create_store
    if params[:shop_name].present? && params[:admin_email].present? && params[:admin_password].present?
      CreateStore.make_store(params[:shop_name], params[:admin_email], params[:admin_password])
      url = "http://" + params[:shop_name] + ".armoiar.com"
      redirect_to url, flash: {success: "Successfully created a #{params[:shop_name]}"}
    else
      redirect_to admin_users_index_path,  flash: {error: "Failed to create a Shop"}
    end
  end
end
