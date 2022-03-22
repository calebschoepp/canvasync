import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["query"];

  connect() {
  }

  update() {
    // Call search endpoint with search query and render links
    fetch(`/search?query=${this.query}`)
        .then(response => response.text())
        .then(html => this.element.querySelector("#results").innerHTML = html)
  }

  get query() {
    return this.queryTarget.value;
  }
}
