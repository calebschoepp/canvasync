/**
 * @jest-environment jsdom
 */

import React from "react";
import {act, render, fireEvent, waitFor, cleanup} from '@testing-library/react';
import App from "../../app/javascript/components/App";
import { Notebook } from "../../app/javascript/components/notebook";
import { shallow } from "enzyme";
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

  it("tests that new page button callback is fired on new page click", () => {
    const spy = jest.spyOn(console, "log");
    const { container, getByTestId } = render(<App />);
    expect(container).toMatchSnapshot();
    act(() => {
      fireEvent.click(getByTestId("new-page-button"));
    });
    expect(spy).toHaveBeenCalledWith("Transmitting new page");
  });

  it("tests that participants aren't given open to add new page", () => {
    window.isOwner = false;
    window.ownerId = 2;
    const { container, queryByTestId } = render(<App />);
    expect(container).toMatchSnapshot();
    expect(queryByTestId("new-page-button")).toBeNull();
  });

  it("tests that users can edit canvas with pen tool", () => {
    const spy = jest.spyOn(console, "log");
    window.ownerId = 2;
    window.isOwner = false;
    window.ownerLayers = [{id: 1}];
    window.participantLayers = [{id: 2}];
    const { container, getByTestId } = render(<App />);
    expect(container).toMatchSnapshot();
    const canvas = getByTestId(/canvasync-canvas-1-2/);
    act(() => {
      fireEvent.mouseDown(canvas);
      fireEvent.mouseUp(canvas);
    });
    expect(spy).toHaveBeenCalledWith("Sending tangible diff (seq = 0)...");
  });

  it("tests that users can edit canvas", () => {
    const spy = jest.spyOn(console, "log");
    window.ownerId = 2;
    window.isOwner = false;
    window.ownerLayers = [{id: 1}];
    window.participantLayers = [{id: 2}];
    const { container, getByTestId } = render(<App />);
    expect(container).toMatchSnapshot();
    const canvas = getByTestId(/canvasync-canvas-1-2/);
    act(() => {
      fireEvent.mouseDown(canvas);
      fireEvent.mouseUp(canvas);
    });
    expect(spy).toHaveBeenCalledWith("Sending tangible diff (seq = 0)...");
  });
});
