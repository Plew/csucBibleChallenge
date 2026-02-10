import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "selectAll", "userCheckbox", "removeBtn" ]

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.userCheckboxTargets.forEach(cb => cb.checked = checked)
    this.updateRemoveButton()
  }

  toggleOne() {
    const allChecked = this.userCheckboxTargets.every(cb => cb.checked)
    this.selectAllTarget.checked = allChecked
    this.updateRemoveButton()
  }

  updateRemoveButton() {
    const anyChecked = this.userCheckboxTargets.some(cb => cb.checked)
    this.removeBtnTarget.style.display = anyChecked ? "" : "none"
  }

  confirmRemove(event) {
    const checkedCount = this.userCheckboxTargets.filter(cb => cb.checked).length
    if (!confirm(`Remove ${checkedCount} user(s) from their groups?`)) {
      event.preventDefault()
    }
  }
}
