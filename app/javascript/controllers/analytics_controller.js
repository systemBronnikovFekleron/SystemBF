import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="analytics"
export default class extends Controller {
  static values = {
    event: String,
    productId: String,
    productName: String,
    price: Number,
    currency: { type: String, default: 'RUB' },
    category: String,
    orderId: String,
    total: Number,
    items: Array
  }

  connect() {
    // Auto-track on connect if event is specified
    if (this.hasEventValue) {
      this.track()
    }
  }

  track() {
    if (typeof gtag === 'undefined') {
      console.warn('Google Analytics not loaded')
      return
    }

    const eventName = this.eventValue

    switch (eventName) {
      case 'view_item':
        this.trackViewItem()
        break
      case 'add_to_cart':
        this.trackAddToCart()
        break
      case 'purchase':
        this.trackPurchase()
        break
      case 'begin_checkout':
        this.trackBeginCheckout()
        break
      default:
        console.warn(`Unknown analytics event: ${eventName}`)
    }
  }

  // Track product view
  trackViewItem() {
    gtag('event', 'view_item', {
      currency: this.currencyValue,
      value: this.priceValue,
      items: [{
        item_id: this.productIdValue,
        item_name: this.productNameValue,
        item_category: this.categoryValue,
        price: this.priceValue,
        quantity: 1
      }]
    })

    console.log('[GA] View Item:', this.productNameValue)
  }

  // Track add to cart
  trackAddToCart() {
    gtag('event', 'add_to_cart', {
      currency: this.currencyValue,
      value: this.priceValue,
      items: [{
        item_id: this.productIdValue,
        item_name: this.productNameValue,
        item_category: this.categoryValue,
        price: this.priceValue,
        quantity: 1
      }]
    })

    console.log('[GA] Add to Cart:', this.productNameValue)
  }

  // Track purchase completion
  trackPurchase() {
    const items = this.hasItemsValue ? this.itemsValue : []

    gtag('event', 'purchase', {
      transaction_id: this.orderIdValue,
      value: this.totalValue,
      currency: this.currencyValue,
      items: items
    })

    console.log('[GA] Purchase:', this.orderIdValue, 'Total:', this.totalValue)
  }

  // Track checkout initiation
  trackBeginCheckout() {
    const items = this.hasItemsValue ? this.itemsValue : []

    gtag('event', 'begin_checkout', {
      currency: this.currencyValue,
      value: this.totalValue,
      items: items
    })

    console.log('[GA] Begin Checkout, Total:', this.totalValue)
  }

  // Manual tracking methods (can be called from other controllers)
  trackEvent(eventName, params = {}) {
    if (typeof gtag === 'undefined') return

    gtag('event', eventName, params)
    console.log('[GA] Event:', eventName, params)
  }

  // Track custom conversion
  trackConversion(conversionId, params = {}) {
    if (typeof gtag === 'undefined') return

    gtag('event', 'conversion', {
      'send_to': conversionId,
      ...params
    })
  }
}
