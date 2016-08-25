Talkable.configure do |config|
  # site slug takes form ENV["TALKABLE_SITE_SLUG"]
  config.site_slug  = 'spree-example'

  # api key takes from ENV["TALKABLE_API_KEY"]
  # config.api_key  = 'YOUR-API-KEY-GOES-HERE'
end

Spree::Order.state_machine.after_transition to: :complete, do: :register_at_talkable

Spree::Order.class_eval do
  def register_at_talkable
    Talkable::API::Origin.create(Talkable::API::Origin::PURCHASE, talkable_params)
  end

  def talkable_params
    {
      email: email,
      order_number: number,
      subtotal: total,

      shipping_zip: ship_address&.zipcode,
      shipping_address: [
        ship_address&.address1,
        ship_address&.address2,
        ship_address&.city,
        ship_address&.state_name,
        ship_address&.zipcode,
        ship_address&.country&.name,
      ].reject(&:blank?).join(', '),
      coupon_code: promotions.map(&:code),
      customer_id: user_id,
      order_date: completed_at.iso8601,
      ip_address: last_ip_address,

      items: line_items.map do |item|
        {
          price: item.price,
          quantity: item.quantity,
          product_id: item.variant.sku,
        }
      end
    }
  end
end

Spree::OrdersController.class_eval do
  skip_before_action :load_talkable_offer, only: [:show]

  alias_method :original_show, :show

  def show
    original_show
    origin = Talkable.register_purchase(
      @order.talkable_params.merge(campaign_tags: 'post-purchase')
    )
    @offer ||= origin&.offer
  end
end
