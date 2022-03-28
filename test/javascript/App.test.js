/**
 * @jest-environment jsdom
 */

import React from "react";
import {act, render, fireEvent, waitFor, cleanup} from '@testing-library/react';
import App from "../../app/javascript/components/App";
// import { createConsumer } from "@rails/actioncable";

describe('react canvas app tests', () => {
  beforeEach(() => {
    window.notebookId = 1;
    window.notebookName = "Notebook Name";
    window.isOwner = true;
    window.ownerLayers = [];
    window.participantLayers = [];
    window.currentUser = 1;
    window.ownerId = 1;
    window.userNotebookId = 1;
    window.backgroundPdf = null;
  });

  afterEach(() => {
    jest.clearAllMocks();
    cleanup();
  });
  
  it("renders correctly", () => {
    const { container, queryAllByTestId } = render(<App />);
    expect(container).toMatchSnapshot();
    expect(queryAllByTestId(/canvasync-canvas-([0-9]+|null)-([0-9]+|null)/).length).toBe(0);
  });
  
  it("renders correctly with multiple owner layers", () => {
    window.ownerLayers = [{id: 1},{id: 2},{id: 3}];
    const { container, getAllByTestId } = render(<App />);
    expect(container).toMatchSnapshot();
    expect(getAllByTestId(/canvasync-canvas-([0-9]+|null)-([0-9]+|null)/).length).toBe(3);
  });

  it("renders correctly with multiple owner layers and participant layers", () => {
    window.ownerLayers = [{id: 1},{id: 2},{id: 3}];
    window.participantLayers = [{id: 4},{id: 5},{id: 6}];
    const { container, getAllByTestId } = render(<App />);
    expect(container).toMatchSnapshot();
    expect(getAllByTestId(/canvasync-canvas-([0-9]+|null)-([0-9]+|null)/).length).toBe(3);
  });
});
