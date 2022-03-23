import React, { useEffect, useState, useCallback } from 'react'
import consumer from '../channels/consumer';
import { Page } from './page';

export const CanvasTools = {
  pen: 'Pen',
  eraser: 'Eraser',
  select: 'Select',
  text: 'Text',
}

export function Notebook() {
  const [numPages, setNumPages] = useState(Math.max(window.participantLayers.length, window.ownerLayers.length));
  const [activeTool, setActiveTool] = useState(CanvasTools.pen);
  const [activeColor, setActiveColor] = useState('#000000');
  const [pageChannel, setPageChannel] = useState(null);

  const setupSubscription = () => {
    const notebookId = window.notebookId;
    return consumer.subscriptions.create({ channel: 'PageChannel', notebook_id: notebookId }, {
      connected() {
        // Called when the subscription is ready for use on the server
        console.log(`Connected to page_channel_${notebookId} ...`);
      },

      disconnected() {
        // Called when the subscription has been terminated by the server
      },

      received(data) {
        // Called when there's incoming data on the websocket for this channel
        window.ownerLayers.push(data.find(layer => layer.writer.user_id === window.ownerId));
        if (!window.isOwner) {
          window.participantLayers.push(data.find(layer => layer.writer.user_id === window.currentUser));
        }
        setNumPages(Math.max(window.participantLayers.length, window.ownerLayers.length));
      }
    });
  };

  const transmitNewPage = (notebookId) => {
    if (pageChannel !== null) {
      pageChannel.send({ notebookId: notebookId });
    }
  };

  useEffect(() => {
    // Set up action cable subscriber once layer is created
    setPageChannel(setupSubscription(window.notebookId));
  }, []);

  const canvasToolCallback = useCallback((event) =>
    setActiveTool(event.target.innerText)
  );
  const colorToolCallback = useCallback((event) =>
    setActiveColor(event.target.value)
  );
  const addPageCallback = useCallback(() => {
    transmitNewPage(window.notebookId);
  });

  const pages = [];
  for (let i = 0; i < numPages; i++) {
    const pid = window.participantLayers[i] ? window.participantLayers[i].id : null;
    const oid = window.ownerLayers[i] ? window.ownerLayers[i].id : null;
    pages.push(<Page activeTool={activeTool} activeColor={activeColor} ownerLayerId={oid} participantLayerId={pid} key={i} />);
  }

  // TODO: maybe pass in page id or layer id using window here
  return (
    <div className='flex flex-row'>
      <div className='flex flex-col'>
        <input type='color' value={activeColor} onChange={colorToolCallback} />
        <button className='primary-button' onClick={canvasToolCallback}>{CanvasTools.pen}</button>
        <button className='primary-button' onClick={canvasToolCallback}>{CanvasTools.eraser}</button>
        <button className='primary-button' onClick={canvasToolCallback}>{CanvasTools.select}</button>
        <button className='primary-button' onClick={canvasToolCallback}>{CanvasTools.text}</button>
      </div>
      <div className='flex flex-col'>
        {pages}
        {
          window.isOwner && <button className='primary-button' onClick={addPageCallback}>Add Page</button>
        }
      </div>
    </div>
  );
};