// Mandated by FR-8: Open.Notebook through FR-12: ParticipantEdit.Canvas

// Entrypoint for React app
import React from "react";
import { render } from "react-dom";
import App from "./components/App";

document.addEventListener("DOMContentLoaded", () => {
  render(
    <App />,
    document.getElementById("root")
  );
});