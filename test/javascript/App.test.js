/**
 * @jest-environment jsdom
 */

import React from "react";
import renderer from "react-test-renderer";
import App from "../../app/javascript/components/App";
import { faPlus } from '@fortawesome/free-solid-svg-icons'
import { createConsumer } from "@rails/actioncable";

describe('react canvas app tests', () => {
  beforeEach(() => {
    jest.mock("@rails/actioncable", () => {
      return {
        createConsumer: jest.fn().mockImplementation(() => {
          return {};
        }),
      };
    });
  
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
  });
  
  it("renders correctly", () => {
    const app = renderer.create(<App />);
    expect(app).toMatchSnapshot();
  });
  
  it("renders a new page when page added", () => {
    const app = renderer.create(<App />);
    expect(app).toMatchSnapshot();
    const instance = app.root;
    const newPageButton = instance.findByProps({icon: faPlus}).parent;
    console.log(newPageButton.props);
    newPageButton.props.onClick();
    expect(app).toMatchSnapshot();
    expect(window.ownerLayers.length).toBe(1);
  });
});
