import { Controller } from "@hotwired/stimulus"

// Контроллер для страницы оплаты
export default class extends Controller {
  static targets = ["cardNumber", "expiry", "cvv", "submitButton"]

  connect() {
    console.log("Payment controller connected")
  }

  formatCardNumber(event) {
    let value = event.target.value.replace(/\s/g, '')

    // Разрешаем только цифры
    value = value.replace(/\D/g, '')

    // Форматируем по 4 цифры
    const parts = value.match(/.{1,4}/g)
    event.target.value = parts ? parts.join(' ') : ''
  }

  formatExpiry(event) {
    let value = event.target.value.replace(/\D/g, '')

    if (value.length >= 2) {
      value = value.slice(0, 2) + '/' + value.slice(2, 4)
    }

    event.target.value = value
  }

  async submit(event) {
    event.preventDefault()

    if (!this.validateForm()) {
      return
    }

    // Показываем индикатор загрузки
    const originalText = this.submitButtonTarget.textContent
    this.submitButtonTarget.textContent = 'Обработка платежа...'
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.style.opacity = '0.7'

    try {
      // В продакшене здесь будет интеграция с CloudPayments
      // Пока просто отправляем форму
      event.target.submit()
    } catch (error) {
      console.error('Payment error:', error)
      alert('Ошибка при обработке платежа. Попробуйте еще раз.')

      // Восстанавливаем кнопку
      this.submitButtonTarget.textContent = originalText
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.style.opacity = '1'
    }
  }

  validateForm() {
    const cardNumber = this.cardNumberTarget.value.replace(/\s/g, '')
    const expiry = this.expiryTarget.value
    const cvv = this.cvvTarget.value

    // Проверка номера карты (должно быть 16 цифр)
    if (cardNumber.length !== 16) {
      alert('Неверный номер карты')
      this.cardNumberTarget.focus()
      return false
    }

    // Проверка срока действия (MM/YY)
    const expiryRegex = /^(0[1-9]|1[0-2])\/\d{2}$/
    if (!expiryRegex.test(expiry)) {
      alert('Неверный формат срока действия (MM/YY)')
      this.expiryTarget.focus()
      return false
    }

    // Проверка CVV (3 цифры)
    if (cvv.length !== 3) {
      alert('Неверный CVV код')
      this.cvvTarget.focus()
      return false
    }

    return true
  }
}
