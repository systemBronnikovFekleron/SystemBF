import { Controller } from "@hotwired/stimulus"

// Контроллер для редактирования профиля
export default class extends Controller {
  static targets = ["form"]

  connect() {
    console.log("Profile edit controller connected")
  }

  toggleEdit(event) {
    event.preventDefault()

    if (this.formTarget.style.display === "none" || this.formTarget.style.display === "") {
      // Показываем форму
      this.formTarget.style.display = "block"

      // Плавное появление
      setTimeout(() => {
        this.formTarget.style.opacity = "1"
        this.formTarget.style.transform = "translateY(0)"
      }, 10)

      // Прокручиваем к форме
      this.formTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
    } else {
      // Скрываем форму
      this.formTarget.style.opacity = "0"
      this.formTarget.style.transform = "translateY(-10px)"

      setTimeout(() => {
        this.formTarget.style.display = "none"
      }, 300)
    }
  }
}
