import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="wallet"
export default class extends Controller {
  static targets = ["modal", "amountInput"]

  openModal(event) {
    event.preventDefault()
    const modal = document.getElementById('deposit-modal')
    if (modal) {
      modal.style.display = 'flex'
      // Focus on custom amount input
      const input = document.getElementById('custom-amount')
      if (input) {
        setTimeout(() => input.focus(), 100)
      }
    }
  }

  closeModal(event) {
    event.preventDefault()
    const modal = document.getElementById('deposit-modal')
    if (modal) {
      modal.style.display = 'none'
      // Reset form
      const form = modal.querySelector('form')
      if (form) form.reset()
      // Deselect all amount options
      document.querySelectorAll('.amount-option').forEach(btn => {
        btn.classList.remove('selected')
        btn.style.borderColor = 'var(--gray-200)'
        btn.style.background = 'white'
      })
    }
  }

  selectAmount(event) {
    event.preventDefault()
    const button = event.currentTarget
    const amount = button.dataset.amount

    // Update input
    const input = document.getElementById('custom-amount')
    if (input) {
      input.value = amount
    }

    // Visual feedback
    document.querySelectorAll('.amount-option').forEach(btn => {
      btn.classList.remove('selected')
      btn.style.borderColor = 'var(--gray-200)'
      btn.style.background = 'white'
    })

    button.classList.add('selected')
    button.style.borderColor = 'var(--blue-500)'
    button.style.background = 'var(--blue-50)'
  }

  updateAmount(event) {
    // Deselect quick amount buttons when custom input is used
    document.querySelectorAll('.amount-option').forEach(btn => {
      btn.classList.remove('selected')
      btn.style.borderColor = 'var(--gray-200)'
      btn.style.background = 'white'
    })
  }

  submitDeposit(event) {
    const input = document.getElementById('custom-amount')
    const amount = parseInt(input.value)

    if (!amount || amount < 100) {
      event.preventDefault()
      alert('Минимальная сумма пополнения: 100 ₽')
      return false
    }

    // Allow form submission to continue
    return true
  }

  // Close modal when clicking outside
  connect() {
    const modal = document.getElementById('deposit-modal')
    if (modal) {
      modal.addEventListener('click', (event) => {
        if (event.target === modal) {
          this.closeModal(event)
        }
      })

      // Close on Escape key
      document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && modal.style.display === 'flex') {
          this.closeModal(event)
        }
      })
    }
  }
}
