import React, { useState, useCallback } from 'react'
import { Page } from './page';

export const CanvasTools = {
  pen: 'Pen',
  eraser: 'Eraser',
  select: 'Select',
  text: 'Text',
}

export function Notebook() {
  const [numPages, setNumPages] = useState(1);
  const [activeTool, setActiveTool] = useState(CanvasTools.pen);
  const [activeColor, setActiveColor] = useState('#000000');

  const canvasToolCallback = useCallback((event) =>
    setActiveTool(event.target.innerText)
  );
  const colorToolCallback = useCallback((event) =>
    setActiveColor(event.target.value)
  );
  const addPageCallback = useCallback(() => {
    setNumPages(prevNumPages => prevNumPages+1);
  });
  
  const pages = [];
  for (let i = 0; i < numPages; i++) {
    pages.push(      <Page activeTool={activeTool} activeColor={activeColor} />
      );
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