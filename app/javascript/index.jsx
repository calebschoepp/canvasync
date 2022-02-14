// Entrypoint for React app
import React from "react";
import { render } from "react-dom";
import App from "./components/App";
import "./channels"


document.addEventListener("DOMContentLoaded", () => {
    render(
        <App />,
        document.getElementById("root")
    );
});