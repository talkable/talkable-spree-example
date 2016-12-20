class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :load_talkable_offer
  before_action :inject_talkable_offer

  protected

  def load_talkable_offer
    origin = Talkable.register_affiliate_member(email: current_spree_user&.email)
    @offer ||= origin&.offer
  end

  def inject_talkable_offer
    Deface::Override.new(
      virtual_path: "spree/layouts/spree_application",
      name: "talkable-offer",
      insert_before: "div#content",
      text: "<%= @offer&.advocate_share_iframe&.html_safe %>"
    )
  end

end
