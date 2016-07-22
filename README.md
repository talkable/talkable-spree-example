## README

This README has step by step instructions how to integrate talkable referral platform into your `spree` store.

## Getting started

Add `talkable` gem into your `Gemfile`:

```ruby
gem 'talkable'
```

Run the `bundle install` command to install it.

Next, you need to add Talkable middleware into your `application.rb` file:

```ruby
config.middleware.use Talkable::Middleware
```

Create a file `config/initializers/talkable.rb` and configure gem:

```ruby
Talkable.configure do |config|
  config.site_slug  = 'YOUR-SITE-SLUG-AT-TALKABLE-COM'
  config.api_key    = 'YOUR-API-KEY-AT-TALKABLE-COM'
end
```

by default this configuration takes from environment variables `ENV["TALKABLE_SITE_SLUG"]` and `ENV["TALKABLE_API_KEY"]`.

Modify your state machine by additional action after comlete state:

```ruby
Spree::Order.state_machine.after_transition to: :complete, do: :register_at_talkable
```

Add `register_at_talkable` method to your `Spree::Order` model:

```ruby
Spree::Order.class_eval do
  def register_at_talkable
    Talkable::API::Origin.create(Talkable::API::Origin::PURCHASE, talkable_params)
  end

  protected

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
```

