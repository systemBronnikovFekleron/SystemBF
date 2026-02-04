import { Controller } from "@hotwired/stimulus"

// Контроллер для страницы оформления заказа
export default class extends Controller {
  static targets = ["paymentMethod", "submitButton", "walletWarning"]

  connect() {
    console.log("Checkout controller connected")
    this.checkPaymentMethod()
  }

  selectPaymentMethod(event) {
    // Обновляем стили для выбранного метода оплаты
    const labels = this.element.querySelectorAll('.payment-method')
    labels.forEach(label => {
      if (label.contains(event.target)) {
        label.style.borderColor = 'var(--primary)'
        label.style.background = 'rgba(79, 70, 229, 0.1)'
      } else {
        label.style.borderColor = 'rgba(255,255,255,0.1)'
        label.style.background = 'var(--surface)'
      }
    })

    this.checkPaymentMethod()
  }

  checkPaymentMethod() {
    const selectedMethod = this.paymentMethodTargets.find(radio => radio.checked)

    if (selectedMethod?.value === 'wallet' && this.hasWalletWarningTarget) {
      // Если выбран кошелек но недостаточно средств, показываем предупреждение
      this.walletWarningTarget.style.display = 'block'
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.style.opacity = '0.5'
      this.submitButtonTarget.style.cursor = 'not-allowed'
    } else {
      if (this.hasWalletWarningTarget) {
        this.walletWarningTarget.style.display = 'none'
      }
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.style.opacity = '1'
      this.submitButtonTarget.style.cursor = 'pointer'
    }
  }
}
