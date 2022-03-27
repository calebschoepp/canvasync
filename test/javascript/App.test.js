/**
 * @jest-environment jsdom
 */

import React from "react";
import renderer from "react-test-renderer";
import App from "../../app/javascript/components/App";
import { createConsumer } from "@rails/actioncable";

jest.mock("@rails/actioncable", () => {
  return {
    createConsumer: jest.fn().mockImplementation(() => {
      return {};
    }),
  };
});

beforeEach(() => {
  // Clear all instances and calls to constructor and all methods:
  createConsumer.mockClear();

  window.participantLayers = [];
  window.ownerLayers = [];
});

it("renders correctly", () => {
  const app = renderer.create(<App />).toJSON();
  expect(app).toMatchSnapshot();
});
